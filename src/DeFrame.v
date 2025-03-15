module DeFrame(
    input wire  [10:0]  data_parll,     //  Data frame passed from the sipo unit.
    input wire          recieved_flag,

    output reg          parity_bit,     //  The parity bit separated from the data frame.
    output reg          start_bit,      //  The Start bit separated from the data frame.
    output reg          stop_bit,       //  The Stop bit separated from the data frame.
    output reg          done_flag,      //  Indicates that the data is recieved and ready for another data packet.
    output reg  [7:0]   raw_data        //  The 8-bits data separated from the data frame.
);

    //  Deframing 
    always @(*) 
    begin
        start_bit       = data_parll[0];
        raw_data[7:0]   = data_parll[8:1];
        parity_bit      = data_parll[9];
        stop_bit        = data_parll[10];
        done_flag       = recieved_flag;
    end

endmodule