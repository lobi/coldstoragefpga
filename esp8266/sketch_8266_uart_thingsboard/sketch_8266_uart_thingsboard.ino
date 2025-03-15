#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP8266WiFi.h>

/* Wifi configuration */
const char* WIFI_SSID = "Lobi-iphone-11";
const char* WIFI_PASSWORD = "lobicula";

/* Thingsboards configuration */
const char* THINGSBOARD_TOKEN = "s3AiPMGyj8DjIoVteKhU";
constexpr char THINGSBOARD_SERVER[] = "thingsboard.cloud";
constexpr uint16_t THINGSBOARD_PORT = 1883U;
constexpr char CONNECTING_MSG[] = "Connecting to: (%s) with token (%s)\n";
//constexpr char TEMPERATURE_KEY[] = "temperature";
//constexpr char HUMIDITY_KEY[] = "humidity";
String TEMPERATURE_KEY = "temperature";
String HUMIDITY_KEY = "humidity";

WiFiClient espClient;
PubSubClient client(espClient);


/*  UART - to transmit & receive serial data with 8051 */
#include <SoftwareSerial.h>
//SoftwareSerial my_uart(3, 1); // RX, TX
SoftwareSerial my_uart(13, 15);  // RX, TX

/* For the Assignment - Test zub - esp8266 - thingsboard */
const int ledPin = 2; // Define the LED pin (D4) - built-in led
// #define ledPin 2      // Built-in LED on GPIO2 (D4)
bool ledState = false;

// #define buttonPin 0
const int buttonPin = 0; // Define the button pin (D3) - built-in button
bool lastButtonState = LOW;
bool buttonStateReal = LOW;
unsigned long lastDebounceTime = 0; // The last time the button state was toggled
const unsigned long debounceDelay = 50; // 50ms debounce time

const unsigned long telemetryDelay = 2000; // 2s telemetry delay
unsigned long lastTelemetryTime = 0;


/* General configuration */
constexpr uint32_t SERIAL_DEBUG_BAUD = 115200U;
String rpc_002_topic, rpc_006_topic, rpc_008_topic,
  rpc_010_topic, rpc_012_topic, rpc_014_topic,
  rpc_016_topic;

void init_wifi() {
  Serial.println("Connecting to AP ...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    Serial.println("Connected to AP");
    Serial.println("ESP8266's IP address: ");
    Serial.print(WiFi.localIP());
  }
  Serial.println(" connected!");
}

bool reconnect_wifi() {
  // Check to ensure we aren't connected yet
  const wl_status_t status = WiFi.status();
  if (status == WL_CONNECTED) {
    return true;
  }

  // If we aren't establish a new connection to the given WiFi network
  init_wifi();
  return true;
}

bool reconnect_thingsboard() {
  // Reconnect to the ThingsBoard server,
  // if a connection was disrupted or has not yet been established
  Serial.printf(CONNECTING_MSG, THINGSBOARD_SERVER, THINGSBOARD_TOKEN);
  if (!client.connect("ESP8266Client", THINGSBOARD_TOKEN, NULL)) {
    Serial.println("Failed to connect");
    return false;
  }

  // subcribe RPC
  client.subscribe("v1/devices/me/rpc/request/+");
  Serial.println("subcribed to thingsboard.io");
  return true;
}

void send_metrics(String m_key, String m_val) {
  String payload = "{";
    payload += "\"" + m_key;
    payload += "\":";
    payload += m_val;
    payload += "}";
    char telemetry[150];
    Serial.println("sending metric...");
    payload.toCharArray(telemetry, 100);
    client.publish("v1/devices/me/telemetry", telemetry);
}

void send_attribute(String attr, String val) {
  String msg = "{\"" + attr + "\": \"" + String(val == "1" ? "true" : "false") + "\"}";
  client.publish("v1/devices/me/attributes", msg.c_str());
}

void response_rpc(String topic, String val) {
  String responseTopic = topic;
  responseTopic.replace("request", "response");
  client.publish(responseTopic.c_str(), val.c_str());
  Serial.println("RPC response sent: " + topic + " " + val);
}

void send_rpc(String rpcPayload) {
    // The RPC payload
    /*
    String rpcPayload = R"({
        "method": "setValue",
        "params": {
            "value": "ON"
        }
    })";
    */

    // Topic format: v1/devices/me/rpc/request/1 (1 can be any request ID)
    String rpcTopic = "v1/devices/me/rpc/request/1";

    // Publish RPC request
    client.publish(rpcTopic.c_str(), rpcPayload.c_str());
    Serial.println("RPC request sent!");
    Serial.println(rpcPayload);
}

void send_sample_rpc() {
  // The RPC payload
  String rpcPayload = R"({
      "method": "setLedState",
      "params": {
          "value": true
      }
  })";

  send_rpc(rpcPayload);
}

/*
  Data interchange format between UARTs, 
  Command code vs. Thingsboard's methodName convention

  8051 Control Mode (auto/manual)
  - 001: setControlMode
  - 002: getControlMode
  ...
*/

// Thingsboard, the callback for when a PUBLISH message is received from the server.
void on_message(const char* topic, byte* payload, unsigned int length) {

  Serial.println("On message");

  char json[length + 1];
  strncpy(json, (char*)payload, length);
  json[length] = '\0';

  Serial.print("Topic: ");
  Serial.println(topic);
  Serial.print("Message: ");
  Serial.println(json);

  // Decode JSON request
  // Docs ref.: https://arduinojson.org/
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, json);
  if (error) {
    Serial.println("deserializeJson() returned: ");
    Serial.print(error.c_str());
    return;
  }

  deserializeJson(doc, json);

  // Check request method
  String methodName = String((const char*)doc["method"]);
  char valZL[2]; // string for number with zero leading. This is important to save on 8051's eeprom
  Serial.print("parsed methodName: ");
  Serial.println(methodName);

  if (methodName.equals("checkLedState")) {
    /*
      This method is used to check the led state,
      but it is not used in this project because 
      the thingsboard's widget is not working properly
    */
    response_rpc(String(topic), String(ledState));
  }
  else if (methodName.equals("getSwitchValue"))
  {
    response_rpc(String(topic), String(ledState ? "false" : "true"));
  }
  else if (methodName.equals("setSwitchValue"))
  {
    // set led state
    Serial.print("ledState before:");
    Serial.println(String(ledState));
    Serial.println(String(doc["params"]));
    ledState = String(doc["params"]) == "true" ? 0 : 1;
    Serial.print("ledState after:");
    Serial.println(String(ledState));

    digitalWrite(ledPin, ledState);
    response_rpc(String(topic), String(ledState ? "true" : "false"));

    // also send to uart:
    send_to_uart("U", String(ledState));
  }

}

void send_telemetry(String key, String val) {
  String payload = "{";
  payload += "\"" + key;
  payload += "\":";
  payload += val;
  payload += "}";
  char telemetry[150];
  Serial.println("sending telemetry...");
  payload.toCharArray(telemetry, 100);
  client.publish("v1/devices/me/telemetry", telemetry);
  Serial.println("telemetry was sent: " + val);

  
}

void send_led_state() {
  if ((millis() - lastTelemetryTime) > telemetryDelay) {
    send_telemetry("led_state", String(ledState ? "false" : "true"));
    lastTelemetryTime = millis(); // Update the timestamp here
  }
}

// Listen to 8051 (UART - RX)
void listen_on_uart() {
  int buff_size = 70;
  char buff[buff_size];
  String str_rx;
  int i = 0; // buffer index

  int incomingByte = 0;
  if (my_uart.available()) {
    Serial.print("\nReceiving from UART... ");

    // Receive all arrived chars.
    // Use my_uart.read() will faster than my_uart.readString() a lot, it will
    // reduce the issue loss message when transmit/receive multiple messages via UART
    while (my_uart.available() && i < buff_size)
    {
      buff[i] = my_uart.read();
      Serial.print(buff[i]);
      i++;
    }
    Serial.println(". done!");

    if (buff[0] == 0x55) {
      // special case, for testing only
      // let toggle the led state:
      ledState = !ledState;
      digitalWrite(ledPin, ledState);

      // send back to uart to toggle the led on the zuboard:
      send_to_uart("U", String(ledState));
      return;
    }
    
    // identify each message, then proceed with thingsboard
    for (i = 0; buff[i] != '\0' && i < buff_size; i++) {
      if (buff[i] == '/' || buff[i] == '\n') {
        // end of string
      }
      else {
        str_rx += buff[i];
        continue;
      }

      // A new uart rx string arrived, let proceed
      String cmd = str_rx.substring(0, 4);
      String val = str_rx.substring(4, str_rx.length());

      Serial.println("uart cmd: " + cmd);
      if (cmd == "002:") {
        //send_attribute("getControlMode", val + ".0");
        response_rpc(rpc_002_topic, val);
        Serial.print("response rpc topic: " + rpc_002_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "003:") {
        send_metrics(HUMIDITY_KEY, val);
        Serial.println("telemetry HUMIDITY_KEY was sent: " + val);
      } else if (cmd == "004:") {
        send_metrics(TEMPERATURE_KEY, val);
        Serial.println("telemetry TEMPERATURE_KEY was sent: " + val);
      } else if (cmd == "006:") {
        response_rpc(rpc_006_topic, String(val.toInt()));
        Serial.print("response rpc topic: " + rpc_006_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "008:") {
        response_rpc(rpc_008_topic, String(val.toInt()));
        Serial.print("response rpc topic: " + rpc_008_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "010:") {
        response_rpc(rpc_010_topic, String(val.toInt()));
        Serial.print("response rpc topic: " + rpc_010_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "012:") {
        response_rpc(rpc_012_topic, String(val.toInt()));
        Serial.print("response rpc topic: " + rpc_012_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "014:") {
        response_rpc(rpc_014_topic, val);
        Serial.print("response rpc topic: " + rpc_014_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "016:") {
        response_rpc(rpc_016_topic, val);
        Serial.print("response rpc topic: " + rpc_016_topic);
        Serial.println(". val: " + val);
      }


      // reset the message
      str_rx = "";
    }

    Serial.println("");
  }
}

void listen_on_button1() {
  bool buttonState = digitalRead(buttonPin);
  // Serial.print("buttonState=");
  // Serial.println(String(buttonState));

  // Check if the button state has changed
  if (buttonState != lastButtonState) {
    lastDebounceTime = millis(); // Reset debounce timer
    // Serial.println("reseted debounce timer");
  }

  // If the button state is stable for debounceDelay, process it
  if ((millis() - lastDebounceTime) > debounceDelay) {
    // Serial.println("debounce delay passed");
    // Serial.print("buttonState=");
    // Serial.println(String(buttonState));
    // digitalWrite(ledPin, !digitalRead(ledPin));

    // Check if the button state has changed
    if (buttonState != buttonStateReal) {
      buttonStateReal = buttonState;
      // lastButtonState = buttonState;
      // Check if the button is pressed (active-low)
      // if (buttonState == HIGH) {
      //   Serial.println("Button pressed!");
      //   ledState = !ledState;  // Toggle LED state
      //   digitalWrite(ledPin, ledState);
      // }
      if (buttonState == HIGH) {
        Serial.println("Button pressed!");
        ledState = !ledState;  // Toggle LED state
        digitalWrite(ledPin, ledState);

        // send to uart
        send_to_uart("U", String(ledState));
      }
    }
  }

  lastButtonState = buttonState; // Save the current button state
}

// Send data to 8051 (UART - TX)
void send_to_uart(String method, String val) {
  // 3: for [':', '/', '\n']
  int payload_length = method.length() + val.length() + 3; 

  String payload = method;
  payload += ":";
  payload += val;
  payload += "/";  // ending indicator

  Serial.print("sending to uart... ");
  Serial.print(payload);

  // convert payload to char[]
  char char_payload[payload_length];
  payload.toCharArray(char_payload, payload_length);

  // special case for testing
  if (method == "U") {
    // special case, for testing only
    // let toggle the led state:
    my_uart.write(0x55);
    Serial.println(" done 0x55!");
    return;
  }

  // send
  my_uart.write(char_payload);

  Serial.println(" done!");
  //}
}

void setup() {
  // Initalize serial connection for debugging
  Serial.begin(SERIAL_DEBUG_BAUD);

  // wifi
  init_wifi();

  /* UART */
  my_uart.begin(9600);
  my_uart.println("Hello world?");

  // Thingsboard callback
  client.setServer(THINGSBOARD_SERVER, THINGSBOARD_PORT);
  client.subscribe("v1/devices/me/rpc/request/+");
  client.setCallback(on_message);
  Serial.println("Initial subcribed to thingsboard!");

  pinMode(ledPin, OUTPUT); // Initialize the built-in LED pin as an output
  pinMode(buttonPin, INPUT); // Initialize the built-in button pin as an input with pull-up resistor
  digitalWrite(ledPin, 1);   // Ensure LED starts in OFF state
}

void loop() {
  // put your main code here, to run repeatedly:

  /* connect to wifi */
  if (!reconnect_wifi()) {
    return;
  }

  /* connect to thingsboard */
  if (!client.connected()) {
    if (!reconnect_thingsboard()) {
      return;
    }
  }

  /* listen 8051 via UART (TX) */
  listen_on_uart();

  // for button1
  listen_on_button1();

  // send_sample_rpc();

  // send led state to thingsboard via telemetry
  send_led_state();

  // required when using MQTT
  client.loop();
  //delay(1500);
}
