//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 10/14/2025 10:55:35 AM
//// Design Name: 
//// Module Name: fifo32
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////





module fifo32 #(
    parameter DEPTH = 1023 // fifo nay chua dc 16 du lieu 32bit 2047     // 31 31 30 29 (depth 31, read_loop 31, write_loop 30 vaf tra ve 29
    )(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire [31:0] wr_data, //data in
    input wire rd_en,
    output reg [31:0] rd_data, //data out
    output wire full,
    output wire empty
    );

  
    reg [31:0] mem [DEPTH-1:0]; //[0:DEPTH-1];


    reg [$clog2(DEPTH):0] w_ptr; // con tro dung de di chuyen den index ghi
    reg [$clog2(DEPTH):0] r_ptr; // con tro dung de di chuyen den index doc
    reg [$clog2(DEPTH):0] count; // dung de den so luong du lieu con trong fifo

    reg one_time_full;
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    
    reg flag_rd_en;
    reg flag_wr_en;

    reg [$clog2(DEPTH)-1:0] raddr_q;       // địa chỉ đọc đã chốt 1 chu kỳ
    reg [31:0]               mem_dout;     // dữ liệu đọc từ BRAM (đồng bộ)


    always @(posedge clk) begin 
        if (rst) begin
            w_ptr         <= 0;
            r_ptr         <= 0;
            count         <= 0;
            one_time_full <= 1;
            flag_rd_en    <= 1;
            flag_wr_en    <= 1;

            rd_data       <= 32'h0;
        end
        else begin
            // write
            if (wr_en && (count < DEPTH) && one_time_full && flag_wr_en) begin

                count      <= count + 1;
                w_ptr      <= w_ptr + 1;
                flag_wr_en <= 0;
            end

            // read
            if (rd_en && (count > 0) && flag_rd_en) begin

                count      <= count - 1;
                r_ptr      <= r_ptr + 1;
                flag_rd_en <= 0;
            end

            if (!rd_en) begin
                flag_rd_en <= 1;
            end
            if (!wr_en) begin
                flag_wr_en <= 1;
            end

            if (count == DEPTH) begin
                one_time_full <= 0;
            end

            rd_data <= mem_dout;
        end
    end


    always @(posedge clk) begin
        if (wr_en && (count < DEPTH) && one_time_full && flag_wr_en) begin
            mem[w_ptr[$clog2(DEPTH)-1:0]] <= wr_data;
        end
    end


    always @(posedge clk) begin
        if (rd_en && (count > 0) && flag_rd_en) begin
            raddr_q <= r_ptr[$clog2(DEPTH)-1:0];
        end
        mem_dout <= mem[raddr_q];
    end

endmodule