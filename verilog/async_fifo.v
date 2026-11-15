`timescale 1ns/1ps
//==============================================================================
//  Module   : async_fifo
//  Function : 异步 FIFO（双时钟），写侧 wclk 与读侧 rclk 频率、相位完全无关
//  Author   : H0305999
//  Date     : 2026-11-15
//------------------------------------------------------------------------------
//  参数
//    DW    数据位宽，默认 8
//    AW    地址位宽，深度 = 2^AW，默认 8 格；要求 AW >= 2
//    SYNC  同步器级数，默认 2；最小时 2，级数越多越保守
//
//  端口
//    写侧：wclk / wrst_n / wr_en / wdata / full
//    读侧：rclk / rrst_n / rd_en / rdata / empty
//
//  时序
//    写：wr_en && !full 的那个 wclk 上升沿，数据写入 mem
//    读：rd_en && !empty 的那个 rclk 上升沿，rdata 组合直出（同拍有效）
//    指针跨域后延迟 SYNC 个对方时钟周期才可见
//------------------------------------------------------------------------------
//  实现要点
//    1. 指针 AW+1 位，最高位用来区分"指针相等"的空与"差整一圈"的满
//    2. 跨域只传格雷码：相邻值只差 1 位，采样误差最大 1 格，不会撕裂
//    3. 每个域各自判满/判空，判据使用本域的 next 值（提前一拍挡住下一拍）
//    4. 格雷码判满：最高两位相反、其余相同；判空：完全相等
//    5. full / empty 必须寄存器输出，否则 full -> wbin_next -> wgray_next -> full
//       形成组合环，仿真会振荡死锁
//    6. mem 不加复位（对齐真实 SRAM），地址只用低 AW 位
//    7. 同步链标注 ASYNC_REG，禁止综合工具优化、合并或拆散
//------------------------------------------------------------------------------
//  已知取舍
//    full / empty 是悲观的：可能提前报满、提前报空，但绝不会晚报
//    因此不会溢出、不会读空；代价是有效容量略小于标称深度
//    有效容量 ≈ DEPTH - SYNC（最坏情况），同步级数每 +1，边界吞吐再慢一拍
//==============================================================================
module async_fifo #(
    parameter DW   = 8,
    parameter AW   = 3,
    parameter SYNC = 2          // 同步器级数，至少 2；改成 3、4 可以观察"保守"的代价
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

    // 读指针的格雷码 → 同步进写域（SYNC 级触发器串联，第一级允许亚稳，最后一级必干净）
    // ASYNC_REG 告诉综合工具：这是一条同步器链，别优化、别拆散、放近点
    (* ASYNC_REG = "TRUE" *) reg [AW:0] rgray_s [0:SYNC-1];
    genvar gi;
    generate
        for (gi = 0; gi < SYNC; gi = gi + 1) begin : g_r2w
            always @(posedge wclk or negedge wrst_n)
                if (!wrst_n)      rgray_s[gi] <= {(AW+1){1'b0}};
                else if (gi == 0) rgray_s[gi] <= rgray;
                else              rgray_s[gi] <= rgray_s[gi-1];
        end
    endgenerate
    wire [AW:0] rgray_sync = rgray_s[SYNC-1];

    // 格雷码判满：最高两位相反，其余各位相同
    // 注意：full 必须是寄存器输出。若写成组合 assign，会形成
    //   full -> wbin_next -> wgray_next -> full 的组合环路，仿真会震荡死锁
    reg full_r;
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) full_r <= 1'b0;
        else         full_r <= (wgray_next == {~rgray_sync[AW:AW-1], rgray_sync[AW-2:0]});
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
    (* ASYNC_REG = "TRUE" *) reg [AW:0] wgray_s [0:SYNC-1];
    genvar gj;
    generate
        for (gj = 0; gj < SYNC; gj = gj + 1) begin : g_w2r
            always @(posedge rclk or negedge rrst_n)
                if (!rrst_n)      wgray_s[gj] <= {(AW+1){1'b0}};
                else if (gj == 0) wgray_s[gj] <= wgray;
                else              wgray_s[gj] <= wgray_s[gj-1];
        end
    endgenerate
    wire [AW:0] wgray_sync = wgray_s[SYNC-1];

    // 格雷码判空：两边完全相等（同样要寄存器输出，复位后是"空"）
    reg empty_r;
    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) empty_r <= 1'b1;
        else         empty_r <= (rgray_next == wgray_sync);
    assign empty = empty_r;

    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) {rbin, rgray} <= {(2*(AW+1)){1'b0}};
        else         {rbin, rgray} <= {rbin_next, rgray_next};

    // 队首数据直出（这里用组合读，方便 tb 同拍比对）
    assign rdata = mem[rbin[AW-1:0]];

endmodule
