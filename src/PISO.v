module PISO(
    input wire          reset_n,
    input wire          send,
    input wire          baud_clk,
    input wire          parity_bit,
    input wire [7:0]    data_in,
    output reg          data_tx,
    output reg          active_flag,
    output reg          done_flag
);

    localparam          IDLE    = 1'b0, 
                        ACTIVE  = 1'b1;

    reg                 STATE = IDLE;
    reg [3:0]           count = 0;
    wire [10:0]         data_out;
    
    //  Construct the data_out frame: 1 start bit, 8 data bits (LSB first), 1 parity bit, 1 stop bit
    assign data_out = {1'b1, parity_bit, data_in, 1'b0};

    // To detect the rising edge of the send signal
    reg send_prev;
    always @(posedge baud_clk or negedge reset_n) begin
        if (!reset_n) begin
            send_prev <= 1'b0;
        end else begin
            send_prev <= send;
        end
    end
    wire send_rising_edge = send & ~send_prev;

    //  PISO state machine
    always @(posedge baud_clk or negedge reset_n) begin
        if (!reset_n) begin
            STATE <= IDLE;
            data_tx <= 1'b1;
            active_flag <= 1'b0;
            done_flag <= 1'b0;
        end else begin
            case (STATE)
                IDLE: begin
                    if (send_rising_edge) STATE <= ACTIVE;
                        else STATE <= IDLE;
                    data_tx <= 1'b1;
                    active_flag <= 1'b0;
                    count <= 4'd0;
                end
                ACTIVE: begin
                    if (count == 11) begin
                        STATE <= IDLE;
                        data_tx <= 1'b1;
                        active_flag <= 1'b0;
                        done_flag <= 1'b1;  
                        count <= 0;
                    end else begin
                        STATE <= ACTIVE;
                        data_tx <= data_out[count];
                        active_flag <= 1'b1;
                        done_flag <= 1'b0;
                        count <= count + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule