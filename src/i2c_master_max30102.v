`timescale 1ns / 1ps

module i2c_master_max30100 (
    input  wire       clk_1MHz,   // Clock từ module clk_divider
    input  wire       rst_n,      // Reset active high
    input  wire       start,      // Kích hoạt giao dịch I²C
    input  wire       rw,         // 0 - Write, 1 - Read
    input  wire [6:0] slave_addr, // Địa chỉ Slave (7-bit)
    input  wire [7:0] reg_addr,   // Địa chỉ thanh ghi
    input  wire [7:0] data_in,    // Dữ liệu ghi
    output reg  [7:0] data_out,   // Dữ liệu đọc
    output reg        ready,      // Hoàn tất giao dịch
    inout  wire       sda_max,    // Bus SDA
    output reg        scl_max     // Bus SCL
);

    // Định nghĩa các trạng thái FSM
    localparam IDLE        = 4'b0000;
    localparam START_COND  = 4'b0001;
    localparam SEND_ADDR   = 4'b0010;
    localparam ACK1        = 4'b0011;
    localparam SEND_REG    = 4'b0100;
    localparam ACK2        = 4'b0101;
    localparam WRITE_DATA  = 4'b0110;
    localparam ACK3        = 4'b0111;
    localparam STOP_COND   = 4'b1000;
    localparam READ_DATA   = 4'b1001;
    localparam READ_ACK    = 4'b1010;
    localparam WAIT_DELAY  = 4'b1011;

    reg [3:0] state;  // Trạng thái của FSM
    reg [3:0] bit_cnt;
    reg [7:0] tx_byte;
    reg sda_out, sda_oe;

    assign sda_max = sda_oe ? (~sda_out ? 1'b0 : 1'bz) : 1'bz;

    // Bộ đếm delay cho I²C 100 kHz (~10 µs mỗi tick)
    reg [7:0] delay_counter;
    wire delay_done = (delay_counter == 10);

    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            delay_counter <= 0;
        else if (!delay_done)
            delay_counter <= delay_counter + 1;
        else
            delay_counter <= 0;
    end

    // FSM điều khiển I²C
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            ready       <= 1;
            scl_max     <= 1;
            sda_out     <= 1;
            sda_oe      <= 1;
            bit_cnt     <= 0;
            tx_byte     <= 8'd0;
            data_out    <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    ready   <= 1;
                    scl_max <= 1;
                    sda_out <= 1;
                    sda_oe  <= 1;
                    if (start) begin
                        ready   <= 0;
                        state   <= START_COND;
                    end
                end 

                START_COND: begin
                    if (delay_done) begin
                        sda_out <= 0;
                        state   <= SEND_ADDR;
                        tx_byte <= {slave_addr, rw};
                        bit_cnt <= 7;
                    end
                end 

                SEND_ADDR, SEND_REG, WRITE_DATA: begin
                    if (delay_done) begin
                        scl_max <= 0;
                        sda_out <= tx_byte[bit_cnt];
                        if (bit_cnt == 0) begin
                            state <= state + 1;
                            sda_oe <= 0;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end 

                ACK1, ACK2, ACK3: begin
                    if (delay_done) begin
                        scl_max <= 1;
                        state   <= state + 1;
                    end
                end 

                READ_DATA: begin
                    if (delay_done) begin
                        scl_max <= 1;
                        data_out[bit_cnt] <= sda_max;
                        if (bit_cnt == 0) begin
                            state <= READ_ACK;
                            sda_oe <= 1;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end 

                READ_ACK: begin
                    if (delay_done) begin
                        scl_max <= 1;
                        state   <= STOP_COND;
                    end
                end 

                STOP_COND: begin
                    if (delay_done) begin
                        scl_max <= 1;
                        sda_out <= 1;
                        sda_oe  <= 1;
                        state   <= IDLE;
                        ready   <= 1;
                    end
                end 

                default: state <= IDLE;
            endcase
        end
    end

endmodule
