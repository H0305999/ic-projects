`timescale 1ns/1ps
module tb_cnt10;
reg clk,rst_n,en;
wire [3:0] cnt;
cnt10 u1 (.clk(clk), .rst_n(rst_n), .en(en), .cnt(cnt));
initial begin
rst_n = 0;
clk = 0;
en = 1;
end
always #5
clk = ~clk;
initial begin
$dumpfile("cnt10.vcd");
$dumpvars(0,tb_cnt10);
#15 rst_n = 1;
#10 rst_n = 1;
#110 en = 0;
#30 en = 1;
#100 $finish;
end
endmodule
