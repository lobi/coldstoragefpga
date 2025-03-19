`timescale 1ns / 1ps

module tb_top_uart;

  // Inputs
  reg clk;
  reg rst_n;
  reg [15:0] data_heart_rate;
  reg [7:0] data_spo2;
  reg rx;

  // Outputs
  wire tx;
  wire led_1;
  wire led_2;

  // Instantiate the Unit Under Test (UUT)
  top_uart uut (
    .clk(clk), 
    .rst_n(rst_n), 
    .data_heart_rate(data_heart_rate), 
    .data_spo2(data_spo2), 
    .rx(rx), 
    .tx(tx), 
    .led_1(led_1), 
    .led_2(led_2)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    $display("top_uart testbench started.");
    // Initialize Inputs
    clk = 0;
    rst_n = 0;
    data_heart_rate = 0;
    data_spo2 = 0;
    rx = 1;

    // Wait for global reset
    #100;
    rst_n = 1;

    // Test case 1: Send heart rate and SpO2 data
    data_heart_rate = 16'd75; // 75 bpm
    data_spo2 = 8'd98; // 98% SpO2
    #1000000; // Wait for 1 second

    // Test case 2: Send another set of heart rate and SpO2 data
    data_heart_rate = 16'd125; // 125 bpm
    data_spo2 = 8'd80; // 80% SpO2
    // #1000000; // Wait for 1 second
    # 100

    // Test case 3: Simulate receiving data to control LEDs
    $display("top_uart testbench: Simulating receiving data to control LEDs");
    rx = 0; #104167; // Start bit
    rx = 1; #104167; // 'L'
    rx = 0; #104167; // 'L'
    rx = 1; #104167; // ':'
    rx = 0; #104167; // '0'
    rx = 1; #104167; // '0'
    rx = 0; #104167; // '0'
    rx = 1; #104167; // '0'
    rx = 0; #104167; // '0'
    rx = 1; #104167; // '\n'
    rx = 1; #104167; // Stop bit

    // Wait for some time to observe the results
  #100000;

    // Finish simulation
    $display("top_uart testbench finished.");
    $finish;
  end

endmodule