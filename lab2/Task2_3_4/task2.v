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

enum {FILL_INIT, DRAW_LINE, NEXT_LINE, CIRCLE_INIT, DRAW_SECTION, NEXT_SECTION, FINISHED} current_state, next_state;

// Some constants that might be useful for you

parameter SCREEN_WIDTH = 160;
parameter SCREEN_HEIGHT = 120;
parameter RADIUS = 40;

parameter BLACK = 3'b000;
parameter BLUE = 3'b001;
parameter GREEN = 3'b010;
parameter YELLOW = 3'b110;
parameter RED = 3'b100;
parameter WHITE = 3'b111;

// To VGA adapter
  
wire resetn;
wire [7:0] x, centre_x, offset_x;
wire [6:0] y, centre_y, offset_y;
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

reg initx, inity, loadx, loady;
reg xdone, ydone;
reg circle;

int crit;
reg [2:0] counter;

// output logic
always_comb
begin
case (current_state)
	FILL_INIT: {initx, inity, loady, loadx, plot, circle} <= 6'b111100; // fill init
	NEXT_LINE: {initx, inity, loady, loadx, plot, circle} <= 6'b101100; // next line
	DRAW_LINE: {initx, inity, loady, loadx, plot, circle} <= 6'b000110; // draw line
	CIRCLE_INIT: {initx, inity, loady, loadx, plot, circle} <= 6'b111101; // circle init
	DRAW_SECTION: {initx, inity, loady, loadx, plot, circle} <= 6'b000011; // drawing loop
	NEXT_SECTION: {initx, inity, loady, loadx, plot, circle} <= 6'b001101; // next loop
	default: {initx, inity, loady, loadx, plot, circle} <= 6'b000000; // end
endcase
end

// next state
always_ff @(posedge(CLOCK_50) or negedge resetn)
begin
	if (resetn == 0)
		current_state <= FILL_INIT;
	else
		current_state <= next_state;
end
		
// next state logic
always_comb
begin
case (current_state)
	FILL_INIT: next_state <= NEXT_LINE;
	NEXT_LINE: next_state <= DRAW_LINE;
	DRAW_LINE: 
	begin
		if (xdone == 0) next_state <= DRAW_LINE;
		else if (ydone == 0) next_state <= NEXT_LINE;
		else next_state <= CIRCLE_INIT;
	end
	CIRCLE_INIT: next_state <= DRAW_SECTION;
	DRAW_SECTION:
	begin
		if(xdone == 0) next_state <= DRAW_SECTION;
		else if (ydone == 0) next_state <= NEXT_SECTION;
		else next_state <= FINISHED;
	end
	NEXT_SECTION: next_state <= DRAW_SECTION;
	default: next_state <= FINISHED;
endcase
end

// datapath
always_ff @(posedge(CLOCK_50))
begin
	if (circle == 0)
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
				
	/////////////////////////
	else
	if (loady == 1)
	begin
		if (inity == 1)
		begin
			centre_y = SCREEN_HEIGHT/2;
			offset_y = 0;
		end
		else
			offset_y++;
	end
	if (loadx == 1)
	begin
		if (initx == 1)
		begin
			centre_x = SCREEN_WIDTH/2;
			offset_x = RADIUS;
			crit = 1 - RADIUS;
		end
		else
		begin
			if (crit <= 0)
				crit = crit + (2 * offset_y) + 1;
			else
			begin
				offset_x = offset_x -1;
				crit = crit + (2 * (offset_y - offset_x)) + 1;
			end
		end
	end
				
	ydone <= 0;
	xdone <= 0;
	if (circle == 0)
	begin
		if (y == SCREEN_HEIGHT - 1)
			ydone <= 1;
		if (x == SCREEN_WIDTH - 1)
			xdone <= 1;
	end
	else
	begin
		if (counter == 3'b111)
		begin
			counter <= 3'b000;
			xdone <= 1; // recycle
			if (offset_y > offset_x)
				ydone <= 1;
		end
		else
			counter <= counter + 1;
			
		case (counter)
			3'b000:
			begin
				x = centre_x + offset_x;
				y = centre_y + offset_y;
			end
			3'b001:
			begin
				x = centre_x + offset_y;
				y = centre_y + offset_x;
			end
			3'b010:
			begin
				x = centre_x - offset_x;
				y = centre_y + offset_y;
			end
			3'b011:
			begin
				x = centre_x - offset_y;
				y = centre_y + offset_x;
			end
			3'b100:
			begin
				x = centre_x - offset_x;
				y = centre_y - offset_y;
			end
			3'b101:
			begin
				x = centre_x - offset_y;
				y = centre_y - offset_x;
			end
			3'b110:
			begin
				x = centre_x + offset_x;
				y = centre_y - offset_y;
			end
			3'b111:
			begin
				x = centre_x + offset_y;
				y = centre_y - offset_x;
			end
		endcase
	end	
	colour = BLACK;
	if (circle == 1)
		colour = BLUE;
end

endmodule

