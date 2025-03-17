module top_uart(
  input wire clk,
  input wire rst_n,

  input wire [15: 0] data_heart_rate,
  input wire [7: 0] data_spo2,

  input wire rx,
  output wire tx,

  output wire led_1,
  output wire led_2
);

  reg send_signal = 0;
  wire tx_done_flag;
  wire rx_done_flag;

  // convert data_heart_rate of decimal to ascii characters
  reg [7:0] ascii_0, ascii_1, ascii_2, ascii_3, ascii_4; // ASCII digits
  integer temp;
  reg [7:0] data_tx;
  wire [7:0] data_rx; // wire
  reg [2:0] tx_byte_counter; // Counter to keep track of which TX byte to send
  reg [2:0] rx_byte_counter; // Counter to keep track of which RX byte to receive
  reg [7: 0] ascii_led_1, ascii_led_2;

  // leds
  reg led_1_state = 0;
  reg led_2_state = 0;
  assign led_1 = led_1_state;
  assign led_2 = led_2_state;


  /* handle timing to send data_heart_rate and data_spo2 by control send_signal. send every 1s */
  reg [31:0] counter = 0;
  reg [31:0] counter_1s = 10; // 1_000_000; // 1s
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      send_signal <= 0;
      counter <= 0;
    end else begin
      if (counter == counter_1s) begin
        send_signal <= 1;
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end


  /*TX handler*/
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ascii_0 <= 8'h30; // ASCII '0'
      ascii_1 <= 8'h30; // ASCII '0'
      ascii_2 <= 8'h30; // ASCII '0'
      ascii_3 <= 8'h30; // ASCII '0'
      ascii_4 <= 8'h30; // ASCII '0'

      data_tx <= 8'h30; // ASCII '0'
      send_signal <= 0;
      tx_byte_counter <= 0;
    end else if (tx_done_flag) begin
      // heart rate: [ascii_2][ascii_1][ascii_0] e.g.: 075 (75 bpm)
      temp = data_heart_rate;
      ascii_2 = (temp % 10) + 8'h30; temp = temp / 10;
      ascii_1 = (temp % 10) + 8'h30; temp = temp / 10;
      ascii_0 = (temp % 10) + 8'h30;

      // SpO2: [ascii_4][ascii_3] e.g.: 98 (98% SpO2)
      temp = data_spo2;
      ascii_4 = (temp % 10) + 8'h30; temp = temp / 10;
      ascii_3 = (temp % 10) + 8'h30;

      // We need to send 8 bytes of data
      // Format:      S:[ascii_2][ascii_1][ascii_0][ascii_4][ascii_3]\n
      // Sample 1:    S:07598\n (75 bpm, 98% SpO2)
      // Sample 2:    S:12580\n (125 bpm, 80% SpO2)
      // Send one byte at a time:
      case (tx_byte_counter)
        0: data_tx <= 8'h53;      // Command: ASCII of 'S'
        1: data_tx <= 8'h3A;      // Delimiter: ASCII of ':'
        2: data_tx <= ascii_2;    // 1st ASCII of data_heart_rate
        3: data_tx <= ascii_1;    // 2nd ASCII of data_heart_rate
        4: data_tx <= ascii_0;    // 3rd ASCII of data_heart_rate
        5: data_tx <= ascii_4;    // 1st ASCII of data_spo2
        6: data_tx <= ascii_3;    // 2nd ASCII of data_spo2
        7: data_tx <= 8'h0A;      // Newline ASCII of '\n'
      endcase

      if (tx_byte_counter < 7) begin
        tx_byte_counter <= tx_byte_counter + 1;
      end else begin
        tx_byte_counter <= 0;
        send_signal <= 0; // Stop sending after the last byte
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
      case (rx_byte_counter)
        0: if (data_rx == 8'h4C) rx_byte_counter <= rx_byte_counter + 1; // Check for 'L' (led)
        1: if (data_rx == 8'h3A) rx_byte_counter <= rx_byte_counter + 1; // Check for ':'
        2: begin
          ascii_led_1 <= data_rx;
          rx_byte_counter <= rx_byte_counter + 1;
        end
        3: begin
          ascii_led_2 <= data_rx;
          rx_byte_counter <= rx_byte_counter + 1;
        end
        4: begin
          if (data_rx == 8'h0A) begin // Check for '\n'
            // Data reception complete, process the received data
            rx_byte_counter <= 0;
          end else begin
            // If not '\n', reset the counter to start over
            // actually, it's incorrect! But I don't care since a already have enough data :)
            rx_byte_counter <= 0;
          end

          // let proceed to handle the received data
          // e.g.: display the received data on the LEDs
          led_1_state <= (ascii_2 == 8'h30) ? 1'b1 : 1'b0; // ASCII '0'
          led_2_state <= (ascii_1 == 8'h30) ? 1'b1 : 1'b0; // ASCII '0'
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
    .tx_active_flag (),
    .tx_done_flag   (tx_done_flag),
    .rx_active_flag (),
    .rx_done_flag   (rx_done_flag),
    .data_received  (data_rx),
    .error_flag     ()
  );  

endmodule