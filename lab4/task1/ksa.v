module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;

// states	

enum {F_INIT, FILL, // FILL stage states
		S_READ_I, S_WAIT_I, S_COMPUTE_J, S_COMPUTE_WAIT, S_WRITE_I, S_WRITE_J, // SWAP stage states
		D_INIT, D_INC_I, D_INC_I_WAIT, D_COMPUTE_J, D_COMPUTE_WAIT, D_WRITE_I, D_WRITE_J, D_READ_F, D_READ_K, D_GET_F, D_WRITE_OUT, // DECRYPT stage states
		DONE} state;

// Signals that connect to s_memory
reg [7:0] s_address, s_data, s_q;	
reg s_wren;

// Signals that connect to d_memory
reg [4:0] d_address;
reg [7:0] d_data, d_q;	
reg d_wren;

// Signals that connect to e_ROM
reg [4:0] e_address;
reg [7:0] e_q;

// Pointers and temporary storage
reg [7:0] i, j, k;								// addresses in s_memory
reg [7:0] data_i, data_j, data_f, data_k;	// values corresponding to above addresses

// secret key (display least significant 10 bits on LEDs)
reg [23:0] secret_key;
assign LEDR = secret_key[9:0];

// include S memory structurally

s_memory u0(	.address(s_address), 
					.clock(CLOCK_50), 
					.data(s_data), 
					.wren(s_wren), 
					.q(s_q));
					
					
// include D memory structurally
d_memory u1(	.address(d_address),
					.clock(CLOCK_50),
					.data(d_data),
					.wren(d_wren),
					.q(d_q));

// include e_ROM structurally			
e_ROM u2(		.address(e_address),
					.clock(CLOCK_50),
					.q(e_q));
// This code drives the address, data, and wren signals to fill the memory with the values 0..255.

always_ff @(posedge CLOCK_50) begin
	
	case (state)
		
		///////////////////////
		// FILL memory with 0-255
		
		/* F_INIT:
		 * this state initializes our memory filling process,
		 * and performs the first write at address 0.
		 */
		F_INIT: begin
			s_address <= 8'd0;
			s_data <= 8'd0;
			s_wren <= 1'b1;
			
			i <= 8'd0;
			j <= 8'd0;
			secret_key <= {{14'd0}, {SW}};
			state <= FILL;
		end // case F_INIT
		
		
		/* FILL:
		 * this state fills memory addresses 0 to 255
		 * with values corresponding to the index
		 */
		FILL: begin
			
			if (s_address < 8'd255) begin				// loop back in until done
				s_address <= s_address + 1'b1;		// increment address and data values
				s_data <= s_data + 1'b1;
				
				s_wren <= 1'b1;
				state <= FILL;
			
			end else begin						// when done, disable write and move to done_state
				state <= S_READ_I;
			end // if
		end // case FILL
		
		
		///////////////////////
		// SWAP Memory based on key
		
		/* S_READ_I:
		 * this state asserts s_wren to 0 and loads the address of  i
		 */
		S_READ_I: begin
			s_wren <= 1'b0;
			s_address <= i;	// read i
			state <= S_WAIT_I;
		end // case S_READ_I
		
		/* S_WAIT_I:
		 * no-op state after S_READ_I
		 */
		S_WAIT_I: begin
			state <= S_COMPUTE_J;
		end // case S_WAIT_I
		
		/* S_COMPUTE_J:
		 * this state loads the value of i to a register, 
		 * computes the desired address of j,
		 * and initializes a read from that address
		 */
		S_COMPUTE_J: begin
			data_i = s_q;	// load i
			j = (j + data_i + secret_key[5'd23 - (4'd8 * (i % 2'd3)) -: 8]);	// compute j
			s_wren <= 1'b0;
			
			s_address <= j;	// read j
			state <= S_COMPUTE_WAIT;
		end // case S_COMPUTE_J
		
		/* S_COMPUTE_WAIT:
		 * no-op state after S_COMPUTE_J
		 */
		S_COMPUTE_WAIT: begin
			state <= S_WRITE_I;
		end // case S_COMPUTE_WAIT
		
		/* S_WRITE_I:
		 * loads the value of j into its register, 
		 * and writes  the value at i to memory at s_address j
		 */
		S_WRITE_I: begin
			data_j = s_q;	// load j
			s_wren <= 1'b1;
			s_data <= data_j; // write data_j to i
			s_address <= i;
			state <= S_WRITE_J;
		end // case S_WRITE_I
		
		/* S_WRITE_J:
		 * writes the value at j to memory at address i, 
		 * and evaluates whether we should enter the swapping loop or carry on
		 */
		S_WRITE_J: begin
			s_wren <= 1'b1;
			s_data <= data_i;  // write data_i to j
			s_address <= j;
			
			if (i < 8'd255) begin
				i <= i + 1'b1;
				state <= S_READ_I;
			end else begin
				state <= D_INIT;
			end // if
		end // case S_WRITE_J
		
		
		/////////////////////////////
		// DECRYPT message given key
		
		/* D_INIT:
		 * initializes addresses for decryption stage
		 */
		D_INIT: begin
			i <= 8'd0;
			j <= 8'd0;
			k <= 8'd0;
			state <= D_INC_I;
		end // case D_INIT
		
		/* D_INC_I:
		 *	increments address i and initializes read from s_memory at address i
		 */
		D_INC_I: begin
			i = i + 1'b1;
			
			s_address <= i;
			s_wren <= 1'b0;
			
			state <= D_INC_I_WAIT;
		end // case D_INC_I
		
		
		/* D_INC_I_WAIT:
		 * no-op stage after D_INC_I
		 */
		D_INC_I_WAIT: begin
			state <= D_COMPUTE_J;
		end // case D_INC_I_WAIT
		
		/* D_COMPUTE_J:
		 * completes read from address i, uses this to initialize read at address j.
		 */
		D_COMPUTE_J: begin
			data_i = s_q;		// load data_i and compute j
			j = j + data_i;
			
			s_wren <= 1'b0;	// read from address j
			s_address <= j;
			
			state <= D_COMPUTE_WAIT;
		end // case D_COMPUTE_J
		
		/* D_COMPUTE_WAIT:
		 * no-op state after D_COMPUTE_J
		 */
		D_COMPUTE_WAIT: begin
			state <= D_WRITE_I;
		end // case D_COMPUTE_WAIT
		
		/* D_WRITE_I:
		 * completes read from address j, writes the value to address i
		 */
		D_WRITE_I: begin
			data_j = s_q;	// load data_j
			
			s_wren <= 1'b1;	// write data_j to i
			s_data <= data_j;
			s_address <= i;
			
			state <= D_WRITE_J;
		end // case D_WRITE_I

		/* D_WRITE_J:
		 * writes value from address i to address j
		 */
		D_WRITE_J: begin
			
			s_wren <= 1'b1;	// write data_i to j
			s_data <= data_i;
			s_address <= j;
			
			state <= D_READ_F;
		end // case D_WRITE_J
		
		/* D_READ_F:
		 *	initializes read from address f in s_memory
		 */
		D_READ_F: begin
			
			s_wren <= 1'b0;	// read from address f in s_memory
			s_address <= (data_j + data_i) % 9'd256;
			
			state <= D_READ_K;
		end // case D_READ_F
		
		/*	D_READ_K:
		 * initializes read from address k in e_memory.
		 * Serves as WAIT state after D_READ_F
		 */
		D_READ_K: begin
			
			e_address <= k[4:0];	// read from address k in e_ROM
			
			state <= D_GET_F;
		end // case D_READ_K
		
		/* D_GET_F:
		 * loads value at address f from s_memory
		 * Serves as WAIT state after D_READ_K
		 */
		D_GET_F: begin
			data_f <= s_q;
			state <= D_WRITE_OUT;
		end // case D_GET_F
		
		/* D_WRITE_OUT:
		 * Computes decrypted character using data_f and value at address k in e_ROM
		 * Writes this value to d_memory
		 * Determines whether or not to enter decryption loop once again
		 */
		D_WRITE_OUT: begin
		
			d_wren = 1'b1;	// compute and write decrypted character to d_memory
			d_data = (data_f ^ e_q);
			d_address = k[4:0];
			
			if (k[4:0] < 5'd31) begin	// loop control: exit once we have completed 32 iterations
				k <= k + 1'b1;
				state <= D_INC_I;
			end else begin
				state <= DONE;
			end // if
			
		end // case D_WRITE_OUT
			
		/* DONE:
		 * this state does nothing but loop back into itself
		 */
		DONE: begin
			state <= DONE;
		end // case DONE
	
	endcase
end // always_ff


endmodule



