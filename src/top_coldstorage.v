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
  wire [7:0] temperature_test = 8'h19; // 25
  wire [7:0] humidity_test = 8'h32; // 50

  // lcd 16x2
  wire [127:0] lcd_row1, lcd_row2;
  wire lcd_en;
  // sensor data
  wire [7:0] temperature, humidity;
  // uart
  // wire [6:0] max_temp, min_temp, max_hum, min_hum;
  wire [7:0] chr_cmd, chr_val0, chr_val1;
  wire rx_msg_done;

  logic_controller logic_controller_inst(
    .clk(clk),
    .rst_n(rst_n),
    .temperature(temperature_test),
    .humidity(humidity_test),
    // .max_temp(max_temp),
    // .min_temp(min_temp),
    // .max_hum(max_hum),
    // .min_hum(min_hum),
    .chr_cmd(chr_cmd),
    .chr_val0(chr_val0),
    .chr_val1(chr_val1),
    .rx_msg_done(rx_msg_done),
    .lcd_en(lcd_en),
    .lcd_row1(lcd_row1),
    .lcd_row2(lcd_row2),
    .led_fan(led_fan),
    .led_hum(led_hum)
  );

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
    .temperature(temperature_test),
    .humidity(humidity_test),
    .tx(tx),
    .rx(rx),
    // .max_temp(max_temp),
    // .min_temp(min_temp),
    // .max_hum(max_hum),
    // .min_hum(min_hum),
    .chr_cmd(chr_cmd),
    .chr_val0(chr_val0),
    .chr_val1(chr_val1),
    .rx_msg_done(rx_msg_done)
    // .led_fan(led_fan),
    // .led_hum(led_hum)
  );

  lcd_16x2 lcd_16x2_inst(
    .clk_1MHz(clk_1MHz),
    .rst_n(rst_n),
    .ena(lcd_en),
    .row1(lcd_row1),
    .row2(lcd_row2),
    .sda(sda_lcd),
    .scl(scl_lcd)
  );  

endmodule