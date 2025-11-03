myRomEntry:
    | will prevent an 040 from booting at all!
    moveq #3,%d0
    movec %d0, %pcr     | disable FPU (bit 1 = 1) and superscalar execution (bit 0 = 0)
    jmp INITIAL_PC      | back to original entry

#include "serial.S"

SerialTest:
    
	bra InitSCC
mainloop:

	put_char 'H'
	put_char 'e'
	put_char 'l'
	put_char 'l'
	put_char 'o'

    bra  mainloop

