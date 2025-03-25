/*
  This module is used to send/receive string of ascii characters to/from the UART module
  - TX: The ascii string is formatted as follows: S:[temperature_high][temperature_low][humidity_high][humidity_low]\n
  - RX: Handle the received ascii string of 5 characters
      Format: [char_command][char_value1]:[char_value2]\n
      Example: L1:0\n (L: LED; 1: led_fan ON, 0: led_hum OFF)
      Example: A2:5\n (A: Max Temperature; 25: 25 degrees Celsius)
      Example: B1:0\n (B: Min Temperature; 10: 10 degrees Celsius)
      Example: C5:0\n (C: Max Humidity; 50: 50%)
      Example: D2:0\n (D: Min Humidity; 20: 20%)
*/
module uart_string(
  input wire clk_1Mhz,
  input wire rst_n,

  input wire [7: 0] temperature,//data_heart_rate,
  input wire [7: 0] humidity,//data_spo2,

  input wire rx,
  output wire tx,
  input wire en_tx,

  // humidifer & cooling fan states
  input wire fan_state,
  input wire hum_state,

  // Threshold values for temperature and humidity.
  // These settings retrieved from Thingsboard MQTT via ESP8266 (UART)
  // output reg [6:0] max_temp,
  // output reg [6:0] min_temp,
  // output reg [6:0] max_hum,
  // output reg [6:0] min_hum,
  
  // RX String message
  // Format: [char_command][char_value1][char_value2] 
  // Example: L10 (L: LED; 1: led_fan ON, 0: led_hum OFF)
  //output reg [6:0] rx_msg [0:2], // 3 characters
  output reg [7:0] chr_cmd,
  output reg [7:0] chr_val0,
  output reg [7:0] chr_val1,
  output reg       rx_msg_done  // RX done flag

  // output wire led_fan,
  // output wire led_hum
);

  // localparam [1:0] parity_type = 2'b01; // ODD parity
  // localparam [1:0] baud_rate = 2'b10;   // 9600 baud
  // SEND_INTERVAL = Clock frequency (1 MHz) * Time (1 second) = 1,000,000 cycles
  localparam SEND_INTERVAL = 1_000_000; // 1 second for 1MHz clock

  wire tx_done, rx_done;

  reg [2:0] tx_index;  // Index for 8 characters
  reg [7:0] tx_data;
  reg send_start;
  reg [31:0] timer_count; // Timer counter for 1-second delay
  wire tx_busy;

  // ASCII message to send
  reg [6:0] tx_msg [0:6];

  integer temp;

  initial begin
    tx_msg[0] = 8'h53; // ASCII 'S'
    tx_msg[1] = 8'h3A; // ASCII ':'
    tx_msg[2] = 8'h30; // ASCII '0'
    tx_msg[3] = 8'h30; // ASCII '0'
    tx_msg[4] = 8'h30; // ASCII '0'
    tx_msg[5] = 8'h30; // ASCII '0'
    tx_msg[6] = 8'h2F; // ASCII '/'
    //tx_msg[6] = 8'h30; // ASCII '0'
    //tx_msg[7] = 8'h30; // ASCII '0'
    //tx_msg[8] = 8'h2F; // ASCII '\n'
  end

  // Sending logic - TX Handler
  reg TX_STATE;
  always @(posedge clk_1Mhz or negedge rst_n) begin
    /*
      Handle the state machine for sending the string of ASCII characters every 1 second via UART
      You should control the SFM with 2 different clock domains: 100MHz and baud rate 9600
    */
    if (!rst_n) begin
      // Reset all states and signals
      tx_msg[0] <= 8'h53; // ASCII 'S'
      tx_msg[1] <= 8'h3A; // ASCII ':'
      tx_msg[2] <= 8'h30; // ASCII '0'
      tx_msg[3] <= 8'h30; // ASCII '0'
      tx_msg[4] <= 8'h30; // ASCII '0'
      tx_msg[5] <= 8'h30; // ASCII '0'
      tx_msg[6] <= 8'h2F; // ASCII '/'
      // tx_msg[6] <= 8'h30; // ASCII '0'
      // tx_msg[7] <= 8'h30; // ASCII '0'
      //tx_msg[8] <= 8'h2F; // ASCII '/'

      tx_index <= 0;
      send_start <= 0;
      timer_count <= 0;
      TX_STATE <= 0;
    end else if (en_tx) begin
      case (TX_STATE)
        0: begin
          // Wait for 1-second interval
          if (timer_count == SEND_INTERVAL) begin
            timer_count <= 0;
            TX_STATE <= 1; // Transition to sending state
          end else begin
            timer_count <= timer_count + 1;
          end
        end
        1: begin
          // Update sensor data at the start of transmission
          if (tx_index == 0 && !tx_busy) begin
            tx_msg[2] <= temperature / 10 + 8'h30;
            tx_msg[3] <= temperature % 10 + 8'h30;
            tx_msg[4] <= humidity / 10 + 8'h30;
            tx_msg[5] <= humidity % 10 + 8'h30;
            // tx_msg[6] <= fan_state ? 8'h31 : 8'h30; // ASCII '1' or '0'
            // tx_msg[7] <= hum_state ? 8'h31 : 8'h30; // ASCII '1' or '0'
          end

          // Send one character at a time
          if (!tx_busy && !send_start) begin
            tx_data <= tx_msg[tx_index]; // Load the current character
            send_start <= 1;            // Start UART transmission
          end else if (send_start && !tx_busy) begin
            send_start <= 0;            // Clear send_start after transmission
            tx_index <= (tx_index < 6) ? tx_index + 1 : 0; // Increment or reset index
            TX_STATE <= (tx_index == 6) ? 0 : TX_STATE;    // Transition to idle if done
          end
        end
      endcase
    end
  end

  /*
  Rx Handler
  Retrieve the ASCII characters from the UART module and control the LEDs based on the received values
  Format: L[ascii_led_1]:[ascii_led_2]\n
  E.g.: L1:0\n (LED 1 ON, LED 2 OFF)
  Because we are working on 2 different clock domains, the delimiter (:) is necessary to indentify correct state in SFM synchronization
  */
  wire [7:0] rx_data;
  // reg led_fan_reg, led_hum_reg;
  // assign led_fan = led_fan_reg;
  // assign led_hum = led_hum_reg;
  wire rx_busy;
  reg [5:0] RX_STATE;
  //reg [7:0] chr_cmd, chr_val0, chr_val1;
  always @(posedge clk_1Mhz or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all states and signals
      RX_STATE <= 0;      // Reset FSM state
      rx_msg_done <= 1'b0;   // Reset RX done flag

      // led_fan_reg <= 1'b0; // Turn on fan LED
      // led_hum_reg <= 1'b0; // Turn on humidity LED
    end else if (!rx_busy && rx_done) begin
      // If not busy and a character is received
      case (RX_STATE)
        0: begin
          // Check first char, it could be 'A', 'B', 'C', 'D' or 'L' (ASCII)
          if (rx_data == 8'h41 || rx_data == 8'h42 || rx_data == 8'h43
              || rx_data == 8'h44 || rx_data == 8'h4C) begin
            RX_STATE <= 1;
            chr_cmd <= rx_data;
            rx_msg_done <= 1'b0;
          end else begin
            RX_STATE <= 0; // Stay in idle state if invalid
          end
        end
        1: begin
          // Check for fan control value (ASCII digit). it should be 0 or 1
          if (rx_data == 8'h30 || rx_data == 8'h31) begin // ASCII '0' or '1'
            RX_STATE <= 2;
            chr_val0 <= rx_data;
          end
          // led_fan_reg <= 1; // test
        end
        2: begin
          // Check for ':' (separator)
          if (rx_data == 8'h3A) begin // ASCII ':'
            RX_STATE <= 3;
          end
          // led_hum_reg <= 1; // test
        end
        3: begin
          // Check for humidity control value (ASCII digit). it should be 0 or 1
          if (rx_data == 8'h30 || rx_data == 8'h31) begin // ASCII '0' or '1'
            RX_STATE <= 4;
            chr_val1 <= rx_data;
          end
          // led_fan_reg <= 1; // test
        end
        4: begin
          // Check for newline character ('\n') or * or '/' character
          if (rx_data == 8'h0A || rx_data == 8'h2A || rx_data == 8'h2F) begin
            rx_msg_done <= 1'b1;
          end
        end
      endcase
    end
  end

  uart_tx uart_tx_inst(
    .clk(clk_1Mhz),
    .rst_n(rst_n),
    .tx_start(send_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
  );

  uart_rx uart_rx_inst (
    .clk(clk_1Mhz),
    .rst_n(rst_n),
    .rx(rx),
    .data_out(rx_data),
    .rx_busy(rx_busy),
    .done(rx_done)
  );
endmodule