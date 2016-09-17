module statemachine ( slow_clock, resetb,
                      dscore, pscore, pcard3,
                      load_pcard1, load_pcard2,load_pcard3,
                      load_dcard1, load_dcard2, load_dcard3,
                      player_win_light, dealer_win_light);
							 
input slow_clock, resetb;
input [3:0] dscore, pscore, pcard3;
output load_pcard1, load_pcard2, load_pcard3;
output load_dcard1, load_dcard2, load_dcard3;
output player_win_light, dealer_win_light;

enum {NEW_GAME, P_CARD1, D_CARD1, P_CARD2, D_CARD2, P_CARD3, D_CARD3, SCORE, P_WIN, D_WIN, TIE} current_state;

/*
	STATES
	
	2'd00 , 4'b0000: New game
	2'd01 , 4'b0001: Player 1 card
	2'd02 , 4'b0010: Dealer 1 card
	2'd03 , 4'b0011: Player 2 card
	2'd04 , 4'b0100: Dealer 2 card
	2'd05 , 4'b0101: Player 3 card
	2'd06 , 4'b0110: Dealer 3 card
	2'd07 , 4'b0111: Score
	2'd08 , 4'b1000: Player win
	2'd09 , 4'b1001: Dealer win
	2'd10 , 4'b1010: Tie
	others: invalid
*/

// The code describing your state machine will go here.  Remember that
// a state machine consists of next state logic, output logic, and the 
// registers that hold the state.  You will want to review your notes from
// CPEN 211 or equivalent if you have forgotten how to write a state machine.

	always_comb
		begin
			if (resetb == 1)									// reset on reset bit
					current_state = NEW_GAME;
			else
				begin
					case (current_state)
						NEW_GAME: 
							current_state = P_CARD1; 			// deal player first card
						P_CARD1: current_state = D_CARD1; 			// deal dealer first card
						D_CARD1: current_state = P_CARD2; 			// deal player second card
						P_CARD2: current_state = D_CARD2; 			// deal dealer second card
						D_CARD2: 
							if ((pscore >= 8) || (dscore >= 8))		// "natural": score of 8 or 9 in any hand
								current_state = SCORE;
							else if (pscore <= 5)						// give player a card if score is too low
								current_state = P_CARD3;
							else if (dscore <= 5)						// give dealer a card if score is too low
								current_state = D_CARD3;				
							else												// evaluate score if both hands are in range 6,7
								current_state = SCORE;
						P_CARD3:											
							if (dscore == 7)
								current_state = SCORE;				// score
							else if ((dscore == 6) && (6 <= pscore <= 7))
								current_state = D_CARD3;
							else if ((dscore == 5) && (4 <= pscore <= 7))
								current_state = D_CARD3;
							else if ((dscore == 4) && (2 <= pscore <= 7))
								current_state = D_CARD3;
							else if ((dscore == 3) && (pscore != 8))
								current_state = D_CARD3;
							else if (dscore <= 2)
								current_state = D_CARD3;
							else
								current_state = SCORE;
						D_CARD3: current_state = SCORE;				// both players have 3 cards: score
						SCORE:
							if (pscore > dscore)
								current_state = P_WIN;
							else if (pscore < dscore)
								current_state = D_WIN;
							else
								current_state = TIE;
																			// reset at end of game
						P_WIN: current_state = NEW_GAME;			// player win
						D_WIN: current_state = NEW_GAME;			// dealer win
						TIE: current_state = NEW_GAME;			// tie
						default: current_state = NEW_GAME;			// reset if invalid state (should not happen)	
					endcase
				end
		end
			
endmodule