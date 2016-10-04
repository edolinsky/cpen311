module task2 (CLOCK_50, 
		 KEY,             
       VGA_R, VGA_G, VGA_B, 
       VGA_HS,             
       VGA_VS,             
       VGA_BLANK,           
       VGA_SYNC,            
       VGA_CLK);
  
input CLOCK_50;
input [3:0] KEY;
output [9:0] VGA_R, VGA_G, VGA_B; 
output VGA_HS;             
output VGA_VS;          
output VGA_BLANK;           
output VGA_SYNC;            
output VGA_CLK;

// Some constants that might be useful for you

parameter SCREEN_WIDTH = 160;
parameter SCREEN_HEIGHT = 120;

parameter BLACK = 3'b000;
parameter BLUE = 3'b001;
parameter GREEN = 3'b010;
parameter YELLOW = 3'b110;
parameter RED = 3'b100;
parameter WHITE = 3'b111;

// To VGA adapter
  
wire resetn;
wire [7:0] x;
wire [6:0] y;
reg [2:0] colour;
reg plot;
   
// instantiate VGA adapter 
	
vga_adapter #( .RESOLUTION("160x120"))
    vga_u0 (.resetn(KEY[3]),
	         .clock(CLOCK_50),
			   .colour(colour),
			   .x(x),
			   .y(y),
			   .plot(plot),
			   .VGA_R(VGA_R),
			   .VGA_G(VGA_G),
			   .VGA_B(VGA_B),	
			   .VGA_HS(VGA_HS),
			   .VGA_VS(VGA_VS),
			   .VGA_BLANK(VGA_BLANK),
			   .VGA_SYNC(VGA_SYNC),
			   .VGA_CLK(VGA_CLK));


// Your code to fill the screen goes here.
assign resetn = KEY[3];

reg [1:0] current_state, next_state;
reg initx, inity, loadx, loady;
reg xdone, ydone;

// output logic
always_comb
begin
case (current_state)
	2'b00: {initx,inity,loady,loadx,plot} <= 5'b11110;
	2'b01: {initx,inity,loady,loadx,plot} <= 5'b10110;
	2'b10: {initx,inity,loady,loadx,plot} <= 5'b00011;
	default: {initx,inity,loady,loadx,plot} <= 5'b00000;
endcase
end

// next state
always_ff @(posedge(CLOCK_50) or negedge resetn)
begin
	if (resetn == 0)
		current_state <= 2'b00;
	else
		current_state <= next_state;
end
		
// next state logic
always_comb
begin
case (current_state)
	2'b00: next_state <= 2'b10;
	2'b01: next_state <= 2'b10;
	2'b10: 
	begin
		if (xdone == 0) next_state <= 2'b10;
		else if (ydone == 0) next_state <= 2'b01;
		else next_state <= 2'b11;
	end
	default: next_state <= 2'b11;
endcase
end

// datapath
always_ff @(posedge(CLOCK_50))
begin
	if (loady == 1)
		if (inity == 1)
			y = 0;
		else
			y++;
	if (loadx == 1)
		if (initx == 1)
			x = 0;
		else
			x++;
	ydone <= 0;
	xdone <= 0;
	if (y == SCREEN_HEIGHT - 1)
		ydone <= 1;
	if (x == SCREEN_WIDTH - 1)
		xdone <= 1;
		
	colour = BLUE;
end

endmodule

