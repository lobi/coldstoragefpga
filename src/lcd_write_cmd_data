`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2025 11:54:29 AM
// Design Name: 
// Module Name: lcd_write_cmd_data
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
// Module Name: lcd_write_cmd_data
// Description: Ghi lệnh/dữ liệu lên LCD qua I²C sử dụng bus riêng (sda_lcd, scl_lcd)
//              Theo chế độ 4-bit, mỗi byte được chia thành high nibble và low nibble,
//              với các xung enable (EN) được tạo ra để latch dữ liệu trên LCD.
//////////////////////////////////////////////////////////////////////////////////
module lcd_write_cmd_data(
    input       clk_1MHz,      // Clock 1MHz (1µs mỗi xung)
    input       rst_n,         // Reset active low
    input [7:0] data,          // Byte cần ghi (lệnh hoặc dữ liệu)
    input       cmd_data,      // 0 = command, 1 = data
    input       ena,           // Enable write flag
    input [6:0] i2c_addr,      // Địa chỉ I²C của PCF8574 (ví dụ: 0x27 hoặc 0x3F)
    inout       sda_lcd,       // Bus SDA dành cho LCD
    output      scl_lcd,       // Bus SCL dành cho LCD
    output      done,          // Write done flag
    output      sda_en         // Điều khiển drive SDA (cho LCD)
);

    // Delay parameter: 50µs delay cho LCD xử lý
    localparam DELAY = 50;
    reg [20:0] cnt;         // Bộ đếm microsecond
    reg        cnt_clr;     // Cờ reset bộ đếm

    // FSM states
    localparam WAIT_EN            = 0,
               WRITE_ADDR         = 1,
               WAIT_ADDR_DONE     = 2,
               WRITE_HIGH_NIB1    = 3,
               WAIT_HIGH1_DONE    = 4,
               DELAY_CMD1         = 5,
               WRITE_HIGH_NIB2    = 6,
               WAIT_HIGH2_DONE    = 7,
               WRITE_LOW_NIB1     = 8,
               WAIT_LOW1_DONE     = 9,
               DELAY_CMD2         = 10,
               WRITE_LOW_NIB2     = 11,
               WAIT_LOW2_DONE     = 12,
               DONE_STATE         = 13;
               
    reg [3:0] state, next_state;

    // Microsecond counter logic
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (cnt_clr)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    // FSM state register
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n)
            state <= WAIT_EN;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            WAIT_EN: begin
                if (ena)
                    next_state = WRITE_ADDR;
                else
                    next_state = WAIT_EN;
            end
            WRITE_ADDR: next_state = WAIT_ADDR_DONE;
            WAIT_ADDR_DONE: begin
                if (cnt >= DELAY)
                    next_state = WRITE_HIGH_NIB1;
                else
                    next_state = WAIT_ADDR_DONE;
            end
            WRITE_HIGH_NIB1: next_state = WAIT_HIGH1_DONE;
            WAIT_HIGH1_DONE: begin
                if (cnt >= DELAY)
                    next_state = DELAY_CMD1;
                else
                    next_state = WAIT_HIGH1_DONE;
            end
            DELAY_CMD1: begin
                if (cnt >= DELAY)
                    next_state = WRITE_HIGH_NIB2;
                else
                    next_state = DELAY_CMD1;
            end
            WRITE_HIGH_NIB2: next_state = WAIT_HIGH2_DONE;
            WAIT_HIGH2_DONE: begin
                if (cnt >= DELAY)
                    next_state = WRITE_LOW_NIB1;
                else
                    next_state = WAIT_HIGH2_DONE;
            end
            WRITE_LOW_NIB1: next_state = WAIT_LOW1_DONE;
            WAIT_LOW1_DONE: begin
                if (cnt >= DELAY)
                    next_state = DELAY_CMD2;
                else
                    next_state = WAIT_LOW1_DONE;
            end
            DELAY_CMD2: begin
                if (cnt >= DELAY)
                    next_state = WRITE_LOW_NIB2;
                else
                    next_state = DELAY_CMD2;
            end
            WRITE_LOW_NIB2: next_state = WAIT_LOW2_DONE;
            WAIT_LOW2_DONE: begin
                if (cnt >= DELAY)
                    next_state = DONE_STATE;
                else
                    next_state = WAIT_LOW2_DONE;
            end
            DONE_STATE: next_state = WAIT_EN;
            default: next_state = WAIT_EN;
        endcase
    end

    // Control signals for I²C write via submodule i2c_writeframe
    reg [7:0] i2c_data;
    reg       en_write;      // Enable write signal for I²C writeframe module
    reg       start_frame;   // Start frame flag
    reg       stop_frame;    // Stop frame flag

    // Output logic: set control signals based on FSM state.
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            cnt_clr      <= 1;
            en_write     <= 0;
            start_frame  <= 0;
            stop_frame   <= 0;
            i2c_data     <= 8'd0;
        end else begin
            case (state)
                WAIT_EN: begin
                    cnt_clr     <= 1;
                    en_write    <= 0;
                    start_frame <= 0;
                    stop_frame  <= 0;
                    i2c_data    <= 8'd0;
                end
                WRITE_ADDR: begin
                    cnt_clr     <= 1;
                    start_frame <= 1;  // Tạo start condition
                    stop_frame  <= 0;
                    // Gửi địa chỉ I²C của PCF8574 với bit write (0)
                    i2c_data <= {i2c_addr, 1'b0};
                    en_write <= 1;
                end
                WAIT_ADDR_DONE: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                WRITE_HIGH_NIB1: begin
                    cnt_clr  <= 1;
                    // Gửi high nibble với EN = 1, BL=1, RW=0, RS = cmd_data
                    // Format: {data[7:4], BL, EN, RW, RS}
                    i2c_data <= {data[7:4], 1'b1, 1'b1, 1'b0, cmd_data};
                    en_write <= 1;
                end
                WAIT_HIGH1_DONE: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                DELAY_CMD1: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                WRITE_HIGH_NIB2: begin
                    cnt_clr  <= 1;
                    // Generate falling edge: clear EN bit (set EN = 0)
                    i2c_data <= {data[7:4], 1'b1, 1'b0, 1'b0, cmd_data};
                    en_write <= 1;
                end
                WAIT_HIGH2_DONE: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                WRITE_LOW_NIB1: begin
                    cnt_clr  <= 1;
                    // Gửi low nibble: {data[3:0], BL=1, EN=1, RW=0, RS = cmd_data}
                    i2c_data <= {data[3:0], 1'b1, 1'b1, 1'b0, cmd_data};
                    en_write <= 1;
                end
                WAIT_LOW1_DONE: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                DELAY_CMD2: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                WRITE_LOW_NIB2: begin
                    cnt_clr  <= 1;
                    // Generate falling edge for low nibble: clear EN bit
                    i2c_data <= {data[3:0], 1'b1, 1'b0, 1'b0, cmd_data};
                    en_write <= 1;
                    stop_frame <= 1;  // Sau khi gửi low nibble, tạo stop condition
                end
                WAIT_LOW2_DONE: begin
                    cnt_clr  <= 0;
                    en_write <= 0;
                end
                DONE_STATE: begin
                    cnt_clr     <= 1;
                    en_write    <= 0;
                    start_frame <= 0;
                    stop_frame  <= 0;
                    i2c_data    <= 8'd0;
                end
                default: begin
                    cnt_clr  <= 1;
                    en_write <= 0;
                end
            endcase
        end
    end

    // Done flag: khi FSM đạt DONE_STATE, tín hiệu done = 1
    assign done = (state == DONE_STATE);

    // Instantiation của module i2c_writeframe (giữ nguyên code module i2c_writeframe)
    // Các kết nối được đổi tên: sda -> sda_lcd, scl -> scl_lcd.
    i2c_writeframe i2c_writframe_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .en_write   (en_write),
        .start_frame(start_frame),
        .stop_frame (stop_frame),
        .data       (i2c_data),
        .sda        (sda_lcd),
        .scl        (scl_lcd),
        .done       (),  // Nếu cần, có thể kết nối flag done từ module con
        .sda_en     (sda_en)
    );
    
endmodule

