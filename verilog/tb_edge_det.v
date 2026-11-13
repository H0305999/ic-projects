`timescale 1ns/1ps
module tb_edge_det;
    reg  clk, rst_n, sig;
    wire rise, fall;

    edge_det u1 (.clk(clk), .rst_n(rst_n), .sig(sig), .rise(rise), .fall(fall));

    initial begin clk = 0; rst_n = 0; sig = 0; end
    always #5 clk = ~clk;

    initial begin
        $dumpfile("edge_det.vcd");
        $dumpvars(0, tb_edge_det);
        #12 rst_n = 1;
        #5  sig = 1;        // 17ns 翻高
        #17 sig = 0;        // 34ns 翻低
        #17 sig = 1;        // 51ns 翻高
        #17 sig = 0;        // 68ns 翻低
        #40 $finish;
    end

    always @(posedge clk) begin
        if (rise) $display("rise @ %0t", $time);
        if (fall) $display("fall @ %0t", $time);
    end
endmodule

