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


//module fifo32 #(
//    parameter DEPTH = 1023 // fifo nay chua dc 16 du lieu 32bit 2047     // 31 31 30 29 (depth 31, read_loop 31, write_loop 30 vaf tra ve 29
//    )(
//    input wire clk,
//    input wire rst,
//    input wire wr_en,
//    input wire [31:0] wr_data, //data in
//    input wire rd_en,
//    output reg [31:0] rd_data, //data out
//    output wire full,
//    output wire empty
//    );
//    reg [31:0] mem [DEPTH-1:0];//[0:DEPTH-1];
//    reg [$clog2(DEPTH):0] w_ptr; // con tro dung de di chuyen den index ghi
//    reg [$clog2(DEPTH):0] r_ptr; // con tro dung de di chuyen den index doc
//    reg [$clog2(DEPTH):0] count; // dung de den so luong du lieu con trong fifo
    
//    reg one_time_full;
//    assign full = (count == DEPTH);
//    assign empty = (count == 0);
    
    
//    reg flag_rd_en;
//    reg flag_wr_en;
    
    
//    always @(posedge clk or posedge rst ) begin //or posedge rd_en or posedge wr_en
//        if (rst) begin
//            w_ptr <= 0;
//            r_ptr <= 0;
//            count <= 0;
//            one_time_full <= 1;
//            flag_rd_en <= 1;
//            flag_wr_en <= 1;
//        end
//        else begin
//            // write
//            if (wr_en && count < DEPTH && one_time_full && flag_wr_en) begin
//                mem[w_ptr] <= wr_data;
//                count <= count + 1;
//                w_ptr <= w_ptr + 1;
//                flag_wr_en <= 0;
                
//            end
            
//            // read
//            if (rd_en && count > 0 && flag_rd_en) begin //r_ptr <= DEPTH
//                rd_data <= mem[r_ptr];
//                count <= count - 1;
//                r_ptr <= r_ptr + 1;
//                flag_rd_en <= 0;
                
//            end
            
//            if (!rd_en) begin
//                flag_rd_en <= 1;
//            end
//            if (!wr_en) begin
//                flag_wr_en <= 1;
//            end
            
            
//            if (count == DEPTH) begin
//                one_time_full <= 0;
//            end
//        end
//    end    
//endmodule


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

    // *** CHANGED: ép Vivado infer Block RAM (không reset mảng trong reset)
    reg [31:0] mem [DEPTH-1:0]; //[0:DEPTH-1];

    // *** CHANGED: thêm hàm clog2 cho width địa chỉ nếu cần (Vivado hỗ trợ $clog2, giữ nguyên cách tính của bạn).
    // reg [$clog2(DEPTH):0] w_ptr; // con tro dung de di chuyen den index ghi
    // reg [$clog2(DEPTH):0] r_ptr; // con tro dung de di chuyen den index doc
    // reg [$clog2(DEPTH):0] count; // dung de den so luong du lieu con trong fifo
    reg [$clog2(DEPTH):0] w_ptr; // con tro dung de di chuyen den index ghi
    reg [$clog2(DEPTH):0] r_ptr; // con tro dung de di chuyen den index doc
    reg [$clog2(DEPTH):0] count; // dung de den so luong du lieu con trong fifo

    reg one_time_full;
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    
    reg flag_rd_en;
    reg flag_wr_en;

    // *** CHANGED: pipeline địa chỉ đọc + dữ liệu đọc đồng bộ từ BRAM
    reg [$clog2(DEPTH)-1:0] raddr_q;       // địa chỉ đọc đã chốt 1 chu kỳ
    reg [31:0]               mem_dout;     // dữ liệu đọc từ BRAM (đồng bộ)

    // --------------------------------------------------------------------
    // KHỐI ĐIỀU KHIỂN (reset đồng bộ) - GIỮ logic điều kiện của bạn
    // - Không động chạm trực tiếp đến mảng mem ở đây
    // - Tạo tín hiệu "fire" cho write/read theo điều kiện hiện tại
    // - Quản lý con trỏ, counter, flags, và rd_data (lấy từ mem_dout)
    // --------------------------------------------------------------------
    always @(posedge clk) begin // *** CHANGED: bỏ posedge rst khỏi sensitivity của RAM
        if (rst) begin
            w_ptr         <= 0;
            r_ptr         <= 0;
            count         <= 0;
            one_time_full <= 1;
            flag_rd_en    <= 1;
            flag_wr_en    <= 1;

            // *** CHANGED: rd_data reset ở đây (không reset trong khối READ RAM)
            rd_data       <= 32'h0;
        end
        else begin
            // *** CHANGED: tạo điều kiện fire ghi/đọc (giữ nguyên điều kiện của bạn)
            // write
            if (wr_en && (count < DEPTH) && one_time_full && flag_wr_en) begin
                // Ghi thực tế vào RAM được làm ở always WRITE bên dưới
                // Cập nhật con trỏ & đếm phần tử giữ nguyên như bạn
                count      <= count + 1;
                w_ptr      <= w_ptr + 1;
                flag_wr_en <= 0;
            end

            // read
            if (rd_en && (count > 0) && flag_rd_en) begin
                // *** CHANGED: thay vì đọc trực tiếp mem[r_ptr] ở đây,
                // ta chốt địa chỉ raddr_q tại khối READ_ADDR (bên dưới)
                // và rd_data sẽ nhận từ mem_dout đồng bộ 1 chu kỳ sau (khối READ_DATA).
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

            // *** CHANGED: cập nhật rd_data từ mem_dout (đọc đồng bộ BRAM, trễ 1 clk)
            rd_data <= mem_dout;
        end
    end

    // --------------------------------------------------------------------
    // WRITE PORT - ghi vào BRAM (không có reset trong sensitivity)
    // --------------------------------------------------------------------
    always @(posedge clk) begin
        // *** CHANGED: ghi vào BRAM khi đúng điều kiện fire như khối control
        if (wr_en && (count < DEPTH) && one_time_full && flag_wr_en) begin
            // *** CHANGED: dùng địa chỉ ghi hiện tại (hành vi giống bạn: ghi trước rồi tăng w_ptr trong khối control)
            mem[w_ptr[$clog2(DEPTH)-1:0]] <= wr_data;
        end
        // *** LƯU Ý: không reset mem[] ở đây để Vivado infer BRAM
    end

    // --------------------------------------------------------------------
    // READ PORT - đọc BRAM đồng bộ 1 chu kỳ
    //   Chu kỳ N: chốt raddr_q = r_ptr khi điều kiện đọc thoả
    //   Chu kỳ N+1: mem_dout <= mem[raddr_q]; rd_data <= mem_dout (ở khối control)
    // --------------------------------------------------------------------
    always @(posedge clk) begin
        // *** CHANGED: đăng ký địa chỉ đọc khi có yêu cầu đọc
        if (rd_en && (count > 0) && flag_rd_en) begin
            raddr_q <= r_ptr[$clog2(DEPTH)-1:0];
        end
        // *** CHANGED: đọc đồng bộ từ BRAM - infer BRAM READ port
        mem_dout <= mem[raddr_q];
    end

endmodule