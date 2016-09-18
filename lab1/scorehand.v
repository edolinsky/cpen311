
module scorehand (card1, card2, card3, total);

	input [3:0] card1, card2, card3;
	output [3:0] total;

// The code describing scorehand will go here.  Remember this is a combinational
// block.  The function is described in the handout.  Be sure to read the section
// on representing numbers in Slide Set 2.

	always_comb
		total <= (card1 + card2 + card3) % 10;

endmodule
	