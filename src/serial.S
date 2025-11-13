||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| Serial debug tooling
| steal the modem SCC and use it for debug strings!

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| addresses for wombat
.set ADDR_SCC,   0x50F0C020     | SCC read/write
.set ADDR_VIA1,  0x50F00000     | VIA1

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| SCC regs
| modem -> channel A
.set aData, 6 + ADDR_SCC        | offset for A channel data
.set aCtl, 2 + ADDR_SCC         | offset for A channel control
.set bData,4 + ADDR_SCC         | offset for B channel data
.set bCtl, 0 + ADDR_SCC         | offset for B channel control
.set sccData, 4 + ADDR_SCC      | general offset for data from control
.set rxBF, 0 + ADDR_SCC         | SCC receive buffer full
.set txBE, 2 + ADDR_SCC         | SCC transmit buffer empty
.set RxCA, 0 + ADDR_SCC         | Receive Character Available

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| VIA regs
.set vBufB, 0                   | BUFFER B
.set vBufAH, 0x200              | buffer a (with handshake) [ Dont use! ]
.set vDirB, 0x400               | DIRECTION B
.set vDirA, 0x600               | DIRECTION A
.set vT1C, 0x800                | TIMER 1 COUNTER (L.O.)
.set vT1CH, 0xA00               | timer 1 counter (high order)
.set vT1L, 0xC00                | TIMER 1 LATCH (L.O.)
.set vT1LH, 0xE00               | timer 1 latch (high order)
.set vT2C, 0x1000               | TIMER 2 LATCH (L.O.)
.set vT2CH, 0x1200              | timer 2 counter (high order)
.set vSR, 0x1400                | SHIFT REGISTER
.set vACR, 0x1600               | AUX. CONTROL REG.
.set vPCR, 0x1800               | PERIPH. CONTROL REG.
.set vIFR, 0x1A00               | INT. FLAG REG.
.set vIER, 0x1C00               | INT. ENABLE REG.
.set vBufA, 0x1E00              | BUFFER A

.set vSync, 3 				    | Synchronous modem bit in via2

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| setup SCC on modem port, preserve registers
InitSerialFunc:
    movem.l  %d0/%a0-%a1,-(%sp)
    tst.b (ADDR_SCC)              |sync up accept address byte

    lea PortSetUp, %a1            |point at set up table
	
1: 
    move.b (%a1)+, %d0            |get SCC register to access
    bmi.s  2f                     |done with init
    move.b %d0, (aCtl)            |select SCC register      
    move.b (%a1)+, (aCtl)         |write data to SCC register    
    bra.s  1b                     |until done...
2: 

	| set the via for async operation
	move.l #ADDR_VIA1, %a0
	
    bset.b #vSync, vDirA(%a0)     |set the sync bit as an output 
	bclr.b #vSync, vBufA(%a0) 	  |clear the sync bit       
    
    movem.l  (%sp)+,%d0/%a0-%a1
    rts

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| SCC initialization table
PortSetUp:
	dc.b	0x09,0xC0			|reg  9, reset hardware
	dc.b	0x0F,0x00			|reg 15, disable interrupts
	dc.b	0x04,0x44			|reg  4, X16clk,8 bit,1 stop (original 2 stop 0x4C)
	dc.b	0x0B,0x50			|reg 11, rClk = tClk = BR gen
	dc.b	0x0E,0x00			|reg 14, disable BR gen
	dc.b	0x0D,0x00			|reg 13, high byte 9600 baud	
	dc.b	0x0C,0x0A			|reg 12, low  byte 9600 baud	
	dc.b	0x0E,0x01			|reg 14, enable BR gen
	dc.b	0x0A,0x00			|reg 10, NRZ
	dc.b	0x03,0xC1			|reg  3, Rx 8 bits, enabled
	dc.b	0x05,0xEA			|reg  5, Tx 8 bits, DTR/RTS	
	dc.b	0x01,0x00			|reg  1, Ext Sts interrupts disabled
	dc.b	0xFF,0xFF			|end of table


||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| put string in %a0    
_puts:
    movem.l %A0/%D0, -(%SP)

1:
    move.b (%A0)+, %D0
    jeq 3f
    
    bsr _putb
    bra 1b
3:
    movem.l (%SP)+,%A0/%D0
    rts

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| put hex long in %d0      
_puthexlong:
    move.l %D0, -(%SP)

    swap %D0
    jbsr _puthexword
    
    move.l (%SP), %D0
    jbsr _puthexword

    move.l (%SP)+, %D0
    rts
      
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| put hex word in %d0         
_puthexword:
    move.w %D0, -(%SP)

    lsr.w #8, %D0
    jbsr _puthexbyte
    
    move.w (%SP), %D0
    jbsr _puthexbyte

    move.w (%SP)+, %D0
    rts

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| put hex byte in %d0    
_puthexbyte:
    movem.l %A0/%D0, -(%SP)        | save regs
    
    lsr.b #4, %D0                  | shift top 4 bits over
    bsr.s _puthdigit
    
    move.w (2, %SP), %D0           | restore D0 from stack    
    bsr.s _puthdigit
    
    movem.l (%SP)+, %A0/%D0        | restore regs
    rts

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| put hex digit in %d0    
_puthdigit:
    lea (%pc,_hexchars), %A0
    and.w #0xF, %D0
    move.b (%A0, %D0.W), %D0       | look up char
    jbsr _putb
    rts

||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
| write byte in %d0 to serial
_putb:
    move.b	#0x30,(aCtl)	|reset any errors			
	move.b	%d0,(aData)	    |send character			

1:	move.w	#1, %d0			|wait until all sent status
	move.b	%d0,(aCtl)		|select RR1			
	
	btst	#0,(aCtl)		|All Sent?			
	beq.s	1b
    rts

_hexchars: .string "0123456789ABCDEF"
.align 2