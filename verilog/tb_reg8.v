`timescale 1ns/1ps
module tb_reg8;
reg clk,rst_n,en;
reg [7:0] d;
wire [7:0] q;
reg8 u1 (.clk(clk),.rst_n(rst_n),.en(en),.d(d),.q(q));
initial begin
clk = 0;
rst_n = 1;
en = 0;
d = 8'b11111111;
end
always #5 clk = ~clk;
initial begin
        $dumpfile("reg8.vcd");        // 生成波形文件
        $dumpvars(0, tb_reg8);        // 记录所有信号
	#7 rst_n = 0;
	#6 rst_n = 1;
	#1 en = 1;
	#5 en = 0;
	#5 d = 8'b11101110;
	#5 en = 1;
	#10 rst_n = 0;
	#100 $finish;
end
endmodule
