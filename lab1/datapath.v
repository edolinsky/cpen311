module datapath ( slow_clock, fast_clock, resetb, reset_cards,
                  load_pcard1, load_pcard2, load_pcard3,
                  load_dcard1, load_dcard2, load_dcard3,
						result, bet_in, wager_in, load_wager,
                  pcard3_out,
                  pscore_out, dscore_out,
                  HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
						balance_out);
						
input slow_clock, fast_clock, resetb, reset_cards;
input load_pcard1, load_pcard2, load_pcard3;
input load_dcard1, load_dcard2, load_dcard3;
input load_wager;
input [2:0] result, bet_in;
input [7:0] wager_in;
output [3:0] pcard3_out;
output [3:0] pscore_out, dscore_out;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
output [7:0] balance_out;

wire [3:0] new_card;
wire [3:0] pcard1, pcard2, pcard3, dcard1, dcard2, dcard3;
wire [7:0] wager_out;
wire [7:0] balance_in;
wire [1:0] bet_out;
wire load_balance;

dealcard dealcard (.clock(fast_clock), .resetb(resetb), .new_card(new_card));

reg4 preg1 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_pcard1), .in(new_card), .out(pcard1));
reg4 preg2 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_pcard2), .in(new_card), .out(pcard2));
reg4 preg3 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_pcard3), .in(new_card), .out(pcard3));
reg4 dreg1 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_dcard1), .in(new_card), .out(dcard1));
reg4 dreg2 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_dcard2), .in(new_card), .out(dcard2));
reg4 dreg3 (.clk(slow_clock), .reset(resetb), .reset_cards(reset_cards), .load(load_dcard3), .in(new_card), .out(dcard3));

card7seg pcard1_display (.card(pcard1), .seg7(HEX0));
card7seg pcard2_display (.card(pcard2), .seg7(HEX1));
card7seg pcard3_display (.card(pcard3), .seg7(HEX2));
card7seg dcard1_display (.card(dcard1), .seg7(HEX3));
card7seg dcard2_display (.card(dcard2), .seg7(HEX4));
card7seg dcard3_display (.card(dcard3), .seg7(HEX5));

scorehand playerscore (.card1(pcard1), .card2(pcard2), .card3(pcard3), .total(pscore_out));
scorehand dealerscore (.card1(dcard1), .card2(dcard2), .card3(dcard3), .total(dscore_out));

reg2 bet(.clk(slow_clock), .reset(resetb), .load(load_wager), .in(bet_in), .out(bet_out));

reg8 wager(.clk(slow_clock), .reset(resetb), .load(load_wager), .in(wager_in), .out(wager_out),
.reset_val(8'b00000000));
reg8 balance(.clk(slow_clock), .reset(resetb), .load(load_balance), .in(balance_in), .out(balance_out),
.reset_val(8'b1100100));

always_comb
	load_balance = result[0] | result[1];
	
always_ff
	if (bet_out == result) 
	begin
		if (bet_out == 2'b11)
			balance_in = balance_out + (8 * wager_out);
		else
			balance_in = balance_out + wager_out;
	end
	else
	begin
		if (bet_out == 2'b11)
			balance_in = balance_out;
		else
			balance_in = balance_out - wager_out;
	end
	

assign pcard3_out = pcard3;

endmodule
