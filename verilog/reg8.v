module reg8 (input clk,rst_n,en,input [7:0] d,output reg [7:0] q);
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			q <= 8'b0;
		else if (en)
			q <=d;
		else
			q <=q;
end
endmodule
