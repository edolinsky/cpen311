module lights (CLOCK_50, SW, KEY, LEDG, HEX1, HEX0);
	input CLOCK_50;
	input [7:0] SW;
	input [0:0] KEY;
	output [7:0] LEDG;
	output [6:0] HEX1, HEX0;
	
	wire [7:0] result;
	
	nios_system NIOSII (
		.clk_clk(CLOCK_50),
		.reset_reset_n(KEY),
		.switches_export(SW),
		.leds_export(LEDG),
		.sevensegs_export(result));
		
	sevensegdriver msd(
		.num(result[7:4]),
		.seg7(HEX1));
	
	sevensegdriver lsd(
		.num(result[3:0]),
		.seg7(HEX0));
		
endmodule