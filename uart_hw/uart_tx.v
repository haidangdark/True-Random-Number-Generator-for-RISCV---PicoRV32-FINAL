`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2025 11:05:40 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
    parameter F_CLK = 100000000,
    parameter BAUD = 115200
)(
    input wire clk,
    input wire data_valid,
    input wire [7:0] tx_byte,
    output wire tx_active,
    output reg tx_serial,
    output wire tx_done
);
    localparam CLKS_PER_BIT = F_CLK / BAUD;


    localparam [2:0]
    s_IDLE = 3'b000,
    s_TX_START_BIT = 3'b001,
    s_TX_DATA_BITS = 3'b010,
    s_TX_STOP_BIT = 3'b011,
    s_CLEANUP = 3'b100;


    reg [2:0] state = s_IDLE;
    reg [15:0] clk_count = 16'd0;
    reg [2:0] bit_index = 3'd0;
    reg [7:0] tx_data = 8'h00;
    reg tx_done_r = 1'b0;
    reg tx_act_r = 1'b0;


    always @(posedge clk) begin
        case (state)
            s_IDLE: begin
                tx_serial <= 1'b1; // idle high
                tx_done_r <= 1'b0;
                clk_count <= 16'd0;
                bit_index <= 3'd0;
                if (data_valid) begin
                    tx_act_r <= 1'b1;
                    tx_data <= tx_byte;
                    state <= s_TX_START_BIT;
                end
            end
    
    
            s_TX_START_BIT: begin
                tx_serial <= 1'b0; // start bit
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1'b1; 
                end else begin
                    clk_count <= 16'd0;
                    state <= s_TX_DATA_BITS;
                end
            end
    
    
            s_TX_DATA_BITS: begin
                tx_serial <= tx_data[bit_index];
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1'b1; 
                end else begin
                    clk_count <= 16'd0;
                    if (bit_index < 3'd7)begin
                        bit_index <= bit_index + 1'b1; 
                    end else begin
                        bit_index <= 3'd0;
                        state <= s_TX_STOP_BIT;
                    end
                end
            end
    
    
            s_TX_STOP_BIT: begin
                tx_serial <= 1'b1; // stop bit
                if (clk_count < CLKS_PER_BIT-1)begin 
                    clk_count <= clk_count + 1'b1; 
                end else begin
                    tx_done_r <= 1'b1;
                    clk_count <= 16'd0;
                    tx_act_r <= 1'b0;
                    state <= s_CLEANUP;
                end
            end
    
    
            s_CLEANUP: begin
                tx_done_r <= 1'b1; // 1-cycle pulse
                state <= s_IDLE;
            end
        endcase
    end


    assign tx_active = tx_act_r;
    assign tx_done = tx_done_r;
endmodule
