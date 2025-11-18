`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2025 11:04:09 AM
// Design Name: 
// Module Name: simple_ram_with_io
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


module simple_ram_with_io (
    input wire clk,
    input wire rst,
    
    // cpu mem interface
    input wire mem_valid,
    input wire [3:0] mem_wstrb,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    output reg [31:0] mem_rdata,
    output reg mem_ready,
    
    //FIFO_in
    output reg fifo1_wr_en,
    output reg [31:0] fifo1_wr_data,
    input wire fifo1_full,
    input wire fifo1_empty,
    input wire [31:0] fifo1_rd_data,
    output reg fifo1_rd_en, // co the pop tu fifo_in
    
    //FIFO_out
    output reg fifo2_wr_en,
    output reg [31:0] fifo2_wr_data,
    input wire fifo2_full,
    input wire fifo2_empty,
    
    //status signal
    output reg loading_out,
    output reg full_1,
    output reg full_2
    

    
);
    //reg flag_cancel_1st_fifo2_wr_en;
    (* ram_style = "block" *)  reg [31:0] mem_arr [0:2047]; //(* ram_style = "block" *)  
    integer i;

    initial begin
        for (i=0; i<2048; i=i+1) mem_arr[i] = 32'h0000_0013; // nop
        $readmemh("D:/HDL_DoAn/sw_project1_2/prog_mem.hex", mem_arr); // load code prog.hex "C:/Users/Dark/OneDrive/Tai liu/sw_project1_2/prog_mem.hex"  C:/Users/Dark/OneDrive/Tai liu/sw_project1_3/prog_mem.hex
    end

    always @(posedge clk ) begin //or posedge rst
        if (rst) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
            fifo1_wr_en <= 1'b0;
            fifo1_wr_data <= 32'h0;
            fifo1_rd_en <= 1'b0;
            fifo2_wr_en <= 1'b0;
            fifo2_wr_data <= 32'h0;
            loading_out <= 1'b0;
            full_1 <= 1'b0;
            full_2 <= 1'b0;
            //flag_cancel_1st_fifo2_wr_en <= 1'b1;
        end
        else begin
            
            mem_ready <= 1'b0;
            fifo1_wr_en <= 1'b0;
            fifo1_rd_en <= 1'b0;
            fifo2_wr_en <= 1'b0;
            
            
            full_1 <= fifo1_full;
            full_2 <= fifo2_full;
            
            if (mem_valid) begin
                mem_ready <= 1'b1;
                // RAM region 0x0000_0000
                if (mem_addr < 32'h00002000) begin
                    if (|mem_wstrb) begin
                        if (mem_wstrb[0]) mem_arr[mem_addr[12:2]][ 7: 0] <= mem_wdata[ 7: 0];
                        if (mem_wstrb[1]) mem_arr[mem_addr[12:2]][15: 8] <= mem_wdata[15: 8];
                        if (mem_wstrb[2]) mem_arr[mem_addr[12:2]][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) mem_arr[mem_addr[12:2]][31:24] <= mem_wdata[31:24];
                    end
                    mem_rdata <= mem_arr[mem_addr[12:2]];
                end 
                
                // FIFO_IN status at 0x30000000
                else if (mem_addr == 32'h30000000) begin
                     mem_rdata <= {30'h0, fifo1_empty, fifo1_full};
                end 
                
                // FIFO_IN read/pop at 0x30000004 (CPU does lw -> get data and cause pop)
                else if (mem_addr == 32'h30000004) begin
                    mem_rdata <= fifo1_rd_data;    // return current front data
                    fifo1_rd_en <= 1'b1;          // request pop (fifo will pop on posedge)
                end
                
                // FIFO_OUT write at 0x30000008 (CPU sw pushes into FIFO_OUT)
                else if (mem_addr == 32'h30000008) begin
                    if (|mem_wstrb) begin
//                        if (flag_cancel_1st_fifo2_wr_en == 1) begin
//                            flag_cancel_1st_fifo2_wr_en <= 1'b0;
//                            fifo2_wr_en  <= 1'b0;
//                        end
//                        else begin
//                            fifo2_wr_en  <= 1'b1;
//                        end
                        fifo2_wr_en  <= 1'b1;
                        fifo2_wr_data<= mem_wdata;
                    end
                    mem_rdata <= {31'h0, fifo2_full};
                end
                
                // CTRL at 0x30000010
                else if (mem_addr == 32'h30000010) begin
                    if (|mem_wstrb) begin
                        if (mem_wdata[0]) loading_out <= 1'b1; // CPU sets start
                        if (mem_wdata[1]) begin
                            // request external reset of FIFOs (top handles)
                            // expose via loading_out flag clearing etc.
                        end
                    end
                    mem_rdata <= {31'b0, loading_out};
                    // optionally clear when fifo2 full
                    if (fifo2_full) loading_out <= 1'b0;
                end
                
                else begin
                    mem_rdata <= 32'h0;
                end
                
                            
            end
            
            
        end
        
    end

endmodule


