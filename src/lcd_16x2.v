module lcd_16x2(
  input   wire            clk_1MHz,
  input   wire            rst_n,
  input   wire            ena,
  input   wire  [127:0]   row1,
  input   wire  [127:0]   row2,
  output  wire            scl,
  inout   wire            sda
);

  // Internal signals
  wire            clk_1MHz;           // 1 MHz clock for I2C and LCD timing
  wire            done_write;         // Write done flag from I2C module
  wire [7:0]      data;               // Data to write to LCD
  wire            cmd_data;           // Command/data flag (0 = command, 1 = data)
  wire            ena_write;          // Enable write flag
  // reg  [127:0]    row1;               // LCD row 1 data (16 characters)
  // reg  [127:0]    row2;               // LCD row 2 data (16 characters)

  // LCD display module
  lcd_display lcd_display_inst(
    .clk_1MHz   (clk_1MHz),         // 1 MHz clock
    .rst_n      (rst_n),            // Active low reset
    .ena        (ena),              // Enable write
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
