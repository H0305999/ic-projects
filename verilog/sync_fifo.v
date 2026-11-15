//==============================================================================
//  Module   : sync_fifo
//  Function : 同步 FIFO（单时钟），深度 2^AW，位宽 DW
//  Author   : H0305999
//  Date     : 2026-11-14
//------------------------------------------------------------------------------
//  参数
//    DW    数据位宽，默认 8
//    AW    地址位宽，深度 = 2^AW，默认 8 格；要求 AW >= 2
//
//  时序
//    写：wr_en && !full 的那个 clk 上升沿，数据写入 mem
//    读：rd_en && !empty 的那个 clk 上升沿，dout 下一拍有效（寄存器输出）
//------------------------------------------------------------------------------
//  实现要点
//    1. 指针 AW+1 位：最高位用来区分"指针相等"的空与"差整一圈"的满
//    2. 空 = 两指针完全相等；满 = 最高位相反且低位相同
//    3. 存储体不加复位（对齐真实 SRAM），地址只取低 AW 位
//    4. 指针与 dout 均异步复位，复位后 empty = 1
//    5. dout 打一拍输出：无毛刺，且与多数 FIFO IP 的默认行为一致
//==============================================================================
module sync_fifo #(
    parameter DW = 8,          // 数据位宽
    parameter AW = 3           // 地址位宽，深度 = 2^AW = 8
)(
    input               clk,
    input               rst_n,       // 异步复位，低有效

    input               wr_en,       // 写请求
    input  [DW-1:0]     din,         // 写数据
    output              full,        // 满：满了不许再写

    input               rd_en,       // 读请求
    output reg [DW-1:0] dout,        // 读数据，读命令后一拍有效
    output              empty        // 空：空了没得读
);

    localparam DEPTH = (1 << AW);

    reg [DW-1:0] mem [0:DEPTH-1];    // 存储体：8 个格子
    reg [AW:0]   wptr, rptr;         // 指针 4 位 = 3 位地址 + 1 位绕圈标记

    wire wr_fire = wr_en & ~full;    // 真正写进去的条件
    wire rd_fire = rd_en & ~empty;   // 真正读出来的条件

    assign empty = (wptr == rptr);
    assign full  = (wptr[AW] != rptr[AW]) && (wptr[AW-1:0] == rptr[AW-1:0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        wptr <= {(AW+1){1'b0}};
        else if (wr_fire)  wptr <= wptr + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        rptr <= {(AW+1){1'b0}};
        else if (rd_fire)  rptr <= rptr + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        dout <= {DW{1'b0}};
        else if (rd_fire)  dout <= mem[rptr[AW-1:0]];
    end

    always @(posedge clk) begin
        if (wr_fire)       mem[wptr[AW-1:0]] <= din;
    end

endmodule
