`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 10:54:25 AM
// Design Name: 
// Module Name: catching_ro
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


module catching_ro(
    input wire clk,
    input wire rst,
    input wire data_in,  // 1 bit from RO
    
    output reg [31:0] data_out,
    output reg data_valid     // bang 1 khi data_out shift xong 32 bit
    );
    
    reg [4:0] bit_counter;
    reg [31:0] shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift <= 32'h00000000;
            bit_counter <= 0;
            data_out <= 32'h00000000;
            data_valid <= 1'b0;
        end
        
        else begin
            data_valid <= 1'b0;
            shift <= {shift[30:0], data_in};
            if (bit_counter == 31) begin
                bit_counter <= 0;
                data_out <= {shift[30:0], data_in};
                data_valid <= 1'b1;
            end
            else begin
                bit_counter <= bit_counter + 1;
            end
        end
    end

endmodule
