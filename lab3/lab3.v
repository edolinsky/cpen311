`include "lab3_inc.v"
							  
////////////////////////////////////////////////////////////////
//
//  This file is the starting point for Lab 3.  This design implements
//  a simple pong game, with a paddle at the bottom and one ball that 
//  bounces around the screen.  When downloaded to an FPGA board, 
//  KEY(0) will move the paddle to right, and KEY(1) will move the 
//  paddle to the left.  KEY(3) will reset the game.  If the ball drops
//  below the bottom of the screen without hitting the paddle, the game
//  will reset.
//
//  This is written in a combined datapath/state machine style as
//  discussed in the second half of Slide Set 7.  It looks like a 
//  state machine, but the datapath operations that will be performed
//  in each state are described within the corresponding WHEN clause
//  of the state machine.  From this style, Quartus II will be able to
//  extract the state machine from the design.
//
//  In Lab 3, you will modify this file as described in the handout.
//
//  This file makes extensive use of types and constants described in
//  lab3_inc.v   Be sure to read and understand that file before
//  trying to understand this one.
// 
////////////////////////////////////////////////////////////////////////

// Entity part of the description.  Describes inputs and outputs

module lab3 (CLOCK_50, KEY, 
             VGA_R, VGA_G, VGA_B,
             VGA_HS, VGA_VS,
             VGA_BLANK, VGA_SYNC, VGA_CLK);

input CLOCK_50;
input [3:0] KEY;
output [9:0] VGA_R, VGA_G, VGA_B;
output VGA_HS, VGA_VS;
output VGA_BLANK, VGA_SYNC, VGA_CLK;

// These are signals that will be connected to the VGA adapater.
// The VGA adapater was described in the Lab 2 handout.
  
reg resetn;
wire [7:0] x;
wire [6:0] y;
reg [2:0] colour;
reg plot;
reg [DATA_WIDTH_COORD-1:0] paddle_width;
reg [7:0] paddle_shrink_timer;
reg [7:0] top_shrink_timer;
reg [6:0] top_line;
point draw;

// The state of our state machine

draw_state_type state;

// This variable will store the x position of the paddle (left-most pixel of the paddle
reg [DATA_WIDTH_COORD-1:0] paddle_x;

// These variables will store the puck and the puck velocity.
// In this implementation, the puck velocity has two components: an x component
// and a y component.  Each component is always +1 or -1.

point puck1;
velocity puck1_velocity;

point puck2;
velocity puck2_velocity;
	 
// This will be used as a counter variable in the IDLE state

integer clock_counter = 0;

// Be sure to see all the constants, types, etc. defined in lab3_inc.h

// include the VGA controller structurally.  The VGA controller 
// was decribed in Lab 2.  You probably know it in great detail now, but 
// if you have forgotten, please go back and review the description of the 
// VGA controller in Lab 2 before trying to do this lab.

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

// the x and y lines of the VGA controller will be always
// driven by draw.x and draw.y.   The process below will update
// signals draw.x and draw.y.
  
assign x = draw.x[7:0];
assign y = draw.y[6:0];


// ============================================================================= 
// This is the main loop.  As described above, it is written in a combined
// state machine / datapath style.  It looks like a state machine, but rather
// than simply driving control signals in each state, the description describes 
// the datapath operations that happen in each state.  From this Quartus II
// will figure out a suitable datapath for you.
  
// Notice that this is written as a pattern-3 process (sequential with an
// asynchronous reset)



always_ff @(posedge CLOCK_50, negedge KEY[3])

   // first see if the reset button has been pressed.  If so, we need to
   // reset to state INIT
	 
   if (KEY[3] == 1'b0) begin	
      draw.x <= 0;
      draw.y <= 0;
		
		top_line = TOP_LINE_INIT;
      paddle_x <= PADDLE_X_START[DATA_WIDTH_COORD-1:0];
		paddle_width <= INIT_PADDLE_WIDTH;
		paddle_shrink_timer = 0;
		top_shrink_timer = 0;
      
		puck1.x <= FACEOFF_X1;
      puck1.y <= FACEOFF_Y1;
      puck1_velocity.x <= VELOCITY_START_X1;
      puck1_velocity.y <= VELOCITY_START_Y1;
		
		puck2.x <= FACEOFF_X2;
      puck2.y <= FACEOFF_Y2;
      puck2_velocity.x <= VELOCITY_START_X2;
      puck2_velocity.y <= VELOCITY_START_Y2;
		
      colour <= BLACK;
      plot <= 1'b1;
      state <= INIT;
	  
    // Otherwise, we are here because of a rising clock edge.  This follows
    // the standard pattern for a type-3 process we saw in the lecture slides.
	 
    end else begin

      case (state) 
		
         // ============================================================
         // The INIT state sets the variables to their default values
         // ============================================================
	
         INIT : begin
            draw.x <= 0;
            draw.y <= 0;
				
				top_line = TOP_LINE_INIT;
            paddle_x <= PADDLE_X_START[DATA_WIDTH_COORD-1:0];
				paddle_width <= INIT_PADDLE_WIDTH;
				paddle_shrink_timer = 0;
				top_shrink_timer = 0;
				
            puck1.x <= FACEOFF_X1;
            puck1.y <= FACEOFF_Y1;
            puck1_velocity.x <= VELOCITY_START_X1;
            puck1_velocity.y <= VELOCITY_START_Y1;
				
				puck2.x <= FACEOFF_X2;
            puck2.y <= FACEOFF_Y2;
            puck2_velocity.x <= VELOCITY_START_X2;
            puck2_velocity.y <= VELOCITY_START_Y2;
				
            colour <= BLACK;
            plot <= 1'b1;
            state <= START;
           end	 // case INIT 
			  
		   // ============================================================
         // the START state is used to clear the screen.  We will spend many cycles
		   // in this state, because only one pixel can be updated each cycle.  The  
		   // counters in draw.x and draw.y will be used to keep track of which pixel 
		   // we are erasing.  
		   // ============================================================
		  
         START: begin
		  
		       // See if we are done erasing the screen		    
            if (draw.x == SCREEN_WIDTH-1) begin
              if (draw.y == SCREEN_HEIGHT-1) begin
				
				     // We are done erasing the screen.  Set the next state 
				     // to DRAW_TOP_ENTER

                 state <= DRAW_TOP_ENTER;	
		  
               end else begin
				
				     // In this cycle we will be erasing a pixel.  Update 
				     // draw.y so that next time it will erase the next pixel
				  
                 draw.y <= draw.y + 1'b1;
      			  draw.x <= 1'b0;				  
               end  // else
             end else begin
	
               // Update draw.x so next time it will erase the next pixel    
  		  	  	
               draw.x <= draw.x + 1'b1;

				 end // if
           end // case START
			  
		  // ============================================================
        // The DRAW_TOP_ENTER state draws the first pixel of the bar on
		  // the top of the screen.  The machine only stays here for
		  // one cycle; the next cycle it is in DRAW_TOP_LOOP to draw the
		  // rest of the bar.
		  // ============================================================
		  
		  DRAW_TOP_ENTER: begin
				  top_shrink_timer = top_shrink_timer + 1;
				  
				  if (top_shrink_timer >= TOP_SHRINK_SPEED) begin
						top_shrink_timer = 0;
						if (top_line >= SCREEN_HEIGHT / 2) begin
							top_line = top_line + 1;
						end // if
				  end // if
				  
			     draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
				  draw.y <= top_line;
				  colour <= WHITE;
				  state <= DRAW_TOP_LOOP;
			  end // case DRAW_TOP_ENTER
			  
		  // ============================================================
        // The DRAW_TOP_LOOP state is used to draw the rest of the bar on 
		  // the top of the screen.
        // Since we can only update one pixel per cycle,
        // this will take multiple cycles
		  // ============================================================
		  
        DRAW_TOP_LOOP: begin	
           // See if we have been in this state long enough to have completed the line
    		  if (draw.x == RIGHT_LINE) begin
			     // if so, the next state is DRAW_RIGHT_ENTER			  
              state <= DRAW_RIGHT_ENTER; // next state is DRAW_RIGHT
           end else begin
				
				  // Otherwise, update draw.x to point to the next pixel
              draw.y <= top_line;
              draw.x <= draw.x + 1'b1;
				  
				  // Do not change the state, since we want to come back to this state
				  // the next time we come through this process (at the next rising clock
				  // edge) to finish drawing the line
				  
            end
           end //case DRAW_TOP_LOOP
		  // ============================================================
        // The DRAW_RIGHT_ENTER state draws the first pixel of the bar on
		  // the right-side of the screen.  The machine only stays here for
		  // one cycle; the next cycle it is in DRAW_RIGHT_LOOP to draw the
		  // rest of the bar.
		  // ============================================================

		  DRAW_RIGHT_ENTER: begin				
			     draw.x <= RIGHT_LINE[DATA_WIDTH_COORD-1:0];
				  draw.y <= top_line;
				  state <= DRAW_RIGHT_LOOP;
			  end // case DRAW_RIGHT_ENTER		  
   		  
		  // ============================================================
        // The DRAW_RIGHT_LOOP state is used to draw the rest of the bar on 
		  // the right side of the screen.
        // Since we can only update one pixel per cycle,
        // this will take multiple cycles
		  // ============================================================
		  
		  DRAW_RIGHT_LOOP: begin

		  // See if we have been in this state long enough to have completed the line
	   	  if (draw.y == SCREEN_HEIGHT-1) begin
		  
			     // We are done, so the next state is DRAW_LEFT_ENTER	  
	 
              state <= DRAW_LEFT_ENTER;	// next state is DRAW_LEFT
            end else begin

				  // Otherwise, update draw.y to point to the next pixel				
              draw.x <= RIGHT_LINE[DATA_WIDTH_COORD-1:0];
              draw.y <= draw.y + 1'b1;
            end	
           end //case DRAW_RIGHT_LOOP
		  // ============================================================
        // The DRAW_LEFT_ENTER state draws the first pixel of the bar on
		  // the left-side of the screen.  The machine only stays here for
		  // one cycle; the next cycle it is in DRAW_LEFT_LOOP to draw the
		  // rest of the bar.
		  // ============================================================

		  DRAW_LEFT_ENTER: begin				
			     draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
				  draw.y <= top_line;
				  state <= DRAW_LEFT_LOOP;
			  end // case DRAW_LEFT_ENTER				  
   		  
		  // ============================================================
        // The DRAW_LEFT_LOOP state is used to draw the rest of the bar on 
		  // the left side of the screen.
        // Since we can only update one pixel per cycle,
        // this will take multiple cycles
		  // ============================================================
		  
		  DRAW_LEFT_LOOP: begin 

		  // See if we have been in this state long enough to have completed the line		  
          if (draw.y == SCREEN_HEIGHT-1) begin

			     // We are done, so get things set up for the IDLE state, which 
				  // comes next.  
				  
              state <= IDLE;  // next state is IDLE
				  clock_counter <= 0;  // initialize counter we will use in IDLE  
				  
            end else begin
				
				  // Otherwise, update draw.y to point to the next pixel					
              draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
              draw.y <= draw.y + 1'b1;
            end
           end //case DRAW_LEFT_LOOP
		

		  // ============================================================
        // The IDLE state is basically a delay state.  If we didn't have this,
		  // we'd be updating the puck location and paddle far too quickly for the
		  // the user.  So, this state delays for 1/8 of a second.  Once the delay is
		  // done, we can go to state ERASE_PADDLE.  Note that we do not try to
		  // delay using any sort of wait statement: that won't work (not synthesziable).  
		  // We have to build a counter to count a certain number of clock cycles.
		  // ============================================================
		  
        IDLE: begin
		  
		    // See if we are still counting.  LOOP_SPEED indicates the maximum 
			 // value of the counter
			 
			 plot <= 1'b0;  // nothing to draw while we are in this state
			 
          if (clock_counter < LOOP_SPEED) begin
			    clock_counter <= clock_counter + 1'b1;
          end else begin 
			 
			     // otherwise, we are done counting.  So get ready for the 
				  // next state which is ERASE_PADDLE_ENTER
				  
              clock_counter <= 0;
              state <= ERASE_PADDLE_ENTER;  // next state
	  
			 end  // if
        end // case IDLE
        
		  // ============================================================
        // In the ERASE_PADDLE_ENTER state, we will erase the first pixel of
		  // the paddle. We will only stay here one cycle; the next cycle we will
		  // be in ERASE_PADDLE_LOOP which will erase the rest of the pixels
		  // ============================================================     		 

		  ERASE_PADDLE_ENTER: begin
           draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
		     draw.x <= paddle_x;	
           colour <= BLACK;
           plot <= 1'b1;			
           state <= ERASE_PADDLE_LOOP;				 
			 end // case ERASE_PADDLE_ENTER
			 
		  // ============================================================
        // In the ERASE_PADDLE_LOOP state, we will erase the rest of the paddle. 
		  // Since the paddle consists of multiple pixels, we will stay in this state for
		  // multiple cycles.  draw.x will be used as the counter variable that
		  // cycles through the pixels that make up the paddle.
		  // ============================================================
		  
		  ERASE_PADDLE_LOOP: begin
		  
		      // See if we are done erasing the paddle (done with this state)
            if (draw.x == paddle_x+paddle_width[DATA_WIDTH_COORD-1:0]) begin
			
				  // If so, the next state is DRAW_PADDLE_ENTER. 
				  
              state <= DRAW_PADDLE_ENTER;  // next state is DRAW_PADDLE 

            end else begin

				  // we are not done erasing the paddle.  Erase the pixel and update
				  // draw.x by increasing it by 1
   		     draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
              draw.x <= draw.x + 1'b1;
				  
				  // state stays the same, since we want to come back to this state
				  // next time through the process (next rising clock edge) until 
				  // the paddle has been erased
				  
            end // if
          end //case ERASE_PADDLE_LOOP
			 
		  // ============================================================
        // The DRAW_PADDLE_ENTER state will start drawing the paddle.  In 
		  // this state, the paddle position is updated based on the keys, and
		  // then the first pixel of the paddle is drawn.  We then immediately
		  // go to DRAW_PADDLE_LOOP to draw the rest of the pixels of the paddle.
		  // ============================================================
		  
		  DRAW_PADDLE_ENTER: begin
		  
				  // shrink paddle every 20 seconds, until only 4 pixels long
				  paddle_shrink_timer = paddle_shrink_timer + 1'b1; // increment shrink timer
				  
				  if (paddle_shrink_timer >= PADDLE_SHRINK_SPEED) begin
						paddle_shrink_timer = 0;
						if (paddle_width > 4) begin
							paddle_width = paddle_width - 1;
						end // if
				  end // if
				  
				  // We need to figure out the x lcoation of the paddle before the 
				  // start of DRAW_PADDLE_LOOP.  The x location does not change, unless
				  // the user has pressed one of the buttons.
				  
				  if (KEY[0] == 1'b0) begin
				  
						// If the user has pressed the right button check to make sure we
						// are not already at the rightmost position of the screen
					  
						if (paddle_width % 2 == 0) begin
							if (paddle_x <= RIGHT_LINE - paddle_width - 2) begin 
								// add 2 to the paddle position
								paddle_x = paddle_x + 2'b10;
							end
						end else begin
							if (paddle_x <= RIGHT_LINE - paddle_width - 3)begin
								paddle_x = paddle_x + 2'b10;
							end else if (paddle_x <= RIGHT_LINE - paddle_width - 2)begin
								paddle_x = paddle_x + 2'b01;
							end // if
						end // if
					  
						// If the user has pressed the right button check to make sure we
						// are not already at the rightmost position of the screen
					  
				  end else begin
						if (KEY[1] == 1'b0) begin 
					  
						// If the user has pressed the left button check to make sure we
						// are not already at the leftmost position of the screen
							
							if (paddle_width & 2 == 0) begin
								if (paddle_x >= LEFT_LINE + 2) begin				 
									// subtract 2 from the paddle position 
									paddle_x = paddle_x - 2'b10;						
								end //if
							end else begin
								if (paddle_x >= LEFT_LINE + 3) begin
									paddle_x = paddle_x - 2'b10;
								end else if (paddle_x >= LEFT_LINE + 2)begin
									paddle_x = paddle_x - 2'b01;
								end // if
							end // if
						end // if
					end //if 

              // In this state, draw the first element of the paddle	
				  
					draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];				  
					draw.x <= paddle_x;  // get ready for next state			  
					colour <= paddle_width - 3; // when we draw the paddle, the colour will be WHITE		  
					state <= DRAW_PADDLE_LOOP;
				end // case DRAW_PADDLE_ENTER
				
		  // ============================================================
        // The DRAW_PADDLE_LOOP state will draw the rest of the paddle. 
		  // Again, because we can only update one pixel per cycle, we will 
		  // spend multiple cycles in this state.  
		  // ============================================================
		  
		  DRAW_PADDLE_LOOP: begin
		  
		      // See if we are done drawing the paddle

            if (draw.x == paddle_x+paddle_width) begin
				
				  // If we are done drawing the paddle, set up for the next state
				  
              plot  <= 1'b0;  
              state <= ERASE_PUCK1;	// next state is ERASE_PUCK
				end else begin		
				
				  // Otherwise, update the x counter to the next location in the paddle 
              draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
              draw.x <= draw.x + 1'b1;

				  // state stays the same so we come back to this state until we
				  // are done drawing the paddle

				end // if
			  end // case DRAW_PADDLE_LOOP

		  // ============================================================
        // The ERASE_PUCK state erases the puck from its old location   
		  // At also calculates the new location of the puck. Note that since
		  // the puck is only one pixel, we only need to be here for one cycle.
		  // ============================================================
		  
        ERASE_PUCK1:  begin
				  colour <= BLACK;  // erase by setting colour to black
              plot <= 1'b1;
				  draw.x <= puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS];  // the x and y lines are driven by "puck1", stripped of its fractional components
				  draw.y <= puck1.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				                 // holds the location of the puck1.
				  state <= DRAW_PUCK1;  // next state is DRAW_PUCK1.
				  
				  puck1_velocity.y = puck1_velocity.y + GRAVITY;	// account for downwards acceleration  due to gravity
				  
				  // update the location of the puck1, taking integer values of each of x, y
				  puck1.x = puck1.x + puck1_velocity.x[INT_BITS + FRAC_BITS - 1:0];
				  puck1.y = puck1.y + puck1_velocity.y[INT_BITS + FRAC_BITS - 1:0];				  
				  
				  // See if we have bounced off the top of the screen
				  if (puck1.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= top_line + 1) begin
				     puck1_velocity.y = 0-puck1_velocity.y;
					  puck.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] = top_line + 1;
				  end // if

				  // See if we have bounced off the right or left of the screen
				  if ( (puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= LEFT_LINE + 1) |
				       (puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= RIGHT_LINE - 1)) begin 
				     puck1_velocity.x = 0-puck1_velocity.x;
				  end // if  
		
              // See if we have bounced of the paddle on the bottom row of
	           // the screen		
		        if (puck1.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= PADDLE_ROW - 1) begin 
				     if ((puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= paddle_x) &
					      (puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= paddle_x + paddle_width)) begin
							
					     // we have bounced off the paddle
   				     puck1_velocity.y = 0-puck1_velocity.y;
						  puck1.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] = PADDLE_ROW - 1;
						  
				     end else begin
				        // we are at the bottom row, but missed the paddle.  Reset game!
					     state <= INIT;
					  end // if
				  end // if  
			 end // ERASE_PUCK1
				  
		  // ============================================================
        // The DRAW_PUCK1 draws the puck1.  Note that since
		  // the puck1 is only one pixel, we only need to be here for one cycle.					 
		  // ============================================================
		  
        DRAW_PUCK1: begin
				  colour <= CYAN;
              plot <= 1'b1;
				  draw.x <= puck1.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				  draw.y <= puck1.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				  state <= ERASE_PUCK2;	  // next state is ERASE_PUCK2		  
           end // case DRAW_PUCK1
			  
			  
		  // ============================================================
        // The ERASE_PUCK2 state erases the puck from its old location   
		  // At also calculates the new location of the puck. Note that since
		  // the puck is only one pixel, we only need to be here for one cycle.
		  // ============================================================
		  
        ERASE_PUCK2:  begin
				  colour <= BLACK;  // erase by setting colour to black
              plot <= 1'b1;
				  draw.x <= puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS];  // the x and y lines are driven by "puck2", stripped of its fractional components
				  draw.y <= puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				                 // holds the location of the puck2.
				  state <= DRAW_PUCK2;  // next state is DRAW_PUCK2.
				  
				  puck2_velocity.y = puck2_velocity.y + GRAVITY; // account for downwards acceleration due to gravity

				  // update the location of the puck2 
				  puck2.x = puck2.x + puck2_velocity.x[INT_BITS + FRAC_BITS - 1:0];
				  puck2.y = puck2.y + puck2_velocity.y[INT_BITS + FRAC_BITS - 1:0];				  
				  
				  // See if we have bounced off the top of the screen
				  if (puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= top_line + 1) begin
				     puck2_velocity.y = 0-puck2_velocity.y;
					  puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] = top_line + 1;
				  end // if

				  // See if we have bounced off the right or left of the screen
				  if ( (puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= LEFT_LINE + 1) |
				       (puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= RIGHT_LINE - 1)) begin 
				     puck2_velocity.x = 0-puck2_velocity.x;
				  end // if  
		
              // See if we have bounced of the paddle on the bottom row of
	           // the screen		
		        if (puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= PADDLE_ROW - 1) begin 
				     if ((puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] >= paddle_x) &
					      (puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS] <= paddle_x + paddle_width)) begin
							
					     // we have bounced off the paddle
   				     puck2_velocity.y = 0-puck2_velocity.y;
						  puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS] = PADDLE_ROW - 1;
				     end else begin
				        // we are at the bottom row, but missed the paddle.  Reset game!
					     state <= INIT;
					  end // if
				  end // if  
			 end // ERASE_PUCK2
				  
		  // ============================================================
        // The DRAW_PUCK2 draws the puck2.  Note that since
		  // the puck2 is only one pixel, we only need to be here for one cycle.					 
		  // ============================================================
		  
        DRAW_PUCK2: begin
				  colour <= YELLOW;
              plot <= 1'b1;
				  draw.x <= puck2.x[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				  draw.y <= puck2.y[INT_BITS + FRAC_BITS - 1:FRAC_BITS];
				  state <= IDLE;	  // next state is IDLE (which is the delay state)			  
           end // case DRAW_PUCK1
			  
 		  // ============================================================
        // We'll never get here, but good practice to include it anyway
		  // ============================================================
		  
        default:
		    state <= START;
	
	
     endcase
	 end // if
	 
endmodule
