**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

	machine 	mc68060
	near	code
	opt !
	incdir	include:
	include	"all_lvo.i"
	include	exec/exec.i
	include	exec/memory.i
	include	exec/types.i
	include	exec/libraries.i
	include	exec/execbase.i

	include	ispemu/isp_debug.i
MYDEBUG	set	0

	include	mc40_rev.i

**-------------------------------------------------------------------------------

	STRUCTURE	MC40_LIBBASE,LIB_SIZE
	ULONG	MC40_SYSBASE
	ULONG	MC40_SEGLIST
	ULONG	MC40_CPU040
	ULONG	MC40_CPU060
	LABEL	MC40_SIZE

tv_Illegal:	EQU	$00000010	* Vector Vier

**-------------------------------------------------------------------------------

	SECTION	loader,CODE

ProgStart:	DBUG	10,"Shell start"
	MOVEQ	#0,D0
	RTS

**-------------------------------------------------------------------------------

LibStart:	ILLEGAL
	dc.l	LibStart
	dc.l             LibEnd
	dc.b	RTF_AUTOINIT
	dc.b             40
	dc.b	NT_LIBRARY
	dc.b             120
	dc.l	_LibName
	dc.l	_LibId
	dc.l	InitVector

**-------------------------------------------------------------------------------

_LibName:	dc.b	'68040.library',0
_LibName040:	dc.b	'CPU40.library',0
_LibName060:	dc.b	'68060.library',0
_LibId:                 VERS
	dc.b	' ('
	DATE
	dc.b	') '
	dc.b	'©1997 by Carsten Schlote, Coenobium Developments',0
	even
**-------------------------------------------------------------------------------

InitVector:	dc.l             MC40_SIZE
	dc.l	funcTable
	dc.l	dataTable
	dc.l	_LibCode
**-------------------------------------------------------------------------------

funcTable:	dc.l	_LibOpen
	dc.l	_LibClose
	dc.l	_LibExpunge
	dc.l	_LibNull
	dc.l	-1

**-------------------------------------------------------------------------------

dataTable:	INITBYTE	LN_TYPE,NT_LIBRARY
	INITLONG	LN_NAME,_LibName
	INITBYTE	LIB_FLAGS,(LIBF_CHANGED+LIBF_SUMUSED)
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,_LibId
	dc.l	0

**--------------------------------------------------------------------------------
_LibOpen:	ADDQ.W	#1,(LIB_OPENCNT,A6)
	MOVE.L	A6,D0
	RTS
**--------------------------------------------------------------------------------
_LibClose:	MOVEQ	#0,D0
	SUBQ.W	#1,(LIB_OPENCNT,A6)
	BNE.B	.quit
**                      BTST.B	#LIBB_DELEXP,(LIB_FLAGS,A6)    ; only for delayed expunge
**                      BEQ	.quit
	BSR.W	_LibExpunge
.quit:	RTS
**--------------------------------------------------------------------------------
_LibNull:
	MOVEQ	#0,D0
	RTS
**--------------------------------------------------------------------------------
_LibExpunge:
	MOVEM.L	D2/A5/A6,-(SP)
	MOVEA.L	A6,A5                  ; remember libbase
	MOVEA.L	(MC40_SYSBASE,A5),A6	; get Sysbase

	TST.W	(LIB_OPENCNT,A5)	; not in use - close now !
	BEQ.W            .expunge

	BSET	#LIBB_DELEXP,(LIB_FLAGS,A5)	; still in use - delay expunge
	MOVEQ	#0,D0
	BRA.B	.Expunge_End                   ; do nothing

.expunge:	MOVE.L	(MC40_SEGLIST,A5),D2	; get seglist

	MOVEA.L	A5,A1
	JSR	(_LVORemove,A6)	; Remove from lib from base

	MOVEQ	#0,D0	; Free lib vector table
	MOVEA.L	A5,A1
	MOVE.W	(LIB_NEGSIZE,A5),D0
	SUBA.L	D0,A1
	ADD.W	(LIB_POSSIZE,A5),D0
	JSR	(_LVOFreeMem,A6)

	MOVE.L	D2,D0	; return seglist for libcode

.Expunge_End:	MOVEM.L	(SP)+,D2/A5/A6
	RTS

**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------

	XDEF	_LibCode
_LibCode:	DBUG	10,"SP:=%08lx\n",SP
	MOVEM.L	d1-d7/a2-A6,-(SP)
	DBUG	10,"Enter Lib...($%08lx) \n",d0

	MOVEA.L	D0,A5		; A4:= LibBase

	MOVE.L	A6,(MC40_SYSBASE,A5)		;
	MOVE.L	A0,(MC40_SEGLIST,A5)

	bsr	_Check060		; Check for 060
	tst.l	d0
	bne	.load060lib

.load040lib:	DBUG	10," load 040 code, "
	LEA	(_LibName040,PC),A1		; Load 040
	MOVEQ	#0,D0
	JSR	(_LVOOpenLibrary,A6)
	MOVE.L	D0,(MC40_CPU040,A5)
	BEQ.B	.quit		; failure.... hmmm
	BRA.B	.returnbase		; ok

.load060lib:	DBUG	10," load 060 code, "
	LEA	(_LibName060,PC),A1		; Load 060
	MOVEQ	#0,D0
	JSR	(_LVOOpenLibrary,A6)
	MOVE.L	D0,(MC40_CPU060,A5)
	BEQ.B	.quit		; failure

.returnbase:	MOVE.L	A5,D0		; return Base

.quit:
	tst.l	d0
	bne	.noproblem
	move.l	#(AN_Unknown|AG_OpenLib|AO_Unknown),d7
	JSR	(_LVOAlert,a6)

.noproblem:	DBUG	10,", end ($%08lx) \n",d0
	MOVEM.L	(SP)+,d1-d7/a2-A6
	DBUG	10,"SP:=%08lx\n",SP
	RTS

**---------------------------------------------------------------------------------
** Check for 060
**---------------------------------------------------------------------------------

	XDEF	_Check060
_Check060:
	movem.l	d2-d7/a2-a6,-(sp)
                        LEA	(.checkcode,pc),a5
	jsr	_LVOSupervisor(a6)	; Do magic
	move.l	d2,d0
	movem.l          (sp)+,d2-d7/a2-a6
	rts


.checkcode:
	MOVE.L	#1,d2	; Remember Stack
	LEA	(.illegal,PC),A2	; Set Illegal Vector
	movec.l          VBR,a3
	MOVE.L	(tv_Illegal,a3),D3	; Remember Illegal Vector
	nop
                	CPUSHA	DC	; Dump

	MOVE.L	A2,(tv_Illegal,a3)
	NOP

.xx	MOVEC	PCR,D0	; Get PCR
.zz
	MOVE.L	D3,(tv_Illegal,a3)	; Restore Illegal Vector
	NOP
                	CPUSHA	DC	; Dump
	rte

	**----------------------------------------


.illegal:	ADD.L	#(.zz-.xx),(2,SP)	; Remember Flag
	MOVE.L	#0,D2                  ; Remember 040 flag
           	rte
**-----------------------------------------------------------------------------------

LibEnd:	NOP
	end
