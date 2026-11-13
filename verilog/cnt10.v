module cnt10 (input clk,rst_n,en,output reg [3:0] cnt);
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			cnt <= 4'd0;
		else if (en) begin
			if(cnt == 4'd9)
				cnt <= 4'd0;
			else
				cnt <= cnt+4'd1;
		end
	end
endmodule
