module reg4 (clk, reset, reset_cards, load, in, out);

	input clk, reset, reset_cards, load;
	input [3:0] in;
	output reg [3:0] out;
	
	always_ff @(posedge clk or negedge reset or posedge reset_cards)
		if (reset == 0 || reset_cards == 1)
			out <= 0;
		else begin
			if (load == 1)
				out <= in;
		end
endmodule