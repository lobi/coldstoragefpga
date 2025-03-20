`timescale 1ns / 1ps

module top_tb;

    // Khai báo tín hiệu
    reg         clk;                // Xung nhịp chính
    reg         rst_n;              // Tín hiệu reset tích cực mức thấp
    reg  [7:0]  temperature;        // Giá trị nhiệt độ đầu vào
    reg  [7:0]  humidity;           // Giá trị độ ẩm đầu vào
    
    wire        scl;                // Đường clock I2C
    wire        sda;                // Đường dữ liệu I2C (hai chiều)

    // Khởi tạo module cần kiểm tra (UUT)
    top uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .temperature (temperature),
        .humidity    (humidity),
        .scl         (scl),
        .sda         (sda)
    );

    // Tạo xung nhịp
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Xung nhịp 100 MHz (chu kỳ 10 ns)
    end

    // Chuỗi kiểm tra
    initial begin
        // Reset hệ thống
        rst_n = 0;
        temperature = 8'd0;
        humidity = 8'd0;
        #20 rst_n = 1;

        // Kiểm tra các trường hợp khác nhau
        #100 temperature = 8'd25; humidity = 8'd60; // 25 độ C, 60% độ ẩm
        #100 temperature = 8'd40; humidity = 8'd90; // 40 độ C, 90% độ ẩm
        #100 temperature = 8'd10; humidity = 8'd20; // 10 độ C, 20% độ ẩm
        #100 temperature = 8'd99; humidity = 8'd99; // 99 độ C, 99% độ ẩm
        #100 temperature = 8'd0;  humidity = 8'd0;  // 0 độ C, 0% độ ẩm
        
        // Kết thúc mô phỏng
        #1000 $stop;
    end

    // Theo dõi tín hiệu đầu ra
    initial begin
        $monitor("%t | Temp: %d | Humi: %d | SCL: %b | SDA: %b",
                 $time, temperature, humidity, scl, sda);
    end

endmodule
