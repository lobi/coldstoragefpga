module dht11_reader (
  input rst_n,          // Reset signal (active low)
  input wire en,        // Enable signal to start reading DHT11
  input wire clk,       // System clock (100MHz)
  inout wire dht_data,  // Bi-directional data line for DHT11
  output reg led1_test, // Test LED 1
  output reg led2_test, // Test LED 2
  output reg [7:0] humidity,
  output reg [7:0] temperature,
  output reg data_ready
);

  reg [5:0] state = 0;  // FSM state
  reg [31:0] counter;   // Timing counter
  reg [39:0] dht_data_reg; // 40-bit data storage
  integer bit_count = 0;

  // Drive the `dht_data` line low only during the start signal
  assign dht_data = (state == 1) ? 1'b0 : 1'bz;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= 0;
      counter <= 0;
      dht_data_reg <= 0;
      bit_count <= 0;
      humidity <= 0;
      temperature <= 0;
      data_ready <= 0;

      led1_test <= 1'b0;
      //led2_test <= 1'b0;
    end else if (en) begin
      //led2_test <= 1'b1;
      case (state)
        0: begin
          counter <= 0;
          data_ready <= 0;
          state <= 1;
          led1_test <= 1'b0;
          humidity <= 8'b0;
          temperature <= 8'b0;
        end

        1: begin
          counter <= counter + 1;
          if (counter >= 1800000) begin // 18 ms for 100 MHz clock
            state <= 2;
            counter <= 0;
          end
        end

        2: begin
          counter <= counter + 1;
          if (counter >= 40) begin // 20-40 µs delay
            state <= 3;
            counter <= 0;            
          end
        end

        3: begin
          if (dht_data == 0) begin
            state <= 4;
            counter <= 0;
          end
        end

        4: begin
          if (dht_data == 1) begin
            state <= 5;
            bit_count <= 0;
            dht_data_reg <= 0;
          end
        end

        5: begin
          if (dht_data == 1) begin
            counter <= counter + 1;
          end else if (dht_data == 0) begin
            if (counter > 5000) begin // If high pulse > 50 µs
              dht_data_reg <= {dht_data_reg[38:0], 1'b1};
            end else begin
              dht_data_reg <= {dht_data_reg[38:0], 1'b0};
            end
            bit_count <= bit_count + 1;
            counter <= 0;
          end

          if (bit_count == 40) begin
            state <= 6;
          end
        end

        6: begin
          if (dht_data_reg[39:32] + dht_data_reg[31:24] + dht_data_reg[23:16] + dht_data_reg[15:8] == dht_data_reg[7:0]) begin
            humidity <= dht_data_reg[39:32];
            temperature <= dht_data_reg[23:16] + 2; // add more 2 degrees to the temperature
            data_ready <= 1;
            led1_test <= 1'b1;
          end else begin
            data_ready <= 0;
          end
          state <= 0;
        end
      endcase
    end else begin
      state <= 0;
      counter <= 0;
      dht_data_reg <= 0;
      bit_count <= 0;
      data_ready <= 0;
      //led2_test <= 1'b0;
    end
  end
endmodule