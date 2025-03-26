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
  output        led1_test,    // Test LED 1
  output        led2_test,    // Test LED 2

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

  // data test for temperature, humidity: 33 celcius, 10%
  // wire [7:0] temperature_test = 8'h21; // 33
  // wire [7:0] humidity_test = 8'h28; // 40

  // lcd 16x2
  wire [127:0] lcd_row1, lcd_row2;
  wire lcd_en, lcd_busy;
  // sensor data
  wire [7:0] temperature, humidity;
  wire dht_en, dht_data_ready;
  // uart
  // wire [6:0] max_temp, min_temp, max_hum, min_hum;
  wire [7:0] chr_cmd, chr_val0, chr_val1;
  wire rx_msg_done, en_tx, tx_msg_done;

  logic_controller logic_controller_inst(
    .clk(clk_1MHz),
    .rst_n(rst_n),

    // dht:
    .temperature(temperature),
    .humidity(humidity),
    .dht_en(dht_en),
    .dht_data_ready(dht_data_ready),

    // uart:
    .chr_cmd(chr_cmd),
    .chr_val0(chr_val0),
    .chr_val1(chr_val1),
    .en_tx(en_tx),
    .rx_msg_done(rx_msg_done),
    .tx_msg_done(tx_msg_done),

    // lcd:
    .lcd_en(lcd_en),
    .lcd_row1(lcd_row1),
    .lcd_row2(lcd_row2),

    // led:
    .led_fan(led_fan),
    .led_hum(led_hum)
  );

  dht11_reader dht11_reader_inst(
    .clk(clk_1MHz),
    .rst_n(rst_n),
    .en(dht_en),
    .dht_data(dht11_data),
    .led1_test(led1_test),
    .led2_test(led2_test),
    .temperature(temperature),
    .humidity(humidity),
    .data_ready(dht_data_ready)
  );

  uart_string uart_string_inst(
    .clk_1Mhz(clk_1MHz),
    .rst_n(rst_n),
    .temperature(temperature),
    .humidity(humidity),
    .en_tx(en_tx),
    .tx_msg_done(tx_msg_done),
    .tx(tx),
    .rx(rx),
    .fan_state(led_fan),
    .hum_state(led_hum),
    .chr_cmd(chr_cmd),
    .chr_val0(chr_val0),
    .chr_val1(chr_val1),
    .rx_msg_done(rx_msg_done)
  );

  lcd_16x2 lcd_16x2_inst(
    .clk_1MHz(clk_1MHz),
    .rst_n(rst_n),
    .lcd_ena(lcd_en),
    .row1(lcd_row1),
    .row2(lcd_row2),
    .busy(lcd_busy),
    .sda(sda_lcd),
    .scl(scl_lcd)
  );  

endmodule