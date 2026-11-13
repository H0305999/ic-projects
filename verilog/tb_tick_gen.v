`timescale 1ns/1ps
module tb_tick_gen;
reg clk,rst_n;
wire tick;
tick_gen #(.DIV(4)) u1 (.clk(clk),.rst_n(rst_n),.tick(tick));
initial begin
clk = 0;
rst_n = 0;
end
always #5 clk = ~clk;
initial begin
$dumpfile("tick_gen.vcd");
$dumpvars(0,tb_tick_gen);
#7 rst_n = 1;
#200 $finish;
end
endmodule
