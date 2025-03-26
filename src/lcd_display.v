module lcd_display(
    input           clk_1MHz,               // 1 MHz = 1us clock    
    input           rst_n,                  // active low reset
    input           ena,                    // enable write
    input           done_write,             // write done flag
    input  [127:0]  row1,                   // row 1 data
    input  [127:0]  row2,                   // row 2 data
    output reg[7:0] data,                   // data to write
    output          cmd_data,               // 0 = command, 1 = data
    output reg      ena_write,              // enable write flag
    output          busy                    // busy flag
);

    localparam  DELAY           = 50;       // delay 50us

    // FSM states
    localparam  WaitEn          = 0,
                Write           = 1,
                WaitWrite       = 2,
                WaitDelay       = 3,
                Done            = 4;

    reg [2:0]   state, next_state;          
    reg [20:0]  cnt;                        // counter
    reg         cnt_clr;                    // counter clear flag

    wire [7:0]  cmd_data_array [0:39];

    assign cmd_data_array[0]    = 8'h02;    // 4 bit mode
    assign cmd_data_array[1]    = 8'h28;    // initialization of 16x2 lcd in 4bit mode
    assign cmd_data_array[2]    = 8'h0C;    // display ON, cursor OFF
    assign cmd_data_array[3]    = 8'h06;    // auto increment cursor
    assign cmd_data_array[4]    = 8'h01;    // clear dispay
    assign cmd_data_array[5]    = 8'h80;    // cursor at first line
    assign cmd_data_array[22]   = 8'hC0;    // cursor at second line

    generate
        genvar i;
        for (i = 1; i < 17; i=i+1) begin: for_name
            assign cmd_data_array[22-i] = row1[(i*8)-1:i*8-8];      // row1 data
            assign cmd_data_array[39-i] = row2[(i*8)-1:i*8-8];      // row2 data
        end
    endgenerate

    reg [5:0]   ptr;                        // pointer to cmd_data_array

    assign cmd_data = (ptr <= 6'd6 || ptr == 6'd23) ? 1'b0 : 1'b1;  // 0 = command, 1 = data

    assign busy = ~(state == WaitEn);

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
            next_state = WaitEn;
        else begin
            case (state)
                WaitEn:     next_state = ena ? Write : WaitEn;
                Write:      next_state = WaitWrite;
                WaitWrite:  next_state = done_write ? WaitDelay : WaitWrite;
                WaitDelay:  next_state = (ptr == 6'd39) ? Done : ((cnt == DELAY) ? Write : WaitDelay);
                Done:       next_state = WaitEn;
            endcase
        end
    end

    // output logic
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n) begin
            cnt_clr     = 1'b1;
            ena_write  <= 1'b0;            
        end else begin
            case (state)
                WaitEn: begin
                    cnt_clr     = 1'b1;                 // clear counter
                    ena_write  <= 1'b0;                 // disable write
                end
                Write: begin
                    cnt_clr     = 1'b1;                 // clear counter
                    data       <= cmd_data_array[ptr];  // write data   
                    ena_write  <= 1'b1;                 // enable write
                end
                WaitWrite: begin
                    ena_write  <= 1'b0;                 // disable write
                end
                WaitDelay: begin
                    cnt_clr     = 1'b0;
                end
            endcase
        end
    end

    // ptr counter
    always @(posedge clk_1MHz, negedge rst_n) begin
        if (!rst_n)
            ptr <= 6'd0;
        else if (state == WaitEn)
            ptr <= 6'd0;
        else if (state == Write)
            ptr <= ptr + 1'b1;
        else
            ptr <= ptr;
    end

endmodule