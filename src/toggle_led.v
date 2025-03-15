module toggle_led(
    input       clk,
    input       rx_done_flag,
    input [7:0] opcode,
    output      led
);

    reg         led_state;
    wire        rx_done_flag_rising_edge;

    rising_edge_detect RX_done_detect(
        .clk            (clk),
        .btn            (rx_done_flag),
        .rising_edge    (rx_done_flag_rising_edge)
    );

    always @(posedge clk) begin
        if (rx_done_flag_rising_edge &&  (opcode == 8'h55)) begin
            led_state <= ~led_state;
        end
    end

    assign led = led_state;

endmodule
