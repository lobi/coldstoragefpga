`timescale 1us/1ns  // Adjust timing scale for accurate simulation

module dht11_testbench;
  reg clk;
  wire dht_data;
  wire [7:0] humidity;
  wire [7:0] temperature;
  wire data_ready;
  
  reg dht_data_reg;
  assign dht_data = dht_data_reg ? 1'bz : 1'b0;  // Simulate open-drain behavior
  
  dht11_reader uut (
    .clk(clk),
    .dht_data(dht_data),
    .humidity(humidity),
    .temperature(temperature),
    .data_ready(data_ready)
  );
  
  initial begin
    clk = 0;
    dht_data_reg = 1;
    #1000; // Wait 1ms before starting simulation
    
    // Simulate DHT11 response
    force dht_data = 0; // DHT11 pulls low for 80us
    #80;
    force dht_data = 1; // DHT11 pulls high for 80us
    #80;
    
    // Send 40-bit data (Humidity = 50, Temperature = 25, Checksum = 75)
    send_dht11_bit(8'h32); // Humidity High = 50
    send_dht11_bit(8'h00); // Humidity Low  = 0
    send_dht11_bit(8'h19); // Temperature High = 25
    send_dht11_bit(8'h00); // Temperature Low  = 0
    send_dht11_bit(8'h4B); // Checksum = 50 + 0 + 25 + 0 = 75

    release dht_data; // Release bus
  end
  
  // Clock generator (10MHz)
  always #50 clk = ~clk;
  
  // Task to send a byte (8-bits) following DHT11 protocol
  task send_dht11_bit(input [7:0] data);
    integer i;
    for (i = 7; i >= 0; i = i - 1) begin
      force dht_data = 0;
      #50; // 50us low (start of bit)
      force dht_data = data[i];
      if (data[i])
        #70; // '1' bit: high for 70us
      else
        #26; // '0' bit: high for 26us
      release dht_data;
      #10;  // Short gap
    end
  endtask
endmodule
