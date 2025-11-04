**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

* This file is derived from the isp.asm,v 1.0.1.4 1996/02/19 23:02:26
*
* Use PhxAss (AmiNet) to compile.
*
* ALL RIGHTS RESERVED BY CARSTEN SCHLOTE, COENOBIUM DEVELOPMENTS
*
**------------------------------------------------------------------------------------------------------
** Import System stuff - keep it inside this module !

	NOLIST

	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i
	include	exec/nodes.i
	include	exec/resident.i

**------------------------------------------------------------------------------------------------------

	include          fpsp_debug.i
MYDEBUG	SET         	0		* Current Debug Level
DEBUG_DETAIL 	set 	10		* Detail Level


**------------------------------------------------------------------------------------------------------

	include	fpsp_emu.i
	include	fpsp_macros.i
	LIST

	MACHINE	MC68060
                SECTION         FPSP060,code
	NEAR            CODE
	OPT 	!


*----------------------------------------------------------------------
*
* _real_trace():
*
* This is the exit point for the 060FPSP when an instruction is being traced
* and there are no other higher priority exceptions pending for this instruction
* or they have already been processed.
*
* The sample code below simply executes an "rte".
*
	XDEF	_real_trace
_real_trace:
	MOVEM.L	a0/a1,-(SP)	* Save two regs
	movec.l	VBR,A0          * Now get VBR
	move.l	(9*4,a0),4(sp)  * Get TRACE Handler to stack
	MOVEM.L	(sp)+,a0	* Get back only A0
 	rts                             * rts to Handler :-)
*	RTE


*----------------------------------------------------------------------
*
* _real_access():
*
* This is the exit point for the 060FPSP when an access error exception
* is encountered. The routine below should point to the operating system
* handler for access error exceptions. The exception stack frame is an
* 8-word access error frame.
*
* The sample routine below simply executes an "rte" instruction which
* is most likely the incorrect thing to do and could put the system
* into an infinite loop. @@@@@@@@@@@@@@@@@@ !!!!!!!!!!!
*
	XDEF 	_real_access
_real_access:
	MOVEM.L	a0/a1,-(SP)		* Save two regs
	movec.l	VBR,A0                 	* Now get VBR
	move.l	(2*4,a0),4(sp)         	* Get TRACE Handler to stack
	MOVEM.L         (sp)+,a0		* Get back only A0
 	rts                                     * rts to Handler :-)
*	RTE

; --------------------------------------------------------------
;  Emulation follows
; --------------------------------------------------------------
;
; _fpsp_done():
;
; This is the main exit point for the 68060 Floating-Point
; Software Package. For a normal exit, all 060FPSP routines call this
; routine. The operating system can do system dependent clean-up or
; simply execute an "rte" as with the sample code below.
;

	XDEF	_fpsp_done
_fpsp_done:
	RTE

; --------------------------------------------------------------
;
; _real_ovfl():
;
; This is the exit point for the 060FPSP when an enabled overflow exception
; is present. The routine below should point to the operating system handler
; for enabled overflow conditions. The exception stack frame is an overflow
; stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;

	XDEF	_real_ovfl
_real_ovfl:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_unfl():
;
; This is the exit point for the 060FPSP when an enabled underflow exception
; is present. The routine below should point to the operating system handler
; for enabled underflow conditions. The exception stack frame is an underflow
; stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
	XDEF	_real_unfl
_real_unfl:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_operr():
;
; This is the exit point for the 060FPSP when an enabled operand error exception
; is present. The routine below should point to the operating system handler
; for enabled operand error exceptions. The exception stack frame is an operand error
; stack frame. The FP state frame holds the source operand of the faulting
; instruction.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
	XDEF	_real_operr
_real_operr:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_snan():
;
; This is the exit point for the 060FPSP when an enabled signalling NaN exception
; is present. The routine below should point to the operating system handler
; for enabled signalling NaN exceptions. The exception stack frame is a signalling NaN
; stack frame. The FP state frame holds the source operand of the faulting
; instruction.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
	XDEF	_real_snan
_real_snan:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_dz():
;
; This is the exit point for the 060FPSP when an enabled divide-by-zero exception
; is present. The routine below should point to the operating system handler
; for enabled divide-by-zero exceptions. The exception stack frame is a divide-by-zero
; stack frame. The FP state frame holds the source operand of the faulting
; instruction.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
	XDEF	_real_dz
_real_dz:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_inex():
;
; This is the exit point for the 060FPSP when an enabled inexact exception
; is present. The routine below should point to the operating system handler
; for enabled inexact exceptions. The exception stack frame is an inexact
; stack frame. The FP state frame holds the source operand of the faulting
; instruction.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
	XDEF	_real_inex
_real_inex:
	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _real_bsun():
;
; This is the exit point for the 060FPSP when an enabled bsun exception
; is present. The routine below should point to the operating system handler
; for enabled bsun exceptions. The exception stack frame is a bsun
; stack frame.
;
; The sample routine below clears the exception status bit, clears the NaN
; bit in the FPSR, and does an "rte". The instruction that caused the
; bsun will now be re-executed but with the NaN FPSR bit cleared.
;
	XDEF	_real_bsun
_real_bsun:
	FSAVE	-(SP)
	FMOVE.L	FPSR,-(SP)
	ANDI.B	#$FE,(SP)
	FMOVE.L	(SP)+,FPSR
	ADDA.L	#12,SP
	RTE

; --------------------------------------------------------------
;
; _real_fline():
;
; This is the exit point for the 060FPSP when an F-Line Illegal exception is
; encountered. Three different types of exceptions can enter the F-Line exception
; vector number 11: FP Unimplemented Instructions, FP implemented instructions when
; the FPU is disabled, and F-Line Illegal instructions. The 060FPSP module
; _fpsp_fline() distinguishes between the three and acts appropriately. F-Line
; Illegals branch here.
;
	XREF	Vector_11
	XDEF	_real_fline
_real_fline:
	MOVE.L	(Vector_11,PC),-(SP)
	RTS

; --------------------------------------------------------------
;
; _real_fpu_disabled():
;
; This is the exit point for the 060FPSP when an FPU disabled exception is
; encountered. Three different types of exceptions can enter the F-Line exception
; vector number 11: FP Unimplemented Instructions, FP implemented instructions when
; the FPU is disabled, and F-Line Illegal instructions. The 060FPSP module
; _fpsp_fline() distinguishes between the three and acts appropriately. FPU disabled
; exceptions branch here.
;
; The sample code below enables the FPU, sets the PC field in the exception stack
; frame to the PC of the instruction causing the exception, and does an "rte".
; The execution of the instruction then proceeds with an enabled floating-point
; unit.
;
	XDEF 	_real_fpu_disabled
_real_fpu_disabled:
	DBUG	10,"*** fpu disabled exception.  Solution: Enable FPU.\n"
	MOVE.L	D0,-(SP)	; enable FPU
	MOVEC	PCR,D0
	BCLR	#1,D0
	MOVEC	D0,PCR
	MOVE.L	(SP)+,D0
	MOVE.L	(12,SP),(2,SP)	; set Current pc
	RTE

; --------------------------------------------------------------
;
; _real_trap():
;
; This is the exit point for the 060FPSP when an emulated "ftrapcc" instruction
; discovers that the trap condition is true and it should branch to the operating
; system handler for the trap exception vector number 7.
;
; The sample code below simply executes an "rte".
;
	XDEF	_real_trap
_real_trap:
	MOVEM.L	a0/a1,-(SP)	* Save two regs
	MOVEC.L	VBR,A0                 * Now get VBR
	MOVE.L	(7*4,a0),4(sp)         * Get TRACE Handler to stack
	MOVEM.L          (sp)+,a0	* Get back only A0
 	RTS                                     * rts to Handler :-)
*	RTE





