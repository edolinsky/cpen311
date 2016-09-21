module reg8 (clk, reset, load, in, out, reset_val);

	input clk, reset, load;
	input [7:0] in, reset_val;
	output reg [7:0] out;
	
	always_ff @(posedge clk or negedge reset)
		if (reset == 0)
			out <= reset_val;
		else 
			if (load == 1)
				out <= in;
endmodule