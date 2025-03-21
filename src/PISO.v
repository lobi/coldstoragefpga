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

    // States of the PISO state machine
    localparam          IDLE    = 1'b0, 
                        ACTIVE  = 1'b1;

    reg                 STATE = IDLE;
    reg [3:0]           count = 0;
    wire [10:0]         data_out;
    
    //  Construct the data_out frame: 1 start bit, 8 data bits (LSB first), 1 parity bit, 1 stop bit
    assign data_out = {1'b1, parity_bit, data_in, 1'b0};

    // To detect the rising edge of the send signal
    // reg send_prev;
    // always @(posedge baud_clk or negedge reset_n) begin
    //     if (!reset_n) begin
    //         send_prev <= 1'b0;
    //     end else begin
    //         send_prev <= send;
    //     end
    // end
    // wire send_rising_edge = send & ~send_prev;

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
                    if (send) 
                        STATE <= ACTIVE;
                    else 
                        STATE <= IDLE;
                    data_tx <= 1'b1;
                    active_flag <= 1'b0;
                    count <= 4'd0;
                    done_flag <= 1'b0;
                end
                ACTIVE: begin
                    if (count == 11) begin
                        // Done transmitting the frame, let's go back to IDLE state
                        STATE <= IDLE;
                        data_tx <= 1'b1;
                        active_flag <= 1'b0;
                        done_flag <= 1'b1;  
                        count <= 0;
                    end else begin
                        // Transmit the data
                        STATE <= ACTIVE;
                        data_tx <= data_out[count];
                        active_flag <= 1'b1;
                        done_flag <= 1'b0;
                        count <= count + 1'b1;
                    end
                end
            endcase

            $display("PISO state: %b, value: %b, of %c", STATE, data_tx, data_in);
        end
    end

endmodule