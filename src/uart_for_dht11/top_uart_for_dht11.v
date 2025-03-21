/* 
  
*/
module top_uart_for_dht11(
  input wire clk_100Mhz,
  input wire rst_n,
  input wire send, // enable signal for sending data to uart

  input wire [7: 0] temperature,//data_heart_rate,
  input wire [7: 0] humidity,//data_spo2,

  input wire rx,
  output wire tx,
  output reg tx_str_ready,

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

  /*
  reg [6:0] message [0:7];
  initial begin
    send_next_byte = 0;
    tx_str_ready = 0;
    tx_byte_counter = 0;
    rx_leds_byte_counter = 0;

    // S:[temperature_high][temperature_low][humidity_high][humidity_low]\n
    message[0] = 8'h53; // ASCII 'S'
    message[1] = 8'h3A; // ASCII ':'
    message[2] = 8'h30; // ASCII '0'
    message[3] = 8'h30; // ASCII '0'
    message[4] = 8'h30; // ASCII '0'
    message[5] = 8'h30; // ASCII '0'
    message[6] = 8'h0A; // ASCII '\n'
  end
  */


  /* handle timing to send data_heart_rate and data_spo2 by control send_next_byte. send every 1s */
  /*
  reg [31:0] counter = 0;
  reg [31:0] counter_1s = 1_000_000; // 1_000_000; // 1s
  always @(posedge clk_100Mhz or negedge rst_n) begin
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
  */

  /*
  TX Handler:
  Send a string of ASCII characters to the UART module.
  The ASCII string is formatted as follows: S:[temperature_high][temperature_low][humidity_high][humidity_low]\n
  For example, if the temperature is 25 degrees Celsius and the humidity is 50%, the ASCII string would be: S:2550\n
  */
  always @(posedge clk_100Mhz or negedge rst_n) begin
    if (!rst_n) begin
      tx_str_ready <= 0;
      tx_byte_counter <= 0;
      data_tx <= 8'h30; // ASCII '0'
      send_next_byte <= 0; // Reset send_next_byte to 0 on reset
    end else if (send) begin
      // Finite state machine to send the temperature and humidity data

      if (send_next_byte) begin
        // 1. Update current data_tx
        case (tx_byte_counter)
        0: begin
          data_tx <= 8'h53; // ASCII 'S'
          tx_byte_counter <= 1;
        end
        1: begin
          // Convert temperature to ASCII characters
          temp = temperature;
          ch_temp0 = temp % 10;
          ch_temp1 = temp / 10;
          ascii_0 = ch_temp0 + 8'h30; // Convert to ASCII
          ascii_1 = ch_temp1 + 8'h30; // Convert to ASCII
          data_tx <= ascii_1;
          tx_byte_counter <= 2;
        end
        2: begin
          data_tx <= ascii_0;
          tx_byte_counter <= 3;
        end
        3: begin
          // Convert humidity to ASCII characters
          temp = humidity;
          ch_hum0 = temp % 10;
          ch_hum1 = temp / 10;
          ascii_2 = ch_hum0 + 8'h30; // Convert to ASCII
          ascii_3 = ch_hum1 + 8'h30; // Convert to ASCII
          data_tx <= ascii_3;
          tx_byte_counter <= 4;
        end
        4: begin
          data_tx <= ascii_2;
          tx_byte_counter <= 5;
        end
        5: begin
          data_tx <= 8'h0A; // ASCII '\n'
          tx_byte_counter <= 0;
          tx_str_ready <= 1;
        end
        endcase
      end

      // 2. Check if UART is not busy(not in active) to send the next byte
      if (!tx_active_flag == 0) begin
        send_next_byte <= 1;
        if (tx_str_ready) begin
          tx_str_ready <= 0; // Reset tx_str_ready after being set
        end
      end else begin
        send_next_byte <= 0;
      end

    end
  end


  /*RX handler*/
  always @(posedge clk_100Mhz or negedge rst_n) begin
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
    .send           (send_next_byte), 
    .clock          (clk_100Mhz),
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