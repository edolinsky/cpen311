module datapath ( slow_clock, fast_clock, resetb,
                  load_pcard1, load_pcard2, load_pcard3,
                  load_dcard1, load_dcard2, load_dcard3,				
                  pcard3_out,
                  pscore_out, dscore_out,
                  HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
						
input slow_clock, fast_clock, resetb;
input load_pcard1, load_pcard2, load_pcard3;
input load_dcard1, load_dcard2, load_dcard3;
output [3:0] pcard3_out;
output [3:0] pscore_out, dscore_out;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

wire [3:0] new_card;
wire [3:0] pcard1, pcard2, pcard3, dcard1, dcard2, dcard3;
						
dealcard dealcard (.clock(fast_clock), .resetb(resetb), .new_card(new_card));

reg4 preg1 (.clk(slow_clock), .reset(resetb), .load(load_pcard1), .in(new_card), .out(pcard1));
reg4 preg2 (.clk(slow_clock), .reset(resetb), .load(load_pcard2), .in(new_card), .out(pcard2));
reg4 preg3 (.clk(slow_clock), .reset(resetb), .load(load_pcard3), .in(new_card), .out(pcard3));
reg4 dreg1 (.clk(slow_clock), .reset(resetb), .load(load_dcard1), .in(new_card), .out(dcard1));
reg4 dreg2 (.clk(slow_clock), .reset(resetb), .load(load_dcard2), .in(new_card), .out(dcard2));
reg4 dreg3 (.clk(slow_clock), .reset(resetb), .load(load_dcard3), .in(new_card), .out(dcard3));

card7seg pcard1_display (.card(pcard1), .seg7(HEX0));
card7seg pcard2_display (.card(pcard2), .seg7(HEX1));
card7seg pcard3_display (.card(pcard3), .seg7(HEX2));
card7seg dcard1_display (.card(dcard1), .seg7(HEX3));
card7seg dcard2_display (.card(dcard2), .seg7(HEX4));
card7seg dcard3_display (.card(dcard3), .seg7(HEX5));

scorehand playerscore (.card1(pcard1), .card2(pcard2), .card3(pcard3), .total(pscore_out));
scorehand dealerscore (.card1(dcard1), .card2(dcard2), .card3(dcard3), .total(dscore_out));

assign pcard3_out = pcard3;

endmodule
