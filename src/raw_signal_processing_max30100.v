`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 10:07:24 PM
// Design Name: 
// Module Name: raw_signal_processing_max30100
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
// Module Name: raw_signal_processing_max30100
// Description: Lọc tín hiệu và phát hiện đỉnh từ MAX30100 với clock 1MHz
//////////////////////////////////////////////////////////////////////////////////

module raw_signal_processing_max30100 #(
    parameter DATA_WIDTH = 16,
    parameter THRESHOLD  = 1000  // Ngưỡng phát hiện đỉnh
)(
    input  wire                     clk_1MHz,      // Clock 1MHz từ clk_divider
    input  wire                     rst_n,         // Reset đồng bộ, active high
    input  wire                     new_sample,    // Tín hiệu báo có dữ liệu mới
    input  wire [DATA_WIDTH-1:0]    raw_data,      // Dữ liệu thô từ MAX30100

    output reg  [DATA_WIDTH-1:0]    filtered_data, // Dữ liệu sau lọc (Low-pass)
    output reg                      peak_detected  // Phát hiện đỉnh (1 clock cycle)
);

    // Bộ lọc IIR (Exponential Moving Average)
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            filtered_data <= 0;
        else if (new_sample)
            filtered_data <= filtered_data + ((raw_data - filtered_data) >> 3);
    end

    // Phát hiện đỉnh
    reg [DATA_WIDTH-1:0] prev_sample;
    reg rising;

    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            prev_sample   <= 0;
            rising        <= 0;
            peak_detected <= 0;
        end else if (new_sample) begin
            if (filtered_data > prev_sample) begin
                rising        <= 1;
                peak_detected <= 0;
            end else if (rising && (filtered_data < prev_sample) && (prev_sample > THRESHOLD)) begin
                peak_detected <= 1;
                rising        <= 0;
            end else begin
                peak_detected <= 0;
                if (filtered_data <= prev_sample)
                    rising <= 0;
            end
            prev_sample <= filtered_data;
        end
    end

endmodule


