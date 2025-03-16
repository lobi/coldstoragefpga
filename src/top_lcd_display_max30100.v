`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: lcd_display_max30100
// Description: Nhận các thông số heart_rate (BPM) và spo2 (%) từ hệ thống nội bộ,
//              chuyển đổi chúng thành chuỗi ký tự định dạng cho LCD (2 hàng, 16 ký tự mỗi hàng)
//              và gửi dữ liệu qua bus I²C dành cho LCD (sda_lcd, scl_lcd) bằng cách gọi module
//              lcd_write_frame. Các thông số hiển thị chỉ được sử dụng nội bộ và không xuất ra ngoài.
//////////////////////////////////////////////////////////////////////////////////
module lcd_display_max30100(
    input         clk_1MHz,      // Clock 1MHz từ module i2c_clk_delay
    input         rst_n,         // Reset active low
    input  [15:0] heart_rate,    // Heart rate (BPM), giả sử <= 999
    input  [7:0]  spo2,          // SpO₂ (%)
    inout         sda_lcd,       // Bus SDA dành cho LCD
    output        scl_lcd,       // Bus SCL dành cho LCD
    output        done           // Flag báo hiệu frame hiển thị đã xong
);

    // Chuyển đổi số sang ký tự ASCII (mỗi hàng có 16 ký tự, tổng 128 bit)
    reg [127:0] row1;
    reg [127:0] row2;
    
    // '0' có mã ASCII là 8'd48.
    wire [7:0] hr_hundreds = 8'd48 + ((heart_rate / 100) % 10);
    wire [7:0] hr_tens     = 8'd48 + ((heart_rate / 10) % 10);
    wire [7:0] hr_units    = 8'd48 + (heart_rate % 10);
    wire [7:0] spo2_tens   = 8'd48 + ((spo2 / 10) % 10);
    wire [7:0] spo2_units  = 8'd48 + (spo2 % 10);
    
    // Format chuỗi hiển thị:
    // Row1: "HR:" + 3 số của heart_rate + 10 khoảng trắng = 16 ký tự
    // Row2: "SpO2:" + 2 số của spo2 + "%" + 8 khoảng trắng = 16 ký tự
    always @(*) begin
        row1 = { "HR:",
                 hr_hundreds, hr_tens, hr_units,
                 "            "};
        row2 = { "SpO2:",
                 spo2_tens, spo2_units,
                 "%",
                 "        "};
    end

    // Instanciate module lcd_write_frame để gửi frame dữ liệu qua I²C cho LCD.
    lcd_write_frame lcd_frame_inst (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),
        .row1(row1),
        .row2(row2),
        .sda_lcd(sda_lcd),   // Sửa: sử dụng tên port sda_lcd thay vì sda
        .scl_lcd(scl_lcd),
        .done(done)
    );

endmodule



