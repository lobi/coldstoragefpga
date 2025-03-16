`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2025 05:43:50 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top-Level Module: top
// Description: Tích hợp i2c_clk_delay, top_max30100_system và lcd_display_max30100.
//   - i2c_clk_delay chia clock từ nguồn (ví dụ 50MHz) xuống 1MHz.
//   - top_max30100_system giao tiếp với MAX30100 qua bus riêng (sda_max, scl_max),
//     xử lý dữ liệu và tính toán heart_rate, spo2 (nội bộ).
//   - lcd_display_max30100 nhận các thông số nội bộ và hiển thị lên LCD qua bus riêng
//     (sda_lcd, scl_lcd).
// Các thông số heart_rate và spo2 chỉ được sử dụng nội bộ.
//////////////////////////////////////////////////////////////////////////////////
module top(
    input         clk,      // Clock nguồn, ví dụ 50MHz
    input         rst_n,       // Reset active high
    // Bus I²C cho MAX30100:
    inout         sda_max,
    output        scl_max,
    // Bus I²C cho LCD:
    inout         sda_lcd,
    output        scl_lcd
);


    //********************************************************************
    // Instantiation: i2c_clk_delay
    //********************************************************************
    // Chia clock từ clk_in (50MHz) xuống 1MHz.
    wire clk_1MHz;
   // wire delay_done_unused; // Tín hiệu delay_done không cần xuất ra ngoài

/*    i2c_clk_delay #(
        .DIVISOR(50),       // Với clk_in = 50MHz, divisor = 50 để tạo xung 1MHz (toggle-based)
        .DELAY_COUNT(50000) // Tham số delay nội bộ (có thể đi�?u chỉnh)
    ) i2c_clk_delay_inst (
        .clk_in(clk_in),
        .reset(reset),
        .start(1'b1),       // Luôn kích hoạt
        .clk_out(clk_1MHz),
        .delay_done(delay_done_unused)
    );*/

    clk_divider#(
        .input_clk_freq(100_000_000),  
        .output_clk_freq(100_000_000)
    )clk_div_inst(
        .clk(clk),
        .clk_1MHz(clk_1MHz)
    );
    
    //********************************************************************
    // Instantiation: top_max30100_system
    //********************************************************************
    // Module này giao tiếp với MAX30100 qua bus riêng (sda_max, scl_max),
    // xử lý dữ liệu, l�?c tín hiệu và tính toán các thông số heart_rate, spo2.
    // Các kết quả chỉ được sử dụng nội bộ.
    wire [15:0] heart_rate;
    wire [7:0]  spo2;
    
    top_max30100_system sensor_system_inst (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),
        .sda_max(sda_max),
        .scl_max(scl_max),
        .heart_rate(heart_rate),
        .spo2(spo2)
    );

    //********************************************************************
    // Instantiation: lcd_display_max30100
    //********************************************************************
    // Module này nhận các thông số heart_rate và spo2 nội bộ và hiển thị lên LCD
    // qua bus I²C riêng (sda_lcd, scl_lcd). Các thông số chỉ dùng nội bộ.
    
    wire done_display;
    
    lcd_display_max30100 lcd_display_inst (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),    // rst_n active low
        .heart_rate(heart_rate),
        .spo2(spo2),
        .sda_lcd(sda_lcd),
        .scl_lcd(scl_lcd),
        .done(done_display)            // Flag done không được xuất ra ngoài
    );

endmodule

