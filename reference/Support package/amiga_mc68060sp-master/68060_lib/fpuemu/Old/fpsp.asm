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
**------------------------------------------------------------------------------------------------------
	NOLIST

	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i
	include	exec/nodes.i
	include	exec/resident.i

**------------------------------------------------------------------------------------------------------

	include          fpsp_debug.i
MYDEBUG	SET         	0	; Current Debug Level
DEBUG_DETAIL 	set 	10	; Detail Level

ICMP	macro		; Simplefy things.
	cmp.\0 \2,\1
	endm

**------------------------------------------------------------------------------------------------------

	LIST
_custom	equ	$dff000

	include	fpsp.i	; move stuff to header
	include	AmigaFPSP_rev.i	; move stuff to header

**------------------------------------------------------------------------------------------------------
	MACHINE	MC68060	; Destination CPU
	OPT	0

                        Section          Init,code
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------

                        IFD	TESTCODE
	XDEF	FooBar
FooBar:	DBUG	10,"AmigaFPSP started from shell\n"
                        bsr              FPSP060_Code
                        move.l	4.w,a6
	moveq	#0,d0
	jsr	_LVOWait(a6)	; Wait forever
	nop
	rts
	ENDC

**------------------------------------------------------------------------------------------------------

	XDEF FPSP060_Start
FPSP060_Start:	ILLEGAL
	dc.l             FPSP060_Start
	dc.l	FPSP060_End
	dc.b	RTF_COLDSTART			; This is a coldstart resident
	dc.b	VERSION                             	; Version
	dc.b             NT_UNKNOWN			; Type
	dc.b	115			; Do patches right before diag.init
	dc.l	FPSP060_Name
	dc.l	FPSP060_Info
	dc.l	FPSP060_Code
FPSP060_Name:	dc.b	'AmigaFPSP',0			; name
FPSP060_Info:	dc.b	'MC68060 '		   	; give some info
	VERS
	dc.b	'('
                        DATE
	dc.b	') ©1997 by Carsten Schlote,'
	dc.b	' Coenobium Developments\r\n',0
                        even                                          		; align code

**------------------------------------------------------------------------------------------------------

	XDEF	_Install_AmigaFPSP
_Install_AmigaFPSP:
FPSP060_Code:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	(FPS060_SuperCode,PC),A5
	MOVEA.L	(4).W,A6
	JSR	(_LVOSupervisor,A6)
	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVEQ	#0,D0
	RTS

; --------------------------------------------------------------


FPS060_SuperCode:
	ORI.W	#$0700,SR
	MOVEC	VBR,A2
	SETVECTOR	_060_fpsp_snan,54              ; _FPUExceptionHandler_SNAN
	SETVECTOR	_060_fpsp_operr,52             ; _FPUExceptionHandler_OpError
	SETVECTOR	_060_fpsp_ovfl,53              ; _FPUExceptionHandler_Overflow
	SETVECTOR	_060_fpsp_unfl,51              ; _FPUExceptionHandler_Underflow
	SETVECTOR	_060_fpsp_dz,50                ; _FPUExceptionHandler_DivByZero
	SETVECTOR	_060_fpsp_inex,49              ; _FPUExceptionHandler_InexactResult
	SETVECTOR	_060_real_bsun,48

	SETVECTOR	_060_fpsp_fline,11             ; _ExceptionHandler_UnimplFPUInst
	SETVECTOR	_060_fpsp_unsupp,55            ; _FPUExceptionHandler_UnimplDType
	SETVECTOR	_060_fpsp_effadd,60            ; _Unimplemented Eff Addr
	CPUSHA	DC
	RTE

* 48 ?? _FPUExceptionHandler_UnorderedCond

Vector_11:	dc.l	0	; In USE !

Vector_48:	dc.l	0
Vector_49:	dc.l	0
Vector_50:	dc.l	0
Vector_51:	dc.l	0
Vector_52:	dc.l	0
Vector_53:	dc.l	0
Vector_54:	dc.l	0

Vector_55:	dc.l	0

Vector_60:	dc.l	0

**------------------------------------------------------------------------------------------------------

*****************************************************************************
* CONSTANTS *
*****************************************************************************
*
*T1:	dc.l	$40C62D38,$D3D64634	* 16381 LOG2 LEAD
*T2:	dc.l	$3D6F90AE,$B1E75CC7	* 16381 LOG2 TRAIL
*
*PI:	dc.l	$40000000,$C90FDAA2,$2168C235,$00000000
*PIBY2:	dc.l	$3FFF0000,$C90FDAA2,$2168C235,$00000000

*TWOBYPI:
*	dc.l	$3FE45F30,$6DC9C883



*--------------------------------------------------------
*
* Each IO routine checks to see if the memory write/read is to/from user
* or supervisor application space. The examples below use simple "move"
* instructions for supervisor mode applications and call _copyin()/_copyout()
* for user mode applications.
* When installing the 060SP, the _copyin()/_copyout() equivalents for a
* given operating system should be substituted.
*
* The addresses within the 060SP are guaranteed to be on the stack.
* The result is that Unix processes are allowed to sleep as a consequence
* of a page fault during a _copyout.
*

*----------------------------------------------------------------------
*
* _060_dmem_write():
*
* Writes to data memory while in supervisor mode.
*
* INPUTS:
*	a0 - supervisor source address
*	a1 - user destination address
*	d0 - number of bytes to write
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d1 - 0 = success, !0 = failure
*
	XDEF	_060_dmem_write
_060_dmem_write:
	MOVE.L	A6,-(SP)
	MOVEA.L	(4).W,A6
	JSR	(_LVOCopyMem,A6)
	MOVEA.L	(SP)+,A6
	MOVEQ	#0,D1
	RTS
*----------------------------------------------------------------------
*
* _060_imem_read(), _060_dmem_read():
*
* Reads from data/instruction memory while in supervisor mode.
*
* INPUTS:
*	a0 - user source address
*	a1 - supervisor destination address
*	d0 - number of bytes to read
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d1 - 0 = success, !0 = failure
*
_060_imem_read:
_060_dmem_read:
	MOVE.L	A6,-(SP)
	MOVEA.L	(4).W,A6
	JSR	(_LVOCopyMem,A6)
	MOVEA.L	(SP)+,A6
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_read_byte():
*
* Read a data byte from user memory.
*
* INPUTS:
*	a0 - user source address
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d0 - data byte in d0
*	d1 - 0 = success, !0 = failure
*
_060_dmem_read_byte:
	MOVEQ	#0,D0
	MOVE.B	(A0),D0
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_read_word():
*
* Read a data word from user memory.
*
* INPUTS:
*	a0 - user source address
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d0 - data word in d0
*	d1 - 0 = success, !0 = failure
*
_060_dmem_read_word:
	MOVEQ	#0,D0
	MOVE.W	(A0),D0
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_read_long():
*

*
* INPUTS:
*	a0 - user source address
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d0 - data longword in d0
*	d1 - 0 = success, !0 = failure
*
_060_dmem_read_long:
	MOVE.L	(A0),D0
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_write_byte():
*
* Write a data byte to user memory.
*
* INPUTS:
*	a0 - user destination address
* 	d0 - data byte in d0
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d1 - 0 = success, !0 = failure
*
_060_dmem_write_byte:
	MOVE.B	D0,(A0)
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_write_word():
*
* Write a data word to user memory.
*
* INPUTS:
*	a0 - user destination address
* 	d0 - data word in d0
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d1 - 0 = success, !0 = failure
*
_060_dmem_write_word:
	MOVE.W	D0,(A0)
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_dmem_write_long():
*
* Write a data longword to user memory.
*
* INPUTS:
*	a0 - user destination address
* 	d0 - data longword in d0
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d1 - 0 = success, !0 = failure
*
_060_dmem_write_long:
	MOVE.L	D0,(A0)
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_imem_read_word():
*
* Read an instruction word from user memory.
*
* INPUTS:
*	a0 - user source address
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d0 - instruction word in d0
*	d1 - 0 = success, !0 = failure
*
_060_imem_read_word:
	MOVE.W	(A0),D0
	MOVEQ	#0,D1
	RTS

*----------------------------------------------------------------------
*
* _060_imem_read_long():
*
* Read an instruction longword from user memory.
*
* INPUTS:
*	a0 - user source address
* 	0x4(%a6),bit5 - 1 = supervisor mode, 0 = user mode
* OUTPUTS:
*	d0 - instruction longword in d0
*	d1 - 0 = success, !0 = failure
*
_060_imem_read_long:
	MOVE.L	(A0),D0
	MOVEQ	#0,D1
	RTS


*----------------------------------------------------------------------
*
* _060_real_trace():
*
* This is the exit point for the 060FPSP when an instruction is being traced
* and there are no other higher priority exceptions pending for this instruction
* or they have already been processed.
*
* The sample code below simply executes an "rte".
*
_060_real_trace:
                        MOVEM.L	a0/a1,-(SP)	* Save two regs
                        movec.l	VBR,A0                 * Now get VBR
                        move.l	(9*4,a0),4(sp)         * Get TRACE Handler to stack
                        MOVEM.L          (sp)+,a0	* Get back only A0
 	rts                                     * rts to Handler :-)
*	RTE


*----------------------------------------------------------------------
*
* _060_real_access():
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
_060_real_access:
                        MOVEM.L	a0/a1,-(SP)	* Save two regs
                        movec.l	VBR,A0                 * Now get VBR
                        move.l	(2*4,a0),4(sp)         * Get TRACE Handler to stack
                        MOVEM.L          (sp)+,a0	* Get back only A0
 	rts                                     * rts to Handler :-)
*	RTE

; --------------------------------------------------------------
;  Emulation follows
; --------------------------------------------------------------
;
; _060_fpsp_done():
;
; This is the main exit point for the 68060 Floating-Point
; Software Package. For a normal exit, all 060FPSP routines call this
; routine. The operating system can do system dependent clean-up or
; simply execute an "rte" as with the sample code below.
;

_060_fpsp_done:
	RTE

; --------------------------------------------------------------
;
; _060_real_ovfl():
;
; This is the exit point for the 060FPSP when an enabled overflow exception
; is present. The routine below should point to the operating system handler
; for enabled overflow conditions. The exception stack frame is an overflow
; stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;

_060_real_ovfl:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_unfl():
;
; This is the exit point for the 060FPSP when an enabled underflow exception
; is present. The routine below should point to the operating system handler
; for enabled underflow conditions. The exception stack frame is an underflow
; stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
;
; The sample routine below simply clears the exception status bit and
; does an "rte".
;
_060_real_unfl:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_operr():
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
_060_real_operr:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_snan():
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
_060_real_snan:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_dz():
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
_060_real_dz:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_inex():
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
_060_real_inex:	FSAVE	-(SP)
	MOVE.W	#$6000,(2,SP)
	FRESTORE	(SP)+
	RTE

; --------------------------------------------------------------
;
; _060_real_bsun():
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
_060_real_bsun:	FSAVE	-(SP)
	FMOVE.L	FPSR,-(SP)
	ANDI.B	#$FE,(SP)
	FMOVE.L	(SP)+,FPSR
	ADDA.L	#12,SP
	RTE

; --------------------------------------------------------------
;
; _060_real_fline():
;
; This is the exit point for the 060FPSP when an F-Line Illegal exception is
; encountered. Three different types of exceptions can enter the F-Line exception
; vector number 11: FP Unimplemented Instructions, FP implemented instructions when
; the FPU is disabled, and F-Line Illegal instructions. The 060FPSP module
; _fpsp_fline() distinguishes between the three and acts appropriately. F-Line
; Illegals branch here.
;
_060_real_fline:	MOVE.L	(Vector_11,PC),-(SP)
	RTS

; --------------------------------------------------------------
;
; _060_real_fpu_disabled():
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
_060_real_fpu_disabled:
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
; _060_real_trap():
;
; This is the exit point for the 060FPSP when an emulated "ftrapcc" instruction
; discovers that the trap condition is true and it should branch to the operating
; system handler for the trap exception vector number 7.
;
; The sample code below simply executes an "rte".
;
_060_real_trap:
                        MOVEM.L	a0/a1,-(SP)	* Save two regs
                        movec.l	VBR,A0                 * Now get VBR
                        move.l	(7*4,a0),4(sp)         * Get TRACE Handler to stack
                        MOVEM.L          (sp)+,a0	* Get back only A0
 	rts                                     * rts to Handler :-)
*	RTE


; --------------------------------------------------------------

_060_fpsp_snan:         CALL_IN	_fpsp,0,"_060_fpsp_snan:        (SP: %08lx %08lx)\n"
_060_fpsp_operr:        CALL_IN	_fpsp,1,"_060_fpsp_operr:       (SP: %08lx %08lx)\n"
_060_fpsp_ovfl:         CALL_IN	_fpsp,2,"_060_fpsp_ovfl:        (SP: %08lx %08lx)\n"
_060_fpsp_unfl:         CALL_IN	_fpsp,3,"_060_fpsp_unfl:        (SP: %08lx %08lx)\n"
_060_fpsp_dz:           CALL_IN	_fpsp,4,"_060_fpsp_dz:          (SP: %08lx %08lx)\n"
_060_fpsp_inex:         CALL_IN	_fpsp,5,"_060_fpsp_inex:        (SP: %08lx %08lx)\n"
_060_fpsp_fline:        CALL_IN	_fpsp,6,"_060_fpsp_fline:       (SP: %08lx %08lx)\n"
_060_fpsp_unsupp:       CALL_IN	_fpsp,7,"_060_fpsp_unsupp:      (SP: %08lx %08lx)\n"
_060_fpsp_effadd:       CALL_IN	_fpsp,8,"_060_fpsp_effadd:      (SP: %08lx %08lx)\n"

; --------------------------------------------------------------

****  This is the list of Callouts !
****
****
****
	cnop	14,16
	nop

_FP_CALL_TOP:
	dc.l	_060_real_bsun	- _FP_CALL_TOP
	dc.l	_060_real_snan	- _FP_CALL_TOP
	dc.l	_060_real_operr	- _FP_CALL_TOP
	dc.l	_060_real_ovfl	- _FP_CALL_TOP
	dc.l	_060_real_unfl	- _FP_CALL_TOP
	dc.l	_060_real_dz	- _FP_CALL_TOP
	dc.l	_060_real_inex	- _FP_CALL_TOP
	dc.l	_060_real_fline	- _FP_CALL_TOP
	dc.l	_060_real_fpu_disabled	- _FP_CALL_TOP
	dc.l	_060_real_trap	- _FP_CALL_TOP
	dc.l	_060_real_trace	- _FP_CALL_TOP
	dc.l	_060_real_access	- _FP_CALL_TOP
	dc.l	_060_fpsp_done	- _FP_CALL_TOP
	dcb.l	3,0

	dc.l	_060_imem_read	- _FP_CALL_TOP
	dc.l	_060_dmem_read	- _FP_CALL_TOP
	dc.l	_060_dmem_write	- _FP_CALL_TOP
	dc.l	_060_imem_read_word	- _FP_CALL_TOP
	dc.l	_060_imem_read_long	- _FP_CALL_TOP
	dc.l	_060_dmem_read_byte	- _FP_CALL_TOP
	dc.l	_060_dmem_read_word	- _FP_CALL_TOP
	dc.l	_060_dmem_read_long	- _FP_CALL_TOP
	dc.l	_060_dmem_write_byte	- _FP_CALL_TOP
	dc.l	_060_dmem_write_word	- _FP_CALL_TOP
	dc.l	_060_dmem_write_long	- _FP_CALL_TOP
	dcb.l	5,0

_060FPSP_TABLE:
_fpsp:	include     "fpsp.sa"

FPSP060_End
	end
