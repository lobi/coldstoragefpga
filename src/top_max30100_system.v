`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Module: top_max30100_system
// Description: Tích hợp giao tiếp I²C với MAX30100, FIFO, xử lý tín hiệu và tính toán nhịp tim, SpO₂.
//              Nhận clock `clk_1MHz` từ `clk_divider` trong module top.
//////////////////////////////////////////////////////////////////////////////////

module top_max30100_system (
    input         clk_1MHz,    // Clock 1MHz từ module clk_divider trong top
    input         rst_n,       // Reset active high
    inout         sda_max,     // Bus SDA dành cho MAX30100
    output        scl_max,     // Bus SCL dành cho MAX30100
    output [15:0] heart_rate,  // Nhịp tim (BPM)
    output [7:0]  spo2         // SpO₂ (%)
);

    //------------------------------------------------------------------------- 
    // Giao tiếp I²C với MAX30100: i2c_master_max30100 
    //------------------------------------------------------------------------- 
    wire [7:0] sensor_data_byte;
    wire sensor_ready;
    reg  sensor_start;
    
    i2c_master_max30100 i2c_sensor_inst (
        .clk_1MHz(clk_1MHz),         // Sử dụng clock 1MHz thay vì 100MHz
        .rst_n(rst_n),
        .start(sensor_start),
        .rw(1'b1),              // Chế độ đọc
        .slave_addr(7'h57),     // Địa chỉ MAX30100 (ví dụ)
        .reg_addr(8'h09),       // Đọc từ thanh ghi FIFO_DATA
        .data_in(8'd0),         // Không dùng cho chế độ read
        .data_out(sensor_data_byte),
        .ready(sensor_ready),
        .sda_max(sda_max),
        .scl_max(scl_max)
    );

    //------------------------------------------------------------------------- 
    // Bộ nhớ FIFO: lưu trữ dữ liệu 16-bit từ cảm biến.
    //------------------------------------------------------------------------- 
    wire [15:0] fifo_data_out;
    wire fifo_empty;
    wire fifo_full;
    reg  fifo_wr_en;
    reg  fifo_rd_en;
    
    fifo_buffer #( 
        .DATA_WIDTH(16),
        .FIFO_DEPTH(256) 
    ) fifo_inst (
        .clk_1MHz(clk_1MHz),         // Sử dụng clock 1MHz thay vì 100MHz
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .data_in(sensor_raw),
        .data_out(fifo_data_out),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    //------------------------------------------------------------------------- 
    // Ghép 2 byte từ cảm biến thành dữ liệu 16-bit.
    //------------------------------------------------------------------------- 
    reg [7:0] sensor_data_byte_reg;
    reg       byte_received;
    reg [15:0] sensor_raw;
    
    reg [1:0] comb_state;
    localparam COMB_IDLE   = 0, 
               COMB_FIRST  = 1, 
               COMB_SECOND = 2;
                    
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            comb_state <= COMB_IDLE;
            sensor_data_byte_reg <= 8'd0;
            sensor_raw <= 16'd0;
            byte_received <= 1'b0;
            fifo_wr_en <= 1'b0;
            sensor_start <= 1'b0;
        end else begin
            // Luôn kích hoạt sensor_start để đọc dữ liệu liên tục
            sensor_start <= 1'b1;
            case (comb_state)
                COMB_IDLE: begin
                    if (sensor_ready) begin
                        sensor_data_byte_reg <= sensor_data_byte;
                        byte_received <= 1'b1;
                        comb_state <= COMB_SECOND;
                    end
                end
                COMB_SECOND: begin
                    if (sensor_ready) begin
                        sensor_raw <= {sensor_data_byte_reg, sensor_data_byte};
                        byte_received <= 1'b0;
                        comb_state <= COMB_IDLE;
                        // Ghi dữ liệu vào FIFO nếu chưa đầy
                        if (!fifo_full)
                            fifo_wr_en <= 1'b1;
                        else
                            fifo_wr_en <= 1'b0;
                    end else begin
                        fifo_wr_en <= 1'b0;
                    end
                end
                default: comb_state <= COMB_IDLE;
            endcase
        end
    end

    //------------------------------------------------------------------------- 
    // Đọc dữ liệu từ FIFO để xử lý tín hiệu.
    //------------------------------------------------------------------------- 
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            fifo_rd_en <= 1'b0;
        else if (!fifo_empty)
            fifo_rd_en <= 1'b1;
        else
            fifo_rd_en <= 1'b0;
    end

    //------------------------------------------------------------------------- 
    // Xử lý tín hiệu thô: lọc và phát hiện đỉnh.
    //------------------------------------------------------------------------- 
    wire [15:0] filtered_data;
    wire peak_detected;
    reg new_sample;
    
    raw_signal_processing_max30100 raw_proc_inst (
        .clk_1MHz(clk_1MHz),         // Sử dụng clock 1MHz thay vì 100MHz
        .rst_n(rst_n),
        .new_sample(new_sample),
        .raw_data(fifo_data_out),
        .filtered_data(filtered_data),
        .peak_detected(peak_detected)
    );

    // Kích hoạt new_sample mỗi khi FIFO được đọc.
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            new_sample <= 0;
        else
            new_sample <= (fifo_rd_en && !fifo_empty);
    end

    //------------------------------------------------------------------------- 
    // Tính toán nhịp tim (heart_rate) và SpO₂.
    //------------------------------------------------------------------------- 
    vital_sign_calculation_max30100 vital_calc_inst (
        .clk_1MHz(clk_1MHz),         // Sử dụng clock 1MHz thay vì 100MHz
        .rst_n(rst_n),
        .new_sample(new_sample),
        .peak_detected(peak_detected),
        .filtered_ir(filtered_data),
        .filtered_red(filtered_data), // Giả sử dùng cùng dữ liệu nếu chỉ có 1 kênh
        .heart_rate(heart_rate),
        .spo2(spo2)
    );

endmodule
