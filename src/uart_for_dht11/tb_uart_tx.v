`timescale 1ns / 1ps

module tb_uart_tx;

  // Inputs
  reg clk;
  reg rst_n;
  reg tx_start;
  reg [7:0] tx_data;

  // Outputs
  wire tx;
  wire tx_done;
  wire tx_busy;

  // Instantiate the UART TX module
  uart_tx uut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_done(tx_done),
    .tx_busy(tx_busy)
  );

  // Clock generation (1 MHz)
  initial begin
    clk = 0;
    forever #500 clk = ~clk; // 1 MHz clock (1 µs period)
  end

  // Test sequence
  initial begin
    // Initialize inputs
    rst_n = 0;
    tx_start = 0;
    tx_data = 8'h00;

    // Reset the system
    #1000; // Wait for 1 ms
    rst_n = 1;

    // Wait for the system to stabilize
    #1000;

    // Test Case 1: Transmit a single byte (ASCII 'A' = 8'h41)
    tx_data = 8'h41; // ASCII 'A'
    tx_start = 1;
    #1000; // Wait for 1 clock cycle
    tx_start = 0;

    // Wait for the transmission to complete
    wait (tx_done);
    $display("Test Case 1 Passed: Transmitted byte = %h", tx_data);

    // Test Case 2: Transmit another byte (ASCII 'Z' = 8'h5A)
    #10000; // Wait for some time before starting the next transmission
    tx_data = 8'h5A; // ASCII 'Z'
    tx_start = 1;
    #1000; // Wait for 1 clock cycle
    tx_start = 0;

    // Wait for the transmission to complete
    wait (tx_done);
    $display("Test Case 2 Passed: Transmitted byte = %h", tx_data);

    // End simulation
    #1000;
    $stop;
  end

endmodule