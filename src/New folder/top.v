`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
module top(
    input         clk,      // Clock nguá»“n, vÃ­ dá»¥ 50MHz
    input         rst_n,       // Reset active high
    // Bus IÂ²C cho MAX30100:
    inout         sda_max,
    output        scl_max,
    // Bus IÂ²C cho LCD:
    inout         sda_lcd,
    output        scl_lcd,
    input        rx1, 
    output        tx1 
);


    //********************************************************************
    // Instantiation: i2c_clk_delay
    //********************************************************************
    // Chia clock tá»« clk_in (50MHz) xuá»‘ng 1MHz.
    wire clk_1MHz;
   // wire delay_done_unused; // TÃ­n hiá»‡u delay_done khÃ´ng cáº§n xuáº¥t ra ngoÃ i

/*    i2c_clk_delay #(
        .DIVISOR(50),       // Vá»›i clk_in = 50MHz, divisor = 50 Ä‘á»ƒ táº¡o xung 1MHz (toggle-based)
        .DELAY_COUNT(50000) // Tham sá»‘ delay ná»™i bá»™ (cÃ³ thá»ƒ Ä‘iï¿½?u chá»‰nh)
    ) i2c_clk_delay_inst (
        .clk_in(clk_in),
        .reset(reset),
        .start(1'b1),       // LuÃ´n kÃ­ch hoáº¡t
        .clk_out(clk_1MHz),
        .delay_done(delay_done_unused)
    );*/

    clk_divider#(
        .input_clk_freq(100_000_000),  
        .output_clk_freq(1_000_000)
    )clk_div_inst(
        .clk(clk),
        .clk_1MHz(clk_1MHz)
    );
    
    //********************************************************************
    // Instantiation: top_max30100_system
    //********************************************************************
    // Module nÃ y giao tiáº¿p vá»›i MAX30100 qua bus riÃªng (sda_max, scl_max),
    // xá»­ lÃ½ dá»¯ liá»‡u, lï¿½?c tÃ­n hiá»‡u vÃ  tÃ­nh toÃ¡n cÃ¡c thÃ´ng sá»‘ heart_rate, spo2.
    // CÃ¡c káº¿t quáº£ chá»‰ Ä‘Æ°á»£c sá»­ dá»¥ng ná»™i bá»™.
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
    // Module nÃ y nháº­n cÃ¡c thÃ´ng sá»‘ heart_rate vÃ  spo2 ná»™i bá»™ vÃ  hiá»ƒn thá»‹ lÃªn LCD
    // qua bus IÂ²C riÃªng (sda_lcd, scl_lcd). CÃ¡c thÃ´ng sá»‘ chá»‰ dÃ¹ng ná»™i bá»™.
    
    wire done_display;
    
    lcd_display_max30100 lcd_display_inst (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),    // rst_n active low
        .heart_rate(heart_rate),
        .spo2(spo2),
        .sda_lcd(sda_lcd),
        .scl_lcd(scl_lcd),
        .done(done_display)            // Flag done khÃ´ng Ä‘Æ°á»£c xuáº¥t ra ngoÃ i
    );

    top_uart top_uart_inst (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),    // rst_n active low
        .heart_rate(heart_rate),
        .spo2(spo2),
        .rx(rx1),
        .tx(tx1)
        //.tx_done(),         

      
    );
endmodule

