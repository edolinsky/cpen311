`ifndef _my_incl_vh_
`define _my_incl_vh_

//
// Data width of each x and y
//

parameter DATA_WIDTH_COORD = 8;
parameter FRAC_BITS = 8;
parameter INT_BITS = 8;

//
// This file provides useful parameters and types for Lab 3.
// 

parameter SCREEN_WIDTH = 160;
parameter SCREEN_HEIGHT = 120;


// Use the same precision for x and y as it simplifies life
// A new type that describes a pixel location on the screen
typedef struct {
   reg [INT_BITS + FRAC_BITS-1:0] x;
   reg [INT_BITS + FRAC_BITS-1:0] y;
} point;

// A new type that describes a velocity.  Each component of the
// velocity can be either + or -, so use signed type

typedef struct {
   reg signed [INT_BITS + FRAC_BITS-1:0] x;
   reg signed [INT_BITS + FRAC_BITS-1:0] y;
} velocity;
  
  //Colours.  
parameter BLACK = 3'b000;
parameter BLUE  = 3'b001;
parameter GREEN = 3'b010;
parameter CYAN = 3'b011;
parameter RED = 3'b100;
parameter PURPLE = 3'b101;
parameter YELLOW = 3'b110;
parameter WHITE = 3'b111;

// We are going to write this as a state machine.  The following
// is a list of states that the state machine can be in.

typedef enum int unsigned {INIT = 1 , START = 2, 
              DRAW_TOP_ENTER = 4, DRAW_TOP_LOOP = 8, 
              DRAW_RIGHT_ENTER = 16, DRAW_RIGHT_LOOP =32,
              DRAW_LEFT_ENTER = 64, DRAW_LEFT_LOOP = 128, IDLE =256, 
              ERASE_PADDLE_ENTER = 512, ERASE_PADDLE_LOOP = 1024, 
              DRAW_PADDLE_ENTER = 2048, DRAW_PADDLE_LOOP = 4096, 
              ERASE_PUCK1 = 8192, DRAW_PUCK1 = 16384, 
				  ERASE_PUCK2 = 32768, DRAW_PUCK2 = 65536} draw_state_type;  

// Here are some parameters that we will use in the code. 
 
// These parameters contain information about the paddle 
parameter INIT_PADDLE_WIDTH = 10;  // width, in pixels, of the initial paddle
parameter PADDLE_ROW = SCREEN_HEIGHT - 2;  // row to draw the paddle 
parameter PADDLE_X_START = SCREEN_WIDTH / 2;  // starting x position of the paddle

// These parameters describe the lines that are drawn around the  
// border of the screen  
parameter TOP_LINE = 4;
parameter RIGHT_LINE = SCREEN_WIDTH - 5;
parameter LEFT_LINE = 5;

// These parameters describe the starting location for the puck 
parameter FACEOFF_OFFSET = 10;

parameter FACEOFF_X1 = {{SCREEN_WIDTH/2 - FACEOFF_OFFSET}, {8'd0}};
parameter FACEOFF_Y1 = {{SCREEN_HEIGHT/2}, {8'd0}};

parameter FACEOFF_X2 = {{SCREEN_WIDTH/2 + FACEOFF_OFFSET}, {8'd0}};
parameter FACEOFF_Y2 = {{SCREEN_HEIGHT/2}, {8'd0}};
  
// Starting Velocity			  	
parameter VELOCITY_START_X1 = {{8'b00000000}, {8'b11110110}}; // 0.96
parameter VELOCITY_START_Y1 = {{8'b11111111}, {8'b11000000}}; // -0.25

parameter VELOCITY_START_X2 = {{8'b00000000}, {8'b11011100}}; // 0.86
parameter VELOCITY_START_Y2 = {{8'b11111111}, {8'b10000000}}; // -0.5
  
// This parameter indicates how many times the counter should count in the
// START state between each invocation of the main loop of the program.
// A larger value will result in a slower game.  The current setting will    
// cause the machine to wait in the start state for 1/8 of a second between 
// each invocation of the main loop.  The 50000000 is because we are
// clocking our circuit with  a 50Mhz clock. 
  
parameter LOOP_SPEED = 50000000/8;  // 8Hz
parameter PADDLE_SHRINK_SPEED = 50000000 * 20;
  
`endif // _my_incl_vh_