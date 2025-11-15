/* ################################################################################
| patch to initialize the 68060 PCR immediately after boot, replacing normal entry */
ROMEntryNew:
    clr.l %d0                       | disable superscalar (bit0=0)

#ifdef DISABLE_FPU
    bset #1, %d0                    | disable FPU (bit1=1)
#endif

#ifdef DISABLE_LOADSTOREBYPASS
    bset #5, %d0                    | I14, documented in 060 errata document
#endif

    movec %d0, %pcr                 | NOTE: this will prevent an 040 from booting at all! 
    jmp ROMEntryOrig                | back to original entry

/* ################################################################################
| InstallFPSP replacement.
| runs much later after VBR is in RAM, and after SysErrInit blows away our unimplemented integer handler 
| so install vectors again*/

PatchInstallSP:
    movem.l  %d0/%a0-%a1, -(%sp)

    INIT_SERIAL
    PUT_STRING "\nHello!\nPatchInstallSP\n"

    movec.l %VBR, %a0
    
#ifdef INSTALL_ISP
    lea _060_isp_unimp, %a1
    move.l %a1, VECI_UNIMP_II(%a0)
#endif

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

    /* BSUN vector is not used on 060, it's handled in fline */
#endif

    movem.l  (%sp)+,%d0/%a0-%a1
    rts

/* ################################################################################
| Do any late boot initialization. Replaces SetupDockBase since we're never gonna have a dock 
| OK to trash D0-D2, A0-A1 */
LateInit:
    PUT_STRING "LateInit\n"

#ifdef ENABLE_SUPERSCALAR
    movec %pcr, %d0                 | turn on superscalar after timedbra has run
    bset #0, %d0                    | enable superscalar (bit0=1)
    movec %d0, %pcr     
#endif

#ifdef ENABLE_BRANCH_CACHE    
    jsr TurnOnBC                    | turn on branch cache. we can patch the vector table and have it stick
                                    | and slot manager is done messing with bus error vector too.
#endif

    rts

/* ################################################################################
| Initialize caches. replaces 040-centric ENABLECACHESPATCH / part of StartInit
| OK to thrash D0. */
Initialize060Caches:
    clr.l %d0
    bset #CACR060_EDC, %d0          | enable data cache
    bset #CACR060_EIC, %d0          | enable instruction cache

#ifdef ENABLE_LOADSTORE_FIFO
    bset #CACR060_ESB, %d0          | enable loadstore FIFO (distinct from the bypass errata)
#endif

#ifdef CPUSH_NO_INVALIDATE
    bset #CACR060_DPI, %d0          | cpush doesn't invalidate lines, could help performance
#endif

    movec %d0, %cacr                | ...and make it live
    rts  

/* ################################################################################
| Because we have known issues with 32 bit mode, we can patch validatePRAM to come here
| we'll always force the XPRAM to 32 bit mode before anything else happens (such as MM init). */  
ValidatePRAM_Patch:
    MOVE.L  %sp, %a3                | temporary buffer on the stack already from VALIDATEPRAM 
    move.b  #MMFlagsDefault, (%a3)  | default value into buffer
    MOVE.L  #MMFlags_Write, %D3		| write 1 byte into mmflags (See defs.s)
	JSR		PRAMIO                  | do the write. trashes A3, D3
    LEA		256(%SP),%SP            | continue patched code, release the buffer
    move.l  (%sp)+,%d3              | and restore D3
    rts    

/* ################################################################################
| install a new bus error (Access error) handler that deals with branch prediction error correctly */
.global TurnOnBC
TurnOnBC:
    movem.l %d0/%a0-%a1, -(%sp)

    PUT_STRING "TurnOnBC\n"

    movec.l %VBR, %a0
    lea New_AccessFault, %a1
    move.l %a1, VECI_ACCERR(%a0)

    movec %cacr, %d0                | get current CACR
    bset #CACR060_EBC, %d0          | enable branch prediction cache
    bset #CACR060_CABC, %d0         | and clear it
    movec %d0, %cacr

    movem.l  (%sp)+,%d0/%a0-%a1
    rts

/* ################################################################################
| VBL patch for shenanigans (debug)
| do not trash any registers!! */
DebugVBLPatch:

    /* patched code from DoVBLTask, do not move */
	.long 0x52A9000A	| +A334     addq.l	#1,slotTickCount-slotVBLQHdr(A1)	; increment slot tickcount
	.long 0xB3F80D10	| +A338     cmpa.l	ScrnVBLPtr,a1		; is it the main screen?
    rts

/* ################################################################################
| new access fault handler. Must check for BPE bit and clear branch cache if set, 
| then either return if no further error or proceed to normal bus error handler 
| NOTE: not yet verified as don't seem to be hitting BPEs */
New_AccessFault:	
	PUT_STRING "BERR\n"
    
    BTST	#2,(12+3,%SP)		    | BPE ?
	BNE.B	BranchPredictionError

    PUT_STRING "Sendit\n"
    jmp GENEXCPS_BusError           | hand off to Deepshit BusError

BranchPredictionError:
    move.l %d0, -(%sp)
    PUT_STRING "BPE\n"              | DEBUG note we hit a BPE
	
    movec %cacr, %d0
    bset #CACR060_CABC, %d0 
    movec %d0, %cacr
	nop
    move.l (%sp)+,%d0
    RTE  

/* ################################################################################
| Include additional code chunks as needed */
#ifdef INSTALL_ISP
    #include "isp-memacc.S"
    #include "isp-callouts.S"
#endif

#ifdef INSTALL_FPSP
    #include "fpsp-callouts.S"
#endif

#ifdef ENABLE_SERIAL_DEBUG
    #include "serial.S"
#endif