/* ################################################################################
| StartTest patch.
| runs very early, just after some basic MMU setup and RESET */
PatchStartTest:
    clr.l %d0                       | disable superscalar (bit0=0)

#ifdef DISABLE_FPU
    bset #1, %d0                    | disable FPU (bit1=1)
#endif

#ifdef DISABLE_LOADSTOREBYPASS
    bset #5, %d0                    | I14, documented in 060 errata document
#endif

    movec %d0, %pcr                 | NOTE: this will prevent an 040 from booting at all! 

    # replaced code resumes here
	movea.w #0x2600,%sp
	moveq   #0,%d7
    bral PatchStartTest_return

/* ################################################################################
| InstallFPSP replacement.
| runs much later after VBR is in RAM, and after SysErrInit blows away our unimplemented integer handler 
| so install vectors again. OK to thrash A0, A1 */

PatchInstallSP:
    INIT_SERIAL
    PUT_STRING "\nHello!\nPatchInstallSP\n"

    movec.l %VBR, %a0
    
#ifdef INSTALL_ISP
    move.l #_060_isp_unimp, VECI_UNIMP_II(%a0)
#endif

#ifdef INSTALL_FPSP
    move.l #_060_fpsp_inex, VECI_FP_INEX(%a0)
    move.l #_060_fpsp_dz, VECI_FP_DZ(%a0)
    move.l #_060_fpsp_unfl, VECI_FP_UNFL(%a0)
    move.l #_060_fpsp_operr, VECI_FP_OPERR(%a0)
    move.l #_060_fpsp_ovfl, VECI_FP_OVFL(%a0)
    move.l #_060_fpsp_snan, VECI_FP_SNAN(%a0)
    move.l #_060_fpsp_unsupp, VECI_UNIMP_FP_DATA(%a0)
    move.l #_060_fpsp_effadd, VECI_UNIMP_EA(%a0)
    move.l #_060_fpsp_fline, VECI_LINE1111(%a0)
    /* BSUN vector is not used on 060, it's handled in fline */
#endif

    rts

/* ################################################################################
| Do any late boot initialization. Replaces SetupDockBase since we're never gonna have a dock 
| OK to trash D0-D2, A0-A1 */
LateInit:
    PUT_STRING "LateInit\n"

    movec %pcr, %d0                 

#ifdef ENABLE_SUPERSCALAR
    bset #0, %d0                    | turn on superscalar after timedbra has been run (bit0=1)
#endif

#ifdef LATE_ENABLE_FPU
    bclr #1, %d0                    | re-enable FPU, if FPU was disabled intentionally early in boot. might cause odd behavior in mac os without FPSP
#endif

    movec %d0, %pcr     


#ifdef ENABLE_BRANCH_CACHE    
    jsr TurnOnBC                    | turn on branch cache. (TODO bus error is changed by later code...)
#endif

#ifdef ENABLE_LATE_ADB_CACHE_HACK   
    movec %cacr, %d0                | get cacr...
    bset #CACR060_EDC, %d0          | enable data cache
    movec %d0, %cacr                | ...and make it live
#endif

    rts

/* ################################################################################
| Initialize caches. replaces 040-centric ENABLECACHESPATCH / part of StartInit
| OK to thrash D0. */
Initialize060Caches:
    clr.l %d0

    | ADB seems to get wedged at init with an 060 + L2 cache > 38mhz or so, so do data cache later to slow things down
#ifndef ENABLE_LATE_ADB_CACHE_HACK
    bset #CACR060_EDC, %d0          | enable data cache
#endif

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

SizeBanks_bankDisable:
    | perform similar initialization as we would have normally performed in SizeBanks
    | including the code we replaced to jump over here

	moveq	#0,%d0		            | clear total RAM size
	sub.l	%a3,%a3		            | initialize the "bank 8-15" information
	subq.l	#1,%a3		            | ... to an improbable bank config value
    movea.l	%a5,%a7		            | keep running copy in a7	
    add.l	#2*8,%a7		        | skip first two banks entries in memory table https://github.com/elliotnunn/supermario/blob/9dd3c4bef84df2ea30f5ec2c5e97b043e8267b3f/base/SuperMarioProj.1994-02-09/OS/UniversalTables.a#L5108

    jmp SizeBanks_Resume            | ... resume sizing in original ROM code

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
DebugVBLTask:

    /* patched code from DoVBLTask, do not move */
	.long 0x52A9000A	            | +A334     addq.l	#1,slotTickCount-slotVBLQHdr(A1)	; increment slot tickcount
	.long 0xB3F80D10	            | +A338     cmpa.l	ScrnVBLPtr,a1		; is it the main screen?
    rts

/* ################################################################################
| new access fault handler. Must check for BPE bit and clear branch cache if set, 
| then either return if no further error or proceed to normal bus error handler 
| NOTE: mac os is replacing bus error handler... so this really isn't working/tested */
New_AccessFault:	
	PUT_STRING "BERR\n"
    
    BTST	#2,(12+3,%SP)		    | BPE ?
	BNE.B	BranchPredictionError

    PUT_STRING "Sendit\n"
    bral GENEXCPS_BusError           | hand off to Deepshit BusError

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

#ifdef ENABLE_SERIAL_DEBUG
    #include "serial.S"
#endif
