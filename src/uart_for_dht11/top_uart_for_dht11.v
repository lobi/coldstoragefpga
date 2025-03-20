module top_uart_for_dht11(
  input wire clk,
  input wire rst_n,
  input wire send, // enable signal for sending data to uart

  input wire [7: 0] temperature,//data_heart_rate,
  input wire [7: 0] humidity,//data_spo2,

  input wire rx,
  output wire tx,

  output wire led_1,
  output wire led_2
);

  reg send_next_byte;
  wire tx_done_flag, tx_active_flag;
  wire rx_done_flag;

  // buffer rx
  reg [7:0] temp_rx[0:7];
  reg [2:0] rx_counter = 0;

  // convert data_heart_rate of decimal to ascii characters
  reg [7:0] ascii_0, ascii_1, ascii_2, ascii_3, ascii_4; // ASCII digits
  reg [7:0] ch_temp0, ch_temp1, ch_hum0, ch_hum1;
  integer temp;
  reg [7:0] data_tx;
  wire [7:0] data_rx; // wire
  reg [2:0] tx_byte_counter; // Counter to keep track of which TX byte to send
  reg [2:0] rx_leds_byte_counter; // Counter to keep track of which RX byte to receive
  reg [7: 0] ascii_led_1, ascii_led_2;

  // leds
  reg led_1_state = 0;
  reg led_2_state = 0;
  assign led_1 = led_1_state;
  assign led_2 = led_2_state;


  /* handle timing to send data_heart_rate and data_spo2 by control send_next_byte. send every 1s */
  reg [31:0] counter = 0;
  reg [31:0] counter_1s = 10; // 1_000_000; // 1s
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      send_next_byte <= 0;
      counter <= 0;
    end else if (send) begin
      if (counter == counter_1s) begin
        send_next_byte <= 1;
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end


  /*TX handler*/
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ch_temp0 <= 8'h30; // ASCII '0'
      ch_temp1 <= 8'h30; // ASCII '0'
      ch_hum0 <= 8'h30; // ASCII '0'
      ch_hum1 <= 8'h30; // ASCII '0'

      data_tx <= 8'h30; // ASCII '0'
      send_next_byte <= 0;
      tx_byte_counter <= 0;
    end else if (send && !tx_active_flag && tx_done_flag) begin
      // If enable to send, the FSM is not in active mode and the previous ascii data has been sent, than send the next ascii data

      // Convert temperature data to ASCII : [ch_temp1][ch_temp0] e.g.: 05 (05 Celsius)
      temp = temperature;
      ch_temp1 = (temp % 10) + 8'h30; temp = temp / 10;
      ch_temp0 = (temp % 10) + 8'h30;

      // Convert humidity data to ASCII: [ch_hum0][ch_hum1] e.g.: 55 (98%)
      temp = humidity;
      ch_hum1 = (temp % 10) + 8'h30; temp = temp / 10;
      ch_hum0 = (temp % 10) + 8'h30;

      // We need to send 7 bytes of data
      // Format:      S:[ch_temp1][ch_temp0][ch_hum1][ch_hum0]\n
      // Sample 1:    S:0598\n (05 Celsius, 98%)
      // Sample 2:    S:1598\n (15 Celsius, 98%)
      case (tx_byte_counter)
        0: data_tx <= 8'h53;      // Command: ASCII of 'S'
        1: data_tx <= 8'h3A;      // Delimiter: ASCII of ':'
        2: data_tx <= ch_temp1;    // 1st ASCII of temperature
        3: data_tx <= ch_temp0;    // 2nd ASCII of temperature
        4: data_tx <= ch_hum1;    // 1st ASCII of humidity
        5: data_tx <= ch_hum0;    // 2nd ASCII of humidity
        6: data_tx <= 8'h0A;      // Newline ASCII of '\n'
      endcase

      $display("top_uart: Sending data: %c", data_tx);

      if (tx_byte_counter < 7) begin
        tx_byte_counter <= tx_byte_counter + 1;
      end else begin
        tx_byte_counter <= 0;
        send_next_byte <= 0; // Stop sending after the last byte
      end
    end
  end

  /*RX handler*/
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // data_rx <= 8'h30; // ASCII '0'

      // reset leds:
      led_1_state = 0;
      led_2_state = 0;
    end else if (rx_done_flag) begin
      // shift data_rx to temp_rx for other purposes:
      temp_rx[rx_counter] <= data_rx;
      rx_counter <= rx_counter + 1;
      if (rx_counter == 7) begin
        rx_counter <= 0;
      end

      // Finite state machine to detect if the received data is for controlling the LEDs:
      // LEDs controlling format: L:[ascii_led_1][ascii_led_2]\n. e.g.: L:01\n (LED 1 ON, LED 2 OFF)
      case (rx_leds_byte_counter)
      0: begin
        if (data_rx == 8'h4C) // Check for 'L' (led)
        rx_leds_byte_counter <= 1;
        else
        rx_leds_byte_counter <= 0; // Reset if not 'L'
      end
      1: begin
        if (data_rx == 8'h3A) // Check for ':'
        rx_leds_byte_counter <= 2;
        else
        rx_leds_byte_counter <= 0; // Reset if not ':'
      end
      2: begin
        ascii_led_1 <= data_rx; // Store first LED data
        rx_leds_byte_counter <= 3;
      end
      3: begin
        ascii_led_2 <= data_rx; // Store second LED data
        rx_leds_byte_counter <= 4;
      end
      4: begin
        if (data_rx == 8'h0A) begin // Check for '\n'
          // Data reception complete, process the received data
          rx_leds_byte_counter <= 0;

          // Handle the received data
          led_1_state <= (ascii_led_1 == 8'h31) ? 1'b1 : 1'b0; // ASCII '1' for ON
          led_2_state <= (ascii_led_2 == 8'h31) ? 1'b1 : 1'b0; // ASCII '1' for ON
        end else begin
        // If not '\n', reset the counter to start over
        rx_leds_byte_counter <= 0;
        end
      end
      endcase
    end
  end

  // Instantiate Duplex uart module
  Duplex UART_Driver (
    .reset_n        (rst_n),
    .send           (1), 
    .clock          (clk),
    .parity_type    (2'b01),        // ODD parity
    .baud_rate      (2'b10),        // 9600 baud
    .data_transmit  (data_tx),        // ASCII of 'U'
    .rx             (rx),
    //  Outputs
    .tx             (tx),
    .tx_active_flag (tx_active_flag),
    .tx_done_flag   (tx_done_flag),
    .rx_active_flag (),
    .rx_done_flag   (rx_done_flag),
    .data_received  (data_rx),
    .error_flag     ()
  );  

endmodule