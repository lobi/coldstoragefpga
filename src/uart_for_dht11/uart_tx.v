module uart_tx(
  input  wire clk,              // System clock: 1MHz
  input  wire rst_n,            // Reset signal
  input  wire tx_start,         // Start transmission signal
  input  wire [7:0] tx_data,    // Data to be transmitted
  output reg tx,                // UART TX output
  output reg tx_done,           // Transmission done flag
  output reg tx_busy            // Transmission busy flag
);

  parameter CLK_FREQ = 1_000_000; // 1 MHz clock
  parameter BAUD_RATE = 9600;
  localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE; // Clock cycles per bit

  reg [3:0] bit_index;     // Current bit index (0-9 for start, 8 data bits, stop bit)
  reg [15:0] clk_count;    // Clock cycle counter
  reg [9:0] tx_shift_reg;  // Shift register including start & stop bits

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx <= 1;          // Idle state is HIGH
      tx_busy <= 0;
      bit_index <= 0;
      clk_count <= 0;
      tx_done <= 0;
    end else begin
      if (tx_start && !tx_busy) begin
        tx_shift_reg <= {1'b1, tx_data, 1'b0}; // Start bit (0) + Data + Stop bit (1)
        tx_busy <= 1'b1;
        bit_index <= 0;
        clk_count <= 0;
        tx_done <= 0;
      end

      if (tx_busy) begin
        if (clk_count < BIT_PERIOD - 1) begin
          clk_count <= clk_count + 1;
        end else begin
          clk_count <= 0;
          tx <= tx_shift_reg[bit_index]; // Send next bit
          bit_index <= bit_index + 1;

          if (bit_index == 9) begin
            tx_busy <= 1'b0; // End transmission after stop bit
            tx_done <= 1;
          end
        end
      end
    end
  end
endmodule