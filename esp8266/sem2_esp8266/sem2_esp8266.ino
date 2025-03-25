#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP8266WiFi.h>

/* Wifi configuration */
const char* WIFI_SSID = "BALOI";
const char* WIFI_PASSWORD = "0909286456";

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


/* DHT for testing first */
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>
#include <cmath>
#define DHTPIN 4  // Digital pin connected to the DHT sensor
// Feather HUZZAH ESP8266 note: use pins 3, 4, 5, 12, 13 or 14 --
// Pin 15 can work but DHT must be disconnected during program upload.

// Uncomment the type of sensor in use:
#define DHTTYPE DHT11  // DHT 11
//#define DHTTYPE    DHT22     // DHT 22 (AM2302)

// See guide for details on sensor wiring and usage:
//   https://learn.adafruit.com/dht/overview

DHT_Unified dht(DHTPIN, DHTTYPE);
uint32_t delayMS;


/* Generaal configuration */
constexpr uint32_t SERIAL_DEBUG_BAUD = 9600U;
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

void init_dht11() {
  dht.begin();
  Serial.println(F("DHTxx Unified Sensor Example"));
  // Print temperature sensor details.
  sensor_t sensor;
  dht.temperature().getSensor(&sensor);
  Serial.println(F("------------------------------------"));
  Serial.println(F("Temperature Sensor"));
  Serial.print(F("Sensor Type: "));
  Serial.println(sensor.name);
  Serial.print(F("Driver Ver:  "));
  Serial.println(sensor.version);
  Serial.print(F("Unique ID:   "));
  Serial.println(sensor.sensor_id);
  Serial.print(F("Max Value:   "));
  Serial.print(sensor.max_value);
  Serial.println(F("°C"));
  Serial.print(F("Min Value:   "));
  Serial.print(sensor.min_value);
  Serial.println(F("°C"));
  Serial.print(F("Resolution:  "));
  Serial.print(sensor.resolution);
  Serial.println(F("°C"));
  Serial.println(F("------------------------------------"));
  // Print humidity sensor details.
  dht.humidity().getSensor(&sensor);
  Serial.println(F("Humidity Sensor"));
  Serial.print(F("Sensor Type: "));
  Serial.println(sensor.name);
  Serial.print(F("Driver Ver:  "));
  Serial.println(sensor.version);
  Serial.print(F("Unique ID:   "));
  Serial.println(sensor.sensor_id);
  Serial.print(F("Max Value:   "));
  Serial.print(sensor.max_value);
  Serial.println(F("%"));
  Serial.print(F("Min Value:   "));
  Serial.print(sensor.min_value);
  Serial.println(F("%"));
  Serial.print(F("Resolution:  "));
  Serial.print(sensor.resolution);
  Serial.println(F("%"));
  Serial.println(F("------------------------------------"));
}

void send_sample_dht_metrics() {
  sensors_event_t event;

  // Get temperature event and print its value.
  // Serial.println("Sending temperature data...");
  dht.temperature().getEvent(&event);
  if (isnan(event.temperature)) {
    Serial.println(F("Error reading temperature!"));
  } else {
    //tb.sendTelemetryData(TEMPERATURE_KEY, event.temperature);
    String payload = "{";
    payload += "\"" + TEMPERATURE_KEY;
    payload += "\":";
    payload += event.temperature;
    payload += "}";
    char telemetry[150];
    payload.toCharArray(telemetry, 100);
    client.publish("v1/devices/me/telemetry", telemetry);
    // Serial.print(F("Temperature: "));
    // Serial.print(event.temperature);
    // Serial.println(F("°C"));
  }

  // Get humidity event and print its value.
  // Serial.println("Sending humidity data...");
  dht.humidity().getEvent(&event);
  if (isnan(event.relative_humidity)) {
    Serial.println(F("Error reading humidity!"));
  } else {
    //tb.sendTelemetryData(HUMIDITY_KEY, event.relative_humidity);
    String payload = "{";
    payload += "\"" + HUMIDITY_KEY;
    payload += "\":";
    payload += event.relative_humidity;
    payload += "}";
    char telemetry[150];
    payload.toCharArray(telemetry, 100);
    client.publish("v1/devices/me/telemetry", telemetry);
    // Serial.print(F("Humidity: "));
    // Serial.print(event.relative_humidity);
    // Serial.println(F("%"));
  }
  //Serial.println("dht sent.");
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
}

/*
  8051 <-uart-> 8266 <-wifi-> Thingsboard MQTT
  Thingsboard MQTT: Attributes API & RPC API
*/

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

  String str_3 = "";
  deserializeJson(doc, json);

  // Check request method
  String methodName = String((const char*)doc["method"]);
  char valZL[2]; // string for number with zero leading. This is important to save on 8051's eeprom
  Serial.print("parsed methodName: ");
  Serial.println(methodName);

  if (methodName.equals("setControlMode")) {
    send_to_uart("001", doc["params"] ? "1" : "0");
  }
  else if (methodName.equals("getControlMode")) {
    send_to_uart("002", "2");
    rpc_002_topic = String(topic);
  }
  else if (methodName.equals("setDevice1OnAt")) {
    int digit = (int)doc["params"];
    // save to str_3 with format: [Tens digit]:[Units digit]
    sprintf(valZL, "%02d", digit);
    str_3 = valZL[0];
    str_3 += ":";
    str_3 += valZL[1];
    send_to_uart("A", String(str_3));
  }
  else if (methodName.equals("getDevice1OnAt")) {
    send_to_uart("006", "2");
    rpc_006_topic = String(topic);
  }
  else if (methodName.equals("setDevice1OffAt")) {
    int digit = (int)doc["params"];
    // save to str_3 with format: [Tens digit]:[Units digit]
    sprintf(valZL, "%02d", digit);
    str_3 = valZL[0];
    str_3 += ":";
    str_3 += valZL[1];
    send_to_uart("B", String(str_3));
  }
  else if (methodName.equals("getDevice1OffAt")) {
    send_to_uart("008", "2");
    rpc_008_topic = String(topic);
  }
  else if (methodName.equals("setDevice2OnAt")) {
    int digit = (int)doc["params"];
    // save to str_3 with format: [Tens digit]:[Units digit]
    sprintf(valZL, "%02d", digit);
    str_3 = valZL[0];
    str_3 += ":";
    str_3 += valZL[1];
    send_to_uart("C", String(str_3));
  }
  else if (methodName.equals("getDevice2OnAt")) {
    send_to_uart("010", "2");
    rpc_010_topic = String(topic);
  }
  else if (methodName.equals("setDevice2OffAt")) {
    int digit = (int)doc["params"];
    // save to str_3 with format: [Tens digit]:[Units digit]
    sprintf(valZL, "%02d", digit);
    str_3 = valZL[0];
    str_3 += ":";
    str_3 += valZL[1];
    send_to_uart("D", String(str_3));
  }
  else if (methodName.equals("getDevice2OffAt")) {
    send_to_uart("012", "2");
    rpc_012_topic = String(topic);
  }
  else if (methodName.equals("setDevice1State")) {
    send_to_uart("013", doc["params"] ? "1" : "0");
  }
  else if (methodName.equals("getDevice1State")) {
    send_to_uart("014", "2");
    rpc_014_topic = String(topic);
  }
  else if (methodName.equals("setDevice2State")) {
    send_to_uart("015", doc["params"] ? "1" : "0");
  }
  else if (methodName.equals("getDevice2State")) {
    send_to_uart("016", "2");
    rpc_016_topic = String(topic);
  }
  else if (methodName.equals("getDHT11")) {
    send_to_uart("000", "2");
    rpc_016_topic = String(topic);
  }
}

void listen_on_uart() {
  int buff_size = 7;
  char buff[buff_size];
  
  int i = 0; // buffer index
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

      // check if end of message
      if (buff[i] == '*' || buff[i] == '\n' || buff[i] == '/') {
        break;
      }
    }
    Serial.println(". done!");
    String str_rx;
    
    // identify each message, then proceed with thingsboard
    for (i = 0; buff[i] != '\0' && i < buff_size; i++) {
      if (buff[i] == '/' || buff[i] == '\n' || buff[i] == '*') {
        // end of string
      }
      else {
        str_rx += buff[i];
        continue;
      }

      // A new uart rx string arrived, let proceed
      String cmd = str_rx.substring(0, 1);
      String val = str_rx.substring(2, str_rx.length());

      Serial.println("uart cmd: " + cmd);
      if (cmd == "002:") {
        //send_attribute("getControlMode", val + ".0");
        response_rpc(rpc_002_topic, val);
        Serial.print("response rpc topic: " + rpc_002_topic);
        Serial.println(". val: " + val);
      } else if (cmd == "S") {
        
        String temp = val.substring(0, 2);
        String hum = val.substring(2, 4);
        String temp_state = val.substring(4, 5) == "1" ? "true" : "false";
        String hum_state = val.substring(5, 6) == "1" ? "true" : "false";
        send_metrics(HUMIDITY_KEY, hum);
        Serial.println("telemetry HUMIDITY_KEY was sent: " + hum);
        send_metrics(TEMPERATURE_KEY, temp);
        Serial.println("telemetry TEMPERATURE_KEY was sent: " + temp);
        send_metrics("temp_state", temp_state);
        Serial.println("telemetry temp_state was sent: " + temp_state);
        send_metrics("hum_state", hum_state);
        Serial.println("telemetry hum_state was sent: " + hum_state);
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

      // break for loop if end of buffer
      break;
    }

    Serial.println("... end of uart rx");
  }
}

void send_to_uart(String method, String val) {
  // 3: for [':', '/', '\n']
  int payload_length = method.length() + val.length() + 3; 

  String payload = method;
  // payload += ":";
  payload += val;
  payload += "*";  // ending indicator

  Serial.print("sending to uart... ");
  Serial.print(payload);

  // convert payload to char[]
  char char_payload[payload_length];
  payload.toCharArray(char_payload, payload_length);

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
  my_uart.begin(9600);  //same with 8051
  my_uart.println("Hello, world?");
  

  /* DHT11 on ESP8266 - just for testing. In fact, we receive temperature from 8051 via UART */
  init_dht11();

  // Thingsboard callback
  client.setServer(THINGSBOARD_SERVER, THINGSBOARD_PORT);
  client.subscribe("v1/devices/me/rpc/request/+");
  client.setCallback(on_message);
  Serial.println("Initial subcribed to thingsboard!");
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

  /* Just for practice DHT11 on ESP8266, 
    remove this when use metrics from 8051 */
  //send_sample_dht_metrics();

  // required when using MQTT
  client.loop();
  delay(1500);
}
