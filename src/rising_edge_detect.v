module rising_edge_detect(
    input       clk,
    input       btn,
    output      rising_edge
);

    reg btn_d, btn_prev;

    always @(posedge clk) begin
        btn_d <= btn;
        btn_prev <= btn_d;
    end

    assign rising_edge = btn_d & ~btn_prev;

endmodule
