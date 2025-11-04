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
*_custom	equ	$dff000

**------------------------------------------------------------------------------------------------------
	include          fpsp_debug.i
MYDEBUG	SET         	0		* Current Debug Level
DEBUG_DETAIL 	set 	10		* Detail Level
	LIST
**------------------------------------------------------------------------------------------------------

	include	fpsp_macros.i		* move stuff to header
	include	AmigaFPSP_rev.i		* move stuff to header

**------------------------------------------------------------------------------------------------------

	MACHINE	MC68060		; Destination CPU
	OPT             !
                SECTION         FPSP060,code
	NEAR	CODE

**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**- Test only code. Overinstalls and Wait for ever - use RUn to launch

	IFD	TESTCODE
	XDEF	FooBar
FooBar:	DBUG	10,"AmigaFPSP started from shell\n"
	bsr              FPSP060_Code
	move.l	4.w,a6
	moveq	#0,d0
	jsr	_LVOWait(a6)			; Wait forever
	nop
	rts
	ENDC

**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------

	XDEF 	FPSP060_Start
	XREF 	FPSP060_End

FPSP060_Start:	ILLEGAL
	dc.l             FPSP060_Start
	dc.l	FPSP060_End
	dc.b	RTF_COLDSTART			; This is a coldstart resident
	dc.b	VERSION                             	; Version
	dc.b             NT_UNKNOWN			; Type
	dc.b	115				; Do patches right before diag.init
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
                even                                   		; align code

**------------------------------------------------------------------------------------------------------
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

	**-------------------------------------------------------------------------------------
	XREF	_fpsp_snan		; This are the clueless entry points
	XREF	_fpsp_operr
	XREF	_fpsp_ovfl
	XREF	_fpsp_unfl
	XREF	_fpsp_dz
	XREF	_fpsp_inex
	XREF	_real_bsun

	XREF	_fpsp_fline
	XREF	_fpsp_unsupp
	XREF	_fpsp_effadd
FPS060_SuperCode:
	ORI.W	#$0700,SR
	MOVEC	VBR,A2
	SETVECTOR	_fpsp_snan,54              ; _FPUExceptionHandler_SNAN
	SETVECTOR	_fpsp_operr,52             ; _FPUExceptionHandler_OpError
	SETVECTOR	_fpsp_ovfl,53              ; _FPUExceptionHandler_Overflow
	SETVECTOR	_fpsp_unfl,51              ; _FPUExceptionHandler_Underflow
	SETVECTOR	_fpsp_dz,50                ; _FPUExceptionHandler_DivByZero
	SETVECTOR	_fpsp_inex,49              ; _FPUExceptionHandler_InexactResult
	SETVECTOR	_real_bsun,48	       ; _FPUExceptionHandler_UnorderedCond

	SETVECTOR	_fpsp_fline,11             ; _ExceptionHandler_UnimplFPUInst
	SETVECTOR	_fpsp_unsupp,55            ; _FPUExceptionHandler_UnimplDType
	SETVECTOR	_fpsp_effadd,60            ; _Unimplemented Eff Addr
	CPUSHA	DC
	NOP
	RTE

	**-------------------------------------------------------------------------------------
	**
	XDEF	Vector_11
	XDEF	Vector_48
	XDEF	Vector_49
	XDEF	Vector_50
	XDEF	Vector_51
	XDEF	Vector_52
	XDEF	Vector_53
	XDEF	Vector_54
	XDEF	Vector_55
	XDEF	Vector_60

Vector_11:	dc.l	0				; In USE !
Vector_48:	dc.l	0
Vector_49:	dc.l	0
Vector_50:	dc.l	0
Vector_51:	dc.l	0
Vector_52:	dc.l	0
Vector_53:	dc.l	0
Vector_54:	dc.l	0
Vector_55:	dc.l	0
Vector_60:	dc.l	0

	end
