| djMEMC Configuration Register initialization values
| +49C0
djConfigTable:          
#ifdef DRAM_TIMINGS_CUSTOM    
    .word TIMING_DJCONFIG
#else
	.word 0x0101        | 20
#endif
    .word 0x001A        | 25
	.word 0x00A3        | 33
    .word 0x02F4        | 40

| DRAM refresh cycle times assuming a 15.6µs refresh period	
| (Refresh = (MHz * 15.6 ) - 27). Fractional parts are rounded DOWN		<H25>
| +49CC
djRefreshTable:             
#ifdef DRAM_TIMINGS_CUSTOM
    .word TIMING_BIOSTIMEOUT
#else
	.word 0x011D        | 20
#endif
    .word 0x016B        | 25
	.word 0x01E7        | 33
    .word 0x0255        | 40

| BIOS Configuration Register initialization values	
| +49D0     BCLK_25 = 1 or not
BIOS_Config:           	
#ifdef DRAM_TIMINGS_CUSTOM
    .byte TIMING_BIOSCFG
#else
	.byte 1             
#endif
    .byte 1
    .byte 0
    .byte 0	

| BIOS watchdog timer timeout count-down value	
BIOS_Timeout:          
#ifdef DRAM_TIMINGS_CUSTOM
    .word TIMING_BIOSTIMEOUT
#else
	.word 0x0280        | 20
#endif
    .word 0x01E0        | 25
	.word 0x00D5        | 33
    .word 0x0000        | 40

| Table for determining whether or not to use "SpeedBump"ed Config values	
| +49DC	
MachineTbl:             
	.byte 0x00,0x42	    | +49DC
    .byte 0x01,0x52	    | +49DE bump
	.byte 0x00,0x40	    | +49E0
    .byte 0x00,0x42	    | +49E2
	.byte 0x01,0x44	    | +49E4 bump
    .byte 0x00,0x46	    | +49E6
	.byte 0x01,0x50	    | +49E8 bump
    .byte 0x01,0x54	    | +49EA bump
	.byte 0x01,0x56		| +49EC bump
SCSI96ANDRPUPATCH:      | ???? this offset is wrong in the listing
	.word 0x0000		| +49EE  end of MachineTbl
    
| Configuration register values for SpeedBumped machines (by clock speed)
| +49F0
BumpConfigTable:        
	.word 0x0101        | 20
    .word 0x001A        | 25
	.word 0x00FB        | 33
    .word 0x02FC        | 40