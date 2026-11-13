module tick_gen #(parameter DIV = 5)
(input clk,rst_n,output reg tick);
	reg [7:0] cnt;
	always @(posedge clk) begin
		if (!rst_n) begin
			cnt <= 8'd0;
			tick <= 0;
		end
		else if(cnt == DIV-1) begin
			tick <= 1;
			cnt <= 8'd0;
		end
		else begin
			cnt <= cnt+8'd1;
			tick <= 0;
		end
	end
endmodule
