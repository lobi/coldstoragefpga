`timescale 1ns / 1ps
/*
  * UART String Testbench (only for RX)
  * Description: This testbench sends a string "L1:0\n" to the UART String module and checks the LED outputs.
  * L1:0\n means LED 1 is ON and LED 2 is OFF.
*/
module tb_uart_string;

  // Inputs
  reg clk_100Mhz;
  reg rst_n;
  reg rx;

  // Outputs
  wire led_fan;
  wire led_hum;

  // Instantiate the UART String module
  uart_string uut (
    .clk_100Mhz(clk_100Mhz),
    .rst_n(rst_n),
    .rx(rx),
    .led_fan(led_fan),
    .led_hum(led_hum)
  );

  // Clock generation (100 MHz)
  initial begin
    clk_100Mhz = 0;
    forever #5 clk_100Mhz = ~clk_100Mhz; // 10 ns period (100 MHz)
  end

  // Task to send a UART byte
  task send_uart_byte;
    input [7:0] data;
    integer i;
    begin
      // Start bit
      rx = 0;
      #(104167); // 1/9600 baud rate = 104.167 us

      // Send 8 data bits (LSB first)
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        #(104167);
      end

      // Stop bit
      rx = 1;
      #(104167);
    end
  endtask

  // Test sequence
  initial begin
    // Initialize inputs
    rx = 1; // Idle state for UART
    rst_n = 0;

    // Reset the system
    #100;
    rst_n = 1;

    // Wait for the system to stabilize
    #100;

    // Send the string "L1:0\n" via UART
    send_uart_byte(8'h4C); // 'L'
    send_uart_byte(8'h31); // '1'
    send_uart_byte(8'h3A); // ':'
    send_uart_byte(8'h30); // '0'
    send_uart_byte(8'h0A); // '\n'

    // Wait for the FSM to process the string
    #1000;

    // Check the LED outputs
    if (led_fan == 1 && led_hum == 0) begin
      $display("Test Passed: LED states are correct.");
    end else begin
      $display("Test Failed: LED states are incorrect.");
    end

    // End simulation
    #100;
    $stop;
  end

endmodule