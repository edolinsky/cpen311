module lab5(CLOCK_50, CLOCK_27, KEY, FL_ADDR, FL_CE_N, FL_DQ, FL_OE_N, FL_RST_N, FL_WE_N,
AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, I2C_SDAT, I2C_SCLK, AUD_DACDAT, AUD_XCK);

input CLOCK_50, CLOCK_27, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT;
inout I2C_SDAT;
output I2C_SCLK,AUD_DACDAT,AUD_XCK;
input [3:0] KEY;

output [21:0] FL_ADDR;	// Flash address bus
output FL_CE_N;			// Flash Chip enable
inout[7:0] FL_DQ;			// Flash Data input/output
output FL_OE_N;			// Flash output enable
output FL_RST_N;			// Flash hardware reset
output FL_WE_N;			// Flash write enable

// reset
assign resetb = KEY[3];

// State machine states
enum {WAIT_READ_READY, WAIT_WRITE_READY, SEND_SAMPLE, WAIT_ACCEPT, DONE} state;


// signals that are used to communicate with the audio core

reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire reset, read_s;

// instantiate the parts of the audio core. 

clock_generator my_clock_gen (CLOCK_27, reset, AUD_XCK);
audio_and_video_config cfg (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
audio_codec codec (CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

assign reset = ~resetb;

// we will never read from the microphone in this lab, so we might as well set read_s to 0.
assign read_s = 1'b0;

// flash reader signals
wire [15:0] f_data, sample;
wire valid, next, done;

flash_reader_de2 flash_reader(
	.CLOCK_50(CLOCK_50),
	.resetb(resetb),
	.FL_ADDR(FL_ADDR),
	.FL_CE_N(FL_CE_N),
	.FL_DQ(FL_DQ),
	.FL_OE_N(FL_OE_N),
	.FL_RST_N(FL_RST_N),
	.FL_WE_N(FL_WE_N),
	.data(f_data),
	.valid(valid),
	.next(next),
	.done(done));

always_ff @(posedge CLOCK_50, negedge resetb) begin

	if(resetb == 0) begin
		next <= 1'b0;
		state <= WAIT_READ_READY;
	end else begin
	
	case(state)
	
		/* WAIT_READ_READY:
		 * waits for a value to be ready from flash memory
		 */
		WAIT_READ_READY: begin
			write_s <= 1'b0;
			
			if (done) begin
				state <= DONE;
			end else if (valid == 1) begin
				sample <= f_data; // record the data provided
				next <= 1'b1; // start reading the next sample
				state <= WAIT_WRITE_READY;
			end else begin
				state <= WAIT_READ_READY;
			end
			
		end
		
		/* WAIT_WRITE_READY:
		 * waits for the audio core to be ready for a sample
		 * and the flash memory to have started its next read.
		 */
		WAIT_WRITE_READY: begin
			if (write_ready == 1'b1 && valid == 1'b0) begin
				next <= 1'b0;
				state <= SEND_SAMPLE;
			end else begin
				state <= WAIT_WRITE_READY;
			end
		end
		
		/* SEND_SAMPLE:
		 * sends a sample to the audio core
		 */
		SEND_SAMPLE: begin
			writedata_right <= sample;
			writedata_left <= sample;
			write_s <= 1'b1;  // indicate we are writing a value
			state <= WAIT_ACCEPT;
		end
		
		/* WAIT_ACCEPT:
		 * waits for the sample to be accepted by the audio core
		 */
		WAIT_ACCEPT: begin
			if (write_ready == 1'b0) begin
				state <= WAIT_READ_READY;
			end
		end
		
		DONE: begin
			state <= DONE;
		end
		
		default: begin
			state <= WAIT_READ_READY;
		end
		
	endcase
	
	end
	
end

endmodule