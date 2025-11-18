`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 11:06:05 AM
// Design Name: 
// Module Name: top_test
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


module top_test(
    input wire clk,
    input wire rst,
    input wire button,
    
    
    output wire [31:0] data_out,
    //output wire [3:0] data_output,
    output wire full_1,
    output wire full_2,
    output wire loading_out
    );
    
    //wire [31:0] data_out;
    wire [3:0] data_output;
    wire [31:0] fifo2_wr_data;
    wire [31:0] trng_word;
    wire [31:0] fifo1_rd_data;
    wire [31:0] mem_wdata;
     wire fifo1_full;
     wire fifo1_empty;
     wire fifo1_rd_en;
     wire fifo2_full;
     wire fifo2_empty;
     wire fifo2_wr_en;
     wire fifo1_wr_en;
     wire [31:0] mem_addr;
     wire [31:0] mem_rdata;
    
 top_full_fn1 top_full_fn1(
    .clk(clk),
    .rst(rst),
    .button(button),
    
    .data_out(data_out), // final output
    .data_output(data_output),
    .full_1(full_1),
    .full_2(full_2),
    .loading_out(loading_out),
    .fifo2_wr_data(fifo2_wr_data),
    .trng_word(trng_word),
    .fifo1_rd_data(fifo1_rd_data),
    .mem_wdata(mem_wdata),
    
    
    .fifo1_full(fifo1_full),
    .fifo1_empty(fifo1_empty),
    .fifo1_rd_en(fifo1_rd_en),
    .fifo2_full(fifo2_full),
    .fifo2_empty(fifo2_empty),
    .fifo2_wr_en(fifo2_wr_en),
    .fifo1_wr_en(fifo1_wr_en),
    .mem_addr(mem_addr), 
    .mem_rdata(mem_rdata)
    
    );

endmodule
