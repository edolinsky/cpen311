module lab5 (CLOCK_50, CLOCK_27, KEY,
         AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT,
			I2C_SDAT, I2C_SCLK,AUD_DACDAT,AUD_XCK,
			FL_ADDR, FL_CE_N, FL_DQ, FL_OE_N, FL_RST_N, FL_WE_N);
				
input CLOCK_50,CLOCK_27,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT;
input [3:0] KEY;
inout I2C_SDAT;
output I2C_SCLK,AUD_DACDAT,AUD_XCK;

// Flash memory I/O
output [21:0] FL_ADDR;	// Flash address bus
output FL_CE_N;			// Flash Chip enable
inout[7:0] FL_DQ;			// Flash Data input/output
output FL_OE_N;			// Flash output enable
output FL_RST_N;			// Flash hardware reset
output FL_WE_N;			// Flash write enable

// states
enum {WAIT_UNTIL_READY, COLLECT_SAMPLE, SEND_SAMPLE, WAIT_FOR_ACCEPTED, DONE} state;

// signals that are used to communicate with the audio core
reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire reset, audio_reset, read_s;

// instantiate the parts of the audio core. 
clock_generator my_clock_gen (CLOCK_27, audio_reset, AUD_XCK);
audio_and_video_config cfg (CLOCK_50, audio_reset, I2C_SDAT, I2C_SCLK);
audio_codec codec (CLOCK_50,audio_reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

// our components work with an active low reset;
assign reset = KEY[3];
// The audio core requires an active high audio_reset signal
assign audio_reset = ~(KEY[3]);
// we will never read from the microphone in this lab, so we might as well set read_s to 0.
assign read_s = 1'b0;

// flash reader singals
reg [15:0] data, sample;
wire valid, next, done;
// instantiate flash memory reader
flash_reader_de2 flash_reader( CLOCK_50, reset, FL_ADDR, FL_CE_N, FL_DQ, FL_OE_N, FL_RST_N, FL_WE_N, data, valid, next, done);
	
always_ff @(posedge CLOCK_50, posedge reset)
	if (reset == 1'b1) begin
		state <= WAIT_UNTIL_READY;
		next <= 0;
	write_s <= 1'b0;

	end else begin
	
	case (state)

		WAIT_UNTIL_READY: begin

		// In this state, we set write_s to 0,
		// and wait for write_ready to become 1.
		// The write_ready signal will go 1 when the FIFOs
		// are ready to accept new data.  We can't do anything
		// until this signal goes to a 1.

			write_s <= 1'b0;
			if (write_ready == 1'b1) begin
				state <= COLLECT_SAMPLE;
			end
		end // WAIT_UNTIL_READY	

		COLLECT_SAMPLE : begin
			
			if (valid == 1'b1) begin
				
				if (done == 1'b1) begin
					state <= DONE;
				end else begin 
					sample <= data;
					next <= 1'b1;
					state <= SEND_SAMPLE;
				end
			end
		end

		SEND_SAMPLE: begin
			next <= 1'b0;

			writedata_right <= sample;
			writedata_left <= sample;
			write_s <= 1'b1;  // indicate we are writing a value
			state <= WAIT_FOR_ACCEPTED;
		end // SEND_SAMPLE

		WAIT_FOR_ACCEPTED: begin

		// now we have to wait until the core has accepted
		// the value. We will know this has happened when
		// write_ready goes to 0.   Once it does, we can 
		// go back to the top, set write_s to 0, and 
		// wait until the core is ready for a new sample.

			if (write_ready == 1'b0) begin
				state <= WAIT_UNTIL_READY;
			end

		end // WAIT_FOR_ACCEPTED
		
		DONE: begin
			state <= DONE;
		end

		default: begin
			state <= WAIT_UNTIL_READY;
		end // default
		
	endcase
end  // if 

endmodule
