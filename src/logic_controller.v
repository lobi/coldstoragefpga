module logic_controller(
  input   wire            clk,       // 1 MHz clock
  input   wire            rst_n,

  // dht11 sensor
  input   wire  [7: 0]    temperature,
  input   wire  [7: 0]    humidity,
  output  reg             dht_en,
  input   wire            dht_data_ready,

  // uart
  input   wire  [7:0]     chr_cmd,
  input   wire  [7:0]     chr_val0,
  input   wire  [7:8]     chr_val1,
  input   wire            rx_msg_done,
  output   reg             en_tx,

  // LCD display
  output  reg             lcd_en,   // LCD enable signal
  output  reg   [127:0]   lcd_row1, // LCD row 1 data (16 characters)
  output  reg   [127:0]   lcd_row2, // LCD row 2 data (16 characters)

  // led indicators
  output  reg             led_fan,      // cooling fan (1/0): on/off
  output  reg             led_hum      // humidifier (1/0): on/off
);

  localparam LCD_INTERVAL = 500_000; // 0.5 second for 1 MHz clock
  integer lcd_interval_count = 0;
  reg [6:0] max_temp, min_temp, min_hum, max_hum; // 7 bits wide (enough for 0-100 integer) 
  
  reg [7:0] temp_tens, temp_units, humi_tens, humi_units;
  reg tick; // 1 second tick - posedge

  initial begin
    // Initialize the LCD lines with 2 lines: 16 characters per line
    lcd_row1 = "  Cold Storage  ";
    lcd_row2 = "     Hello      ";
    dht_en <= 1'b0;
  end
  reg initialed;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all states and signals

      tick <= 1'b0;

      // reset threshold values
      max_temp <= 18; // 18 degrees Celsius
      min_temp <= 0; // 0 degrees Celsius
      min_hum <= 10; // 10%
      max_hum <= 35; // 35%
      dht_en <= 1'b0;

      // lcd
      lcd_row1 <= "  Cold Storage  ";
      lcd_row2 <= "     Welcome    ";
      lcd_en <= 1'b0;
      initialed <= 1'b0;
    end else begin
      // Update LCD rows with temperature and humidity data (exactly 16 characters)
      // update every 0.5 second
      if (lcd_interval_count == LCD_INTERVAL) begin
        initialed <= 1'b1;
        lcd_interval_count <= 0;
        tick <= ~tick;
        //lcd_en <= 1'b1;

        if (tick) begin
          // refresh sensor data
          if (!dht_en ) begin
            dht_en <= 1'b1;
          end

          // enable uart tx to send metrics
          en_tx <= 1'b1;

          // 
          if (rx_msg_done) begin
            

            update_settings();
            update_leds();
          end

          update_lcd();

          //lcd_en <= 1'b0;
          lcd_en <= 1'b1;
        end else begin
          dht_en <= 1'b0;
          lcd_en <= 1'b0;
        end
      end else begin
        lcd_interval_count <= lcd_interval_count + 1;
      end

      // disable dht_en if data is done
      if (dht_en && dht_data_ready) begin
        dht_en <= 1'b0;
      end

      // disable uart - stop sending metrics
      if (en_tx && rx_msg_done) begin
        en_tx <= 1'b0;
      end
    end
  end

  task update_settings;
    begin
      // data from uart: chr_cmd, chr_val0, chr_val1
      if (chr_cmd == 8'h4C) begin // ASCII 'L'
        // Update LED states based on received values
        led_fan <= (chr_val0 != 8'h30); // Turn on if not '0'
        led_hum <= (chr_val1 != 8'h30); // Turn on if not '0'
      end else if (chr_cmd == 8'h41) begin // ASCII 'A'
        // combine chr_val0 and chr_val1 to form a 2-digit number, then assign to max_temp
        max_temp <= ((chr_val0 - 8'h30) * 10) + (chr_val1 - 8'h30);
      end else if (chr_cmd == 8'h42) begin // ASCII 'B'
        // combine chr_val0 and chr_val1 to form a 2-digit number, then assign to min_temp
        min_temp <= ((chr_val0 - 8'h30) * 10) + (chr_val1 - 8'h30);
      end else if (chr_cmd == 8'h43) begin // ASCII 'C'
        // combine chr_val0 and chr_val1 to form a 2-digit number, then assign to max_hum
        max_hum <= ((chr_val0 - 8'h30) * 10) + (chr_val1 - 8'h30);
      end else if (chr_cmd == 8'h44) begin // ASCII 'D'
        // combine chr_val0 and chr_val1 to form a 2-digit number, then assign to min_hum
        min_hum <= ((chr_val0 - 8'h30) * 10) + (chr_val1 - 8'h30);
      end
    end
  endtask

  // update cooling fan and humidifier (leds) based on temperature and humidity
  task update_leds;
    begin
      // Control the LED indicators based on the temperature and humidity data
      if (temperature > max_temp) begin
        led_fan <= 1'b1; // Turn on the cooling fan
      end else begin
        led_fan <= 1'b0; // Turn off the cooling fan
      end

      if (humidity < min_hum) begin
        led_hum <= 1'b1; // Turn on the humidifier
      end else begin
        led_hum <= 1'b0; // Turn off the humidifier
      end
    end
  endtask

  task update_lcd;
    begin
      // Convert temperature and humidity to ASCII for display
      temp_tens <= (temperature / 10) + 8'h30;  // Tens digit of temperature
      temp_units <= (temperature % 10) + 8'h30; // Units digit of temperature
      humi_tens <= (humidity / 10) + 8'h30;   // Tens digit of humidity
      humi_units <= (humidity % 10) + 8'h30;  // Units digit of humidity

      // Update LCD rows with temperature and humidity data (exactly 16 characters)
      if (temperature < 10) begin
        lcd_row1 <= { "Temp: 0", temp_units, " C      " }; // 16 characters
      end else begin
        lcd_row1 <= { "Temp: ", temp_tens, temp_units, " C      " }; // 16 characters
      end

      if (humidity < 10) begin
        lcd_row2 <= { "Humi: 0", humi_units, "%       " };  // 16 characters
      end else begin
        lcd_row2 <= { "Humi: ", humi_tens, humi_units, "%       " };  // 16 characters
      end

      // let display on
      // lcd_en <= 1'b1;
    end
  endtask

endmodule