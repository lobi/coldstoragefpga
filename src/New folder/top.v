module top_UART(
    input       clk,
    input       btn,
    input       rx,
    output      tx,
    output      led
);

    reg         send;
    wire [7:0]  data_received;
    wire        rx_done_flag;



    Duplex UART_Driver(
        //  Inputs
        .reset_n        (1),
        .send           (btn), 
        .clock          (clk),
        .parity_type    (2'b01),        // ODD parity
        .baud_rate      (2'b10),        // 9600 baud
        .data_transmit  (8'h55),        // ASCII of 'U'
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


    //wire        btn_pressed;
    // //  Instance for the rising edge detector
    // rising_edge_detect BTN_pressed_detect(
    //     .clk            (clk),
    //     .btn            (btn),
    //     .rising_edge    (btn_pressed)
    // );
 /*   // Instance for the LED toggle
    toggle_led LED_Toggle(
        .clk            (clk),
        .rx_done_flag   (rx_done_flag),
        .opcode         (data_received),
        .led            (led)
    );*/


endmodule
