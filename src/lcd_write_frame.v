`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/05/2025 05:15:49 PM
// Design Name: 
// Module Name: lcd_write_frame
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
// Module: lcd_write_frame
// Description: Nhận vào 2 hàng dữ liệu (row1 và row2, mỗi hàng 128 bit),
//              tạo thành một frame gồm 34 byte theo thứ tự:
//                - Byte 0: 0x80 (command: đặt con trỏ cho hàng 1)
//                - Byte 1..16: dữ liệu của row1
//                - Byte 17: 0xC0 (command: đặt con trỏ cho hàng 2)
//                - Byte 18..33: dữ liệu của row2
//              Gửi tuần tự từng byte qua I²C sử dụng module lcd_write_cmd_data.
//              Khi frame xong, flag done được khẳng định.
//////////////////////////////////////////////////////////////////////////////////
module lcd_write_frame (
    input         clk_1MHz,   // Clock 1MHz (1µs/xung)
    input         rst_n,      // Reset active low
    input  [127:0] row1,      // Dữ liệu cho hàng 1 (16 byte)
    input  [127:0] row2,      // Dữ liệu cho hàng 2 (16 byte)
    inout         sda_lcd,    // Bus SDA dành cho LCD
    output        scl_lcd,    // Bus SCL dành cho LCD
    output reg    done        // Flag báo hiệu frame đã được gửi xong
);

    // Số byte của frame: 34 (index 0 đến 33)
    localparam FRAME_SIZE = 34;
    
    // Tạo mảng ROM nội bộ chứa frame dữ liệu
    reg [7:0] frame [0:FRAME_SIZE-1];
    integer i;
    always @(*) begin
        frame[0] = 8'h80; // Command: đặt con trỏ hàng 1
        for (i = 1; i <= 16; i = i + 1) begin
            // Lấy từng byte từ row1: row1[127:120] là byte đầu tiên, row1[119:112] là byte thứ 2, v.v.
            frame[i] = row1[127 - ((i-1)*8) -: 8];
        end
        frame[17] = 8'hC0; // Command: đặt con trỏ hàng 2
        for (i = 18; i < FRAME_SIZE; i = i + 1) begin
            // Lấy từng byte từ row2: row2[127:120] là byte đầu tiên, v.v.
            frame[i] = row2[127 - ((i-18)*8) -: 8];
        end
    end

    // FSM để gửi frame qua I²C
    localparam STATE_IDLE = 2'd0,
               STATE_SEND = 2'd1,
               STATE_WAIT = 2'd2,
               STATE_INC  = 2'd3,
               STATE_DONE = 2'd4;
               
    reg [1:0] state, next_state;
    reg [5:0] ptr;            // Con trỏ chạy từ 0 đến 33
    reg       en;             // Tín hiệu enable gửi cho module lcd_write_cmd_data
    reg [7:0] data_to_send;   // Dữ liệu byte cần gửi
    reg       cmd_data;       // 0: command, 1: data
    
    // Xác định cmd_data: nếu ptr = 0 hoặc ptr = 17 -> command; các vị trí khác -> data.
    always @(*) begin
        if (ptr == 0 || ptr == 17)
            cmd_data = 1'b0;
        else
            cmd_data = 1'b1;
    end
    
    // FSM state register và con trỏ
    always @(posedge clk_1MHz or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            ptr   <= 0;
            en    <= 0;
            data_to_send <= 8'd0;
            done  <= 0;
        end else begin
            state <= next_state;
            case (state)
                STATE_IDLE: begin
                    ptr <= 0;
                    en <= 0;
                    done <= 0;
                end
                STATE_SEND: begin
                    data_to_send <= frame[ptr];
                    en <= 1;
                end
                STATE_WAIT: begin
                    en <= 0;
                end
                STATE_INC: begin
                    ptr <= ptr + 1;
                end
                STATE_DONE: begin
                    done <= 1;
                    en <= 0;
                end
                default: ;
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            STATE_IDLE: next_state = STATE_SEND;
            STATE_SEND: next_state = STATE_WAIT;
            STATE_WAIT: next_state = (write_done) ? STATE_INC : STATE_WAIT;
            STATE_INC:  next_state = (ptr == FRAME_SIZE - 1) ? STATE_DONE : STATE_SEND;
            STATE_DONE: next_state = STATE_DONE;
            default:    next_state = STATE_IDLE;
        endcase
    end
    
    // Flag done được truyền ra khi FSM ở STATE_DONE và write_done đã xảy ra.
    wire write_done;
    // Kết nối done flag được lấy từ module lcd_write_cmd_data
    // Trong ví dụ này, chúng ta sử dụng write_done để chuyển sang trạng thái tiếp theo.
    
    // Instanciate module lcd_write_cmd_data để gửi 1 byte qua I²C
    lcd_write_cmd_data lcd_writer (
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n),
        .data(data_to_send),
        .cmd_data(cmd_data),
        .ena(en),
        .i2c_addr(7'h27),    // Địa chỉ I²C của PCF8574 (điều chỉnh nếu cần)
        .sda_lcd(sda_lcd),
        .scl_lcd(scl_lcd),
        .done(write_done),
        .sda_en()           // Nếu cần, có thể kết nối cổng điều khiển
    );
    
endmodule

