`timescale 1ns / 1ps

module tb_TxUnit;

  // Inputs
  reg reset_n = 0;
  reg send = 0;
  reg clock = 0;
  reg [1:0] parity_type;
  reg [1:0] baud_rate;
  reg [7:0] data_in;

  // Outputs
  wire tx;
  // wire active_flag;
  wire done_flag;
  wire baud_clk_w;

  // Instantiate the Unit Under Test (UUT)
  TxUnit uut (
    .reset_n(reset_n), 
    .send(send), 
    .clock(clock), 
    .parity_type(parity_type), 
    .baud_rate(baud_rate), 
    .data_in(data_in), 
    .data_tx(tx), 
    .active_flag(), 
    .done_flag(done_flag),
    .baud_clk_w(baud_clk_w)
  );

  // Clock generation
  // always #5 clock = ~clock;
  // generate clock 100Mhz
  always #5 clock = ~clock;

  initial begin
    $display("TxUnit testbench started.");
    // Initialize Inputs
    reset_n = 0;
    send = 1;
    clock = 0;
    parity_type = 2'b01; // No parity
    baud_rate = 2'b11; // 9600 baud
    //data_in = 8'h00;

    // Wait for global reset
    // #10;
    // reset_n = 1;
    #10;
    reset_n = 1;

    // Test case 1: Send data with no parity
    data_in = 8'hA5; // Example data
    // send = 1;

    $display("TxUnit testbench waiting for test case 1 ...");
    // Wait for transmission to complete
    wait(done_flag == 1);
    #100;

    // Test case 2: Send data with even parity
    //parity_type = 2'b10; // Even parity
    data_in = 8'h3C; // Example data
    send = 1;
    #10;
    //send = 0;

    // Wait for transmission to complete
    wait(done_flag == 1);
    #100;

    // Test case 3: Send data with odd parity
    //parity_type = 2'b01; // Odd parity
    data_in = 8'h7E; // Example data
    //send = 1;
    #10;
    //send = 0;

    // Wait for transmission to complete
    $display("TxUnit testbench waiting for test case 3...");
    wait(done_flag == 1);
    #100;

    $display("TxUnit testbench finished.");
    // Finish simulation
    $finish;
  end

endmodule