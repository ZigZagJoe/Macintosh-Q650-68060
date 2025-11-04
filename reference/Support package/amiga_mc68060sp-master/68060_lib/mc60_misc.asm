**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

	machine	68060
	near

	include	"mc60_system.i"
	include	"mc60_libbase.i"

	section          mmu_code,code
MYDEBUG	SET              0
DEBUG_DETAIL 	set              10

**-------------------------------------------------------------------------------

	XDEF	_GetVBR
_GetVBR:	MOVEC	VBR,D0
	DBUG	10,"VBR is set to %08lx\n",d0
	RTE


	XDEF	_SetVBR
_SetVBR:	DBUG	10,"VBR is set to %08lx\n",d0
	MOVEC	D0,VBR
	RTE

*-----------------------------------------------------------------------------

CACRB_ESB	= 29	;@@@@@@@@@@ Make a header
CACRB_CABC	= 22
CACRB_EBC	= 23
PCRB_ESS	= 0

	XDEF	_EnableCaches
_EnableCaches:
	ORI.W	#700,SR	; Stop all
	CPUSHA	BC	; Invalidate all Caches

	movec.l	VBR,a1                	; patch bpe grap
	move.l	2*4(a1),Old_AccessFault
	Lea	(New_AccessFault,pc),a0
 	move.l  	a0,2*4(a1)
 	move.l	a0,(2*4).w

	MOVEC	CACR,D0	; Get CACR from CPU
	BSET	#CACRB_CABC,D0	; Flush Branch Cache on set PCR !
	MOVEC	D0,CACR	; Now store it back to CACR
	BSET	#CACRB_ESB,D0	; Enable store buffer to optimize
	BSET	#CACRB_EBC,D0	; Enable Branch Pred. Cache
	MOVEC	D0,CACR	; Now store it back to CACR
	NOP		; Stall pipe

	MOVEC	PCR,D1	; Enable Superscalar Mode
	BSET	#PCRB_ESS,D1
	MOVEC	d1,PCR
	NOP		; Stall pipe - now things are
                                                                ; really set. go on and have fun...

	DBUG	10,"\t\tCache Regs set to: CACR=$%08lx, PCR=$%08lx\n",d0,d1
	RTE

; --------------------------------------------------------------------------

Old_AccessFault:	dc.l	0
New_AccessFault:	DBUG	5,"Exception AccessFault!!!\n"
	BTST	#2,(12+3,SP)		; BPE ?
	BNE.B	New_AccessFault_BranchPredictionError
	MOVE.L	(Old_AccessFault,PC),-(sp)
	RTS


New_AccessFault_BranchPredictionError:
	DBUG	5,"Flush Branch Cache\n"

	MOVE.L	D0,-(SP)
	CPUSHA	BC
	NOP
	MOVEC	CACR,D0
	bset	#CACRB_CABC,D0	; CABC
	MOVEC	D0,CACR
	NOP
	CPUSHA	BC
	NOP
	MOVE.L	(SP)+,D0
	RTE



*----------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------
*
* Flush Data Lines at (a0)-(16,a0)
*

**
**	XDEF	_FlushLines
**_FlushLines:
**	MOVEM.L	A5/A6,-(SP)
**	LEA	(FlushMMU_Trap,PC),A5
**	MOVEA.L	(mc60_SysBase,A6),A6
**	JSR	(_LVOSupervisor,A6)
**	MOVEM.L	(SP)+,A5/A6
**	RTS
**
**FlushMMU_Trap:	CPUSHL	DC,(A0)
**	LEA	($0010,A0),A0
**	CPUSHL	DC,(A0)
**	PFLUSHA		;Invalidate ATCs
**	RTE
**
**





**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
** following code ripped from 68040.library
**
**
** Load CPU Ctrl Regs with MMU Parameters.

TTDISABLE	MACRO
	movec.l          \1,\2
	bclr.l	#15,\2
	movec.l	\2,\1
	ENDM

	XREF	_MMUFrame
	XDEF	_SetMMUTables

_SetMMUTables:
	MOVEM.L          d0-d7/a0-a6,-(sp)
	MOVE.L	(_MMUFrame,pc),a0
	DBUG	10,'\t\tURP: %08lx,SRP: %08lx,TCR: %08lx\n',(a0),4(a0),8(a0)

	ORI.W	#$0700,SR	; Stop IRqs
	PFLUSHA                                 ;
	CPUSHA           BC
	MOVE.L	(A0)+,D0
	MOVEC	D0,URP	;SetUserRootPtr
	NOP
	MOVE.L	(A0)+,D0
	MOVEC	D0,SRP	;Set RootPtr
                        NOP
	MOVE.L	(A0)+,D0	;set Translation Ctrl Reg - go !
	MOVEC	D0,TC
                        NOP
 	PFLUSHA		;MC68040

	TTDISABLE	ITT0,d0                ;Disable all transparent translation
	TTDISABLE	ITT1,d1
	TTDISABLE	DTT0,d2
	TTDISABLE	DTT1,d3
	DBUG	10,'\t\tITT0: %08lx,ITT1: %08lx,DTT0: %08lx, DTT0: %08lx\n',d0,d1,d2,d3

	MOVEM.L          (sp)+,d0-d7/a0-a6
	RTE



**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
** following code ripped from 68040.library

	XDEF	_CheckMMU
_CheckMMU:	DBUG	10,'\t\tInstall Data Translation : '

	MOVEC	DTT1,D1	;transparent data set to nocache, precise
	AND.B	#$9F,D1
	OR.B	#$40,D1
	DBUG	10," DTT1=$%08lx",d1
	MOVEC	D1,DTT1

	MOVEQ	#0,D0	;rc = FALSE
	ORI.W	#$0700,SR	;stop any irq

	MOVEC	TC,D1	;mmu paging on ?
	TST.W	D1
	DBUG	10," TCR=%$%08lx\n",d1
	BMI.B	.is_set

	BSET	#15,D1	;set mmu paging
	MOVEC	D1,TC
	MOVEC	TC,D1	;set & readback
	MOVEC	D0,TC	;no mmu paging!
	TST.W	D1	;was paging set ?
	BPL.B	.no_MMU

.is_set:	AND.W	#$F000,D1
	MOVE.L	D1,D0

.no_MMU:	RTE

	end


