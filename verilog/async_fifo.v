`timescale 1ns/1ps
//==============================================================
//  异步 FIFO —— 写侧 wclk，读侧 rclk，两个时钟完全无关
//  两个域之间只靠"格雷码指针"通信，其余各管各的
//  参数：DW 数据位宽，AW 地址位宽（深度 = 2^AW，AW 至少为 2）
//==============================================================
module async_fifo #(
    parameter DW = 8,
    parameter AW = 3
)(
    // ---- 写侧 ----
    input               wclk,
    input               wrst_n,
    input               wr_en,
    input  [DW-1:0]     wdata,
    output              full,
    // ---- 读侧 ----
    input               rclk,
    input               rrst_n,
    input               rd_en,
    output [DW-1:0]     rdata,
    output              empty
);

    localparam DEPTH = (1 << AW);

    // 存储体：写域写、读域读，两边地址各算各的
    reg [DW-1:0] mem [0:DEPTH-1];

    //==========================================================
    //  写域
    //==========================================================
    reg  [AW:0] wbin, wgray;                        // 二进制 / 格雷码，多一位区分满空
    wire [AW:0] wbin_next  = wbin + (wr_en & ~full); // 只有真写进去才走指针
    wire [AW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;

    // 读指针的格雷码 → 同步进写域（两级触发器，打掉亚稳态）
    reg  [AW:0] rgray_w1, rgray_w2;
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) {rgray_w2, rgray_w1} <= {(AW+1){1'b0}};
        else         {rgray_w2, rgray_w1} <= {rgray_w1, rgray};

    // 格雷码判满：最高两位相反，其余各位相同
    // 注意：full 必须是寄存器输出。若写成组合 assign，会形成
    //   full -> wbin_next -> wgray_next -> full 的组合环路，仿真会震荡死锁
    reg full_r;
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) full_r <= 1'b0;
        else         full_r <= (wgray_next == {~rgray_w2[AW:AW-1], rgray_w2[AW-2:0]});
    assign full = full_r;

    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) {wbin, wgray} <= {(2*(AW+1)){1'b0}};
        else         {wbin, wgray} <= {wbin_next, wgray_next};

    // 写存储体：不加复位（真实 RAM 也没有复位端）
    always @(posedge wclk)
        if (wr_en && !full) mem[wbin[AW-1:0]] <= wdata;

    //==========================================================
    //  读域
    //==========================================================
    reg  [AW:0] rbin, rgray;
    wire [AW:0] rbin_next  = rbin + (rd_en & ~empty);
    wire [AW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;

    // 写指针的格雷码 → 同步进读域
    reg  [AW:0] wgray_r1, wgray_r2;
    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) {wgray_r2, wgray_r1} <= {(AW+1){1'b0}};
        else         {wgray_r2, wgray_r1} <= {wgray_r1, wgray};

    // 格雷码判空：两边完全相等（同样要寄存器输出，复位后是"空"）
    reg empty_r;
    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) empty_r <= 1'b1;
        else         empty_r <= (rgray_next == wgray_r2);
    assign empty = empty_r;

    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) {rbin, rgray} <= {(2*(AW+1)){1'b0}};
        else         {rbin, rgray} <= {rbin_next, rgray_next};

    // 队首数据直出（这里用组合读，方便 tb 同拍比对）
    assign rdata = mem[rbin[AW-1:0]];

endmodule
