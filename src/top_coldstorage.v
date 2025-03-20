// `timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Top-Level Module: top_coldstorage
// Description: perform the following tasks:
// 1. Read data from DHT11 sensor to get temperature and humidity
// 2. Send temperature and humidity data to UART
// 3. Control the LED indicators based on the temperature and humidity data
// 4. Show temperature and humidity data on the LCD
// 5. Control the cooling fan and humidifier based on the temperature and humidity data
////////////////////////////////////////////////////////////////////////////////


module top_coldstorage(
  input         clk,          // Main clock from zynq - 100 MHz
  input         rst_n,        // Reset active high

  // dht11 sensor for temperature and humidity
  inout         dht11_data,

  // led indicators
  output        led_mod,        // mode (1/0): auto/manual
  output        led_fan,        // cooling fan (1/0): on/off
  output        led_hum,        // humidifier (1/0): on/off

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


  // instantiate dht11_reader
  wire [7:0] temperature, humidity;
  wire dht11_data_ready;
  // we need an enable signal to control the DHT11 reader
  wire dht11_enable;
  dht11_reader dht11_reader_inst(
    .en(dht11_enable),
    .clk(clk_1MHz),
    .dht_data(dht11_data),
    .temperature(temperature),
    .humidity(humidity),
    .data_ready(dht11_data_ready)
  );


  // instantiate top_uart_for_dht11
  wire led_1, led_2;
  // enable signal for sending data to uart
  wire uart_tx_en; // enable signal for uart tx
  top_uart_for_dht11 top_uart_inst(
    .clk(clk_1MHz),
    .send(uart_tx_en),
    .rst_n(rst_n),
    .temperature(temperature),
    .humidity(humidity),
    .rx(rx),
    .tx(tx),
    .led_1(led_1),
    .led_2(led_2)
  );

  // instantiate lcd display
  // wire done_display;
  // lcd_display_max30100 lcd_display_inst (
  //   .clk_1MHz(clk_1MHz),
  //   .rst_n(rst_n),    // rst_n active low
  //   .heart_rate(heart_rate),
  //   .spo2(spo2),
  //   .sda_lcd(sda_lcd),
  //   .scl_lcd(scl_lcd),
  //   .done(done_display)            // Flag done không được xuất ra ngoài
  // );


  // led indicators
  assign led_mod = led_1;
  assign led_fan = led_2;
  assign led_hum = led_1;


  ////////////////////////////
  // Logic control
  ////////////////////////////
  // send DHT11 data to uart every 1s:
  reg [31:0] counter_uart = 0;
  reg [31:0] counter_uart_1s = 10; // 1_000_000; // 1s
  // reg dht11_enable_reg = 0; // enable signal for DHT11 reader
  always @(posedge clk_1MHz or negedge rst_n) begin
    if (!rst_n) begin
      counter_uart <= 0;
      dht11_enable <= 0;
      dht11_data_ready <= 0;
    end else begin
      if (counter_uart == counter_uart_1s) begin
        counter_uart <= 0;
        dht11_enable <= 1;
      end else begin
        counter_uart <= counter_uart + 1;
      end
    end

    // wait for dht11 data ready, then trigger the uart
    if (dht11_data_ready) begin
      dht11_enable <= 0;
      counter_uart <= 0;
    end
  end

endmodule