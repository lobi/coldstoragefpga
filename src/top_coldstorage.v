// `timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Top-Level Module: top_coldstorage
// Description: perform the following tasks:
// 1. Read data from DHT11 sensor to get temperature and humidity
// 2. Send temperature and humidity data to UART
// 3. Control the LED indicators based on the temperature and humidity data
// 4. Show temperature and humidity data on the LCD
// 5. Control the cooling fan and humidifier based on the temperature and humidity data
//
// Communication protocols: I2C for LCD, UART for ESP8266, GPIO for DHT11 sensor
////////////////////////////////////////////////////////////////////////////////


module top_coldstorage(
  input         clk,          // Main clock from zynq - 100 MHz
  input         rst_n,        // Reset active high

  inout         dht11_data,   // bi-directional data line for DHT11

  // led indicators
  output        led_fan,      // cooling fan (1/0): on/off
  output        led_hum,      // humidifier (1/0): on/off

  // i2c for lcd
  inout         sda_lcd,
  output        scl_lcd,
    
  // uart
  input         rx,
  output        tx
);

  // generate 1 MHz clock
  wire clk_1MHz;
  clk_divider clk_divider_inst(
    .clk(clk),
    .clk_1MHz(clk_1MHz)
  );

  // data test for temperature, humidity:
  // wire [7:0] temperature_test = 8'h19; // 25
  // wire [7:0] humidity_test = 8'h32; // 50

  // instantiate dht11_reader
  wire [7:0] temperature, humidity;
  dht11_reader dht11_reader_inst(
    .en(1'b1),
    .clk(clk),
    .dht_data(dht11_data),
    .temperature(temperature),
    .humidity(humidity),
    .data_ready()
  );

  uart_string uart_string_inst(
    .clk_100Mhz(clk),
    .rst_n(rst_n),
    .temperature(p),
    .humidity(humidity),
    .rx(rx),
    .tx(tx),
    .led_fan(led_fan),
    .led_hum(led_hum)
  );

  top_lcd top_lcd_inst(
    .clk(clk),
    .rst_n(rst_n),
    .temperature(p),
    .humidity(humidity),
    .sda(sda_lcd),
    .scl(scl_lcd)
  );  

endmodule