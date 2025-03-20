`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2025 06:48:05 PM
// Design Name: 
// Module Name: DHT11
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DHT11(
    input clk_1MHz,
    input rst_n,
    inout signal,
    output reg [7:0] humidity,
    output reg [7:0] temperature
    );
    
    parameter S_DELAY = 3'd0;
    parameter S_LOW_20MS = 3'd1;
    parameter S_HIGH_13US = 3'd2;
    parameter S_LOW_80US = 3'd3; 
    parameter S_HIGH_80US = 3'd4;
    parameter S_READ_DATA = 3'd5;
    
    reg [2:0] cur_state=0, next_state=0;
    reg [21:0] count_usec=0;
    reg [39:0] data_temp=0;
    reg count_usec_enable=0;
    reg dht_buffer = 1'bz;
    reg dht_d0 = 0,dht_d1 = 0;
    reg read_state = 0;
    reg [5:0] data_count = 0;
   
    wire next_stage;
    //wire clk_1MHz;
    wire dht_nedge = 0, dht_podge = 0;
     
    //clk_divider G (.clk(clk), .clk_(clk_usec));   
    
    //usec counter
    always @ (posedge clk_1MHz or negedge rst_n) begin
        if(!rst_n) count_usec =0;
        else if(count_usec_enable) count_usec = count_usec + 1;
        else count_usec =0;
    end
    //change state
    always @ (posedge clk_1MHz or negedge rst_n) begin
        if(!rst_n) cur_state = S_DELAY;
        else cur_state = next_state;       
    end
    
    //FSM
    always @ (posedge clk_1MHz or negedge rst_n) begin
        if(!rst_n) begin
            cur_state = S_DELAY; 
            count_usec_enable = 0;
            data_temp = 0;
            dht_buffer = 1'bz;
            read_state = 0;
            data_count = 0;
        end
        else begin
            case (cur_state) 
                S_DELAY : begin
                    if(count_usec <22'd3000000) begin
                        dht_buffer = 1'bz; // 임피던스 출력
                        count_usec_enable = 1;
                    end
                    else begin 
                        next_state = S_LOW_20MS;
                        count_usec_enable = 0;
                    end
                end
                S_LOW_20MS : begin
                    if(count_usec < 20000) begin
                        dht_buffer = 0;
                        count_usec_enable = 1;    
                    end
                    else begin
                        count_usec_enable = 0;
                        next_state = S_HIGH_13US;
                        dht_buffer = 1'bz;
                    end
                end
                S_HIGH_13US : begin
                    if (count_usec < 13) begin
                        dht_buffer = 1;
                        count_usec_enable = 1;
                    end
                    else begin
                        if(count_usec < 40) begin
                            count_usec_enable = 1;
                            dht_buffer = 1'bz;
                            if (dht_nedge) begin
                                next_state = S_LOW_80US;
                                count_usec_enable = 0;
                            end  
                        end 
                        else begin
                            next_state = S_DELAY;
                            count_usec_enable = 0;
                        end                                            
                    end
                end
                S_LOW_80US : begin
                    if (count_usec < 83) begin
                        count_usec_enable = 1;
                        if(dht_podge) begin
                            next_state = S_HIGH_80US;  
                            count_usec_enable = 0;  
                        end        
                    end
                    else begin
                        next_state = S_DELAY;
                        count_usec_enable = 0;  
                    end
                end
                S_HIGH_80US : begin
                    if (count_usec < 87) begin
                        count_usec_enable = 1;
                        if(dht_nedge) begin
                            next_state = S_READ_DATA;  
                            count_usec_enable = 0;  
                        end        
                    end
                    else begin
                        next_state = S_DELAY;
                        count_usec_enable = 0;  
                    end    
                end
                S_READ_DATA : begin
                    case (read_state)
                        0 : begin
                            if (count_usec < 60) begin
                                if(dht_podge) begin
                                    read_state = 1;
                                    count_usec_enable = 1;
                                end
                            end
                            else begin
                                next_state = S_DELAY;
                                count_usec_enable = 0;
                            end 
                        end
                        1 : begin
                            if(count_usec < 80) begin
                                if(dht_nedge) begin
                                    data_count = data_count + 1;
                                    count_usec_enable = 0;
                                    if(count_usec < 60) data_temp <= {data_temp[38:0],1'b0};                                  
                                    else data_temp <= {data_temp[38:0],1'b1};                                                                   
                                end
                                else count_usec_enable = 1;    
                            end
                            else begin
                                next_state = S_DELAY;
                                count_usec_enable = 0;
                            end    
                        end
                    endcase
                    if(data_count == 40) begin
                        data_count = 0;
                        next_state = S_DELAY;
                        if(data_temp[7:0] == data_temp[39:32] + data_temp[31:24] 
                                           + data_temp[23:16] + data_temp[15:8]) begin
                           humidity = data_temp[39:32];
                           temperature = data_temp[23:16];                   
                                           
                       end                                        
                    end
                end
                default : next_state = S_DELAY;
            endcase
        end
    end
    
    //edge detect  
    always @ (posedge clk_1MHz or negedge rst_n) begin
        if(!rst_n) begin
            dht_d0 = 0;
            dht_d1 = 0;
        end
        else begin
            dht_d1 <= dht_d0;
            dht_d0 <= signal;
        end
    end   
    
    assign dht_podge = ~dht_d1 & dht_d0;
    assign dht_nedge = dht_d1 & ~dht_d0; 
    assign signal = dht_buffer;    
endmodule
