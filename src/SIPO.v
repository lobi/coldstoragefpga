module SIPO(
    input  wire         reset_n,        //  Active low reset.
    input  wire         data_tx,        //  Serial Data recieved from the transmitter.
    input  wire         baud_clk,       //  The clocking input comes from the sampling unit.

    output wire         active_flag,    //  outputs logic 1 when data is in progress.
    output wire         recieved_flag,  //  outputs a signal enables the deframe unit. 
    output wire  [10:0] data_parll      //  outputs the 11-bit parallel frame.
);
    //  Internal
    reg [10:0]          temp, data_parll_temp;
    reg [3:0]           frame_counter, stop_count;
    reg [1:0]           STATE;

    //  Encoding the states of the reciever
    localparam          IDLE   = 2'b00,
                        CENTER = 2'b01,
                        GET    = 2'b10,
                        FRAME  = 2'b11;

    //  Recieving logic FSM
    always @(posedge baud_clk, negedge reset_n) begin
        if (!reset_n) begin
            STATE         <= IDLE;
            stop_count    <= 4'd0;
            frame_counter <= 4'd0;
            temp          <= {11{1'b1}};
        end
        else begin
            case (STATE)
                IDLE: begin
                    temp          <= {11{1'b1}};
                    stop_count    <= 4'd0;
                    frame_counter <= 4'd0;
                    if (~data_tx) STATE  <= CENTER;
                        else STATE <= IDLE;
                end

                CENTER: begin
                    if (stop_count == 4'd6) begin
                        stop_count   <= 4'd0;
                        STATE        <= GET;
                    end else begin
                        stop_count   <= stop_count + 4'b1;
                        STATE        <= CENTER;
                    end
                end

                FRAME: begin
                    temp <= data_parll_temp;
                    if (frame_counter == 4'd10) begin
                        frame_counter <= 4'd0;
                        STATE    <= IDLE;
                    end else begin
                        if (stop_count == 4'd14) begin
                            frame_counter <= frame_counter + 4'b1;
                            stop_count    <= 4'd0; 
                            STATE         <= GET;
                        end else begin
                            frame_counter <= frame_counter;
                            stop_count    <= stop_count + 4'b1;
                            STATE         <= FRAME;
                      end
                    end
                end

                GET: begin 
                    STATE  <= FRAME;
                    temp   <= data_parll_temp;
                end
            endcase
        end
    end

    always @(*) begin
        case (STATE)
            IDLE, CENTER, FRAME: data_parll_temp = temp;

            GET: begin
                data_parll_temp     = temp >> 1;
                data_parll_temp[10] = data_tx;
            end
        endcase
    end

    assign data_parll    = recieved_flag? data_parll_temp : {11{1'b1}};
    assign recieved_flag = (frame_counter == 4'd10);
    assign active_flag   = !recieved_flag;

endmodule
