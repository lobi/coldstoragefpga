`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: vital_sign_calculation_max30100
// Description: Dựa vào tín hiệu đã qua xử lý (filtered_data) từ MAX30100, module tính
//              toán nhịp tim (BPM) và SpO₂ (%). Các giá trị max/min (ir_max, ir_min,
//              red_max, red_min) được cập nhật trong một always block với cấu trúc if-else
//              mutually exclusive để tránh multiple drivers.
//////////////////////////////////////////////////////////////////////////////////
 

module vital_sign_calculation_max30100 #( 
    parameter DATA_WIDTH     = 16,       // Độ rộng dữ liệu cảm biến
    parameter COUNTER_WIDTH  = 32,       // Độ rộng bộ đếm thời gian
    parameter INPUT_CLK_FREQ = 100_000_000,  // Tần số xung nhịp đầu vào (100 MHz)
    parameter OUTPUT_CLK_FREQ = 1_000_000   // Tần số clock chia xuống (1 MHz)
)(
    input  wire                      clk,           // Clock gốc (100 MHz)
    input  wire                      clk_1MHz,      // Clock đã chia xuống (1 MHz)
    input  wire                      rst_n,        
    input  wire                      new_sample,    
    input  wire                      peak_detected, 
    input  wire [DATA_WIDTH-1:0]     filtered_ir,   
    input  wire [DATA_WIDTH-1:0]     filtered_red,  
    output reg  [15:0]               heart_rate,    
    output reg  [7:0]                spo2           
);     

    //----- Tính Nhịp Tim (HR) -----
    reg [COUNTER_WIDTH-1:0] free_counter;
    reg [COUNTER_WIDTH-1:0] last_peak_time;
    wire [COUNTER_WIDTH-1:0] interval;

    assign interval = free_counter - last_peak_time;

    // Bộ đếm thời gian chạy trên clk_1MHz
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            free_counter <= 0;
        else
            free_counter <= free_counter + 1;
    end

    // Cập nhật nhịp tim khi phát hiện đỉnh
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            last_peak_time <= 0;
            heart_rate     <= 0;
        end 
        else if (peak_detected) begin
            last_peak_time <= free_counter;
            if (interval != 0)
                heart_rate <= (60 * OUTPUT_CLK_FREQ) / interval; 
        end
    end

    //----- Tính SpO₂ và cập nhật giá trị max/min -----
    reg [DATA_WIDTH-1:0] ir_max, ir_min;
    reg [DATA_WIDTH-1:0] red_max, red_min;
    reg [31:0] numerator;
    reg [31:0] denominator;
    reg [31:0] ratio;

    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            ir_max  <= 0;
            ir_min  <= {DATA_WIDTH{1'b1}}; 
            red_max <= 0;
            red_min <= {DATA_WIDTH{1'b1}};
            spo2    <= 0;
        end 
        else if (peak_detected) begin
            numerator   = (red_max - red_min) * ((ir_max + ir_min) >> 1);
            denominator = (ir_max - ir_min) * ((red_max + red_min) >> 1);
            if (denominator != 0)
                ratio = numerator / denominator;
            else
                ratio = 0;

            spo2 <= 110 - (25 * ratio[7:0]);

            // Reset lại max/min
            ir_max  <= filtered_ir;
            ir_min  <= filtered_ir;
            red_max <= filtered_red;
            red_min <= filtered_red;
        end 
        else if (new_sample) begin
            if (filtered_ir > ir_max) ir_max <= filtered_ir;
            if (filtered_ir < ir_min) ir_min <= filtered_ir;
            if (filtered_red > red_max) red_max <= filtered_red;
            if (filtered_red < red_min) red_min <= filtered_red;
        end
    end

endmodule
