`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 11:04:56 AM
// Design Name: 
// Module Name: top_full_fn1
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


module top_full_fn1(
    input wire clk,
    input wire rst,
    input wire button,
    
    output wire [31:0] data_out, // final output
    output wire [3:0] data_output,
    output wire full_1,
    output wire full_2,
    output wire loading_out,
    output wire [31:0] fifo2_wr_data,
    output wire [31:0] trng_word,
    output wire [31:0] fifo1_rd_data,
    output wire [31:0] mem_wdata,
    
    
    output wire fifo1_full,
    output wire fifo1_empty,
    output wire fifo1_rd_en,
    output wire fifo2_full,
    output wire fifo2_empty,
    output wire fifo2_wr_en,
    output wire fifo1_wr_en,
    output wire [31:0] mem_addr, 
    output wire [31:0] mem_rdata
    
    );
    
    // TRNG + fifoin
    //wire [31:0] trng_word;
    wire trng_valid;
    
    top_catching_ro uv_top_catching(
        .clk(clk),
        .rst(rst),
        .data_out(trng_word),
        .data_valid(trng_valid)
    );
    
   // wire fifo1_full, fifo1_empty;
    //wire [31:0] fifo1_rd_data;
    //wire fifo1_rd_en;
    
    assign fifo1_wr_en = trng_valid & ~fifo1_full; // auto write while fifo1 not full
    wire [31:0] fifo1_wr_data = trng_word;
    fifo32 #(.DEPTH(  1023/*16*/  )) fifo_in(
        .clk(clk),
        .rst(rst),
        .wr_en(fifo1_wr_en),
        .wr_data(fifo1_wr_data),
        .rd_en(fifo1_rd_en),
        .rd_data(fifo1_rd_data),
        .full(fifo1_full),
        .empty(fifo1_empty)
    );
    
    
    //fifo_out
   // wire fifo2_full, fifo2_empty;
    wire [31:0] fifo2_rd_data;
    //wire fifo2_wr_en;
    //wire [31:0] fifo2_wr_data;
    wire fifo2_rd_en = button ;//& ~fifo2_empty; // pop ra khi co data va dc bam nut
    
    fifo32 #(.DEPTH(  1023/*16*/  )) fifo_out(
        .clk(clk),
        .rst(rst),
        .wr_en(fifo2_wr_en),
        .wr_data(fifo2_wr_data),
        .rd_en(fifo2_rd_en),
        .rd_data(fifo2_rd_data),
        .full(fifo2_full),
        .empty(fifo2_empty)        
    );
    
    assign data_out = fifo2_rd_data;
    
    // ---------- PicoRV32 + RAM/MMIO ----------
    wire mem_valid, mem_ready;
    //wire [31:0] mem_addr, mem_rdata  ;//, mem_wdata;
    wire [3:0]  mem_wstrb;

    simple_ram_with_io uv_ram (
        .clk(clk), .rst(rst),
        .mem_valid(mem_valid),
        .mem_wstrb(mem_wstrb),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),

        // FIFO1 (input TRNG)
        .fifo1_full(fifo1_full),
        .fifo1_empty(fifo1_empty),
        .fifo1_rd_data(fifo1_rd_data),
        .fifo1_rd_en(fifo1_rd_en),

        // FIFO2 (output data)
        .fifo2_wr_en(fifo2_wr_en),
        .fifo2_wr_data(fifo2_wr_data),
        .fifo2_full(fifo2_full),
        .fifo2_empty(fifo2_empty),

        // Status outputs
        .loading_out(loading_out),
        .full_1(full_1),
        .full_2(full_2)
    );

    // ---------- CPU ----------
    picorv32 #(
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0)
    ) uv_cpu (
        .clk       (clk),
        .resetn    (~rst),
        .mem_valid (mem_valid),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata),
        .mem_instr ()
    );    
    
    
    
    assign data_output = data_out[3:0];
    
    
    
endmodule
