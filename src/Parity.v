module Parity(
    input wire          reset_n,
    input wire [7:0]    data_in,
    input wire [1:0]    parity_type,
    output reg          parity_bit
);

    localparam          ODD         = 2'b01,
                        EVEN        = 2'b10,
                        NOPARITY00  = 2'b00,
                        NOPARITY11  = 2'b11;
    
    always @(*) begin
        if (!reset_n) parity_bit = 1'b1;
        else begin
            case (parity_type)
                NOPARITY00, NOPARITY11: parity_bit = 1'b1;
                ODD:        parity_bit = ~^data_in;
                EVEN:       parity_bit = ^data_in;
                default:    parity_bit = 1'b1;
            endcase
        end                
    end

endmodule
