module lcd_16x2(
  input           clk,
  input           clk_1MHz,
  input           rst_n,
  input           lcd_ena,
  input [127:0]   row1,
  input [127:0]   row2,
  output          busy,
  output          scl,
  inout           sda,
  output          lcd_done
);

  localparam      i2c_addr = 7'h27;

  // wire            done_write;
  wire [7:0]      data;
  wire            cmd_data;
  wire            ena_write;

  lcd_display lcd_display_inst(
    .clk_1MHz           (clk_1MHz),
    .rst_n              (rst_n),
    .ena                (lcd_ena),
    .done_write         (lcd_done),
    .row1               (row1),
    .row2               (row2),
    .data               (data),
    .cmd_data           (cmd_data),
    .ena_write          (ena_write),
    .busy               (busy)
  );

  lcd_write_cmd_data lcd_write_cmd_data_inst(
    .clk_1MHz           (clk_1MHz),
    .rst_n              (rst_n),
    .data               (data),
    .cmd_data           (cmd_data),
    .ena                (ena_write),
    .i2c_addr           (i2c_addr),
    .sda                (sda),
    .scl                (scl),
    .done               (lcd_done)
  );

endmodule