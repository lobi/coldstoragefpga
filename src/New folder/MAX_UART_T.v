module top_uart(
    input       clk_1MHz,
   // input       btn,
    input wire rst_n,          // Active Low Reset
    input wire [15:0] heart_rate,  // 16-bit Heart Rate Data
    input wire [7:0] spo2,        // 8-bit SpO2 Data
    input       rx,
    output      tx
//    output      led
);

    reg         send;
    wire [7:0]  data_received;
    wire        rx_done_flag;
/*
    wire        btn_pressed;

     //  Instance for the rising edge detector
     rising_edge_detect BTN_pressed_detect(
         .clk            (clk),
        .btn            (btn),
         .rising_edge    (btn_pressed)
     );*/


    reg [7:0] data_buffer [0:3]; // Buffer to hold bytes for UART transmission
    reg [1:0] index = 0;
    reg send_signal = 0;
    
    wire done_flag;
    wire active_flag;
    wire start_tx = 1;
    // Load Heart Rate and SpO2 data into the buffer (Little Endian Format)
    always @(posedge clk_1MHz or negedge rst_n) begin
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

    Duplex UART_Driver(
        //  Inputs
        .reset_n        (1),
        .send           (btn), 
        .clock          (clk_1MHz),
        .parity_type    (2'b01),        // ODD parity
        .baud_rate      (2'b10),        // 9600 baud
        .data_transmit  (data_buffer[index]),        
        .rx             (rx),
        //  Outputs
        .tx             (tx),
        .tx_active_flag (),
        .tx_done_flag   (),
        .rx_active_flag (),
        .rx_done_flag   (rx_done_flag),
        .data_received  (data_received),
        .error_flag     ()
    );
/*
    // Instance for the LED toggle
    toggle_led LED_Toggle(
        .clk            (clk),
        .rx_done_flag   (rx_done_flag),
        .opcode         (data_received),
        .led            (led)
    );
  */  
    assign tx_done_flag = (index == 4) ? 1 : 0;

endmodule
