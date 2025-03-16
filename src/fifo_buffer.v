`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: fifo_buffer
// Description: FIFO sử dụng clock 1MHz từ clk_divider
//////////////////////////////////////////////////////////////////////////////////
module fifo_buffer #(
    parameter DATA_WIDTH = 8,      // Chiều rộng dữ liệu (8-bit)
    parameter FIFO_DEPTH = 256     // Số phần tử của FIFO
)(
    input  wire                    clk_1MHz,  // Clock 1MHz từ clk_divider
    input  wire                    rst_n,     // Reset bất đồng bộ (active high)
    input  wire                    wr_en,     // Cho phép ghi dữ liệu vào FIFO
    input  wire                    rd_en,     // Cho phép đọc dữ liệu từ FIFO
    input  wire [DATA_WIDTH-1:0]   data_in,   // Dữ liệu ghi vào FIFO
    output reg  [DATA_WIDTH-1:0]   data_out,  // Dữ liệu đọc từ FIFO
    output reg                     empty,     // FIFO rỗng
    output reg                     full,      // FIFO đầy
    output reg                     almost_full // FIFO gần đầy
);

    // Tính số bit cần thiết cho địa chỉ
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Bộ nhớ FIFO
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Con trỏ ghi và đọc
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;

    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr       <= 0;
            rd_ptr       <= 0;
            empty        <= 1;
            full         <= 0;
            almost_full  <= 0;
            data_out     <= 0;  // Đảm bảo không có dữ liệu sai sau reset
        end else begin
            // Ghi dữ liệu khi wr_en được kích hoạt và FIFO không đầy
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end 

            // Đọc dữ liệu khi rd_en được kích hoạt và FIFO không rỗng
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end 

            // FIFO rỗng khi con trỏ đọc và ghi bằng nhau
            empty <= (wr_ptr == rd_ptr);

            // FIFO đầy khi con trỏ ghi đi trước con trỏ đọc một vòng
            full <= (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                    (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

            // FIFO gần đầy khi chỉ còn 1 vị trí trống
            almost_full <= ((wr_ptr + 1'b1) == rd_ptr);
        end
    end

endmodule
