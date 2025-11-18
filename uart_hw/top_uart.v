`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2025 11:20:41 PM
// Design Name: 
// Module Name: top_uart
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

module top_uart #(
  parameter F_CLK = 100000000,
  parameter BAUD  = 115200,
  parameter WORDS = 1023
)(
  input  wire        clk,
  input  wire        rst,
  input  wire        start_i,
  output wire        uart_txd,
  //output wire [31:0] data_out,
  output wire        full_1,
  output wire        full_2,
  output wire        loading_out,
  output reg         done_o
);
  wire [31:0] data_out;
  reg  dut_button_pulse;
  top_test U_DUT (
    .clk         (clk),
    .rst         (rst),
    .button      (dut_button_pulse),
    .data_out    (data_out),
    .full_1      (full_1),
    .full_2      (full_2),
    .loading_out (loading_out)
  );

  reg        tx_dv;
  reg [7:0]  tx_byte;
  wire       tx_active;
  wire       tx_done;
  uart_tx #(.F_CLK(F_CLK), .BAUD(BAUD)) U_TX (
    .clk        (clk),
    .data_valid (tx_dv),
    .tx_byte    (tx_byte),
    .tx_active  (tx_active),
    .tx_serial  (uart_txd),
    .tx_done    (tx_done)
  );

  reg [1:0] start_sync;
  always @(posedge clk) start_sync <= {start_sync[0], start_i};
  wire start_rise = (start_sync[1:0] == 2'b01);

  localparam [3:0]
    S_IDLE   = 4'd0,
    S_REQ    = 4'd1,
    S_WAIT0  = 4'd2,
    S_WAIT1  = 4'd3,
    S_LATCH  = 4'd4,
    S_B0     = 4'd5,
    S_B1     = 4'd6,
    S_B2     = 4'd7,
    S_B3     = 4'd8,
    S_NEXT   = 4'd9,
    S_DONE   = 4'd10;

  reg [3:0]  st;
  reg [31:0] word_latched;
  reg [12:0] word_cnt;

  task drive_byte;
    input [7:0] b;
    begin
      if (!tx_active) begin
        tx_byte <= b;
        tx_dv   <= 1'b1;
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      st                <= S_IDLE;
      tx_dv             <= 1'b0;
      tx_byte           <= 8'h00;
      dut_button_pulse  <= 1'b0;
      done_o            <= 1'b0;
      word_cnt          <= 13'd0;
      word_latched      <= 32'h0;
    end else begin
      tx_dv            <= 1'b0;
      dut_button_pulse <= 1'b0;

      case (st)
        S_IDLE: begin
          done_o   <= 1'b0;
          word_cnt <= 13'd0;
          if (start_rise) st <= S_REQ;
        end

        S_REQ: begin
          dut_button_pulse <= 1'b1;
          st <= S_WAIT0;
        end
        S_WAIT0: st <= S_WAIT1;
        S_WAIT1: st <= S_LATCH;

        S_LATCH: begin
          word_latched <= data_out;
          st <= S_B0;
        end

        S_B0: begin
          if (!tx_active) begin
            drive_byte(word_latched[7:0]);
            st <= S_B1;
          end
        end
        S_B1: begin
          if (!tx_active) begin
            drive_byte(word_latched[15:8]);
            st <= S_B2;
          end
        end
        S_B2: begin
          if (!tx_active) begin
            drive_byte(word_latched[23:16]);
            st <= S_B3;
          end
        end
        S_B3: begin
          if (!tx_active) begin
            drive_byte(word_latched[31:24]);
            st <= S_NEXT;
          end
        end

        S_NEXT: begin
          if (word_cnt == (WORDS-1)) begin
            st     <= S_DONE;
          end else begin
            word_cnt <= word_cnt + 1'b1;
            st       <= S_REQ;
          end
        end

        S_DONE: begin
          done_o <= 1'b1;
          if (start_rise) begin
            done_o   <= 1'b0;
            word_cnt <= 13'd0;
            st       <= S_REQ;
          end
        end
      endcase
    end
  end
endmodule
