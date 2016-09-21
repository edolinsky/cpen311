module reg4 (clk, reset, load, in, out, reset_cards);

	input clk, reset, load, reset_cards;
	input [3:0] in;
	output reg [3:0] out;
	
	always_ff @(posedge clk or negedge reset or posedge reset_cards)
		if (reset == 0 || reset_cards == 1)
			out <= 0;
		else 
			if (load == 1)
				out <= in;
endmodule