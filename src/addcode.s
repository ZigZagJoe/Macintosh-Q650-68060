/* patch to disable the FPU at early boot */
myRomEntry:
    moveq.l #2,%d0      | disable FPU (bit 1 = 1)
    movec %d0, %pcr     | NOTE: this will prevent an 040 from booting at all! 
    jmp INITIAL_PC      | back to original entry

/* runs much later after VBR is in RAM, and after SysErrInit blows away our unimplemented integer handler 
so install vectors again here. Called from InstallFPSP */
PatchInstallSP:
    movem.l  %d0/%a0-%a1, -(%sp)

    movec.l %VBR, %a0
    lea _060_isp_unimp, %a1
    move.l %a1, VECI_UNIMP_II(%a0)

#ifdef INSTALL_FPSP
    lea _060_fpsp_inex, %a1
    move.l %a1, VECI_FP_INEX(%a0)

    lea _060_fpsp_dz, %a1
    move.l %a1, VECI_FP_DZ(%a0)

    lea _060_fpsp_unfl, %a1
    move.l %a1, VECI_FP_UNFL(%a0)

    lea _060_fpsp_operr, %a1
    move.l %a1, VECI_FP_OPERR(%a0)
    
    lea _060_fpsp_ovfl, %a1
    move.l %a1, VECI_FP_OVFL(%a0)
    
    lea _060_fpsp_snan, %a1
    move.l %a1, VECI_FP_SNAN(%a0)
    
    lea _060_fpsp_unsupp, %a1
    move.l %a1, VECI_UNIMP_FP_DATA(%a0)
    
    lea _060_fpsp_effadd, %a1
    move.l %a1, VECI_UNIMP_EA(%a0)
    
    lea _060_fpsp_fline, %a1
    move.l %a1, VECI_LINE1111(%a0)

    /* BSUN vector is not used on 060 - handled in fline */
#endif

    movec %pcr, %d0 

#ifdef INSTALL_FPSP    
    bclr #1, %d0        | clear FPU disable bit (bit=0)
#else
    bset #1, %d0        | set FPU disable bit (bit=1)
#endif
#ifdef ENABLE_SUPERSCALAR
    bset #0, %d0        | enable superscalar (bit=1)
#else
    bclr #0, %d0        | disable superscalar (bit=0)
#endif

    movec %d0, %pcr     

    movem.l  (%sp)+,%d0/%a0-%a1
    rts

/* OK to thrash D0. replaces ENABLECACHESPATCH / part of StartInit*/
Initialize060Caches:
    
    clr.l %d0
    bset #CACR060_EDC, %d0
    bset #CACR060_EIC, %d0

#ifdef ENABLE_LOADSTORE_FIFO
    bset #CACR060_ESB, %d0 
#endif

    movec %d0, %cacr

    rts  

/* Because we have known issues with 32 bit mode, we can patch INITMMU to come here
we'll always force the PRAM to 32 bit mode before anything else inits. */  
Force32PRAM:
    move.l  %a1, -(%sp)             | preserve %a1, thrashed by writexpram

    MOVE.L	#0x25252525, -(%SP)     | MMFlagsDefault repeated across all bytes on stack
    MOVE.L	%sp,%A0	                | address of data to write
    MOVE.L	#MMPRAMloc,%D0			| address in pram to write
    jsr WRITEXPRAM 					| do it
    move.L (%sp)+,%d0 
    move.l  (%sp)+, %a1
    
    rts                             | return MMUFlags in %D0

/* experimental function to install a new access error handler that deals with branch prediction error correctly
see amiga code for reference, based on that 
doesn't seem to work (Branch cache still crashes)*/
.global TurnOnBC
TurnOnBC:
    movem.l %d0/%a0-%a1, -(%sp)

    movec.l %VBR, %a0

    lea New_AccessFault, %a1
    /*move.l VECI_ACCERR(%a0), %d0
    cmp.l %a1, %d0              
    beq AlreadyInstalled        | already installed, don't overwrite the old handler

    move.l VECI_ACCERR(%a0), (Old_AccessFault).W*/
    move.l %a1, VECI_ACCERR(%a0)

AlreadyInstalled:
    movec %cacr, %d0            | set up the CACR for 060 added featuresget
    bset #CACR060_EBC, %d0      | enable
    bset #CACR060_CABC, %d0     | and clear all
    movec %d0, %cacr
    
    movem.l  (%sp)+,%d0/%a0-%a1

    rts

/* borrowed wholesale from amiga */
New_AccessFault:	
	/*BTST	#2,(12+3,%SP)		| BPE ?
	BNE.B	BranchPredictionError
	|MOVE.L	(Old_AccessFault).w,-(%sp)
    MOVE.L	(GENEXCPS),-(%sp) | call to Deepshit bus error handler
    
	RTS                         | continue in original handler

BranchPredictionError:*/
	move.l %d0, -(%sp)

    movec %cacr, %d0
    bset #CACR060_CABC, %d0 
    movec %d0, %cacr
	
	move.l (%sp)+,%d0
    RTE  
