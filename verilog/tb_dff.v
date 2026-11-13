`timescale 1ns/1ps
module tb_dff;
    reg clk, rst_n, d;
    wire q;

    dff u1 (.clk(clk), .rst_n(rst_n), .d(d), .q(q));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dff.vcd");
        $dumpvars(0, tb_dff);

        rst_n = 0;          // t=0    上电复位
        d = 0;
        #8  rst_n = 1;      // t=8    释放复位，离时钟沿 3ns
        #9  d = 1;          // t=17   15ns沿后2ns才变，20ns沿采样到1
        #10 d = 0;          // t=27   30ns沿采样到0
        #10 d = 1;          // t=37   40ns沿采样到1
        #11 rst_n = 0;      // t=48   异步复位：q立刻清零
        #10 rst_n = 1;      // t=58   释放复位
        #9  d = 0;          // t=67   70ns沿采样到0
        #53 $finish;        // t=120
    end
endmodule
