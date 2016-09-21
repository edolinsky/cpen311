// This module contains a Verilog description of the top level module
// Assuming you don't modify the inputs and outputs of the various submodules,
// you should not have to modify anything in this file.

module lab1 (CLOCK_50, KEY, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, SW);
input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;

output [9:0] LEDR;
output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

// Some local signals 

wire fast_clock, slow_clock, resetb;
wire load_pcard1, load_pcard2, load_pcard3;
wire load_dcard1, load_dcard2, load_dcard3;
wire load_wager, betting;
wire [3:0] pscore, dscore;
wire [3:0] pcard3;
	

assign resetb = KEY[3];
assign bet_in = SW[9:8];
assign wager_in = SW[7:0];
assign slow_clock = KEY[0];
assign fast_clock = CLOCK_50;

// instantiate the datapath
	
datapath dp (.slow_clock(slow_clock),
             .fast_clock(fast_clock),
				 .wager_in(wager_in),
				 .bet_in(bet_in),
             .resetb(resetb),
				 .reset_cards(betting),
				 .load_wager(load_wager),
             .load_pcard1(load_pcard1),
             .load_pcard2(load_pcard2),
             .load_pcard3(load_pcard3),
             .load_dcard1(load_dcard1),
             .load_dcard2(load_dcard2),
             .load_dcard3(load_dcard3),
             .dscore_out(dscore),
             .pscore_out(pscore),
             .pcard3_out(pcard3),
             .HEX5(HEX5),
             .HEX4(HEX4),
             .HEX3(HEX3),
             .HEX2(HEX2),
             .HEX1(HEX1),
             .HEX0(HEX0));
							
assign LEDR[3:0] = pscore;
assign LEDR[7:4] = dscore;

// instantiate the state machine
	
statemachine sm (.slow_clock(slow_clock),
                 .resetb(resetb),
					  .load_wager(load_wager),
					  .betting(betting),
                 .dscore(dscore),
                 .pscore(pscore),
                 .pcard3(pcard3),
                 .load_pcard1(load_pcard1),
                 .load_pcard2(load_pcard2),
                 .load_pcard3(load_pcard3),						  
                 .load_dcard1(load_dcard1),
                 .load_dcard2(load_dcard2),
                 .load_dcard3(load_dcard3),	
                 .player_win_light(LEDR[8]), 
                 .dealer_win_light(LEDR[9]));
	
endmodule