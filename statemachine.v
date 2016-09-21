module statemachine ( slow_clock, resetb, load_wager, result, betting,
                      dscore, pscore, pcard3,
                      load_pcard1, load_pcard2,load_pcard3,
                      load_dcard1, load_dcard2, load_dcard3,
                      player_win_light, dealer_win_light);
							 
input slow_clock, resetb;
input [3:0] dscore, pscore, pcard3;
output result;
output load_wager;
output betting;
output load_pcard1, load_pcard2, load_pcard3;
output load_dcard1, load_dcard2, load_dcard3;
output player_win_light, dealer_win_light;

enum {NEW_GAME, P_CARD1, D_CARD1, P_CARD2, D_CARD2, DECIDE, P_CARD3, D_CARD3, SCORE} current_state, next_state;


/*
	STATE TRANSITION LOGIC
*/
	always_comb
		begin
			case (current_state)
				NEW_GAME:
					next_state = P_CARD1;	
				P_CARD1: 
					next_state = D_CARD1;		// deal dealer first card
				D_CARD1: 				
					next_state = P_CARD2; 		// deal player second card
				P_CARD2: 				
					next_state = D_CARD2; 		// deal dealer second card
				D_CARD2: 
						next_state = DECIDE;		// enter decision logic after dealer's second card is dealt
				DECIDE:
					begin
						if (pcard3 == 0)			// evaluate this set if third player card has not yet been dealt
							begin
								if (pscore >= 8 || dscore >= 8)				// "natural": evaluate score if 8 or 9 in any hand
									next_state = SCORE;
								else if (pscore <= 5)							// give player a card if its score is too low
									next_state = P_CARD3;
								else if (dscore <= 5)							// give dealer a card its score is too low
									next_state = D_CARD3;		
								else													// evaluate score if both hands are in range 6,7
									next_state = SCORE;
							end
						else							// evaluate this set if third player card has been dealt
							begin
								if ((dscore == 6) && (6 <= pcard3) && (pcard3 <= 7))			// give dealer a card if any of these statements are true; 1
									next_state = D_CARD3;								
								else if ((dscore == 5) && (4 <= pcard3) && (pcard3 <= 7))   // 2
									next_state = D_CARD3;								
								else if ((dscore == 4) && (2 <= pcard3) && (pcard3 <= 7))	// 3
									next_state = D_CARD3;								
								else if ((dscore == 3) && (pcard3 != 8))							// 4
									next_state = D_CARD3;
								else if (dscore <= 2)													// 5
									next_state = D_CARD3;
								else																			// score otherwise
									next_state = SCORE;
							end
					end			
				P_CARD3:											
					if (dscore == 7)			// evaluate score if dealer score is 7
						next_state = SCORE;
					else							// evaluate score otherwise
						next_state = DECIDE;
						
				D_CARD3: 						// both players have 3 cards: score
					next_state = SCORE;								
				SCORE: 							// do nothing when game is finished, until reset button is pressed
					next_state = NEW_GAME;					
				default: 						// reset if invalid state (should not happen)
					next_state = NEW_GAME;								
			endcase
		end
		
	/*
		STATE MACHINE OUTPUT LOGIC
	*/
	always_ff @(posedge slow_clock or negedge resetb)
		begin
			
			if (resetb == 0)						// if reset button is pressed, start from beginning   
				current_state <= NEW_GAME;
			else
				begin
					current_state <= next_state;
					
					load_pcard1 <= 0;		// default state: no cards, no lights
					load_pcard2 <= 0;
					load_pcard3 <= 0;
					
					load_dcard1 <= 0;
					load_dcard2 <= 0;
					load_dcard3 <= 0;
					
					dealer_win_light <= 0;
					player_win_light <= 0;
					
					load_wager <= 0;
					result <= 0;
					
					if (current_state == NEW_GAME)
						betting <= 1;
					else
						betting <= 0;
					
						case (current_state)
							NEW_GAME:
									load_wager <= 1;
							P_CARD1:							// load player's first card
									load_pcard1 <= 1;
							D_CARD1:							// load dealer's first card	
								load_dcard1 <= 1;
							P_CARD2:							// load player's second card
								load_pcard2 <= 1;
							D_CARD2:							// load dealer's second card
								load_dcard2 <= 1;
							P_CARD3:							// load player's third card	
								load_pcard3 <= 1;
							D_CARD3:							// load dealer's third card
								load_dcard3 <= 1;
							SCORE:							// evaluate score
								begin
									
									if (pscore > dscore)			// if player wins, 
										begin
											player_win_light <= 1;	// player light on
											result <= 2'b01;
										end
									else if (pscore < dscore)	// if dealer wins,
										begin
											dealer_win_light <= 1;	// dealer light on
											result <= 2'b10;
										end
									else								// otherwise, tie
										begin
											player_win_light <= 1;	// dealer and player lights on
											dealer_win_light <= 1;
											result <= 2'b11;
										end
								end
							default:							// no cards, lights on other cases
								begin
									load_pcard1 <= 0;
									load_pcard2 <= 0;
									load_pcard3 <= 0;
									
									load_dcard1 <= 0;
									load_dcard2 <= 0;
									load_dcard3 <= 0;
									
									player_win_light <= 0;
									dealer_win_light <= 0;
								end
						endcase
				end
			
		end
			
endmodule