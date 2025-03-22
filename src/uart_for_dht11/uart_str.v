/*
  This module is used to send/receive string of ascii characters to/from the UART module
  - TX: The ascii string is formatted as follows: S:[temperature_high][temperature_low][humidity_high][humidity_low]\n
  - RX: LEDs controlling format: L[ascii_led_1]:[ascii_led_2]\n. e.g.: L1:0\n (LED 1 ON, LED 2 OFF)
*/
module uart_string(
  input wire clk_100Mhz,
  input wire rst_n,

  input wire [7: 0] temperature,//data_heart_rate,
  input wire [7: 0] humidity,//data_spo2,

  input wire rx,
  output wire tx,

  output wire led_fan,
  output wire led_hum
);

  localparam [1:0] parity_type = 2'b01; // ODD parity
  localparam [1:0] baud_rate = 2'b10;   // 9600 baud
  // SEND_INTERVAL = Clock frequency (100 MHz) * Time (1 second) = 100,000,000 cycles
  localparam SEND_INTERVAL = 100_000_000; // 1 second

  wire tx_done, rx_done;

  reg [2:0] tx_index;  // Index for 8 characters
  reg [7:0] tx_data;
  reg send_start;
  reg [31:0] timer_count; // Timer counter for 1-second delay
  wire tx_busy;

  // ASCII message to send
  reg [6:0] tx_msg [0:7];

  integer temp;

  initial begin
    tx_msg[0] = 8'h53; // ASCII 'S'
    tx_msg[1] = 8'h3A; // ASCII ':'
    tx_msg[2] = 8'h30; // ASCII '0'
    tx_msg[3] = 8'h30; // ASCII '0'
    tx_msg[4] = 8'h30; // ASCII '0'
    tx_msg[5] = 8'h30; // ASCII '0'
    tx_msg[6] = 8'h0A; // ASCII '\n'
  end

  // Sending logic - TX Handler
  reg STATE_STR;
  always @(posedge clk_100Mhz or negedge rst_n) begin
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
      tx_msg[6] <= 8'h0A; // ASCII '\n

      tx_index <= 0;
      send_start <= 0;
      timer_count <= 0;
      STATE_STR <= 0;
    end else begin
      case (STATE_STR)
        0: begin
          // Wait for 1-second interval
          if (timer_count == SEND_INTERVAL) begin
            timer_count <= 0;
            STATE_STR <= 1; // Transition to sending state
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
          end

          // Send one character at a time
          if (!tx_busy && !send_start) begin
            tx_data <= tx_msg[tx_index]; // Load the current character
            send_start <= 1;            // Start UART transmission
          end else if (!tx_busy && send_start) begin
            send_start <= 0;            // Clear send_start after transmission
            if (tx_index < 6) begin
              tx_index <= tx_index + 1; // Move to the next character
            end else begin
              tx_index <= 0;            // Reset index after all characters are sent
              STATE_STR <= 0;           // Transition back to idle state
            end
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
  reg led_fan_reg, led_hum_reg;
  assign led_fan = led_fan_reg;
  assign led_hum = led_hum_reg;
  wire rx_busy;
  reg [5:0] RX_STATE;
  reg [7:0] ascii_fan, ascii_hum;
  always @(posedge clk_100Mhz or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all states and signals
      ascii_fan <= 8'h30; // Default ASCII '0'
      ascii_hum <= 8'h30; // Default ASCII '0'
      RX_STATE <= 0;      // Reset FSM state

      led_fan_reg <= 1'b0; // Turn on fan LED
      led_hum_reg <= 1'b0; // Turn on humidity LED
    end else if (!rx_busy && rx_done) begin
      // If not busy and a character is received
      case (RX_STATE)
        0: begin
          // Check for 'L' (LED control)
          if (rx_data == 8'h4C) begin // ASCII 'L'
            RX_STATE <= 1;
          end else begin
            RX_STATE <= 0; // Stay in idle state if invalid
          end
        end
        1: begin
          // Check for fan control value (ASCII digit). it should be 0 or 1
          if (rx_data == 8'h30 || rx_data == 8'h31) begin // ASCII '0' or '1'
            ascii_fan <= rx_data; // Store fan control value
            RX_STATE <= 2;
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
            ascii_hum <= rx_data; // Store humidity control value
            RX_STATE <= 4;
          end
          // led_fan_reg <= 1; // test
        end
        4: begin
          // Check for newline character ('\n') or * character
          if (rx_data == 8'h0A || rx_data == 8'h2A) begin // ASCII '\n' or '*'
            // Update LED states based on received values
            led_fan_reg <= (ascii_fan != 8'h30); // Turn on if not '0'
            led_hum_reg <= (ascii_hum != 8'h30); // Turn on if not '0'
            RX_STATE <= 0; // Reset FSM to idle state
          end
        end
      endcase
    end
  end

  uart_tx uart_tx_inst(
    .clk(clk_100Mhz),
    .rst_n(rst_n),
    .tx_start(send_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
  );

  uart_rx uart_rx_inst (
    .clk(clk_100Mhz),
    .rst_n(rst_n),
    .rx(rx),
    .data_out(rx_data),
    .rx_busy(rx_busy),
    .done(rx_done)
  );
endmodule