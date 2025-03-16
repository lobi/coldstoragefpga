module UART_Transmit (
    input wire clock,            // System Clock
    input wire rst_n,          // Active Low Reset
   // input wire start_tx,       // Signal to Start Transmission
    input wire [15:0] heart_rate,  // 16-bit Heart Rate Data
    input wire [7:0] spo2,        // 8-bit SpO2 Data
    input   wire  [1:0]  parity_type,   //  Parity type agreed upon by the Tx and Rx units.
    input   wire  [1:0]  baud_rate,     //  Baud Rate agreed upon by the Tx and Rx units.
 
    output wire data_tx,         // UART TX Line
    output wire tx_done          // Transmission Done
);

    reg [7:0] data_buffer [0:3]; // Buffer to hold bytes for UART transmission
    reg [1:0] index = 0;
    reg send_signal = 0;
    
    wire done_flag;
    wire active_flag;
    wire start_tx = 1;
    // Load Heart Rate and SpO2 data into the buffer (Little Endian Format)
    always @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            index <= 0;
            send_signal <= 0;
        end else if (start_tx) begin
            data_buffer[0] <= heart_rate[7:0];   // Lower byte
            data_buffer[1] <= heart_rate[15:8];  // Upper byte
            data_buffer[2] <= spo2;              // SpO2 Value
            data_buffer[3] <= 8'h0A;             // New Line (ASCII '\n')
            send_signal <= 1;
        end else if (done_flag) begin
            index <= index + 1;
            send_signal <= (index < 4) ? 1 : 0;
        end
    end

    // Instantiate TxUnit to send data
    TxUnit uart_tx (
        .reset_n(rst_n),
        .send(send_signal),
        .clock(clock),
        .parity_type(parity_type),
        .baud_rate(baud_rate),
        .data_in(data_buffer[index]),
        .data_tx(data_tx),
        .active_flag(active_flag),
        .done_flag(done_flag)
    );

    assign tx_done = (index == 4) ? 1 : 0;

endmodule


