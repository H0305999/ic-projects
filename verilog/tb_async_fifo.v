`timescale 1ns/1ps
module tb_async_fifo;

    localparam DW    = 8;
    localparam AW    = 3;
    localparam DEPTH = (1 << AW);
    localparam N     = 24;          // 总共搬 24 个数据（深度只有 8，必然写满几次）
    localparam SYNC  = 2;           // ← 同步器级数，改这里就能做对照实验

    reg  wclk, rclk, wrst_n, rrst_n;
    reg  wr_en, rd_en;
    reg  [DW-1:0] wdata;
    wire [DW-1:0] rdata;
    wire full, empty;

    async_fifo #(.DW(DW), .AW(AW), .SYNC(SYNC)) dut (
        .wclk(wclk),   .wrst_n(wrst_n), .wr_en(wr_en), .wdata(wdata), .full(full),
        .rclk(rclk),   .rrst_n(rrst_n), .rd_en(rd_en), .rdata(rdata), .empty(empty)
    );

    // 两个毫不相干的时钟：写 100MHz，读 62.5MHz（写比读快，所以一定会写满）
    always #5 wclk = ~wclk;
    always #8 rclk = ~rclk;

    reg  [DW-1:0] exp_q [0:N-1];    // 期望值队列：写进去什么，就该读出什么
    integer wr_cnt = 0, rd_cnt = 0, err_cnt = 0, full_times = 0;
    time t_done;
    integer i, j;                   // 写侧用 i，读侧用 j —— 两个进程绝不能共用一个循环变量

    //------------------------- 写侧 -------------------------
    initial begin
        wclk = 0; wrst_n = 0; wr_en = 0; wdata = 0;
        #37 wrst_n = 1;

        for (i = 0; i < N; i = i + 1) begin
            @(negedge wclk);
            while (full) @(negedge wclk);       // 满了就等，不许硬写
            wr_en = 1; wdata = i[DW-1:0];
            @(negedge wclk);                    // 跨过一个 posedge，数据真正写进去
            wr_en = 0;
            exp_q[wr_cnt] = i[DW-1:0];
            wr_cnt = wr_cnt + 1;
            repeat (i % 2) @(negedge wclk);
        end
        $display("[%0t] 写侧结束：共写 %0d 个", $time, wr_cnt);
    end

    //------------------------- 读侧 -------------------------
    initial begin
        rclk = 0; rrst_n = 0; rd_en = 0;
        #53 rrst_n = 1;

        for (j = 0; j < N; j = j + 1) begin
            @(negedge rclk);
            while (empty) @(negedge rclk);      // 空了就等
            rd_en = 1;
            @(negedge rclk);
            rd_en = 0;
            repeat (j % 3) @(negedge rclk);
        end
    end

    //-------------------- 自检：读出的对不对 --------------------
    always @(posedge rclk) begin
        if (rd_en && !empty) begin
            if (rdata !== exp_q[rd_cnt]) begin
                $display("!! 数据错 @%0t 第 %0d 个: 读到 %h, 应该是 %h",
                         $time, rd_cnt, rdata, exp_q[rd_cnt]);
                err_cnt = err_cnt + 1;
            end
            rd_cnt = rd_cnt + 1;
            if (rd_cnt == N) t_done = $time;
        end
    end

    always @(posedge full) full_times = full_times + 1;

    //------------------- 满空标志的变化时刻 -------------------
    always @(full)  $display("[%0t]   full  -> %b", $time, full);
    always @(empty) $display("[%0t]   empty -> %b", $time, empty);

    //------------------------- 收尾 -------------------------
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
        #3000;
        $display("==================================================");
        $display("同步级数 SYNC=%0d   深度 DEPTH=%0d", SYNC, DEPTH);
        $display("写入 %0d 个 / 读出 %0d 个 / 出错 %0d 个",
                 wr_cnt, rd_cnt, err_cnt);
        $display("搬完 %0d 个数据用了 %0t，full 拉高 %0d 次", N, t_done, full_times);
        $display("结束状态: full=%b empty=%b  wbin=%b  rbin=%b",
                 full, empty, dut.wbin, dut.rbin);
        if (rd_cnt == N && err_cnt == 0) $display(">>> TEST PASS：24 个数据跨两个时钟一个不差");
        else                             $display(">>> TEST FAIL");
        $finish;
    end

endmodule
