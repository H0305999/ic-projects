`timescale 1ns/1ps
module tb_sync_fifo;

    localparam DW = 8;
    localparam AW = 3;

    reg  clk, rst_n, wr_en, rd_en;
    reg  [DW-1:0] din;
    wire [DW-1:0] dout;
    wire full, empty;

    sync_fifo #(.DW(DW), .AW(AW)) u_fifo (
        .clk(clk),     .rst_n(rst_n),
        .wr_en(wr_en), .din(din),   .full(full),
        .rd_en(rd_en), .dout(dout), .empty(empty)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (wr_en || rd_en)
            $strobe("t=%0t wr=%b rd=%b din=%h dout=%h | wptr=%b rptr=%b full=%b empty=%b",
                    $time, wr_en, rd_en, din, dout,
                    u_fifo.wptr, u_fifo.rptr, full, empty);
    end

    task do_write(input [DW-1:0] v);
        begin
            @(negedge clk); wr_en = 1'b1; din = v;
            @(negedge clk); wr_en = 1'b0;
        end
    endtask

    task do_read;
        begin
            @(negedge clk); rd_en = 1'b1;
            @(negedge clk); rd_en = 1'b0;
        end
    endtask

    integer i;
    reg [DW-1:0] wdata;
    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        rst_n = 1'b0; wr_en = 1'b0; rd_en = 1'b0; din = 8'h00;
        #12 rst_n = 1'b1;

        $display("== 1. 写 3 个数据 ==");
        do_write(8'hA1); do_write(8'hA2); do_write(8'hA3);

        $display("== 2. 读 2 个数据 ==");
        do_read; do_read;

        $display("== 3. 连写 8 次，第 8 次应该被 full 挡住 ==");
        for (i = 1; i <= 8; i = i + 1) begin
            wdata = 8'h10 + i;
            do_write(wdata);
        end

        $display("== 4. 全部读出，读空后 empty=1 ==");
        for (i = 1; i <= 8; i = i + 1) do_read;

        $display("== 5. 已经空了，再读一次应该被 empty 挡住 ==");
        do_read;

        #20;
        $display("---- 结束状态: wptr=%b rptr=%b full=%b empty=%b ----",
                 u_fifo.wptr, u_fifo.rptr, full, empty);
        $finish;
    end

endmodule
