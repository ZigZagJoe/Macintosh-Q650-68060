

**---------------------------------------------------------------------------------------------
** Coenobium Developments
** Software & Hardware Entwicklung, Netzadministration und Netzdienstleistunge
**
** Carsten Schlote         Oberstedter Str 1   61440 Oberursel
** Telefon 06171-910536    Fax: -910286        schlote@stud.uni-frankfurt.de
**---------------------------------------------------------------------------------------------
** ALL RIGHTS ON THIS SOURCES RESERVED TO COENOBIUM DEVELOPMENTS
**
** $Id$
**
**------------------------------------------------------------------------------------------------------

	Machine	68060
	SECTION         FPSP060,CODE
	NEAR	CODE
	OPT !

	NOLIST
	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i

	include         fpsp_debug.i
	include	fpsp_emu.i

MYDEBUG	SET         	0		* Current Debug Level
DEBUG_DETAIL 	set 	10		* Detail Level
	LIST

**-------------------------------------------------------------------------------------------------

	XREF	fetch_dreg
	XREF	store_dreg_b,store_dreg_w,store_dreg_l
	XREF            _calc_ea_fout,norm,unf_res,ovf_res,_round,bindec

**-------------------------------------------------------------------------------------------------

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	fmovm_dynamic(): emulate "fmovm" dynamic instruction
**-------------------------------------------------------------------------------------------------
*
* xdef :	fetch_dreg() - fetch data register
*	{i,d,}mem_read() - fetch data from memory
*	_mem_write() - write data to memory
*	iea_iacc() - instruction memory access error occurred
*	iea_dacc() - data memory access error occurred
*	restore() - restore An index regs if access error occurred
*
* INPUT :	None
*
* OUTPUT :*	If instr is "fmovm Dn,-(A7)" from supervisor mode,
*	d0 = size of dump
*	d1 = Dn
*	Else if instruction access error,
*	d0 = FSLW
*	Else if data access error,
*	d0 = FSLW
*	a0 = address of fault
*	Else
*	none.
*
* ALGORITHM :
*
*  The  effective  address  must  be  calculated since this is entered from an "Unimplemented
* Effective  Address" exception handler.  So, we have our own fcalc_ea() routine here.  If an
* access  error  is  flagged  by  a  _{i,d,}mem_read() call, we must exit through the special
* handler.
*
* The  data  register  is  determined and its value loaded to get the string of FP registers
* affected.   This  value  is used as an index into a lookup table such that we can determine
* the number of bytes involved.
*
* If  the instruction is "fmovem.x <ea>,Dn", a _mem_read() is used to read in all FP values.
* Again, _mem_read() may fail and require a special exit.
*
* If the instruction is "fmovem.x DN,<ea>", a _mem_write() is used
* to write all FP values. _mem_write() may also fail.
*
*  If the instruction is "fmovem.x DN,-(a7)" from supervisor mode, then we return the size of
* the  dump  and the string to the caller so that the move can occur outside of this routine.
* This special case is required so that moves to the system stack are handled correctly.
*
* DYNAMIC:
* 	fmovem.x	dn, <ea>
* 	fmovem.x	<ea>, dn
*
* 	     <WORD 1>		      <WORD2>
*	1111 0010 00 |<ea>|	11@# 1000 0$$$ 0000
*
*	# = (0): predecrement addressing mode
*	    (1): postincrement or control addressing mode
*	@ = (0): move listed regs from memory to the FPU
*	    (1): move listed regs from the FPU to memory
*	$$$    : index of data register holding reg select mask
*
* NOTES:
* If the data register holds a zero, then the instruction is a nop.
*
***-------------------------------------------------------------------------------------------------

	xdef	fmovm_dynamic

	**--------------------------------------------------------------------------------
fmovm_dynamic:	* extract the data register in which the bit string resides...

	MOVE.B	EXC_LV+EXC_EXTWORD+1(a6),d1	* fetch extword
	ANDI.W	#$70,d1				* extract reg bits
	LSR.B	#$4,d1				* shift into lo bits

	**--------------------------------------------------------------------------------
	* fetch the bit string into d0...

	BSR	fetch_dreg		* fetch reg string

	ANDI.L	#$000000ff,d0		* keep only lo byte

	MOVE.L	d0,-(sp)		* save strg
	MOVE.B	(tbl_fmovm_size.w,pc,d0),d0
	MOVE.L	d0,-(sp)		* save size
	BSR	fmovm_calc_ea		* calculate <ea>
	MOVE.L	(sp)+,d0		* restore size
	MOVE.L	(sp)+,d1		* restore strg

	**--------------------------------------------------------------------------------
	* if the bit string is a zero, then the operation is a no-op
	* but, make sure that we've calculated ea and advanced the opword pointer

	BEQ	fmovm_data_done

	**--------------------------------------------------------------------------------
	* separate move ins from move outs...

	BTST	#$5,EXC_LV+EXC_EXTWORD(a6)	* is it a move in or out?
	BEQ	fmovm_data_in			* it's a move out

	**--------------------------------------------------------------------------------
	* MOVE OUT:

fmovm_data_out:
	BTST	#$4,EXC_LV+EXC_EXTWORD(a6)	* control or predecrement?
	BNE	fmovm_out_ctrl			* control

	**--------------------------------------------------------------------------------
fmovm_out_predec:
	* for predecrement mode, the bit string is the opposite of both control
	* operations and postincrement mode. (bit7 = FP7 ... bit0 = FP0)
	* here, we convert it to be just like the others...

	MOVE.B	(tbl_fmovm_convert.w,pc,d1.w*1),d1
	BTST	#$5,EXC_SR(a6)			* user or supervisor mode?
	BEQ	fmovm_out_ctrl			* user

fmovm_out_predec_s:
	CMP.b	#mda7_flg,EXC_LV+SPCOND_FLG(a6) * is <ea> mode -(a7)?
	BNE.b	fmovm_out_ctrl

	**--------------------------------------------------------------------------------
	* the operation was unfortunately an: fmovem.x dn,-(sp)
	* called from supervisor mode.
	* we're also passing "size" and "strg" back to the calling routine

	RTS

	**--------------------------------------------------------------------------------
	**--------------------------------------------------------------------------------
fmovm_out_ctrl:
	MOVE.L	a0,a1				* move <ea> to a1

*	SUB.L	d0,sp				* subtract size of dump
*	LEA	(sp),a0

	TST.B	d1				* should FP0 be moved?
	BPL	fmovm_out_ctrl_fp1		* no
	MOVE.L	EXC_LV+EXC_FP0+0(a6),(a0)+	* yes
	MOVE.L	EXC_LV+EXC_FP0+4(a6),(a0)+
	MOVE.L	EXC_LV+EXC_FP0+8(a6),(a0)+

fmovm_out_ctrl_fp1:
	LSL.B	#$1,d1				* should FP1 be moved?
	BPL	fmovm_out_ctrl_fp2		* no
	MOVE.L	EXC_LV+EXC_FP1+0(a6),(a0)+	* yes
	MOVE.L	EXC_LV+EXC_FP1+4(a6),(a0)+
	MOVE.L	EXC_LV+EXC_FP1+8(a6),(a0)+

fmovm_out_ctrl_fp2:
	LSL.B	#$1,d1			* should FP2 be moved?
	BPL	fmovm_out_ctrl_fp3	* no
	FMOVEM.X	fp2,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_fp3:
	LSL.B	#$1,d1			* should FP3 be moved?
	BPL	fmovm_out_ctrl_fp4	* no
	FMOVEM.x	fp3,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_fp4:
	LSL.B	#$1,d1			* should FP4 be moved?
	BPL	fmovm_out_ctrl_fp5	* no
	FMOVEM.X	fp4,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_fp5:
	LSL.B	#$1,d1			* should FP5 be moved?
	BPL	fmovm_out_ctrl_fp6	* no
	FMOVEM.X	fp5,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_fp6:
	LSL.B	#$1,d1			* should FP6 be moved?
	BPL	fmovm_out_ctrl_fp7	* no
	FMOVEM.X	fp6,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_fp7:
	LSL.B	#$1,d1			* should FP7 be moved?
	BPL	fmovm_out_ctrl_done	* no
	FMOVEM.X	fp7,(a0)		* yes
	ADD.L	#$c,a0

fmovm_out_ctrl_done:
	MOVE.L	a1,EXC_LV+L_SCR1(a6)

*	LEA	(sp),a0			* pass: supervisor src
*	MOVE.L	d0,-(sp)		* save size
*	BSR	_dmem_write		* copy data to user mem
*	MOVE.L	(sp)+,d0
*	ADD.L	d0,sp			* clear fpreg data from stack
*	TST.L	d1			* did dstore err?
*	BNE.W	fmovm_out_err		* yes
	RTS

	**--------------------------------------------------------------------------------
	**--------------------------------------------------------------------------------
	** MOVE IN:
fmovm_data_in:
	MOVE.L	a0,EXC_LV+L_SCR1(a6)

*	SUB.L	d0,sp			* make room for fpregs
*	LEA	(sp),a1

*	MOVE.L	d1,-(sp)		* save bit string for later
*	MOVE.L	d0,-(sp)		* save # of bytes
*	BSR	_dmem_read		* copy data from user mem
*	MOVE.L	(sp)+,d0		* retrieve * of bytes
*	TST.L	d1			* did dfetch fail?
*	BNE.W	fmovm_in_err		* yes
*	move.l	(sp)+,d1		* load bit string

*	lea	(sp),a0			* addr of stack

	TST.B	d1			* should FP0 be moved?
	BPL	fmovm_data_in_fp1	* no

	MOVE.L	(a0)+,EXC_LV+EXC_FP0+$0(a6)	* yes
	MOVE.L	(a0)+,EXC_LV+EXC_FP0+$4(a6)
	MOVE.L	(a0)+,EXC_LV+EXC_FP0+$8(a6)
fmovm_data_in_fp1:
	LSL.B	#$1,d1			* should FP1 be moved?
	BPL	fmovm_data_in_fp2	* no

	MOVE.L	(a0)+,EXC_LV+EXC_FP1+$0(a6)	* yes
	MOVE.L	(a0)+,EXC_LV+EXC_FP1+$4(a6)
	MOVE.L	(a0)+,EXC_LV+EXC_FP1+$8(a6)

fmovm_data_in_fp2:
	LSL.B	#$1,d1			* should FP2 be moved?
	BPL	fmovm_data_in_fp3	* no
	FMOVEM.X	(a0)+,fp2		* yes

fmovm_data_in_fp3:
	LSL.B	#$1,d1			* should FP3 be moved?
	BPL	fmovm_data_in_fp4	* no
	FMOVEM.X	(a0)+,fp3		* yes

fmovm_data_in_fp4:
	LSL.B	#$1,d1			* should FP4 be moved?
	BPL.B	fmovm_data_in_fp5	* no
	FMOVEM.X	(a0)+,fp4		* yes

fmovm_data_in_fp5:
	LSL.B	#$1,d1			* should FP5 be moved?
	BPL	fmovm_data_in_fp6	* no
	FMOVEM.X	(a0)+,fp5		* yes

fmovm_data_in_fp6:
	LSL.B	#$1,d1			* should FP6 be moved?
	BPL	fmovm_data_in_fp7	* no
	FMOVEM.X	(a0)+,fp6		* yes

fmovm_data_in_fp7:
	LSL.B	#$1,d1			* should FP7 be moved?
	BPL	fmovm_data_in_done	* no
	FMOVEM.X	(a0)+,fp7		* yes

fmovm_data_in_done:
*	add.l	d0,sp	* remove fpregs from stack

	**--------------------------------------------------------------------------------
fmovm_data_done:
	rts

	**---------------------------------------------------------------------------------
	*
	* table indexed by the operation's bit string that gives the number
	* of bytes that will be moved.
	*
	* number of bytes = (* of 1's in bit string) * 12(bytes/fpreg)
	*
tbl_fmovm_size:
	dc.b	$00,$0c,$0c,$18,$0c,$18,$18,$24
	dc.b	$0c,$18,$18,$24,$18,$24,$24,$30
	dc.b	$0c,$18,$18,$24,$18,$24,$24,$30
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$0c,$18,$18,$24,$18,$24,$24,$30
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$0c,$18,$18,$24,$18,$24,$24,$30
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$30,$3c,$3c,$48,$3c,$48,$48,$54
	dc.b	$0c,$18,$18,$24,$18,$24,$24,$30
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$30,$3c,$3c,$48,$3c,$48,$48,$54
	dc.b	$18,$24,$24,$30,$24,$30,$30,$3c
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$30,$3c,$3c,$48,$3c,$48,$48,$54
	dc.b	$24,$30,$30,$3c,$30,$3c,$3c,$48
	dc.b	$30,$3c,$3c,$48,$3c,$48,$48,$54
	dc.b	$30,$3c,$3c,$48,$3c,$48,$48,$54
	dc.b	$3c,$48,$48,$54,$48,$54,$54,$60

	**---------------------------------------------------------------------------------
	*
	* table to convert a pre-decrement bit string into a post-increment
	* or control bit string.
	* ex: 	$00	==>	$00
	*	$01	==>	$80
	*	$02	==>	$40
	*	.
	*	.
	*	$fd	==>	$bf
	*	$fe	==>	$7f
	*	$ff	==>	$ff
	*
tbl_fmovm_convert:
	dc.b	$00,$80,$40,$c0,$20,$a0,$60,$e0
	dc.b	$10,$90,$50,$d0,$30,$b0,$70,$f0
	dc.b	$08,$88,$48,$c8,$28,$a8,$68,$e8
	dc.b	$18,$98,$58,$d8,$38,$b8,$78,$f8
	dc.b	$04,$84,$44,$c4,$24,$a4,$64,$e4
	dc.b	$14,$94,$54,$d4,$34,$b4,$74,$f4
	dc.b	$0c,$8c,$4c,$cc,$2c,$ac,$6c,$ec
	dc.b	$1c,$9c,$5c,$dc,$3c,$bc,$7c,$fc
	dc.b	$02,$82,$42,$c2,$22,$a2,$62,$e2
	dc.b	$12,$92,$52,$d2,$32,$b2,$72,$f2
	dc.b	$0a,$8a,$4a,$ca,$2a,$aa,$6a,$ea
	dc.b	$1a,$9a,$5a,$da,$3a,$ba,$7a,$fa
	dc.b	$06,$86,$46,$c6,$26,$a6,$66,$e6
	dc.b	$16,$96,$56,$d6,$36,$b6,$76,$f6
	dc.b	$0e,$8e,$4e,$ce,$2e,$ae,$6e,$ee
	dc.b	$1e,$9e,$5e,$de,$3e,$be,$7e,$fe
	dc.b	$01,$81,$41,$c1,$21,$a1,$61,$e1
	dc.b	$11,$91,$51,$d1,$31,$b1,$71,$f1
	dc.b	$09,$89,$49,$c9,$29,$a9,$69,$e9
	dc.b	$19,$99,$59,$d9,$39,$b9,$79,$f9
	dc.b	$05,$85,$45,$c5,$25,$a5,$65,$e5
	dc.b	$15,$95,$55,$d5,$35,$b5,$75,$f5
	dc.b	$0d,$8d,$4d,$cd,$2d,$ad,$6d,$ed
	dc.b	$1d,$9d,$5d,$dd,$3d,$bd,$7d,$fd
	dc.b	$03,$83,$43,$c3,$23,$a3,$63,$e3
	dc.b	$13,$93,$53,$d3,$33,$b3,$73,$f3
	dc.b	$0b,$8b,$4b,$cb,$2b,$ab,$6b,$eb
	dc.b	$1b,$9b,$5b,$db,$3b,$bb,$7b,$fb
	dc.b	$07,$87,$47,$c7,$27,$a7,$67,$e7
	dc.b	$17,$97,$57,$d7,$37,$b7,$77,$f7
	dc.b	$0f,$8f,$4f,$cf,$2f,$af,$6f,$ef
	dc.b	$1f,$9f,$5f,$df,$3f,$bf,$7f,$ff

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* _fmovm_calc_ea: calculate effective address
**-------------------------------------------------------------------------------------------------
	xdef	fmovm_calc_ea
fmovm_calc_ea:
	MOVE.L	d0,a0	* move * bytes to a0

	**---------------------------------------------------------------------------------
	* currently, MODE and REG are taken from the EXC_LV+EXC_OPWORD. this could be
	* easily changed if they were inputs passed in registers.

	MOVE.W	EXC_LV+EXC_OPWORD(a6),d0	* fetch opcode word
	MOVE.W	d0,d1				* make a copy

	ANDI.W	#$3f,d0				* extract mode field
	ANDI.L	#$7,d1				* extract reg  field

	**---------------------------------------------------------------------------------
	* jump to the corresponding function for each {MODE,REG} pair.

	MOVE.W	((tbl_fea_mode).b,pc,d0.w*2),d0 * fetch jmp distance
	JMP	((tbl_fea_mode).b,pc,d0.w*1) 	* jmp to correct ea mode

tbl_fea_mode:	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode

	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode
	dc.w	tbl_fea_mode	-	tbl_fea_mode

	dc.w	faddr_ind_a0	- 	tbl_fea_mode
	dc.w	faddr_ind_a1	- 	tbl_fea_mode
	dc.w	faddr_ind_a2	- 	tbl_fea_mode
	dc.w	faddr_ind_a3 	- 	tbl_fea_mode
	dc.w	faddr_ind_a4 	- 	tbl_fea_mode
	dc.w	faddr_ind_a5 	- 	tbl_fea_mode
	dc.w	faddr_ind_a6 	- 	tbl_fea_mode
	dc.w	faddr_ind_a7 	- 	tbl_fea_mode

	dc.w	faddr_ind_p_a0	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a1 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a2 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a3 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a4 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a5 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a6 	- 	tbl_fea_mode
	dc.w	faddr_ind_p_a7 	- 	tbl_fea_mode

	dc.w	faddr_ind_m_a0 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a1 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a2 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a3 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a4 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a5 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a6 	- 	tbl_fea_mode
	dc.w	faddr_ind_m_a7 	- 	tbl_fea_mode

	dc.w	faddr_ind_disp_a0	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a1 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a2 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a3 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a4 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a5 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a6 	- 	tbl_fea_mode
	dc.w	faddr_ind_disp_a7	-	tbl_fea_mode

	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode
	dc.w	faddr_ind_ext 	- 	tbl_fea_mode

	dc.w	fabs_short	- 	tbl_fea_mode
	dc.w	fabs_long	- 	tbl_fea_mode
	dc.w	fpc_ind	- 	tbl_fea_mode
	dc.w	fpc_ind_ext	- 	tbl_fea_mode
	dc.w	tbl_fea_mode	- 	tbl_fea_mode
	dc.w	tbl_fea_mode	- 	tbl_fea_mode
	dc.w	tbl_fea_mode	- 	tbl_fea_mode
	dc.w	tbl_fea_mode	- 	tbl_fea_mode

	**---------------------------------------------------------------------------------
	* Address register indirect: (An) *

faddr_ind_a0:	MOVE.L	EXC_LV+EXC_A0(a6),a0	* Get current a0
	RTS
faddr_ind_a1:	MOVE.L	EXC_LV+EXC_A1(a6),a0	* Get current a1
	RTS
faddr_ind_a2:	MOVE.L	a2,a0			* Get current a2
	RTS
faddr_ind_a3:	MOVE.L	a3,a0			* Get current a3
	RTS
faddr_ind_a4:	MOVE.L	a4,a0			* Get current a4
	RTS
faddr_ind_a5:	MOVE.L	a5,a0			* Get current a5
	RTS
faddr_ind_a6:	MOVE.L	(a6),a0			* Get current a6
	RTS
faddr_ind_a7:	MOVE.L	EXC_LV+EXC_A7(a6),a0	* Get current a7
	rts

	**---------------------------------------------------------------------------------
	* Address register indirect w/ postincrement: (An)+ *

faddr_ind_p_a0:	MOVE.L	EXC_LV+EXC_A0(a6),d0	* Get current a0
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,EXC_LV+EXC_A0(a6)	* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a1:	MOVE.L	EXC_LV+EXC_A1(a6),d0	* Get current a1
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,EXC_LV+EXC_A1(a6)	* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a2:	MOVE.L	a2,d0			* Get current a2
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,a2			* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a3:	MOVE.L	a3,d0			* Get current a3
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,a3			* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a4:	MOVE.L	a4,d0			* Get current a4
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,a4			* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a5:	MOVE.L	a5,d0			* Get current a5
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,a5			* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a6:	MOVE.L	(a6),d0			* Get current a6
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,(a6)			* Save incr value
	MOVE.L	d0,a0
	RTS

faddr_ind_p_a7: MOVE.B	#mia7_flg,EXC_LV+SPCOND_FLG(a6) * set "special case" flag
	MOVE.L	EXC_LV+EXC_A7(a6),d0	* Get current a7
	MOVE.L	d0,d1
	ADD.L	a0,d1			* Increment
	MOVE.L	d1,EXC_LV+EXC_A7(a6)	* Save incr value
	MOVE.L	d0,a0
	RTS

	**---------------------------------------------------------------------------------
	* Address register indirect w/ predecrement: -(An) *
faddr_ind_m_a0:
	MOVE.L	EXC_LV+EXC_A0(a6),d0	* Get current a0
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,EXC_LV+EXC_A0(a6)	* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a1:	MOVE.L	EXC_LV+EXC_A1(a6),d0	* Get current a1
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,EXC_LV+EXC_A1(a6)	* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a2:	MOVE.L	a2,d0			* Get current a2
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,a2			* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a3:	MOVE.L	a3,d0			* Get current a3
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,a3			* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a4:	MOVE.L	a4,d0			* Get current a4
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,a4			* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a5:	MOVE.L	a5,d0			* Get current a5
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,a5			* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a6:	MOVE.L	(a6),d0			* Get current a6
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,(a6)			* Save decr value
	MOVE.L	d0,a0
	RTS

faddr_ind_m_a7:	MOVE.b	#mda7_flg,EXC_LV+SPCOND_FLG(a6) * set "special case" flag
	MOVE.L	EXC_LV+EXC_A7(a6),d0	* Get current a7
	SUB.L	a0,d0			* Decrement
	MOVE.L	d0,EXC_LV+EXC_A7(a6)	* Save decr value
	MOVE.L	d0,a0
	RTS

	**---------------------------------------------------------------------------------
	* Address register indirect w/ displacement: (d16, An) *
faddr_ind_disp_a0:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	EXC_LV+EXC_A0(a6),a0		* a0 + d16
	RTS

faddr_ind_disp_a1:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	EXC_LV+EXC_A1(a6),a0		* a1 + d16
	RTS

faddr_ind_disp_a2:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	a2,a0				* a2 + d16
	RTS

faddr_ind_disp_a3:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	a3,a0				* a3 + d16
	RTS

faddr_ind_disp_a4:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	a4,a0				* a4 + d16
	RTS

faddr_ind_disp_a5:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	a5,a0				* a5 + d16
	RTS

faddr_ind_disp_a6:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	(a6),a0				* a6 + d16
	RTS

faddr_ind_disp_a7:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	EXC_LV+EXC_A7(a6),a0		* a7 + d16
	RTS


	**---------------------------------------------------------------------------------
	* Address register indirect w/ index(8-bit displacement): (d8, An, Xn)
	*    "       "         "    w/   "  (base displacement): (bd, An, Xn)
	* Memory indirect postindexed: ([bd, An], Xn, od)
	* Memory indirect preindexed: ([bd, An, Xn], od)

faddr_ind_ext:	ADDQ.L	#$8,d1
	BSR	fetch_dreg			* fetch base areg

	MOVE.L	d0,-(sp)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.W	(a0),D0 			* sign extend displacement

	MOVE.L	(sp)+,a0

	BTST	#$8,d0
	BNE	fcalc_mem_ind

	MOVE.L	d0,EXC_LV+L_SCR1(a6)		* hold opword

	MOVE.L	d0,d1
	ROL.W	#$4,d1
	ANDI.W	#$f,d1				* extract index regno

	* count on fetch_dreg() not to alter a0...

	BSR	fetch_dreg			* fetch index

	MOVE.L	d2,-(sp)			* save d2
	MOVE.L	EXC_LV+L_SCR1(a6),d2		* fetch opword

	BTST	#$b,d2				* is it word or dc.l?
	BNE	faii8_long
	EXT.L	d0				* sign extend word index
faii8_long:
	MOVE.L	d2,d1
	ROL.W	#$7,d1
	ANDI.L	#$3,d1				* extract scale value

	LSL.L	d1,d0				* shift index by scale

	EXTB.L	d2				* sign extend displacement
	ADD.L	d2,d0				* index + disp
	ADD.L	d0,a0				* An + (index + disp)

	MOVE.L	(sp)+,d2			* restore old d2
	RTS

           	**---------------------------------------------------------------------------------
	* Absolute dc.w: (XXX).W

fabs_short:	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	RTS


           	**---------------------------------------------------------------------------------
	** Absolute dc.l: (XXX).L

fabs_long:	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.L	(a0),A0 			* sign extend displacement
	RTS

           	**---------------------------------------------------------------------------------
	** Program counter indirect w/ displacement: (d16, PC)
fpc_ind:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVEA.W	(a0),A0 			* sign extend displacement
	ADD.L	EXC_LV+EXC_EXTWPTR(a6),a0	* pc + d16

	* _imem_read_word() increased the extwptr by 2. need to adjust here. ??????@@@@@@

	SUBQ.L	#$2,a0	* adjust <ea>
	RTS

           	**---------------------------------------------------------------------------------
	* PC indirect w/ index(8-bit displacement): (d8, PC, An) *
	* "     "     w/   "  (base displacement): (bd, PC, An)  *
	* PC memory indirect postindexed: ([bd, PC], Xn, od)     *
	* PC memory indirect preindexed: ([bd, PC, Xn], od)      *
fpc_ind_ext:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
                MOVE.W	(a0),d0

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* put base in a0
	SUBQ.L	#$2,a0				* adjust base

	BTST	#$8,d0				* is disp only 8 bits?
	BNE	fcalc_mem_ind			* calc memory indirect

	MOVE.L	d0,EXC_LV+L_SCR1(a6)		* store opword

	MOVE.L	d0,d1				* make extword copy
	ROL.W	#$4,d1				* rotate reg num into place
	ANDI.W	#$f,d1				* extract register number

           	**---------------------------------------------------------------------------------
	* count on fetch_dreg() not to alter a0...

	BSR	fetch_dreg		* fetch index

	MOVE.L	d2,-(sp)		* save d2
	MOVE.L	EXC_LV+L_SCR1(a6),d2	* fetch opword

	BTST	#$b,d2			* is index word or dc.l?
	BNE	fpii8_long		* dc.l
	EXT.L	d0			* sign extend word index
fpii8_long:
	MOVE.L	d2,d1
	ROL.W	#$7,d1			* rotate scale value into place
	ANDI.L	#$3,d1			* extract scale value

	LSL.L	d1,d0			* shift index by scale

	EXTB.L	d2			* sign extend displacement
	ADD.L	d2,d0			* disp + index
	ADD.L	d0,a0			* An + (index + disp)

	MOVE.L	(sp)+,d2		* restore temp register
	RTS

           	**---------------------------------------------------------------------------------
	* d2 = index
	* d3 = base
	* d4 = od
	* d5 = extword
fcalc_mem_ind:
	BTST	#$6,d0		* is the index suppressed?
	BEQ	fcalc_index
	MOVEM.L	d2-d5,-(sp)	* save d2-d5

	MOVE.L	d0,d5		* put extword in d5
	MOVE.L	a0,d3		* put base in d3

	CLR.L	d2		* yes, so index = 0
	BRA	fbase_supp_ck

           	**---------------------------------------------------------------------------------
	* index:
fcalc_index:
	MOVE.L	d0,EXC_LV+L_SCR1(a6)	* save d0 (opword)
	BFEXTU	d0{16:4},d1		* fetch dreg index
	BSR	fetch_dreg

	MOVEM.L	d2-d5,-(sp)		* save d2-d5
	MOVE.L	d0,d2			* put index in d2
	MOVE.L	EXC_LV+L_SCR1(a6),d5
	MOVE.L	a0,d3

	BTST	#$b,d5			* is index word or dc.l?
	BNE	fno_ext
	EXT.L	d2

fno_ext:	BFEXTU	d5{21:2},d0
	LSL.L	d0,d2

           	**---------------------------------------------------------------------------------
	* base address (passed as parameter in d3):
	* we clear the value here if it should actually be suppressed.
fbase_supp_ck:
	BTST	#$7,d5			* is the bd suppressed?
	BEQ	fno_base_sup
	CLR.L	d3

           	**---------------------------------------------------------------------------------
	* base displacement:
fno_base_sup:
	BFEXTU	d5{26:2},d0	* get bd size
*	beq.l	fmovm_error	* if (size == 0) it's reserved

	CMP.b	#2,d0
	BLT	fno_bd
	BEQ	fget_word_bd

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0

	BRA	fchk_ind

           	**---------------------------------------------------------------------------------
fget_word_bd:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.W	(a0),d0
	EXT.L	d0				* sign extend bd
fchk_ind:
	ADD.L	d0,d3				* base += bd

           	**---------------------------------------------------------------------------------
	* outer displacement:
fno_bd:
	BFEXTU	d5{30:2},d0			* is od suppressed?
	BEQ	faii_bd

	CMP.b	#2,d0
	BLT	fnull_od
	BEQ	fword_od

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
                MOVE.L	(a0),d0
	BRA 	fadd_them

           	**---------------------------------------------------------------------------------
fword_od:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.W	(a0),d0
	EXT.L	d0				* sign extend od
	bra.b	fadd_them

           	**---------------------------------------------------------------------------------
fnull_od:
	CLR.L	d0
fadd_them:
	MOVE.L	d0,d4

	BTST	#$2,d5			* pre or post indexing?
	BEQ	fpre_indexed

	MOVE.L	d3,a0
                MOVE.L	(a0),d0

	ADD.L	d2,d0		* <ea> += index
	ADD.L	d4,d0		* <ea> += od
	bra.b	fdone_ea

           	**---------------------------------------------------------------------------------
fpre_indexed:
	ADD.L	d2,d3		* preindexing
	MOVE.L	d3,a0
	MOVE.L	(a0),d0
	ADD.L	d4,d0		* ea += od
	bra.b	fdone_ea

           	**---------------------------------------------------------------------------------
faii_bd:
	ADD.L	d2,d3		* ea = (base + bd) + index
	MOVE.L	d3,d0
fdone_ea:
	MOVE.L	d0,a0

	MOVEM.L	(sp)+,d2-d5	* restore d2-d5
	RTS

*fmovm_err:
*	MOVE.L	EXC_LV+L_SCR1(a6),a0
*	bra	iea_dacc
*	ILLEGAL





**-------------------------------------------------------------------------------------------------
** 	fmovm_ctrl(): emulate fmovem.l of control registers instr
**-------------------------------------------------------------------------------------------------
*	_imem_read_long() - read longword from memory
*	iea_iacc() - _imem_read_long() failed; error recovery
*
* INPUT :
*	None
*
* OUTPUT :
*	If _imem_read_long() doesn't fail:
*	EXC_LV+USER_FPCR(a6)  = new FPCR value
*	EXC_LV+USER_FPSR(a6)  = new FPSR value
*	EXC_LV+USER_FPIAR(a6) = new FPIAR value
*
* ALGORITHM :
*
*
*  Decode  the  instruction  type  by  looking at the extension word in order to see how many
* control registers to fetch from memory.  Fetch them using _imem_read_long().  If this fetch
* fails, exit through the special access error exit handler iea_iacc().
*
* Instruction word decoding:
*
* 	fmovem.l *<data>, {FPIAR#|FPCR#|FPSR}
*
*	WORD1	        WORD2
*	1111 0010 00 111100	100$ $$00 0000 0000
*
*	$$$ (100): FPCR
*	    (010): FPSR
*	    (001): FPIAR
*	    (000): FPIAR
*
**-------------------------------------------------------------------------------------------------

	xdef	fmovm_ctrl
fmovm_ctrl:
	DBUG	10,"<fmove_ctrl>"

	MOVE.B	EXC_LV+EXC_EXTWORD(a6),d0	* fetch reg select bits
	CMP.b	#$9c,d0				* fpcr # fpsr # fpiar ?
	BEQ	fctrl_in_7			* yes
	CMP.B	#$98,d0				* fpcr # fpsr ?
	BEQ	fctrl_in_6			* yes
	CMP.B	#$94,d0				* fpcr # fpiar ?
	BEQ	fctrl_in_5			* yes
	
	**--------------------------------------------------------------------------------
	* fmovem.l *<data>, fpsr/fpiar
fctrl_in_3:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPSR from mem
	MOVE.L	d0,EXC_LV+USER_FPSR(a6)		* store new FPSR to stack

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPIAR from mem
	MOVE.L	d0,EXC_LV+USER_FPIAR(a6)	* store new FPIAR to stack
	RTS

	**--------------------------------------------------------------------------------
	* fmovem.l *<data>, fpcr/fpiar
fctrl_in_5:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPCR from mem
	MOVE.L	d0,EXC_LV+USER_FPCR(a6)		* store new FPCR to stack

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPIAR from mem
	MOVE.L	d0,EXC_LV+USER_FPIAR(a6)	* store new FPIAR to stack
	RTS

	**--------------------------------------------------------------------------------
	* fmovem.l *<data>, fpcr/fpsr
fctrl_in_6:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPCR from mem
	MOVE.L	d0,EXC_LV+USER_FPCR(a6)		* store new FPCR to mem
	
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPSR from mem
	MOVE.L	d0,EXC_LV+USER_FPSR(a6)		* store new FPSR to mem
	RTS

	**--------------------------------------------------------------------------------
	* fmovem.l *<data>, fpcr/fpsr/fpiar
fctrl_in_7:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPCR from mem
	MOVE.L	d0,EXC_LV+USER_FPCR(a6)		* store new FPCR to mem

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPSR from mem
	MOVE.L	d0,EXC_LV+USER_FPSR(a6)		* store new FPSR to mem

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch FPIAR from mem
	MOVE.L	d0,EXC_LV+USER_FPIAR(a6)	* store new FPIAR to mem
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** 	dst_dbl(): create double precision value from extended prec.
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*
*	None
*
* INPUT :
*	a0 = pointer to source operand in extended precision
*
* OUTPUT :
*	d0 = hi(double precision result)
*	d1 = lo(double precision result)
*
* ALGORITHM :
*
*  Changes extended precision to double precision.
*  Note: no attempt is made to round the extended value to double.
*
*	dbl_sign = ext_sign
*	dbl_exp = ext_exp - $3fff(ext bias) + $7ff(dbl bias)
*	get rid of ext integer bit
*	dbl_mant = ext_mant{62:12}
*
*	    			---------------   ---------------    ---------------
*  extended ->			  	|s|    exp    |   |1| ms mant   |    | ls mant     |
*	    			---------------   ---------------    ---------------
*	   		 	95	    64    63 62	      32      31     11	  0
*		     			|	     |
*		     			|	     |
*		     			|	     |
*		 			v   	     v
*	    		      	---------------   ---------------
*  double   ->  		      	|s|exp| mant  |   |  mant       |
*	    		      	---------------   ---------------
*	   	 	      	63     51   32   31	       0
*
**-------------------------------------------------------------------------------------------------

dst_dbl:
	CLR.L	d0		* clear d0
	MOVE.W	FTEMP_EX(a0),d0	* get exponent
	SUBI.W	#EXT_BIAS,d0	* subtract extended precision bias
	ADDI.W	#DBL_BIAS,d0	* add double precision bias
	TST.B	FTEMP_HI(a0)	* is number a denorm?
	BMI	dst_get_dupper	* no
	SUBQ.W	#$1,d0		* yes; denorm bias = DBL_BIAS - 1
dst_get_dupper:
	SWAP	d0		* d0 now in upper word
	LSL.L	#$4,d0		* d0 in proper place for dbl prec exp
	TST.B	FTEMP_EX(a0)	* test sign
	BPL	dst_get_dman	* if postive, go process mantissa
	BSET	#$1f,d0		* if negative, set sign
dst_get_dman:
	MOVE.L	FTEMP_HI(a0),d1		* get ms mantissa
	BFEXTU	d1{31:20},d1		* get upper 20 bits of ms
	OR.L	d1,d0			* put these bits in ms word of double
	MOVE.L	d0,EXC_LV+L_SCR1(a6)	* put the new exp back on the stack

	MOVE.L	FTEMP_HI(a0),d1		* get ms mantissa
	MOVE.L	#21,d0			* load shift count
	LSL.L	d0,d1			* put lower 11 bits in upper bits
	MOVE.L	d1,EXC_LV+L_SCR2(a6)	* build lower lword in memory

	MOVE.L	FTEMP_LO(a0),d1		* get ls mantissa
	BFEXTU	d1{0:21},d0		* get ls 21 bits of double
	MOVE.L	EXC_LV+L_SCR2(a6),d1
	OR.L	d0,d1			* put them in double result
	MOVE.L	EXC_LV+L_SCR1(a6),d0
	RTS

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* 	dst_sgl(): create single precision value from extended prec
**-------------------------------------------------------------------------------------------------
*
*
* INPUT :
*	a0 = pointer to source operand in extended precision
*
* OUTPUT :
*	d0 = single precision result
*
* ALGORITHM :
*
* Changes extended precision to single precision.
*	sgl_sign = ext_sign
*	sgl_exp = ext_exp - $3fff(ext bias) + $7f(sgl bias)
*	get rid of ext integer bit
*	sgl_mant = ext_mant{62:12}
*
*	    			---------------   ---------------    ---------------
*  extended ->  			|s|    exp    |   |1| ms mant   |    | ls mant     |
*	    			---------------   ---------------    ---------------
*	   	 		95	    64    63 62	   40 32      31     12	  0
*					     |	   |
*					     |	   |
*					     |	   |
*	 			             v     v
*	    				---------------
*  single   ->  	      			|s|exp| mant  |
*	   				---------------
*	   		 	      	31     22     0
*
**-------------------------------------------------------------------------------------------------

dst_sgl:	CLR.L	d0
	MOVE.W	FTEMP_EX(a0),d0		* get exponent
	SUBI.W	#EXT_BIAS,d0		* subtract extended precision bias
	ADDI.W	#SGL_BIAS,d0		* add single precision bias
	TST.B	FTEMP_HI(a0)		* is number a denorm?
	BMI.B	dst_get_supper		* no
	SUBQ.W	#$1,d0			* yes; denorm bias = SGL_BIAS - 1
dst_get_supper:
	SWAP	d0			* put exp in upper word of d0
	LSL.L	#$7,d0			* shift it into single exp bits
	TST.B	FTEMP_EX(a0)		* test sign
	BPL	dst_get_sman		* if positive, continue
	BSET	#$1f,d0			* if negative, put in sign first
dst_get_sman:
	MOVE.L	FTEMP_HI(a0),d1		* get ms mantissa
	ANDI.L	#$7fffff00,d1		* get upper 23 bits of ms
	LSR.L	#$8,d1			* and put them flush right
	OR.L	d1,d0			* put these bits in ms word of single
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** 	fout(): move from fp register to memory or data register
**-------------------------------------------------------------------------------------------------
*
* xdef **
*	_round() - needed to create EXOP for sgl/dbl precision
*	norm() - needed to create EXOP for extended precision
*	ovf_res() - create default overflow result for sgl/dbl precision*
*	unf_res() - create default underflow result for sgl/dbl prec.
*	dst_dbl() - create rounded dbl precision result.
*	dst_sgl() - create rounded sgl precision result.
*	fetch_dreg() - fetch dynamic k-factor reg for packed.
*	bindec() - convert FP binary number to packed number.
*	_mem_write() - write data to memory.
*	_mem_write2() - write data to memory unless supv mode -(a7) exc.*
*	_dmem_write_{byte,word,dc.l}() - write data to memory.
*	store_dreg_{b,w,l}() - store data to data register file.
*	facc_out_{b,w,l,d,x}() - data access error occurred.
*
* INPUT :
*	a0 = pointer to extended precision source operand
*	d0 = round prec,mode
*
* OUTPUT :
*	fp0 : intermediate underflow or overflow result if
*	      OVFL/UNFL occurred for a sgl or dbl operand
*
* ALGORITHM :
*
* This  routine  is  accessed  by  many  handlers that need to do an opclass three move of an
* operand out to memory.
*
* Decode an fmove out (opclass 3) instruction to determine if it's b,w,l,s,d,x, or p in size.
* b,w,l  can  be  stored  to either a data register or memory.  The algorithm uses a standard
* "fmove"  to  create  the  rounded  result.   Also, since exceptions are disabled, this also
* create the correct OPERR default result if appropriate.
*
* For  sgl  or  dbl  precision,  overflow  or  underflow can occur.  If either occurs and is
* enabled,  the  EXOP.   For  extended precision, the stacked <ea> must be fixed along w/ the
* address index register as appropriate w/ _calc_ea_fout().  If the source is a denorm and if
* underflow is enabled, an EXOP must be created.
*
* For  packed,  the  k-factor  must be fetched from the instruction word or a data register.
* The  <ea>  must  be fixed as w/ extended precision.  Then, bindec() is called to create the
* appropriate packed result.
*
* If  at  any time an access error is flagged by one of the move- to-memory routines, then a
* special exit must be made so that the access error can be handled properly.
*
**-------------------------------------------------------------------------------------------------

	xdef	fout
fout:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){3:3},d1 	* extract dst fmt
	MOVE.W	((tbl_fout).b,pc,d1.w*2),a1 	* use as index
	JMP	((tbl_fout).b,pc,a1)		* jump to routine

tbl_fout:	dc.w	fout_long	-	tbl_fout
	dc.w	fout_sgl	-	tbl_fout
	dc.w	fout_ext	-	tbl_fout
	dc.w	fout_pack	-	tbl_fout
	dc.w	fout_word	-	tbl_fout
	dc.w	fout_dbl	-	tbl_fout
	dc.w	fout_byte	-	tbl_fout
	dc.w	fout_pack	-	tbl_fout

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* fmove.b out
	* Only "Unimplemented Data Type" exceptions enter here. The operand
	* is either a DENORM or a NORM.

fout_byte:	TST.B	EXC_LV+STAG(a6)			* is operand normalized?
	BNE	fout_byte_denorm		* no

	FMOVEM.X	SRC(a0),fp0			* load value
fout_byte_norm:	FMOVE.L	d0,fpcr				* insert rnd prec,mode
	FMOVE.b	fp0,d0				* exec move out w/ correct rnd mode

	FMOVE.L	#$0,fpcr			* clear FPCR
	FMOVE.L	fpsr,d1				* fetch FPSR
	OR.W	d1,EXC_LV+USER_FPSR+2(a6)	* save new exc,accrued bits

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	ANDI.B	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_byte_dn			* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct

	MOVE.B	d0,(a0)				* write byte
	RTS
fout_byte_dn:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_b
	RTS

fout_byte_denorm:
	MOVE.L	SRC_EX(a0),d1
	ANDI.L	#$80000000,d1			* keep DENORM sign
	ORI.L	#$00800000,d1			* make smallest sgl
	FMOVE.S	d1,fp0
	BRA	fout_byte_norm

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* fmove.w out
	* Only "Unimplemented Data Type" exceptions enter here. The operand
	* is either a DENORM or a NORM.
fout_word:
	TST.B	EXC_LV+STAG(a6)			* is operand normalized?
	BNE	fout_word_denorm		* no

	FMOVEM.X	SRC(a0),fp0			* load value
fout_word_norm:
	FMOVE.L	d0,fpcr				* insert rnd prec:mode

	FMOVE.W	fp0,d0				* exec move out w/ correct rnd mode

	FMOVE.L	#$0,fpcr			* clear FPCR
	FMOVE.L	fpsr,d1				* fetch FPSR
	OR.W	d1,EXC_LV+USER_FPSR+2(a6)	* save new exc,accrued bits

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	ANDI.B	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_word_dn			* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct

	MOVE.W          d0,(a0)				* write Word
	RTS

fout_word_dn:	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_w
	RTS

fout_word_denorm:
	MOVE.L	SRC_EX(a0),d1
	ANDI.L	#$80000000,d1			* keep DENORM sign
	ORI.L	#$00800000,d1			* make smallest sgl
	FMOVE.S	d1,fp0
	BRA	fout_word_norm

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* fmove.l out
	* Only "Unimplemented Data Type" exceptions enter here. The operand
	* is either a DENORM or a NORM.
fout_long:

	TST.B	EXC_LV+STAG(a6)			* is operand normalized?
	BNE	fout_long_denorm		* no

	FMOVEM.X	SRC(a0),fp0			* load value

fout_long_norm:
	FMOVE.L	d0,fpcr				* insert rnd prec:mode
	FMOVE.L	fp0,d0				* exec move out w/ correct rnd mode

	FMOVE.L	#$0,fpcr			* clear FPCR
	FMOVE.L	fpsr,d1				* fetch FPSR
	OR.W	d1,EXC_LV+USER_FPSR+2(a6)	* save new exc,accrued bits

fout_long_write:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	ANDI.B	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_long_dn			* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct

                MOVE.L	d0,(a0)                 	* write dc.l
	RTS

fout_long_dn:	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_l
	RTS

fout_long_denorm:
	MOVE.L	SRC_EX(a0),d1
	ANDI.L	#$80000000,d1			* keep DENORM sign
	ORI.L	#$00800000,d1			* make smallest sgl
	FMOVE.S	d1,fp0
	BRA	fout_long_norm

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
                * fmove.x out
	* Only "Unimplemented Data Type" exceptions enter here. The operand
	* is either a DENORM or a NORM.
	* The DENORM causes an Underflow exception.
fout_ext:
	**-----------------------------------------------------------------------------
	* we copy the extended precision result to EXC_LV+FP_SCR0 so that the reserved
	* 16-bit field gets zeroed. we do this since we promise not to disturb
	* what's at SRC(a0).

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	CLR.W	EXC_LV+FP_SCR0_EX+2(a6)			* clear reserved field

	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	FMOVEM.X	SRC(a0),fp0		* return result

	BSR	_calc_ea_fout		* fix stacked <ea>

	MOVE.L	a0,a1			* pass: dst addr
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: src addr
	MOVE.L	#$c,d0			* pass: opsize is 12 bytes

	**-----------------------------------------------------------------------------
	* we must not yet write the extended precision data to the stack
	* in the pre-decrement case from supervisor mode or else we'll corrupt
	* the stack frame. so, leave it in EXC_LV+FP_SRC for now and deal with it later...

	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BEQ	fout_ext_a7

	MOVE.L	(a0),(a1)       	* write ext prec number to memory
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)

	TST.B	EXC_LV+STAG(a6)		* is operand normalized?
	BNE	fout_ext_denorm		* no
	RTS

	**-----------------------------------------------------------------------------
	* the number is a DENORM. must set the underflow exception bit
fout_ext_denorm:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* set underflow exc bit

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0
	ANDI.B	#$0a,d0					* is UNFL or INEX enabled?
	BNE	fout_ext_exc				* yes
	RTS

	**-----------------------------------------------------------------------------
	* we don't want to do the write if the exception occurred in supervisor mode
	* so _mem_write2() handles this for us.
fout_ext_a7:
	BTST	#$5,EXC_SR(a6)		* Supvisor Mode
	BNE	fout_ext_a7s		* yes

	MOVE.L	0(a0),0(a1)    	   	* write ext prec number to memory
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)

	BRA	fout_ext_a7_cont	* ok, in mem

	**-----------------------------------------------------------------------------
fout_ext_a7s:
	MOVE.L	0(a0),EXC_LV+FP_DST_EX(a6)	* Store it in frame. Do it later !
	MOVE.L	4(a0),EXC_LV+FP_DST_HI(a6)
	MOVE.L	8(a0),EXC_LV+FP_DST_LO(a6)

fout_ext_a7_cont:
	TST.B	EXC_LV+STAG(a6)		* is operand normalized?
	BNE	fout_ext_denorm		* no
	RTS
	**-----------------------------------------------------------------------------
fout_ext_exc:
	LEA	EXC_LV+FP_SCR0(a6),a0
	BSR	norm				* normalize the mantissa
	NEG.W	d0				* new exp = -(shft amt)
	ANDI.W	#$7fff,d0
	ANDI.W	#$8000,EXC_LV+FP_SCR0_EX(a6)	* keep only old sign
	OR.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1		* return EXOP in fp1
	RTS

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* fmove.s out

fout_sgl:	ANDI.B	#$30,d0				* clear rnd prec
	ORI.B	#s_mode*$10,d0			* insert sgl prec
	MOVE.L	d0,EXC_LV+L_SCR3(a6)		* save rnd prec,mode on stack

	**----------------------------------------------------------------------------
	* operand is a normalized number. first, we check to see if the move out
	* would cause either an underflow or overflow. these cases are handled
	* separately. otherwise, set the FPCR to the proper rounding mode and
	* execute the move.
	*
	MOVE.W	SRC_EX(a0),d0		* extract exponent
	ANDI.W	#$7fff,d0		* strip sign

	CMP.w	#SGL_HI,d0		* will operand overflow?
	BGT	fout_sgl_ovfl		* yes; go handle OVFL
	BEQ	fout_sgl_may_ovfl	* maybe; go handle possible OVFL
	CMP.w	#SGL_LO,d0		* will operand underflow?
	BLT	fout_sgl_unfl		* yes; go handle underflow

	**----------------------------------------------------------------------------
	* NORMs(in range) can be stored out by a simple "fmove.s"
	* Unnormalized inputs can come through this point.
	*
fout_sgl_exg:
	FMOVEM.X	SRC(a0),fp0		* fetch fop from stack

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMOVE.S	fp0,d0			* store does convert and round

	FMOVE.L	#$0,fpcr		* clear FPCR
	FMOVE.L	fpsr,d1			* save FPSR

	OR.W	d1,EXC_LV+USER_FPSR+2(a6) * set possible inex2/ainex

	**----------------------------------------------------------------------------
fout_sgl_exg_write:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	ANDI.B	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_sgl_exg_write_dn		* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct

	MOVE.L	d0,(a0)                 	* write dc.l
	RTS

fout_sgl_exg_write_dn:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_l
	RTS

	**----------------------------------------------------------------------------
                * here, we know that the operand would UNFL if moved out to single prec,
	* so, denorm and round and then use generic store single routine to
	* write the value to memory.
	*
fout_sgl_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set UNFL

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.L	a0,-(sp)

	CLR.L	d0				* pass: S.F. = 0

	CMP.b	#DENORM,EXC_LV+STAG(a6)		* fetch src optype tag
	BNE	fout_sgl_unfl_cont		* let DENORMs fall through

	LEA	EXC_LV+FP_SCR0(a6),a0
	BSR	norm				* normalize the DENORM

	**----------------------------------------------------------------------------
fout_sgl_unfl_cont:
	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to operand
	MOVE.L	EXC_LV+L_SCR3(a6),d1		* pass: rnd prec,mode
	BSR	unf_res				* calc default underflow result

	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to fop
	BSR	dst_sgl				* convert to single prec

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	andi.b	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_sgl_unfl_dn		* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct

	MOVE.L	d0,(A0)                 	* write dc.l

	BRA	fout_sgl_unfl_chkexc

	**----------------------------------------------------------------------------
fout_sgl_unfl_dn:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_l

fout_sgl_unfl_chkexc:
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	ANDI.B	#$0a,d1				* is UNFL or INEX enabled?
	BNE	fout_sd_exc_unfl		* yes
	ADDQ.L	#$4,sp
	RTS

	**----------------------------------------------------------------------------
	* it's definitely an overflow so call ovf_res to get the correct answer
	*
fout_sgl_ovfl:
	TST.B	SRC_HI+3(a0)			* is result inexact?
	BNE	fout_sgl_ovfl_inex2

	TST.L	SRC_LO(a0)			* is result inexact?
	BNE	fout_sgl_ovfl_inex2

	ORI.W	#ovfl_inx_mask,2+EXC_LV+USER_FPSR(a6) 	* set ovfl/aovfl/ainex
	BRA	fout_sgl_ovfl_cont
fout_sgl_ovfl_inex2:
	ORI.W	#ovfinx_mask,2+EXC_LV+USER_FPSR(a6) 	* set ovfl/aovfl/ainex/inex2

fout_sgl_ovfl_cont:
	MOVE.L	a0,-(sp)

	**----------------------------------------------------------------------------
	* call ovf_res() w/ sgl prec and the correct rnd mode to create the default
	* overflow result. DON'T save the returned ccodes from ovf_res() since
	* fmove out doesn't alter them.

	TST.B	SRC_EX(a0)			* is operand negative?
	SMI	d1				* set if so

	MOVE.L	EXC_LV+L_SCR3(a6),d0		* pass: sgl prec,rnd mode
	BSR	ovf_res				* calc OVFL result

	FMOVEM.X	(a0),fp0			* load default overflow result
	FMOVE.S	fp0,d0				* store to single

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract dst mode
	ANDI.B	#$38,d1				* is mode == 0? (Dreg dst)
	BEQ	fout_sgl_ovfl_dn		* must save to integer regfile

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct
	MOVE.L	d0,(a0)				* store long

	BRA	fout_sgl_ovfl_chkexc

fout_sgl_ovfl_dn:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract Dn
	ANDI.W	#$7,d1
	BSR	store_dreg_l

fout_sgl_ovfl_chkexc:
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	ANDI.B	#$0a,d1				* is UNFL or INEX enabled?
	BNE	fout_sd_exc_ovfl		* yes
	ADDQ.L	#$4,sp
	RTS

	**----------------------------------------------------------------------------
	* move out MAY overflow:
	* (1) force the exp to $3fff
	* (2) do a move w/ appropriate rnd mode
	* (3) if exp still equals zero, then insert original exponent
	*	for the correct result.
	*     if exp now equals one, then it overflowed so call ovf_res.
fout_sgl_may_ovfl:
	MOVE.W	SRC_EX(a0),d1			* fetch current sign
	ANDI.W	#$8000,d1			* keep it,clear exp
	ORI.W	#$3fff,d1			* insert exp = 0
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert scaled exp
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6) * copy hi(man)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6) * copy lo(man)

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr		* set FPCR

	FMOVE.X	EXC_LV+FP_SCR0(a6),fp0		* force fop to be rounded
	FMOVE.L	#$0,fpcr			* clear FPCR

	FABS.X	fp0				* need absolute value
	FCMP.B	#2,fp0				* did exponent increase?
	FBLT.W	fout_sgl_exg			* no; go finish NORM
	BRA	fout_sgl_ovfl			* yes; go handle overflow

	**----------------------------------------------------------------------------
fout_sd_exc_unfl:
	MOVE.L	(sp)+,a0

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	CMP.b	#DENORM,EXC_LV+STAG(a6)		* was src a DENORM?
	BNE	fout_sd_exc_cont		* no

	LEA	EXC_LV+FP_SCR0(a6),a0
	BSR	norm

	NEG.L	d0
	ANDI.W	#$7fff,d0
	BFINS	d0,EXC_LV+FP_SCR0_EX(a6){1:15}
	BRA	fout_sd_exc_cont

	**----------------------------------------------------------------------------
fout_sd_exc:
fout_sd_exc_ovfl:
	MOVE.L	(sp)+,a0			* restore a0

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	**----------------------------------------------------------------------------
fout_sd_exc_cont:
	BCLR	#$7,EXC_LV+FP_SCR0_EX(a6)	* clear sign bit
	SNE.B	EXC_LV+FP_SCR0_EX+2(a6)		* set internal sign bit
	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to DENORM

	MOVE.B	EXC_LV+L_SCR3+3(a6),d1
	LSR.B	#$4,d1
	ANDI.W	#$0c,d1
	SWAP	d1

	MOVE.B	EXC_LV+L_SCR3+3(a6),d1
	LSR.B	#$4,d1
	ANDI.W	#$03,d1
	CLR.L	d0				* pass: zero g,r,s
	BSR	_round				* round the DENORM

	TST.b	EXC_LV+FP_SCR0_EX+2(a6)		* is EXOP negative?
	BEQ	fout_sd_exc_done		* no
	BSET	#$7,EXC_LV+FP_SCR0_EX(a6)	* yes
fout_sd_exc_done:
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1		* return EXOP in fp1
	RTS

	**----------------------------------------------------------------------------
	**----------------------------------------------------------------------------
	* fmove.d out
fout_dbl:
	ANDI.B	#$30,d0				* clear rnd prec
	ORI.B	#d_mode*$10,d0			* insert dbl prec
	MOVE.L	d0,EXC_LV+L_SCR3(a6)		* save rnd prec,mode on stack

	**----------------------------------------------------------------------------
	* operand is a normalized number. first, we check to see if the move out
	* would cause either an underflow or overflow. these cases are handled
	* separately. otherwise, set the FPCR to the proper rounding mode and
	* execute the move.

	MOVE.W	SRC_EX(a0),d0		* extract exponent
	ANDI.W	#$7fff,d0		* strip sign

	CMP.w	#DBL_HI,d0		* will operand overflow?
	BGT	fout_dbl_ovfl		* yes; go handle OVFL
	BEQ	fout_dbl_may_ovfl	* maybe; go handle possible OVFL
	CMP.w	#DBL_LO,d0		* will operand underflow?
	BLT	fout_dbl_unfl		* yes; go handle underflow

	**----------------------------------------------------------------------------
	* NORMs(in range) can be stored out by a simple "fmove.d"
	* Unnormalized inputs can come through this point.
	*
fout_dbl_exg:
	FMOVEM.X	SRC(a0),fp0		* fetch fop from stack

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMOVE.D	fp0,EXC_LV+L_SCR1(a6)	* store does convert and round

	FMOVE.L	#$0,fpcr		* clear FPCR
	FMOVE.L	fpsr,d0			* save FPSR

	OR.W	d0,EXC_LV+USER_FPSR+2(a6) 	* set possible inex2/ainex

	MOVE.L	EXC_EA(a6),a1		* pass: dst addr
	LEA	EXC_LV+L_SCR1(a6),a0	* pass: src addr
	MOVEQ.L	#$8,d0			* pass: opsize is 8 bytes

	MOVE.L	(a0),(a1)       	* store dbl fop to memory
	MOVE.L	4(a0),4(a1)

	RTS				* no; so we're finished

	**----------------------------------------------------------------------------
	* here, we know that the operand would UNFL if moved out to double prec,
	* so, denorm and round and then use generic store double routine to
	* write the value to memory.
	*
fout_dbl_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* set UNFL

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.L	a0,-(sp)

	CLR.L	d0				* pass: S.F. = 0

	CMP.b	#DENORM,EXC_LV+STAG(a6)		* fetch src optype tag
	BNE	fout_dbl_unfl_cont		* let DENORMs fall through

	LEA	EXC_LV+FP_SCR0(a6),a0
	BSR	norm				* normalize the DENORM

fout_dbl_unfl_cont:
	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to operand
	MOVE.L	EXC_LV+L_SCR3(a6),d1		* pass: rnd prec,mode
	BSR	unf_res				* calc default underflow result

	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to fop
	BSR	dst_dbl				* convert to single prec
	MOVE.L	d0,EXC_LV+L_SCR1(a6)
	MOVE.L	d1,EXC_LV+L_SCR2(a6)

	MOVE.L	EXC_EA(a6),a1			* pass: dst addr
	LEA	EXC_LV+L_SCR1(a6),a0		* pass: src addr
	MOVEQ.L	#$8,d0				* pass: opsize is 8 bytes

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	ANDI.B	#$0a,d1				* is UNFL or INEX enabled?
	BNE	fout_sd_exc_unfl		* yes
	ADDQ.L	#$4,sp
	RTS

	**----------------------------------------------------------------------------
                * it's definitely an overflow so call ovf_res to get the correct answer
	*
fout_dbl_ovfl:
	MOVE.W	SRC_LO+2(a0),d0
	ANDI.W	#$7ff,d0
	BNE	fout_dbl_ovfl_inex2

	ORI.W	#ovfl_inx_mask,2+EXC_LV+USER_FPSR(a6) 	* set ovfl/aovfl/ainex
	BRA	fout_dbl_ovfl_cont
fout_dbl_ovfl_inex2:
	ORI.W	#ovfinx_mask,2+EXC_LV+USER_FPSR(a6) 	* set ovfl/aovfl/ainex/inex2
fout_dbl_ovfl_cont:
	MOVE.L	a0,-(sp)

	**----------------------------------------------------------------------------
	* call ovf_res() w/ dbl prec and the correct rnd mode to create the default
	* overflow result. DON'T save the returned ccodes from ovf_res() since
	* fmove out doesn't alter them.

	TST.B	SRC_EX(a0)		* is operand negative?
	SMI	d1			* set if so
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass: dbl prec,rnd mode
	BSR	ovf_res			* calc OVFL result

	FMOVEM.X	(a0),fp0		* load default overflow result
	FMOVE.D	fp0,EXC_LV+L_SCR1(a6)	* store to double

	MOVE.L	EXC_EA(a6),a1		* pass: dst addr
	LEA	EXC_LV+L_SCR1(a6),a0	* pass: src addr
	MOVEQ.L	#$8,d0			* pass: opsize is 8 bytes

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)		* store dbl fop to memory

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	ANDI.B	#$0a,d1			* is UNFL or INEX enabled?
	BNE.W	fout_sd_exc_ovfl	* yes
	ADDQ.L	#$4,sp
	RTS

	**----------------------------------------------------------------------------
	* move out MAY overflow:
	* (1) force the exp to $3fff
	* (2) do a move w/ appropriate rnd mode
	* (3) if exp still equals zero, then insert original exponent
	*	for the correct result.
	*     if exp now equals one, then it overflowed so call ovf_res.

fout_dbl_may_ovfl:
	MOVE.W	SRC_EX(a0),d1			* fetch current sign
	ANDI.W	#$8000,d1			* keep it,clear exp
	ORI.W	#$3fff,d1			* insert exp = 0
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert scaled exp
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6) * copy hi(man)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6) * copy lo(man)

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr		* set FPCR

	FMOVE.X	EXC_LV+FP_SCR0(a6),fp0		* force fop to be rounded
	FMOVE.L	#$0,fpcr			* clear FPCR

	FABS.X	fp0				* need absolute value
	FCMP.B	#2,fp0				* did exponent increase?
	FBLT.W	fout_dbl_exg			* no; go finish NORM
	BRA	fout_dbl_ovfl			* yes; go handle overflow



	**-------------------------------------------------------------------------------*****
	**-------------------------------------------------------------------------------*****
	**-------------------------------------------------------------------------------*****
fout_pack:
	BSR	_calc_ea_fout			* fetch the <ea>
	MOVE.L	a0,-(sp)

	MOVE.B	EXC_LV+STAG(a6),d0		* fetch input type
	BNE	fout_pack_not_norm		* input is not NORM
fout_pack_norm:
	BTST	#$4,EXC_LV+EXC_CMDREG(a6)	* static or dynamic?
	BEQ	fout_pack_s			* static

fout_pack_d:	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1	* fetch dynamic reg
	LSR.B	#$4,d1
	ANDI.W	#$7,d1

	BSR	fetch_dreg			* fetch Dn w/ k-factor
	BRA	fout_pack_type

fout_pack_s:	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d0	* fetch static field

fout_pack_type:	BFEXTS	d0{25:7},d0			* extract k-factor
	MOVE.L	d0,-(sp)

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to input

	**-----------------------------------------------------------------------------------
	* bindec is currently scrambling EXC_LV+FP_SRC for denorm inputs.
*$* !!!	* we'll have to change this, but for now, tough luck!!! $$$$$$$

	BSR	bindec				* convert xprec to packed

*$*	ANDI.L	#$cfff000f,EXC_LV+FP_SCR0(a6) 	* clear unused fields
	ANDI.L	#$cffff00f,EXC_LV+FP_SCR0(a6) 	* clear unused fields

	MOVE.L	(sp)+,d0

	TST.B	EXC_LV+FP_SCR0_EX+3(a6)
	BNE	fout_pack_set

	TST.L	EXC_LV+FP_SCR0_HI(a6)
	BNE	fout_pack_set

	TST.L	EXC_LV+FP_SCR0_LO(a6)
	BNE	fout_pack_set

	**----------------------------------------------------------------------------------
	* add the extra condition that only if the k-factor was zero, too, should
	* we zero the exponent

	TST.l	d0
	BNE	fout_pack_set

	**----------------------------------------------------------------------------------
	* "mantissa" is all zero which means that the answer is zero. but, the '040
	* algorithm allows the exponent to be non-zero. the 881/2 do not. therefore,
	* if the mantissa is zero, I will zero the exponent, too.
	* the question now is whether the exponents sign bit is allowed to be non-zero
	* for a zero, also...

	ANDI.W	#$f000,EXC_LV+FP_SCR0(a6)

fout_pack_set:	LEA	EXC_LV+FP_SCR0(a6),a0			* pass: src addr

fout_pack_write:
	MOVE.L	(sp)+,a1	* pass: dst addr
	MOVE.L	#$c,d0		* pass: opsize is 12 bytes

	CMP.b	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BEQ	fout_pack_a7

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)
	RTS

	**----------------------------------------------------------------------------------
	* we don't want to do the write if the exception occurred in supervisor mode
	* so _mem_write2() handles this for us.
fout_pack_a7:
	BTST	#$5,EXC_SR(a6)			* Is Supvisor
	BNE	fout_pack_a7s			* yes - store in frame for later
	MOVE.L	(a0),(a1)			* Store packed value
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)
                BRA	fout_pack_a7_cont
fout_pack_a7s:
	MOVE.L	0(a0),EXC_LV+FP_DST_EX(a6)
	MOVE.L	4(a0),EXC_LV+FP_DST_HI(a6)
	MOVE.L	8(a0),EXC_LV+FP_DST_LO(a6)
fout_pack_a7_cont:
	RTS

	**----------------------------------------------------------------------------------
	*
fout_pack_not_norm:
	CMP.b	#DENORM,d0			* is it a DENORM?
	BEQ	fout_pack_norm			* yes

	LEA	EXC_LV+FP_SRC(a6),a0
	CLR.W	EXC_LV+FP_SRC_EX+2(a6)

	CMP.b	#SNAN,d0			* is it an SNAN?
	BEQ	fout_pack_snan			* yes
	BRA	fout_pack_write			* no

	**----------------------------------------------------------------------------------
fout_pack_snan:
	ORI.W	#snaniop2_mask,EXC_LV+FPSR_EXCEPT(a6)	* set SNAN/AIOP
	BSET	#$6,EXC_LV+FP_SRC_HI(a6)		* set snan bit
	BRA.B	fout_pack_write








