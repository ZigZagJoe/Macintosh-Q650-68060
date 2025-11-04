
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
**---------------------------------------------------------------------------------------------
**
**
** Geht jetzt...

	Machine	68060
	SECTION	FPSP060,CODE
	NEAR	CODE
	OPT !
	NOLIST
	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i


	include         fpsp_debug.i
	include	fpsp_emu.i
	include	fpsp_macros.i

MYDEBUG	SET         	0		* Current Debug Level
DEBUG_DETAIL 	set 	10		* Detail Level

**-------------------------------------------------------------------------------------------------

	XREF	fetch_dreg
	XREF	store_dreg_l,store_dreg_b
	XREF	inc_areg,dec_areg

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* fdbcc(): routine to emulate the fdbcc instruction
*
* XDEF ** *
*	_fdbcc()
*
* xdef ** *
*	fetch_dreg() - fetch Dn value
*	store_dreg_l() - store updated Dn value
*
* INPUT ***************************************************************
*	d0 = displacement
*
* OUTPUT ************************************************************** *
*	none
*
* ALGORITHM ***********************************************************
*	This routine checks which conditional predicate is specified by
* the stacked fdbcc instruction opcode and then branches to a routine
* for that predicate. The corresponding fbcc instruction is then used
* to see whether the condition (specified by the stacked FPSR) is true
* or false.
*	If a BSUN exception should be indicated, the BSUN and ABSUN
* bits are set in the stacked FPSR. If the BSUN exception is enabled,
* the fbsun_flg is set in the EXC_LV+SPCOND_FLG location on the stack. If an
* enabled BSUN should not be flagged and the predicate is true, then
* Dn is fetched and decremented by one. If Dn is not equal to -1, add
* the displacement value to the stacked PC so that when an "rte" is
* finally executed, the branch occurs.
*
**-------------------------------------------------------------------------------------------------

	xdef	_fdbcc
_fdbcc:
	DBUG	10,"<fdbcc>"

	MOVE.L	d0,EXC_LV+L_SCR1(a6)		* save displacement
	MOVE.W	EXC_LV+EXC_CMDREG(a6),d0	* fetch predicate

	CLR.L	d1				* clear scratch reg
	MOVE.B	EXC_LV+FPSR_CC(a6),d1		* fetch fp ccodes
	ROR.L	#$8,d1				* rotate to top byte
	FMOVE.L	d1,fpsr				* insert into FPSR

	MOVE.W	((tbl_fdbcc).b,pc,d0.w*2),d1 	* load table
	jmp	((tbl_fdbcc).b,pc,d1.w) 	* jump to fdbcc routine

tbl_fdbcc:	dc.w	fdbcc_f		-	tbl_fdbcc	* 00
	dc.w	fdbcc_eq	-	tbl_fdbcc	* 01
	dc.w	fdbcc_ogt	-	tbl_fdbcc	* 02
	dc.w	fdbcc_oge	-	tbl_fdbcc	* 03
	dc.w	fdbcc_olt	-	tbl_fdbcc	* 04
	dc.w	fdbcc_ole	-	tbl_fdbcc	* 05
	dc.w	fdbcc_ogl	-	tbl_fdbcc	* 06
	dc.w	fdbcc_or	-	tbl_fdbcc	* 07
	dc.w	fdbcc_un	-	tbl_fdbcc	* 08
	dc.w	fdbcc_ueq	-	tbl_fdbcc	* 09
	dc.w	fdbcc_ugt	-	tbl_fdbcc	* 10
	dc.w	fdbcc_uge	-	tbl_fdbcc	* 11
	dc.w	fdbcc_ult	-	tbl_fdbcc	* 12
	dc.w	fdbcc_ule	-	tbl_fdbcc	* 13
	dc.w	fdbcc_neq	-	tbl_fdbcc	* 14
	dc.w	fdbcc_t		-	tbl_fdbcc	* 15
	dc.w	fdbcc_sf	-	tbl_fdbcc	* 16
	dc.w	fdbcc_seq	-	tbl_fdbcc	* 17
	dc.w	fdbcc_gt	-	tbl_fdbcc	* 18
	dc.w	fdbcc_ge	-	tbl_fdbcc	* 19
	dc.w	fdbcc_lt	-	tbl_fdbcc	* 20
	dc.w	fdbcc_le	-	tbl_fdbcc	* 21
	dc.w	fdbcc_gl	-	tbl_fdbcc	* 22
	dc.w	fdbcc_gle	-	tbl_fdbcc	* 23
	dc.w	fdbcc_ngle	-	tbl_fdbcc	* 24
	dc.w	fdbcc_ngl	-	tbl_fdbcc	* 25
	dc.w	fdbcc_nle	-	tbl_fdbcc	* 26
	dc.w	fdbcc_nlt	-	tbl_fdbcc	* 27
	dc.w	fdbcc_nge	-	tbl_fdbcc	* 28
	dc.w	fdbcc_ngt	-	tbl_fdbcc	* 29
	dc.w	fdbcc_sneq	-	tbl_fdbcc	* 30
	dc.w	fdbcc_st	-	tbl_fdbcc	* 31

	**----------------------------------------------------------------------------------
	*
	* IEEE Nonaware tests
	*
	* For the IEEE nonaware tests, only the false branch changes the
	* counter. However, the true branch may set bsun so we check to see
	* if the NAN bit is set, in which case BSUN and AIOP will be set.
	*
	* The cases EQ and NE are shared by the Aware and Nonaware groups
	* and are incapable of setting the BSUN exception bit.
	*
	* Typically, only one of the two possible branch directions could
	* have the NAN bit set.
	* (This is assuming the mutual exclusiveness of FPSR cc bit groupings
	*  is preserved.)
	*
	**---------------------------------------------------------------------------------
	* equal:
	*
	*	Z
	*
fdbcc_eq:	FBEQ.W	fdbcc_eq_yes	* equal?
fdbcc_eq_no:	BRA	fdbcc_false	* no; go handle counter
fdbcc_eq_yes:	RTS

	*
	* not equal:
	*	_
	*	Z
	*
fdbcc_neq:	FBNE.W	fdbcc_neq_yes	* not equal?
fdbcc_neq_no:	BRA	fdbcc_false	* no; go handle counter
fdbcc_neq_yes:	RTS

	*
	* greater than:
	*	_______
	*	NANvZvN
	*
fdbcc_gt:	FBGT.W	fdbcc_gt_yes				* greater than?
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_false				* no;go handle counter
	ORI.L	#bsun_mask+aiop_mask,EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* no; go handle counter
fdbcc_gt_yes:	RTS						* do nothing

	*
	* not greater than:
	*
	*	NANvZvN
	*
fdbcc_ngt:	FBNGT.W	fdbcc_ngt_yes				* not greater than?
fdbcc_ngt_no:	BRA	fdbcc_false				* no; go handle counter
fdbcc_ngt_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ.B	fdbcc_ngt_done				* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_ngt_done:	RTS						* no; do nothing

	*
	* greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
fdbcc_ge:	FBGE.W	fdbcc_ge_yes				* greater than or equal?
fdbcc_ge_no:  	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_false				* no;go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* no; go handle counter
fdbcc_ge_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_ge_yes_done			* no;go do nothing
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_ge_yes_done:
	RTS						* do nothing

	*
	* not (greater than or equal):
	*	       _
	*	NANv(N^Z)
	*
fdbcc_nge:	FBNGE.W	fdbcc_nge_yes				* not (greater than or equal)?
fdbcc_nge_no:	BRA	fdbcc_false				* no; go handle counter
fdbcc_nge_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_nge_done				* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE.W	fdbcc_bsun				* yes; we have an exception
fdbcc_nge_done:	rts			* no; do nothing

	*
	* less than:
	*	   _____
	*	N^(NANvZ)
	*
fdbcc_lt:	FBLT.W	fdbcc_lt_yes				* less than?
fdbcc_lt_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_false				* no; go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit,EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* no; go handle counter
fdbcc_lt_yes:	RTS						* do nothing

	*
	* not less than:
	*	       _
	*	NANv(ZvN)
	*
fdbcc_nlt:	FBNLT.W	fdbcc_nlt_yes				* not less than?
fdbcc_nlt_no:	BRA	fdbcc_false				* no; go handle counter
fdbcc_nlt_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_nlt_done				* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit,EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_nlt_done:	RTS						* no; do nothing

	*
	* less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
fdbcc_le:	FBLE.W	fdbcc_le_yes				* less than or equal?
fdbcc_le_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_false				* no; go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	btst	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* no; go handle counter
fdbcc_le_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_le_yes_done			* no; go do nothing
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_le_yes_done:
	rts			* do nothing

	*
	* not (less than or equal):
	*	     ___
	*	NANv(NvZ)
	*
fdbcc_nle:	FBNLE.W	fdbcc_nle_yes				* not (less than or equal)?
fdbcc_nle_no:	BRA.W	fdbcc_false				* no; go handle counter
fdbcc_nle_yes:	BTSt	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_nle_done				* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_nle_done:	RTS						* no; do nothing

	*
	* greater or less than:
	*	_____
	*	NANvZ
	*
fdbcc_gl:	FBGL.W	fdbcc_gl_yes				* greater or less than?
fdbcc_gl_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_false				* no; handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* no; go handle counter
fdbcc_gl_yes:	RTS						* do nothing

	*
	* not (greater or less than):
	*
	*	NANvZ
	*
fdbcc_ngl:	FBNGL.W	fdbcc_ngl_yes				* not (greater or less than)?
fdbcc_ngl_no:	BRA	fdbcc_false				* no; go handle counter
fdbcc_ngl_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fdbcc_ngl_done				* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
fdbcc_ngl_done:	RTS						* no; do nothing

	*
	* greater, less, or equal:
	*	___
	*	NAN
	*
fdbcc_gle:	FBGLE.W	fdbcc_gle_yes				* greater, less, or equal?
fdbcc_gle_no:	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE.W	fdbcc_bsun				* yes; we have an exception
	BRA.W	fdbcc_false				* no; go handle counter
fdbcc_gle_yes:	RTS						* do nothing

	*
	* not (greater, less, or equal):
	*
	*	NAN
	*
fdbcc_ngle:	FBNGLE.W	fdbcc_ngle_yes				* not (greater, less, or equal)?
fdbcc_ngle_no:	BRA	fdbcc_false				* no; go handle counter
fdbcc_ngle_yes:	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	rts						* no; do nothing


	**----------------------------------------------------------------------------------
	*
	* Miscellaneous tests
	*
	* For the IEEE miscellaneous tests, all but fdbf and fdbt can set bsun.
	*
	**----------------------------------------------------------------------------------
	*
	* false:
	*
	*	False
	*
fdbcc_f:				* no bsun possible
	BRA	fdbcc_false	* go handle counter

	*
	* true:
	*
	*	True
	*
fdbcc_t:				* no bsun possible
	RTS			* do nothing

	*
	* signalling false:
	*
	*	False
	*
fdbcc_sf:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* is NAN set?
	BEQ	fdbcc_false				* no;go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* is BSUN enabled?
	BNE	fdbcc_bsun				* yes; we have an exception
	BRA	fdbcc_false				* go handle counter

	*
	* signalling true:
	*
	*	True
	*
fdbcc_st:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* is NAN set?
	BEQ	fdbcc_st_done					* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE	fdbcc_bsun					* yes; we have an exception
fdbcc_st_done:	RTS

	*
	* signalling equal:
	*
	*	Z
	*
fdbcc_seq:	FBSEQ.W	fdbcc_seq_yes					* signalling equal?
fdbcc_seq_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* is NAN set?
	BEQ	fdbcc_false					* no;go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE	fdbcc_bsun					* yes; we have an exception
	BRA	fdbcc_false					* go handle counter
fdbcc_seq_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* is NAN set?
	BEQ.B	fdbcc_seq_yes_done				* no;go do nothing
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE.W	fdbcc_bsun					* yes; we have an exception
fdbcc_seq_yes_done:
	rts							* yes; do nothing

	*
	* signalling not equal:
	*	_
	*	Z
	*
fdbcc_sneq:	FBSNE.W	fdbcc_sneq_yes					* signalling not equal?
fdbcc_sneq_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* is NAN set?
	BEQ	fdbcc_false					* no;go handle counter
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE.W	fdbcc_bsun					* yes; we have an exception
	BRA.W	fdbcc_false					* go handle counter
fdbcc_sneq_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* set BSUN exc bit
	BEQ.W	fdbcc_sneq_done					* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* is BSUN enabled?
	BNE	fdbcc_bsun					* yes; we have an exception
fdbcc_sneq_done:RTS

	**-------------------------------------------------------------------------------------------------
	*
	* IEEE Aware tests
	*
	* For the IEEE aware tests, action is only taken if the result is false.
	* Therefore, the opposite branch type is used to jump to the decrement
	* routine.
	* The BSUN exception will not be set for any of these tests.
	*
	**-------------------------------------------------------------------------------------------------

	*
	* ordered greater than:
	*	_______
	*	NANvZvN
	*
fdbcc_ogt:	FBOGT.W	fdbcc_ogt_yes		* ordered greater than?
fdbcc_ogt_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ogt_yes:	RTS				* yes; do nothing

	*
	* unordered or less or equal:
	*	_______
	*	NANvZvN
	*
fdbcc_ule:	FBULE.W	fdbcc_ule_yes		* unordered or less or equal?
fdbcc_ule_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ule_yes:	RTS				* yes; do nothing

	*
	* ordered greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
fdbcc_oge:	FBOGE.W	fdbcc_oge_yes		* ordered greater than or equal?
fdbcc_oge_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_oge_yes:	RTS				* yes; do nothing

	*
	* unordered or less than:
	*	       _
	*	NANv(N^Z)
	*
fdbcc_ult:	FBULT.W	fdbcc_ult_yes		* unordered or less than?
fdbcc_ult_no:	BRA.W	fdbcc_false		* no; go handle counter
fdbcc_ult_yes:	RTS				* yes; do nothing

	*
	* ordered less than:
	*	   _____
	*	N^(NANvZ)
	*
fdbcc_olt:	FBOLT.W	fdbcc_olt_yes		* ordered less than?
fdbcc_olt_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_olt_yes:	RTS				* yes; do nothing

	*
	* unordered or greater or equal:
	*
	*	NANvZvN
	*
fdbcc_uge:	FBUGE.W	fdbcc_uge_yes		* unordered or greater than?
fdbcc_uge_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_uge_yes:	RTS				* yes; do nothing

	*
	* ordered less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
fdbcc_ole:	FBOLE.W	fdbcc_ole_yes		* ordered greater or less than?
fdbcc_ole_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ole_yes:	RTS				* yes; do nothing

	*
	* unordered or greater than:
	*	     ___
	*	NANv(NvZ)
	*
fdbcc_ugt:	FBUGT.W	fdbcc_ugt_yes		* unordered or greater than?
fdbcc_ugt_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ugt_yes:	RTS				* yes; do nothing

	*
	* ordered greater or less than:
	*	_____
	*	NANvZ
	*
fdbcc_ogl:	FBOGL.W	fdbcc_ogl_yes		* ordered greater or less than?
fdbcc_ogl_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ogl_yes:	RTS				* yes; do nothing

	*
	* unordered or equal:
	*
	*	NANvZ
	*
fdbcc_ueq:	FBUEQ.W	fdbcc_ueq_yes		* unordered or equal?
fdbcc_ueq_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_ueq_yes:	RTS				* yes; do nothing

	*
	* ordered:
	*	___
	*	NAN
	*
fdbcc_or:	FBOR.W	fdbcc_or_yes		* ordered?
fdbcc_or_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_or_yes:	RTS				* yes; do nothing

	*
	* unordered:
	*
	*	NAN
	*
fdbcc_un:	FBUN.W	fdbcc_un_yes		* unordered?
fdbcc_un_no:	BRA	fdbcc_false		* no; go handle counter
fdbcc_un_yes:	RTS				* yes; do nothing

	**-------------------------------------------------------------------------------
	*
	* the bsun exception bit was not set.
	*
	* (1) subtract 1 from the count register
	* (2) if (cr == -1) then
	*	pc = pc of next instruction
	*     else
	*	pc += sign_ext(16-bit displacement)
	*
fdbcc_false:	MOVE.B	EXC_LV+EXC_OPWORD+1(a6), d1		* fetch lo opword
	ANDI.W	#$7, d1					* extract count register
	BSR	fetch_dreg				* fetch count value

	*----------------------------------------------------------
	* make sure that d0 isn't corrupted between calls...

	SUBQ.W	#$1, d0				* Dn - 1 -> Dn
	BSR	store_dreg_l			* store new count value

	CMP.w	#-1,d0				* is (Dn == -1)?
	BNE	fdbcc_false_cont		* no;
	RTS

fdbcc_false_cont:
	MOVE.L	EXC_LV+L_SCR1(a6),d0		* fetch displacement
	ADD.L	EXC_LV+USER_FPIAR(a6),d0	* add instruction PC
	ADDQ.L	#$4,d0				* add instruction length
	MOVE.l	d0,EXC_PC(a6)			* set new PC
	RTS

	* the emulation routine set bsun and BSUN was enabled. have to
	* fix stack and jump to the bsun handler.
	* let the caller of this routine shift the stack frame up to
	* eliminate the effective address field.
fdbcc_bsun:
	MOVE.B	#fbsun_flg,EXC_LV+SPCOND_FLG(a6)
	RTS
















**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* ftrapcc(): routine to emulate the ftrapcc instruction
**-------------------------------------------------------------------------------------------------
*
* XDEF **
*	_ftrapcc()
*
* xdef **
*	none
*
* INPUT :
*	none
*
* OUTPUT :
*	none
*
* ALGORITHM :
*	This routine checks which conditional predicate is specified by
* the stacked ftrapcc instruction opcode and then branches to a routine
* for that predicate. The corresponding fbcc instruction is then used
* to see whether the condition (specified by the stacked FPSR) is true
* or false.
*	If a BSUN exception should be indicated, the BSUN and ABSUN
* bits are set in the stacked FPSR. If the BSUN exception is enabled,
* the fbsun_flg is set in the EXC_LV+SPCOND_FLG location on the stack. If an
* enabled BSUN should not be flagged and the predicate is true, then
* the ftrapcc_flg is set in the EXC_LV+SPCOND_FLG location. These special
* flags indicate to the calling routine to emulate the exceptional
* condition.
*
**-------------------------------------------------------------------------------------------------

	xdef	_ftrapcc
_ftrapcc:
	DBUG	10,"<ftrapcc>"

	MOVE.W	EXC_LV+EXC_CMDREG(a6),d0	* fetch predicate
	CLR.L	d1				* clear scratch reg
	MOVE.B	EXC_LV+FPSR_CC(a6),d1		* fetch fp ccodes
	ROR.L	#$8,d1				* rotate to top byte
	FMOVE.L	d1,fpsr				* insert into FPSR
	MOVE.W	((tbl_ftrapcc).b,pc,d0.w*2), d1 * load table
	JMP	((tbl_ftrapcc).b,pc,d1.w) 	* jump to ftrapcc routine

tbl_ftrapcc:
	dc.w	ftrapcc_f	-	tbl_ftrapcc	* 00
	dc.w	ftrapcc_eq	-	tbl_ftrapcc	* 01
	dc.w	ftrapcc_ogt	-	tbl_ftrapcc	* 02
	dc.w	ftrapcc_oge	-	tbl_ftrapcc	* 03
	dc.w	ftrapcc_olt	-	tbl_ftrapcc	* 04
	dc.w	ftrapcc_ole	-	tbl_ftrapcc	* 05
	dc.w	ftrapcc_ogl	-	tbl_ftrapcc	* 06
	dc.w	ftrapcc_or	-	tbl_ftrapcc	* 07
	dc.w	ftrapcc_un	-	tbl_ftrapcc	* 08
	dc.w	ftrapcc_ueq	-	tbl_ftrapcc	* 09
	dc.w	ftrapcc_ugt	-	tbl_ftrapcc	* 10
	dc.w	ftrapcc_uge	-	tbl_ftrapcc	* 11
	dc.w	ftrapcc_ult	-	tbl_ftrapcc	* 12
	dc.w	ftrapcc_ule	-	tbl_ftrapcc	* 13
	dc.w	ftrapcc_neq	-	tbl_ftrapcc	* 14
	dc.w	ftrapcc_t	-	tbl_ftrapcc	* 15
	dc.w	ftrapcc_sf	-	tbl_ftrapcc	* 16
	dc.w	ftrapcc_seq	-	tbl_ftrapcc	* 17
	dc.w	ftrapcc_gt	-	tbl_ftrapcc	* 18
	dc.w	ftrapcc_ge	-	tbl_ftrapcc	* 19
	dc.w	ftrapcc_lt	-	tbl_ftrapcc	* 20
	dc.w	ftrapcc_le	-	tbl_ftrapcc	* 21
	dc.w	ftrapcc_gl	-	tbl_ftrapcc	* 22
	dc.w	ftrapcc_gle	-	tbl_ftrapcc	* 23
	dc.w	ftrapcc_ngle	-	tbl_ftrapcc	* 24
	dc.w	ftrapcc_ngl	-	tbl_ftrapcc	* 25
	dc.w	ftrapcc_nle	-	tbl_ftrapcc	* 26
	dc.w	ftrapcc_nlt	-	tbl_ftrapcc	* 27
	dc.w	ftrapcc_nge	-	tbl_ftrapcc	* 28
	dc.w	ftrapcc_ngt	-	tbl_ftrapcc	* 29
	dc.w	ftrapcc_sneq	-	tbl_ftrapcc	* 30
	dc.w	ftrapcc_st	-	tbl_ftrapcc	* 31

	*-----------------------------------------------------------------------------------
	*
	* IEEE Nonaware tests
	*
	* For the IEEE nonaware tests, we set the result based on the
	* floating point condition codes. In addition, we check to see
	* if the NAN bit is set, in which case BSUN and AIOP will be set.
	*
	* The cases EQ and NE are shared by the Aware and Nonaware groups
	* and are incapable of setting the BSUN exception bit.
	*
	* Typically, only one of the two possible branch directions could
	* have the NAN bit set.
	*
	*----------------------------------------------------------------------------------
	*
	* equal:
	*
	*	Z
	*
ftrapcc_eq:	FBEQ.W	ftrapcc_trap	* equal?
ftrapcc_eq_no:	RTS			* do nothing

	*
	* not equal:
	*	_
	*	Z
	*
ftrapcc_neq:	FBNE.W	ftrapcc_trap	* not equal?
ftrapcc_neq_no:	RTS			* do nothing

	*
	* greater than:
	*	_______
	*	NANvZvN
	*
ftrapcc_gt:	FBGT.W	ftrapcc_trap				* greater than?
ftrapcc_gt_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	ftrapcc_gt_done				* no
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6)	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
ftrapcc_gt_done:RTS						* no; do nothing

	*
	* not greater than:
	*
	*	NANvZvN
	*
ftrapcc_ngt:	FBNGT.W	ftrapcc_ngt_yes				* not greater than?
ftrapcc_ngt_no:	RTS						* do nothing
ftrapcc_ngt_yes:BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	ftrapcc_trap				* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
	BRA	ftrapcc_trap				* no; go take trap

	*
	* greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
ftrapcc_ge:	FBGE.W	ftrapcc_ge_yes				* greater than or equal?
ftrapcc_ge_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	ftrapcc_ge_done				* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
ftrapcc_ge_done:RTS						* no; do nothing
ftrapcc_ge_yes:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	ftrapcc_trap				* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
	BRA	ftrapcc_trap				* no; go take trap

	*
	* not (greater than or equal):
	*	       _
	*	NANv(N^Z)
	*
ftrapcc_nge:	FBNGE.W	ftrapcc_nge_yes				* not (greater than or equal)?
ftrapcc_nge_no:	RTS						* do nothing
ftrapcc_nge_yes:BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	ftrapcc_trap				* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
	BRA	ftrapcc_trap				* no; go take trap

	*
	* less than:
	*	   _____
	*	N^(NANvZ)
	*
ftrapcc_lt:	FBLT.W	ftrapcc_trap					* less than?
ftrapcc_lt_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_lt_done					* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
ftrapcc_lt_done:
	RTS							* no; do nothing

	*
	* not less than:
	*	       _
	*	NANv(ZvN)
	*
ftrapcc_nlt:	FBNLT.W	ftrapcc_nlt_yes					* not less than?
ftrapcc_nlt_no:	RTS							* do nothing
ftrapcc_nlt_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_trap					* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
	BRA	ftrapcc_trap					* no; go take trap

	*
	* less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
ftrapcc_le:	FBLE.W	ftrapcc_le_yes					* less than or equal?
ftrapcc_le_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_le_done					* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
ftrapcc_le_done:
	RTS							* no; do nothing
ftrapcc_le_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_trap					* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6)		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
	BRA	ftrapcc_trap					* no; go take trap

	*
	* not (less than or equal):
	*	     ___
	*	NANv(NvZ)
	*
ftrapcc_nle:	FBNLE.W	ftrapcc_nle_yes			* not (less than or equal)?
ftrapcc_nle_no:	RTS					* do nothing
ftrapcc_nle_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	ftrapcc_trap			* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) * was BSUN set?
	BNE	ftrapcc_bsun			* yes
	BRA	ftrapcc_trap			* no; go take trap

	*
	* greater or less than:
	*	_____
	*	NANvZ
	*
ftrapcc_gl:	FBGL.W	ftrapcc_trap					* greater or less than?
ftrapcc_gl_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_gl_done					* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
ftrapcc_gl_done:
	RTS							* no; do nothing

	*
	* not (greater or less than):
	*
	*	NANvZ
	*
ftrapcc_ngl:	FBNGL.W	ftrapcc_ngl_yes					* not (greater or less than)?
ftrapcc_ngl_no:	RTS							* do nothing
ftrapcc_ngl_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)			* is NAN set in cc?
	BEQ	ftrapcc_trap					* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
	BRA	ftrapcc_trap					* no; go take trap

	*
	* greater, less, or equal:
	*	___
	*	NAN
	*
ftrapcc_gle:	FBGLE.W	ftrapcc_trap					* greater, less, or equal?
ftrapcc_gle_no:	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
	RTS							* no; do nothing

	*
	* not (greater, less, or equal):
	*
	*	NAN
	*
ftrapcc_ngle:	FBNGLE.W	ftrapcc_ngle_yes		* not (greater, less, or equal)?
ftrapcc_ngle_no:RTS					* do nothing
ftrapcc_ngle_yes:
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun			* yes
	BRA	ftrapcc_trap			* no; go take trap

	**----------------------------------------------------------------------------------
	* Miscellaneous tests
	*
	* For the IEEE aware tests, we only have to set the result based on the
	* floating point condition codes. The BSUN exception will not be
	* set for any of these tests.
	*
	**----------------------------------------------------------------------------------
	* false:
	*
	*	False
	*
ftrapcc_f:	RTS			* do nothing

	*
	* true:
	*
	*	True
	*
ftrapcc_t:	BRA	ftrapcc_trap		* go take trap

	*
	* signalling false:
	*
	*	False
	*
ftrapcc_sf:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* set BSUN exc bit
	BEQ	ftrapcc_sf_done					* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
ftrapcc_sf_done:
	RTS			* no; do nothing

	*
	* signalling true:
	*
	*	True
	*
ftrapcc_st:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 			* set BSUN exc bit
	BEQ	ftrapcc_trap					* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 		* was BSUN set?
	BNE	ftrapcc_bsun					* yes
	BRA	ftrapcc_trap					* no; go take trap

	*
	* signalling equal:
	*
	*	Z
	*
ftrapcc_seq:	FBSEQ.W	ftrapcc_seq_yes				* signalling equal?
ftrapcc_seq_no:	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* set BSUN exc bit
	BEQ	ftrapcc_seq_done			* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
ftrapcc_seq_done:
	RTS						* no; do nothing
ftrapcc_seq_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* set BSUN exc bit
	BEQ	ftrapcc_trap				* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
	BRA	ftrapcc_trap				* no; go take trap

	*
	* signalling not equal:
	*	_
	*	Z
	*
ftrapcc_sneq:	FBSNE.W	ftrapcc_sneq_yes			* signalling equal?
ftrapcc_sneq_no:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* set BSUN exc bit
	BEQ	ftrapcc_sneq_no_done			* no; go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE.W	ftrapcc_bsun				* yes
ftrapcc_sneq_no_done:
	RTS						* do nothing
ftrapcc_sneq_yes:
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* set BSUN exc bit
	BEQ	ftrapcc_trap				* no; go take trap
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BTST	#bsun_bit, EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	ftrapcc_bsun				* yes
	BRA	ftrapcc_trap				* no; go take trap

	**-----------------------------------------------------------------------------------
	*
	* IEEE Aware tests
	*
	* For the IEEE aware tests, we only have to set the result based on the
	* floating point condition codes. The BSUN exception will not be
	* set for any of these tests.
	*
	**-----------------------------------------------------------------------------------
	*
	* ordered greater than:
	*	_______
	*	NANvZvN
	*
ftrapcc_ogt:	FBOGT.W	ftrapcc_trap	* ordered greater than?
ftrapcc_ogt_no:	RTS			* do nothing

	*
	* unordered or less or equal:
	*	_______
	*	NANvZvN
	*
ftrapcc_ule:	FBULE.w	ftrapcc_trap	* unordered or less or equal?
ftrapcc_ule_no:	RTS			* do nothing

	*
	* ordered greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
ftrapcc_oge:	FBOGE.W	ftrapcc_trap	* ordered greater than or equal?
ftrapcc_oge_no:	RTS			* do nothing

	*
	* unordered or less than:
	*	       _
	*	NANv(N^Z)
	*
ftrapcc_ult:	FBULT.W	ftrapcc_trap	* unordered or less than?
ftrapcc_ult_no:	RTS			* do nothing

	*
	* ordered less than:
	*	   _____
	*	N^(NANvZ)
	*
ftrapcc_olt:	FBOLT.W	ftrapcc_trap	* ordered less than?
ftrapcc_olt_no:	RTS			* do nothing

	*
	* unordered or greater or equal:
	*
	*	NANvZvN
	*
ftrapcc_uge:	FBUGE.W	ftrapcc_trap	* unordered or greater than?
ftrapcc_uge_no:	RTS			* do nothing

	*
	* ordered less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
ftrapcc_ole:	FBOLE.W	ftrapcc_trap	* ordered greater or less than?
ftrapcc_ole_no:	RTS			* do nothing

	*
	* unordered or greater than:
	*	     ___
	*	NANv(NvZ)
	*
ftrapcc_ugt:	FBUGT.W	ftrapcc_trap	* unordered or greater than?
ftrapcc_ugt_no:	RTS			* do nothing

	*
	* ordered greater or less than:
	*	_____
	*	NANvZ
	*
ftrapcc_ogl:	FBOGL.W	ftrapcc_trap	* ordered greater or less than?
ftrapcc_ogl_no:	RTS			* do nothing

	*
	* unordered or equal:
	*
	*	NANvZ
	*
ftrapcc_ueq:	FBUEQ.W	ftrapcc_trap	* unordered or equal?
ftrapcc_ueq_no:	RTS			* do nothing

	*
	* ordered:
	*	___
	*	NAN
	*
ftrapcc_or:	FBOR.w	ftrapcc_trap	* ordered?
ftrapcc_or_no:	RTS			* do nothing

	*
	* unordered:
	*
	*	NAN
	*
ftrapcc_un:	FBUN.w	ftrapcc_trap	* unordered?
ftrapcc_un_no:	RTS			* do nothing

	*********************************************************************
	* the bsun exception bit was not set.
	* we will need to jump to the ftrapcc vector. the stack frame
	* is the same size as that of the fp unimp instruction. the
	* only difference is that the <ea> field should hold the PC
	* of the ftrapcc instruction and the vector offset field
	* should denote the ftrapcc trap.

ftrapcc_trap:
	MOVE.B	#ftrapcc_flg,EXC_LV+SPCOND_FLG(a6)
	RTS

	* the emulation routine set bsun and BSUN was enabled. have to
	* fix stack and jump to the bsun handler.
	* let the caller of this routine shift the stack frame up to
	* eliminate the effective address field.
ftrapcc_bsun:
	MOVE.B	#fbsun_flg,EXC_LV+SPCOND_FLG(a6)
	RTS












**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* fscc(): routine to emulate the fscc instruction
**-------------------------------------------------------------------------------------------------
*
* XDEF ** *
*	_fscc()
*
* xdef ** *
*	store_dreg_b() - store result to data register file
*	dec_areg() - decrement an areg for -(an) mode
*	inc_areg() - increment an areg for (an)+ mode
*	_dmem_write_byte() - store result to memory
*
* INPUT ***************************************************************
*	none
*
* OUTPUT ************************************************************** *
*	none
*
* ALGORITHM ***********************************************************
*	This routine checks which conditional predicate is specified by
* the stacked fscc instruction opcode and then branches to a routine
* for that predicate. The corresponding fbcc instruction is then used
* to see whether the condition (specified by the stacked FPSR) is true
* or false.
*	If a BSUN exception should be indicated, the BSUN and ABSUN
* bits are set in the stacked FPSR. If the BSUN exception is enabled,
* the fbsun_flg is set in the EXC_LV+SPCOND_FLG location on the stack. If an
* enabled BSUN should not be flagged and the predicate is true, then
* the result is stored to the data register file or memory
*
**-------------------------------------------------------------------------------------------------

	xdef	_fscc
_fscc:
	DBUG	10,"<fscc>"

	MOVE.W	EXC_LV+EXC_CMDREG(a6),d0	* fetch predicate
	CLR.L	d1				* clear scratch reg
	MOVE.B	EXC_LV+FPSR_CC(a6),d1		* fetch fp ccodes
	ROR.L	#$8,d1				* rotate to top byte
	FMOVE.L	d1,fpsr				* insert into FPSR
	MOVE.W	((tbl_fscc).b,pc,d0.w*2),d1 	* load table
	JMP	((tbl_fscc).b,pc,d1.w) 		* jump to fscc routine

tbl_fscc:
	dc.w	fscc_f		-	tbl_fscc	* 00
	dc.w	fscc_eq		-	tbl_fscc	* 01
	dc.w	fscc_ogt	-	tbl_fscc	* 02
	dc.w	fscc_oge	-	tbl_fscc	* 03
	dc.w	fscc_olt	-	tbl_fscc	* 04
	dc.w	fscc_ole	-	tbl_fscc	* 05
	dc.w	fscc_ogl	-	tbl_fscc	* 06
	dc.w	fscc_or		-	tbl_fscc	* 07
	dc.w	fscc_un		-	tbl_fscc	* 08
	dc.w	fscc_ueq	-	tbl_fscc	* 09
	dc.w	fscc_ugt	-	tbl_fscc	* 10
	dc.w	fscc_uge	-	tbl_fscc	* 11
	dc.w	fscc_ult	-	tbl_fscc	* 12
	dc.w	fscc_ule	-	tbl_fscc	* 13
	dc.w	fscc_neq	-	tbl_fscc	* 14
	dc.w	fscc_t		-	tbl_fscc	* 15
	dc.w	fscc_sf		-	tbl_fscc	* 16
	dc.w	fscc_seq	-	tbl_fscc	* 17
	dc.w	fscc_gt		-	tbl_fscc	* 18
	dc.w	fscc_ge		-	tbl_fscc	* 19
	dc.w	fscc_lt		-	tbl_fscc	* 20
	dc.w	fscc_le		-	tbl_fscc	* 21
	dc.w	fscc_gl		-	tbl_fscc	* 22
	dc.w	fscc_gle	-	tbl_fscc	* 23
	dc.w	fscc_ngle	-	tbl_fscc	* 24
	dc.w	fscc_ngl	-	tbl_fscc	* 25
	dc.w	fscc_nle	-	tbl_fscc	* 26
	dc.w	fscc_nlt	-	tbl_fscc	* 27
	dc.w	fscc_nge	-	tbl_fscc	* 28
	dc.w	fscc_ngt	-	tbl_fscc	* 29
	dc.w	fscc_sneq	-	tbl_fscc	* 30
	dc.w	fscc_st		-	tbl_fscc	* 31

	*----------------------------------------------------------------------------
	*
	* IEEE Nonaware tests
	*
	* For the IEEE nonaware tests, we set the result based on the
	* floating point condition codes. In addition, we check to see
	* if the NAN bit is set, in which case BSUN and AIOP will be set.
	*
	* The cases EQ and NE are shared by the Aware and Nonaware groups
	* and are incapable of setting the BSUN exception bit.
	*
	* Typically, only one of the two possible branch directions could
	* have the NAN bit set.
	*
	*----------------------------------------------------------------------------------

	*
	* equal:
	*
	*	Z
	*
fscc_eq:	FBEQ.W	fscc_eq_yes		* equal?
fscc_eq_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_eq_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* not equal:
	*	_
	*	Z
	*
fscc_neq:	FBNE.W	fscc_neq_yes		* not equal?
fscc_neq_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_neq_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* greater than:
	*	_______
	*	NANvZvN
	*
fscc_gt:	FBGT.W	fscc_gt_yes		* greater than?
fscc_gt_no:	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_gt_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* not greater than:
	*
	*	NANvZvN
	*
fscc_ngt:	FBNGT.W	fscc_ngt_yes		* not greater than?
fscc_ngt_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ngt_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
fscc_ge:	FBGE.W	fscc_ge_yes		* greater than or equal?
fscc_ge_no:	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_ge_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* not (greater than or equal):
	*	       _
	*	NANv(N^Z)
	*
fscc_nge:	FBNGE.W	fscc_nge_yes		* not (greater than or equal)?
fscc_nge_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_nge_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.l	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* less than:
	*	   _____
	*	N^(NANvZ)
	*
fscc_lt:	FBLT.W	fscc_lt_yes		* less than?
fscc_lt_no:	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_lt_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* not less than:
	*	       _
	*	NANv(ZvN)
	*
fscc_nlt:	FBNLT.W	fscc_nlt_yes		* not less than?
fscc_nlt_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_nlt_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
fscc_le:	FBLE.W	fscc_le_yes			* less than or equal?
fscc_le_no:	CLR.B	d0				* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done			* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun			* go finish
fscc_le_yes:
	ST	d0				* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done			* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun			* go finish

	*
	* not (less than or equal):
	*	     ___
	*	NANv(NvZ)
	*
fscc_nle:	FBNLE.W	fscc_nle_yes		* not (less than or equal)?
fscc_nle_no:	CLR.B	d0		* set false
	BRA	fscc_done		* go finish
fscc_nle_yes:	ST	d0		* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)	* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* greater or less than:
	*	_____
	*	NANvZ
	*
fscc_gl:	FBGL.W	fscc_gl_yes		* greater or less than?
fscc_gl_no:	CLR.B	d0		* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_gl_yes:	ST	d0		* set true
	BRA	fscc_done		* go finish

	*
	* not (greater or less than):
	*
	*	NANvZ
	*
fscc_ngl:	FBNGL.W	fscc_ngl_yes		* not (greater or less than)?
fscc_ngl_no:	CLR.B	d0		* set false
	BRA	fscc_done		* go finish
fscc_ngl_yes:	ST	d0		* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6)		* is NAN set in cc?
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* greater, less, or equal:
	*	___
	*	NAN
	*
fscc_gle:	FBGLE.W	fscc_gle_yes		* greater, less, or equal?
fscc_gle_no:    CLR.B	d0			* set false
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_gle_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* not (greater, less, or equal):
	*
	*	NAN
	*
fscc_ngle:	FBNGLE.W	fscc_ngle_yes		* not (greater, less, or equal)?
fscc_ngle_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ngle_yes:	ST	d0			* set true
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	**-------------------------------------------------------------------------------------------------
	*
	* Miscellaneous tests
	*
	* For the IEEE aware tests, we only have to set the result based on the
	* floating point condition codes. The BSUN exception will not be
	* set for any of these tests.
	*
	**-------------------------------------------------------------------------------------------------
	*
	* false:
	*
	*	False
	*
fscc_f:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish

	*
	* true:
	*
	*	True
	*
fscc_t:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* signalling false:
	*
	*	False
	*
fscc_sf:
	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 	* set BSUN exc bit
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* signalling true:
	*
	*	True
	*
fscc_st:	ST	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 	* set BSUN exc bit
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* signalling equal:
	*
	*	Z
	*
fscc_seq:	FBSEQ.W	fscc_seq_yes		* signalling equal?
fscc_seq_no:	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 	* set BSUN exc bit
	BEQ	fscc_done		* no;go finish
	ORI.l	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_seq_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 	* set BSUN exc bit
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	*
	* signalling not equal:
	*	_
	*	Z
	*
fscc_sneq:	FBSNE.W	fscc_sneq_yes		* signalling equal?
fscc_sneq_no:	CLR.B	d0			* set false
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 		* set BSUN exc bit
	BEQ	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) 	* set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish
fscc_sneq_yes:	ST	d0			* set true
	BTST	#nan_bit, EXC_LV+FPSR_CC(a6) 	* set BSUN exc bit
	BEQ.W	fscc_done		* no;go finish
	ORI.L	#bsun_mask+aiop_mask, EXC_LV+USER_FPSR(a6) * set BSUN exc bit
	BRA	fscc_chk_bsun		* go finish

	**--------------------------------------------------------------------------------
	*
	* IEEE Aware tests
	*
	* For the IEEE aware tests, we only have to set the result based on the
	* floating point condition codes. The BSUN exception will not be
	* set for any of these tests.
	*
	**------------------------------------------------------------------------------

	*
	* ordered greater than:
	*	_______
	*	NANvZvN
	*
fscc_ogt:	FBOGT.W	fscc_ogt_yes		* ordered greater than?
fscc_ogt_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ogt_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered or less or equal:
	*	_______
	*	NANvZvN
	*
fscc_ule:	FBULE.W	fscc_ule_yes		* unordered or less or equal?
fscc_ule_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ule_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* ordered greater than or equal:
	*	   _____
	*	Zv(NANvN)
	*
fscc_oge:	FBOGE.W	fscc_oge_yes		* ordered greater than or equal?
fscc_oge_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_oge_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered or less than:
	*	       _
	*	NANv(N^Z)
	*
fscc_ult:	FBULT.W	fscc_ult_yes		* unordered or less than?
fscc_ult_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ult_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* ordered less than:
	*	   _____
	*	N^(NANvZ)
	*
fscc_olt:	FBOLT.W	fscc_olt_yes		* ordered less than?
fscc_olt_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_olt_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered or greater or equal:
	*
	*	NANvZvN
	*
fscc_uge:	FBUGE.W	fscc_uge_yes		* unordered or greater than?
fscc_uge_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_uge_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* ordered less than or equal:
	*	     ___
	*	Zv(N^NAN)
	*
fscc_ole:	FBOLE.W	fscc_ole_yes		* ordered greater or less than?
fscc_ole_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ole_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered or greater than:
	*	     ___
	*	NANv(NvZ)
	*
fscc_ugt:    	FBUGT.W	fscc_ugt_yes		* unordered or greater than?
fscc_ugt_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ugt_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* ordered greater or less than:
	*	_____
	*	NANvZ
	*
fscc_ogl:    	FBOGL.w	fscc_ogl_yes		* ordered greater or less than?
fscc_ogl_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ogl_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered or equal:
	*
	*	NANvZ
	*
fscc_ueq:	FBUEQ.W	fscc_ueq_yes		* unordered or equal?
fscc_ueq_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_ueq_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* ordered:
	*	___
	*	NAN
	*
fscc_or:	FBOR.W	fscc_or_yes		* ordered?
fscc_or_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_or_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*
	* unordered:
	*
	*	NAN
	*
fscc_un:    	FBUN.W	fscc_un_yes		* unordered?
fscc_un_no:	CLR.B	d0			* set false
	BRA	fscc_done		* go finish
fscc_un_yes:	ST	d0			* set true
	BRA	fscc_done		* go finish

	*	********

	*
	* the bsun exception bit was set. now, check to see is BSUN
	* is enabled. if so, don't store result and correct stack frame
	* for a bsun exception.
	*
fscc_chk_bsun:
	BTST	#bsun_bit,EXC_LV+FPCR_ENABLE(a6) 	* was BSUN set?
	BNE	fscc_bsun

	*
	* the bsun exception bit was not set.
	* the result has been selected.
	* now, check to see if the result is to be stored in the data register
	* file or in memory.
	*
fscc_done:
	MOVE.L	d0,a0			* save result for a moment

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1		* fetch lo opword
	MOVE.L	d1,d0					* make a copy
	ANDI.B	#$38,d1			* extract src mode

	BNE	fscc_mem_op		* it's a memory operation

	MOVE.L	d0,d1
	ANDI.W	#$7,d1			* pass index in d1
	MOVE.L	a0,d0			* pass result in d0
	BSR	store_dreg_b		* save result in regfile
	RTS

	*
	* the stacked <ea> is correct with the exception of:
	* 	-> Dn : <ea> is garbage
	*
	* if the addressing mode is post-increment or pre-decrement,
	* then the address registers have not been updated.
	*
fscc_mem_op:
	CMP.b	#$18,d1		* is <ea> (An)+ ?
	BEQ	fscc_mem_inc	* yes

	CMP.b	#$20,d1		* is <ea> -(An) ?
	BEQ	fscc_mem_dec	* yes

	MOVE.L	a0,d0		* pass result in d0
	MOVE.L	EXC_EA(a6),a0	* fetch <ea>
	MOVE.B          d0,(a0)
	RTS

	* addresing mode is post-increment. write the result byte. if the write
	* fails then don't update the address register. if write passes then
	* call inc_areg() to update the address register.
fscc_mem_inc:
	MOVE.L	a0,d0		* pass result in d0
	MOVE.L	EXC_EA(a6),a0	* fetch <ea>
	MOVE.B          d0,(a0)

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* fetch opword
	ANDI.W	#$7,d1				* pass index in d1
	MOVEQ.L	#$1,d0				* pass amt to inc by
	BSR	inc_areg			* increment address register
	RTS

	* addressing mode is pre-decrement. write the result byte. if the write
	* fails then don't update the address register. if the write passes then
	* call dec_areg() to update the address register.

fscc_mem_dec:	MOVE.L	a0,d0			* pass result in d0
	MOVE.L	EXC_EA(a6),a0		* fetch <ea>
                MOVE.B	d0,(a0)

	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* fetch opword
	ANDI.W	#$7,d1		* pass index in d1
	MOVEQ.L	#$1,d0		* pass amt to dec by
	BSR	dec_areg	* decrement address register
	RTS

	* the emulation routine set bsun and BSUN was enabled. have to
	* fix stack and jump to the bsun handler.
	* let the caller of this routine shift the stack frame up to
	* eliminate the effective address field.
fscc_bsun:
	MOVE.B	#fbsun_flg,EXC_LV+SPCOND_FLG(a6)
	RTS

	* the byte write to memory has failed. pass the failing effective address
	* and a FSLW to funimp_dacc().
	*fscc_err:
	*	move.w	#$00a1,EXC_VOFF(a6)
	*	bra	facc_finish


**--------------------------------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------------------------------

