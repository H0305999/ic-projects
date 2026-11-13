`timescale 1ns/1ps
module tb_seq_det;
reg clk,rst_n,in;
wire found;
seq_det u1 (.clk(clk),.rst_n(rst_n),.in(in),.found(found));
	initial clk = 0;
	always #5 clk = ~clk;
	initial begin
	$dumpfile("seq_det.vcd");
	$dumpvars(0,tb_seq_det);
	rst_n = 0;
	#7 rst_n = 1;
	#5 in = 1;
	#10 in = 0;
	#10 in = 1;
	#10 in = 1;
	#10 in = 0;
	#10 in = 1;
	#10 in = 0;
	#10 in = 1;
	#20 $finish;
	end
always @(posedge clk) begin
    if (found) $display("found @ %0t", $time);
end
endmodule
