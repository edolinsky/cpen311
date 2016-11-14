module flash_reader_de2( CLOCK_50, KEY,
    FL_ADDR,
    FL_CE_N,
    FL_DQ,
    FL_OE_N,
    FL_RST_N,
    FL_WE_N);
  
input CLOCK_50;
input [3:0] KEY;

// Flash memory I/O
// low enable for all signals
output [21:0] FL_ADDR;	// Flash address bus
output FL_CE_N;			// Flash Chip enable
inout[7:0] FL_DQ;			// Flash Data input/output
output FL_OE_N;			// Flash output enable
output FL_RST_N;			// Flash hardware reset
output FL_WE_N;			// Flash write enable

// State machine states
enum {FL_INIT, FL_READ, FL_WAIT, FL_LOAD, FL_LOOP_CONTROL, DONE} state;

// clock & reset
wire clk, resetb;
assign clk = CLOCK_50;
assign resetb = KEY[3];

// Do not need to reset, nor write to flash
assign FL_WE_N = 1'b1;	// high write enable for flash read
assign FL_RST_N = 1'b1; // flash reset is low enable

// Wait counter
parameter WAIT_CYCLES = 3'd6; // minimum 110ns read time, so wait 6 cycles in between read and load on 50MHz clock (120ns)
reg [2:0] wait_reg;	// register for number of cycles in 

// RAM & intermediary registers
reg s_wren;
reg [7:0] s_address;
reg [15:0] s_data, s_q, f_data;
reg addr_offset;

s_memory s0(.address(s_address),
				.clock(CLOCK_50),
				.data(s_data),
				.wren(s_wren),
				.q(s_q));

always_ff @(posedge CLOCK_50, negedge resetb) begin

	if(resetb == 0) begin
		state <= FL_INIT;
	end else begin
	
	case (state)

		/* FL_INIT:
		 * This state initializes registers needed for loading data from flash
		 */
		FL_INIT: begin
			s_address <= 8'd0;	// initialize address to 0
			addr_offset <= 1'b0;	// initialize flash offset address to 0
			wait_reg <= 3'd0;		// initialize wait counter to 0
			
			state <= FL_READ;
		end // case FL_INIT
		
		/* FL_READ:
		 * This state initializes the read process from flash
		 */
		FL_READ: begin
			FL_OE_N <= 1'b0;
			FL_CE_N <= 1'b0;
			
			// can only read 8 bits at a time, so read each byte separately
			FL_ADDR <= (2'd2 * s_address) + addr_offset;
			
			state <= FL_WAIT;
		end // case FL_READ
		
		/* FL_WAIT:
		 * This state waits WAIT_CYCLES cycles after a read from flash is initialized
		 */
		FL_WAIT: begin
			
			// no-op loop until wait counter is finished
			if (wait_reg < WAIT_CYCLES) begin
				wait_reg <= wait_reg + 1'b1;
				state <= FL_WAIT;
				
			// reset wait counter and move to next state
			end else begin
				wait_reg <= 3'd0;
				state <= FL_LOAD;
			end // if
			
		end // case FL_WAIT
		
		/*	FL_LOAD:
		 *	This state loads the requested byte from flash into an internal register
		 * and if the full sample (2 bytes) has been read, loads the sample into memory
		 */
		FL_LOAD: begin
			
			// load byte that has been read
			f_data[4'd8 * addr_offset +: 4'd8] = FL_DQ;
			FL_OE_N <= 1'b1;
			FL_CE_N <= 1'b1;
			
			// if offset is 0, we still need to read one more byte
			if (addr_offset == 1'b0) begin
				addr_offset <= 1'b1;
				
				state <= FL_READ;
				
			// if offset is 1, full sample has been read; load into memory
			end else begin
				addr_offset <= 1'b0;
				
				s_wren <= 1'b1;
				s_data <= f_data;
				
				state <= FL_LOOP_CONTROL;
			end // if
		end // case FL_LOAD
		
		/* FL_LOOP_CONTROL
		 * This state determines whether we need to continue reading information,
		 * and updates the write address accordingly
		 */
		FL_LOOP_CONTROL: begin
			
			if (s_address < 8'd255) begin
				s_address <= s_address + 1'b1;
				state <= FL_READ;
			end else begin
				state <= DONE;
			end // if
		
		end // case FL_LOOP_CONTROL
		
		DONE: begin
			state <= DONE;
		end // case DONE
		
	
	
	endcase
	
	
	end // if
	

end


endmodule
