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
parameter RADIUS = 25;
parameter OLYMPIC_Y_OFFSET = 14;
parameter OLYMPIC_X_OFFSET = 27;

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
reg xdone, ydone, olympicdone;
reg circle;
reg [2:0] olympic_count;

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
	NEXT_SECTION: {initx, inity, loady, loadx, plot, circle} <= 6'b001111; // next loop
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
	CIRCLE_INIT: 
	begin
		if (olympic_count < 5)
			next_state <= DRAW_SECTION;
		else
			next_state <= FINISHED;
	end
	DRAW_SECTION:
	begin
		if(xdone == 0) next_state <= DRAW_SECTION;
		else if (ydone == 0) next_state <= NEXT_SECTION;
		else next_state <= CIRCLE_INIT;
	end
	NEXT_SECTION: next_state <= DRAW_SECTION;
	default: next_state <= FINISHED;
endcase
end

// datapath
always_ff @(posedge(CLOCK_50))
begin
	if (resetn == 0)
	begin
		olympic_count <= 3'b000;
		colour = BLACK;
	end

	if (circle == 0)
	begin
		if (loady == 1)
		begin
			if (inity == 1)
				y = 0;
			else
				y++;
		end
		if (loadx == 1)
		begin
			if (initx == 1)
				x = 0;
			else
				x++;
		end
	end
				
	/////////////////////////
	else
	begin
		if (loady == 1)
		begin
			if (inity == 1)
			begin
				case (olympic_count)
					3'd0: centre_y = SCREEN_HEIGHT / 2 - OLYMPIC_Y_OFFSET;
					3'd1: centre_y = SCREEN_HEIGHT / 2 - OLYMPIC_Y_OFFSET;
					3'd2: centre_y = SCREEN_HEIGHT / 2 - OLYMPIC_Y_OFFSET;
					3'd3: centre_y = SCREEN_HEIGHT / 2 + OLYMPIC_Y_OFFSET;
					3'd4: centre_y = SCREEN_HEIGHT / 2 + OLYMPIC_Y_OFFSET;
					default: centre_y = SCREEN_HEIGHT / 2;
				endcase
				offset_y = 0;
			end
			else
				offset_y++;
		end
		if (loadx == 1)
		begin
			if (initx == 1)
			begin
				offset_x = RADIUS;
				crit = 1 - RADIUS;
				case (olympic_count)
					3'd0: centre_x = SCREEN_WIDTH / 2 - 2 * OLYMPIC_X_OFFSET;
					3'd1: centre_x = SCREEN_WIDTH / 2;
					3'd2:	centre_x = SCREEN_WIDTH / 2 + 2 * OLYMPIC_X_OFFSET;
					3'd3: centre_x = SCREEN_WIDTH / 2 - OLYMPIC_X_OFFSET;
					3'd4: centre_x = SCREEN_WIDTH / 2 + OLYMPIC_X_OFFSET;
					default: centre_x = SCREEN_WIDTH / 2;
				endcase
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
	end
	
	olympicdone <= 0;
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
			begin
				ydone <= 1;
				olympic_count <= olympic_count + 1;
				if (olympic_count >= 4)
					olympicdone <= 1;
			end
					
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
		case (olympic_count)
			3'd0: colour = BLUE;
			3'd1: colour = WHITE;
			3'd2: colour = RED;
			3'd3: colour = YELLOW;
			3'd4: colour = GREEN;
			default: colour = RED;
		endcase
end

endmodule

