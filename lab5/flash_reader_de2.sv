module flash_reader_de2( CLOCK_50, CLOCK_27, KEY, SW, FL_ADDR, FL_CE_N, FL_DQ, FL_OE_N, FL_RST_N, FL_WE_N,
         AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT, I2C_SDAT, I2C_SCLK, AUD_DACDAT, AUD_XCK);

input CLOCK_50,CLOCK_27,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT;
input [3:0] KEY;
input [1:0] SW;
inout I2C_SDAT;
output I2C_SCLK,AUD_DACDAT,AUD_XCK;

// Flash memory I/O
// low enable for all signals
output [21:0] FL_ADDR;	// Flash address bus
output FL_CE_N;			// Flash Chip enable
inout[7:0] FL_DQ;			// Flash Data input/output
output FL_OE_N;			// Flash output enable
output FL_RST_N;			// Flash hardware reset
output FL_WE_N;			// Flash write enable

// State machine states
enum {FL_INIT, FL_READ, FL_WAIT, FL_LOAD, FL_LOOP_CONTROL, WAIT_READY, SEND_SAMPLE, WAIT_ACCEPTED, TURTLE, DONE} state;

// clock & reset
wire resetb;
assign resetb = KEY[3];

// Do not need to reset, nor write to flash
assign FL_WE_N = 1'b1;	// high write enable for flash read
assign FL_RST_N = 1'b1; // flash reset is low enable

// Wait counter
parameter WAIT_CYCLES = 3'd6; // minimum 110ns read time, so wait 6 cycles in between read and load on 50MHz clock (120ns)
reg [2:0] wait_reg;	// register for number of cycles in 

reg [23:0] f_address;
reg [15:0] f_data;
reg signed [16:0] signed_sample;
reg addr_offset;

// signals that are used to communicate with the audio core
reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire audio_reset, read_s;

assign audio_reset = ~(KEY[3]);
assign read_s = 1'b0;

// instantiate the parts of the audio core. 
clock_generator my_clock_gen (CLOCK_27, audio_reset, AUD_XCK);
audio_and_video_config cfg (CLOCK_50, audio_reset, I2C_SDAT, I2C_SCLK);
audio_codec codec (CLOCK_50,audio_reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

s_memory s0(.address(f_address),
				.clock(CLOCK_50),
				.data(s_data),
				.wren(s_wren),
				.q(s_q));
				
// challenge mode
wire chipmunk, chipmunk_counter, turtle, turtle_counter;
assign chipmunk = SW[0];
assign turtle = SW[1];

always_ff @(posedge CLOCK_50, negedge resetb) begin

	if(resetb == 0) begin
		write_s <= 1'b0;
		state <= FL_INIT;
		valid <= 0;
	end else begin
	
	case (state)

		/* FL_INIT:
		 * This state initializes registers needed for loading data from flash
		 */
		FL_INIT: begin
			f_address <= 24'd0;	// initialize address to 0
			addr_offset <= 1'b0;	// initialize flash offset address to 0
			wait_reg <= 3'd0;		// initialize wait counter to 0
			
			
			chipmunk_counter <= 1'b0;
			turtle_counter <= 1'b0;
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
				
				signed_sample <= $signed(f_data)/$signed(8'd64);
				// start write handshake
				
				if (turtle == 1'b0 && chipmunk == 1'b1) begin
				
					if (chipmunk_counter == 1'b0) begin
						state <= FL_LOOP_CONTROL;
						chipmunk_counter <= 1'b1;
					end else begin
						state <= WAIT_READY;
						chipmunk_counter <= 1'b0;
					end
					
				end else begin
					state <= WAIT_READY;
				end
			end // if
		end // case FL_LOAD
		
		WAIT_READY: begin
		
			if (write_ready == 1'b1) begin
				state <= SEND_SAMPLE;
			end
		end
		
		SEND_SAMPLE: begin
		
			writedata_left <= signed_sample;
			writedata_right <= signed_sample;
			write_s <= 1'b1;
			state <= WAIT_ACCEPTED;
		end
		
		WAIT_ACCEPTED: begin
			if (write_ready == 1'b0) begin
			
				if (turtle == 1'b1 && chipmunk == 1'b0) begin
					if (turtle_counter == 1'b0) begin
						state <= TURTLE;
						turtle_counter <= 1'b1;
					end else begin
						state <= FL_LOOP_CONTROL;
						turtle_counter <= 1'b0;
					end
					
				end else begin
					state <= FL_LOOP_CONTROL;
				end
			end
		end
		
		/* TURTLE:
		 * This state is a surrugate loop control for playing a sample twice
		 */
		TURTLE: begin
			write_s <= 1'b0;
			state <= WAIT_READY;
		end
			
		
		/* FL_LOOP_CONTROL
		 * This state determines whether we need to continue reading information,
		 * and updates the write address accordingly
		 */
		FL_LOOP_CONTROL: begin
			write_s <= 1'b0;
			
			if (f_address < 21'h1FFFFF) begin
				f_address <= f_address + 1'b1;
				state <= FL_READ;
			end else begin
				state <= FL_INIT;
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
		
	endcase
	
	
	end // if
	

end


endmodule
