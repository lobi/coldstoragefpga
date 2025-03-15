module BaudGenT(
    input wire          reset_n,
    input wire          clock,
    input wire [1:0]    baud_rate,
    output reg          baud_clk
);

    localparam          clock_freq  = 100_000_000;   // ZuBoard's clock frequency.
    localparam          BAUD_2400   = 2'b00,
                        BAUD_4800   = 2'b01,
                        BAUD_9600   = 2'b10,
                        BAUD_19200  = 2'b11;

    reg [14:0]          count;
    reg [14:0]          max_count;

    always @(*) begin
        case (baud_rate)
            BAUD_2400:  max_count = 15'd20833;       // clock_freq / baud_rate / 2
            BAUD_4800:  max_count = 15'd10416;     
            BAUD_9600:  max_count = 15'd5208;     
            BAUD_19200: max_count = 15'd2604;      
            default:    max_count = 15'd5208;       // 9600 baud rate
        endcase
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            count <= 13'd0;
            baud_clk <= 1'b0;
        end else begin
            if (count == max_count) begin
                count <= 13'd0;
                baud_clk <= ~baud_clk;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule
