`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2025 03:26:36 PM
// Design Name: 
// Module Name: top_trng
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


module top_trng(
    input wire clk,
    input wire reset,
    //input wire peripheral_aresetn,
    input wire button_rst,
    input wire button,
    input wire button_start,
    output reg start,
    output wire [31:0] data_out, // final output
    //output wire [2:0] ledbit,
    output wire full_1,
    output wire full_2,
    output wire loading_out
    );
    
    reg bs_ff1, bs_ff2;      // 2 FF đồng bộ
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bs_ff1 <= 1'b0;
            bs_ff2 <= 1'b0;
        end else begin
            bs_ff1 <= button_start;
            bs_ff2 <= bs_ff1;
        end
    end

    // start là phiên bản đã đồng bộ của button_start, PS sẽ đọc được mức '1' khi bạn nhấn
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start <= 1'b0;
        end else begin
            start <= bs_ff2;
        end
    end
//    // 1) Debounce + đồng bộ nút (khuyên dùng, tối thiểu là đồng bộ 2 FF)
//reg b1,b2;
//always @(posedge clk) begin b1 <= button_rst; b2 <= b1; end
//wire button_rst_sync = b2;  // (thêm debounce nếu cần)

//// 2) Gộp hai nguồn thành reset active-high dạng async-assert
//wire rst_async = (~peripheral_aresetn) | button_rst_sync;

//// 3) Async assert, sync deassert
//reg [1:0] rst_ff;
//always @(posedge clk or posedge rst_async) begin
//  if (rst_async) rst_ff <= 2'b11;             // assert ngay
//  else           rst_ff <= {1'b0, rst_ff[1]}; // nhả theo clk
//end
//wire rst = rst_ff[0];  // dùng rst cho toàn bộ logic theo clk
    
    
    wire rst;
    assign rst = ~reset | button_rst;
//     wire full_1;
//     wire full_2;
//     wire loading_out;
    // TRNG + fifoin
    wire [31:0] trng_word;
    wire trng_valid;
    
    catching_random_number catching_random_number(
        .clk(clk),
        .rst(rst),
        .data_out(trng_word),
        .data_valid(trng_valid)
    );
    
    wire fifo1_full, fifo1_empty;
    wire [31:0] fifo1_rd_data;
    wire fifo1_rd_en;
    wire fifo1_wr_en;
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
    wire fifo2_full, fifo2_empty;
    wire [31:0] fifo2_rd_data;
    wire fifo2_wr_en;
    wire [31:0] fifo2_wr_data;
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
    wire [31:0] mem_addr, mem_rdata , mem_wdata;
    wire [3:0]  mem_wstrb;

    RAM_FOR_PICO uv_ram (
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
    
    //assign ledbit = {full_1, full_2, loading_out};  // ledbit[2]=full_1, [1]=full_2, [0]=loading_out
    
    
    
    
    
    
endmodule
