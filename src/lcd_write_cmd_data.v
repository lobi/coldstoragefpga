module lcd_write_cmd_data(
    input       clk_1MHz,                   // 1 MHz = 1us clock
    input       rst_n,                      // active low reset
    input [7:0] data,                       // byte to write, could be command or data
    input       cmd_data,                   // 0 = command, 1 = data
    input       ena,                        // enable write flag
    input [6:0] i2c_addr,                   // PCF8574 i2c address. Texas Instrument's: 0x27 (0 1 0 0 A2 A1 A0). NXP's: 0x3F (0 1 1 1 A2 A1 A0)
    inout       sda,                        // bidirectional data line
    output      scl,                        // clock line
    output      done,                       // write done flag
    output      sda_en
);

    localparam  DELAY               = 50;   // 50us delay for LCD to process command
    reg [20:0]  cnt;                        // counter
    reg         cnt_clr;                    // counter clear flag

    // FSM states
    localparam  WaitEn              = 0,    // wait for enable
                Write_Addr          = 1,    // write i2c address
                Wait_AddrDone       = 2,    // wait for address write done
                Write_HighNibble1   = 3,    // write high nibble and make enable high
                Wait_High1Done      = 4,    // wait for done write
                Delay_CMD1          = 5,    // delay for lcd to process command
                Write_HighNibble2   = 6,    // make enable low (generate high to low EN pulse) to write high nibble
                Wait_High2Done      = 7,    // wait for done write
                Write_LowNibble1    = 8,    // write low nibble and make enable high
                Wait_Low1Done       = 9,    // wait for done write
                Delay_CMD2          = 10,   // delay for lcd to process command
                Write_LowNibble2    = 11,   // make enable low (generate high to low EN pulse) to write low nibble
                Wait_Low2Done       = 12,   // wait for done write
                Done                = 13;   // done
    
    reg [3:0]   state, next_state;
    reg         en_write;                   // enable write
    wire        en_i2cwrite = en_write;
    wire        i2c_done;                   // write done flag
    reg [7:0]   i2c_data;                   // data to write

    reg         start_frame;                // start frame flag: if set, generate start condition
    reg         stop_frame;                 // stop  frame flag: if set, generate stop  condition

    // microsecond counter
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n)
            cnt <= 21'd0;
        else if (cnt_clr)
            cnt <= 21'd0;
        else
            cnt <= cnt + 1'b1;
    end

    // reset logic
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n)
            state <= WaitEn;
        else
            state <= next_state;
    end

    // next state logic
    always @(*) begin
        if (!rst_n)
            next_state = WaitEn;                // reset state, wait for enable
        else begin
            case (state)
                WaitEn:             next_state = ena ? Write_Addr : WaitEn;
                Write_Addr:         next_state = Wait_AddrDone;
                Wait_AddrDone:      next_state = i2c_done ? Write_HighNibble1 : Wait_AddrDone;
                Write_HighNibble1:  next_state = Wait_High1Done;
                Wait_High1Done:     next_state = i2c_done ? Delay_CMD1 : Wait_High1Done;
                Delay_CMD1:         next_state = (cnt == DELAY) ? Write_HighNibble2 : Delay_CMD1;
                Write_HighNibble2:  next_state = Wait_High2Done;
                Wait_High2Done:     next_state = i2c_done ? Write_LowNibble1 : Wait_High2Done;
                Write_LowNibble1:   next_state = Wait_Low1Done;
                Wait_Low1Done:      next_state = i2c_done ? Delay_CMD2 : Wait_Low1Done;
                Delay_CMD2:         next_state = (cnt == DELAY) ? Write_LowNibble2 : Delay_CMD2;
                Write_LowNibble2:   next_state = Wait_Low2Done;
                Wait_Low2Done:      next_state = i2c_done ? Done : Wait_Low2Done;
                Done:               next_state = WaitEn;
            endcase
        end
    end

    // output logic
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) begin                   // setup initial state
            i2c_data <= 8'd0;
            en_write <= 1'b0;
            cnt_clr  <= 1'b1;
        end else begin
            case (state)
                WaitEn: begin
                    i2c_data    <= 8'd0;
                    en_write    <= 1'b0;
                    cnt_clr     <= 1'b1;
                end
                Write_Addr: begin
                    start_frame <= 1'b1;                // before writing i2c address, generate start condition
                    stop_frame  <= 1'b0;
                    i2c_data    <= {i2c_addr, 1'b0};    // append write bit after i2c address
                    en_write    <= 1'b1;                // enable write
                end
                Wait_AddrDone: begin
                    en_write    <= 1'b0;                // disable write, wait for done
                end
                Write_HighNibble1: begin
                    start_frame <= 1'b0;
                    stop_frame  <= 1'b0;
                    // P7 P6 P5 P4 P3 P2 P1 P0 - DB7 DB6 DB5 DB4 BL EN RW RS - D7 D6 D5 D4 1 1 0 RS
                    i2c_data    <= (data & 8'hF0) | 8'h0C | cmd_data;
                    en_write    <= 1'b1;                // enable write
                end
                Wait_High1Done: begin
                    en_write    <= 1'b0;                // disable write, wait for done
                end
                Delay_CMD1: begin
                    cnt_clr     <= 1'b0;                // delay for LCD to process comm
                end
                Write_HighNibble2: begin
                    start_frame <= 1'b0;
                    stop_frame  <= 1'b0;
                    // P7 P6 P5 P4 P3 P2 P1 P0 - DB7 DB6 DB5 DB4 BL EN RW RS - D7 D6 D5 D4 1 0 0 RS
                    i2c_data    <= ((data & 8'hF0) | 8'h0C | cmd_data) & 8'hFB;
                    en_write    <= 1'b1;                // enable write
                    cnt_clr     <= 1'b1;                // clear counter
                end
                Wait_High2Done: begin
                    en_write    <= 1'b0;                // disable write, wait for done
                end
                Write_LowNibble1: begin              
                    start_frame <= 1'b0;
                    stop_frame  <= 1'b0;
                    // P7 P6 P5 P4 P3 P2 P1 P0 - DB7 DB6 DB5 DB4 BL EN RW RS - D3 D2 D1 D0 1 1 0 RS
                    i2c_data    <= ((data & 8'h0F) << 4) | 8'h0C | cmd_data;
                    en_write    <= 1'b1;                
                end
                Wait_Low1Done: begin
                    en_write    <= 1'b0;                // disable write, wait for done
                end
                Delay_CMD2: begin
                    cnt_clr     <= 1'b0;                // delay for LCD to process comm
                end
                Write_LowNibble2: begin
                    start_frame <= 1'b0;
                    stop_frame  <= 1'b1;                // after writing low nibble, generate stop condition
                    // P7 P6 P5 P4 P3 P2 P1 P0 - DB7 DB6 DB5 DB4 BL EN RW RS - D3 D2 D1 D0 1 0 0 RS
                    i2c_data    <= (((data & 8'h0F) << 4) | 8'h0C | cmd_data) & 8'hFB;
                    en_write    <= 1'b1;                // enable write
                    cnt_clr     <= 1'b1;                // clear counter
                end
                Wait_Low2Done: begin
                    en_write    <= 1'b0;                // disable write, wait for done
                end
            endcase
        end
    end

    // done flag
    assign done = (state == Done);

    i2c_writeframe i2c_writframe_inst(
        .clk_1MHz   (clk_1MHz),
        .rst_n      (rst_n),
        .en_write   (en_i2cwrite),
        .start_frame(start_frame),
        .stop_frame (stop_frame),
        .data       (i2c_data),
        .sda        (sda),
        .scl        (scl),
        .done       (i2c_done),
        .sda_en     (sda_en)
    );

endmodule