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
  // output        led_mod,        // mode (1/0): auto/manual
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

  // data test for temperature, humidity:
  wire [7:0] temperature_test = 8'h19; // 25
  wire [7:0] humidity_test = 8'h32; // 50
  wire dht11_data_ready_test = 1;

  // instantiate dht11_reader
  wire [7:0] temperature, humidity;
  /*
  wire dht11_data_ready = 0;
  // we need an enable signal to control the DHT11 reader
  wire dht11_enable = 0; // Correctly declared as reg for procedural assignment
  reg dht11_enable_reg = 0; // enable signal for DHT11 reader
  assign dht11_enable = dht11_enable_reg; // Correctly declared as reg for procedural assignment
  dht11_reader dht11_reader_inst(
    .en(dht11_enable),
    .clk(clk_1MHz),
    .dht_data(dht11_data),
    .temperature(temperature),
    .humidity(humidity),
    .data_ready(dht11_data_ready)
  );
  */

  DHT11 dht11_inst(
    .clk_1MHz(clk_1MHz),
    .rst_n(rst_n),
    .signal(dht11_data),
    .humidity(humidity_test),
    .temperature(temperature_test)
  );


  // instantiate top_uart_for_dht11
  wire led_1, led_2;
  assign led_fan = led_2;
  assign led_hum = led_1;

  uart_string uart_string_inst(
    .clk_100Mhz(clk),
    .rst_n(rst_n),
    .temperature(temperature_test),
    .humidity(humidity_test),
    .rx(rx),
    .tx(tx),
    .led_1(led_1),
    .led_2(led_2)
  );

  top_lcd top_lcd_inst(
    .clk(clk),
    .rst_n(rst_n),
    .temperature(temperature),
    .humidity(humidity),
    .sda(sda_lcd),
    .scl(scl_lcd)
  );

  /////////////////////////////////////////////////////////////////////////////
  //                            Logic control                                //
  /////////////////////////////////////////////////////////////////////////////
  // send DHT11 data to uart every 1s:
  // reg [31:0] counter_uart = 0;
  // reg [31:0] counter_uart_1s = 1_000_000; // 1_000_000; // 1s
  /*
  This block to control enable signal for UART tx every 1s
  Condition: 
    - Check every 1s
    - dht11 data ready: dht11_enable_reg == 1
    - uart tx str ready: tx_str_ready == 1
  */
  /*
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      uart_tx_en <= 0;
      counter_uart <= 0;
    end else begin
      if (counter_uart == counter_uart_1s) begin
        if (dht11_data_ready_test == 1 && tx_str_ready == 1) begin
          uart_tx_en <= 1;
        end else begin
          uart_tx_en <= 0;
        end
        counter_uart <= 0;
      end else begin
        counter_uart <= counter_uart + 1;
      end
    end
  end
  */
  /*
  always @(posedge clk_1MHz or negedge rst_n) begin
    if (!rst_n) begin
      counter_uart <= 0;
      dht11_enable_reg <= 0;
      uart_tx_en <= 0;
    end else begin
      if (counter_uart == counter_uart_1s) begin
        counter_uart <= 0;
        dht11_enable_reg <= 1; // enable DHT11 reader
      end else begin
        counter_uart <= counter_uart + 1;
        uart_tx_en <= 0;
      end

      // wait for dht11 data ready, then trigger the uart
      if (dht11_enable_reg && dht11_data_ready_test) begin
        dht11_enable_reg <= 0;
        counter_uart <= 0;

        // enable uart tx
        uart_tx_en <= 1;
      end
    end
  end
  */
  
  

endmodule