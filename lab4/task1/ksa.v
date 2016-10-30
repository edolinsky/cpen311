module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;

// states	

enum {INIT, FILL, DONE} state;

// these are signals that connect to the memory

reg [7:0] address, data, q;
reg wren;

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
			state <= FILL;
		end // case INIT
		
		
		/* FILL:
		 * this state fills memory addresses 0 to 255
		 * with values corresponding to the index
		 */
		FILL: begin
			
			if (address <= 8'd255) begin		// loop back in until done
				address <= address + 1'b1;			// increment address and data values
				data <= address + 1'b1;
				
				wren <= 1'b1;
				state <= FILL;
			
			end else begin						// when done, disable write and move to done_state
				address <= 8'd0;
				data <= 8'd0;
				wren <= 1'b0;
				state <= DONE;
			
			end // if
		end // case FILL
		
		/* DONE:
		 * this state does nothing but loop back into itself
		 */
		DONE: begin
			address <= 8'd0;
			data <= 8'd0;
			wren <= 1'b0;
			state <= DONE;
		end // case DONE
	
	endcase
end // always_ff


endmodule



