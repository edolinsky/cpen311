module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;

// states	

enum {INIT, FILL, READ_I, SHUFFLE_LOOP, SHUFFLE_WAIT, COMPUTE, COMPUTE_WAIT, WRITE_I, WRITE_J, DONE} state;

// these are signals that connect to the memory

reg [23:0] secret_key;
reg [7:0] address, data, q, i, j, data_i, data_j;
reg wren;

assign LEDR = secret_key[9:0];

// include S memory structurally

s_memory u0(	.address(address), 
					.clock(CLOCK_50), 
					.data(data), 
					.wren(wren), 
					.q(q));


// This code drives the address, data, and wren signals to fill the memory with the values 0..255.

always_ff @(posedge CLOCK_50) begin
	
	case (state)
		
		/* INIT:
		 * this state initializes our memory filling process,
		 * and performs the first write at address 0.
		 */
		INIT: begin
			address <= 8'd0;
			data <= 8'd0;
			wren <= 1'b1;
			
			i <= 8'd0;
			j = 8'd0;
			secret_key <= {{14'd0}, {SW}};
			state <= FILL;
		end // case INIT
		
		
		/* FILL:
		 * this state fills memory addresses 0 to 255
		 * with values corresponding to the index
		 */
		FILL: begin
			
			if (address < 8'd255) begin		// loop back in until done
				address <= address + 1'b1;			// increment address and data values
				data <= data + 1'b1;
				
				wren <= 1'b1;
				state <= FILL;
			
			end else begin						// when done, disable write and move to done_state
				state <= READ_I;;
			end // if
		end // case FILL
		
		READ_I: begin
			wren <= 1'b0;
			address <= i;	// read i
			state <= SHUFFLE_LOOP;
		end // case READ_I
		
		SHUFFLE_LOOP: begin
			if (i < 8'd255) begin
				i <= i + 1'b1;
				state <= SHUFFLE_WAIT;
			end else begin
				state <= DONE;
			end // if
		end // case SHUFFLE
		
		SHUFFLE_WAIT: begin
			data_i <= q;	// load i
			state <= COMPUTE;
		end // case POST_SHUFFLE
		
		COMPUTE: begin
			j = (j + data_i + secret_key[2'd2 - (4'd8 * (i % 2'd3)) +: 8]);	// compute j
			wren <= 1'b0;
			
			address <= j;	// read j
			state <= COMPUTE_WAIT;
		end // case COMPUTE
		
		COMPUTE_WAIT: begin
			state <= WRITE_I;
		end // case POST_COMPUTE
		
		WRITE_I: begin
			data_j <= q;	// load j
			wren <= 1'b1;
			data <= data_j;
			address <= i;
			state <= WRITE_J;
		end // case WRITE_I
		
		WRITE_J: begin
			wren <= 1'b1;
			data <= data_i;
			address <= j;
			state <= READ_I;
		end // case WRITE_J
		
		/* DONE:
		 * this state does nothing but loop back into itself
		 */
		DONE: begin
			state <= DONE;
		end // case DONE
	
	endcase
end // always_ff


endmodule



