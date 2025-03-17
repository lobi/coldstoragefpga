module i2c_writeframe(
    input       clk_1MHz,               // 1 MHz = 1us clock
    input       rst_n,                  // active low reset
    input       en_write,               // enable write
    input       start_frame,            // start frame flag
    input       stop_frame,             // stop frame flag
    input [7:0] data,                   // data to write
    inout       sda,                    // bidirectional data line
    output reg  scl,                    // clock line
    output      done,                   // write done flag
    output reg  sda_en                  // sda write enable
);

    localparam  DELAY       = 10;       // 10us delay
    reg [20:0]  cnt;                    // counter
    reg         cnt_clr;                // counter clear flag

    // FSM states
    localparam  WaitEn      = 0,        // wait for enable  
                PreStart    = 1,        // prepare for start condition
                Start       = 2,        // start condition
                AfterStart  = 3,        // after start condition
                PreWrite    = 4,        // prepare for write data
                WriteLow    = 5,        // write data to sda line when scl is low      
                WriteHigh   = 6,        // when sda is stable, pull scl high to latch the data  
                WriteDone   = 7,        // write data done     
                WaitAck     = 8,        // wait for ack from slave
                Ack1        = 9,        // pull scl high when got ack
                Ack2        = 10,       // pull scl low to finish ack pulse      
                AckDone     = 11,       // ack done, check if this is the stop frame. If so, create stop condition.
                PreStop     = 12,       // prepare for stop condition     
                Stop        = 13,       // stop condition
                Done        = 14;       // finish write frame
    
    reg [3:0]   state, next_state;
    reg [3:0]   bit_cnt;                // bit counter
    reg         sda_out;                // sda output
    wire        sda_in;                 // sda input

    // sda is a bidirectional tri-state buffer enabled by sda_en.
    // When sda_en = 1; if sda_out = 0, sda = 0; if sda_out = 1, sda is high impedance, allowing pull-up resistor pulls sda to 1.
    // When sda_en = 0; sda is high impedance, allowing read sda from the bus.
    assign sda = sda_en ? (~sda_out ? 1'b0 : 1'bz) : 1'bz;
    assign sda_in = sda;

    // for simulation, we use those lines instead:
    // assign sda = sda_en ? sda_out : 1'bz;
    // assign sda_in = sda;

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
            next_state <= WaitEn;           // reset state, wait for enable
        else begin
            case (state)
                WaitEn:     next_state = en_write ? (start_frame ? PreStart : PreWrite) : WaitEn;
                PreStart:   next_state = (cnt == DELAY) ? Start : PreStart;
                Start:      next_state = (cnt == DELAY) ? AfterStart : Start;
                AfterStart: next_state = (cnt == DELAY) ? WriteLow : AfterStart;
                PreWrite:   next_state = (cnt == DELAY) ? WriteLow : PreWrite;
                WriteLow:   next_state = (cnt == DELAY) ? WriteHigh : WriteLow;
                WriteHigh:  next_state = (cnt == DELAY && bit_cnt == 4'd8) ? WriteDone : ((cnt == DELAY) ? WriteLow : WriteHigh);
                WriteDone:  next_state = (cnt == DELAY) ? WaitAck : WriteDone;
                WaitAck:    next_state = (sda_in == 1'b0) ? Ack1 : WaitAck;
                Ack1:       next_state = (cnt == DELAY) ? Ack2 : Ack1;
                Ack2:       next_state = (cnt == DELAY) ? AckDone : Ack2;
                AckDone:    next_state = (cnt == DELAY) ? (stop_frame ? PreStop : Done) : AckDone;
                PreStop:    next_state = (cnt == DELAY) ? Stop : PreStop;
                Stop:       next_state = (cnt == DELAY) ? Done : Stop;
                Done:       next_state = WaitEn;
            endcase
        end
    end   


    // output logic
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) begin                   // setup initial state
            sda_en  <= 1'b1;                       
            cnt_clr <= 1'b1;            
        end else begin
            case (state)
                WaitEn: begin
                    sda_en  <= 1'b1;        // enable sda write
                    cnt_clr <= 1'b1;        // clear counter
                end
                PreStart: begin
                    sda_out <= 1'b1;                                // pull sda and scl high to prepare for start condition
                    scl     <= 1'b1;        
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                Start: begin
                    sda_out <= 1'b0;                                // when scl is high, pull sda low for start condition
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                AfterStart: begin
                    scl     <= 1'b0;                                // pull scl low to prepare for write data
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                PreWrite: begin
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                WriteLow: begin
                    scl     <= 1'b0;                                // when scl is low, write a bit to sda line
                    sda_out <= data[7-(bit_cnt-1)] ? 1'b1 : 1'b0;   // write data from MSB to LSB
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us      
                end
                WriteHigh: begin
                    scl     <= 1'b1;                                // when sda is stable, pull scl high to latch a bit
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                WriteDone: begin
                    scl     <= 1'b0;                                // pull scl low to prepare for ack
                    sda_en  <= 1'b0;                                // disable sda write, prepare for read ack
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                WaitAck: begin
                    cnt_clr <= 1'b1;                                // delay 10us, wait for ack from slave
                end
                Ack1: begin
                    scl     <= 1'b1;                                // when got ack, pull scl high
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                Ack2: begin
                    scl     <= 1'b0;                                // pull scl low to finish ack pulse
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                AckDone: begin      
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us      
                end
                PreStop: begin
                    scl     <= 1'b1;                                // pull scl high to prepare for stop condition
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end   
                Stop: begin
                    sda_en  <= 1'b1;                                // enable sda write
                    sda_out <= 1'b1;                                // when scl is high, pull sda high for stop condition        
                    cnt_clr <= (cnt == DELAY-1) ? 1'b1 : 1'b0;      // delay 10us
                end
                Done: begin
                    cnt_clr <= 1'b1;                                // clear counter
                end
            endcase
        end
    end

    // bit counter
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 4'd0;
        else begin
            case (state)
                WriteLow:   bit_cnt <= (cnt == 1'b0) ? bit_cnt + 1'b1 : bit_cnt;    // bit_cnt starts from 0, increment before writing
                WaitEn:     bit_cnt <= 4'd0;
                Done:       bit_cnt <= 4'd0;
                default:    bit_cnt <= bit_cnt;
            endcase
        end
    end

    // done flag
    assign done = (state == Done);

endmodule
