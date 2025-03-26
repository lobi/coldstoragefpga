module uart_rx (
  input wire clk,             // System clock
  input wire rst_n,           // Reset signal
  input wire rx,              // UART RX input
  output reg [7:0] data_out,  // Received data byte
  output reg rx_busy,         // Indicates if receiving is active
  output reg done             // Indicates a valid received byte
);

  parameter CLK_FREQ = 1_000_000;                 // System clock frequency
  parameter BAUD_RATE = 9600;
  localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;   // Clock cycles per bit

  reg [9:0] rx_shift_reg;   // Shift register for start bit, 8 data bits, stop bit
  reg [3:0] bit_index;      // Tracks received bits (0-9)
  reg [15:0] clk_count;     // Clock counter for baud rate timing

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_busy <= 0;
      clk_count <= 0;
      bit_index <= 0;
      done <= 1'b0; // Reset done signal after stop bit validation
    end else begin
      if (!rx_busy && !rx) begin
        // Start bit detected (low signal)
        rx_busy <= 1'b1;
        done <= 1'b0;
        clk_count <= BIT_PERIOD / 2; // Align to middle of start bit
        bit_index <= 0;
      end

      if (rx_busy) begin
        if (clk_count < BIT_PERIOD - 1) begin
          clk_count <= clk_count + 1;
        end else begin
          clk_count <= 0;
          rx_shift_reg[bit_index] <= rx; // Shift in received bit
          bit_index <= bit_index + 1;

          if (bit_index == 9) begin
            if (rx_shift_reg[9] == 1'b1) begin // Validate stop bit
              rx_busy <= 1'b0;
              done <= 1'b1; // Set done signal when a valid byte is received
              data_out <= rx_shift_reg[8:1]; // Extract only data bits
            end else begin
              rx_busy <= 1'b0; // Stop bit error, reset reception
              done <= 1'b0;
            end
          end
        end
      end else begin
        if (done) begin
          done <= 1'b0; // Ensure done is cleared after being read
        end
      end
    end
  end

endmodule