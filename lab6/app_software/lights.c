#define switches (volatile char *) 0x0002020 
#define leds (char *) 0x0002010
#define sevenSegs (char *) 0x0002000

void main()
{ 
   while (1) {
      *leds = *switches;

      char output[8];
      int carry = 0;
      int i;
      for (i = 0; i < 4; i++) {
         output[i] = (*(switches + i) + *(switches + i + 4) + carry) % 2;
	 carry = (*(switches + i) + *(switches + i + 4) + carry) / 2;
      }
      output[5] = carry;

      *sevenSegs = output;
   }
}
