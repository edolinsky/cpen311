
module scorehand (card1, card2, card3, total);

	input [3:0] card1, card2, card3;
	output [3:0] total;
	
	wire [3:0] card1_r, card2_r, card3_r;

// The code describing scorehand will go here.  Remember this is a combinational
// block.  The function is described in the handout.  Be sure to read the section
// on representing numbers in Slide Set 2.

	always_comb
	begin
		if (card1 > 10)
			card1_r = 10;
		else
			card1_r = card1;
			
		if (card2 > 10)
			card2_r = 10;
		else
			card2_r = card2;
		
		if (card3 > 10)
			card3_r = 10;
		else
			card3_r = card3;
			
		total <= (card1_r + card2_r + card3_r) % 10;
	end

endmodule
	