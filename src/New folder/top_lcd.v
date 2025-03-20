module top(
    input           clk,                // Main clock
    input           rst_n,              // Active low reset
    input  [7:0]    temperature,        // Temperature input (8-bit integer)
    input  [7:0]    humidity,           // Humidity input (8-bit integer)
    output          scl,                // I2C clock line
    inout           sda                 // I2C data line (bidirectional)
);

    // Internal signals
    wire            clk_1MHz;           // 1 MHz clock for I2C and LCD timing
    wire            done_write;         // Write done flag from I2C module
    wire [7:0]      data;               // Data to write to LCD
    wire            cmd_data;           // Command/data flag (0 = command, 1 = data)
    wire            ena_write;          // Enable write flag
    reg  [127:0]    row1;               // LCD row 1 data (16 characters)
    reg  [127:0]    row2;               // LCD row 2 data (16 characters)

    // Convert temperature and humidity to ASCII for display
    wire [7:0] temp_tens, temp_units, humi_tens, humi_units;
    assign temp_tens = (temperature / 10) + "0";  // Tens digit of temperature
    assign temp_units = (temperature % 10) + "0"; // Units digit of temperature
    assign humi_tens = (humidity / 10) + "0";     // Tens digit of humidity
    assign humi_units = (humidity % 10) + "0";    // Units digit of humidity

    // Generate 1 MHz clock from the main clock
    clk_divider clk_1MHz_gen(
        .clk        (clk),             // Input clock
        .clk_1MHz   (clk_1MHz)         // Output clock (1 MHz)
    );

    // Update LCD rows with temperature and humidity data (exactly 16 characters)
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            row1 <= "Temp: -- C      "; // 16 characters
            row2 <= "Humi: -- %      "; // 16 characters
        end else begin
            row1 <= { "Temp: ", temp_tens, temp_units, " C      " }; // 16 characters
            row2 <= { "Humi: ", humi_tens, humi_units, "%      " };  // 16 characters
        end
    end

    // LCD display module
    lcd_display lcd_display_inst(
        .clk_1MHz   (clk_1MHz),         // 1 MHz clock
        .rst_n      (rst_n),            // Active low reset
        .ena        (1'b1),             // Always enabled
        .done_write (done_write),       // Write done flag from I2C
        .row1       (row1),             // Row 1 data
        .row2       (row2),             // Row 2 data
        .data       (data),             // Data to write to LCD
        .cmd_data   (cmd_data),         // Command/data flag
        .ena_write  (ena_write)         // Enable write flag
    );

    // LCD command and data writing module
    lcd_write_cmd_data lcd_write_cmd_data_inst(
        .clk_1MHz   (clk_1MHz),         // 1 MHz clock
        .rst_n      (rst_n),            // Active low reset
        .data       (data),             // Data to write
        .cmd_data   (cmd_data),         // Command/data flag
        .ena        (ena_write),        // Enable write flag
        .i2c_addr   (7'h27),            // I2C address of the LCD
        .sda        (sda),              // I2C data line
        .scl        (scl),              // I2C clock line
        .done       (done_write)        // Write done flag
    );

endmodule
