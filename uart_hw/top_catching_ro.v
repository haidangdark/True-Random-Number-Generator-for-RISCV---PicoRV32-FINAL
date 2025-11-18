`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 11:02:44 AM
// Design Name: 
// Module Name: top_catching_ro
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


module top_catching_ro(
    input wire clk,
    input wire rst,
    
    output wire [31:0] data_out,
    output wire data_valid

    );
    
    
    

    
//    XOR_RO XOR_RO(
//        .clk(clk),
//        .XOR_RESULT(result)
//    );
    

    
    wire T;
    wire I1;
    wire I2;
    wire OSC1,OSC2, OSC3, OSC4;
    assign T = 1;
    assign I1 = 1;
    assign I2 = 2;

    
    osc_cell osc_cell1(
        .T(T),
        .I1(I1),
        .I2(I2),
        .OSC(OSC1)
    );
    
    osc_cell osc_cell2(
        .T(T),
        .I1(I1),
        .I2(I2),
        .OSC(OSC2)
    );
    
    osc_cell osc_cell3(
        .T(T),
        .I1(I1),
        .I2(I2),
        .OSC(OSC3)
    );
    
    osc_cell osc_cell4(
        .T(T),
        .I1(I1),
        .I2(I2),
        .OSC(OSC4)
    );
    
    wire [3:0] osc_in;
    assign osc_in = {OSC1,OSC2,OSC3,OSC4};
    wire result;
    wire [15:0] debug_ring;
    ring_generator16 ring_generator16(
        .clk(clk),
        .rst(rst),
        .osc_in(osc_in),
        .bit_out(result),
        .q(debug_ring)
    );
    
    catching_ro catching_ro (
        .clk(clk),
        .rst(rst),
        .data_in(result),
        .data_out(data_out),
        .data_valid(data_valid)
    );
endmodule

