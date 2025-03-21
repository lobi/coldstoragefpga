/*
  This module is used to send/receive string of ascii characters to/from the UART module
  - TX: The ascii string is formatted as follows: S:[temperature_high][temperature_low][humidity_high][humidity_low]\n
  - Rx: LEDs controlling format: L:[ascii_led_1][ascii_led_2]\n. e.g.: L:01\n (LED 1 ON, LED 2 OFF)
*/
module uart_string(
  input wire clk_100Mhz,
  input wire rst_n,

  input wire [7: 0] temperature,//data_heart_rate,
  input wire [7: 0] humidity,//data_spo2,

  input wire rx,
  output wire tx,

  output wire led_1,
  output wire led_2
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
  always @(posedge clk_100Mhz or negedge rst_n) begin
    if (!rst_n) begin
      tx_msg[0] = 8'h53; // ASCII 'S'
      tx_msg[1] = 8'h3A; // ASCII ':'
      tx_msg[2] = 8'h30; // ASCII '0'
      tx_msg[3] = 8'h30; // ASCII '0'
      tx_msg[4] = 8'h30; // ASCII '0'
      tx_msg[5] = 8'h30; // ASCII '0'
      tx_msg[6] = 8'h0A; // ASCII '\n'

      tx_index <= 0;
      send_start <= 0;
      timer_count <= 0;
    end else begin
      // disable sending when tx_done
      if (tx_done) begin
        send_start <= 0;
      end

      // Timer logic for 1-second interval
      if (timer_count < SEND_INTERVAL - 1 && tx_index == 0) begin
        timer_count <= timer_count + 1;
      end else begin
        timer_count <= 0;   // Reset timer after 1 second
        // Send 7 bytes of data, one by one
        if (!tx_busy) begin
          // tx_index <= 0;    // Reset character index
          send_start <= 1;  // Start sending

          // update current data of temperature and humidity
          // Convert temperature & humidity to ASCII characters
          tx_msg[2] <= temperature / 10 + 8'h30;
          tx_msg[3] <= temperature % 10 + 8'h30;
          tx_msg[4] <= humidity / 10 + 8'h30;
          tx_msg[5] <= humidity % 10 + 8'h30;
        end
      end

      // Sending character logic
      if (send_start && tx_done) begin
        tx_data <= tx_msg[tx_index]; // Load character to send
        tx_index <= (tx_index < 7) ? tx_index + 1 : 0; // Increment or reset index
        send_start <= (tx_index < 7); // Continue sending until all characters are sent
      end
    end
  end

  /*
  Rx Handler
  */
  reg [7:0] rx_msg [0:4]; // Buffer for received 5 characters
  reg [3:0] rx_index;  // Index for 4 characters
  wire [7:0] data_rx;
  reg led_1_reg, led_2_reg;
  assign led_1 = led_1_reg;
  assign led_2 = led_2_reg;
  wire rx_busy;
  always @(posedge clk_100Mhz or negedge rst_n) begin
    if (!rst_n) begin
      rx_index <= 0;
      
      rx_msg[0] <= 8'h4C; // ASCII 'L'
      rx_msg[1] <= 8'h3A; // ASCII ':'
      rx_msg[2] <= 8'h30; // ASCII '0'
      rx_msg[3] <= 8'h30; // ASCII '0'
      rx_msg[4] <= 8'h0A; // ASCII '\n'
    end else if (rx_done && !rx_busy) begin
      if (rx_index == 4) begin
        rx_index <= 0; // Reset index after receiving all characters
        // let proceed logic base on rx_msg
        
        // Control LEDs based on received ASCII values
        led_1_reg <= (rx_msg[2] != 8'h30); // Turn on if not '0'
        led_2_reg <= (rx_msg[3] != 8'h30); // Turn on if not '0'

      end else begin
        rx_msg[rx_index] <= data_rx;
        rx_index <= rx_index + 1;
      end
    end
  end

  TxUnit Transmitter(
    //  Inputs
    .reset_n(rst_n),
    .send(send_start),
    .clock(clk_100Mhz),
    .parity_type(parity_type),
    .baud_rate(baud_rate),
    .data_in(tx_data),

    //  Outputs
    .data_tx(tx),
    .active_flag(tx_busy),
    .done_flag(tx_done)
  );
  
  RxUnit Reciever(
    //  Inputs
    .reset_n(rst_n),
    .clock(clk_100Mhz),
    .parity_type(parity_type),
    .baud_rate(baud_rate),
    .data_tx(rx),

    //  Outputs
    .data_out(data_rx),
    .error_flag(),
    .active_flag(rx_busy),
    .done_flag(rx_done)
  );

endmodule