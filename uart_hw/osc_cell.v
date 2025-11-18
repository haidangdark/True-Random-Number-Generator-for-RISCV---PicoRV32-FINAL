`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2025 07:37:53 AM
// Design Name: 
// Module Name: osc_cell
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


// ======================================================================
// OSC CELL (paper-like, no explicit reset pin)
// Reset   : T=0, I1=0, I2=0
// Arm     : I1=1 & I2=0  (hoặc I1=0 & I2=1)
// Start   : T=1  -> free-running oscillation
// ======================================================================
(* KEEP_HIERARCHY = "TRUE" *)
module osc_cell (
    input  wire T,   // trigger
    input  wire I1,  // arm input 1
    input  wire I2,  // arm input 2
    output wire OSC  // free-running output
);
    // Vòng XOR/AND nối chéo (combinational loop) - cố ý để dao động nhờ trễ LUT/route
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) wire x1, a1, x2, a2;

    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign x1 = I1 ^ a2;
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign a1 = T & x1;
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign x2 = I2 ^ a1;
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign a2 = T & x2;

    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign OSC = a2;
endmodule

