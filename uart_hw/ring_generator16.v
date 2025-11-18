`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2025 08:18:32 AM
// Design Name: 
// Module Name: ring_generator16
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
// 16-state Ring Generator (Fig.1 style) with four oscillator injection points
// - Mỗi state là 1 FF (q[15:0])
// - Output bit stream lấy tại FF15 (q[15])
// - Injection ⊕ tại các FF: 9, 12, 13, 0  (đúng 4 điểm trong hình)
// - Feedback theo polynomial: x^16 + x^10 + x^7 + x^4 + 1
//   => taps (0-based) : q[15], q[9], q[6], q[3]
// ======================================================================
module ring_generator16 (
    input  wire        clk,
    input  wire        rst,        // reset active-low: chỉ seed ring, KHÔNG reset OSC
    input  wire [3:0]  osc_in,       // 4 OSC injection inputs: {osc3,osc2,osc1,osc0}
    output wire        bit_out,      // Output bit stream (từ FF15)
    output reg  [15:0] q             // Trạng thái 16 FF để quan sát/debug
);
    // -----------------------------
    // 1) Feedback theo đa thức
    //    feedback = q15 ^ q9 ^ q6 ^ q3
    // -----------------------------
    wire feedback = q[15] ^ q[9] ^ q[6] ^ q[3];

    // -----------------------------
    // 2) Injection mapping (đúng 4 ⊕ trong Fig.1):
    //    - OSC tại đầu vào FF9
    //    - OSC tại đầu vào FF12
    //    - OSC tại đầu vào FF13
    //    - OSC tại đầu vào FF0
    //    (nếu muốn đổi, chỉnh các dòng gán dưới đây)
    // -----------------------------
    wire [15:0] inj_mask;
    assign inj_mask         = 16'b0;
    // map 4 OSC vào 4 điểm ⊕:
    wire inj_ff9  = osc_in[0];  // ⊕ vào FF9
    wire inj_ff12 = osc_in[1];  // ⊕ vào FF12
    wire inj_ff13 = osc_in[2];  // ⊕ vào FF13
    wire inj_ff0  = osc_in[3];  // ⊕ vào FF0

    // -----------------------------
    // 3) Next-state logic từng FF
    //    Quy ước dịch: FF0 <= feedback, FF1 <= q0, FF2 <= q1, ..., FF15 <= q14
    //    Sau đó cộng (XOR) với injection tại đúng FF tương ứng.
    // -----------------------------
    wire [15:0] d;

    // FF0 nhận feedback + injection tại FF0
    assign d[0]  = feedback;

    // FF1..FF15 nhận từ FF trước đó
    assign d[1]  = q[0] ^ inj_ff0;
    assign d[2]  = q[1];
    assign d[3]  = q[2] ^ q[12];
    assign d[4]  = q[3];
    assign d[5]  = q[4] ^ q[11];
    assign d[6]  = q[5] ^ q[9];
    assign d[7]  = q[6];
    assign d[8]  = q[7];
    assign d[9]  = q[8]  ^ inj_ff9;   // ⊕ injection vào FF9 (như hình)
    assign d[10] = q[9];
    assign d[11] = q[10];
    assign d[12] = q[11] ^ inj_ff12;  // ⊕ injection vào FF12
    assign d[13] = q[12] ^ inj_ff13;  // ⊕ injection vào FF13
    assign d[14] = q[13];
    assign d[15] = q[14];

    // -----------------------------
    // 4) FF bank (16 FF = 16 state)
    // -----------------------------
    // Seed non-zero để tránh lock 0 (có thể đổi SEED tuỳ ý)
    localparam [15:0] SEED = 16'hACE1;

    always @(posedge clk or posedge  rst) begin
        if (rst) begin
            q <= SEED;
        end else begin
            q <= d;
        end
    end

    // -----------------------------
    // 5) Output bit stream: lấy tại FF15 (đúng Fig.1)
    // -----------------------------
    assign bit_out = q[15];

endmodule

