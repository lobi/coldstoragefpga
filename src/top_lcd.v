module top(
    input           clk,
    input           rst_n,
    output          scl,
    input  [15:0]   heart_rate,    
    input  [7:0]    spo2,  
    inout           sda
);

    wire            clk_1MHz;
    wire            done_write;
    wire [7:0]      data;
    wire            cmd_data;
    wire            ena_write;
    reg [127:0]     row1;
    reg [127:0]     row2;

    // Kiểm tra giá trị hợp lệ, tránh lỗi hiển thị
    wire [15:0] hr_safe   = (heart_rate > 999) ? 999 : heart_rate;
    wire [7:0]  spo2_safe = (spo2 > 99) ? 99 : spo2;

    // Chuyển đổi số sang mã ASCII
    wire [7:0] hr_hundreds = 8'd48 + ((hr_safe / 100) % 10);
    wire [7:0] hr_tens     = 8'd48 + ((hr_safe / 10) % 10);
    wire [7:0] hr_units    = 8'd48 + (hr_safe % 10);
    wire [7:0] spo2_tens   = 8'd48 + ((spo2_safe / 10) % 10);
    wire [7:0] spo2_units  = 8'd48 + (spo2_safe % 10);

    // Cập nhật giá trị row1, row2 mỗi khi có xung clk_1MHz hoặc reset
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            row1 <= "HR:   --- BPM   "; // Giá trị mặc định khi reset
            row2 <= "SpO2: --%       ";
        end else begin
            row1 <= { "HR: ", hr_hundreds, hr_tens, hr_units, " BPM     " };
            row2 <= { "SpO2: ", spo2_tens, spo2_units, "%       " };
        end
    end

    // Bộ chia clock để tạo xung 1MHz
    clk_divider clk_1MHz_gen(
        .clk        (clk),
        .clk_1MHz   (clk_1MHz)
    );

    // Module hiển thị LCD
    lcd_display lcd_display_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .ena        (1'b1),
        .done_write (done_write),
        .row1       (row1),
        .row2       (row2),
        .data       (data),
        .cmd_data   (cmd_data),
        .ena_write  (ena_write)
    );

    // Module ghi dữ liệu I2C ra LCD
    lcd_write_cmd_data lcd_write_cmd_data_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .data       (data),
        .cmd_data   (cmd_data),
        .ena        (ena_write),
        .i2c_addr   (7'h27),
        .sda        (sda),
        .scl        (scl),
        .done       (done_write)
    );

endmodule
