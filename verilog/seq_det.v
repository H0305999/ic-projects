module seq_det(input clk,rst_n,in,output found);
	parameter s0=0,s1=1,s2=2,s3=3;
	reg [1:0] state,next;
	always @(posedge clk) begin
		if(!rst_n)
			state <= s0;
		else
			state <= next;
	end
	always @(*) begin
		case(state)
			s0:next = in?s1:s0;
			s1:next = in?s1:s2;
			s2:next = in?s3:s0;
			s3:next = in?s1:s2;
		endcase
	end
	assign found = (state == s3);
endmodule		
