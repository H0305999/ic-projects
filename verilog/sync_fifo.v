// sync_fifo.v —— 同步 FIFO，深度 2^AW，位宽 DW
// 读写共用同一个时钟 clk
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
