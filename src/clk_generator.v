module clk_generator #(
  parameter INPUT_FREQ = 100_000_000, // Default input clock frequency: 100 MHz
  parameter OUTPUT_FREQ = 1_000_000   // Default output clock frequency: 1 MHz
)(
  input wire clk_in,       // Input clock
  input wire rst_n,        // Reset signal
  output reg clk_out       // Output divided clock
);
  localparam DIV_FACTOR = INPUT_FREQ / OUTPUT_FREQ; // Calculate division factor
  localparam COUNTER_WIDTH = $clog2(DIV_FACTOR);    // Width of the counter
  reg [COUNTER_WIDTH-1:0] counter;                 // Counter for clock division

  always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 0;
      clk_out <= 0;
    end else begin
      if (counter == (DIV_FACTOR/2 - 1)) begin
        clk_out <= ~clk_out;
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end
endmodule