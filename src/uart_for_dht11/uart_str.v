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
  output reg tx_msg_done,

  // humidifer & cooling fan states
  input wire fan_state,
  input wire hum_state,
  
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

  localparam IDLE = 2'b00, LOAD = 2'b01, TRANSMIT = 2'b10, DONE = 2'b11;
  wire tx_done, rx_done;

  reg [3:0] tx_index;  // Index for numbers from 0 to 9
  reg [7:0] tx_data;
  reg send_start;
  reg [31:0] timer_count; // Timer counter for 1-second delay
  wire tx_busy;

  // ASCII message to send
  reg [7:0] tx_msg [0:8]; // 9 ascii characters

  integer temp;

  initial begin
    tx_msg[0] = 8'h53; // ASCII 'S'
    tx_msg[1] = 8'h3A; // ASCII ':'
    tx_msg[2] = 8'h30; // ASCII '0'
    tx_msg[3] = 8'h30; // ASCII '0'
    tx_msg[4] = 8'h30; // ASCII '0'
    tx_msg[5] = 8'h30; // ASCII '0'
    //tx_msg[6] = 8'h2F; // ASCII '/'
    tx_msg[6] = 8'h30; // ASCII '0'
    tx_msg[7] = 8'h30; // ASCII '0'
    tx_msg[8] = 8'h2F; // ASCII '\n'

    tx_msg_done = 1'b0;
  end

  // Sending logic - TX Handler
  reg [1:0] TX_STATE;
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
      //tx_msg[6] <= 8'h2F; // ASCII '/'
      tx_msg[6] <= 8'h30; // ASCII '0'
      tx_msg[7] <= 8'h30; // ASCII '0'
      tx_msg[8] <= 8'h2F; // ASCII '/'

      tx_msg_done <= 1'b0;
      tx_index <= 0;
      send_start <= 1'b0;
      timer_count <= 0;
      TX_STATE <= IDLE;
      //txstate <= 0;
    end else if (en_tx) begin
      case (TX_STATE)
        IDLE: begin
          tx_msg_done <= 1'b0; // Reset done flag
          if (!tx_busy) begin
            // Wait for 1-second interval
            if (timer_count == SEND_INTERVAL) begin
              timer_count <= 0;
              TX_STATE <= LOAD;
            end else begin
              timer_count <= timer_count + 1;
            end
          end
        end
        LOAD: begin
          // only load the temperature and humidity values one at a time, to save performance & power
          if (tx_index == 0) begin
            tx_msg[2] <= temperature / 10 + 8'h30;
            tx_msg[3] <= temperature % 10 + 8'h30;
            tx_msg[4] <= humidity / 10 + 8'h30;
            tx_msg[5] <= humidity % 10 + 8'h30;
            tx_msg[6] <= fan_state ? 8'h31 : 8'h30; // ASCII '1' or '0'
            tx_msg[7] <= hum_state ? 8'h31 : 8'h30; // ASCII '1' or '0'
          end

          tx_data <= tx_msg[tx_index]; // Load the current character
          send_start <= 1'b1;          // Start UART transmission
          TX_STATE <= TRANSMIT;
        end
        TRANSMIT: begin
          if (tx_done) begin
            send_start <= 1'b0;        // Clear send_start after transmission
            if (tx_index < 8) begin
              tx_index <= tx_index + 1;
              TX_STATE <= LOAD;       // Load the next character
            end else begin
              tx_index <= 0;
              TX_STATE <= DONE;       // All characters sent
            end
          end
        end
        DONE: begin
          tx_msg_done <= 1'b1;         // Set done flag
          TX_STATE <= IDLE;           // Return to idle state
        end
      endcase
    end
  end

  /*
  Rx Handler
  Retrieve the ASCII characters from the UART module and control the LEDs based on the received values
  Format: [command][value_1]:[value_2]\n (':' is the delimiter, '\n' is the newline character to identify the end of the message)
  E.g.: L1:0\n (LED 1 ON, LED 2 OFF), A2:5\n (Max Temp: 25 celcius), C5:0\n (Max Humidity: 50%)
  Because we are working on 2 different clock domains, the delimiter (:) is necessary to indentify correct state in SFM synchronization
  */
  wire [7:0] rx_data;
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
          // check for first ascii number, it couble be a minus or a numbers:
          if ((rx_data >= 8'h30 && rx_data <= 8'h39) || rx_data == 8'h2D) begin // ASCII '0' to '9' or '-'
            RX_STATE <= 2;
            chr_val0 <= rx_data;
          end
        end
        2: begin
          // Check for ':' (separator)
          if (rx_data == 8'h3A) begin // ASCII ':'
            RX_STATE <= 3;
          end
          // led_hum_reg <= 1; // test
        end
        3: begin
          // Check for second ascii number
          if (rx_data >= 8'h30 && rx_data <= 8'h39) begin // ASCII '0' or '1'
            RX_STATE <= 4;
            chr_val1 <= rx_data;
          end
          // led_fan_reg <= 1; // test
        end
        4: begin
          // Check for newline character ('\n') or * or '/' character
          if (rx_data == 8'h0A || rx_data == 8'h2A || rx_data == 8'h2F) begin
            rx_msg_done <= 1'b1;
            RX_STATE <= 0;
          end
        end
      endcase
    end
    else if (rx_busy && !rx_done) begin
      rx_msg_done <= 1'b0;
    end
  end

  uart_tx uart_tx_inst(
    .clk(clk_1Mhz),
    .rst_n(rst_n),
    .tx_start(send_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
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