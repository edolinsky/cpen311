module reg2 (clk, reset, load, in, out);

	input clk, reset, load;
	input [1:0] in;
	output reg [1:0] out;
	
	always_ff @(posedge clk or negedge reset)
		if (reset == 0)
			out <= 0;
		else 
			if (load == 1)
				out <= in;
endmodule