
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
** Soweit durch...

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

**-------------------------------------------------------------------------------------------------


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* XDEF :	inc_areg(): increment an address register by the value in d0
**-------------------------------------------------------------------------------------------------
*
* XREF:
*	None
*
* INPUT :
*	d0 = amount to increment by
*	d1 = index of address register to increment
*
* OUTPUT :
*	(address register is updated)
*
* ALGORITHM:
*

*  Typically  used  for  an  instruction  w/  a  post-increment  <ea>,  this routine adds the
* increment  value  in d0 to the address register specified by d1.  A0/A1/A6/A7 reside on the
* stack.  The rest reside in their original places.
*
*  For  a7,  if  the  increment  amount is one, then we have to increment by two.  For any a7
* update,  set  the mia7_flag so that if an access error exception occurs later in emulation,
* this address register update can be undone.
*
*-------------------------------------------------------------------------------------------------

	xdef	inc_areg
inc_areg:	MOVE.W	((tbl_iareg).b,pc,d1.w*2),d1
	JMP	((tbl_iareg).b,pc,d1.w*1)

tbl_iareg:	dc.w	iareg0 - tbl_iareg
	dc.w	iareg1 - tbl_iareg
	dc.w	iareg2 - tbl_iareg
	dc.w	iareg3 - tbl_iareg
	dc.w	iareg4 - tbl_iareg
	dc.w	iareg5 - tbl_iareg
	dc.w	iareg6 - tbl_iareg
	dc.w	iareg7 - tbl_iareg

iareg0:	ADD.L	d0,EXC_LV+EXC_A0(a6)
	RTS
iareg1:	ADD.L	d0,EXC_LV+EXC_A1(a6)
	RTS
iareg2:	ADD.L	d0,a2
	RTS
iareg3:	ADD.L	d0,a3
	RTS
iareg4:	ADD.L	d0,a4
	RTS
iareg5:	ADD.L	d0,a5
	RTS
iareg6:	ADD.L	d0,(a6)
	RTS
iareg7:	MOVE.B	#mia7_flg,EXC_LV+SPCOND_FLG(a6)
	CMP.b	#1,d0
	BEQ	iareg7b
	ADD.L	d0,EXC_LV+EXC_A7(a6)
	RTS
iareg7b:	ADDQ.L	#$2,EXC_LV+EXC_A7(a6)
	RTS

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** XDEF :	dec_areg(): decrement an address register by the value in d0
**-------------------------------------------------------------------------------------------------
* XREF
*	None
*
* INPUT :
*	d0 = amount to decrement by
*	d1 = index of address register to decrement
*
* OUTPUT :
*	(address register is updated)
*
* ALGORITHM :
*
*  Typically used for an instruction w/ a pre-decrement <ea>, this routine adds the decrement
* value in d0 to the address register specified by d1.  A0/A1/A6/A7 reside on the stack.  The
* rest reside in their original places.
*
*  For  a7,  if  the  decrement  amount is one, then we have to decrement by two.  For any a7
* update,  set  the mda7_flag so that if an access error exception occurs later in emulation,
* this address register update can be undone.
*
**-------------------------------------------------------------------------------------------------

	xdef	dec_areg
dec_areg:	MOVE.W	((tbl_dareg).b,pc,d1.w*2),d1
	JMP	((tbl_dareg).b,pc,d1.w*1)

tbl_dareg:
	dc.w	dareg0 - tbl_dareg
	dc.w	dareg1 - tbl_dareg
	dc.w	dareg2 - tbl_dareg
	dc.w	dareg3 - tbl_dareg
	dc.w	dareg4 - tbl_dareg
	dc.w	dareg5 - tbl_dareg
	dc.w	dareg6 - tbl_dareg
	dc.w	dareg7 - tbl_dareg

dareg0:	SUB.L	d0,EXC_LV+EXC_A0(a6)
	RTS
dareg1:	SUB.L	d0,EXC_LV+EXC_A1(a6)
	RTS
dareg2:	SUB.L	d0,a2
	RTS
dareg3:	SUB.L	d0,a3
	RTS
dareg4:	SUB.L	d0,a4
	RTS
dareg5:	SUB.L	d0,a5
	RTS
dareg6:	SUB.L	d0,(a6)
	RTS
dareg7:	MOVE.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	CMP.B	#1,d0
	BEQ	dareg7b
	SUB.L	d0,EXC_LV+EXC_A7(a6)
	RTS
dareg7b:	SUBQ.L	#$2,EXC_LV+EXC_A7(a6)
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	_dcalc_ea(): calc correct <ea> from <ea> stacked on exception
**-------------------------------------------------------------------------------------------------
*
* XREF:	inc_areg() - increment an address register
*	dec_areg() - decrement an address register
*
* INPUT :
*	d0 = number of bytes to adjust <ea> by
*
* OUTPUT :
*	None
*
* ALGORITHM :
*
* "Dummy" CALCulate Effective Address:
* 	The stacked <ea> for FP unimplemented instructions and opclass
*	two packed instructions is correct with the exception of...
*
*	1) -(An)   : The register is not updated regardless of size.
*	     Also, for extended precision and packed, the
*	     stacked <ea> value is 8 bytes too big
*	2) (An)+   : The register is not updated.
*	3) *<data> : The upper longword of the immediate operand is
*	     stacked b,w,l and s sizes are completely stacked.
*	     d,x, and p are not.
*
**-------------------------------------------------------------------------------------------------

_dcalc_ea:	MOVE.L	d0, a0				* move * bytes to a0
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6), d0	* fetch opcode word
	MOVE.L	d0, d1				* make a copy

	ANDI.W	#$38, d0			* extract mode field
	ANDI.L	#$7, d1				* extract reg  field

	CMP.b	#$18,d0				* is mode (An)+ ?
	BEQ	dcea_pi				* yes

	CMP.b	#$20,d0				* is mode -(An) ?
	BEQ	dcea_pd				* yes

	OR.W	d1,d0				* concat mode,reg
	CMP.b	#$3c,d0				* is mode *<data>?

	BEQ	dcea_imm			* yes

	MOVE.L	EXC_EA(a6),a0			* return <ea>
	RTS

                **--------------------------------------------------------------------------------
	* need to set immediate data flag here since we'll need to do
	* an imem_read to fetch this later.
dcea_imm:
	MOVE.B	#immed_flg,EXC_LV+SPCOND_FLG(a6)
	LEA	([EXC_LV+USER_FPIAR,a6],$4),a0 * no; return <ea>
	RTS

                **--------------------------------------------------------------------------------
	* here, the <ea> is stacked correctly. however, we must update the
	* address register...
dcea_pi:
	MOVE.L	a0,d0		* pass amt to inc by
	BSR	inc_areg	* inc addr register
	MOVE.L	EXC_EA(a6),a0	* stacked <ea> is correct
	RTS

                **--------------------------------------------------------------------------------
	* the <ea> is stacked correctly for all but extended and packed which
	* the <ea>s are 8 bytes too large.
	* it would make no sense to have a pre-decrement to a7 in supervisor
	* mode so we don't even worry about this tricky case here : )
dcea_pd:
	MOVE.L	a0,d0		* pass amt to dec by
	BSR	dec_areg	* dec addr register

	MOVE.L	EXC_EA(a6),a0	* stacked <ea> is correct
	CMP.B	#12,d0		* is opsize ext or packed?
	BEQ	dcea_pd2	* yes
	RTS
dcea_pd2:	SUB.L	#$8,a0		* correct <ea>
	MOVE.L	a0,EXC_EA(a6)	* put correct <ea> on stack
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** XDEF : 	_calc_ea_fout(): calculate correct stacked <ea> for extended
**	 and packed data opclass 3 operations.
**-------------------------------------------------------------------------------------------------
*
* XREF :	None
*
* INPUT :
*	None
*
* OUTPUT :
*	a0 = return correct effective address
*
* ALGORITHM :
*
*  For  opclass  3 extended and packed data operations, the <ea> stacked for the exception is
* incorrect  for  -(an)  and  (an)+  addressing  modes.   Also,  while we're at it, the index
* register itself must get updated.
*
*  So,  for  -(an), we must subtract 8 off of the stacked <ea> value and return that value as
* the correct <ea> and store that value in An.  For (an)+, the stacked <ea> is correct but we
* must adjust An by +12.
**-------------------------------------------------------------------------------------------------

	**---------------------------------------------------------------------------------
	* This calc_ea is currently used to retrieve the correct <ea>
	* for fmove outs of type extended and packed.

	xdef	_calc_ea_fout
_calc_ea_fout:
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d0	* fetch opcode word
	MOVE.L	d0,d1				* make a copy

	ANDI.W	#$38,d0				* extract mode field
	ANDI.L	#$7,d1				* extract reg  field

	CMP.b	#$18,d0				* is mode (An)+ ?
	BEQ	ceaf_pi				* yes

	CMP.b	#$20,d0				* is mode -(An) ?
	BEQ	ceaf_pd				* yes

	MOVE.L	EXC_EA(a6),a0			* stacked <ea> is correct
	RTS

	**---------------------------------------------------------------------------------
	* (An)+ : extended and packed fmove out
	*	: stacked <ea> is correct
	*	: "An" not updated
ceaf_pi:
	MOVE.W	((tbl_ceaf_pi).b,pc,d1.w*2),d1
	MOVE.L	EXC_EA(a6),a0
	JMP	((tbl_ceaf_pi).b,pc,d1.w*1)
tbl_ceaf_pi:
	dc.w	ceaf_pi0 - tbl_ceaf_pi
	dc.w	ceaf_pi1 - tbl_ceaf_pi
	dc.w	ceaf_pi2 - tbl_ceaf_pi
	dc.w	ceaf_pi3 - tbl_ceaf_pi
	dc.w	ceaf_pi4 - tbl_ceaf_pi
	dc.w	ceaf_pi5 - tbl_ceaf_pi
	dc.w	ceaf_pi6 - tbl_ceaf_pi
	dc.w	ceaf_pi7 - tbl_ceaf_pi

ceaf_pi0:   	ADDI.L	#$c,EXC_LV+EXC_A0(a6)
	RTS
ceaf_pi1:	ADDI.L	#$c,EXC_LV+EXC_A1(a6)
	RTS
ceaf_pi2:	ADD.L	#$c,a2
	RTS
ceaf_pi3:	ADD.L	#$c,a3
	RTS
ceaf_pi4:	ADD.L	#$c,a4
	RTS
ceaf_pi5:	ADD.L	#$c,a5
	RTS
ceaf_pi6:	ADDI.L	#$c,EXC_LV+EXC_A6(a6)
	RTS
ceaf_pi7:	MOVE.B	#mia7_flg,EXC_LV+SPCOND_FLG(a6)
	ADDI.L	#$c,EXC_LV+EXC_A7(a6)
	RTS

	**----------------------------------------------------------------------------------
	* -(An) : extended and packed fmove out
	*	: stacked <ea> = actual <ea> + 8
	*	: "An" not updated
ceaf_pd:
	MOVE.W	((tbl_ceaf_pd).b,pc,d1.w*2),d1
	MOVE.L	EXC_EA(a6),a0
	SUB.L	#$8,a0
	SUB.L	#$8,EXC_EA(a6)
	JMP	((tbl_ceaf_pd).b,pc,d1.w*1)
tbl_ceaf_pd:
	dc.w	ceaf_pd0 - tbl_ceaf_pd
	dc.w	ceaf_pd1 - tbl_ceaf_pd
	dc.w	ceaf_pd2 - tbl_ceaf_pd
	dc.w	ceaf_pd3 - tbl_ceaf_pd
	dc.w	ceaf_pd4 - tbl_ceaf_pd
	dc.w	ceaf_pd5 - tbl_ceaf_pd
	dc.w	ceaf_pd6 - tbl_ceaf_pd
	dc.w	ceaf_pd7 - tbl_ceaf_pd

ceaf_pd0:	MOVE.L	a0,EXC_LV+EXC_A0(a6)
	RTS
ceaf_pd1:	MOVE.L	a0,EXC_LV+EXC_A1(a6)
	RTS
ceaf_pd2:	MOVE.L	a0,a2
	RTS
ceaf_pd3:  	MOVE.L	a0,a3
	RTS
ceaf_pd4:	MOVE.L	a0,a4
	RTS
ceaf_pd5:	MOVE.L	a0,a5
	RTS
ceaf_pd6:	MOVE.L	a0,EXC_LV+EXC_A6(a6)
	RTS
ceaf_pd7:	MOVE.L	a0,EXC_LV+EXC_A7(a6)
	MOVE.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	RTS




**-------------------------------------------------------------------------------------------------*****
**-------------------------------------------------------------------------------------------------*****
**-------------------------------------------------------------------------------------------------*****
**-------------------------------------------------------------------------------------------------*****
**-------------------------------------------------------------------------------------------------*****
**-------------------------------------------------------------------------------------------------*****





**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* fetch_from_mem():
* - called by _load_fop
* - src is out in memory. must:
*	(1) calc ea - must read AFTER you know the src type since
*	      if the ea is -() or ()+, need to know * of bytes.
*	(2) read it in from either user or supervisor space
*	(3) if (b || w || l) then simply read in
*	    if (s || d || x) then check for SNAN,UNNORM,DENORM
*	    if (packed) then punt for now
* INPUT:
*	d0 : src type field
**-------------------------------------------------------------------------------------------------

fetch_from_mem:
	CLR.B	EXC_LV+STAG(a6)				* either NORM or ZERO
	MOVE.W	((tbl_exc_fp__type).b,pc,d0.w*2), d0 	* index by src type field
	JMP	((tbl_exc_fp__type).b,pc,d0.w*1)

tbl_exc_fp__type:
	dc.w	load_long	- tbl_exc_fp__type
	dc.w	load_sgl	- tbl_exc_fp__type
	dc.w	load_ext	- tbl_exc_fp__type
	dc.w	load_packed	- tbl_exc_fp__type
	dc.w	load_word	- tbl_exc_fp__type
	dc.w	load_dbl	- tbl_exc_fp__type
	dc.w	load_byte	- tbl_exc_fp__type
	dc.w	tbl_exc_fp__type	- tbl_exc_fp__type

	**--------------------------------------------------------------------------------
	* load a LONG into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 4 bytes into EXC_LV+L_SCR1
	*	(3) fmove.l into fp0

load_long:	MOVEQ.L	#$4, d0			* pass: 4 (bytes)
	BSR	_dcalc_ea		* calc <ea>; <ea> in a0

	MOVE.L	(a0),d0        		* fetch src operand from memory

	FMOVE.L	d0, fp0			* read into fp0;convert to xprec
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ	load_long_zero		* src op is a ZERO
	RTS
load_long_zero:	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set optype tag to ZERO
	RTS

	**--------------------------------------------------------------------------------
	* load a WORD into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 2 bytes into EXC_LV+L_SCR1
	*	(3) fmove.w into fp0

load_word:
	MOVEQ.L	#$2, d0			* pass: 2 (bytes)
	BSR	_dcalc_ea		* calc <ea>; <ea> in a0

	MOVE.W	(a0),d0

load_word_cont:	FMOVE.W	d0, fp0			* read into fp0;convert to xprec
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ	load_word_zero		* src op is a ZERO
	RTS
load_word_zero:	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set optype tag to ZERO
	RTS


	**--------------------------------------------------------------------------------
	* load a BYTE into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 1 byte into EXC_LV+L_SCR1
	*	(3) fmove.b into fp0

load_byte:	MOVEQ.l	#$1, d0			* pass: 1 (byte)
	BSR	_dcalc_ea		* calc <ea>; <ea> in a0

	MOVE.B	(A0),d0
load_byte_cont:
	FMOVE.B	d0, fp0			* read into fp0;convert to xprec
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ.W	load_byte_zero		* src op is a ZERO
	RTS
load_byte_zero:	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set optype tag to ZERO
	RTS

	**--------------------------------------------------------------------------------
	* load a SGL into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 4 bytes into EXC_LV+L_SCR1
	*	(3) fmove.s into fp0
load_sgl:
	MOVEQ.l	#$4, d0			* pass: 4 (bytes)
	BSR	_dcalc_ea		* calc <ea>; <ea> in a0

	MOVE.L	(a0),d0
	MOVE.l	d0, EXC_LV+L_SCR1(a6)	* store src op on stack

	LEA	EXC_LV+L_SCR1(a6), a0	* pass: ptr to sgl src op
	BSR	set_tag_s		* determine src type tag
	MOVE.B	d0, EXC_LV+STAG(a6)	* save src optype tag on stack

	CMP.b	#DENORM,d0		* is it a sgl DENORM?
	BEQ	get_sgl_denorm		* yes

	CMP.b	#SNAN,d0		* is it a sgl SNAN?
	BEQ	get_sgl_snan		* yes

	FMOVE.S	EXC_LV+L_SCR1(a6), fp0	* read into fp0;convert to xprec
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	rts

	**--------------------------------------------------------------------------------
	* must convert sgl denorm format to an Xprec denorm fmt suitable for
	* normalization...
	* a0 : points to sgl denorm
get_sgl_denorm:
	CLR.W	EXC_LV+FP_SRC_EX(a6)
	BFEXTU	(a0){9:23}, d0			* fetch sgl hi(_mantissa)
	LSL.L	#$8, d0
	MOVE.L	d0, EXC_LV+FP_SRC_HI(a6)	* set ext hi(_mantissa)
	CLR.L	EXC_LV+FP_SRC_LO(a6)		* set ext lo(_mantissa)

	CLR.W	EXC_LV+FP_SRC_EX(a6)
	BTST	#$7,(a0)			* is sgn bit set?
	BEQ	sgl_dnrm_norm
	BSET	#$7,EXC_LV+FP_SRC_EX(a6)	* set sgn of xprec value

sgl_dnrm_norm:
	LEA	EXC_LV+FP_SRC(a6), a0
	BSR	norm				* normalize number
	MOVE.W	#$3f81, d1			* xprec exp = $3f81
	SUB.W	d0, d1				* exp = $3f81 - shft amt.
	OR.W	d1, EXC_LV+FP_SRC_EX(a6)	* {sgn,exp}
	MOVE.B	#NORM, EXC_LV+STAG(a6)	* fix src type tag
	RTS

	**--------------------------------------------------------------------------------
	* convert sgl to ext SNAN
	* a0 : points to sgl SNAN
get_sgl_snan:
	MOVE.W	#$7fff, EXC_LV+FP_SRC_EX(a6) 	* set exp of SNAN
	BFEXTU	(a0){9:23}, d0
	LSL.L	#$8, d0				* extract and insert hi(man)
	MOVE.L	d0, EXC_LV+FP_SRC_HI(a6)
	CLR.L	EXC_LV+FP_SRC_LO(a6)

	BTST	#$7, (a0)			* see if sign of SNAN is set
	BEQ	no_sgl_snan_sgn
	BSET	#$7, EXC_LV+FP_SRC_EX(a6)
no_sgl_snan_sgn:
	RTS

	**--------------------------------------------------------------------------------
	* load a DBL into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 8 bytes into EXC_LV+L_SCR(1,2)*
	*	(3) fmove.d into fp0

load_dbl:       MOVEQ.L	#$8, d0				* pass: 8 (bytes)
	BSR	_dcalc_ea			* calc <ea>; <ea> in a0

	lea	EXC_LV+L_SCR1(a6), a1		* pass: ptr to input dbl tmp space
	MOVEQ.L	#$8, d0				* pass: * bytes to read

	MOVE.L	(a0),(a1)                       * fetch src operand from memory
	MOVE.L	4(a0),4(a1)

	LEA	EXC_LV+L_SCR1(a6), a0		* pass: ptr to input dbl
	BSR	set_tag_d			* determine src type tag
	MOVE.B	d0, EXC_LV+STAG(a6)		* set src optype tag

	CMP.b	#DENORM,d0			* is it a dbl DENORM?
	BEQ	get_dbl_denorm			* yes

	CMP.b	#SNAN,d0			* is it a dbl SNAN?
	BEQ	get_dbl_snan			* yes

	FMOVE.D	EXC_LV+L_SCR1(a6), fp0		* read into fp0;convert to xprec
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)		* return src op in EXC_LV+FP_SRC
	RTS

	**--------------------------------------------------------------------------------
	* must convert dbl denorm format to an Xprec denorm fmt suitable for
	* normalization...
	* a0 : loc. of dbl denorm
get_dbl_denorm:
	CLR.W	EXC_LV+FP_SRC_EX(a6)

	BFEXTU	(a0){12:31}, d0			* fetch hi(_mantissa)
	MOVE.L	d0, EXC_LV+FP_SRC_HI(a6)

	BFEXTU	4(a0){11:21}, d0		* fetch lo(_mantissa)
	MOVE.L	#$b, d1
	LSL.L	d1, d0
	MOVE.L	d0, EXC_LV+FP_SRC_LO(a6)

	BTST	#$7, (a0)			* is sgn bit set?
	BEQ	dbl_dnrm_norm
	BSET	#$7, EXC_LV+FP_SRC_EX(a6)	* set sgn of xprec value
dbl_dnrm_norm:	LEA	EXC_LV+FP_SRC(a6), a0
	BSR	norm				* normalize number
	MOVE.W	#$3c01, d1			* xprec exp = $3c01
	SUB.W	d0, d1				* exp = $3c01 - shft amt.
	OR.W	d1, EXC_LV+FP_SRC_EX(a6)	* {sgn,exp}
	MOVE.B	#NORM, EXC_LV+STAG(a6)		* fix src type tag
	RTS

	**--------------------------------------------------------------------------------
	* convert dbl to ext SNAN
	* a0 : points to dbl SNAN
get_dbl_snan:
	MOVE.W	#$7fff, EXC_LV+FP_SRC_EX(a6) 	* set exp of SNAN

	BFEXTU	(a0){12:31},d0			* fetch hi(_mantissa)
	MOVE.L	d0, EXC_LV+FP_SRC_HI(a6)

	BFEXTU	4(a0){11:21},d0			* fetch lo(_mantissa)
	MOVE.L	#$b,d1
	LSL.L	d1,d0
	MOVE.L	d0,EXC_LV+FP_SRC_LO(a6)

	BTST	#$7,(a0)			* see if sign of SNAN is set
	BEQ	no_dbl_snan_sgn
	BSET	#$7,EXC_LV+FP_SRC_EX(a6)
no_dbl_snan_sgn:
	RTS


	**--------------------------------------------------------------------------------
	**--------------------------------------------------------------------------------
	* load a Xprec into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 12 bytes into EXC_LV+L_SCR(1,2)
	*	(3) fmove.x into fp0
load_ext:
	MOVE.L	#$c, d0			* pass: 12 (bytes)
	BSR	_dcalc_ea		* calc <ea>

	LEA	EXC_LV+FP_SRC(a6), a1	* pass: ptr to input ext tmp space
	move.l	#$c, d0			* pass: * of bytes to read

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)

	LEA	EXC_LV+FP_SRC(a6), a0	* pass: ptr to src op
	BSR	set_tag_x		* determine src type tag

	CMP.b	#UNNORM,d0		* is the src op an UNNORM?
	BEQ	load_ext_unnorm		* yes

	MOVE.B	d0, EXC_LV+STAG(a6)	* store the src optype tag
	RTS
load_ext_unnorm:
	BSR	unnorm_fix		* fix the src UNNORM
	MOVE.B	d0, EXC_LV+STAG(a6)	* store the src optype tag
	RTS

	**--------------------------------------------------------------------------------
	* load a packed into fp0:
	* 	-number can't fault
	*	(1) calc ea
	*	(2) read 12 bytes into EXC_LV+L_SCR(1,2,3)
	*	(3) fmove.x into fp0
load_packed:
	BSR	get_packed

	LEA	EXC_LV+FP_SRC(a6),a0	* pass ptr to src op
	BSR	set_tag_x		* determine src type tag
	CMP.b	#UNNORM,d0		* is the src op an UNNORM ZERO?
	BEQ	load_packed_unnorm	* yes
	MOVE.B	d0,EXC_LV+STAG(a6)	* store the src optype tag
	RTS
load_packed_unnorm:
	BSR	unnorm_fix		* fix the UNNORM ZERO
	MOVE.B	d0,EXC_LV+STAG(a6)	* store the src optype tag
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** XDEF :*	_load_fop(): load operand for unimplemented FP exception
**-------------------------------------------------------------------------------------------------
*
* xref :
*	set_tag_x() - determine ext prec optype tag
*	set_tag_s() - determine sgl prec optype tag
*	set_tag_d() - determine dbl prec optype tag
*	unnorm_fix() - convert normalized number to denorm or zero
*	norm() - normalize a denormalized number
*	get_packed() - fetch a packed operand from memory
*	_dcalc_ea() - calculate <ea>, fixing An in process
*
*	_imem_read_{word,dc.l}() - read from instruction memory
*	_dmem_read() - read from data memory
*	_dmem_read_{byte,word,dc.l}() - read from data memory
*
*	facc_in_{b,w,l,d,x}() - mem read failed; special exit point
*
* INPUT :
*	None
*
* OUTPUT :
*	If memory access doesn't fail:
*	EXC_LV+FP_SRC(a6) = source operand in extended precision
* 	EXC_LV+FP_DST(a6) = destination operand in extended precision
*
* ALGORITHM :
*
*  This is called from the Unimplemented FP exception handler in order to load the source and
* maybe destination operand into EXC_LV+FP_SRC(a6) and EXC_LV+FP_DST(a6).  If the instruction
* was  opclass  zero,  load  the  source  and destination from the FP register file.  Set the
* optype tags for both if dyadic, one for monadic.  If a number is an UNNORM, convert it to a
* DENORM or a ZERO.
*
*  If  the  instruction  is  opclass  two  (memory->reg), then fetch the destination from the
* register  file  and  the  source operand from memory.  Tag and fix both as above w/ opclass
* zero instructions.
*
*  If  the  source operand is byte,word,dc.l, or single, it may be in the data register file.
* If  it's  actually  out  in memory, use one of the mem_read() routines to fetch it.  If the
* mem_read() access returns a failing value, exit through the special facc_in() routine which
* will create an acess error exception frame from the current exception frame.
*
*  Immediate data and regular data accesses are separated because if an immediate data access
* fails, the resulting fault status longword stacked for the access error exception must have
* the instruction bit set.
**-------------------------------------------------------------------------------------------

	xdef	_load_fop
_load_fop:
                **---------------------------------------------------------------------------
	*  15     13 12 10  9 7  6       0
	* /        \ /   \ /  \ /         \
	* ---------------------------------
	* | opclass | RX  | RY | EXTENSION |  (2nd word of general FP instruction)
	* ---------------------------------
	*

*	bfextu	EXC_LV+EXC_CMDREG(a6)0:3},d0 	* extract opclass
*	ICMP.b	#2,d0				* which class is it? ('000,'010,'011)
*	beq.w	op010				* handle <ea> -> fpn
*	bgt.w	op011				* handle fpn -> <ea>

                **---------------------------------------------------------------------------
	* we're not using op011 for now...

	BTST	#$6,EXC_LV+EXC_CMDREG(a6)
	BNE	op010

                **---------------------------------------------------------------------------
                **---------------------------------------------------------------------------
	* OPCLASS '000: reg -> reg

op000:	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d0	* fetch extension word lo
	BTST	#$5,d0				* testing extension bits
	BEQ	op000_src			* (bit 5 == 0) => monadic
	BTST	#$4,d0				* (bit 5 == 1)
	BEQ	op000_dst			* (bit 4 == 0) => dyadic
	AND.W	#$007f,d0			* extract extension bits {6:0}
	CMP.W	#$38,d0				* is it an fcmp (dyadic) ?
	BNE.B	op000_src			* it's an fcmp
op000_dst:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3}, d0	* extract dst field
	BSR	load_fpn2			* fetch dst fpreg into EXC_LV+FP_DST
	BSR	set_tag_x			* get dst optype tag

	CMP.B	#UNNORM,d0			* is dst fpreg an UNNORM?
	BEQ	op000_dst_unnorm		* yes
op000_dst_cont:
	MOVE.B 	d0,EXC_LV+DTAG(a6)		* store the dst optype tag
op000_src:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){3:3}, d0 	* extract src field
	BSR	load_fpn1			* fetch src fpreg into EXC_LV+FP_SRC
	BSR	set_tag_x			* get src optype tag

	CMP.b	#UNNORM,d0			* is src fpreg an UNNORM?
	BEQ	op000_src_unnorm		* yes
op000_src_cont:	MOVE.B	d0, EXC_LV+STAG(a6)		* store the src optype tag
	rts

op000_dst_unnorm:
	BSR	unnorm_fix			* fix the dst UNNORM
	BRA	op000_dst_cont
op000_src_unnorm:
	BSR	unnorm_fix			* fix the src UNNORM
	BRA	op000_src_cont

                **---------------------------------------------------------------------------
	** OPCLASS '010: <ea> -> reg

op010:	MOVE.W	EXC_LV+EXC_CMDREG(a6),d0	* fetch extension word
	BTST	#$5,d0				* testing extension bits
	BEQ	op010_src			* (bit 5 == 0) => monadic
	BTST	#$4,d0				* (bit 5 == 1)
	BEQ	op010_dst			* (bit 4 == 0) => dyadic
	AND.W	#$007f,d0			* extract extension bits {6:0}
	CMP.W	#$38,d0				* is it an fcmp (dyadic) ?
	BNE	op010_src			* it's an fcmp

op010_dst:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3}, d0 	* extract dst field
	BSR	load_fpn2			* fetch dst fpreg ptr

	BSR	set_tag_x			* get dst type tag
	CMP.b	#UNNORM,d0			* is dst fpreg an UNNORM?
	BEQ	op010_dst_unnorm		* yes

op010_dst_cont:	MOVE.B	d0, EXC_LV+DTAG(a6)		* store the dst optype tag

op010_src:	BFEXTU	EXC_LV+EXC_CMDREG(a6){3:3}, d0 	* extract src type field
	BFEXTU	EXC_LV+EXC_OPWORD(a6){10:3}, d1 * extract <ea> mode field
	BNE	fetch_from_mem			* src op is in memory
op010_dreg:
	CLR.B	EXC_LV+STAG(a6)			* either NORM or ZERO
	BFEXTU	EXC_LV+EXC_OPWORD(a6){13:3}, d1 * extract src reg field

	MOVE.W	((tbl_op010_dreg).b,pc,d0.w*2), d0 * jmp based on optype
	JMP	((tbl_op010_dreg).b,pc,d0.w*1) * fetch src from dreg

op010_dst_unnorm:
	BSR	unnorm_fix	* fix the dst UNNORM
	BRA	op010_dst_cont

tbl_op010_dreg:
	dc.w	opd_long	- tbl_op010_dreg
	dc.w	opd_sgl 	- tbl_op010_dreg
	dc.w	tbl_op010_dreg	- tbl_op010_dreg
	dc.w	tbl_op010_dreg	- tbl_op010_dreg
	dc.w	opd_word	- tbl_op010_dreg
	dc.w	tbl_op010_dreg	- tbl_op010_dreg
	dc.w	opd_byte	- tbl_op010_dreg
	dc.w	tbl_op010_dreg	- tbl_op010_dreg

	**-----------------------------------------------------------------------------
	* LONG: can be either NORM or ZERO...
	*
opd_long:
	BSR	fetch_dreg		* fetch dc.l in d0
	FMOVE.L	d0,fp0 			* load a dc.l
	FMOVEM.X	fp0,EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ	opd_long_zero		* dc.l is a ZERO
	RTS
opd_long_zero:
	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set ZERO optype flag
	RTS

	**-----------------------------------------------------------------------------
	* WORD: can be either NORM or ZERO...
	*
opd_word:
	BSR	fetch_dreg		* fetch word in d0
	FMOVE.W	d0, fp0 		* load a word
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ	opd_word_zero		* WORD is a ZERO
	RTS
opd_word_zero:
	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set ZERO optype flag
	RTS

	**-----------------------------------------------------------------------------
	* BYTE: can be either NORM or ZERO...
	*
opd_byte:
	BSR	fetch_dreg		* fetch word in d0
	FMOVE.B	d0, fp0 		* load a byte
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	FBEQ	opd_byte_zero		* byte is a ZERO
	RTS
opd_byte_zero:
	MOVE.B	#ZERO, EXC_LV+STAG(a6)	* set ZERO optype flag
	RTS

	**-----------------------------------------------------------------------------
	*
	* SGL: can be either NORM, DENORM, ZERO, INF, QNAN or SNAN but not UNNORM
	*
	* separate SNANs and DENORMs so they can be loaded w/ special care.
	* all others can simply be moved "in" using fmove.
	*
opd_sgl:
	BSR	fetch_dreg		* fetch sgl in d0
	MOVE.L	d0,EXC_LV+L_SCR1(a6)

	LEA	EXC_LV+L_SCR1(a6), a0 	* pass: ptr to the sgl
	BSR	set_tag_s		* determine sgl type
	MOVE.B	d0, EXC_LV+STAG(a6)	* save the src tag

	CMP.b	#SNAN,d0		* is it an SNAN?
	BEQ	get_sgl_snan		* yes

	CMP.b	#DENORM,d0		* is it a DENORM?
	BEQ	get_sgl_denorm		* yes

	FMOVE.S	(a0), fp0		* no, so can load it regular
	FMOVEM.X	fp0, EXC_LV+FP_SRC(a6)	* return src op in EXC_LV+FP_SRC
	RTS





**-------------------------------------------------------------------------------------------------
* XDEF **
*	fetch_dreg(): fetch register according to index in d1
*
* xdef **
*	None
*
* INPUT ***************************************************************
*	d1 = index of register to fetch from
*
* OUTPUT **************************************************************
*	d0 = value of register fetched
*
* ALGORITHM ***********************************************************
*	According to the index value in d1 which can range from zero
* to fifteen, load the corresponding register file value (where
* address register indexes start at 8). D0/D1/A0/A1/A6/A7 are on the
* stack. The rest should still be in their original places.
*
**-------------------------------------------------------------------------------------------------
* this routine leaves d1 intact for subsequent store_dreg calls.

	xdef	fetch_dreg
fetch_dreg:
	MOVE.W	((tbl_fdreg).b,pc,d1.w*2),d0
	JMP	((tbl_fdreg).b,pc,d0.w*1)

tbl_fdreg:	dc.w	fdreg0 - tbl_fdreg
	dc.w	fdreg1 - tbl_fdreg
	dc.w	fdreg2 - tbl_fdreg
	dc.w	fdreg3 - tbl_fdreg
	dc.w	fdreg4 - tbl_fdreg
	dc.w	fdreg5 - tbl_fdreg
	dc.w	fdreg6 - tbl_fdreg
	dc.w	fdreg7 - tbl_fdreg
	dc.w	fdreg8 - tbl_fdreg
	dc.w	fdreg9 - tbl_fdreg
	dc.w	fdrega - tbl_fdreg
	dc.w	fdregb - tbl_fdreg
	dc.w	fdregc - tbl_fdreg
	dc.w	fdregd - tbl_fdreg
	dc.w	fdrege - tbl_fdreg
	dc.w	fdregf - tbl_fdreg

fdreg0:	MOVE.L	EXC_LV+EXC_D0(a6),d0
	RTS
fdreg1:	MOVE.L	EXC_LV+EXC_D1(a6),d0
	RTS
fdreg2:	MOVE.L	d2,d0
	RTS
fdreg3:	MOVE.L	d3,d0
	RTS
fdreg4:	MOVE.L	d4,d0
	RTS
fdreg5:	MOVE.L	d5,d0
	RTS
fdreg6:	MOVE.L	d6,d0
	RTS
fdreg7:	MOVE.L	d7,d0
	RTS
fdreg8:	MOVE.L	EXC_LV+EXC_A0(a6),d0
	RTS
fdreg9:	MOVE.L	EXC_LV+EXC_A1(a6),d0
	RTS
fdrega:	MOVE.L	a2,d0
	RTS
fdregb:	MOVE.L	a3,d0
	RTS
fdregc:	MOVE.L	a4,d0
	RTS
fdregd:	MOVE.L	a5,d0
	RTS
fdrege:	MOVE.L	(a6),d0
	RTS
fdregf:	MOVE.L	EXC_LV+EXC_A7(a6),d0
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	store_dreg_l(): store longword to data register specified by d1
*
* xdef **
*	None
*
* INPUT ***************************************************************
*	d0 = longowrd value to store
*	d1 = index of register to fetch from
*
* OUTPUT **************************************************************
*	(data register is updated)
*
* ALGORITHM ***********************************************************
*	According to the index value in d1, store the longword value
* in d0 to the corresponding data register. D0/D1 are on the stack
* while the rest are in their initial places.
*
**-------------------------------------------------------------------------------------------------

	xdef	store_dreg_l
store_dreg_l:
	MOVE.W	((tbl_sdregl).b,pc,d1.w*2),d1
	JMP	((tbl_sdregl).b,pc,d1.w*1)

tbl_sdregl:	dc.w	sdregl0 - tbl_sdregl
	dc.w	sdregl1 - tbl_sdregl
	dc.w	sdregl2 - tbl_sdregl
	dc.w	sdregl3 - tbl_sdregl
	dc.w	sdregl4 - tbl_sdregl
	dc.w	sdregl5 - tbl_sdregl
	dc.w	sdregl6 - tbl_sdregl
	dc.w	sdregl7 - tbl_sdregl

sdregl0:	MOVE.L	d0,EXC_LV+EXC_D0(a6)
	RTS
sdregl1:	MOVE.L	d0,EXC_LV+EXC_D1(a6)
	RTS
sdregl2:	MOVE.L	d0,d2
	RTS
sdregl3:	MOVE.L	d0,d3
	RTS
sdregl4:	MOVE.L	d0,d4
	RTS
sdregl5:	MOVE.L	d0,d5
	RTS
sdregl6:	MOVE.L	d0,d6
	RTS
sdregl7:	MOVE.L	d0,d7
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	store_dreg_w(): store word to data register specified by d1
*		
* xdef **
*	None	
*		
* INPUT ***************************************************************
*	d0 = word value to store	
*	d1 = index of register to fetch from
* 		
* OUTPUT **************************************************************
*	(data register is updated)
*		
* ALGORITHM ***********************************************************
*	According to the index value in d1, store the word value
* in d0 to the corresponding data register. D0/D1 are on the stack
* while the rest are in their initial places.
*		
**-------------------------------------------------------------------------------------------------

	xdef	store_dreg_w
store_dreg_w:	MOVE.W	((tbl_sdregw).b,pc,d1.w*2),d1
	JMP	((tbl_sdregw).b,pc,d1.w*1)

tbl_sdregw:	dc.w	sdregw0 - tbl_sdregw
	dc.w	sdregw1 - tbl_sdregw
	dc.w	sdregw2 - tbl_sdregw
	dc.w	sdregw3 - tbl_sdregw
	dc.w	sdregw4 - tbl_sdregw
	dc.w	sdregw5 - tbl_sdregw
	dc.w	sdregw6 - tbl_sdregw
	dc.w	sdregw7 - tbl_sdregw

sdregw0:	MOVE.W	d0,EXC_LV+EXC_D0+2(a6)
	RTS
sdregw1:	MOVE.W	d0,EXC_LV+EXC_D1+2(a6)
	RTS
sdregw2:	MOVE.W	d0,d2
	RTS
sdregw3:	MOVE.W	d0,d3
	RTS
sdregw4:	MOVE.W	d0,d4
	RTS
sdregw5:	MOVE.W	d0,d5
	RTS
sdregw6:	MOVE.W	d0,d6
	RTS
sdregw7:	MOVE.W	d0,d7
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	store_dreg_b(): store byte to data register specified by d1
*
* xdef **
*	None
*
* INPUT ***************************************************************
*	d0 = byte value to store
*	d1 = index of register to fetch from
*
* OUTPUT **************************************************************
*	(data register is updated)
*
* ALGORITHM ***********************************************************
*	According to the index value in d1, store the byte value
* in d0 to the corresponding data register. D0/D1 are on the stack
* while the rest are in their initial places.
*
**-------------------------------------------------------------------------------------------------

	xdef	store_dreg_b
store_dreg_b:
	MOVE.W	((tbl_sdregb).b,pc,d1.w*2),d1
	JMP	((tbl_sdregb).b,pc,d1.w*1)

tbl_sdregb:	dc.w	sdregb0 - tbl_sdregb
	dc.w	sdregb1 - tbl_sdregb
	dc.w	sdregb2 - tbl_sdregb
	dc.w	sdregb3 - tbl_sdregb
	dc.w	sdregb4 - tbl_sdregb
	dc.w	sdregb5 - tbl_sdregb
	dc.w	sdregb6 - tbl_sdregb
	dc.w	sdregb7 - tbl_sdregb

sdregb0:	MOVE.B	d0,EXC_LV+EXC_D0+3(a6)
	RTS
sdregb1:	MOVE.B	d0,EXC_LV+EXC_D1+3(a6)
	RTS
sdregb2:	MOVE.B	d0,d2
	RTS
sdregb3:	MOVE.B	d0,d3
	RTS
sdregb4:	MOVE.B	d0,d4
	RTS
sdregb5:	MOVE.B	d0,d5
	RTS
sdregb6:	MOVE.B	d0,d6
	RTS
sdregb7:	MOVE.B	d0,d7
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	load_fpn1(): load FP register value into EXC_LV+FP_SRC(a6).
**-------------------------------------------------------------------------------------------------
*
* INPUT :
*	d0 = index of FP register to load
*
* OUTPUT :
*	EXC_LV+FP_SRC(a6) = value loaded from FP register file
*
* ALGORITHM ***********************************************************
*	Using the index in d0, load EXC_LV+FP_SRC(a6) with a number from the
* FP register file.
*
**-------------------------------------------------------------------------------------------------

	xdef 	load_fpn1
load_fpn1:
	MOVE.W	((tbl_load_fpn1).b,pc,d0.w*2), d0
	JMP	((tbl_load_fpn1).b,pc,d0.w*1)

tbl_load_fpn1:	dc.w	load_fpn1_0 - tbl_load_fpn1
	dc.w	load_fpn1_1 - tbl_load_fpn1
	dc.w	load_fpn1_2 - tbl_load_fpn1
	dc.w	load_fpn1_3 - tbl_load_fpn1
	dc.w	load_fpn1_4 - tbl_load_fpn1
	dc.w	load_fpn1_5 - tbl_load_fpn1
	dc.w	load_fpn1_6 - tbl_load_fpn1
	dc.w	load_fpn1_7 - tbl_load_fpn1

load_fpn1_0:  	MOVE.L	0+EXC_LV+EXC_FP0(a6), 0+EXC_LV+FP_SRC(a6)
	MOVE.L	4+EXC_LV+EXC_FP0(a6), 4+EXC_LV+FP_SRC(a6)
	MOVE.L	8+EXC_LV+EXC_FP0(a6), 8+EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_1:	MOVE.L	0+EXC_LV+EXC_FP1(a6), 0+EXC_LV+FP_SRC(a6)
	MOVE.L	4+EXC_LV+EXC_FP1(a6), 4+EXC_LV+FP_SRC(a6)
	MOVE.L	8+EXC_LV+EXC_FP1(a6), 8+EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_2:	FMOVEM.X	fp2, EXC_LV+FP_SRC(a6)			** movem == no FPCR change !!!
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_3:	FMOVEM.X	fp3, EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_4:	FMOVEM.X	fp4, EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_5:	FMOVEM.X	fp5, EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_6:	FMOVEM.X	fp6, EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS
load_fpn1_7:	FMOVEM.X	fp7, EXC_LV+FP_SRC(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*	load_fpn2(): load FP register value into EXC_LV+FP_DST(a6).
**-------------------------------------------------------------------------------------------------
* XREF:	None
*
* INPUT :
*	d0 = index of FP register to load
*
* OUTPUT :
*	EXC_LV+FP_DST(a6) = value loaded from FP register file
*	a0 = dst addr
*
* ALGORITHM :
*	Using the index in d0, load EXC_LV+FP_DST(a6) with a number from the
* FP register file.
*
**-------------------------------------------------------------------------------------------------

	xdef	load_fpn2
load_fpn2:	MOVE.W	((tbl_load_fpn2).b,pc,d0.w*2), d0
	JMP	((tbl_load_fpn2).b,pc,d0.w*1)

tbl_load_fpn2:	dc.w	load_fpn2_0 - tbl_load_fpn2
	dc.w	load_fpn2_1 - tbl_load_fpn2
	dc.w	load_fpn2_2 - tbl_load_fpn2
	dc.w	load_fpn2_3 - tbl_load_fpn2
	dc.w	load_fpn2_4 - tbl_load_fpn2
	dc.w	load_fpn2_5 - tbl_load_fpn2
	dc.w	load_fpn2_6 - tbl_load_fpn2
	dc.w	load_fpn2_7 - tbl_load_fpn2

load_fpn2_0:	MOVE.L	0+EXC_LV+EXC_FP0(a6), 0+EXC_LV+FP_DST(a6)
	MOVE.L	4+EXC_LV+EXC_FP0(a6), 4+EXC_LV+FP_DST(a6)
	MOVE.L	8+EXC_LV+EXC_FP0(a6), 8+EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_1:
	MOVE.L	0+EXC_LV+EXC_FP1(a6), 0+EXC_LV+FP_DST(a6)
	MOVE.L	4+EXC_LV+EXC_FP1(a6), 4+EXC_LV+FP_DST(a6)
	MOVE.L	8+EXC_LV+EXC_FP1(a6), 8+EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_2:	FMOVEM.X	fp2, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_3:	FMOVEM.X	fp3, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_4:	FMOVEM.X	fp4, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_5:	FMOVEM.X	fp5, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_6:	FMOVEM.X	fp6, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS
load_fpn2_7:	FMOVEM.X	fp7, EXC_LV+FP_DST(a6)
	LEA	EXC_LV+FP_DST(a6), a0
	RTS


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** 	store_fpreg(): store an fp value to the fpreg designated d0.
**-------------------------------------------------------------------------------------------------
* xref :
*	None
*
* INPUT ***************************************************************
*	fp0 = extended precision value to store
*	d0  = index of floating-point register
*
* OUTPUT **************************************************************
*	None
*
* ALGORITHM ***********************************************************
*	Store the value in fp0 to the FP register designated by the
* value in d0. The FP number can be DENORM or SNAN so we have to be
* careful that we don't take an exception here.
*
**-------------------------------------------------------------------------------------------------

	xdef	store_fpreg
store_fpreg:
	IFGT	MYDEBUG
	MOVEM.L	a0,-(sp)	* remember
	FMOVEM.X	fp0,-(sp)
	MOVE.L	sp,a0           * remember stack
	DBUG	10,"<store_fpreg: %l08x %l08x %l08x, %ld>",(a0),4(a0),8(a0),d0
	FMOVEM.X	(sp)+,fp0
	MOVEM.L	(sp)+,a0
	ENDC

	MOVE.W	((tbl_store_fpreg).b,pc,d0.w*2), d0
	JMP	((tbl_store_fpreg).b,pc,d0.w*1)

tbl_store_fpreg:
	dc.w	store_fpreg_0 - tbl_store_fpreg
	dc.w	store_fpreg_1 - tbl_store_fpreg
	dc.w	store_fpreg_2 - tbl_store_fpreg
	dc.w	store_fpreg_3 - tbl_store_fpreg
	dc.w	store_fpreg_4 - tbl_store_fpreg
	dc.w	store_fpreg_5 - tbl_store_fpreg
	dc.w	store_fpreg_6 - tbl_store_fpreg
	dc.w	store_fpreg_7 - tbl_store_fpreg

store_fpreg_0:	FMOVEM.X	fp0, EXC_LV+EXC_FP0(a6)
	RTS
store_fpreg_1:	FMOVEM.X	fp0, EXC_LV+EXC_FP1(a6)
	RTS
store_fpreg_2:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+, fp2
	RTS
store_fpreg_3:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+, fp3
	RTS
store_fpreg_4:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+, fp4
	RTS
store_fpreg_5:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+, fp5
	RTS
store_fpreg_6:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+, fp6
	RTS
store_fpreg_7:	FMOVEM.X 	fp0, -(sp)
	FMOVEM.X	(sp)+,fp7
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* 	_denorm(): denormalize an intermediate result
**-------------------------------------------------------------------------------------------------
*
* xdef :
*	None
*
* INPUT :
*	a0 = points to the operand to be denormalized
*	(in the internal extended format)
*
*	d0 = rounding precision
*
* OUTPUT :
*	a0 = pointer to the denormalized result
*	(in the internal extended format)
*
*	d0 = guard,round,sticky
*
* ALGORITHM :
*
*  According  to the exponent underflow threshold for the given precision, shift the mantissa
* bits to the right in order raise the exponent of the operand to the threshold value.  While
* shifting the mantissa bits right, maintain the value of the guard, round, and sticky bits.
*
* other notes:
*	(1) _denorm() is called by the underflow routines
*	(2) _denorm() does NOT affect the status register
*
**-------------------------------------------------------------------------------------------------
*
* table of exponent threshold values for each precision
*
tbl_thresh:	dc.w	$0
	dc.w	sgl_thresh
	dc.w	dbl_thresh

	xdef	_denorm
_denorm:
	**---------------------------------------------------------------------------------
	*
	* Load the exponent threshold for the precision selected and check
	* to see if (threshold - exponent) is > 65 in which case we can
	* simply calculate the sticky bit and zero the mantissa. otherwise
	* we have to call the denormalization routine.
	*
	LSR.b	#$2, d0					* shift prec to lo bits
	MOVE.W	((tbl_thresh).b,pc,d0.w*2),d1 		* load prec threshold
	MOVE.W	d1, d0					* copy d1 into d0
	SUB.W	FTEMP_EX(a0), d0			* diff = threshold - exp
	CMP.w	#66,d0					* is diff > 65? (mant + g,r bits)
	BPL.B	denorm_set_stky				* yes; just calc sticky

	CLR.L	d0					* clear g,r,s
	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6) 	* yes; was INEX2 set?
	BEQ	denorm_call				* no; don't change anything
	BSET	#29,d0					* yes; set sticky bit
denorm_call:
	BSR	dnrm_lp					* denormalize the number
	RTS

	**---------------------------------------------------------------------------------
	*
	* all bit would have been shifted off during the denorm so simply
	* calculate if the sticky should be set and clear the entire mantissa.
	*
denorm_set_stky:
	MOVE.L	#$20000000, d0		* set sticky bit in return value
	MOVE.W	d1, FTEMP_EX(a0)	* load exp with threshold
	CLR.L	FTEMP_HI(a0)		* set d1 = 0 (ms mantissa)
	CLR.L	FTEMP_LO(a0)		* set d2 = 0 (ms mantissa)
	RTS







**----------------------------------------------------------------------------------------------------
**----------------------------------------------------------------------------------------------------
** 	dnrm_lp(): normalize exponent/mantissa to specified threshhold
**----------------------------------------------------------------------------------------------------
*
* INPUT:
*	a0	   : points to the operand to be denormalized
*	d0{31:29} : initial guard,round,sticky
*	d1{15:0}  : denormalization threshold
* OUTPUT:
*	a0	   : points to the denormalized operand
*	d0{31:29} : final guard,round,sticky
*

	* *** Local Equates *** *

GRS	equ	EXC_LV+L_SCR2	* g,r,s temp storage
FTEMP_LO2	equ	EXC_LV+L_SCR1	* FTEMP_LO copy

	xdef	dnrm_lp
dnrm_lp:

	**------------------------------------------------------------------------------------
	*
	* make a copy of FTEMP_LO and place the g,r,s bits directly after it
	* in memory so as to make the bitfield extraction for denormalization easier.
	*
	MOVE.L	FTEMP_LO(a0), FTEMP_LO2(a6) 	* make FTEMP_LO copy
	MOVE.L	d0, GRS(a6)			* place g,r,s after it

	**------------------------------------------------------------------------------------
	*
	* check to see how much less than the underflow threshold the operand
	* exponent is.
	*
	MOVE.L	d1, d0			* copy the denorm threshold
	SUB.W	FTEMP_EX(a0), d1	* d1 = threshold - uns exponent
	BLE	dnrm_no_lp		* d1 <= 0
	CMP.w	#$20,d1			* is ( 0 <= d1 < 32) ?
	BLT	case_1			* yes
	CMP.w	#$40,d1			* is (32 <= d1 < 64) ?
	BLT	case_2			* yes
	BRA	case_3			* (d1 >= 64)

	**------------------------------------------------------------------------------------
	*
	* No normalization necessary
	*
dnrm_no_lp:
	MOVE.L	GRS(a6), d0 	* restore original g,r,s
	RTS

	**------------------------------------------------------------------------------------
	*
	* case (0<d1<32)
	*
	* d0 = denorm threshold
	* d1 = "n" = amt to shift
	*
	*	---------------------------------------------------------
	*	|     FTEMP_HI	  |    	FTEMP_LO     |grs000.........000|
	*	---------------------------------------------------------
	*	<-(32 - n)-><-(n)-><-(32 - n)-><-(n)-><-(32 - n)-><-(n)->
	*	\	   \	      \		 \
	*	 \	    \	       \	  \
	*	  \	     \		\	   \
	*	   \	      \		 \	    \
	*	    \	       \	  \	     \
	*	     \		\	   \	      \
	*	      \		 \	    \	       \
	*	       \	  \	     \		\
	*	<-(n)-><-(32 - n)-><------(32)-------><------(32)------->
	*	---------------------------------------------------------
	*	|0.....0| NEW_HI  |  NEW_FTEMP_LO     |grs	|
	*	---------------------------------------------------------
	*
case_1:
	MOVE.L	d2, -(sp)		* create temp storage
	MOVE.W	d0, FTEMP_EX(a0)	* exponent = denorm threshold
	MOVE.L	#32, d0
	SUB.W	d1, d0			* d0 = 32 - d1

	CMP.w	#29,d1			* is shft amt >= 29
	BLT	case1_extract		* no; no fix needed
	MOVE.B	GRS(a6), d2
	OR.B	d2,FTEMP_LO2+3(a6)

case1_extract:	BFEXTU	FTEMP_HI(a0){0:20}, d2 	* d2 = new FTEMP_HI
	BFEXTU	FTEMP_HI(a0){0:32}, d1 	* d1 = new FTEMP_LO
	BFEXTU	FTEMP_LO2(a6){0:32}, d0 * d0 = new G,R,S

	MOVE.L	d2, FTEMP_HI(a0)	* store new FTEMP_HI
	MOVE.L	d1, FTEMP_LO(a0)	* store new FTEMP_LO

	BFTST	d0{2:30}		* were bits shifted off?
	BEQ	case1_sticky_clear	* no; go finish
	BSET	#rnd_stky_bit, d0	* yes; set sticky bit
case1_sticky_clear:
	AND.L	#$e0000000, d0		* clear all but G,R,S
	MOVE.L	(sp)+, d2		* restore temp register
	RTS

	**------------------------------------------------------------------------------------
	*
	* case (32<=d1<64)
	*
	* d0 = denorm threshold
	* d1 = "n" = amt to shift
	*
	*	---------------------------------------------------------
	*	|     FTEMP_HI	  |    	FTEMP_LO     |grs000.........000|
	*	---------------------------------------------------------
	*	<-(32 - n)-><-(n)-><-(32 - n)-><-(n)-><-(32 - n)-><-(n)->
	*	\	   \	      \
	*	 \	    \	       \
	*	  \	     \		-------------------
	*	   \	      --------------------	   \
	*	    -------------------	  	  \	    \
	*		     	       \	   \	     \
	*		      	 	\     	    \	      \
	*		       	  	 \	     \	       \
	*	<-------(32)------><-(n)-><-(32 - n)-><------(32)------->
	*	---------------------------------------------------------
	*	|0...............0|0....0| NEW_LO     |grs	|
	*	---------------------------------------------------------
	*
case_2:
	MOVE.L	d2, -(sp)		* create temp storage

	MOVE.W	d0, FTEMP_EX(a0)	* exponent = denorm threshold
	SUBI.W	#$20, d1		* d1 now between 0 and 32
	MOVE.L	#$20, d0
	sub.w	d1, d0	* d0 = 32 - d1

	**------------------------------------------------------------------------------------
	* subtle step here; or in the g,r,s at the bottom of FTEMP_LO to minimize
	* the number of bits to check for the sticky detect.
	* it only plays a role in shift amounts of 61-63.

	MOVE.B	GRS(a6), d2
	OR.B	d2,FTEMP_LO2+3(a6)

	BFEXTU	FTEMP_HI(a0){0:20}, d2 	* d2 = new FTEMP_LO
	BFEXTU	FTEMP_HI(a0){20:32}, d1 * d1 = new G,R,S

	BFTST	d1{2:30}		* were any bits shifted off?
	BNE	case2_set_sticky	* yes; set sticky bit
	BFTST	FTEMP_LO2(a6){d0:31}	* were any bits shifted off?
	BNE	case2_set_sticky	* yes; set sticky bit

	MOVE.L	d1, d0			* move new G,R,S to d0
	BRA	case2_end

case2_set_sticky:
	MOVE.L	d1,d0			* move new G,R,S to d0
	BSET	#rnd_stky_bit,d0	* set sticky bit

case2_end:	CLR.L	FTEMP_HI(a0)		* store FTEMP_HI = 0
	MOVE.L	d2, FTEMP_LO(a0)	* store FTEMP_LO
	AND.L	#$e0000000,d0		* clear all but G,R,S
	MOVE.L	(sp)+,d2		* restore temp register
	RTS

	**------------------------------------------------------------------------------------
	*
	* case (d1>=64)
	*
	* d0 = denorm threshold
	* d1 = amt to shift
	*
case_3:
	MOVE.W	d0, FTEMP_EX(a0)	* insert denorm threshold

	CMP.w	#65,d1			* is shift amt > 65?
	BLT	case3_64		* no; it's == 64
	BEQ	case3_65		* no; it's == 65

	**------------------------------------------------------------------------------------
	*
	* case (d1>65)
	*
	* Shift value is > 65 and out of range. All bits are shifted off.
	* Return a zero mantissa with the sticky bit set
	*
	CLR.L	FTEMP_HI(a0)	* clear hi(mantissa)
	CLR.L	FTEMP_LO(a0)	* clear lo(mantissa)
	MOVE.L	#$20000000, d0	* set sticky bit
	RTS

	**------------------------------------------------------------------------------------
	*
	* case (d1 == 64)
	*
	*	---------------------------------------------------------
	*	|     FTEMP_HI	  |    	FTEMP_LO     |grs000.........000|
	*	---------------------------------------------------------
	*	<-------(32)------>
	*	\	   	   \
	*	 \	    	    \
	*	  \	     	     \
	*	   \	      	      ------------------------------
	*	    -------------------------------		    \
	*			     	       	   \		     \
	*	      		 	     	    \		      \
	*	       		  	 	     \		       \
	*					      <-------(32)------>
	*	---------------------------------------------------------
	*	|0...............0|0................0|grs	|
	*	---------------------------------------------------------
*
case3_64:
	MOVE.L	FTEMP_HI(a0), d0	* fetch hi(mantissa)
	MOVE.L	d0, d1			* make a copy
	AND.L	#$c0000000, d0		* extract G,R
	AND.L	#$3fffffff, d1		* extract other bits
	BRA	case3_complete

	**------------------------------------------------------------------------------------
	*
	* case (d1 == 65)
	*
	*	---------------------------------------------------------
	*	|     FTEMP_HI	  |    	FTEMP_LO     |grs000.........000|
	*	---------------------------------------------------------
	*	<-------(32)------>
	*	\	   	   \
	*	 \	    	    \
	*	  \	     	     \
	*	   \	      	      ------------------------------
	*	    --------------------------------		    \
	*	     	       			    \		     \
	*	      	 		     	     \		      \
	*	       	  		 	      \		       \
	*					       <-------(31)----->
	*	---------------------------------------------------------
	*	|0...............0|0................0|0rs	|
	*	---------------------------------------------------------
	*
case3_65:
	MOVE.L	FTEMP_HI(a0), d0	* fetch hi(mantissa)
	AND.L	#$80000000, d0		* extract R bit
	LSR.L	#$1, d0			* shift high bit into R bit
	AND.L	#$7fffffff, d1		* extract other bits

case3_complete:
	**------------------------------------------------------------------------------------
	* last operation done was an "and" of the bits shifted off so the condition
	* codes are already set so branch accordingly.

	BNE.B	case3_set_sticky	* yes; go set new sticky
	TST.L	FTEMP_LO(a0)		* were any bits shifted off?
	BNE	case3_set_sticky	* yes; go set new sticky
	TST.B	GRS(a6)			* were any bits shifted off?
	BNE	case3_set_sticky	* yes; go set new sticky

	**------------------------------------------------------------------------------------
	* no bits were shifted off so don't set the sticky bit.
	* the guard and
	* the entire mantissa is zero.
	*
	CLR.L	FTEMP_HI(a0)		* clear hi(mantissa)
	CLR.L	FTEMP_LO(a0)		* clear lo(mantissa)
	RTS

	**------------------------------------------------------------------------------------
	*
	* some bits were shifted off so set the sticky bit.
	* the entire mantissa is zero.
	*
case3_set_sticky:
	BSET	#rnd_stky_bit,d0	* set new sticky bit
	CLR.L	FTEMP_HI(a0)		* clear hi(mantissa)
	CLR.L	FTEMP_LO(a0)		* clear lo(mantissa)
	RTS




**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	_round(): round result according to precision/mode
**-------------------------------------------------------------------------------------------------
*
* xdef :
*	None
*
* INPUT :
*	a0	  = ptr to input operand in internal extended format
*	d1(hi)    = contains rounding precision:
*	ext = $000$xxx
*	sgl = $0004xxxx
*	dbl = $0008xxxx
*	d1(lo)	  = contains rounding mode:
*	RN  = $xxxx0000
*	RZ  = $xxxx0001
*	RM  = $xxxx0002
*	RP  = $xxxx0003
*	d0{31:29} = contains the g,r,s bits (extended)
*
* OUTPUT :
*	a0 = pointer to rounded result
*
* ALGORITHM :
*	On return the value pointed to by a0 is correctly rounded,
*	a0 is preserved and the g-r-s bits in d0 are cleared.
*	The result is not typed - the tag field is invalid.  The
*	result is still in the internal extended format.
*
*	The INEX bit of USER_FPSR will be set if the rounded result was
*	inexact (i.e. if any of the g-r-s bits were set).
*
**-------------------------------------------------------------------------------------------------

	xdef	_round
_round:
	**---------------------------------------------------------------------------------
	* ext_grs() looks at the rounding precision and sets the appropriate
	* G,R,S bits.
	* If (G,R,S == 0) then result is exact and round is done, else set
	* the inex flag in status reg and continue.
	*
	BSR	ext_grs			* extract G,R,S

	TST.L	d0			* are G,R,S zero?
	BEQ	truncate		* yes; round is complete

	OR.W	#inx2a_mask,EXC_LV+USER_FPSR+2(a6) * set inex2/ainex

	**---------------------------------------------------------------------------------
	* Use rounding mode as an index into a jump table for these modes.
	* All of the following assumes grs != 0.
	*
	MOVE.W	((tbl_mode).b,pc,d1.w*2), a1 	* load jump offset
	JMP	((tbl_mode).b,pc,a1)		* JMP to rnd mode handler

tbl_mode:	dc.w	rnd_near - tbl_mode
	dc.w	truncate - tbl_mode		* RZ always truncates
	dc.w	rnd_mnus - tbl_mode
	dc.w	rnd_plus - tbl_mode

	**---------------------------------------------------------------------------------
	*	ROUND PLUS INFINITY
	*
	*	If sign of fp number = 0 (positive), then add 1 to l.
rnd_plus:
	TST.B	FTEMP_SGN(a0)		* check for sign
	bmi.w	truncate		* if positive then truncate

	MOVE.L	#$ffffffff, d0		* force g,r,s to be all f's
	SWAP	d1			* set up d1 for round prec.

	CMP.b	#s_mode,d1		* is prec = sgl?
	BEQ	add_sgl			* yes
	BGT	add_dbl			* no; it's dbl
	BRA	add_ext			* no; it's ext

	**---------------------------------------------------------------------------------
	*	ROUND MINUS INFINITY
	*
	*	If sign of fp number = 1 (negative), then add 1 to l.
rnd_mnus:
	TST.B	FTEMP_SGN(a0)		* check for sign
	BPL	truncate		* if negative then truncate

	MOVE.L	#$ffffffff, d0		* force g,r,s to be all f's
	swap	d1			* set up d1 for round prec.

	CMP.b	#s_mode,d1		* is prec = sgl?
	BEQ	add_sgl			* yes
	BGT	add_dbl			* no; it's dbl
	BRA	add_ext			* no; it's ext

	**---------------------------------------------------------------------------------
                *	ROUND NEAREST
	*
	*	If (g=1), then add 1 to l and if (r=s=0), then clear l
	*	Note that this will round to even in case of a tie.
rnd_near:
	ASL.L	#$1, d0			* shift g-bit to c-bit
	BCC.W	truncate		* if (g=1) then

	SWAP	d1			* set up d1 for round prec.

	CMP.b	#s_mode,d1		* is prec = sgl?
	BEQ	add_sgl			* yes
	BGT	add_dbl			* no; it's dbl
	BRA	add_ext			* no; it's ext

	**---------------------------------------------------------------------------------
	**** LOCAL EQUATES ***

ad_1_sgl	equ	$00000100	* constant to add 1 to l-bit in sgl prec
ad_1_dbl	equ	$00000800	* constant to add 1 to l-bit in dbl prec

	**---------------------------------------------------------------------------------
	*	ADD SINGLE
add_sgl:
	ADD.L	#ad_1_sgl, FTEMP_HI(a0)
	BCC	scc_clr			* no mantissa overflow
	ROXR.W	FTEMP_HI(a0)		* shift v-bit back in
	ROXR.W	FTEMP_HI+2(a0)		* shift v-bit back in
	ADD.W	#$1, FTEMP_EX(a0)	* and incr exponent
scc_clr:	TST.L	d0			* test for rs = 0
	BNE	sgl_done
	AND.W	#$fe00,FTEMP_HI+2(a0)	* clear the l-bit
sgl_done:
	and.l	#$ffffff00,FTEMP_HI(a0) * truncate bits beyond sgl limit
	CLR.L	FTEMP_LO(a0)		* clear d2
	RTS

	**---------------------------------------------------------------------------------
	*	ADD EXTENDED
add_ext:
	ADDQ.L	#1,FTEMP_LO(a0)		* add 1 to l-bit
	BCC	xcc_clr			* test for carry out
	ADDQ.L	#1,FTEMP_HI(a0)		* propogate carry
	BCC	xcc_clr

	ROXR.W	FTEMP_HI(a0)		* mant is 0 so restore v-bit
	ROXR.W	FTEMP_HI+2(a0)		* mant is 0 so restore v-bit
	ROXR.W	FTEMP_LO(a0)
	ROXR.W	FTEMP_LO+2(a0)
	ADD.W	#1,FTEMP_EX(a0)		* and inc exp
xcc_clr:	TST.L	d0			* test rs = 0
	BNE	add_ext_done
	AND.B	#$fe,FTEMP_LO+3(a0)	* clear the l bit
add_ext_done:	RTS

	**---------------------------------------------------------------------------------
                *	ADD DOUBLE

add_dbl:	ADD.L	#ad_1_dbl,FTEMP_LO(a0)	* add 1 to lsb
	BCC	dcc_clr			* no carry
	ADDQ.L	#$1, FTEMP_HI(a0)	* propogate carry
	BCC	dcc_clr			* no carry

	ROXR.W	FTEMP_HI(a0)		* mant is 0 so restore v-bit
	ROXR.W	FTEMP_HI+2(a0)		* mant is 0 so restore v-bit
	ROXR.W	FTEMP_LO(a0)
	ROXR.W	FTEMP_LO+2(a0)
	ADDQ.W	#$1, FTEMP_EX(a0)	* incr exponent
dcc_clr:	TST.L	d0			* test for rs = 0
	BNE	dbl_done
	AND.W	#$f000,FTEMP_LO+2(a0)	* clear the l-bit
dbl_done:	AND.L	#$fffff800,FTEMP_LO(a0)	* truncate bits beyond dbl limit
	RTS

	**---------------------------------------------------------------------------------
	** Truncate all other bits
truncate:
	SWAP	d1		* select rnd prec
	CMP.b	#s_mode,d1	* is prec sgl?
	BEQ	sgl_done	* yes
	BGT	dbl_done	* no; it's dbl
	RTS			* no; it's ext


**---------------------------------------------------------------------------------
**---------------------------------------------------------------------------------
**---------------------------------------------------------------------------------
*
* ext_grs(): extract guard, round and sticky bits according to
*	     rounding precision.
*
* INPUT
*	d0	   = extended precision g,r,s (in d0{31:29})
*	d1 	   = {PREC,ROUND}
* OUTPUT
*	d0{31:29}  = guard, round, sticky
*
* The ext_grs extract the guard/round/sticky bits according to the
* selected rounding precision. It is called by the round subroutine
* only.  All registers except d0 are kept intact. d0 becomes an
* updated guard,round,sticky in d0{31:29}
*
* Notes: the ext_grs uses the round PREC, and therefore has to swap d1
*	 prior to usage, and needs to restore d1 to original. this
*	 routine is tightly tied to the round routine and not meant to
*	 uphold standard subroutine calling practices.
*

ext_grs:	SWAP	d1			* have d1.w point to round precision
	TST.B	d1			* is rnd prec = extended?
	BNE	ext_grs_not_ext		* no; go handle sgl or dbl

	**---------------------------------------------------------------------------------
	* d0 actually already hold g,r,s since _round() had it before calling
	* this function. so, as dc.l as we don't disturb it, we are "returning" it.
	*
ext_grs_ext:	SWAP	d1	* yes; return to correct positions
	RTS

ext_grs_not_ext:
	MOVEM.L	d2-d3, -(sp)		* make some temp registers {d2/d3}

	CMP.b	#s_mode,d1		* is rnd prec = sgl?
	BNE	ext_grs_dbl		* no; go handle dbl

	**---------------------------------------------------------------------------------
	*
	* sgl:
	*		96	64	40	  32			    0
	*		-----------------------------------------------------
	*		| EXP	|XXXXXXX|	  |xx		|	|grs|
	*		-----------------------------------------------------
	*			        <--(24)--->nn\			   /
	*	 			 	   ee ---------------------
	*	   				   ww	|
	*						v
	*					   gr	   new sticky
	*
ext_grs_sgl:
	BFEXTU	FTEMP_HI(a0){24:2}, d3 		* sgl prec. g-r are 2 bits right
	MOVE.L	#30, d2				* of the sgl prec. limits
	LSL.L	d2, d3				* shift g-r bits to MSB of d3
	MOVE.L	FTEMP_HI(a0), d2		* get word 2 for s-bit test
	AND.L	#$0000003f, d2			* s bit is the or of all other
	BNE	ext_grs_st_stky			* bits to the right of g-r
	TST.L	FTEMP_LO(a0)			* test lower mantissa
	BNE	ext_grs_st_stky			* if any are set, set sticky
	TST.L	d0				* test original g,r,s
	BNE	ext_grs_st_stky			* if any are set, set sticky
	BRA	ext_grs_end_sd			* if words 3 and 4 are clr, exit

	**---------------------------------------------------------------------------------
	*
	* dbl:
	*		96	64	  	32	 11	0
	*		-----------------------------------------------------
	*		| EXP	|XXXXXXX|	  	|	 |xx	|grs|
	*		-----------------------------------------------------
	*							  nn\	    /
	*							  ee -------
	*							  ww	|
	*								v
	*							  gr	new sticky
	*
ext_grs_dbl:
	BFEXTU	FTEMP_LO(a0){21:2}, d3 		* dbl-prec. g-r are 2 bits right
	MOVE.L	#30, d2				* of the dbl prec. limits
	LSL.L	d2, d3				* shift g-r bits to the MSB of d3
	MOVE.L	FTEMP_LO(a0), d2		* get lower mantissa  for s-bit test
	AND.L	#$000001ff, d2			* s bit is the or-ing of all
	BNE	ext_grs_st_stky			* other bits to the right of g-r
	TST.L	d0				* test word original g,r,s
	BNE	ext_grs_st_stky			* if any are set, set sticky
	BRA	ext_grs_end_sd			* if clear, exit
ext_grs_st_stky:
	BSET	#rnd_stky_bit,d3		* set sticky bit
ext_grs_end_sd:	MOVE.L	d3,d0				* return grs to d0

	MOVEM.L	(sp)+,d2-d3			* restore scratch registers {d2/d3}
	SWAP	d1				* restore d1 to original
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* norm(): normalize the mantissa of an extended precision input. the
*	  input operand should not be normalized already.
**-------------------------------------------------------------------------------------------------
*
* XDEF **
*	norm()
*
* xdef ** *
*	none
*
* INPUT *************************************************************** *
*	a0 = pointer fp extended precision operand to normalize
*
* OUTPUT ************************************************************** *
* 	d0 = number of bit positions the mantissa was shifted
*	a0 = the input operand's mantissa is normalized; the exponent
*	     is unchanged.
*
**-------------------------------------------------------------------------------------------------

	xdef	norm
norm:	MOVEM.L	d2-d3,-(sp)		* create some temp regs

	MOVE.L	FTEMP_HI(a0),d0		* load hi(mantissa)
	MOVE.L	FTEMP_LO(a0),d1		* load lo(mantissa)

	BFFFO	d0{0:32},d2		* how many places to shift?
	BEQ	norm_lo			* hi(man) is all zeroes!

norm_hi:	LSL.L	d2, d0			* left shift hi(man)
	BFEXTU	d1{0:20}, d3		* extract lo bits

	OR.L	d3,d0			* create hi(man)
	LSL.L	d2,d1			* create lo(man)

	MOVE.L	d0,FTEMP_HI(a0)		* store new hi(man)
	MOVE.L	d1,FTEMP_LO(a0)		* store new lo(man)

	MOVE.L	d2,d0			* return shift amount
	MOVEM.L	(sp)+,d2-d3		* restore temp regs
	RTS

norm_lo:	BFFFO	d1{0:32},d2		* how many places to shift?
	LSL.L	d2,d1			* shift lo(man)
	ADD.L	#32,d2			* add 32 to shft amount

	MOVE.L	d1,FTEMP_HI(a0)		* store hi(man)
	CLR.L	FTEMP_LO(a0)		* lo(man) is now zero

	MOVE.L	d2,d0			* return shift amount
	MOVEM.L	(sp)+,d2-d3		* restore temp regs
	RTS




**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* unnorm_fix(): - changes an UNNORM to one of NORM, DENORM, or ZERO
*	- returns corresponding optype tag
**-------------------------------------------------------------------------------------------------
*
* XDEF :	unnorm_fix()
*
* xdef :
*	norm() - normalize the mantissa
*
* INPUT :
*	a0 = pointer to unnormalized extended precision number
*
* OUTPUT :
*	d0 = optype tag - is corrected to one of NORM, DENORM, or ZERO
*	a0 = input operand has been converted to a norm, denorm, or
*	     zero; both the exponent and mantissa are changed.
*
**-------------------------------------------------------------------------------------------------

	xdef	unnorm_fix
unnorm_fix:
	BFFFO	FTEMP_HI(a0){0:32}, d0 		* how many shifts are needed?
	BNE	unnorm_shift			* hi(man) is not all zeroes

	**--------------------------------------------------------------------------------
	* hi(man) is all zeroes so see if any bits in lo(man) are set
	*
unnorm_chk_lo:
	BFFFO	FTEMP_LO(a0){0:32},d0 		* is operand really a zero?
	BEQ	unnorm_zero			* yes
	ADD.W	#32,d0				* no; fix shift distance

	**--------------------------------------------------------------------------------
	* d0 = # shifts needed for complete normalization
	*
unnorm_shift:
	CLR.L	d1				* clear top word
	MOVE.W	FTEMP_EX(a0), d1		* extract exponent
	AND.W	#$7fff, d1			* strip off sgn

	CMP.W	d1,d0				* will denorm push exp < 0 ?      $$$$$$$$
	BGT	unnorm_nrm_zero			* yes; denorm only until exp = 0

	**--------------------------------------------------------------------------------
	* exponent would not go < 0. therefore, number stays normalized
	*
	SUB.W	d0,d1				* shift exponent value
	MOVE.W	FTEMP_EX(a0), d0		* load old exponent
	AND.W	#$8000,d0			* save old sign
	OR.W	d0,d1				* {sgn,new exp}
	MOVE.W	d1,FTEMP_EX(a0)			* insert new exponent

	BSR	norm				* normalize UNNORM
	MOVE.B	#NORM, d0			* return new optype tag
	RTS

	**--------------------------------------------------------------------------------
	* exponent would go < 0, so only denormalize until exp = 0
	*
unnorm_nrm_zero:
	CMP.b	#32,d1				* is exp <= 32?
	BGT	unnorm_nrm_zero_lrg		* no; go handle large exponent

	BFEXTU	FTEMP_HI(a0){d1:32},d0 		* extract new hi(man)
	MOVE.L	d0, FTEMP_HI(a0)		* save new hi(man)

	MOVE.L	FTEMP_LO(a0), d0		* fetch old lo(man)
	LSL.L	d1,d0				* extract new lo(man)
	MOVE.L	d0,FTEMP_LO(a0)			* save new lo(man)

	AND.W	#$8000,FTEMP_EX(a0)		* set exp = 0
	MOVE.B	#DENORM, d0			* return new optype tag
	RTS

	**--------------------------------------------------------------------------------
	*
	* only mantissa bits set are in lo(man)
	*
unnorm_nrm_zero_lrg:
	SUB.W	#32,d1				* adjust shft amt by 32

	MOVE.L	FTEMP_LO(a0),d0			* fetch old lo(man)
	LSL.L	d1,d0				* left shift lo(man)

	MOVE.L	d0,FTEMP_HI(a0)			* store new hi(man)
	CLR.L	FTEMP_LO(a0)			* lo(man) = 0

	AND.W	#$8000,FTEMP_EX(a0)		* set exp = 0

	MOVE.B	#DENORM,d0			* return new optype tag
	RTS

	**--------------------------------------------------------------------------------
	*
	* whole mantissa is zero so this UNNORM is actually a zero
	*
unnorm_zero:
	AND.W	#$8000, FTEMP_EX(a0) 		* force exponent to zero
	MOVE.B	#ZERO, d0			* fix optype tag
	RTS





**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** 	set_tag_x(): return the optype of the input ext fp number
**-------------------------------------------------------------------------------------------------
*
* xref :
*	None
*
* INPUT :
*	a0 = pointer to extended precision operand
*
* OUTPUT :
*	d0 = value of type tag
* 	one of: NORM, INF, QNAN, SNAN, DENORM, UNNORM, ZERO
*
* ALGORITHM :
*	Simply test the exponent, j-bit, and mantissa values to
* determine the type of operand.
*	If it's an unnormalized zero, alter the operand and force it
* to be a normal zero.
*
**-------------------------------------------------------------------------------------------------

	xdef	set_tag_x
set_tag_x:
	MOVE.W	FTEMP_EX(a0), d0	* extract exponent
	ANDI.W	#$7fff, d0		* strip off sign
	CMP.w	#$7fff,d0		* is (EXP == MAX)?
	BEQ	inf_or_nan_x
not_inf_or_nan_x:
	BTST	#$7,FTEMP_HI(a0)
	BEQ	not_norm_x
is_norm_x:
	MOVE.B	#NORM, d0
	RTS
not_norm_x:
	TST.W	d0			* is exponent = 0?
	BNE	is_unnorm_x
not_unnorm_x:
	TST.L	FTEMP_HI(a0)
	BNE	is_denorm_x
	TST.L	FTEMP_LO(a0)
	BNE	is_denorm_x
is_zero_x:
	MOVE.B	#ZERO, d0
	RTS
is_denorm_x:
	MOVE.B	#DENORM, d0
	RTS
	**--------------------------------------------------------------------------------
	* must distinguish now "Unnormalized zeroes" which we
	* must convert to zero.
is_unnorm_x:
	TST.L	FTEMP_HI(a0)
	BNE	is_unnorm_reg_x
	TST.L	FTEMP_LO(a0)
	BNE	is_unnorm_reg_x

	**--------------------------------------------------------------------------------
	* it's an "unnormalized zero". let's convert it to an actual zero...

	ANDI.W	#$8000,FTEMP_EX(a0)	* clear exponent
	MOVE.B	#ZERO, d0
	RTS
is_unnorm_reg_x:
	MOVE.B	#UNNORM, d0
	RTS
inf_or_nan_x:
	TST.L	FTEMP_LO(a0)
	BNE	is_nan_x
	MOVE.L	FTEMP_HI(a0), d0
	AND.L	#$7fffffff, d0		* msb is a don't care!
	BNE	is_nan_x
is_inf_x:
	MOVE.B	#INF, d0
	RTS
is_nan_x:
	BTST	#$6, FTEMP_HI(a0)
	BEQ.B	is_snan_x
	MOVE.B	#QNAN, d0
	RTS
is_snan_x:
	MOVE.B	#SNAN, d0
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** 	set_tag_d(): return the optype of the input dbl fp number
**-------------------------------------------------------------------------------------------------
*
* xdef :
*	None
*
* INPUT :
*	a0 = points to double precision operand
*
* OUTPUT :
*	d0 = value of type tag
* 	one of: NORM, INF, QNAN, SNAN, DENORM, ZERO
*
* ALGORITHM :
*	Simply test the exponent, j-bit, and mantissa values to
* determine the type of operand.
*
**-------------------------------------------------------------------------------------------------

	xdef	set_tag_d
set_tag_d:	MOVE.L	FTEMP(a0), d0
	MOVE.L	d0, d1

	ANDI.L	#$7ff00000, d0
	BEQ	zero_or_denorm_d

	CMP.l	#$7ff00000,d0
	BEQ	inf_or_nan_d

is_norm_d:	MOVE.B	#NORM, d0
	RTS

zero_or_denorm_d:
	AND.L	#$000fffff, d1
	BNE	is_denorm_d

	TST.L	FTEMP+4(a0)
	BNE	is_denorm_d
is_zero_d:
	MOVE.B	#ZERO,d0
	RTS
is_denorm_d:
	MOVE.B	#DENORM,d0
	RTS
inf_or_nan_d:	AND.L	#$000fffff, d1
	BNE	is_nan_d
	TST.L	FTEMP+4(a0)
	BNE	is_nan_d
is_inf_d:
	MOVE.B	#INF, d0
	RTS
is_nan_d:	BTST	#19, d1
	BNE	is_qnan_d
is_snan_d:
	MOVE.B	#SNAN, d0
	RTS
is_qnan_d:
	MOVE.B	#QNAN, d0
	RTS

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* 	set_tag_s(): return the optype of the input sgl fp number
**-------------------------------------------------------------------------------------------------
* xdef **
*	None
*
* INPUT ***************************************************************
*	a0 = pointer to single precision operand
*
* OUTPUT **************************************************************
*	d0 = value of type tag
* 	one of: NORM, INF, QNAN, SNAN, DENORM, ZERO
*
* ALGORITHM ***********************************************************
*	Simply test the exponent, j-bit, and mantissa values to
* determine the type of operand.
*
**-------------------------------------------------------------------------------------------------

	xdef	set_tag_s
set_tag_s:
	MOVE.L	FTEMP(a0), d0
	MOVE.L	d0, d1

	ANDI.L	#$7f800000, d0
	BEQ	zero_or_denorm_s

	CMP.l	#$7f800000,d0
	BEQ	inf_or_nan_s
is_norm_s:	MOVE.B	#NORM, d0
	RTS
zero_or_denorm_s:
	AND.L	#$007fffff,d1
	BNE	is_denorm_s
is_zero_s:	MOVE.B	#ZERO,d0
	RTS
is_denorm_s:
	MOVE.B	#DENORM,d0
	RTS
inf_or_nan_s:
	AND.L	#$007fffff,d1
	BNE	is_nan_s
is_inf_s:	MOVE.B	#INF, d0
	RTS
is_nan_s:
	BTST	#22, d1
	BNE	is_qnan_s
is_snan_s:	MOVE.B	#SNAN, d0
	RTS
is_qnan_s:
	MOVE.B	#QNAN, d0
	RTS

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* unf_res(): 	routine to produce default underflow result of a
*	scaled extended precision number; this is used by
*	fadd/fdiv/fmul/etc. emulation routines.
* unf_res4(): 	same as above but for fsglmul/fsgldiv which use
*	single round prec and extended prec mode.
**-------------------------------------------------------------------------------------------------
*
* xdef :
*	_denorm() - denormalize according to scale factor
* 	_round() - round denormalized number according to rnd prec
*
* INPUT :
*	a0 = pointer to extended precison operand
*	d0 = scale factor
*	d1 = rounding precision/mode
*
* OUTPUT :
*	a0 = pointer to default underflow result in extended precision
*	d0.b = result EXC_LV+FPSR_cc which caller may or may not want to save
*
* ALGORITHM :
*
*  Convert  the input operand to "internal format" which means the exponent is extended to 16
* bits  and  the  sign  is  stored  in  the  unused portion of the extended precison operand.
* Denormalize  the  number  according  to  the  scale  factor  passed in d0.  Then, round the
* denormalized result.
*
*  Set  the  EXC_LV+FPSR_exc  bits  as  appropriate  but return the cc bits in d0 in case the
* caller doesn't want to save them (as is the case for fmove out).
*
*  unf_res4()  for  fsglmul/fsgldiv  forces the denorm to extended precision and the rounding
* mode to single.
**-------------------------------------------------------------------------------------------------
	xdef	unf_res
unf_res:
                DBUG	10,"** Underflow called"

	MOVE.L	d1, -(sp)		* save rnd prec,mode on stack

	BTST	#$7, FTEMP_EX(a0)	* make "internal" format
	SNE	FTEMP_SGN(a0)

	MOVE.W	FTEMP_EX(a0), d1	* extract exponent
	AND.W	#$7fff, d1
	SUB.W	d0, d1
	MOVE.W	d1, FTEMP_EX(a0)	* insert 16 bit exponent

	MOVE.L	a0, -(sp)		* save operand ptr during calls

	MOVE.L	$4(sp),d0		* pass rnd prec.
	ANDI.W	#$00c0,d0
	LSR.W	#$4,d0
	BSR	_denorm			* denorm result

	MOVE.L	(sp),a0
	MOVE.W	$6(sp),d1		* load prec:mode into d1
	ANDI.W	#$c0,d1			* extract rnd prec
	LSR.W	#$4,d1
	SWAP	d1
	MOVE.W	$6(sp),d1
	ANDI.W	#$30,d1
	LSR.W	#$4,d1
	BSR	_round			* round the denorm

	MOVE.L	(sp)+, a0

                *+------------------------------------------------------------------------------
	* result is now rounded properly. convert back to normal format

	BCLR	#$7, FTEMP_EX(a0)	* clear sgn first; may have residue
	TST.B	FTEMP_SGN(a0)		* is "internal result" sign set?
	BEQ	unf_res_chkifzero	* no; result is positive

	BSET	#$7, FTEMP_EX(a0)	* set result sgn
	CLR.B	FTEMP_SGN(a0)		* clear temp sign

                *+------------------------------------------------------------------------------
	* the number may have become zero after rounding. set ccodes accordingly.
unf_res_chkifzero:
	CLR.L	d0
	TST.L	FTEMP_HI(a0)		* is value now a zero?
	BNE	unf_res_cont		* no
	TST.L	FTEMP_LO(a0)
	BNE	unf_res_cont		* no

*	bset	#z_bit, EXC_LV+FPSR_CC(a6)	* yes; set zero ccode bit
	BSET	#z_bit,d0		* yes; set zero ccode bit
unf_res_cont:

                *+------------------------------------------------------------------------------
	* can inex1 also be set along with unfl and inex2  ???
	*
	* we know that underflow has occurred. aunfl should be set if INEX2 is also set.
	*
	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6) 	* is INEX2 set?
	BEQ	unf_res_end				* no

	BSET	#aunfl_bit, EXC_LV+FPSR_AEXCEPT(a6) 	* yes; set aunfl
unf_res_end:	ADD.L	#$4,sp					* clear stack
	RTS

                *+------------------------------------------------------------------------------
                *+------------------------------------------------------------------------------
	* unf_res() for fsglmul() and fsgldiv().

	xdef	unf_res4
unf_res4:	MOVE.L	d1,-(sp)		* save rnd prec,mode on stack

	BTST	#$7,FTEMP_EX(a0)	* make "internal" format
	SNE	FTEMP_SGN(a0)

	MOVE.W	FTEMP_EX(a0),d1		* extract exponent
	AND.W	#$7fff,d1
	SUB.W	d0,d1
	MOVE.W	d1,FTEMP_EX(a0)		* insert 16 bit exponent

	MOVE.L	a0,-(sp)		* save operand ptr during calls

	CLR.L	d0			* force rnd prec = ext
	BSR	_denorm			* denorm result

	MOVE.L	(sp),a0
	MOVE.W	#s_mode,d1		* force rnd prec = sgl
	SWAP	d1

	MOVE.W	$6(sp),d1		* load rnd mode
	ANDI.W	#$30,d1			* extract rnd prec
	LSR.W	#$4,d1
	BSR	_round			* round the denorm

	MOVE.L	(sp)+,a0

                *+------------------------------------------------------------------------------
	* result is now rounded properly. convert back to normal format

	BCLR	#$7,FTEMP_EX(a0)	* clear sgn first; may have residue
	TST.B	FTEMP_SGN(a0)		* is "internal result" sign set?
	BEQ	unf_res4_chkifzero	* no; result is positive
	BSET	#$7,FTEMP_EX(a0)	* set result sgn
	CLR.B	FTEMP_SGN(a0)		* clear temp sign

                *+------------------------------------------------------------------------------
	* the number may have become zero after rounding. set ccodes accordingly.
unf_res4_chkifzero:
	CLR.L	d0
	TST.L	FTEMP_HI(a0)		* is value now a zero?
	BNE	unf_res4_cont		* no
	TST.L	FTEMP_LO(a0)
	BNE	unf_res4_cont		* no

*	bset	#z_bit,EXC_LV+FPSR_CC(a6)	* yes; set zero ccode bit
	BSET	#z_bit,d0		* yes; set zero ccode bit

unf_res4_cont:

                *+------------------------------------------------------------------------------
	*
	* can inex1 also be set along with unfl and inex2???
	*
	* we know that underflow has occurred. aunfl should be set if INEX2 is also set.
	*
	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6) 	* is INEX2 set?
	BEQ	unf_res4_end				* no
	bset	#aunfl_bit,EXC_LV+FPSR_AEXCEPT(a6) 	* yes; set aunfl

unf_res4_end:	ADD.L	#$4,sp					* clear stack
	RTS



**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* ovf_res(): 	routine to produce the default overflow result of
*	an overflowing number.
* ovf_res2():	same as above but the rnd mode/prec are passed
*	differently.
**-------------------------------------------------------------------------------------------------
*
* xdef :	none
*
* INPUT :
*	d1.b 	= '-1' => (-); '0' => (+)
*   ovf_res():
*	d0 	= rnd mode/prec
*   ovf_res2():
*	hi(d0) 	= rnd prec
*	lo(d0)	= rnd mode
*
* OUTPUT :
*	a0   	= points to extended precision result
*	d0.b 	= condition code bits
*
* ALGORITHM :
*	The default overflow result can be determined by the sign of
* the result and the rounding mode/prec in effect. These bits are
* concatenated together to create an index into the default result
* table. A pointer to the correct result is returned in a0. The
* resulting condition codes are returned in d0 in case the caller
* doesn't want EXC_LV+FPSR_cc altered (as is the case for fmove out).
*
**-------------------------------------------------------------------------------------------------

	xdef	ovf_res
ovf_res:
	ANDI.W	#$10,d1		* keep result sign
	LSR.B	#$4,d0		* shift prec/mode
	OR.B	d0,d1		* concat the two
	MOVE.W	d1,d0		* make a copy
	LSL.B	#$1,d1		* multiply d1 by 2
	BRA	ovf_res_load

	xdef	ovf_res2
ovf_res2:
	AND.W	#$10, d1	* keep result sign
	OR.B	d0, d1		* insert rnd mode
	SWAP	d0
	OR.B	d0, d1		* insert rnd prec
	MOVE.W	d1, d0		* make a copy
	LSL.B	#$1, d1		* shift left by 1

                *+------------------------------------------------------------------------------
	* use the rounding mode, precision, and result sign as in index into the
	* two tables below to fetch the default result and the result ccodes.
	*
ovf_res_load:
	MOVE.B	((tbl_ovfl_cc).b,pc,d0.w*1),d0 		* fetch result ccodes
	LEA	((tbl_ovfl_result).b,pc,d1.w*8),a0 	* return result ptr
	RTS

tbl_ovfl_cc:	dc.b	$2, $0, $0, $2
	dc.b	$2, $0, $0, $2
	dc.b	$2, $0, $0, $2
	dc.b	$0, $0, $0, $0
	dc.b	$2+$8, $8, $2+$8, $8
	dc.b	$2+$8, $8, $2+$8, $8
	dc.b	$2+$8, $8, $2+$8, $8

tbl_ovfl_result:
	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RN
	dc.l	$7ffe0000,$ffffffff,$ffffffff,$00000000 * +EXT; RZ
	dc.l	$7ffe0000,$ffffffff,$ffffffff,$00000000 * +EXT; RM
	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RP

	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RN
	dc.l	$407e0000,$ffffff00,$00000000,$00000000 * +SGL; RZ
	dc.l	$407e0000,$ffffff00,$00000000,$00000000 * +SGL; RM
	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RP

	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RN
	dc.l	$43fe0000,$ffffffff,$fffff800,$00000000 * +DBL; RZ
	dc.l	$43fe0000,$ffffffff,$fffff800,$00000000 * +DBL; RM
	dc.l	$7fff0000,$00000000,$00000000,$00000000 * +INF; RP

	dc.l	$00000000,$00000000,$00000000,$00000000
	dc.l	$00000000,$00000000,$00000000,$00000000
	dc.l	$00000000,$00000000,$00000000,$00000000
	dc.l	$00000000,$00000000,$00000000,$00000000

	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RN
	dc.l	$fffe0000,$ffffffff,$ffffffff,$00000000 * -EXT; RZ
	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RM
	dc.l	$fffe0000,$ffffffff,$ffffffff,$00000000 * -EXT; RP

	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RN
	dc.l	$c07e0000,$ffffff00,$00000000,$00000000 * -SGL; RZ
	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RM
	dc.l	$c07e0000,$ffffff00,$00000000,$00000000 * -SGL; RP

	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RN
	dc.l	$c3fe0000,$ffffffff,$fffff800,$00000000 * -DBL; RZ
	dc.l	$ffff0000,$00000000,$00000000,$00000000 * -INF; RM
	dc.l	$c3fe0000,$ffffffff,$fffff800,$00000000 * -DBL; RP




**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* get_packed(): fetch a packed operand from memory and then
*	convert it to a floating-point binary number.
**-------------------------------------------------------------------------------------------------
*
* xdef :
*	_dcalc_ea() - calculate the correct <ea>
*	_mem_read() - fetch the packed operand from memory
*	facc_in_x() - the fetch failed so jump to special exit code
*	decbin()    - convert packed to binary extended precision
*
* INPUT :
*	None
*
* OUTPUT :
*	If no failure on _mem_read():
* 	EXC_LV+FP_SRC(a6) = packed operand now as a binary FP number
*
* ALGORITHM :
*	Get the correct <ea> whihc is the value on the exception stack
* frame w/ maybe a correction factor if the <ea> is -(an) or (an)+.
* Then, fetch the operand from memory. If the fetch fails, exit
* through facc_in_x().
*	If the packed operand is a ZERO,NAN, or INF, convert it to
* its binary representation here. Else, call decbin() which will
* convert the packed value to an extended precision binary value.
*
**-------------------------------------------------------------------------------------------------

                *+------------------------------------------------------------------------------
	* the stacked <ea> for packed is correct except for -(An).
	* the base reg must be updated for both -(An) and (An)+.

	xdef	get_packed
get_packed:
	MOVE.L	#$c,d0			* packed is 12 bytes
	BSR	_dcalc_ea		* fetch <ea>; correct An

	LEA	EXC_LV+FP_SRC(a6),a1	* pass: ptr to super dst
	MOVE.L	#$c,d0			* pass: 12 bytes

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)

                *+------------------------------------------------------------------------------
	* The packed operand is an INF or a NAN if the exponent field is all ones.

	BFEXTU	EXC_LV+FP_SRC(a6){1:15},d0	* get exp
	CMP.w	#$7fff,d0			* INF or NAN?
	BNE	gp_try_zero			* no
	RTS					* operand is an INF or NAN

                *+------------------------------------------------------------------------------
	* The packed operand is a zero if the mantissa is all zero, else it's
	* a normal packed op.
gp_try_zero:
	MOVE.B	EXC_LV+FP_SRC+3(a6),d0		* get byte 4
	ANDI.B	#$0f,d0				* clear all but last nybble
	BNE	gp_not_spec			* not a zero

	TST.L	EXC_LV+FP_SRC_HI(a6)		* is lw 2 zero?
	BNE	gp_not_spec			* not a zero
	TST.L	EXC_LV+FP_SRC_LO(a6)		* is lw 3 zero?
	BNE	gp_not_spec			* not a zero
	RTS					* operand is a ZERO
gp_not_spec:
	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to packed op
	BSR	decbin				* convert to extended
	FMOVEM.X	fp0,EXC_LV+FP_SRC(a6)		* make this the srcop
	RTS

**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* decbin(): Converts normalized packed bcd value pointed to by register
*	    a0 to extended-precision value in fp0.
*
**-------------------------------------------------------------------------------------------------
*
* INPUT :
*	a0 = pointer to normalized packed bcd value
*
* OUTPUT :
*	fp0 = exact fp representation of the packed bcd value.
*
* ALGORITHM :
*	Expected is a normal bcd (i.e. non-exceptional; all inf, zero,
*	and NaN operands are dispatched without entering this routine)
*	value in 68881/882 format at location (a0).
*
*	A1. Convert the bcd exponent to binary by successive adds and
*	muls. Set the sign according to SE. Subtract 16 to compensate
*	for the mantissa which is to be interpreted as 17 integer
*	digits, rather than 1 integer and 16 fraction digits.
*	Note: this operation can never overflow.
*
*	A2. Convert the bcd mantissa to binary by successive
*	adds and muls in FP0. Set the sign according to SM.
*	The mantissa digits will be converted with the decimal point
*	assumed following the least-significant digit.
*	Note: this operation can never overflow.
*
*	A3. Count the number of leading/trailing zeros in the
*	bcd string.  If SE is positive, count the leading zeros;
*	if negative, count the trailing zeros.  Set the adjusted
*	exponent equal to the exponent from A1 and the zero count
*	added if SM = 1 and subtracted if SM = 0.  Scale the
*	mantissa the equivalent of forcing in the bcd value:
*
*	SM = 0	a non-zero digit in the integer position
*	SM = 1	a non-zero digit in Mant0, lsd of the fraction
*
*	this will insure that any value, regardless of its
*	representation (ex. 0.1E2, 1E1, 10E0, 100E-1), is converted
*	consistently.
*
*	A4. Calculate the factor 10^exp in FP1 using a table of
*	10^(2^n) values.  To reduce the error in forming factors
*	greater than 10^27, a directed rounding scheme is used with
*	tables rounded to RN, RM, and RP, according to the table
*	in the comments of the pwrten section.
*
*	A5. Form the final binary number by scaling the mantissa by
*	the exponent factor.  This is done by multiplying the
*	mantissa in FP0 by the factor in FP1 if the adjusted
*	exponent sign is positive, and dividing FP0 by FP1 if
*	it is negative.
*
*	Clean up and return. Check if the final mul or div was inexact.
*	If so, set INEX1 in USER_FPSR.
*
**-------------------------------------------------------------------------------------------------


                *+------------------------------------------------------------------------------
	*	PTENRN, PTENRM, and PTENRP are arrays of powers of 10 rounded
	*	to nearest, minus, and plus, respectively.  The tables include
	*	10**{1,2,4,8,16,32,64,128,256,512,1024,2048,4096}.  No rounding
	*	is required until the power is greater than 27, however, all
	*	tables include the first 5 for ease of indexing.
	*
RTABLE:	dc.b	0,0,0,0
	dc.b	2,3,2,3
	dc.b	2,3,3,2
	dc.b	3,2,2,3

FNIBS	equ	7
FSTRT	equ	0

ESTRT	equ	4
EDIGITS	equ	2

	xdef	decbin
decbin:	MOVE.L	$0(a0),EXC_LV+FP_SCR0_EX(a6) 	* make a copy of input
	MOVE.L	$4(a0),EXC_LV+FP_SCR0_HI(a6) 	* so we don't alter it
	MOVE.L	$8(a0),EXC_LV+FP_SCR0_LO(a6)

	LEA	EXC_LV+FP_SCR0(a6),a0

	MOVEM.L	d2-d5,-(sp)			* save d2-d5
	FMOVEM.X	fp0,-(sp)			* save fp0

                *+------------------------------------------------------------------------------
	*
	* Calculate exponent:
	*  1. Copy bcd value in memory for use as a working copy.
	*  2. Calculate absolute value of exponent in d1 by mul and add.
	*  3. Correct for exponent sign.
	*  4. Subtract 16 to compensate for interpreting the mant as all integer digits.
	*     (i.e., all digits assumed left of the decimal point.)
	*
	* Register usage:
	*
	*  calc_e:
	*	(*)  d0: temp digit storage
	*	(*)  d1: accumulator for binary exponent
	*	(*)  d2: digit count
	*	(*)  d3: offset pointer
	*	( )  d4: first word of bcd
	*	( )  a0: pointer to working bcd value
	*	( )  a6: pointer to original bcd value
	*	(*)  EXC_LV+FP_SCR1: working copy of original bcd value
	*	(*)  EXC_LV+L_SCR1: copy of original exponent word
	*
calc_e:	MOVE.L	#EDIGITS,d2	* * of nibbles (digits) in fraction part
	MOVE.L	#ESTRT,d3	* counter to pick up digits
	MOVE.L	(a0),d4		* get first word of bcd
	CLR.L	d1		* zero d1 for accumulator
e_gd:
	MULU.L	#$a,d1		* mul partial product by one digit place
	BFEXTU	d4{d3:4},d0	* get the digit and zero extend into d0
	ADD.L	d0,d1		* d1 = d1 + d0
	ADDQ.B	#4,d3		* advance d3 to the next digit
	DBF	d2,e_gd		* if we have used all 3 digits, exit loop

	BTST	#30,d4		* get SE
	BEQ	e_pos		* don't negate if pos
	NEG.L	d1		* negate before subtracting
e_pos:
	SUB.L	#16,d1		* sub to compensate for shift of mant
	BGE	e_save		* if still pos, do not neg
	NEG.L	d1		* now negative, make pos and set SE
	OR.L	#$40000000,d4	* set SE in d4,
	OR.L	#$40000000,(a0)	* and in working bcd
e_save:
	MOVE.L	d1,-(sp)	* save exp on stack
                *+------------------------------------------------------------------------------
	* Calculate mantissa:
	*  1. Calculate absolute value of mantissa in fp0 by mul and add.
	*  2. Correct for mantissa sign.
	*     (i.e., all digits assumed left of the decimal point.)
	*
	* Register usage:
	*
	*  calc_m:
	*	(*)  d0: temp digit storage
	*	(*)  d1: lword counter
	*	(*)  d2: digit count
	*	(*)  d3: offset pointer
	*	( )  d4: words 2 and 3 of bcd
	*	( )  a0: pointer to working bcd value
	*	( )  a6: pointer to original bcd value
	*	(*) fp0: mantissa accumulator
	*	( )  EXC_LV+FP_SCR1: working copy of original bcd value
	*	( )  EXC_LV+L_SCR1: copy of original exponent word
	*
calc_m:
	MOVE.L	#1,d1		* word counter, init to 1
	FMOVE.S	#$00000000,fp0	* accumulator

                *+------------------------------------------------------------------------------
	*  Since the packed number has a dc.l word between the first # second parts,
	*  get the integer digit then skip down # get the rest of the
	*  mantissa.  We will unroll the loop once.
	*
	BFEXTU	(a0){28:4},d0	* integer part is ls digit in dc.l word
	FADD.B	d0,fp0		* add digit to sum in fp0

                *+------------------------------------------------------------------------------
	*  Get the rest of the mantissa.
	*
loadlw:
	MOVE.L	(a0,d1.L*4),d4	* load mantissa lonqword into d4
	MOVE.L	#FSTRT,d3	* counter to pick up digits
	MOVE.L	#FNIBS,d2	* reset number of digits per a0 ptr
md2b:
	FMUL.S	#$41200000,fp0	* fp0 = fp0 * 10
	BFEXTU	d4{d3:4},d0	* get the digit and zero extend
	FADD.B	d0,fp0		* fp0 = fp0 + digit

                *+------------------------------------------------------------------------------
	*  If all the digits (8) in that dc.l word have been converted (d2=0),
	*  then inc d1 (=2) to point to the next dc.l word and reset d3 to 0
	*  to initialize the digit offset, and set d2 to 7 for the digit count;
	*  else continue with this dc.l word.
	*
	ADDQ.B	#4,d3		* advance d3 to the next digit
	DBF	d2,md2b		* check for last digit in this lw
nextlw:
	ADDQ.L	#1,d1		* inc lw pointer in mantissa
	CMP.l	#2,d1		* test for last lw
	BLE	loadlw		* if not, get last one

                *+------------------------------------------------------------------------------
	*  Check the sign of the mant and make the value in fp0 the same sign.
m_sign:
*	btst	#31,(a0)	* test sign of the mantissa
	BEQ	ap_st_z		* if clear, go to append/strip zeros
	FNEG.X	fp0		* if set, negate fp0

                *+------------------------------------------------------------------------------
	* Append/strip zeros:
	*
	*  For adjusted exponents which have an absolute value greater than 27*,
	*  this routine calculates the amount needed to normalize the mantissa
	*  for the adjusted exponent.  That number is subtracted from the exp
	*  if the exp was positive, and added if it was negative.  The purpose
	*  of this is to reduce the value of the exponent and the possibility
	*  of error in calculation of pwrten.
	*
	*  1. Branch on the sign of the adjusted exponent.
	*  2p.(positive exp)
	*   2. Check M16 and the digits in lwords 2 and 3 in decending order.
	*   3. Add one for each zero encountered until a non-zero digit.
	*   4. Subtract the count from the exp.
	*   5. Check if the exp has crossed zero in *3 above; make the exp abs
	*	   and set SE.
	*	6. Multiply the mantissa by 10**count.
	*  2n.(negative exp)
	*   2. Check the digits in lwords 3 and 2 in decending order.
	*   3. Add one for each zero encountered until a non-zero digit.
	*   4. Add the count to the exp.
	*   5. Check if the exp has crossed zero in *3 above; clear SE.
	*   6. Divide the mantissa by 10**count.
	*
	*  *Why 27?  If the adjusted exponent is within -28 < expA < 28, than
	*   any adjustment due to append/strip zeros will drive the resultane
	*   exponent towards zero.  Since all pwrten constants with a power
	*   of 27 or less are exact, there is no need to use this routine to
	*   attempt to lessen the resultant exponent.
	*
	* Register usage:
	*
	*  ap_st_z:
	*	(*)  d0: temp digit storage
	*	(*)  d1: zero count
	*	(*)  d2: digit count
	*	(*)  d3: offset pointer
	*	( )  d4: first word of bcd
	*	(*)  d5: lword counter
	*	( )  a0: pointer to working bcd value
	*	( )  EXC_LV+FP_SCR1: working copy of original bcd value
	*	( )  EXC_LV+L_SCR1: copy of original exponent word
	*
	*
	* First check the absolute value of the exponent to see if this
	* routine is necessary.  If so, then check the sign of the exponent
	* and do append (+) or strip (-) zeros accordingly.
	* This section handles a positive adjusted exponent.
	*
ap_st_z:
	MOVE.L	(sp),d1			* load expA for range test
	CMP.l	#27,d1			* test is with 27
	BLE	pwrten			* if abs(expA) <28, skip ap/st zeros
	BTST	#0,(a0)			* check sign of exp
	BNE	ap_st_n			* if neg, go to neg side
	CLR.L	d1			* zero count reg
	MOVE.L	(a0),d4			* load lword 1 to d4
	BFEXTU	d4{28:4},d0		* get M16 in d0
	BNE	ap_p_fx			* if M16 is non-zero, go fix exp
	addq.l	#1,d1			* inc zero count
	MOVE.L	#1,d5			* init lword counter
	MOVE.L	(a0,d5.L*4),d4		* get lword 2 to d4
	BNE	ap_p_cl			* if lw 2 is zero, skip it
	ADDQ.L	#8,d1			* and inc count by 8
	ADDQ.L	#1,d5			* inc lword counter
	MOVE.L	(a0,d5.L*4),d4		* get lword 3 to d4
ap_p_cl:	CLR.L	d3			* init offset reg
	MOVE.L	#7,d2			* init digit counter

ap_p_gd:	BFEXTU	d4{d3:4},d0		* get digit
	BNE	ap_p_fx			* if non-zero, go to fix exp
	ADDQ.L	#4,d3			* point to next digit
	ADDQ.L	#1,d1			* inc digit counter
	DBF	d2,ap_p_gd		* get next digit
ap_p_fx:
	MOVE.L	d1,d0			* copy counter to d2
	MOVE.L	(sp),d1			* get adjusted exp from memory
	SUB.L	d0,d1			* subtract count from exp
	BGE.B	ap_p_fm			* if still pos, go to pwrten
	NEG.L	d1			* now its neg; get abs
	MOVE.L	(a0),d4			* load lword 1 to d4
	OR.L	#$40000000,d4		* and set SE in d4
	OR.L	#$40000000,(a0)		* and in memory

                *+------------------------------------------------------------------------------
	* Calculate the mantissa multiplier to compensate for the striping of
	* zeros from the mantissa.
	*
ap_p_fm:
	LEA.l	PTENRN(pc),a1		* get address of power-of-ten table
	CLR.L	d3			* init table index
	FMOVE.S	#$3f800000,fp1		* init fp1 to 1
	MOVE.L	#3,d2			* init d2 to count bits in counter
ap_p_el:	ASR.L	#1,d0			* shift lsb into carry
	BCC	ap_p_en			* if 1, mul fp1 by pwrten factor
	FMUL.X	(a1,d3),fp1		* mul by 10**(d3_bit_no)
ap_p_en:
	ADD.L	#12,d3			* inc d3 to next rtable entry
	TST.L	d0			* check if d0 is zero
	BNE	ap_p_el			* if not, get next bit
	FMUL.X	fp1,fp0			* mul mantissa by 10**(no_bits_shifted)
	BRA	pwrten			* go calc pwrten

                *+------------------------------------------------------------------------------
	* This section handles a negative adjusted exponent.
	*
ap_st_n:
	CLR.L	d1		* clr counter
	MOVE.L	#2,d5		* set up d5 to point to lword 3
	MOVE.L	(a0,d5.L*4),d4	* get lword 3
	BNE	ap_n_cl		* if not zero, check digits
	SUB.L	#1,d5		* dec d5 to point to lword 2
	ADDQ.L	#8,d1		* inc counter by 8
	MOVE.L	(a0,d5.L*4),d4	* get lword 2
ap_n_cl:
	MOVE.L	#28,d3		* point to last digit
	MOVE.L	#7,d2		* init digit counter
ap_n_gd:
	BFEXTU	d4{d3:4},d0	* get digit
	BNE	ap_n_fx		* if non-zero, go to exp fix
	SUBQ.L	#4,d3		* point to previous digit
	ADDQ.L	#1,d1		* inc digit counter
	DBF	d2,ap_n_gd	* get next digit
ap_n_fx:
	MOVE.L	d1,d0		* copy counter to d0
	MOVE.L	(sp),d1		* get adjusted exp from memory
	SUB.L	d0,d1		* subtract count from exp
	BGT.B	ap_n_fm		* if still pos, go fix mantissa
	NEG.L	d1		* take abs of exp and clr SE
	MOVE.L	(a0),d4		* load lword 1 to d4
	AND.L	#$bfffffff,d4	* and clr SE in d4
	AND.L	#$bfffffff,(a0)	* and in memory

                *+------------------------------------------------------------------------------
                * Calculate the mantissa multiplier to compensate for the appending of
	* zeros to the mantissa.
	*
ap_n_fm:
	LEA	PTENRN(pc),a1	* get address of power-of-ten table
	CLR.L	d3		* init table index
	FMOVE.S	#$3f800000,fp1	* init fp1 to 1
	MOVE.L	#3,d2		* init d2 to count bits in counter
ap_n_el:
	ASR.L	#1,d0		* shift lsb into carry
	BCC	ap_n_en		* if 1, mul fp1 by pwrten factor
	FMUL.X	(a1,d3),fp1	* mul by 10**(d3_bit_no)
ap_n_en:
	ADD.L	#12,d3		* inc d3 to next rtable entry
	TST.L	d0		* check if d0 is zero
	BNE	ap_n_el		* if not, get next bit
	FDIV.X	fp1,fp0		* div mantissa by 10**(no_bits_shifted)

                *+------------------------------------------------------------------------------
	* Calculate power-of-ten factor from adjusted and shifted exponent.
	* Register usage:
	*
	*  pwrten:
	*	(*)  d0: temp
	*	( )  d1: exponent
	*	(*)  d2: {FPCR[6:5],SM,SE} as index in RTABLE; temp
	*	(*)  d3: FPCR work copy
	*	( )  d4: first word of bcd
	*	(*)  a1: RTABLE pointer
	*  calc_p:
	*	(*)  d0: temp
	*	( )  d1: exponent
	*	(*)  d3: PWRTxx table index
	*	( )  a0: pointer to working copy of bcd
	*	(*)  a1: PWRTxx pointer
	*	(*) fp1: power-of-ten accumulator
	*
	* Pwrten calculates the exponent factor in the selected rounding mode
	* according to the following table:
	*
	*	Sign of Mant  Sign of Exp  Rounding Mode  PWRTEN Rounding Mode
	*
	*	ANY	  ANY	RN	RN
	*
	*	 +	   +	RP	RP
	*	 -	   +	RP	RM
	*	 +	   -	RP	RM
	*	 -	   -	RP	RP
	*
	*	 +	   +	RM	RM
	*	 -	   +	RM	RP
	*	 +	   -	RM	RP
	*	 -	   -	RM	RM
	*
	*	 +	   +	RZ	RM
	*	 -	   +	RZ	RM
	*	 +	   -	RZ	RP
	*	 -	   -	RZ	RP
	*
	*
pwrten:
	MOVE.L	EXC_LV+USER_FPCR(a6),d3		* get user's FPCR
	BFEXTU	d3{26:2},d2			* isolate rounding mode bits
	MOVE.L	(a0),d4				* reload 1st bcd word to d4
	ASL.L	#2,d2				* format d2 to be
	BFEXTU	d4{0:2},d0			* {FPCR[6],FPCR[5],SM,SE}
	ADD.L	d0,d2				* in d2 as index into RTABLE
	LEA.l	RTABLE(pc),a1			* load rtable base
	MOVE.B	(a1,d2),d0			* load new rounding bits from table
	CLR.L	d3				* clear d3 to force no exc and extended
	BFINS	d0,d3{26:2}			* stuff new rounding bits in FPCR
	FMOVE.L	d3,fpcr				* write new FPCR
	ASR.L	#1,d0				* write correct PTENxx table
	BCC	not_rp				* to a1
	LEA.l	PTENRP(pc),a1			* it is RP
	BRA	calc_p				* go to init section
not_rp:
	ASR.L	#1,d0				* keep checking
	BCC	not_rm
	LEA.l	PTENRM(pc),a1			* it is RM
	BRA	calc_p				* go to init section
not_rm:
	LEA	PTENRN(pc),a1			* it is RN
calc_p:
	MOVE.L	d1,d0			* copy exp to d0;use d0
	bpl.b	no_neg			* if exp is negative,
	neg.l	d0			* invert it
	OR.L	#$40000000,(a0)		* and set SE bit
no_neg:
	CLR.L	d3			* table index
	FMOVE.S	#$3f800000,fp1		* init fp1 to 1
e_loop:
	ASR.L	#1,d0			* shift next bit into carry
	BCC	e_next			* if zero, skip the mul
	FMUL.X	(a1,d3),fp1		* mul by 10**(d3_bit_no)
e_next:
	ADD.L	#12,d3			* inc d3 to next rtable entry
	TST.L	d0			* check if d0 is zero
	BNE	e_loop			* not zero, continue shifting

                *+------------------------------------------------------------------------------
	*  Check the sign of the adjusted exp and make the value in fp0 the
	*  same sign. If the exp was pos then multiply fp1*fp0;
	*  else divide fp0/fp1.
	*
	* Register Usage:
	*  norm:
	*	( )  a0: pointer to working bcd value
	*	(*) fp0: mantissa accumulator
	*	( ) fp1: scaling factor - 10**(abs(exp))
	*
pnorm:
	BTST	#0,(a0)		* test the sign of the exponent
	BEQ	mul		* if clear, go to multiply
div:
	FDIV.x	fp1,fp0		* exp is negative, so divide mant by exp
	BRA	end_dec
mul:
	FMUL.x	fp1,fp0		* exp is positive, so multiply by exp

                *+------------------------------------------------------------------------------
	* Clean up and return with result in fp0.
	*
	* If the final mul/div in decbin incurred an inex exception,
	* it will be inex2, but will be reported as inex1 by get_op.
	*
end_dec:
	FMOVE.L	fpsr,d0			* get status register
	BCLR	#inex2_bit+8,d0		* test for inex2 and clear it
	BEQ	no_exc			* skip this if no exc
	ORI.W	#inx1a_mask,EXC_LV+USER_FPSR+2(a6) * set INEX1/AINEX
no_exc:
	ADD.L	#$4,sp			* clear 1 lw param
	FMOVEM.X	(sp)+,fp1		* restore fp1
	MOVEM.L	(sp)+,d2-d5		* restore d2-d5
	FMOVE.L	#$0,fpcr
	FMOVE.L	#$0,fpsr
	RTS






**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* bindec(): Converts an input in extended precision format to bcd format*
**-------------------------------------------------------------------------------------------------
*
* INPUT ***************************************************************
*	a0 = pointer to the input extended precision value in memory.
*	     the input may be either normalized, unnormalized, or
*	     denormalized.
*	d0 = contains the k-factor sign-extended to 32-bits.
*
* OUTPUT **************************************************************
*	EXC_LV+FP_SCR0(a6) = bcd format result on the stack.
*
* ALGORITHM ***********************************************************
*
*	A1.	Set RM and size ext;  Set SIGMA = sign of input.
*	The k-factor is saved for use in d7. Clear the
*	BINDEC_FLG for separating normalized/denormalized
*	input.  If input is unnormalized or denormalized,
*	normalize it.
*
*	A2.	Set X = abs(input).
*
*	A3.	Compute ILOG.
*	ILOG is the log base 10 of the input value.  It is
*	approximated by adding e + 0.f when the original
*	value is viewed as 2^^e * 1.f in extended precision.
*	This value is stored in d6.
*
*	A4.	Clr INEX bit.
*	The operation in A3 above may have set INEX2.
*
*	A5.	Set ICTR = 0;
*	ICTR is a flag used in A13.  It must be set before the
*	loop entry A6.
*
*	A6.	Calculate LEN.
*	LEN is the number of digits to be displayed.  The
*	k-factor can dictate either the total number of digits,
*	if it is a positive number, or the number of digits
*	after the decimal point which are to be included as
*	significant.  See the 68882 manual for examples.
*	If LEN is computed to be greater than 17, set OPERR in
*	USER_FPSR.  LEN is stored in d4.
*
*	A7.	Calculate SCALE.
*	SCALE is equal to 10^ISCALE, where ISCALE is the number
*	of decimal places needed to insure LEN integer digits
*	in the output before conversion to bcd. LAMBDA is the
*	sign of ISCALE, used in A9. Fp1 contains
*	10^^(abs(ISCALE)) using a rounding mode which is a
*	function of the original rounding mode and the signs
*	of ISCALE and X.  A table is given in the code.
*
*	A8.	Clr INEX; Force RZ.
*	The operation in A3 above may have set INEX2.
*	RZ mode is forced for the scaling operation to insure
*	only one rounding error.  The grs bits are collected in *
*	the INEX flag for use in A10.
*
*	A9.	Scale X -> Y.
*	The mantissa is scaled to the desired number of
*	significant digits.  The excess digits are collected
*	in INEX2.
*
*	A10.	Or in INEX.
*	If INEX is set, round error occured.  This is
*	compensated for by 'or-ing' in the INEX2 flag to
*	the lsb of Y.
*
*	A11.	Restore original FPCR; set size ext.
*	Perform FINT operation in the user's rounding mode.
*	Keep the size to extended.
*
*	A12.	Calculate YINT = FINT(Y) according to user's rounding
*	mode.  The FPSP routine sintd0 is used.  The output
*	is in fp0.
*
*	A13.	Check for LEN digits.
*	If the int operation results in more than LEN digits,
*	or less than LEN -1 digits, adjust ILOG and repeat from
*	A6.  This test occurs only on the first pass.  If the
*	result is exactly 10^LEN, decrement ILOG and divide
*	the mantissa by 10.
*
*	A14.	Convert the mantissa to bcd.
*	The binstr routine is used to convert the LEN digit
*	mantissa to bcd in memory.  The input to binstr is
*	to be a fraction; i.e. (mantissa)/10^LEN and adjusted
*	such that the decimal point is to the left of bit 63.
*	The bcd digits are stored in the correct position in
*	the final string area in memory.
*
*	A15.	Convert the exponent to bcd.
*	As in A14 above, the exp is converted to bcd and the
*	digits are stored in the final string.
*	Test the length of the final exponent string.  If the
*	length is 4, set operr.
*
*	A16.	Write sign bits to final string.
*
**-------------------------------------------------------------------------------------------------

                *+------------------------------------------------------------------------------

BINDEC_FLG	equ	EXC_LV+EXC_TEMP	* DENORM flag

	* Constants in extended precision

PLOG2:	dc.l	$3FFD0000,$9A209A84,$FBCFF798,$00000000
PLOG2UP1:	dc.l	$3FFD0000,$9A209A84,$FBCFF799,$00000000

	* Constants in single precision

FONE:	dc.l	$3F800000,$00000000,$00000000,$00000000
FTWO:	dc.l	$40000000,$00000000,$00000000,$00000000
FTEN:	dc.l	$41200000,$00000000,$00000000,$00000000
F4933:	dc.l	$459A2800,$00000000,$00000000,$00000000

RBDTBL:	dc.b	0,0,0,0
	dc.b	3,3,2,2
	dc.b	3,2,2,3
	dc.b	2,3,3,2

                *+------------------------------------------------------------------------------
	*	Implementation Notes:
	*
	*	The registers are used as follows:
	*
	*	d0: scratch; LEN input to binstr
	*	d1: scratch
	*	d2: upper 32-bits of mantissa for binstr
	*	d3: scratch;lower 32-bits of mantissa for binstr
	*	d4: LEN
	*      	d5: LAMBDA/ICTR
	*	d6: ILOG
	*	d7: k-factor
	*	a0: ptr for original operand/final result
	*	a1: scratch pointer
	*	a2: pointer to EXC_LV+FP_X; abs(original value) in ext
	*	fp0: scratch
	*	fp1: scratch
	*	fp2: scratch
	*	F_SCR1:
	*	F_SCR2:
	*	EXC_LV+L_SCR1:
	*	EXC_LV+L_SCR2:

	xdef	bindec
bindec:
	MOVEM.L	d2-d7/a2,-(sp)	*  {d2-d7/a2}
	FMOVEM.X	fp0-fp2,-(sp)	*  {fp0-fp2}

                *+------------------------------------------------------------------------------
	* A1. Set RM and size ext. Set SIGMA = sign input;
	*     The k-factor is saved for use in d7.  Clear BINDEC_FLG for
	*     separating  normalized/denormalized input.  If the input
	*     is a denormalized number, set the BINDEC_FLG memory word
	*     to signal denorm.  If the input is unnormalized, normalize
	*     the input and test for denormalized result.

	FMOVE.L	#rm_mode*$10,fpcr		* set RM and ext
	MOVE.L	(a0),EXC_LV+L_SCR2(a6)		* save exponent for sign check
	MOVE.L	d0,d7				* move k-factor to d7

	CLR.B	BINDEC_FLG(a6)			* clr norm/denorm flag
	CMP.b	#DENORM,EXC_LV+STAG(a6) 	* is input a DENORM?
	BNE	A2_str				* no; input is a NORM

                *+------------------------------------------------------------------------------
	* Normalize the denorm
	*
un_de_norm:
	MOVE.W	(a0),d0
	AND.W	#$7fff,d0		* strip sign of normalized exp
	MOVE.L	4(a0),d1
	MOVE.L	8(a0),d2
norm_loop:
	SUB.W	#1,d0
	LSL.L	#1,d2
	ROXL.L	#1,d1
	TST.L	d1
	BGE	norm_loop

                *+------------------------------------------------------------------------------
	* Test if the normalized input is denormalized
	*
	TST.W	d0
	BGT	pos_exp			* if greater than zero, it is a norm
	ST	BINDEC_FLG(a6)		* set flag for denorm
pos_exp:
	AND.W	#$7fff,d0		* strip sign of normalized exp
	MOVE.W	d0,(a0)
	MOVE.L	d1,4(a0)
	MOVE.L	d2,8(a0)

                *+------------------------------------------------------------------------------
	* A2. Set X = abs(input).
	*
A2_str:
	MOVE.L	(a0),EXC_LV+FP_SCR1(a6)		* move input to work space
	MOVE.L	4(a0),EXC_LV+FP_SCR1+4(a6)	* move input to work space
	MOVE.L	8(a0),EXC_LV+FP_SCR1+8(a6)	* move input to work space
	and.l	#$7fffffff,EXC_LV+FP_SCR1(a6)	* create abs(X)

                *+------------------------------------------------------------------------------
	* A3. Compute ILOG.
	*     ILOG is the log base 10 of the input value.  It is approx-
	*     imated by adding e + 0.f when the original value is viewed
	*     as 2^^e * 1.f in extended precision.  This value is stored
	*     in d6.
	*
	* Register usage:
	*	Input/Output
	*	d0: k-factor/exponent
	*	d2: x/x
	*	d3: x/x
	*	d4: x/x
	*	d5: x/x
	*	d6: x/ILOG
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/final result
	*	a1: x/x
	*	a2: x/x
	*	fp0: x/float(ILOG)
	*	fp1: x/x
	*	fp2: x/x
	*	F_SCR1:x/x
	*	F_SCR2:Abs(X)/Abs(X) with $3fff exponent
	*	EXC_LV+L_SCR1:x/x
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged

	TST.B	BINDEC_FLG(a6)		* check for denorm
	BEQ	A3_cont			* if clr, continue with norm
	MOVE.L	#-4933,d6		* force ILOG = -4933
	BRA	A4_str
A3_cont:
	MOVE.W	EXC_LV+FP_SCR1(a6),d0		* move exp to d0
	MOVE.W	#$3fff,EXC_LV+FP_SCR1(a6)	* replace exponent with $3fff
	FMOVE.X	EXC_LV+FP_SCR1(a6),fp0		* now fp0 has 1.f
	SUB.W	#$3fff,d0			* strip off bias
	FADD.W	d0,fp0				* add in exp
	FSUB.S	FONE(pc),fp0			* subtract off 1.0
	FBGE	pos_res				* if pos, branch
	FMUL.X	PLOG2UP1(pc),fp0		* if neg, mul by LOG2UP1
	FMOVE.L	fp0,d6				* put ILOG in d6 as a lword
	BRA	A4_str				* go move out ILOG
pos_res:
	FMUL.X	PLOG2(pc),fp0		* if pos, mul by LOG2
	FMOVE.L	fp0,d6			* put ILOG in d6 as a lword


                *+------------------------------------------------------------------------------
	* A4. Clr INEX bit.
	*     The operation in A3 above may have set INEX2.
A4_str:
	FMOVE.L	#0,fpsr			* zero all of fpsr - nothing needed


                *+------------------------------------------------------------------------------
	* A5. Set ICTR = 0;
	*     ICTR is a flag used in A13.  It must be set before the
	*     loop entry A6. The lower word of d5 is used for ICTR.

	CLR.W	d5			* clear ICTR

                *+------------------------------------------------------------------------------
	* A6. Calculate LEN.
	*     LEN is the number of digits to be displayed.  The k-factor
	*     can dictate either the total number of digits, if it is
	*     a positive number, or the number of digits after the
	*     original decimal point which are to be included as
	*     significant.  See the 68882 manual for examples.
	*     If LEN is computed to be greater than 17, set OPERR in
	*     USER_FPSR.  LEN is stored in d4.
	*
	* Register usage:
	*	Input/Output
	*	d0: exponent/Unchanged
	*	d2: x/x/scratch
	*	d3: x/x
	*	d4: exc picture/LEN
	*	d5: ICTR/Unchanged
	*	d6: ILOG/Unchanged
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/final result
	*	a1: x/x
	*	a2: x/x
	*	fp0: float(ILOG)/Unchanged
	*	fp1: x/x
	*	fp2: x/x
	*	F_SCR1:x/x
	*	F_SCR2:Abs(X) with $3fff exponent/Unchanged
	*	EXC_LV+L_SCR1:x/x
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged
A6_str:
	TST.L	d7			* branch on sign of k
	BLE	k_neg			* if k <= 0, LEN = ILOG + 1 - k
	MOVE.L	d7,d4			* if k > 0, LEN = k
	BRA	len_ck			* skip to LEN check
k_neg:
	MOVE.L	d6,d4			* first load ILOG to d4
	SUB.L	d7,d4			* subtract off k
	ADDQ.L	#1,d4			* add in the 1
len_ck:
	TST.L	d4			* LEN check: branch on sign of LEN
	BLE	LEN_ng			* if neg, set LEN = 1
	CMP.l	#17,d4			* test if LEN > 17
	BLE	A7_str			* if not, forget it
	MOVE.L	#17,d4			* set max LEN = 17
	TST.L	d7			* if negative, never set OPERR
	BLE	A7_str			* if positive, continue
	OR.L	#opaop_mask,EXC_LV+USER_FPSR(a6)	* set OPERR # AIOP in USER_FPSR
	BRA	A7_str			* finished here
LEN_ng:
	MOVE.L	#1,d4			* min LEN is 1


                *+------------------------------------------------------------------------------
	* A7. Calculate SCALE.
	*     SCALE is equal to 10^ISCALE, where ISCALE is the number
	*     of decimal places needed to insure LEN integer digits
	*     in the output before conversion to bcd. LAMBDA is the sign
	*     of ISCALE, used in A9.  Fp1 contains 10^^(abs(ISCALE)) using
	*     the rounding mode as given in the following table (see
	*     Coonen, p. 7.23 as ref.; however, the SCALE variable is
	*     of opposite sign in bindec.sa from Coonen).
	*
	*	Initial		USE
	*	FPCR[6:5]	LAMBDA	SIGN(X)	FPCR[6:5]
	*	----------------------------------------------
	*	 RN	00	   0	   0	00/0	RN
	*	 RN	00	   0	   1	00/0	RN
	*	 RN	00	   1	   0	00/0	RN
	*	 RN	00	   1	   1	00/0	RN
	*	 RZ	01	   0	   0	11/3	RP
	*	 RZ	01	   0	   1	11/3	RP
	*	 RZ	01	   1	   0	10/2	RM
	*	 RZ	01	   1	   1	10/2	RM
	*	 RM	10	   0	   0	11/3	RP
	*	 RM	10	   0	   1	10/2	RM
	*	 RM	10	   1	   0	10/2	RM
	*	 RM	10	   1	   1	11/3	RP
	*	 RP	11	   0	   0	10/2	RM
	*	 RP	11	   0	   1	11/3	RP
	*	 RP	11	   1	   0	11/3	RP
	*	 RP	11	   1	   1	10/2	RM
	*
	* Register usage:
	*	Input/Output
	*	d0: exponent/scratch - final is 0
	*	d2: x/0 or 24 for A9
	*	d3: x/scratch - offset ptr into PTENRM array
	*	d4: LEN/Unchanged
	*	d5: 0/ICTR:LAMBDA
	*	d6: ILOG/ILOG or k if ((k<=0)#(ILOG<k))
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/final result
	*	a1: x/ptr to PTENRM array
	*	a2: x/x
	*	fp0: float(ILOG)/Unchanged
	*	fp1: x/10^ISCALE
	*	fp2: x/x
	*	F_SCR1:x/x
	*	F_SCR2:Abs(X) with $3fff exponent/Unchanged
	*	EXC_LV+L_SCR1:x/x
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged

A7_str:
	TST.L	d7		* test sign of k
	BGT	k_pos		* if pos and > 0, skip this

	CMP.l	d6,d7		* test k - ILOG
	BLT	k_pos		* if ILOG >= k, skip this
	MOVE.L	d7,d6		* if ((k<0) # (ILOG < k)) ILOG = k
k_pos:
	MOVE.L	d6,d0		* calc ILOG + 1 - LEN in d0
	ADDQ.l	#1,d0		* add the 1
	SUB.L	d4,d0		* sub off LEN
	SWAP	d5		* use upper word of d5 for LAMBDA
	CLR.W	d5		* set it zero initially
	CLR.W	d2		* set up d2 for very small case
	TST.L	d0		* test sign of ISCALE
	BGE	iscale		* if pos, skip next inst
	ADDQ.W	#1,d5		* if neg, set LAMBDA true
	CMP.l	#$ffffecd4,d0	* test iscale <= -4908
	BGT.B	no_inf		* if false, skip rest
	ADD.L	#24,d0		* add in 24 to iscale
	MOVE.L	#24,d2		* put 24 in d2 for A9
no_inf:
	NEG.L	d0		* and take abs of ISCALE
iscale:
	FMOVE.S	FONE(pc),fp1			* init fp1 to 1
	BFEXTU	EXC_LV+USER_FPCR(a6){26:2},d1	* get initial rmode bits
	LSL.W	#1,d1				* put them in bits 2:1
	ADD.W	d5,d1		* add in LAMBDA
	LSL.W	#1,d1		* put them in bits 3:1
	TST.L	EXC_LV+L_SCR2(a6)	* test sign of original x
	BGE	x_pos		* if pos, don't set bit 0
	ADDQ.L	#1,d1		* if neg, set bit 0
x_pos:
	LEA.l	RBDTBL(pc),a2	* load rbdtbl base
	MOVE.B	(a2,d1),d3	* load d3 with new rmode
	LSL.L	#4,d3		* put bits in proper position
	FMOVE.L	d3,fpcr		* load bits into fpu
	LSR.L	#4,d3		* put bits in proper position
	TST.B	d3		* decode new rmode for pten table
	BNE	not_rn		* if zero, it is RN
	LEA.l	PTENRN(pc),a1	* load a1 with RN table base
	BRA	rmode		* exit decode
not_rn:
	LSR.B	#1,d3		* get lsb in carry
	BCC	not_rp2		* if carry clear, it is RM
	LEA.l	PTENRP(pc),a1	* load a1 with RP table base
	BRA	rmode		* exit decode
not_rp2:
	LEA.l	PTENRM(pc),a1	* load a1 with RM table base
rmode:
	CLR.L	d3		* clr table index
e_loop2:
	LSR.L	#1,d0		* shift next bit into carry
	BCC	e_next2		* if zero, skip the mul
	FMUL.X	(a1,d3),fp1	* mul by 10**(d3_bit_no)
e_next2:
	ADD.L	#12,d3		* inc d3 to next pwrten table entry
	TST.L	d0		* test if ISCALE is zero
	BNE	e_loop2		* if not, loop

                *+------------------------------------------------------------------------------
	* A8. Clr INEX; Force RZ.
	*     The operation in A3 above may have set INEX2.
	*     RZ mode is forced for the scaling operation to insure
	*     only one rounding error.  The grs bits are collected in
	*     the INEX flag for use in A10.
	*
	* Register usage:
	*	Input/Output

	FMOVE.L	#0,fpsr			* clr INEX
	FMOVE.L	#rz_mode*$10,fpcr	* set RZ rounding mode

                *+------------------------------------------------------------------------------
	* A9. Scale X -> Y.
	*     The mantissa is scaled to the desired number of significant
	*     digits.  The excess digits are collected in INEX2. If mul,
	*     Check d2 for excess 10 exponential value.  If not zero,
	*     the iscale value would have caused the pwrten calculation
	*     to overflow.  Only a negative iscale can cause this, so
	*     multiply by 10^(d2), which is now only allowed to be 24,
	*     with a multiply by 10^8 and 10^16, which is exact since
	*     10^24 is exact.  If the input was denormalized, we must
	*     create a busy stack frame with the mul command and the
	*     two operands, and allow the fpu to complete the multiply.
	*
	* Register usage:
	*	Input/Output
	*	d0: FPCR with RZ mode/Unchanged
	*	d2: 0 or 24/unchanged
	*	d3: x/x
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA
	*	d6: ILOG/Unchanged
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/final result
	*	a1: ptr to PTENRM array/Unchanged
	*	a2: x/x
	*	fp0: float(ILOG)/X adjusted for SCALE (Y)
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: x/x
	*	F_SCR1:x/x
	*	F_SCR2:Abs(X) with $3fff exponent/Unchanged
	*	EXC_LV+L_SCR1:x/x
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged

A9_str:
	FMOVE.X	(a0),fp0	* load X from memory
	FABS.X	fp0		* use abs(X)
	TST.W	d5		* LAMBDA is in lower word of d5
	BNE	sc_mul		* if neg (LAMBDA = 1), scale by mul
	FDIV.X	fp1,fp0		* calculate X / SCALE -> Y to fp0
	BRA	A10_st		* branch to A10

sc_mul:	TST.B	BINDEC_FLG(a6)	* check for denorm
	BEQ	A9_norm		* if norm, continue with mul

                *+------------------------------------------------------------------------------
	* for DENORM, we must calculate:
	*	fp0 = input_op * 10^ISCALE * 10^24
	* since the input operand is a DENORM, we can't multiply it directly.
	* so, we do the multiplication of the exponents and mantissas separately.
	* in this way, we avoid underflow on intermediate EXC_LV+STAGes of the
	* multiplication and guarantee a result without exception.

	FMOVEM.X	fp1,-(sp)	* save 10^ISCALE to stack

	MOVE.W	(sp),d3		* grab exponent
	ANDI.W	#$7fff,d3	* clear sign
	ORI.W	#$8000,(a0)	* make DENORM exp negative
	ADD.W	(a0),d3		* add DENORM exp to 10^ISCALE exp
	SUBI.W	#$3fff,d3	* subtract BIAS
	ADD.W	36(a1),d3
	SUBI.W	#$3fff,d3	* subtract BIAS
	ADD.W	48(a1),d3
	SUBI.W	#$3fff,d3	* subtract BIAS

	BMI	sc_mul_err	* is result is DENORM, punt!!!

	ANDI.W	#$8000,(sp)	* keep sign
	OR.W	d3,(sp)		* insert new exponent

	ANDI.W	#$7fff,(a0)	* clear sign bit on DENORM again
	MOVE.L	$8(a0),-(sp) 	* put input op mantissa on stk
	MOVE.L	$4(a0),-(sp)
	MOVE.L	#$3fff0000,-(sp) * force exp to zero

	FMOVEM.X	(sp)+,fp0	* load normalized DENORM into fp0
	FMUL.X	(sp)+,fp0

*	fmul.x	36(a1),fp0	* multiply fp0 by 10^8
*	fmul.x	48(a1),fp0	* multiply fp0 by 10^16

	MOVE.L	36+8(a1),-(sp) * get 10^8 mantissa
	MOVE.L	36+4(a1),-(sp)
	MOVE.L	#$3fff0000,-(sp) * force exp to zero
	MOVE.L	48+8(a1),-(sp) * get 10^16 mantissa
	MOVE.L	48+4(a1),-(sp)
	MOVE.L	#$3fff0000,-(sp) * force exp to zero

	FMUL.X	(sp)+,fp0	* multiply fp0 by 10^8
	FMUL.x	(sp)+,fp0	* multiply fp0 by 10^16
	BRA	A10_st
sc_mul_err:
	BRA	sc_mul_err

                *+------------------------------------------------------------------------------
A9_norm:
	TST.W	d2		* test for small exp case
	beq.b	A9_con		* if zero, continue as normal
	fmul.x	36(a1),fp0	* multiply fp0 by 10^8
	fmul.x	48(a1),fp0	* multiply fp0 by 10^16
A9_con:
	fmul.x	fp1,fp0		* calculate X * SCALE -> Y to fp0

                *+------------------------------------------------------------------------------
	* A10. Or in INEX.
	*      If INEX is set, round error occured.  This is compensated
	*      for by 'or-ing' in the INEX2 flag to the lsb of Y.
	*
	* Register usage:
	*	Input/Output
	*	d0: FPCR with RZ mode/FPSR with INEX2 isolated
	*	d2: x/x
	*	d3: x/x
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA
	*	d6: ILOG/Unchanged
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/final result
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: x/ptr to EXC_LV+FP_SCR1(a6)
	*	fp0: Y/Y with lsb adjusted
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: x/x
A10_st:
	FMOVE.L	fpsr,d0			* get FPSR
	FMOVE.X	fp0,EXC_LV+FP_SCR1(a6)	* move Y to memory
	LEA.l	EXC_LV+FP_SCR1(a6),a2	* load a2 with ptr to EXC_LV+FP_SCR1
	BTST	#9,d0			* check if INEX2 set
	beq.b	A11_st			* if clear, skip rest
	OR.L	#1,8(a2)		* or in 1 to lsb of mantissa
	FMOVE.X	EXC_LV+FP_SCR1(a6),fp0	* write adjusted Y back to fpu

                *+------------------------------------------------------------------------------
	* A11. Restore original FPCR; set size ext.
	*      Perform FINT operation in the user's rounding mode.  Keep
	*      the size to extended.  The sintdo entry point in the sint
	*      routine expects the FPCR value to be in EXC_LV+USER_FPCR for
	*      mode and precision.  The original FPCR is saved in EXC_LV+L_SCR1.
A11_st:
	MOVE.L	EXC_LV+USER_FPCR(a6),EXC_LV+L_SCR1(a6)	* save it for later
	AND.L	#$00000030,EXC_LV+USER_FPCR(a6)		* set size to ext,

	*		;block exceptions


                *+------------------------------------------------------------------------------
	* A12. Calculate YINT = FINT(Y) according to user's rounding mode.
	*      The FPSP routine sintd0 is used.  The output is in fp0.
	*
	* Register usage:
	*	Input/Output
	*	d0: FPSR with AINEX cleared/FPCR with size set to ext
	*	d2: x/x/scratch
	*	d3: x/x
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA/Unchanged
	*	d6: ILOG/Unchanged
	*	d7: k-factor/Unchanged
	*	a0: ptr for original operand/src ptr for sintdo
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: ptr to EXC_LV+FP_SCR1(a6)/Unchanged
	*	a6: temp pointer to EXC_LV+FP_SCR1(a6) - orig value saved and restored
	*	fp0: Y/YINT
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: x/x
	*	F_SCR1:x/x
	*	F_SCR2:Y adjusted for inex/Y with original exponent
	*	EXC_LV+L_SCR1:x/original EXC_LV+USER_FPCR
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged

A12_st:
	MOVEM.L	d0-d1/a0-a1,-(sp)	* save regs used by sintd0	 {d0-d1/a0-a1}
	MOVE.L	EXC_LV+L_SCR1(a6),-(sp)
	MOVE.L	EXC_LV+L_SCR2(a6),-(sp)

	LEA.l	EXC_LV+FP_SCR1(a6),a0	* a0 is ptr to EXC_LV+FP_SCR1(a6)
	FMOVE.X	fp0,(a0)		* move Y to memory at EXC_LV+FP_SCR1(a6)
	TST.L	EXC_LV+L_SCR2(a6)	* test sign of original operand
	BGE	do_fint12		* if pos, use Y
	OR.L	#$80000000,(a0)		* if neg, use -Y
do_fint12:	MOVE.L	EXC_LV+USER_FPSR(a6),-(sp)

	FMOVE.L	EXC_LV+USER_FPCR(a6),fpcr
	FMOVE.L	#$0,fpsr			* clear the AEXC bits!!!

	FINT.X	EXC_LV+FP_SCR1(a6),fp0	* do fint()
	FMOVE.L	fpsr,d0
	OR.W	d0,EXC_LV+FPSR_EXCEPT(a6)

	MOVE.B	(sp),EXC_LV+USER_FPSR(a6)
	ADD.L	#4,sp

	MOVE.L	(sp)+,EXC_LV+L_SCR2(a6)
	MOVE.L	(sp)+,EXC_LV+L_SCR1(a6)
	movem.l	(sp)+,d0-d1/a0-a1	* restore regs used by sint	 {d0-d1/a0-a1}

	MOVE.L	EXC_LV+L_SCR2(a6),EXC_LV+FP_SCR1(a6)	* restore original exponent
	MOVE.L	EXC_LV+L_SCR1(a6),EXC_LV+USER_FPCR(a6)	* restore user's FPCR

                *+------------------------------------------------------------------------------
	* A13. Check for LEN digits.
	*      If the int operation results in more than LEN digits,
	*      or less than LEN -1 digits, adjust ILOG and repeat from
	*      A6.  This test occurs only on the first pass.  If the
	*      result is exactly 10^LEN, decrement ILOG and divide
	*      the mantissa by 10.  The calculation of 10^LEN cannot
	*      be inexact, since all powers of ten upto 10^27 are exact
	*      in extended precision, so the use of a previous power-of-ten
	*      table will introduce no error.
	*
	*
	* Register usage:
	*	Input/Output
	*	d0: FPCR with size set to ext/scratch final = 0
	*	d2: x/x
	*	d3: x/scratch final = x
	*	d4: LEN/LEN adjusted
	*	d5: ICTR:LAMBDA/LAMBDA:ICTR
	*	d6: ILOG/ILOG adjusted
	*	d7: k-factor/Unchanged
	*	a0: pointer into memory for packed bcd string formation
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: ptr to EXC_LV+FP_SCR1(a6)/Unchanged
	*	fp0: int portion of Y/abs(YINT) adjusted
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: x/10^LEN
	*	F_SCR1:x/x
	*	F_SCR2:Y with original exponent/Unchanged
	*	EXC_LV+L_SCR1:original EXC_LV+USER_FPCR/Unchanged
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged
A13_st:
	SWAP	d5		* put ICTR in lower word of d5
	TST.W	d5		* check if ICTR = 0
	BNE	not_zr		* if non-zero, go to second test
	*
	* Compute 10^(LEN-1)
	*
	FMOVE.S	FONE(pc),fp2	* init fp2 to 1.0
	MOVE.L	d4,d0		* put LEN in d0
	SUBQ.L	#1,d0		* d0 = LEN -1
	CLR.L	d3		* clr table index
l_loop:
	LSR.L	#1,d0		* shift next bit into carry
	BCC	l_next		* if zero, skip the mul
	FMUL.X	(a1,d3),fp2	* mul by 10**(d3_bit_no)
l_next:
	ADD.L	#12,d3		* inc d3 to next pwrten table entry
	TST.L	d0		* test if LEN is zero
	BNE	l_loop		* if not, loop
	*
	* 10^LEN-1 is computed for this test and A14.  If the input was
	* denormalized, check only the case in which YINT > 10^LEN.
	*
	TST.B	BINDEC_FLG(a6)	* check if input was norm
	BEQ	A13_con		* if norm, continue with checking
	FABS.X	fp0		* take abs of YINT
	BRA	test_2
                *+------------------------------------------------------------------------------
	*
	* Compare abs(YINT) to 10^(LEN-1) and 10^LEN
	*
A13_con:	FABS.X	fp0		* take abs of YINT
	FCMP.X	fp0,fp2		* compare abs(YINT) with 10^(LEN-1)
	FBGE.W	test_2		* if greater, do next test
	SUBQ.L	#1,d6		* subtract 1 from ILOG
	MOVE.W	#1,d5		* set ICTR
	FMOVE.L	#rm_mode*$10,fpcr	* set rmode to RM
	FMUL.S	FTEN(pc),fp2	* compute 10^LEN
	BRA	A6_str		* return to A6 and recompute YINT
test_2:
	FMUL.S	FTEN(pc),fp2	* compute 10^LEN
	FCMP.X	fp0,fp2		* compare abs(YINT) with 10^LEN
	FBLT	A14_st		* if less, all is ok, go to A14
	FBGT	fix_ex		* if greater, fix and redo
	FDIV.S	FTEN(pc),fp0	* if equal, divide by 10
	ADDQ.L	#1,d6		* and inc ILOG
	BRA	A14_st		* and continue elsewhere
fix_ex:
	ADDQ.L	#1,d6		* increment ILOG by 1
	MOVE.W	#1,d5		* set ICTR
	FMOVE.L	#rm_mode*$10,fpcr	* set rmode to RM
	BRA	A6_str		* return to A6 and recompute YINT

                *+------------------------------------------------------------------------------
	*
	* Since ICTR <> 0, we have already been through one adjustment,
	* and shouldn't have another; this is to check if abs(YINT) = 10^LEN
	* 10^LEN is again computed using whatever table is in a1 since the
	* value calculated cannot be inexact.
	*
not_zr:
	FMOVE.S	FONE(pc),fp2	* init fp2 to 1.0
	MOVE.L	d4,d0		* put LEN in d0
	CLR.L	d3		* clr table index
z_loop:
	LSR.L	#1,d0		* shift next bit into carry
	BCC	z_next		* if zero, skip the mul
	FMUL.X	(a1,d3),fp2	* mul by 10**(d3_bit_no)
z_next:
	ADD.L	#12,d3		* inc d3 to next pwrten table entry
	TST.L	d0		* test if LEN is zero
	BNE	z_loop		* if not, loop
	FABS.X	fp0		* get abs(YINT)
	FCMP.X	fp0,fp2		* check if abs(YINT) = 10^LEN
	FBNE	A14_st		* if not, skip this
	FDIV.S	FTEN(pc),fp0	* divide abs(YINT) by 10
	ADDQ.L	#1,d6		* and inc ILOG by 1
	ADDQ.L	#1,d4		* and inc LEN
	FMUL.S	FTEN(pc),fp2	* if LEN++, the get 10^^LEN

                *+------------------------------------------------------------------------------
	* A14. Convert the mantissa to bcd.
	*      The binstr routine is used to convert the LEN digit
	*      mantissa to bcd in memory.  The input to binstr is
	*      to be a fraction; i.e. (mantissa)/10^LEN and adjusted
	*      such that the decimal point is to the left of bit 63.
	*      The bcd digits are stored in the correct position in
	*      the final string area in memory.
	*
	*
	* Register usage:
	*	Input/Output
	*	d0: x/LEN call to binstr - final is 0
	*	d1: x/0
	*	d2: x/ms 32-bits of mant of abs(YINT)
	*	d3: x/ls 32-bits of mant of abs(YINT)
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA/LAMBDA:ICTR
	*	d6: ILOG
	*	d7: k-factor/Unchanged
	*	a0: pointer into memory for packed bcd string formation
	*	    /ptr to first mantissa byte in result string
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: ptr to EXC_LV+FP_SCR1(a6)/Unchanged
	*	fp0: int portion of Y/abs(YINT) adjusted
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: 10^LEN/Unchanged
	*	F_SCR1:x/Work area for final result
	*	F_SCR2:Y with original exponent/Unchanged
	*	EXC_LV+L_SCR1:original EXC_LV+USER_FPCR/Unchanged
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged
A14_st:
	FMOVE.L	#rz_mode*$10,fpcr	* force rz for conversion
	FDIV.X	fp2,fp0		* divide abs(YINT) by 10^LEN
	LEA.l	EXC_LV+FP_SCR0(a6),a0
	FMOVE.X	fp0,(a0)	* move abs(YINT)/10^LEN to memory
	MOVE.L	4(a0),d2	* move 2nd word of EXC_LV+FP_RES to d2
	MOVE.L	8(a0),d3	* move 3rd word of EXC_LV+FP_RES to d3
	CLR.L	4(a0)		* zero word 2 of EXC_LV+FP_RES
	CLR.L	8(a0)		* zero word 3 of EXC_LV+FP_RES
	MOVE.L	(a0),d0		* move exponent to d0
	SWAP	d0		* put exponent in lower word
	BEQ	no_sft		* if zero, don't shift
	SUB.L	#$3ffd,d0	* sub bias less 2 to make fract
	TST.L	d0		* check if > 1
	BGT	no_sft		* if so, don't shift
	NEG.L	d0		* make exp positive
m_loop:
	LSR.L	#1,d2		* shift d2:d3 right, add 0s
	ROXR.L	#1,d3		* the number of places
	DBF	d0,m_loop	* given in d0
no_sft:
	TST.L	d2		* check for mantissa of zero
	BNE	no_zr		* if not, go on
	TST.L	d3		* continue zero check
	BEQ	zer_m		* if zero, go directly to binstr
no_zr:
	CLR.L	d1		* put zero in d1 for addx
	ADD.L	#$00000080,d3	* inc at bit 7
	ADDX.L	d1,d2		* continue inc
	AND.L	#$ffffff80,d3	* strip off lsb not used by 882
zer_m:
	MOVE.L	d4,d0		* put LEN in d0 for binstr call
	ADDQ.L	#3,a0		* a0 points to M16 byte in result
	BSR	binstr		* call binstr to convert mant


                *+------------------------------------------------------------------------------
	* A15. Convert the exponent to bcd.
	*      As in A14 above, the exp is converted to bcd and the
	*      digits are stored in the final string.
	*
	*      Digits are stored in EXC_LV+L_SCR1(a6) on return from BINDEC as:
	*
	*  	 32               16 15                0
	*	-----------------------------------------
	*  	|  0 | e3 | e2 | e1 | e4 |  X |  X |  X |
	*	-----------------------------------------
	*
	* And are moved into their proper places in EXC_LV+FP_SCR0.  If digit e4
	* is non-zero, OPERR is signaled.  In all cases, all 4 digits are
	* written as specified in the 881/882 manual for packed decimal.
	*
	* Register usage:
	*	Input/Output
	*	d0: x/LEN call to binstr - final is 0
	*	d1: x/scratch (0);shift count for final exponent packing
	*	d2: x/ms 32-bits of exp fraction/scratch
	*	d3: x/ls 32-bits of exp fraction
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA/LAMBDA:ICTR
	*	d6: ILOG
	*	d7: k-factor/Unchanged
	*	a0: ptr to result string/ptr to EXC_LV+L_SCR1(a6)
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: ptr to EXC_LV+FP_SCR1(a6)/Unchanged
	*	fp0: abs(YINT) adjusted/float(ILOG)
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: 10^LEN/Unchanged
	*	F_SCR1:Work area for final result/BCD result
	*	F_SCR2:Y with original exponent/ILOG/10^4
	*	EXC_LV+L_SCR1:original EXC_LV+USER_FPCR/Exponent digits on return from binstr
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged
A15_st:
	TST.B	BINDEC_FLG(a6)	* check for denorm
	BEQ	not_denorm
	FTST.X	fp0		* test for zero
	FBEQ.W	den_zero	* if zero, use k-factor or 4933
	FMOVE.L	d6,fp0		* float ILOG
	FABS.X	fp0		* get abs of ILOG
	BRA	convrt
den_zero:
	TST.L	d7		* check sign of the k-factor
	BLT	use_ilog	* if negative, use ILOG
	FMOVE.S	F4933(pc),fp0	* force exponent to 4933
	BRA	convrt		* do it
use_ilog:
	FMOVE.L	d6,fp0		* float ILOG
	FABS.X	fp0		* get abs of ILOG
	BRA	convrt
not_denorm:
	FTST.X	fp0		* test for zero
	FBNE	not_zero	* if zero, force exponent
	FMOVE.S	FONE(pc),fp0	* force exponent to 1
	BRA	convrt		* do it
not_zero:
	FMOVE.L	d6,fp0		* float ILOG
	FABS.X	fp0		* get abs of ILOG
convrt:
	FDIV.X	24(a1),fp0		* compute ILOG/10^4
	FMOVE.X	fp0,EXC_LV+FP_SCR1(a6)	* store fp0 in memory
	MOVE.L	4(a2),d2		* move word 2 to d2
	MOVE.L	8(a2),d3		* move word 3 to d3
	MOVE.W	(a2),d0			* move exp to d0
	BEQ	x_loop_fin		* if zero, skip the shift
	SUB.W	#$3ffd,d0		* subtract off bias
	NEG.W	d0			* make exp positive
x_loop:
	LSR.L	#1,d2			* shift d2:d3 right
	ROXR.L	#1,d3			* the number of places
	DBF	d0,x_loop		* given in d0
x_loop_fin:
	CLR.L	d1			* put zero in d1 for addx
	ADD.L	#$00000080,d3		* inc at bit 6
	ADDX.L	d1,d2			* continue inc
	AND.L	#$ffffff80,d3		* strip off lsb not used by 882
	MOVE.L	#4,d0			* put 4 in d0 for binstr call
	LEA.l	EXC_LV+L_SCR1(a6),a0	* a0 is ptr to EXC_LV+L_SCR1 for exp digits
	BSR	binstr			* call binstr to convert exp
	MOVE.L	EXC_LV+L_SCR1(a6),d0	* load EXC_LV+L_SCR1 lword to d0
	MOVE.L	#12,d1			* use d1 for shift count
	LSR.L	d1,d0			* shift d0 right by 12
	BFINS	d0,EXC_LV+FP_SCR0(a6){4:12}	* put e3:e2:e1 in EXC_LV+FP_SCR0
	LSR.L	d1,d0			* shift d0 right by 12
	BFINS	d0,EXC_LV+FP_SCR0(a6){16:4}	* put e4 in EXC_LV+FP_SCR0
	TST.B	d0			* check if e4 is zero
	BEQ	A16_st			* if zero, skip rest
	OR.L	#opaop_mask,EXC_LV+USER_FPSR(a6)	* set OPERR # AIOP in USER_FPSR


                *+------------------------------------------------------------------------------
	* A16. Write sign bits to final string.
	*	   Sigma is bit 31 of initial value; RHO is bit 31 of d6 (ILOG).
	*
	* Register usage:
	*	Input/Output
	*	d0: x/scratch - final is x
	*	d2: x/x
	*	d3: x/x
	*	d4: LEN/Unchanged
	*	d5: ICTR:LAMBDA/LAMBDA:ICTR
	*	d6: ILOG/ILOG adjusted
	*	d7: k-factor/Unchanged
	*	a0: ptr to EXC_LV+L_SCR1(a6)/Unchanged
	*	a1: ptr to PTENxx array/Unchanged
	*	a2: ptr to EXC_LV+FP_SCR1(a6)/Unchanged
	*	fp0: float(ILOG)/Unchanged
	*	fp1: 10^ISCALE/Unchanged
	*	fp2: 10^LEN/Unchanged
	*	F_SCR1:BCD result with correct signs
	*	F_SCR2:ILOG/10^4
	*	EXC_LV+L_SCR1:Exponent digits on return from binstr
	*	EXC_LV+L_SCR2:first word of X packed/Unchanged
A16_st:
	CLR.L	d0			* clr d0 for collection of signs
	AND.B	#$0f,EXC_LV+FP_SCR0(a6)	* clear first nibble of EXC_LV+FP_SCR0
	TST.L	EXC_LV+L_SCR2(a6)	* check sign of original mantissa
	BGE	mant_p			* if pos, don't set SM
	MOVE.L	#2,d0			* move 2 in to d0 for SM
mant_p:
	TST.L	d6			* check sign of ILOG
	BGE	wr_sgn			* if pos, don't set SE
	ADDQ.L	#1,d0			* set bit 0 in d0 for SE
wr_sgn:
	BFINS	d0,EXC_LV+FP_SCR0(a6){0:2}	* insert SM and SE into EXC_LV+FP_SCR0

                *+------------------------------------------------------------------------------
	* Clean up and restore all registers used.

	FMOVE.L	#0,fpsr			* clear possible inex2/ainex bits
	FMOVEM.X	(sp)+,fp0-fp2		*  {fp0-fp2}
	MOVEM.l	(sp)+,d2-d7/a2		*  {d2-d7/a2}
	RTS

PTENRN:	dc.l	$40020000,$A0000000,$00000000	* 10 ^ 1
	dc.l	$40050000,$C8000000,$00000000	* 10 ^ 2
	dc.l	$400C0000,$9C400000,$00000000	* 10 ^ 4
	dc.l	$40190000,$BEBC2000,$00000000	* 10 ^ 8
	dc.l	$40340000,$8E1BC9BF,$04000000	* 10 ^ 16
	dc.l	$40690000,$9DC5ADA8,$2B70B59E	* 10 ^ 32
	dc.l	$40D30000,$C2781F49,$FFCFA6D5	* 10 ^ 64
	dc.l	$41A80000,$93BA47C9,$80E98CE0	* 10 ^ 128
	dc.l	$43510000,$AA7EEBFB,$9DF9DE8E	* 10 ^ 256
	dc.l	$46A30000,$E319A0AE,$A60E91C7	* 10 ^ 512
	dc.l	$4D480000,$C9767586,$81750C17	* 10 ^ 1024
	dc.l	$5A920000,$9E8B3B5D,$C53D5DE5	* 10 ^ 2048
	dc.l	$75250000,$C4605202,$8A20979B	* 10 ^ 4096

PTENRP:	dc.l	$40020000,$A0000000,$00000000	* 10 ^ 1
	dc.l	$40050000,$C8000000,$00000000	* 10 ^ 2
	dc.l	$400C0000,$9C400000,$00000000	* 10 ^ 4
	dc.l	$40190000,$BEBC2000,$00000000	* 10 ^ 8
	dc.l	$40340000,$8E1BC9BF,$04000000	* 10 ^ 16
	dc.l	$40690000,$9DC5ADA8,$2B70B59E	* 10 ^ 32
	dc.l	$40D30000,$C2781F49,$FFCFA6D6	* 10 ^ 64
	dc.l	$41A80000,$93BA47C9,$80E98CE0	* 10 ^ 128
	dc.l	$43510000,$AA7EEBFB,$9DF9DE8E	* 10 ^ 256
	dc.l	$46A30000,$E319A0AE,$A60E91C7	* 10 ^ 512
	dc.l	$4D480000,$C9767586,$81750C18	* 10 ^ 1024
	dc.l	$5A920000,$9E8B3B5D,$C53D5DE5	* 10 ^ 2048
	dc.l	$75250000,$C4605202,$8A20979B	* 10 ^ 4096

PTENRM:
	dc.l	$40020000,$A0000000,$00000000	* 10 ^ 1
	dc.l	$40050000,$C8000000,$00000000	* 10 ^ 2
	dc.l	$400C0000,$9C400000,$00000000	* 10 ^ 4
	dc.l	$40190000,$BEBC2000,$00000000	* 10 ^ 8
	dc.l	$40340000,$8E1BC9BF,$04000000	* 10 ^ 16
	dc.l	$40690000,$9DC5ADA8,$2B70B59D	* 10 ^ 32
	dc.l	$40D30000,$C2781F49,$FFCFA6D5	* 10 ^ 64
	dc.l	$41A80000,$93BA47C9,$80E98CDF	* 10 ^ 128
	dc.l	$43510000,$AA7EEBFB,$9DF9DE8D	* 10 ^ 256
	dc.l	$46A30000,$E319A0AE,$A60E91C6	* 10 ^ 512
	dc.l	$4D480000,$C9767586,$81750C17	* 10 ^ 1024
	dc.l	$5A920000,$9E8B3B5D,$C53D5DE4	* 10 ^ 2048
	dc.l	$75250000,$C4605202,$8A20979A	* 10 ^ 4096


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* binstr(): Converts a 64-bit binary integer to bcd.
**-------------------------------------------------------------------------------------------------
*
* INPUT :
*	d2:d3 = 64-bit binary integer
*	d0    = desired length (LEN)
*	a0    = pointer to start in memory for bcd characters
*          	(This pointer must point to byte 4 of the first
*          	 lword of the packed decimal memory string.)
*
* OUTPUT :
*	a0 = pointer to LEN bcd digits representing the 64-bit integer.
*
* ALGORITHM :	The 64-bit binary is assumed to have a decimal point before
*	bit 63.  The fraction is multiplied by 10 using a mul by 2
*	shift and a mul by 8 shift.  The bits shifted out of the
*	msb form a decimal digit.  This process is iterated until
*	LEN digits are formed.
*
* A1. Init d7 to 1.  D7 is the byte digit counter, and if 1, the
*     digit formed will be assumed the least significant.  This is
*     to force the first byte formed to have a 0 in the upper 4 bits.
*
* A2. Beginning of the loop:
*     Copy the fraction in d2:d3 to d4:d5.
*
* A3. Multiply the fraction in d2:d3 by 8 using bit-field
*     extracts and shifts.  The three msbs from d2 will go into d1.
*
* A4. Multiply the fraction in d4:d5 by 2 using shifts.  The msb
*     will be collected by the carry.
*
* A5. Add using the carry the 64-bit quantities in d2:d3 and d4:d5
*     into d2:d3.  D1 will contain the bcd digit formed.
*
* A6. Test d7.  If zero, the digit formed is the ms digit.  If non-
*     zero, it is the ls digit.  Put the digit in its place in the
*     upper word of d0.  If it is the ls digit, write the word
*     from d0 to memory.
*
* A7. Decrement d6 (LEN counter) and repeat the loop until zero.
*
**-------------------------------------------------------------------------------------------------
                *+------------------------------------------------------------------------------
	*	Implementation Notes:
	*
	*	The registers are used as follows:
	*
	*	d0: LEN counter
	*	d1: temp used to form the digit
	*	d2: upper 32-bits of fraction for mul by 8
	*	d3: lower 32-bits of fraction for mul by 8
	*	d4: upper 32-bits of fraction for mul by 2
	*	d5: lower 32-bits of fraction for mul by 2
	*	d6: temp for bit-field extracts
	*	d7: byte digit formation word;digit count {0,1}
	*	a0: pointer into memory for packed bcd string formation
	*

	xdef	binstr
binstr:
	MOVEM.L	d0-d7,-(sp)	*  {d0-d7}

                *+------------------------------------------------------------------------------
	* A1: Init d7
	*

	MOVE.L	#1,d7	* init d7 for second digit
	SUBQ.L	#1,d0	* for dbf d0 would have LEN+1 passes

                *+------------------------------------------------------------------------------
	* A2. Copy d2:d3 to d4:d5.  Start loop.
	*
loop:
	MOVE.L	d2,d4	* copy the fraction before muls
	MOVE.L	d3,d5	* to d4:d5

                *+------------------------------------------------------------------------------
	* A3. Multiply d2:d3 by 8; extract msbs into d1.
	*

	BFEXTU	d2{0:3},d1	* copy 3 msbs of d2 into d1
	ASL.L	#3,d2		* shift d2 left by 3 places
	BFEXTU	d3{0:3},d6	* copy 3 msbs of d3 into d6
	ASL.L	#3,d3		* shift d3 left by 3 places
	OR.L	d6,d2		* or in msbs from d3 into d2

                *+------------------------------------------------------------------------------
	*
	* A4. Multiply d4:d5 by 2; add carry out to d1.
	*
	ASL.L	#1,d5		* mul d5 by 2
	ROXL.L	#1,d4		* mul d4 by 2
	SWAP	d6		* put 0 in d6 lower word
	ADDX.W	d6,d1		* add in extend from mul by 2

                *+------------------------------------------------------------------------------
	*
	* A5. Add mul by 8 to mul by 2.  D1 contains the digit formed.
	*
	ADD.L	d5,d3		* add lower 32 bits
	NOP			* ERRATA FIX *13 (Rev. 1.2 6/6/90)
	ADDX.L	d4,d2		* add with extend upper 32 bits
	NOP			* ERRATA FIX *13 (Rev. 1.2 6/6/90)
	ADDX.W	d6,d1		* add in extend from add to d1
	SWAP	d6		* with d6 = 0; put 0 in upper word

                *+------------------------------------------------------------------------------
	*
	* A6. Test d7 and branch.
	*
	TST.W	d7		* if zero, store digit # to loop
	BEQ	first_d		* if non-zero, form byte # write
sec_d:
	SWAP	d7		* bring first digit to word d7b
	ASL.W	#4,d7		* first digit in upper 4 bits d7b
	ADD.W	d1,d7		* add in ls digit to d7b
	MOVE.B	d7,(a0)+		* store d7b byte in memory
	SWAP	d7		* put LEN counter in word d7a
	CLR.W	d7		* set d7a to signal no digits done
	DBF	d0,loop		* do loop some more!
	BRA	end_bstr	* finished, so exit
first_d:
	SWAP	d7		* put digit word in d7b
	MOVE.W	d1,d7		* put new digit in d7b
	SWAP	d7		* put LEN counter in word d7a
	ADDQ.W	#1,d7		* set d7a to signal first digit done
	DBF	d0,loop		* do loop some more!

	SWAP	d7		* put last digit in string
	LSL.W	#4,d7		* move it to upper 4 bits
	MOVE.B	d7,(a0)+	* store it in memory string

                *+------------------------------------------------------------------------------
	*
	* Clean up and return with result in fp0.
	*
end_bstr:
	MOVEM.L	(sp)+,d0-d7	*  {d0-d7}
	RTS





