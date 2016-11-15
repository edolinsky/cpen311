module flash_reader_de2( CLOCK_50, resetb,
    FL_ADDR,
    FL_CE_N,
    FL_DQ,
    FL_OE_N,
    FL_RST_N,
    FL_WE_N,
	 data,
	 valid,
	 next,
	 done
	 );
  
input CLOCK_50;
input resetb;

// Flash memory I/O
// low enable for all signals
output [21:0] FL_ADDR;	// Flash address bus
output FL_CE_N;			// Flash Chip enable
inout[7:0] FL_DQ;			// Flash Data input/output
output FL_OE_N;			// Flash output enable
output FL_RST_N;			// Flash hardware reset
output FL_WE_N;			// Flash write enable

output [15:0] data;
output valid, done;
input next;

// State machine states
enum {FL_INIT, FL_READ, FL_WAIT, FL_LOAD, FL_LOOP_CONTROL, WAIT, DONE} state;

// Do not need to reset, nor write to flash
assign FL_WE_N = 1'b1;	// high write enable for flash read
assign FL_RST_N = 1'b1; // flash reset is low enable

// Wait counter
parameter WAIT_CYCLES = 3'd6; // minimum 110ns read time, so wait 6 cycles in between read and load on 50MHz clock (120ns)
reg [2:0] wait_reg;	// register for number of cycles in 

// RAM & intermediary registers
reg [7:0] f_address;
reg [15:0] f_data;
reg addr_offset;

always_ff @(posedge CLOCK_50, negedge resetb) begin

	if(resetb == 0) begin
		state <= FL_INIT;
	end else begin
	
	case (state)

		/* FL_INIT:
		 * This state initializes registers needed for loading data from flash
		 */
		FL_INIT: begin
			f_address <= 8'd0;	// initialize address to 0
			addr_offset <= 1'b0;	// initialize flash offset address to 0
			wait_reg <= 3'd0;		// initialize wait counter to 0
			
			data <= 16'd0; // init data to 0
			valid <= 1'b0; // init valid flag to 0
			done <= 1'b0;
			
			state <= FL_READ;
		end // case FL_INIT
		
		/* FL_READ:
		 * This state initializes the read process from flash
		 */
		FL_READ: begin
			FL_OE_N <= 1'b0;
			FL_CE_N <= 1'b0;
			
			// can only read 8 bits at a time, so read each byte separately
			FL_ADDR <= (2'd2 * f_address) + addr_offset;
			
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
		 * and if the full sample (2 bytes) has been read, places the value on the data bus
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
				
			// if offset is 1, full sample has been read;
			end else begin
				addr_offset <= 1'b0;
				
				valid <= 1'b1;
				data <= f_data;
				
				state <= FL_LOOP_CONTROL;
			end // if
		end // case FL_LOAD
		
		/* FL_LOOP_CONTROL
		 * This state determines whether we need to continue reading information,
		 * and updates the write address accordingly
		 */
		FL_LOOP_CONTROL: begin
			
			if (f_address < 8'd255) begin
				f_address <= f_address + 1'b1;
				state <= WAIT;
			end else begin
				state <= DONE;
			end // if
		
		end // case FL_LOOP_CONTROL
		
		/* WAIT:
		 * This states waits for input to instruct the module to load the next value
		 */
		WAIT: begin
			if (next == 1'b1) begin
				valid <= 0; // the data is no longer the next valid value
				state <= FL_READ; // read next value
			end
		end // case WAIT
		
		DONE: begin
			state <= DONE;
			done <= 1'b1;
		end // case DONE
		
	endcase
	
	
	end // if
	

end


endmodule
