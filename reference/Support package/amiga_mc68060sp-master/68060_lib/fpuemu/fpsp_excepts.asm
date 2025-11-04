
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
** This source module contains the 68060 exception handler. These exceptions are thrown
** on misc. events ranging from Dummy exception caused by the 060 achtecture to
** real exceptions caused by math operation (over / underflows etc.)
**
** These Handlers care about these stuff and correct them as possible. Otherwise
** the standard eception handling in EXEC is triggered.
**
** Many many things needed for Unix were thrown out, are the are unneeded at AmigaOS.
**---------------------------------------------------------------------------------------------
	MACHINE	MC68060
	OPT             !
                SECTION         FPSP060,Code
	NEAR            CODE

	NOLIST
	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i

	include         fpsp_debug.i
	include	fpsp_emu.i

MYDEBUG	SET         	0		* Current Debug Level
DEBUG_DETAIL 	set 	10		* Detail Level

**---------------------------------------------------------------------------------------------

	XREF	_real_ovfl,_real_inex,_real_trace,_real_unfl,_real_snan
	XREF	_real_operr,_real_fpu_disabled,_real_access,_real_dz
	XREF	_real_fline,_real_bsun,_real_trap
	XREF	_fpsp_done

**---------------------------------------------------------------------------------------------
	*** fpsp_trans.asm

	XREF	tbl_unsupp		* emulation table
	XREF	tbl_trans		* emulation table

	*** fpsp_fxcc.asm

	XREF	_fdbcc			* FDB<cc>()
	XREF	_fscc			* FS<cc>()
	XREF	_ftrapcc		* FTRAP<cc>()

	***fpsp_fouts.asm

	XREF	fout,fmovm_dynamic,fmovm_ctrl
	XREF	fmovm_calc_ea,smovcr

	*** fpsp_subs.asm

	XREF	set_tag_x,load_fpn2,unnorm_fix,store_fpreg
	XREF	get_packed,load_fpn1,dnrm_lp,decbin,norm
	XREF	store_dreg_b,store_dreg_w,store_dreg_l
	XREF	_calc_ea_fout,_load_fop


**---------------------------------------------------------------------------------------------
**---------------------------------------------------------------------------------------------
	XDEF	_fpsp_snan
	XDEF	_fpsp_operr
	XDEF	_fpsp_ovfl
	XDEF	_fpsp_unfl
	XDEF	_fpsp_dz
	XDEF	_fpsp_inex
	XDEF	_fpsp_fline
	XDEF	_fpsp_unsupp
	XDEF	_fpsp_effadd

*	XDEF	fix_skewed_ops		* fix src op
*	XDEF	funimp_skew		* skew sgl or dbl inputs




**---------------------------------------------------------------------------------------------
**---------------------------------------------------------------------------------------------
** _fpsp_ovfl(): 060FPSP entry point for FP Overflow exception.
**---------------------------------------------------------------------------------------------
**---------------------------------------------------------------------------------------------
**
** This handler should be the first code executed upon taking the FP Overflow exception
** in an operating system.
**
** XREF :
**        fix_skewed_ops()  - adjust src operand in fsave frame
**        set_tag_x()       - determine optype of src/dst operands
**        store_fpreg()     - store opclass 0 or 2 result to FP regfile
**        unnorm_fix()      - change UNNORM operands to NORM or ZERO
**        load_fpn2()       - load dst operand from FP regfile
**        fout()            - emulate an opclass 3 instruction
**        tbl_unsupp        - add of table of emulation routines for opclass 0,2
**
**        _fpsp_done()      - "callout" for 060FPSP exit (all work done!)
**        _real_ovfl()      - "callout" for Overflow exception enabled code
**        _real_inex()      - "callout" for Inexact exception enabled code
**        _real_trace()     - "callout" for Trace exception code
**
** INPUT :
**        - The system stack contains the FP Ovfl exception stack frame
**        - The fsave frame contains the source operand
**
** OUTPUT :
**        Overflow Exception enabled:
**           - The system stack is unchanged
**           - The fsave frame contains the adjusted src op for opclass 0,2
**        Overflow Exception disabled:
**           - The system stack is unchanged
**           - The "exception present" flag in the fsave frame is cleared
**
** ALGORITHM :
**
**  On  the  060,  if an FP overflow is present as the result of any instruction, the 060 will
** take an overflow exception whether the exception is enabled or disabled in the FPCR.
**
**  For the DISABLED case, this handler emulates the instruction to determine what the correct
** default  result  should be for the operation.  This default result is then stored in either
** the  FP regfile, data regfile, or memory.  Finally, the handler exits through the "callout"
** _fpsp_done() denoting that no exceptional conditions exist within the machine.
**
**  If  the  exception  is  ENABLED, then this handler must create the exceptional operand and
** plave it in the fsave state frame, and store the default result (only if the instruction is
** opclass  3).   For  exceptions  enabled,  this  handler  must  exit  through  the "callout"
** _real_ovfl() so that the operating system enabled overflow handler can handle this case.
**
** Two  other conditions exist.  First, if overflow was disabled but the inexact exception was
** enabled,  this  handler  must exit through the "callout" _real_inex() regardless of whether
** the result was inexact.
**
** Also, in the case of an opclass three instruction where overflow was disabled and the trace
** exception was enabled, this handler must exit through the "callout" _real_trace().
**
**----------------------------------------------------------------------------------------------
**----------------------------------------------------------------------------------------------

	XDEF	_fpsp_ovfl
_fpsp_ovfl:
	DBUG	10,"<OVERFLOW EXCEPTION>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* grab the "busy" frame

	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	**-----------------------------------------------------------------------------
	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),EXC_LV+EXC_OPWORD(a6)	* fetch the instruction words

	**-----------------------------------------------------------------------------

	BTST	#5,EXC_LV+EXC_CMDREG(a6)	* is instr an fmove out?
	BNE	fovfl_out            		* yep, direction out set !

	**-----------------------------------------------------------------------------

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to src op
	BSR	fix_skewed_ops			* fix src op

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to src op
	BSR	set_tag_x			* tag the operand type
	MOVE.B	d0,EXC_LV+STAG(a6)		* maybe NORM,DENORM

	**-----------------------------------------------------------------------------
	* bit five of the fp extension word separates the monadic and dyadic operations
	* that can pass through fpsp_ovfl(). remember that fcmp, ftst, and fsincos
	* will never take this exception.

	BTST	#5,EXC_LV+EXC_CMDREG+1(a6)	* is operation monadic or dyadic?
	BEQ	fovfl_extract			* monadic

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg
	BSR	load_fpn2			* load dst into EXC_LV+FP_DST

	LEA	EXC_LV+FP_DST(a6),a0	* pass: ptr to dst op
	BSR	set_tag_x		* tag the operand type

	CMPI.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	fovfl_op2_done		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
fovfl_op2_done:
	MOVE.B	d0,EXC_LV+DTAG(a6)	* save dst optype tag

	**-----------------------------------------------------------------------------
	* Ok, everythings is prepared now. So do the emulation, to get default result
	* Maybe we can make these entry points ONLY the OVFL entry points
                * of each routine.
fovfl_extract:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* d0: pass rnd prec/mode
	BFEXTU	EXC_LV+EXC_CMDREG+1(a6){1:7},d1 * d1: extract extension
	ANDI.L	#$00ff01ff,EXC_LV+USER_FPSR(a6) * zero all but accured field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr
	LEA	EXC_LV+FP_SRC(a6),a0   		* Get Addr of SRC/DST storage
	LEA	EXC_LV+FP_DST(a6),a1
	MOVE.L	((tbl_unsupp).w,pc,d1.w*4),d1 	* fetch routine addr
	JSR	((tbl_unsupp).w,pc,d1.l*1)

	**-----------------------------------------------------------------------------
	* the operation has been emulated. the result is in fp0.
	* the EXOP, if an exception occurred, is in fp1.
	* we must save the default result regardless of whether
	* traps are enabled or disabled.

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0
	BSR	store_fpreg

	**-----------------------------------------------------------------------------
	* the exceptional possibilities we have left ourselves with are ONLY overflow
	* and inexact. and, the inexact is such that overflow occurred and was disabled
	* but inexact was enabled.

	BTST	#ovfl_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	fovfl_ovfl_on                   * Handle OVFL exception

	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	fovfl_inex_on			* Handle INEX exception

	**-----------------------------------------------------------------------------
	* All done so far. Go back to user program.

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6				* Unlink Stackframe
**$$	BRA	_fpsp_done
	RTE

	**-----------------------------------------------------------------------------
	* overflow is enabled AND overflow, of course, occurred. so, we have the EXOP
	* in fp1. now, simply jump to _real_ovfl()!
fovfl_ovfl_on:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6)		* save EXOP (fp1) to stack
	MOVE.W	#$e005,EXC_LV+FP_SRC+2(a6) 	* save exc status

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)	* do this after fmovm,other f<op>s!
	UNLK	a6           		* now state is like exception happened
	BRA	_real_ovfl              * on 68881

	**-----------------------------------------------------------------------------
	* overflow occurred but is disabled. meanwhile, inexact is enabled. therefore,
	* we must jump to real_inex().
fovfl_inex_on:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6) 		* save EXOP (fp1) to stack
	MOVE.W	#$e001,EXC_LV+FP_SRC+2(a6) 	* save exc status

	MOVE.B	#$c4,EXC_VOFF+1(a6)		* vector offset = $c4

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)	* do this after fmovm,other f<op>s!
	UNLK	a6
	BRA	_real_inex

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* The exception was caused by a move out op.
fovfl_out:
	* the src operand is definitely a NORM(!), so tag it as such

	MOVE.B	#NORM,EXC_LV+STAG(a6)		* set src optype tag

	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass rnd prec/mode
	AND.L	#$ffff00ff,EXC_LV+USER_FPSR(a6) * zero all but accured field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr
	LEA	EXC_LV+FP_SRC(a6),a0		* pass ptr to src operand
	BSR	fout

	**-----------------------------------------------------------------------------

	BTST	#ovfl_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	fovfl_ovfl_on

	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	fovfl_inex_on

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6              * now state is complettly restored

	**-----------------------------------------------------------------------------
.
	BTST	#7,(sp)		* is trace on ?
	BEQ	_fpsp_done	* no

	FMOVE.L	fpiar,$8(sp)	* "Current PC" is in FPIAR
	MOVE.W	#$2024,$6(sp)	* stk fmt = $2; voff = $024
	BRA	_real_trace







**-----------------------------------------------------------------------------------------
**-----------------------------------------------------------------------------------------
**    _fpsp_unfl(): 060FPSP entry point for FP Underflow exception.
**-----------------------------------------------------------------------------------------
**-----------------------------------------------------------------------------------------
**
**            This handler should be the first code executed upon taking the
**            FP Underflow exception in an operating system.
**
** XREF :
**         fix_skewed_ops() 	- adjust src operand in fsave frame
**         set_tag_x() 	- determine optype of src/dst operands
**         store_fpreg() 	- store opclass 0 or 2 result to FP regfile
**         unnorm_fix() 	- change UNNORM operands to NORM or ZERO
**         load_fpn2() 	- load dst operand from FP regfile
**         fout()	- emulate an opclass 3 instruction
**         tbl_unsupp 	- add of table of emulation routines for opclass 0,2
**         _fpsp_done() 	- "callout" for 060FPSP exit (all work done!)
**
**         _real_unfl() 	- "callout" for Overflow exception enabled code
**         _real_inex() 	- "callout" for Inexact exception enabled code
**         _real_trace()	- "callout" for Trace exception code
**
** INPUT :
**         - The system stack contains the FP Unfl exception stack frame
**         - The fsave frame contains the source operand
**
** OUTPUT :
**          Underflow Exception enabled:
**              - The system stack is unchanged
**              - The fsave frame contains the adjusted src op for opclass 0,2
**          Underflow Exception disabled:
**              - The system stack is unchanged
**              - The "exception present" flag in the fsave frame is cleared
**
** ALGORITHM ***********************************************************
**
**  On  the  060, if an FP underflow is present as the result of any instruction, the 060
** will  take  an  underflow exception whether the exception is enabled or disabled in the
** FPCR.   For  the disabled case, This handler emulates the instruction to determine what
** the  correct  default  result should be for the operation.  This default result is then
** stored  in  either the FP regfile, data regfile, or memory.  Finally, the handler exits
** through the "callout" _fpsp_done() denoting that no exceptional conditions exist within
** the machine.
**
**  If the exception is enabled, then this handler must create the exceptional operand and
** plave  it  in  the  fsave  state  frame,  and  store  the  default  result (only if the
** instruction  is opclass 3).  For exceptions enabled, this handler must exit through the
** "callout" _real_unfl() so that the operating system enabled overflow handler can handle
** this case.
**
**  Two  other  conditions  exist.   First,  if  underflow  was  disabled  but the inexact
** exception  was  enabled  and the result was inexact, this handler must exit through the
** "callout" _real_inex().  was inexact.
**
**  Also, in the case of an opclass three instruction where underflow was disabled and the
** trace   exception   was   enabled,   this  handler  must  exit  through  the  "callout"
** _real_trace().
**-----------------------------------------------------------------------------------------

	xdef	_fpsp_unfl
_fpsp_unfl:
	DBUG	10,"<UNDERFLOW EXCEPTION>"

	LINK	a6,#-EXC_SIZEOF			* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)		* grab the "busy" frame

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	**-----------------------------------------------------------------------------
	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(A0),EXC_LV+EXC_OPWORD(a6)	* fetch the instruction words

	**-----------------------------------------------------------------------------

	BTST	#$5,EXC_LV+EXC_CMDREG(a6)	* is instr an fmove out?
	BNE	funfl_out

	**-----------------------------------------------------------------------------

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to src op
	BSR	fix_skewed_ops			* fix src op

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to src op
	BSR	set_tag_x			* tag the operand type
	MOVE.B	d0,EXC_LV+STAG(a6)		* maybe NORM,DENORM

	**-----------------------------------------------------------------------------
	* bit five of the fp extention word separates the monadic and dyadic operations
	* that can pass through fpsp_unfl(). remember that fcmp, and ftst
	* will never take this exception.

	BTST	#5,EXC_LV+EXC_CMDREG+1(a6)	* is op monadic or dyadic?
	BEQ	funfl_extract	* monadic

	**-----------------------------------------------------------------------------
	* now, what's left that's not dyadic is fsincos. we can distinguish it
	* from all dyadics by the '011$xx pattern

	BTST	#4,EXC_LV+EXC_CMDREG+1(a6)	* is op an fsincos?
	BNE	funfl_extract			* yes

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg
	BSR	load_fpn2			* load dst into EXC_LV+FP_DST

	LEA	EXC_LV+FP_DST(a6),a0	* pass: ptr to dst op
	BSR	set_tag_x		* tag the operand type

	CMPI.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	funfl_op2_done		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
funfl_op2_done:
	MOVE.B	d0,EXC_LV+DTAG(a6)	* save dst optype tag

	**-----------------------------------------------------------------------------
	* Ok, everythings is prepared now. So do the emulation, to get default result
	* Maybe we can make these entry points ONLY the UNFL entry points
                * of each routine.
funfl_extract:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* d0: pass rnd prec/mode
	BFEXTU	EXC_LV+EXC_CMDREG+1(a6){1:7},d1 * d1: extract extension
	ANDI.L	#$00ff01ff,EXC_LV+USER_FPSR(a6)
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr
	LEA	EXC_LV+FP_SRC(a6),a0
	LEA	EXC_LV+FP_DST(a6),a1
	MOVE.L	((tbl_unsupp).w,pc,d1.w*4),d1 	* fetch routine addr
	JSR	((tbl_unsupp).w,pc,d1.l*1)

	**-----------------------------------------------------------------------------
	* the operation has been emulated. the result is in fp0.
	* the EXOP, if an exception occurred, is in fp1.
	* we must save the default result regardless of whether
	* traps are enabled or disabled.

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0
	BSR	store_fpreg

	**-----------------------------------------------------------------------------
	* The `060 FPU multiplier hardware is such that if the result of a
	* multiply operation is the smallest possible normalized number
	* ($00000000_80000000_00000000), then the machine will take an
	* underflow exception. Since this is incorrect, we need to check
	* if our emulation, after re-doing the operation, decided that
	* no underflow was called for. We do these checks only in
	* funfl_{unfl,inex}_on() because w/ both exceptions disabled, this
	* special case will simply exit gracefully with the correct result.

	**-----------------------------------------------------------------------------
	* the exceptional possibilities we have left ourselves with are ONLY overflow
	* and inexact. and, the inexact is such that overflow occurred and was disabled
	* but inexact was enabled.

	BTST	#unfl_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	funfl_unfl_on
funfl_chkinex:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE 	funfl_inex_on

	**-----------------------------------------------------------------------------
	* All done so far. Go back to user program.
funfl_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6			* do not reload fpu frame as this cause
**$$	BRA	_fpsp_done              * exception again !
	RTE

	**-----------------------------------------------------------------------------
	* underflow is enabled AND underflow, of course, occurred. so, we have the EXOP
	* in fp1 (don't forget to save fp0). what to do now?
	* well, we simply have to get to go to _real_unfl()!
	**-----------------------------------------------------------------------------
	* The `060 FPU multiplier hardware is such that if the result of a
	* multiply operation is the smallest possible normalized number
	* ($00000000_80000000_00000000), then the machine will take an
	* underflow exception. Since this is incorrect, we check here to see
	* if our emulation, after re-doing the operation, decided that
	* no underflow was called for.

funfl_unfl_on:
	BTST	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6)
	BEQ	funfl_chkinex
funfl_unfl_on2:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6)		* save EXOP (fp1) to stack
	MOVE.W	#$e003,2+EXC_LV+FP_SRC(a6) 	* save exc status

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)	* do this after fmovm,other f<op>s!
	UNLK	a6                      * now state is like exception happened
	BRA	_real_unfl              * on 68881

	**-----------------------------------------------------------------------------
	* underflow occurred but is disabled. meanwhile, inexact is enabled. therefore,
	* we must jump to real_inex().
	**-----------------------------------------------------------------------------
	* The `060 FPU multiplier hardware is such that if the result of a
	* multiply operation is the smallest possible normalized number
	* ($00000000_80000000_00000000), then the machine will take an
	* underflow exception.
	* But, whether bogus or not, if inexact is enabled AND it occurred,
	* then we have to branch to real_inex.
funfl_inex_on:
	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6)
	BEQ	funfl_exit
funfl_inex_on2:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6) 		* save EXOP to stack
	MOVE.W	#$e001,EXC_LV+FP_SRC+2(a6) 	* save exc status

	MOVE.B	#$c4,EXC_VOFF+1(a6)		* vector offset = $c4

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)	* do this after fmovm,other f<op>s!
	UNLK	a6
	BRA	_real_inex

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* The exception was caused by a move out op.
funfl_out:
	* the src operand is definitely a NORM(!), so tag it as such

	MOVE.B	#NORM,EXC_LV+STAG(a6)		* set src optype tag

	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass rnd prec/mode
	AND.L	#$ffff00ff,EXC_LV+USER_FPSR(a6) * zero all but accured field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr
	LEA	EXC_LV+FP_SRC(a6),a0		* pass ptr to src operand
	BSR	fout

	**-----------------------------------------------------------------------------

	BTST	#unfl_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	funfl_unfl_on2

	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6)
	BNE	funfl_inex_on2

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6             	* now state is complettly restored

	**-----------------------------------------------------------------------------

	BTST	#$7,(sp)	* is trace on?
	BEQ	_fpsp_done	* no

	FMOVE.L	fpiar,$8(sp)	* "Current PC" is in FPIAR
	MOVE.W	#$2024,$6(sp)	* stk fmt = $2; voff = $024
	BRA	_real_trace









**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**  _fpsp_unsupp(): 060FPSP entry point for FP "Unimplemented Data Type" exception.
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**
**       This handler should be the first code executed upon taking the
**       FP Unimplemented Data Type exception in an operating system.
**
** xdef :
**         _imem_read_{word,dc.l}() - read instruction word/longword
**
**         fix_skewed_ops() 	- adjust src operand in fsave frame
**         set_tag_x() 	- determine optype of src/dst operands
**         store_fpreg() 	- store opclass 0 or 2 result to FP regfile
**         unnorm_fix() 	- change UNNORM operands to NORM or ZERO
**         load_fpn2() 	- load dst operand from FP regfile
**         load_fpn1() 	- load src operand from FP regfile
**         fout() 	- emulate an opclass 3 instruction
**         tbl_unsupp 	- add of table of emulation routines for opclass 0,2
**         funimp_skew() 	- adjust fsave src ops to "incorrect" value
**
**         _real_inex() 	- "callout" to operating system inexact handler
**         _fpsp_done() 	- "callout" for exit; work all done
**         _real_trace() 	- "callout" for Trace enabled exception
**         _real_snan() 	- "callout" for SNAN exception
**         _real_operr() 	- "callout" for OPERR exception
**         _real_ovfl() 	- "callout" for OVFL exception
**         _real_unfl() 	- "callout" for UNFL exception
**         get_packed() 	- fetch packed operand from memory
**
** INPUT :
**         - The system stack contains the "Unimp Data Type" stk frame
**         - The fsave frame contains the ssrc op (for UNNORM/DENORM)
**
** OUTPUT :
**          If Inexact exception (opclass 3):
**              - The system stack is changed to an Inexact exception stk frame
**          If SNAN exception (opclass 3):
**              - The system stack is changed to an SNAN exception stk frame
**          If OPERR exception (opclass 3):
**              - The system stack is changed to an OPERR exception stk frame
**          If OVFL exception (opclass 3):
**              - The system stack is changed to an OVFL exception stk frame
**          If UNFL exception (opclass 3):
**              - The system stack is changed to an UNFL exception stack frame
**          If Trace exception enabled:
**              - The system stack is changed to a Trace exception stack frame
**          Else: (normal case)
**              - Correct result has been stored as appropriate
**
** ALGORITHM ***********************************************************
**
** Two main instruction types can enter here:  (1) DENORM or UNNORM unimplemented data types.
** These can be either opclass 0,2 or 3 instructions, and (2) PACKED unimplemented data format
** instructions also of opclasses 0,2, or 3.
**
**  For  UNNORM/DENORM  opclass  0  and  2, the handler fetches the src operand from the fsave
** state  frame and the dst operand (if dyadic) from the FP register file.  The instruction is
** then  emulated  by  choosing  an  emulation  routine  from  a  table of routines indexed by
** instruction  type.   Once the instruction has been emulated and result saved, then we check
** to  see  if  any  enabled exceptions resulted from instruction emulation.  If none, then we
** exit  through  the  "callout"  _fpsp_done().   If there is an enabled FP exception, then we
** insert  this  exception  into  the  FPU  in  the  fsave  state  frame and then exit through
** _fpsp_done().
**
**  PACKED  opclass  0  and  2  is  similar  in how the instruction is emulated and exceptions
** handled.   The  differences  occur  in  how  the  handler  loads  the packed op (by calling
** get_packed()  routine)  and  by the fact that a Trace exception could be pending for PACKED
** ops.  If a Trace exception is pending, then the current exception stack frame is changed to
** a Trace exception stack frame and an exit is made through _real_trace().
**
**  For  UNNORM/DENORM  opclass  3,  the actual move out to memory is performed by calling the
** routine  fout().   If  no  exception  should occur as the result of emulation, then an exit
** either occurs through _fpsp_done() or through _real_trace() if a Trace exception is pending
** (a  Trace stack frame must be created here, too).  If an FP exception should occur, then we
** must  create  an  exception  stack  frame  of  that  type  and jump to either _real_snan(),
** _real_operr(),  _real_inex(), _real_unfl(), or _real_ovfl() as appropriate.  PACKED opclass
** 3 emulation is performed in a similar manner.
**
**--------------------------------------------------------------------------------------------
*
* (1) DENORM and UNNORM (unimplemented) data types:
*
*                                       post-instruction
*	*****************
*	*      EA       *
*               *pre-instruction*
* 	*****************	*****************
*	* $0 *  $0dc    *	* $3 *  $0dc    *
*	*****************	*****************
*	*     Next	*	*     Next
*	*      PC	*	*      PC
*	*****************	*****************
*	*      SR	*	*      SR
*	*****************	*****************
*
* (2) PACKED format (unsupported) opclasses two and three:
*	*****************
*	*      EA
*	*
*	*****************
*	* $2 *  $0dc
*	*****************
*	*     Next
*	*      PC
*	*****************
*	*      SR
*	*****************
*
	xdef	_fpsp_unsupp
_fpsp_unsupp:
	DBUG	10,"<UNSUPP DATATYPE EXCEPTION>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* save fp state

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	BTST	#5,EXC_SR(a6)		* user or supervisor mode?
	BNE	fu_s

	**-----------------------------------------------------------------------------
fu_u:
	move.l	usp,a0			* fetch user stack pointer
	move.l	a0,EXC_LV+EXC_A7(a6)	* save on stack
	bra.b	fu_cont

	**-----------------------------------------------------------------------------
	* if the exception is an opclass zero or two unimplemented data type
	* exception, then the a7' calculated here is wrong since it doesn't
	* stack an ea. however, we don't need an a7' for this case anyways.
fu_s:
	LEA	EXC_EA+4(a6),a0		* load old a7'
	MOVE.L	a0,EXC_LV+EXC_A7(a6)	* save on stack

fu_cont:
	**-----------------------------------------------------------------------------
	* the FPIAR holds the "current PC" of the faulting instruction
	* the FPIAR should be set correctly for ALL exceptions passing through
	* this point.

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	move.l	(A0),EXC_LV+EXC_OPWORD(a6)	* fetch the instruction words
						* store OPWORD and EXTWORD

	**-----------------------------------------------------------------------------

	CLR.B	EXC_LV+SPCOND_FLG(a6)	* clear special condition flag

	** Separate opclass three (fpn-to-mem) ops since they have a different
	** stack frame and protocol.

	BTST	#$5,EXC_LV+EXC_CMDREG(a6)	* is it an fmove out?
	BNE	fu_out				* yes

	** Separate packed opclass two instructions.

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){0:6},d0	*
	CMPI.B	#$13,d0
	BEQ	fu_in_pack

	**-----------------------------------------------------------------------------
	** I'm not sure at this point what FPSR bits are valid for this instruction.
	** so, since the emulation routines re-create them anyways, zero exception field

	ANDI.L	#$00ff00ff,EXC_LV+USER_FPSR(a6) * zero exception field

	FMOVE.L	#$0,fpcr		* zero current control regs
	FMOVE.L	#$0,fpsr

	**-----------------------------------------------------------------------------
	* Opclass two w/ memory-to-fpn operation will have an incorrect extended
	* precision format if the src format was single or double and the
	* source data type was an INF, NAN, DENORM, or UNNORM

	LEA	EXC_LV+FP_SRC(a6),a0	* pass ptr to input
	BSR	fix_skewed_ops

	**-----------------------------------------------------------------------------
	* we don't know whether the src operand or the dst operand (or both) is the
	* UNNORM or DENORM. call the function that tags the operand type. if the
	* input is an UNNORM, then convert it to a NORM, DENORM, or ZERO.

	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	set_tag_x		* tag the operand type

	CMPI.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	fu_op2			* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
fu_op2:
	MOVE.B	d0,EXC_LV+STAG(a6)	* save src optype tag

	**-----------------------------------------------------------------------------
	* bit five of the fp extension word separates the monadic and dyadic operations
	* at this point

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0	* dyadic; load dst reg

	BTST	#5,EXC_LV+EXC_CMDREG+1(a6)	* is operation monadic or dyadic?
	BEQ	fu_extract			* monadic

	CMPI.B	#$3a,EXC_LV+EXC_CMDREG+1(a6)	* is operation an ftst?
	BEQ	fu_extract			* yes, so it's monadic, too

	BSR	load_fpn2		* load dst into EXC_LV+FP_DST

	LEA	EXC_LV+FP_DST(a6),a0	* pass: ptr to dst op
	BSR	set_tag_x		* tag the operand type

	CMPI.B	#UNNORM	,d0		* is operand an UNNORM?
	BNE	fu_op2_done		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
fu_op2_done:
	MOVE.B	d0,EXC_LV+DTAG(a6)	* save dst optype tag

	**-----------------------------------------------------------------------------
	* Ok, everythings is prepared now. So do the emulation, to get default result
fu_extract:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* fetch rnd mode/prec
	BFEXTU.B	EXC_LV+EXC_CMDREG+1(a6){1:7},d1 * extract extension
	LEA	EXC_LV+FP_SRC(a6),a0
	LEA	EXC_LV+FP_DST(a6),a1
	MOVE.L	((tbl_unsupp).w,pc,d1.l*4),d1 	* fetch routine addr
	JSR	((tbl_unsupp).w,pc,d1.l*1)

	**-----------------------------------------------------------------------------
	*
	* Exceptions in order of precedence:
	* 	BSUN	: none
	*	SNAN	: all dyadic ops
	*	OPERR	: fsqrt(-NORM)
	*	OVFL	: all except ftst,fcmp
	*	UNFL	: all except ftst,fcmp
	*	DZ	: fdiv
	* 	INEX2	: all except ftst,fcmp
	*	INEX1	: none (packed doesn't go through here)
	*
	**-----------------------------------------------------------------------------
	* we determine the highest priority exception(if any) set by the
	* emulation routine that has also been enabled by the user.

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions set
	BNE	fu_in_ena			* some are enabled

fu_in_cont:
	**-----------------------------------------------------------------------------
	* fcmp and ftst do not store any result.

	MOVE.b	EXC_LV+EXC_CMDREG+1(a6),d0	* fetch extension
	ANDI.B	#$38,d0				* extract bits 3-5
	CMPI.B	#$38,d0				* is instr fcmp or ftst?
	BEQ	fu_in_exit			* yes

	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg
	BSR	store_fpreg			* store the result
fu_in_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6
**$$	BRA	_fpsp_done
	RTE


	**-----------------------------------------------------------------------------
	** Exceptions were enabled. So handle them....
fu_in_ena:
	and.b	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enabled
	bfffo	d0{24:8},d0			* find highest priority exception
	bne.b	fu_in_exc			* there is at least one set

	**-----------------------------------------------------------------------------
	*
	* No exceptions occurred that were also enabled. Now:
	*
	* if (OVFL && ovfl_disabled && inexact_enabled) {
	*    branch to _real_inex() (even if the result was exact!);
	* } else {
	*   save the result in the proper fp reg (unless the op is fcmp or ftst);
	*   return;
	* }

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* was overflow set?
	BEQ	fu_in_cont				* no, go user

fu_in_ovflchk:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6) 	* was inexact enabled?
	BEQ	fu_in_cont				* no

	BRA	fu_in_exc_ovfl		* go insert overflow frame

	**-----------------------------------------------------------------------------
	*
	* An exception occurred and that exception was enabled:
	*
	* shift enabled exception field into lo byte of d0;
	* if (((INEX2 || INEX1) && inex_enabled && OVFL && ovfl_disabled) ||
	*      ((INEX2 || INEX1) && inex_enabled && UNFL && unfl_disabled)) {
	*     /*
	*      * this is the case where we must call _real_inex() now or else
	*      * there will be no other way to pass it the exceptional operand
	*      */
	*      call _real_inex();
	* } else {
	*      restore exc state (SNAN||OPERR||OVFL||UNFL||DZ||INEX) into the FPU;
	* }
fu_in_exc:
	SUBI.L	#24,d0			* fix offset to be 0-8
	CMPI.B	#$6,d0			* is exception INEX? (6)
	BNE	fu_in_exc_exit		* no

	* the enabled exception was inexact

	BTST	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did disabled underflow occur?
	BNE	fu_in_exc_unfl			 * yes

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did disabled overflow occur?
	BNE	fu_in_exc_ovfl			 * yes

	**-----------------------------------------------------------------------------
	* here, we insert the correct fsave status value into the fsave frame for the
	* corresponding exception. the operand in the fsave frame should be the original
	* src operand.
fu_in_exc_exit:
	MOVE.L	d0,-(sp)	* save d0
	BSR	funimp_skew	* skew sgl or dbl inputs
	MOVE.L	(sp)+,d0	* restore d0

	MOVE.W	((tbl_except).b,pc,d0.w*2),EXC_LV+FP_SRC+2(a6) * create exc status

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src op
	UNLK	a6
**$$	BRA	_fpsp_done
	RTE

tbl_except:
	dc.w	$e000,$e006,$e004,$e005       	* FPU state status fields
	dc.w	$e003,$e002,$e001,$e001         * causing the enabled except
                                                                * state
	**-----------------------------------------------------------------------------
	** Now set specific state as it happend in emulation
fu_in_exc_unfl:
	MOVE.W	#4,d0
	BRA  	fu_in_exc_exit
fu_in_exc_ovfl:
	MOVE.W	#3,d0
	BRA	fu_in_exc_exit






**--------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------
**   fix_skewed_ops
**--------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------
**
** XREF:
**        norm()                - normalize mantissa
** INPUT:
**        a0 - Address of FPU state frame with possibilly skewed operand.
**
**
**  If  the  input  operand to this operation was opclass two and a single or double precision
** denorm,  inf,  or  nan,  the  operand  needs  to be "corrected" in order to have the proper
** equivalent extended precision number.
**
**--------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------

	xdef	fix_skewed_ops
fix_skewed_ops:
	DBUG	20,"<fix_skewed_ops:"

	BFEXTU	EXC_LV+EXC_CMDREG(a6){0:6},d0 	* extract opclass,src fmt
	CMPI.B	#%010001,d0			* is class = 2 & fmt = sgl?
	BEQ	fso_sgl				* yes

	CMPI.B	#%010101,d0			* is class = 2 # fmt = dbl?
	BEQ	fso_dbl				* yes

	DBUG	20,"nop>"
	RTS					* no - nothing to do....

	**-----------------------------------------------------------------------------
	** As the 060 can not convert this shitty formats anymore, we have to
	** check, if the op passed in wasn't suitable for further processing.
	** The value must be converted to extended format for further processing.

fso_sgl:
	MOVE.W	LOCAL_EX(a0),d0		* fetch src exponent
	ANDI.W	#$7fff,d0		* strip sign
	CMPI.W	#$3f80,d0		* is |exp| == $3f80 ?
	BEQ	fso_sgl_dnrm_zero	* yes

	CMPI.W	#$407f,d0		* no; is |exp| == $407f?
	BEQ	fso_infnan		* yes
	RTS				* no - ok number was ok and fitted.

fso_sgl_dnrm_zero:
	ANDI.L	#$7fffffff,LOCAL_HI(a0) * clear j-bit
	BEQ.B	fso_zero		* it's a skewed zero

fso_sgl_dnrm:
	DBUG	20,"single>"
				** here, we count on norm not to alter a0... !!!!!
	BSR	norm			* normalize mantissa, d0 = # bits shifted
	NEG.W	d0			* -shift amount
	ADDI.W	#$3f81,d0		* adjust new exponent
	ANDI.W	#$8000,LOCAL_EX(a0) 	* clear old exponent
	OR.W	d0,LOCAL_EX(a0)		* insert new exponent
	RTS

	**-----------------------------------------------------------------------------
fso_zero:
	DBUG	20,"zero>"
	ANDI.W	#$8000,LOCAL_EX(a0)	* clear bogus exponent
	RTS

	**-----------------------------------------------------------------------------
fso_infnan:
	DBUG	20,"infnan>"
	ANDI.B	#$7f,LOCAL_HI(a0) 	* clear j-bit
	OR.W	#$7fff,LOCAL_EX(a0)	* make exponent = $7fff
	RTS

	**-----------------------------------------------------------------------------
fso_dbl:
	MOVE.W	LOCAL_EX(a0),d0		* fetch src exponent
	ANDI.W	#$7fff,d0		* strip sign
	CMP.W	#$3c00,d0		* is |exp| == $3c00?
	BEQ	fso_dbl_dnrm_zero	* yes

	CMP.W	#$43ff,d0		* no; is |exp| == $43ff?
	BEQ	fso_infnan		* yes
	RTS				* no

fso_dbl_dnrm_zero:
	ANDI.L	#$7fffffff,LOCAL_HI(a0) * clear j-bit
	BNE	fso_dbl_dnrm		* it's a skewed denorm

	TST.L	LOCAL_LO(a0)		* is it a zero?
	BEQ	fso_zero		* yes

fso_dbl_dnrm:
	DBUG	20,"double>"
			** here, we count on norm not to alter a0... !!!!!!
	BSR	norm			* normalize mantissa
	NEG.W	d0			* -shft amt
	ADDI.W	#$3c01,d0		* adjust new exponent
	ANDI.W	#$8000,LOCAL_EX(a0) 	* clear old exponent
	OR.W	d0,LOCAL_EX(a0)		* insert new exponent
	rts







**--------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------
**  fpu unimplemented datatype MOVE OUT operation
**--------------------------------------------------------------------------------------------
**--------------------------------------------------------------------------------------------
** fmove out took an unimplemented data type exception.
** the src operand is in EXC_LV+FP_SRC. Call _fout() to write out the result and
** to determine which exceptions, if any, to take.
**--------------------------------------------------------------------------------------------

fu_out:
	DBUG	10,"<fu_out>"

	**-----------------------------------------------------------------------------
	* Separate packed move outs from the UNNORM and DENORM move outs.

	BFEXTU	EXC_LV+EXC_CMDREG(a6){3:3},d0

	CMP.B	#%011,d0		* Packed Data
	BEQ	fu_out_pack

	CMP.b	#%111,d0      		* RESERVED - should be illegal ?!!!
	BEQ	fu_out_pack


	**-----------------------------------------------------------------------------
	* I'm not sure at this point what FPSR bits are valid for this instruction.
	* so, since the emulation routines re-create them anyways, zero exception field.
	* fmove out doesn't affect ccodes.

	AND.L	#$ffff00ff,EXC_LV+USER_FPSR(a6) * zero exception field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr

	**-----------------------------------------------------------------------------
	* the src can ONLY be a DENORM or an UNNORM! so, don't make any big subroutine
	* call here. just figure out what it is...

	MOVE.W	EXC_LV+FP_SRC_EX(a6),d0		* get exponent
	ANDI.W	#$7fff,d0			* strip sign
	BEQ	fu_out_denorm			* it's a DENORM

	LEA	EXC_LV+FP_SRC(a6),a0
	BSR	unnorm_fix			* yes; fix it

	MOVE.B	d0,EXC_LV+STAG(a6)
	BRA	fu_out_cont
fu_out_denorm:
	MOVE.B	#DENORM,EXC_LV+STAG(a6)

	**-----------------------------------------------------------------------------
fu_out_cont:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* fetch rnd mode/prec
	LEA	EXC_LV+FP_SRC(a6),a0		* pass ptr to src operand

	MOVE.L	(a6),EXC_LV+EXC_A6(a6)		* in case a6 changes
	BSR	fout				* call fmove out routine

	**-----------------------------------------------------------------------------
	* Exceptions in order of precedence:
	* 	BSUN	: none
	*	SNAN	: none
	*	OPERR	: fmove.{b,w,l} out of large UNNORM
	*	OVFL	: fmove.{s,d}
	*	UNFL	: fmove.{s,d,x}
	*	DZ	: none
	* 	INEX2	: all
	*	INEX1	: none (packed doesn't travel through here)
                *
	* determine the highest priority exception(if any) set by the
	* emulation routine that has also been enabled by the user.

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions enabled
	BNE	fu_out_ena			* some are enabled
fu_out_done:
	MOVE.L	EXC_LV+EXC_A6(a6),(a6)		* in case a6 changed

	**-----------------------------------------------------------------------------
	* on extended precision opclass three instructions using pre-decrement or
	* post-increment addressing mode, the address register is not updated. if the
	* address register was the stack pointer used from user mode, then let's update
	* it here. if it was used from supervisor mode, then we have to handle this
	* as a special case.

	BTST	#5,EXC_SR(a6)
	BNE	fu_out_done_s

	MOVE.L	EXC_LV+EXC_A7(a6),a0		* restore a7
	MOVE.L	a0,usp

fu_out_done_cont:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6

	BTST	#7,(sp)			* is trace on?
	BNE	fu_out_trace		* yes
**$$	BRA	_fpsp_done
	RTE

	**-----------------------------------------------------------------------------
	* is the ea mode pre-decrement of the stack pointer from supervisor mode?
	* ("fmove.x fpm,-(a7)") if so,
fu_out_done_s:
	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BNE.B	fu_out_done_cont

	**-----------------------------------------------------------------------------
	* the extended precision result is still in fp0. but, we need to save it
	* somewhere on the stack until we can copy it to its final resting place.
	* here, we're counting on the top of the stack to be the old place-holders
	* for fp0/fp1 which have already been restored. that way, we can write
	* over those destinations with the shifted stack frame.

	FMOVEM.X	fp0,EXC_LV+FP_SRC(a6)			* put answer on stack

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6					* restore frame pointer

	** move down exception stack frame by 3 LONGS - only needed fields
	** EA field dumped...

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)

	** now, copy the result to the proper place on the stack
	** SP is still pointing to the start of EXC frame ! so use
	** xx(sp) to get data !

	MOVE.L	FP_SRC_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_SRC_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_SRC_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BTST	#7,(sp)			* Was this exception caused in Trace ?
	BNE	fu_out_trace

**$$	BRA	_fpsp_done
	RTE

	**-----------------------------------------------------------------------------
fu_out_ena:
	AND.B	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enabled
	BFFFO	d0{24:8},d0			* find highest priority exception
	BNE	fu_out_exc			* there is at least one set

	**-----------------------------------------------------------------------------
	* no exceptions were set.
	* if a disabled overflow occurred and inexact was enabled but the result
	* was exact, then a branch to _real_inex() is made.

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6)	* was overflow set?
	BEQ	fu_out_done				* no

fu_out_ovflchk:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6) 	* was inexact enabled?
	BEQ	fu_out_done				* no

	BRA	fu_inex					* yes

	**-----------------------------------------------------------------------------
	*
	* The fp move out that took the "Unimplemented Data Type" exception was
	* being traced. Since the stack frames are similar, get the "current" PC
	* from FPIAR and put it in the trace stack frame then jump to _real_trace().
	*
	*   UNSUPP FRAME            TRACE FRAME
	* *****************	*****************
	* *      EA       *	*    Current
	* *               *	*      PC
	* *****************	*****************
	* * $3 *  $0dc    *	* $2 *  $024
	* *****************	*****************
	* *     Next      *	*     Next
	* *      PC       *	*      PC
	* *****************	*****************
	* *      SR       *	*      SR
	* *****************	*****************
	*
fu_out_trace:
	MOVE.W	#$2024,$6(sp)		* set fr#2 , Vector $24 (Trace)
	FMOVE.L	fpiar,$8(sp)
	BRA	_real_trace


	**-----------------------------------------------------------------------------
	* an exception occurred and that exception was enabled.
fu_out_exc:
	SUBI.L	#24,d0			* fix offset to be 0-8

	* we don't mess with the existing fsave frame. just re-insert it and
	* jump to the "_real_{}()" handler...

	MOVE.W	((tbl_fu_out).b,pc,d0.w*2),d0
	JMP	((tbl_fu_out).b,pc,d0.w*1)

tbl_fu_out:
	dc.w	tbl_fu_out	- tbl_fu_out	* BSUN can't happen
	dc.w	tbl_fu_out 	- tbl_fu_out	* SNAN can't happen
	dc.w	fu_operr	- tbl_fu_out	* OPERR
	dc.w	fu_ovfl 	- tbl_fu_out	* OVFL
	dc.w	fu_unfl 	- tbl_fu_out	* UNFL
	dc.w	tbl_fu_out	- tbl_fu_out	* DZ can't happen
	dc.w	fu_inex 	- tbl_fu_out	* INEX2
	dc.w	tbl_fu_out	- tbl_fu_out	* INEX1 won't make it here

	**-----------------------------------------------------------------------------
	* for snan,operr,ovfl,unfl, src op is still in EXC_LV+FP_SRC so just
	* frestore it.
fu_snan:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e006,EXC_LV+FP_SRC+2(a6)	* Set except type to state frame
	MOVE.W	#$30d8,EXC_VOFF(a6)		* vector offset = $d8

	FRESTORE	EXC_LV+FP_SRC(a6)		* load state frame

	UNLK	a6				* Kill frame
	BRA	_real_snan

	**-----------------------------------------------------------------------------
fu_operr:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e004,EXC_LV+FP_SRC+2(a6)	* Set except type
	MOVE.W	#$30d0,EXC_VOFF(a6)		* vector offset = $d0

	FRESTORE	EXC_LV+FP_SRC(a6)

	UNLK	a6
	BRA	_real_operr

	**-----------------------------------------------------------------------------
fu_ovfl:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6)		* save EXOP to the stack

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e005,EXC_LV+FP_SRC+2(a6)	* set except type
	MOVE.W	#$30d4,EXC_VOFF(a6)		* vector offset = $d4

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore EXOP

	UNLK	a6
	BRA	_real_ovfl

	**-----------------------------------------------------------------------------
	* underflow can happen for extended precision. extended precision opclass
	* three instruction exceptions don't update the stack pointer. so, if the
	* exception occurred from user mode, then simply update a7 and exit normally.
	* if the exception occurred from supervisor mode, check it
fu_unfl:
	MOVE.L	EXC_LV+EXC_A6(a6),(a6)	* restore a6, value saved above !

	BTST	#5,EXC_SR(a6)		* supervisor mode ?
	BNE	fu_unfl_s

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* restore a7 whether we need
	MOVE.L	a0,usp			* to or not... saved above !

fu_unfl_cont:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6)	* save EXOP to the stack

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e003,EXC_LV+FP_SRC+2(a6)
	MOVE.W	#$30cc,EXC_VOFF(a6)		* vector offset = $cc

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore EXOP

	UNLK	a6
	BRA	_real_unfl

fu_unfl_s:
	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)	* was the <ea> mode -(sp)?
	BNE	fu_unfl_cont

	**-----------------------------------------------------------------------------
	* the extended precision result is still in fp0. but, we need to save it
	* somewhere on the stack until we can copy it to its final resting place
	* (where the exc frame is currently). make sure it's not at the top of the
	* frame or it will get overwritten when the exc stack frame is shifted "down".

	FMOVEM.X	fp0,EXC_LV+FP_SRC(a6)	* put answer on stack
	FMOVEM.X	fp1,EXC_LV+FP_DST(a6)	* put EXOP on stack

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e003,EXC_LV+FP_DST+2(a6)
	MOVE.W	#$30cc,EXC_VOFF(a6)		* vector offset = $cc

	FRESTORE	EXC_LV+FP_DST(a6)		* restore EXOP

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6				* restore frame pointer

	** move down exception stack frame by 3 LONGS - only needed fields

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_EA(sp),EXC_SIZEOF+EXC_EA-$12(sp)

	* now, copy the result to the proper place on the stack
	** SP is still pointing to the start of EXC frame ! so use
	** xx(sp) to get data !

	MOVE.L	FP_SRC_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_SRC_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_SRC_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BRA	_real_unfl


	**-----------------------------------------------------------------------------
	* fmove in and out enter here.
fu_inex:
	FMOVEM.X	fp1,EXC_LV+FP_SRC(a6)		* save EXOP to the stack

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e001,EXC_LV+FP_SRC+2(a6)
	MOVE.W	#$30c4,EXC_VOFF(a6)		* vector offset = $c4

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore EXOP

	UNLK	a6
	BRA	_real_inex


	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* I'm not sure at this point what FPSR bits are valid for this instruction.
	* so, since the emulation routines re-create them anyways, zero exception field

fu_in_pack:
	ANDI.L	#$0ff00ff,EXC_LV+USER_FPSR(a6) 	* zero exception field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr

	BSR	get_packed			* fetch packed src operand

	LEA	EXC_LV+FP_SRC(a6),a0		* pass ptr to src
	BSR	set_tag_x			* set src optype tag
	MOVE.B	d0,EXC_LV+STAG(a6)		* save src optype tag

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg

	**-----------------------------------------------------------------------------
	* bit five of the fp extension word separates the monadic and dyadic operations
	* at this point

	BTST	#5,EXC_LV+EXC_CMDREG+1(a6)	* is operation monadic or dyadic?
	BEQ	fu_extract_p			* monadic

	CMP.B	#$3a,EXC_LV+EXC_CMDREG+1(a6)	* is operation an ftst?
	BEQ	fu_extract_p			* yes, so it's monadic, too

	BSR	load_fpn2			* load dst into EXC_LV+FP_DST

	LEA	EXC_LV+FP_DST(a6),a0	* pass: ptr to dst op
	BSR	set_tag_x		* tag the operand type
	CMP.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	fu_op2_done_p		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
fu_op2_done_p:
	MOVE.B	d0,EXC_LV+DTAG(a6)	* save dst optype tag

	**-----------------------------------------------------------------------------

fu_extract_p:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* fetch rnd mode/prec
	BFEXTU	EXC_LV+EXC_CMDREG+1(a6){1:7},d1 * extract extension
	LEA	EXC_LV+FP_SRC(a6),a0
	LEA	EXC_LV+FP_DST(a6),a1
	MOVE.L	((tbl_unsupp).w,pc,d1.l*4),d1 	* fetch routine addr
	JSR	((tbl_unsupp).w,pc,d1.l*1)

	**-----------------------------------------------------------------------------
	* Exceptions in order of precedence:
	* 	BSUN	: none
	*	SNAN	: all dyadic ops
	*	OPERR	: fsqrt(-NORM)
	*	OVFL	: all except ftst,fcmp
	*	UNFL	: all except ftst,fcmp
	*	DZ	: fdiv
	* 	INEX2	: all except ftst,fcmp
	*	INEX1	: all
	**-----------------------------------------------------------------------------
	* we determine the highest priority exception(if any) set by the
	* emulation routine that has also been enabled by the user.

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions enabled
	BNE	fu_in_ena_p			* some are enabled

fu_in_cont_p:   ** fcmp and ftst do not store any result.

	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d0	* fetch extension
	ANDI.B	#$38,d0				* extract bits 3-5
	CMP.B	#$38,d0				* is instr fcmp or ftst?
	BEQ	fu_in_exit_p			* yes

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg
	BSR	store_fpreg			* store the result

fu_in_exit_p:
	BTST	#5,EXC_SR(a6)		* user or supervisor?
	BNE	fu_in_exit_s_p		* supervisor

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* update user a7, saved above
	MOVE.L	a0,usp

fu_in_exit_cont_p:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6		* unravel stack frame

	BTST	#7,(sp)		* is trace on?
	BNE	fu_trace_p	* yes

**$$	BRA	_fpsp_done	* exit to os
	RTE

	**-----------------------------------------------------------------------------
	* the exception occurred in supervisor mode. check to see if the
	* addressing mode was (a7)+. if so, we'll need to shift the
	* stack frame "up".

fu_in_exit_s_p:
	BTST	#mia7_bit,EXC_LV+SPCOND_FLG(a6) 	* was ea mode (a7)+
	BEQ	fu_in_exit_cont_p			* no

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6			* unravel stack frame

	* shift the stack frame "up". we don't really care about the <ea> field.

	MOVE.L	4(sp),4+12(sp)
	MOVE.L	0(sp),0+12(sp)

	ADD.L	#12,sp

	BTST	#7,(sp)		* is trace on?
	BNE	fu_trace_p	* yes

**$$	BRA	_fpsp_done	* exit to os
	RTE

	**-----------------------------------------------------------------------------
fu_in_ena_p:
	AND.B	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enabled # set
	BFFFO	d0{24:8},d0			* find highest priority exception
	BNE.B	fu_in_exc_p			* at least one was set

	**-----------------------------------------------------------------------------
	*
	* No exceptions occurred that were also enabled. Now:
	*
	* if (OVFL && ovfl_disabled && inexact_enabled) {
	*     branch to _real_inex() (even if the result was exact!);
	* } else {
	*     save the result in the proper fp reg (unless the op is fcmp or ftst);
	*     return;
	* }

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* was overflow set?
	BEQ	fu_in_cont_p			 	* no

fu_in_ovflchk_p:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6) 	* was inexact enabled?
	BEQ	fu_in_cont_p				* no

	BRA	fu_in_exc_ovfl_p			* do _real_inex() now

	**-----------------------------------------------------------------------------
	*
	* An exception occurred and that exception was enabled:
	*
	* shift enabled exception field into lo byte of d0;
	* if (((INEX2 || INEX1) && inex_enabled && OVFL && ovfl_disabled) ||
	*     ((INEX2 || INEX1) && inex_enabled && UNFL && unfl_disabled)) {
	* /*
	*  * this is the case where we must call _real_inex() now or else
	*  * there will be no other way to pass it the exceptional operand
	*  */
	*    call _real_inex();
	* } else {
	*   restore exc state (SNAN||OPERR||OVFL||UNFL||DZ||INEX) into the FPU;
	* }

fu_in_exc_p:
	SUBI.L	#24,d0			* fix offset to be 0-8
	CMP.B	#6,d0			* is exception INEX? (6 or 7)
	BLT	fu_in_exc_exit_p	* no

	* the enabled exception was inexact

	BTST	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did disabled underflow occur?
	BNE	fu_in_exc_unfl_p		 * yes

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did disabled overflow occur?
	BNE	fu_in_exc_ovfl_p		 * yes

	**-----------------------------------------------------------------------------
	* here, we insert the correct fsave status value into the fsave frame for the
	* corresponding exception. the operand in the fsave frame should be the original
	* src operand.
	* as a reminder for future predicted pain and agony, we are passing in fsave the
	* "non-skewed" operand for cases of sgl and dbl src INFs,NANs, and DENORMs.
	* this is INCORRECT for enabled SNAN which would give to the user the skewed SNAN!!!

fu_in_exc_exit_p:
	BTST	#5,EXC_SR(a6)		* user or supervisor?
	BNE	fu_in_exc_exit_s_p	* supervisor

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* update user a7, saved above
	MOVE.L	a0,usp

fu_in_exc_exit_cont_p:

	MOVE.W	((tbl_except_p).b,pc,d0.w*2),EXC_LV+FP_SRC+2(a6)

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src op

	UNLK	a6

	BTST	#7,(sp)				* is trace enabled?
	BNE	fu_trace_p			* yes

**$$	BRA	_fpsp_done
	RTE

tbl_except_p:
	dc.w	$e000,$e006,$e004,$e005         * the exception types ...
	dc.w	$e003,$e002,$e001,$e001

	**-----------------------------------------------------------------------------
fu_in_exc_ovfl_p:
	MOVE.W	#3,d0
	BRA	fu_in_exc_exit_p

fu_in_exc_unfl_p:
	MOVE.W	#4,d0
	BRA	fu_in_exc_exit_p

	**-----------------------------------------------------------------------------

fu_in_exc_exit_s_p:
	BTST	#mia7_bit,EXC_LV+SPCOND_FLG(a6)
	BEQ	fu_in_exc_exit_cont_p

	MOVE.W	((tbl_except_p).b,pc,d0.w*2),EXC_LV+FP_SRC+2(a6)

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src op

	UNLK	a6				* unravel stack frame

	* shift stack frame "up". who cares about <ea> field.

	MOVE.L	4(sp),4+12(sp)
	MOVE.L	0(sp),0+12(sp)
	ADD.L	#12,sp

	BTST	#7,(sp)				* is trace on?
	BNE	fu_trace_p			* yes

**$$	BRA	_fpsp_done			* exit to os
	RTE

	**-----------------------------------------------------------------------------
	*
	* The opclass two PACKED instruction that took an "Unimplemented Data Type"
	* exception was being traced. Make the "current" PC the FPIAR and put it in the
	* trace stack frame then jump to _real_trace().
	*
	*  UNSUPP FRAME	          TRACE FRAME
	* *****************	*****************
	* *      EA       *	*    Current
	* *               *	*      PC
	* *****************	*****************
	* *   $2 * $0dc   * 	* $2 *  $024
	* *****************	*****************
	* *     Next      *	*     Next
	* *      PC       *    	*      PC
	* *****************	*****************
	* *      SR       *	*      SR
	* *****************	*****************
fu_trace_p:
	MOVE.W	#$2024,6(sp)
	FMOVE.L	fpiar,8(sp)

	BRA	_real_trace



	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* I'm not sure at this point what FPSR bits are valid for this instruction.
	* so, since the emulation routines re-create them anyways, zero exception field.
	* fmove out doesn't affect ccodes.
fu_out_pack:
	AND.L	#$ffff00ff,EXC_LV+USER_FPSR(a6) * zero exception field
	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr

	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0
	BSR	load_fpn1

	* unlike other opclass 3, unimplemented data type exceptions, packed must be
	* able to detect all operand types.

	LEA	EXC_LV+FP_SRC(a6),a0
	BSR	set_tag_x		* tag the operand type
	CMP.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	fu_op2_p		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
fu_op2_p:
	MOVE.B	d0,EXC_LV+STAG(a6)	* save src optype tag

	CLR.l	d0
	MOVE.b	EXC_LV+FPCR_MODE(a6),d0	* fetch rnd mode/prec
	LEA	EXC_LV+FP_SRC(a6),a0	* pass ptr to src operand
	MOVE.L	(a6),EXC_LV+EXC_A6(a6)	* in case a6 changes

	BSR	fout			* call fmove out routine

	**-----------------------------------------------------------------------------
	* Exceptions in order of precedence:
	* 	BSUN	: no
	*	SNAN	: yes
	*	OPERR	: if ((k_factor > +17) || (dec. exp exceeds 3 digits))
	*	OVFL	: no
	*	UNFL	: no
	*	DZ	: no
	* 	INEX2	: yes
	*	INEX1	: no
	*
	* determine the highest priority exception(if any) set by the
	* emulation routine that has also been enabled by the user.

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions enabled
	BNE	fu_out_ena_p			* some are enabled
fu_out_exit_p:
	MOVE.L	EXC_LV+EXC_A6(a6),(a6)	* restore a6, saved above

	BTST	#5,EXC_SR(a6)		* user or supervisor?
	bne.b	fu_out_exit_s_p		* supervisor

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* update user a7
	MOVE.L	a0,usp

fu_out_exit_cont_p:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6		* unravel stack frame

	BTST	#7,(sp)		* is trace on?
	BNE	fu_trace_p	* yes

**$$	BRA	_fpsp_done	* exit to os
	RTE

	**-----------------------------------------------------------------------------
	* the exception occurred in supervisor mode. check to see if the
	* addressing mode was -(a7). if so, we'll need to shift the
	* stack frame "down".

fu_out_exit_s_p:
	BTST	#mda7_bit,EXC_LV+SPCOND_FLG(a6) * was ea mode -(a7)
	BEQ	fu_out_exit_cont_p		* no

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6	* restore frame pointer

	** move down exception stack frame by 3 LONGS - only needed fields
	** EA field dumped...

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)

	** now, copy the result to the proper place on the stack
	** SP is still pointing to the start of EXC frame ! so use
	** xx(sp) to get data !

	MOVE.L	FP_DST_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_DST_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_DST_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BTST	#7,(sp)          * Was this exception caused in Trace ?
	BNE	fu_trace_p

**$$	BRA	_fpsp_done
	RTE

	**-----------------------------------------------------------------------------
fu_out_ena_p:
	AND.B	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enabled
	BFFFO	d0{24:8},d0			* find highest priority exception
	BEQ	fu_out_exit_p

	MOVE.L	EXC_LV+EXC_A6(a6),(a6)	* restore a6, saved above

	**-----------------------------------------------------------------------------
	** an exception occurred and that exception was enabled.
	** the only exception possible on packed move out are INEX, OPERR, and SNAN.
fu_out_exc_p:
	CMP.B	#$1a,d0
	BGT	fu_inex_p2
	BEQ	fu_operr_p
fu_snan_p:
	BTST	#5,EXC_SR(a6)
	BNE	fu_snan_s_p

	MOVE.L	EXC_LV+EXC_A7(a6),a0
	MOVE.L	a0,usp

	BRA	fu_snan

fu_snan_s_p:
	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BNE	fu_snan

	**-----------------------------------------------------------------------------
	* the instruction was "fmove.p fpn,-(a7)" from supervisor mode.
	* the strategy is to move the exception frame "down" 12 bytes. then, we
	* can store the default result where the exception frame was.

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e006,EXC_LV+FP_SRC+2(a6) 	* set fsave status
	MOVE.W	#$30d8,EXC_VOFF(a6)		* vector offset = $d8

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src operand

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6				* restore frame pointer

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_EA(sp),EXC_SIZEOF+EXC_EA-12(sp)

	** now, we copy the default result to it's proper location
	** SP is still pointing to the start of EXC frame ! so use
	** xx(sp) to get data !

	MOVE.L	FP_DST_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_DST_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_DST_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BRA	_real_snan

	**-----------------------------------------------------------------------------
fu_operr_p:
	BTST	#$5,EXC_SR(a6)		* Supervisor mode ?
	BNE	fu_operr_p_s

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* retore a7, saved above, may modified
	MOVE.L	a0,usp

	BRA	fu_operr

	**-----------------------------------------------------------------------------
fu_operr_p_s:
	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BNE.W	fu_operr

	**-----------------------------------------------------------------------------
	* the instruction was "fmove.p fpn,-(a7)" from supervisor mode.
	* the strategy is to move the exception frame "down" 12 bytes. then, we
	* can store the default result where the exception frame was.

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e004,EXC_LV+FP_SRC+2(a6) 		* set fsave status
	MOVE.W	#$30d0,EXC_VOFF(a6)			* vector offset = $d0

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src operand

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6				* restore frame pointer

	** move down exception stack frame by 3 LONGS - only needed fields
	** EA field dumped...

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_EA(sp),EXC_SIZEOF+EXC_EA-12(sp)

	** now, we copy the default result to it's proper location

	MOVE.L	FP_DST_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_DST_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_DST_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BRA	_real_operr

	**-----------------------------------------------------------------------------
fu_inex_p2:
	BTST	#5,EXC_SR(a6)		* supervisor mode ?
	BNE	fu_inex_s_p2

	MOVE.L	EXC_LV+EXC_A7(a6),a0
	MOVE.L	a0,usp

	BRA	fu_inex

	**-----------------------------------------------------------------------------
fu_inex_s_p2:
	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BNE	fu_inex

	**-----------------------------------------------------------------------------
	* the instruction was "fmove.p fpn,-(a7)" from supervisor mode.
	* the strategy is to move the exception frame "down" 12 bytes. then, we
	* can store the default result where the exception frame was.

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0/fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	MOVE.W	#$e001,EXC_LV+FP_SRC+2(a6) 	* set fsave status
	MOVE.W	#$30c4,EXC_VOFF(a6) 		* vector offset = $c4

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore src operand

 ***@@@ HEAVY MAGIC !

	MOVE.L	(a6),a6				* restore frame pointer

	** move down exception stack frame by 3 LONGS - only needed fields

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+2+EXC_PC+2-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_EA(sp),EXC_SIZEOF+EXC_EA-12(sp)

	** now, we copy the default result to it's proper location
	** SP is still pointing to the start of EXC frame ! so use
	** xx(sp) to get data !

	MOVE.L	FP_DST_EX(sp),EXC_SIZEOF+EXC_SR+0(sp)
	MOVE.L	FP_DST_HI(sp),EXC_SIZEOF+EXC_SR+4(sp)
	MOVE.L	FP_DST_LO(sp),EXC_SIZEOF+EXC_SR+8(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp

	BRA	_real_inex







**-------------------------------------------------------------------------------------------------
**  funimp_skew() - skew operand in state frame as provided by hardware in some cases
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** if we're stuffing a source operand back into an fsave frame then we
** have to make sure that for single or double source operands that the
** format stuffed is as weird as the hardware usually makes it.
**
	xdef	funimp_skew
funimp_skew:
	BFEXTU	EXC_LV+EXC_EXTWORD(a6){3:3},d0 	* extract src specifier

	CMP.B	#%001,d0			* was src sgl?
	BEQ	funimp_skew_sgl			* yes

	CMP.B	#%101,d0			* was src dbl?
	BEQ	funimp_skew_dbl			* yes
	RTS

	**-----------------------------------------------------------------------------
funimp_skew_sgl:
	MOVE.W	EXC_LV+FP_SRC_EX(a6),d0		* fetch DENORM exponent
	ANDI.W	#$7fff,d0			* strip sign
	BEQ	funimp_skew_sgl_not

	CMP.W	#$3f80,d0
	BGT	funimp_skew_sgl_not

	NEG.W	d0				* make exponent negative
	ADDI.W	#$3f81,d0			* find amt to shift

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1		* fetch DENORM hi(man)
	LSR.L	d0,d1				* shift it
	BSET	#31,d1				* set j-bit
	MOVE.L	d1,EXC_LV+FP_SRC_HI(a6)		* insert new hi(man)

	ANDI.W	#$8000,EXC_LV+FP_SRC_EX(a6)	* clear old exponent
	ORI.W	#$3f80,EXC_LV+FP_SRC_EX(a6)	* insert new "skewed" exponent

funimp_skew_sgl_not:
	RTS

	**-----------------------------------------------------------------------------
funimp_skew_dbl:
	MOVE.W	EXC_LV+FP_SRC_EX(a6),d0		* fetch DENORM exponent
	ANDI.W	#$7fff,d0			* strip sign
	BEQ	funimp_skew_dbl_not

	CMP.W	#$3c00,d0
	BGT	funimp_skew_dbl_not

	TST.B	EXC_LV+FP_SRC_EX(a6)	* make "internal format"
	SMI.B	EXC_LV+FP_SRC+2(a6)

	MOVE.W	d0,EXC_LV+FP_SRC_EX(a6)	* insert exponent with cleared sign
	CLR.L	d0			* clear g,r,s

	LEA	EXC_LV+FP_SRC(a6),a0	* pass ptr to src op
	MOVE.W	#$3c01,d1		* pass denorm threshold
	BSR	dnrm_lp			* denorm it

	MOVE.W	#$3c00,d0		* new exponent
	TST.B	EXC_LV+FP_SRC+2(a6)	* is sign set?
	BEQ	fss_dbl_denorm_done	* no
	BSET	#15,d0			* set sign
fss_dbl_denorm_done:
	BSET	#7,EXC_LV+FP_SRC_HI(a6)	* set j-bit
	MOVE.W	d0,EXC_LV+FP_SRC_EX(a6)	* insert new exponent

funimp_skew_dbl_not:
	RTS










**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
** _fpsp_effadd(): 060FPSP entry point for FP "Unimplemented effective address" exception.
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*
*    This handler should be the first code executed upon taking the
*    FP Unimplemented Effective Address exception in an operating
*    system.
*
* XREF:
*       _imem_read_long() 	- read instruction longword
*
*       fix_skewed_ops() 	- adjust src operand in fsave frame
*       set_tag_x() 	- determine optype of src/dst operands
*       store_fpreg() 	- store opclass 0 or 2 result to FP regfile
*       unnorm_fix() 	- change UNNORM operands to NORM or ZERO
*       load_fpn2() 	- load dst operand from FP regfile
*       tbl_unsupp 	- add of table of emulation routines for opclass 0,2
*       decbin() 	- convert packed data to FP binary data
*
*       _real_fpu_disabled() 	- "callout" for "FPU disabled" exception
*       _real_access() 	- "callout" for access error exception
*       _mem_read() 	- read extended immediate operand from memory
*       _fpsp_done() 	- "callout" for exit; work all done
*       _real_trace() 	- "callout" for Trace enabled exception
*
*       fmovm_dynamic() 	- emulate dynamic fmovm instruction
*       fmovm_ctrl()            - emulate fmovm control instruction
*
* INPUT :
*         - The system stack contains the "Unimplemented <ea>" stk frame
*
* OUTPUT :
*         If access error:
*             - The system stack is changed to an access error stack frame
*         If FPU disabled:
*             - The system stack is changed to an FPU disabled stack frame
*         If Trace exception enabled:
*             - The system stack is changed to a Trace exception stack frame
*         Else: (normal case)
*             - None (correct result has been stored as appropriate)
*
* ALGORITHM :
*	This exception handles 3 types of operations:
*
* (1) FP Instructions using extended precision or packed immediate addressing mode.
* (2) The "fmovem.x" instruction w/ dynamic register specification.
* (3) The "fmovem.l" instruction w/ 2 or 3 control registers.
*
*	 For  immediate  data operations, the data is read in w/ a _mem_read() "callout", converted
* to  FP  binary  (if packed), and used as the source operand to the instruction specified by
* the  instruction word.  If no FP exception should be reported as a result of the emulation,
* then  the  result  is  stored  to  the  destination  register and the handler exits through
* _fpsp_done().
*
*  If  an  enabled exc has been signalled as a result of emulation, then an fsave state frame
* corresponding to the FP exception type must be entered into the 060 FPU before exiting.  In
* either  the  enabled or disabled cases, we must also check if a Trace exception is pending,
* in  which  case,  we  must  create a Trace exception stack frame from the current exception
* stack frame.  If no Trace is pending, we simply exit through _fpsp_done().
*
*  For  "fmovem.x",  call  the  routine  fmovm_dynamic()  which  will  decode and emulate the
* instruction.   No  FP exceptions can be pending as a result of this operation emulation.  A
* Trace exception can be pending, though, which means the current stack frame must be changed
* to a Trace stack frame and an exit made through _real_trace().
*
*  For  the  case  of  "fmovem.x Dn,-(a7)", where the offending instruction was executed from
* supervisor mode, this handler must store the FP register file values to the system stack by
* itself since fmovm_dynamic() can't handle this.  A normal exit is made through fpsp_done().
*
*  For "fmovem.l", fmovm_ctrl() is used to emulate the instruction.  Again, a Trace exception
* may be pending and an exit made through _real_trace().  Else, a normal exit is made through
* _fpsp_done().
*
*  Before  any  of  the above is attempted, it must be checked to see if the FPU is disabled.
* Since the "Unimp <ea>" exception is taken before the "FPU disabled" exception, but the "FPU
* disabled"  exception  has  higher  priority, we check the disabled bit in the PCR.  If set,
* then  we must create an 8 word "FPU disabled" exception stack frame from the current 4 word
* exception  stack frame.  This includes reproducing the effective address of the instruction
* to put on the new stack frame.
*
*  In  the process of all emulation work, if a _mem_read() "callout" returns a failing result
* indicating  an  access  error,  then  we  must  create an access error stack frame from the
* current   stack  frame.   This  information  includes  a  faulting  address  and  a  fault-
* status-longword.  These are created within this handler.
*
**---------------------------------------------------------------------------------------------

 	xdef	_fpsp_effadd
_fpsp_effadd:
	DBUG	10,"<UNIMP EFF ADDR>"

	**-----------------------------------------------------------------------------
	* This exception type takes priority over the "Line F Emulator"
	* exception. Therefore, the FPU could be disabled when entering here.
	* So, we must check to see if it's disabled and handle that case separately.

	MOVE.L	d0,-(sp)	* save d0
	MOVEC	PCR,d0		* load proc cr
	BTST	#1,d0		* is FPU disabled?
	BNE	iea_disabled	* yes
	MOVE.l	(sp)+,d0	* restore d0

	LINK	a6,#-EXC_SIZEOF	* init stack frame

	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	**** PC of instruction that took the exception is the PC in the frame

	MOVE.L	EXC_PC(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch the instruction words
	MOVE.L	d0,EXC_LV+EXC_OPWORD(a6)	* store OPWORD and EXTWORD

	**-----------------------------------------------------------------------------

	TST.W	d0		* is operation fmovem?
	BMI	iea_fmovm	* yes

	**-----------------------------------------------------------------------------
	*
	* here, we will have:
	* 	fabs	fdabs	fsabs	facos	fmod
	*	fadd	fdadd	fsadd	fasin	frem
	* 	fcmp	fatan	fscale
	*	fdiv	fddiv	fsdiv	fatanh	fsin
	*	fint	fcos	fsincos
	*	fintrz	fcosh	fsinh
	*	fmove	fdmove	fsmove	fetox	ftan
	* 	fmul	fdmul	fsmul	fetoxm1	ftanh
	*	fneg	fdneg	fsneg	fgetexp	ftentox
	*	fsgldiv	fgetman	ftwotox
	* 	fsglmul	flog10
	* 	fsqrt	flog2
	*	fsub	fdsub	fssub	flogn
	*	ftst	flognp1
	* which can all use f<op>.{x,p}
	* so, now it's immediate data extended precision AND PACKED FORMAT!
	*
	**-----------------------------------------------------------------------------
iea_op:
	ANDI.L	#$00ff00ff,EXC_LV+USER_FPSR(a6)

	BTST	#$a,d0			* is src fmt x or p?
	BNE	iea_op_pack		* packed


	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* pass: ptr to *<data>
	LEA	EXC_LV+FP_SRC(a6),a1		* pass: ptr to super addr
**@@	MOVE.L	#$c,d0				* pass: 12 bytes
**@@	BSR.L	_imem_read			* read extended immediate
	 MOVE.L	(a0),(a1)
	 MOVE.L	4(a0),4(a1)
	 MOVE.L	8(a0),8(a1)

**@@	tst.l	d1	* did ifetch fail?
**@@	bne.w	iea_iacc	* yes

	BRA  	iea_op_setsrc

	**-----------------------------------------------------------------------------
iea_op_pack:
	move.l	EXC_LV+EXC_EXTWPTR(a6),a0	* pass: ptr to *<data>
	lea	EXC_LV+FP_SRC(a6),a1		* pass: ptr to super dst
**@@	move.l	#$c,d0				* pass: 12 bytes
**@@	bsr.l	_imem_read			* read packed operand
	 MOVE.L	(a0),(a1)
	 MOVE.L	4(a0),4(a1)
	 MOVE.L	8(a0),8(a1)

**@@	tst.l	d1	* did ifetch fail?
**@@	bne.w	iea_iacc	* yes

	** The packed operand is an INF or a NAN if the exponent field is all ones.

	BFEXTU.W	EXC_LV+FP_SRC(a6){1:15},d0	* get exp
	CMP.W	#$7fff,d0			* INF or NAN?
	BEQ	iea_op_setsrc			* operand is an INF or NAN

	** The packed operand is a zero if the mantissa is all zero, else it's
	** a normal packed op.

	MOVE.B	EXC_LV+FP_SRC+3(a6),d0		* get byte 4
	ANDI.B	#$0f,d0				* clear all but last nybble
	BNE	iea_op_gp_not_spec		* not a zero

	TST.L	EXC_LV+FP_SRC_HI(a6)		* is lw 2 zero?
	BNE	iea_op_gp_not_spec		* not a zero

	TST.L	EXC_LV+FP_SRC_LO(a6)		* is lw 3 zero?
	BEQ	iea_op_setsrc			* operand is a ZERO

iea_op_gp_not_spec:
	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to packed op
	BSR	decbin			* convert to extended
	FMOVEM.X	fp0,EXC_LV+FP_SRC(a6)	* make this the srcop

	**-----------------------------------------------------------------------------
iea_op_setsrc:
	ADDI.L	#12,EXC_LV+EXC_EXTWPTR(a6)	* update extension word pointer

	** EXC_LV+FP_SRC now holds the src operand.

	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	set_tag_x		* tag the operand type
	MOVE.B	d0,EXC_LV+STAG(a6)	* could be ANYTHING!!!

	CMP.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	iea_op_getdst		* no

	BSR	unnorm_fix		* yes; convert to NORM/DENORM/ZERO
	MOVE.B	d0,EXC_LV+STAG(a6)	* set new optype tag

	**-----------------------------------------------------------------------------
iea_op_getdst:
	CLR.B	EXC_LV+STORE_FLG(a6)		* clear "store result" boolean

	BTST	#5,EXC_LV+EXC_CMDREG+1(a6)	* is operation monadic or dyadic?
	BEQ	iea_op_extract			* monadic

	BTST	#4,EXC_LV+EXC_CMDREG+1(a6)	* is operation fsincos,ftst,fcmp?
	BNE	iea_op_spec			* yes

	**-----------------------------------------------------------------------------
iea_op_loaddst:
	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* fetch dst regno
	BSR	load_fpn2			* load dst operand

	LEA	EXC_LV+FP_DST(a6),a0		* pass: ptr to dst op
	BSR	set_tag_x			* tag the operand type
	MOVE.B	d0,EXC_LV+DTAG(a6)		* could be ANYTHING!!!

	CMP.B	#UNNORM,d0			* is operand an UNNORM?
	BNE	iea_op_extract			* no

	BSR	unnorm_fix			* yes; convert to NORM/DENORM/ZERO
	MOVE.B	d0,EXC_LV+DTAG(a6)		* set new optype tag
	BRA	iea_op_extract

	**-----------------------------------------------------------------------------
	* the operation is fsincos, ftst, or fcmp. only fcmp is dyadic
iea_op_spec:
	BTST	#$3,EXC_LV+EXC_CMDREG+1(a6)	* is operation fsincos?
	BEQ	iea_op_extract			* yes

	* now, we're left with ftst and fcmp. so, first let's tag them so that they don't
	* store a result. then, only fcmp will branch back and pick up a dst operand.

	ST	EXC_LV+STORE_FLG(a6)		* don't store a final result
	BTST	#$1,EXC_LV+EXC_CMDREG+1(a6)	* is operation fcmp?
	BEQ	iea_op_loaddst			* yes

iea_op_extract:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass: rnd mode,prec
**@@	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1
**@@	ANDI.W	#$007f,d1			* extract extension
	BFEXTU	EXC_LV+EXC_CMDREG+1(a6){1:7},d1 * d1: extract extension
	FMOVE.L	#$0,fpcr
	FMOVE.L	#$0,fpsr
	LEA	EXC_LV+FP_SRC(a6),a0
	LEA	EXC_LV+FP_DST(a6),a1

	MOVE.L	((tbl_unsupp).w,pc,d1.w*4),d1 	* fetch routine addr
	JSR	((tbl_unsupp).w,pc,d1.l*1)

	**-----------------------------------------------------------------------------
	*
	* Exceptions in order of precedence:
	*	BSUN	: none
	*	SNAN	: all operations
	*	OPERR	: all reg-reg or mem-reg operations that can normally operr
	*	OVFL	: same as OPERR
	*	UNFL	: same as OPERR
	*	DZ	: same as OPERR
	*	INEX2	: same as OPERR
	*	INEX1	: all packed immediate operations
	*
	* we determine the highest priority exception(if any) set by the
	* emulation routine that has also been enabled by the user.

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions enabled
	BNE	iea_op_ena			* some are enabled

	**-----------------------------------------------------------------------------
	* now, we save the result, unless, of course, the operation was ftst or fcmp.
	* these don't save results.
iea_op_save:
	TST.B	EXC_LV+STORE_FLG(a6)		* does this op store a result?
	BNE	iea_op_exit1			* exit with no frestore

iea_op_store:
	BFEXTU.W	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* fetch dst regno
	BSR	store_fpreg			* store the result

iea_op_exit1:
	MOVE.L	EXC_PC(a6),EXC_LV+USER_FPIAR(a6)  * set FPIAR to "Current PC"
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),EXC_PC(a6) * set "Next PC" in exc frame

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	a6				* unravel the frame

	BTST	#7,(sp)				* is trace on?
	BNE	iea_op_trace			* yes

**$$	BRA	_fpsp_done			* exit to os
	RTE

	**-----------------------------------------------------------------------------
iea_op_ena:
	AND.B	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enable and set
	BFFFO	d0{24:8},d0			* find highest priority exception
	BNE	iea_op_exc			* at least one was set

	**-----------------------------------------------------------------------------
	* no exception occurred. now, did a disabled, exact overflow occur with inexact
	* enabled? if so, then we have to stuff an overflow frame into the FPU.

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* did overflow occur?
	BEQ	iea_op_save

iea_op_ovfl:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6) 	* is inexact enabled?
	BEQ	iea_op_store				* no
	BRA	iea_op_exc_ovfl				* yes

	**-----------------------------------------------------------------------------
	* an enabled exception occurred. we have to insert the exception type back into
	* the machine.
iea_op_exc:
	SUBI.L	#24,d0				* fix offset to be 0-8
	CMP.B	#6,d0				* is exception INEX?
	BNE	iea_op_exc_force		* no

	**-----------------------------------------------------------------------------
	* the enabled exception was inexact. so, if it occurs with an overflow
	* or underflow that was disabled, then we have to force an overflow or
	* underflow frame.

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* did overflow occur?
	BNE	iea_op_exc_ovfl				* yes

	BTST	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) 	* did underflow occur?
	BNE	iea_op_exc_unfl				* yes

iea_op_exc_force:
	MOVE.W	((tbl_iea_except).b,pc,d0.w*2),EXC_LV+FP_SRC+2(a6)
	BRA	iea_op_exit2				* exit with frestore

tbl_iea_except:
	dc.w	$e002, $e006, $e004, $e005
	dc.w	$e003, $e002, $e001, $e001

	**-----------------------------------------------------------------------------
iea_op_exc_ovfl:
	MOVE.W	#$e005,EXC_LV+FP_SRC+2(a6)
	BRA	iea_op_exit2

iea_op_exc_unfl:
	MOVE.W	#$e003,EXC_LV+FP_SRC+2(a6)

	**-----------------------------------------------------------------------------
iea_op_exit2:
	MOVE.L	EXC_PC(a6),EXC_LV+USER_FPIAR(a6)   * set FPIAR to "Current PC"
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),EXC_PC(a6)  * set "Next PC" in exc frame

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE 	EXC_LV+FP_SRC(a6)		* restore exceptional state

	UNLK	a6				* unravel the frame

	BTST	#$7,(sp)			* is trace on?
	BNE	iea_op_trace			* yes

**$$	BRA	_fpsp_done			* exit to os
	RTE

	**-----------------------------------------------------------------------------
	*
	* The opclass two instruction that took an "Unimplemented Effective Address"
	* exception was being traced. Make the "current" PC the FPIAR and put it in
	* the trace stack frame then jump to _real_trace().
	*
	*	 UNIMP EA FRAME	           TRACE FRAME
	*	*****************	*****************
	*	* $0 *  $0f0	*	*    Current
	*	*****************	*      PC
	*	*    Current	*	*****************
	*	*      PC	*	* $2 *  $024
	*	*****************	*****************
	*	*      SR	*	*     Next
	*	*****************	*      PC
	*                                       *****************
	*                                       *      SR
	*                                       *****************
iea_op_trace:
	MOVE.L	(sp),-(sp)		* shift stack frame "down"
	MOVE.W	8(sp),4(sp)
	MOVE.W	#$2024,6(sp)		* stk fmt = $2; voff = $024
	FMOVE.L	fpiar,8(sp)		* "Current PC" is in FPIAR

	BRA	_real_trace

**-------------------------------------------------------------------------------------------------

iea_fmovm:
	BTST	#14,d0			* ctrl or data reg
	BEQ	iea_fmovm_ctrl

iea_fmovm_data:
	BTST	#$5,EXC_SR(a6)		* user or supervisor mode
	BNE	iea_fmovm_data_s

iea_fmovm_data_u:
	MOVE.L	usp,a0
	MOVE.L	a0,EXC_LV+EXC_A7(a6)	* store current a7

	BSR	fmovm_dynamic		* do dynamic fmovm

	MOVE.L	EXC_LV+EXC_A7(a6),a0	* load possibly new a7
	MOVE.l	a0,usp			* update usp
	BRA	iea_fmovm_exit

	**-----------------------------------------------------------------------------
iea_fmovm_data_s:
	CLR.B	EXC_LV+SPCOND_FLG(a6)
	LEA	EXC_VOFF+2(a6),a0
	MOVE.L	a0,EXC_LV+EXC_A7(a6)
	BSR	fmovm_dynamic		* do dynamic fmovm

	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)
	BEQ	iea_fmovm_data_predec

	CMP.B	#mia7_flg,EXC_LV+SPCOND_FLG(a6)
	BNE	iea_fmovm_exit

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* right now, d0 = the size.
	* the data has been fetched from the supervisor stack, but we have not
	* incremented the stack pointer by the appropriate number of bytes.
	* do it here.
	*
iea_fmovm_data_postinc:
	BTST	#$7,EXC_SR(a6)
	BNE	iea_fmovm_data_pi_trace

	MOVE.W	EXC_SR(a6),(EXC_SR,a6,d0)
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),(EXC_PC,a6,d0)
	MOVE.W	#$00f0,(EXC_VOFF,a6,d0)

	LEA	(EXC_SR,a6,d0),a0
	MOVE.L	a0,EXC_SR(a6)

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	UNLK	a6
	MOVE.L	(sp)+,sp
**$$	BRA	_fpsp_done
	RTE

	**-----------------------------------------------------------------------------

iea_fmovm_data_pi_trace:
	MOVE.W	EXC_SR(a6),(EXC_SR-4,a6,d0)
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),(EXC_PC-4,a6,d0)
	MOVE.W	#$2024,(EXC_VOFF-4,a6,d0)
	MOVE.L	EXC_PC(a6),(EXC_VOFF+2-4,a6,d0)

	LEA	(EXC_SR-4,a6,d0),a0
	MOVE.L	a0,EXC_SR(a6)

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	UNLK	A6
	MOVE.L	(sp)+,sp
	BRA	_real_trace

	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	**-----------------------------------------------------------------------------
	* right now, d1 = size and d0 = the strg.

iea_fmovm_data_predec:

	MOVE.B	d1,EXC_VOFF(a6)			* store strg
	MOVE.B	d0,EXC_VOFF+1(a6)		* store size

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	MOVE.L	(a6),-(sp)		* make a copy of a6
	MOVE.L	d0,-(sp)		* save d0
	MOVE.L	d1,-(sp)		* save d1

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),-(sp)	* make a copy of Next PC

	CLR.L	d0
	MOVE.B	EXC_VOFF+1(a6),d0		* fetch size
	NEG.L	d0				* get negative of size

	BTST	#$7,EXC_SR(a6)		* is trace enabled?
	BEQ	iea_fmovm_data_p2

	MOVE.W	EXC_SR(a6),(EXC_SR-4,a6,d0)
	MOVE.L	EXC_PC(a6),(EXC_VOFF+2-4,a6,d0)
	MOVE.L	(sp)+,(EXC_PC-4,a6,d0)
	MOVE.W	#$2024,(EXC_VOFF-4,a6,d0)

	PEA	(a6,d0)			* create final sp
	BRA	iea_fmovm_data_p3

	**-----------------------------------------------------------------------------
iea_fmovm_data_p2:
	MOVE.W	EXC_SR(a6),(EXC_SR,a6,d0)
	MOVE.L	(sp)+,(EXC_PC,a6,d0)
	MOVE.W	#$00f0,(EXC_VOFF,a6,d0)

	PEA	($4,a6,d0)		* create final sp

iea_fmovm_data_p3:
	CLR.L	d1
	MOVE.B	EXC_VOFF(a6),d1		* fetch strg

	TST.B	d1
	BPL	fm_1
	FMOVEM.X	fp0,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_1:
	LSL.B	#1,d1
	BPL	fm_2
	FMOVEM.X	fp1,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_2:
	LSL.B	#1,d1
	BPL	fm_3
	FMOVEM.X	fp2,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_3:
	LSL.B	#1,d1
	BPL	fm_4
	FMOVEM.X	fp3,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_4:
	LSL.B	#1,d1
	BPL	fm_5
	FMOVEM.X	fp4,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_5:
	LSL.B	#1,d1
	BPL	fm_6
	FMOVEM.X	fp5,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_6:
	LSL.B	#1,d1
	BPL	fm_7
	FMOVEM.X	fp6,(4+8,a6,d0)
	ADDI.L	#12,d0
fm_7:
	LSL.B	#1,d1
	BPL	fm_end
	FMOVEM.X	fp7,(4+8,a6,d0)
fm_end:
	MOVE.L	4(sp),d1
	MOVE.L	8(sp),d0
	MOVE.L	12(sp),a6
	MOVE.L	(sp)+,sp

	BTST	#$7,(sp)		* is trace enabled?
	BEQ	_fpsp_done
	BRA	_real_trace

                **-----------------------------------------------------------------------------
                **-----------------------------------------------------------------------------
                **-----------------------------------------------------------------------------

iea_fmovm_ctrl:
	BSR	fmovm_ctrl		* load ctrl regs

iea_fmovm_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	BTST	#$7,EXC_SR(a6)		* is trace on?
	BNE	iea_fmovm_trace		* yes

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),EXC_PC(a6) 	* set Next PC

	UNLK	a6			* unravel the frame

**$$	BRA	_fpsp_done		* exit to os
	RTE

                **-----------------------------------------------------------------------------
	*
	* The control reg instruction that took an "Unimplemented Effective Address"
	* exception was being traced. The "Current PC" for the trace frame is the
	* PC stacked for Unimp EA. The "Next PC" is in EXC_LV+EXC_EXTWPTR.
	* After fixing the stack frame, jump to _real_trace().
	*
	*	 UNIMP EA FRAME	   TRACE FRAME
	*	*****************	*****************
	*	* $0 *  $0f0	*	*    Current
	*	*****************	*      PC
	*	*    Current	*	*****************
	*	*      PC	*	* $2 *  $024
	*	*****************	*****************
	*	*      SR	*	*     Next
	*	*****************	*      PC
	*                                       *****************
	*                                       *      SR
	*                                       *****************
	*
	* this ain't a pretty solution, but it works:
	* -restore a6 (not with unlk)
	* -shift stack frame down over where old a6 used to be
	* -add -EXC_LV to stack pointer

iea_fmovm_trace:
	MOVE.L	(a6),a6			* restore frame pointer

	MOVE.W	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+0(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC(sp),EXC_SIZEOF+8(sp)

	MOVE.L	EXC_EXTWPTR(sp),EXC_SIZEOF+2(sp)
	MOVE.W	#$2024,EXC_SIZEOF+6(sp) 	* stk fmt = $2; voff = $024

	ADD.L	#EXC_SIZEOF,sp		* clear stack frame

	BRA	_real_trace

                **-----------------------------------------------------------------------------
                **-----------------------------------------------------------------------------
	* The FPU is disabled and so we should really have taken the "Line
	* F Emulator" exception. So, here we create an 8-word stack frame
	* from our 4-word stack frame. This means we must calculate the length
	* the the faulting instruction to get the "next PC". This is trivial for
	* immediate operands but requires some extra work for fmovm dynamic
	* which can use most addressing modes.
iea_disabled:
	MOVE.l	(sp)+,d0		* restore d0

	LINK	a6,#-EXC_SIZEOF		* init stack frame

	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1

	** PC of instruction that took the exception is the PC in the frame

	MOVE.L	EXC_PC(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch the instruction words
	MOVE.L	d0,EXC_LV+EXC_OPWORD(a6)	* store OPWORD and EXTWORD

	TST.W	d0				* is instr fmovm?
	BMI	iea_dis_fmovm			* yes

                **-----------------------------------------------------------------------------
	* instruction is using an extended precision immediate operand. therefore,
	* the total instruction length is 16 bytes.
iea_dis_immed:
	MOVE.L	#$10,d0			* 16 bytes of instruction
	BRA	iea_dis_cont
iea_dis_fmovm:
	BTST	#$e,d0			* is instr fmovm ctrl
	BNE	iea_dis_fmovm_data	* no

	** the instruction is a fmovem.l with 2 or 3 registers.

	BFEXTU	d0{19:3},d1
	MOVE.L	#12,d0
	CMP.B	#7,d1			* move all regs?
	BNE	iea_dis_cont

	ADDQ.L	#4,d0
	BRA	iea_dis_cont

                **-----------------------------------------------------------------------------
	* the instruction is an fmovem.x dynamic which can use many addressing
	* modes and thus can have several different total instruction lengths.
	* call fmovm_calc_ea which will go through the ea calc process and,
	* as a by-product, will tell us how dc.l the instruction is.

iea_dis_fmovm_data:
	CLR.L	d0
	BSR	fmovm_calc_ea

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),d0
	SUB.L	EXC_PC(a6),d0

                **-----------------------------------------------------------------------------
iea_dis_cont:
	MOVE.W	d0,EXC_VOFF(a6)		* store stack shift value

	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	UNLK	A6

                **-----------------------------------------------------------------------------
	* here, we actually create the 8-word frame from the 4-word frame,
	* with the "next PC" as additional info.
	* the <ea> field is let as undefined.

	SUBQ.L	#8,sp			* make room for new stack
	MOVE.L	d0,-(sp)		* save d0
	MOVE.W	12(sp),4(sp)		* move SR
	MOVE.L	14(sp),6(sp)		* move Current PC
	CLR.L	d0
	MOVE.W	18(sp),d0
	MOVE.L	6(sp),16(sp)		* move Current PC
	ADD.L	d0,6(sp)		* make Next PC
	MOVE.W	#$402c,10(sp)		* insert offset,frame format
	MOVE.L	(sp)+,d0		* restore d0

	BRA	_real_fpu_disabled

                **-----------------------------------------------------------------------------
                **-----------------------------------------------------------------------------

	*** wird irgendwo in core.asm aufgerufen !!! @@@

	XDEF	iea_iacc
iea_iacc:
	movec	pcr,d0
	btst	#$1,d0
	bne.b	iea_iacc_cont
	fmovem.l	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar * restore ctrl regs
	fmovem.x	EXC_LV+EXC_FPREGS(a6),fp0-fp1	* restore fp0-fp1 on stack
iea_iacc_cont:
	movem.l	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	unlk	a6

	subq.w	#$8,sp	* make stack frame bigger
	move.l	$8(sp),(sp)	* store SR,hi(PC)
	move.w	$c(sp),$4(sp)	* store lo(PC)
	move.w	#$4008,$6(sp)	* store voff
	move.l	$2(sp),$8(sp)	* store ea
	move.l	#$09428001,$c(sp)	* store fslw

iea_acc_done:
	btst	#$5,(sp)	* user or supervisor mode?
	beq.b	iea_acc_done2	* user
	bset	#$2,$d(sp)	* set supervisor TM bit

iea_acc_done2:
	BRA	_real_access

	XDEF	iea_dacc
iea_dacc:
	lea	EXC_LV(a6),sp

	movec	pcr,d1
	btst	#$1,d1
	bne.b	iea_dacc_cont
	fmovem.x	EXC_LV+EXC_FPREGS(a6),fp0-fp1	* restore fp0-fp1 on stack
	fmovem.l	EXC_LV-EXC_LV+USER_FPCR(sp),fpcr/fpsr/fpiar * restore ctrl regs
iea_dacc_cont:
	move.l	(a6),a6

	move.l	$4+-EXC_LV(sp),-$8+$4-EXC_LV(sp)
	move.w	$8+-EXC_LV(sp),-$8+$8-EXC_LV(sp)
	move.w	#$4008,-$8+$a-EXC_LV(sp)
	move.l	a0,-$8+$c-EXC_LV(sp)
	move.w	d0,-$8+$10-EXC_LV(sp)
	move.w	#$0001,-$8+$12-EXC_LV(sp)

	movem.l	EXC_LV-EXC_LV+EXC_DREGS(sp),d0-d1/a0-a1 * restore d0-d1/a0-a1
	add.w	#-EXC_LV-$4,sp

	bra.b	iea_acc_done










**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	_fpsp_operr(): 060FPSP entry point for FP Operr exception.
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*
*	This handler should be the first code executed upon taking the
* 	FP Operand Error exception in an operating system.
*
* XREF:
*	_imem_read_long() - read instruction longword
*	fix_skewed_ops() - adjust src operand in fsave frame
*	_real_operr() - "callout" to operating system operr handler
*	_dmem_write_{byte,word,dc.l}() - store data to mem (opclass 3)
*	store_dreg_{b,w,l}() - store data to data regfile (opclass 3)
*	facc_out_{b,w,l}() - store to memory took access error (opcl 3)
*
* INPUT:
*	- The system stack contains the FP Operr exception frame
*	- The fsave frame contains the source operand
*
* OUTPUT:
*	No access error:
*	- The system stack is unchanged
*	- The fsave frame contains the adjusted src op for opclass 0,2
*
* ALGORITHM ***********************************************************
*
* In  a  system  where  the  FP Operr exception is enabled, the goal is to get to the handler
* specified  at  _real_operr().  But, on the 060, for opclass zero and two instruction taking
* this  exception,  the  input operand in the fsave frame may be incorrect for some cases and
* needs  to be corrected.  This handler calls fix_skewed_ops() to do just this and then exits
* through _real_operr().
*
* For opclass 3 instructions, the 060 doesn't store the default operr result out to memory or
* data register file as it should.  This code must emulate the move out before finally
* exiting through _real_inex().  The move out, if to memory, is performed using _mem_write()
* "callout" routines that may return a failing result.
*
* In  this  special  case,  the  handler must exit through facc_out() which creates an access
* error stack frame from the current operr stack frame.
*
**-------------------------------------------------------------------------------------------------


	xdef	_fpsp_operr
_fpsp_operr:
	DBUG	10,"<OPERR>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* grab the "busy" frame

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0
	MOVE.L	(d0),EXC_LV+EXC_OPWORD(a6)	* fetch the instruction words

	**--------------------------------------------------------------------------------

	BTST	#13,d0			* is instr an fmove out?
	BNE	foperr_out		* fmove out

	**--------------------------------------------------------------------------------
	* here, we simply see if the operand in the fsave frame needs to be "unskewed".
	* this would be the case for opclass two operations with a source infinity or
	* denorm operand in the sgl or dbl format. NANs also become skewed, but can't
	* cause an operr so we don't need to check for them here.

	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	fix_skewed_ops		* fix src op

foperr_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)

	UNLK	a6
	BRA	_real_operr

	**--------------------------------------------------------------------------------
	*
	* the hardware does not save the default result to memory on enabled operand error
	* exceptions.   we  do  this here before passing control to the user operand error
	* handler.
	*
	* byte,  word,  and  dc.l destination format operations can pass through here.  we
	* simply need to test the sign of the src operand and save the appropriate minimum
	* or  maximum  integer value to the effective address as pointed to by the stacked
	* effective address.
	*
	* although packed opclass three operations can take operand error exceptions, they
	* won't  pass  through  here  since  they are caught first by the unsupported data
	* format  exception handler.  that handler sends them directly to _real_operr() if
	* necessary.
	*
	**--------------------------------------------------------------------------------
foperr_out:
	DBUG	15,"<OPERR:out>"

	MOVE.W	EXC_LV+FP_SRC_EX(a6),d1	* fetch exponent
	ANDI.W	#$7fff,d1
	CMP.W	#$7fff,d1
	BNE	foperr_out_not_qnan

	* the operand is either an infinity or a QNAN.

	TST.L	EXC_LV+FP_SRC_LO(a6)
	BNE	foperr_out_qnan

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1
	ANDI.L	#$7fffffff,d1
	BEQ	foperr_out_not_qnan

	**--------------------------------------------------------------------------------
foperr_out_qnan:
	MOVE.L	EXC_LV+FP_SRC_HI(a6),EXC_LV+L_SCR1(a6)
	BRA	foperr_out_jmp

foperr_out_not_qnan:
	MOVE.L	#$7fffffff,d1
	TST.B	EXC_LV+FP_SRC_EX(a6)
	BPL	foperr_out_not_qnan2
	ADDQ.L	#$1,d1
foperr_out_not_qnan2:
	MOVE.L	d1,EXC_LV+L_SCR1(a6)

	**--------------------------------------------------------------------------------
foperr_out_jmp:
	BFEXTU	d0{19:3},d0			* extract dst format field
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract <ea> mode,reg
	MOVE.W	((tbl_operr).b,pc,d0.w*2),a0
	JMP	((tbl_operr).b,pc,a0)

tbl_operr:
	dc.w	foperr_out_l - tbl_operr 	* dc.l word integer
	dc.w	tbl_operr    - tbl_operr 	* sgl prec shouldn't happen
	dc.w	tbl_operr    - tbl_operr 	* ext prec shouldn't happen
	dc.w	foperr_exit  - tbl_operr 	* packed won't enter here
	dc.w	foperr_out_w - tbl_operr 	* word integer
	dc.w	tbl_operr    - tbl_operr 	* dbl prec shouldn't happen
	dc.w	foperr_out_b - tbl_operr 	* byte integer
	dc.w	tbl_operr    - tbl_operr 	* packed won't enter here

	**--------------------------------------------------------------------------------
foperr_out_b:
	MOVE.B	EXC_LV+L_SCR1(a6),d0	* load positive default result
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	foperr_out_b_save_dn	* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.B          d0,(a0)         	* write the default result

	BRA	foperr_exit

	**--------------------------------------------------------------------------------
foperr_out_b_save_dn:
	ANDI.W	#$0007,d1
	BSR	store_dreg_b		* store result to regfile
	BRA	foperr_exit

	**--------------------------------------------------------------------------------
foperr_out_w:
	MOVE.W	EXC_LV+L_SCR1(a6),d0	* load positive default result
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	foperr_out_w_save_dn	* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.W	d0,(a0)

	BRA	foperr_exit

	**--------------------------------------------------------------------------------
foperr_out_w_save_dn:
	ANDI.W	#$0007,d1
	BSR	store_dreg_w		* store result to regfile
	BRA	foperr_exit

	**--------------------------------------------------------------------------------
foperr_out_l:
	MOVE.L	EXC_LV+L_SCR1(a6),d0	* load positive default result
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	foperr_out_l_save_dn	* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.L	d0,(a0)

	BRA	foperr_exit

	**--------------------------------------------------------------------------------
foperr_out_l_save_dn:
	ANDI.W	#$0007,d1
	BSR	store_dreg_l		* store result to regfile
	BRA	foperr_exit













**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**   _fpsp_snan(): 060FPSP entry point for FP SNAN exception.
**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*
*	This handler should be the first code executed upon taking the
* 	FP Signalling NAN exception in an operating system.
*
* XREF :
* 	_imem_read_long() 		- read instruction longword
*	fix_skewed_ops() 		- adjust src operand in fsave frame
*	_real_snan() 			- "callout" to operating system SNAN handler
*	_dmem_write_{byte,word,dc.l}() 	- store data to mem (opclass 3)
*	store_dreg_{b,w,l}() 		- store data to data regfile (opclass 3)
*	facc_out_{b,w,l,d,x}()		- store to mem took acc error (opcl 3)
*	_calc_ea_fout() 		- fix An if <ea> is -() or ()+; also get <ea>
*
* INPUT :
*	- The system stack contains the FP SNAN exception frame
*	- The fsave frame contains the source operand
*
* OUTPUT :
*	No access error:
*	- The system stack is unchanged
*	- The fsave frame contains the adjusted src op for opclass 0,2
*
* ALGORITHM :
*
*  In  a  system where the FP SNAN exception is enabled, the goal is to get to the
* handler  specified  at  _real_snan().
*
*  But,  on  the 060, for opclass zero and two instructions taking this exception,
* the  input  operand in the fsave frame may be incorrect for some cases and needs
* to  be  corrected.  This handler calls fix_skewed_ops() to do just this and then
* exits through _real_snan().
*
*  For  opclass  3 instructions, the 060 doesn't store the default SNAN result out
* to  memory  or data register file as it should.  This code must emulate the move
* out before finally exiting through _real_snan().  The move out, if to memory, is
* performed  using  _mem_write()  "callout"  routines  that  may  return a failing
* result.   In  this  special case, the handler must exit through facc_out() which
* creates an access error stack frame from the current SNAN stack frame.
*
*  For  the  case of an extended precision opclass 3 instruction, if the effective
* addressing  mode  was  -() or ()+, then the address register must get updated by
* calling  _calc_ea_fout().   If the <ea> was -(a7) from supervisor mode, then the
* exception  frame currently on the system stack must be carefully moved "down" to
* make room for the operand being moved.

**-------------------------------------------------------------------------------------------------

	xdef	_fpsp_snan
_fpsp_snan:
	DBUG	10,"<SNAN EXC>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* grab the "busy" frame

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0
	MOVE.L	d0,EXC_LV+EXC_OPWORD(a6)	* fetch the instruction words

	**-------------------------------------------------------------------------------

	BTST	#13,d0		* is instr an fmove out?
	BNE	fsnan_out	* fmove out


	**-------------------------------------------------------------------------------
	* here, we simply see if the operand in the fsave frame needs to be "unskewed".
	* this would be the case for opclass two operations with a source infinity or
	* denorm operand in the sgl or dbl format. NANs also become skewed and must be
	* fixed here.

	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	fix_skewed_ops		* fix src op

fsnan_exit:
	DBUG	15,"<SNAN EXC:exit>"

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)

	UNLK	a6
	BRA	_real_snan

	**-------------------------------------------------------------------------------
	*  The  hardware  does  not  save  the  default  result  to memory on enabled snan
	* exceptions.  we do this here before passing control to the user snan handler.
	*
	* byte,  word,  dc.l,  and  packed  destination format operations can pass through
	* here.   since  packed  format  operations already were handled by fpsp_unsupp(),
	* then we need to do nothing else for them here.
	*
	* for byte, word, and dc.l, we simply need to test the sign of the src operand and
	* save  the  appropriate minimum or maximum integer value to the effective address
	* as pointed to by the stacked effective address.
fsnan_out:
	DBUG	10,"<SNAN EXC:out>"

	BFEXTU	d0{19:3},d0			* extract dst format field
	MOVE.B	EXC_LV+EXC_OPWORD+1(a6),d1	* extract <ea> mode,reg
	MOVE.W	((tbl_snan).b,pc,d0.w*2),a0
	JMP	((tbl_snan).b,pc,a0)

tbl_snan:
	dc.w	fsnan_out_l - tbl_snan * dc.l word integer
	dc.w	fsnan_out_s - tbl_snan * sgl prec shouldn't happen
	dc.w	fsnan_out_x - tbl_snan * ext prec shouldn't happen
	dc.w	tbl_snan    - tbl_snan * packed needs no help
	dc.w	fsnan_out_w - tbl_snan * word integer
	dc.w	fsnan_out_d - tbl_snan * dbl prec shouldn't happen
	dc.w	fsnan_out_b - tbl_snan * byte integer
	dc.w	tbl_snan    - tbl_snan * packed needs no help

	**-------------------------------------------------------------------------------
fsnan_out_b:
	DBUG	15,"<SNAN EXC:out_b>"

	MOVE.B	EXC_LV+FP_SRC_HI(a6),d0	* load upper byte of SNAN
	BSET	#6,d0			* set SNAN bit
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	fsnan_out_b_dn		* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.B	d0,(a0)

	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_b_dn:
	DBUG	15,"<SNAN EXC:out_b_dn>"

	ANDI.W	#$0007,d1
	BSR	store_dreg_b		* store result to regfile
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_w:
	DBUG	15,"<SNAN EXC:out_w>"

	MOVE.W	EXC_LV+FP_SRC_HI(a6),d0	* load upper word of SNAN
	BSET	#14,d0			* set SNAN bit
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	fsnan_out_w_dn		* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.W	D0,(a0)			* write the default result
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_w_dn:
	DBUG	15,"<SNAN EXC:out_w_dn>"

	ANDI.W	#$0007,d1
	BSR	store_dreg_w		* store result to regfile
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_l:
	DBUG	15,"<SNAN EXC:out_l>"

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d0	* load upper longword of SNAN
	BSET	#30,d0			* set SNAN bit
	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	fsnan_out_l_dn		* yes

	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
	MOVE.L          d0,(a0)			* write the default result
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_l_dn:
	DBUG	15,"<SNAN EXC:out_l_dn>"

	ANDI.W	#$0007,d1
	BSR	store_dreg_l		* store result to regfile
	BRA	fsnan_exit


	**-------------------------------------------------------------------------------
fsnan_out_s:
	DBUG	15,"<SNAN EXC:out_s>"

	CMP.B	#7,d1			* is <ea> mode a data reg?
	BLE	fsnan_out_d_dn		* yes

	MOVE.L	EXC_LV+FP_SRC_EX(a6),d0	* fetch SNAN sign
	ANDI.L	#$80000000,d0		* keep sign
	ORI.L	#$7fc00000,d0		* insert new exponent,SNAN bit

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1	* load mantissa
	LSR.L	#$8,d1			* shift mantissa for sgl
	OR.L	d1,d0			* create sgl SNAN
	MOVE.L	EXC_EA(a6),a0		* pass: <ea> of default result
                MOVE.L	d0,(a0)                 * write the default result
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_d_dn:
	DBUG	15,"<SNAN EXC:out_d_dn>"

	MOVE.L	EXC_LV+FP_SRC_EX(a6),d0	* fetch SNAN sign
	ANDI.L	#$80000000,d0		* keep sign
	ORI.L	#$7fc00000,d0		* insert new exponent,SNAN bit
	MOVE.L	d1,-(sp)

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1	* load mantissa
	LSR.L	#$8,d1			* shift mantissa for sgl
	OR.L	d1,d0			* create sgl SNAN
	MOVE.L	(sp)+,d1

	ANDI.W	#$0007,d1
	BSR	store_dreg_l		* store result to regfile
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
fsnan_out_d:
	DBUG	15,"<SNAN EXC:out_d>"

	MOVE.L	EXC_LV+FP_SRC_EX(a6),d0		* fetch SNAN sign
	ANDI.L	#$80000000,d0			* keep sign
	ORI.L	#$7ff80000,d0			* insert new exponent,SNAN bit

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1		* load hi mantissa
	MOVE.L	d0,EXC_LV+FP_SCR0_EX(a6)	* store to temp space

	MOVE.L	#11,d0				* load shift amt
	LSR.L	d0,d1
	OR.L	d1,EXC_LV+FP_SCR0_EX(a6)	* create dbl hi

	MOVE.L	EXC_LV+FP_SRC_HI(a6),d1		* load hi mantissa
	ANDI.L	#$000007ff,d1
	ROR.L	d0,d1
	MOVE.L	d1,EXC_LV+FP_SCR0_HI(a6)	* store to temp space

	MOVE.L	EXC_LV+FP_SRC_LO(a6),d1		* load lo mantissa
	LSR.L	d0,d1
	OR.L	d1,EXC_LV+FP_SCR0_HI(a6)	* create dbl lo

	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to operand
	MOVE.L	EXC_EA(a6),a1			* pass: dst addr
**$$$	MOVEQ.L	#$8,d0				* pass: size of 8 bytes
	MOVE.L	(a0),(a1) 			* write eight byte
	MOVE.L	4(a0),4(a1)

**$$$	BSR	_dmem_write	* write the default result
**$$$	tst.l	d1	* did dstore fail?
**$$$	bne.l	facc_out_d	* yes

	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------
	* for extended precision, if the addressing mode is pre-decrement or
	* post-increment, then the address register did not get updated.
	* in addition, for pre-decrement, the stacked <ea> is incorrect.

fsnan_out_x:
	DBUG	15,"<SNAN EXC:out_x>"

	CLR.B	EXC_LV+SPCOND_FLG(a6)		* clear special case flag

	MOVE.W	EXC_LV+FP_SRC_EX(a6),EXC_LV+FP_SCR0_EX(a6)
	CLR.W	EXC_LV+FP_SCR0+2(a6)

	MOVE.l	EXC_LV+FP_SRC_HI(a6),d0
	BSET	#30,d0
	MOVE.L	d0,EXC_LV+FP_SCR0_HI(a6)

	MOVE.L	EXC_LV+FP_SRC_LO(a6),EXC_LV+FP_SCR0_LO(a6)

	BTST	#5,EXC_SR(a6)		* supervisor mode exception?
	BNE	fsnan_out_x_s		* yes

	MOVE.L	usp,a0			* fetch user stack pointer
	MOVE.L	a0,EXC_LV+EXC_A7(a6)	* save on stack for calc_ea()
	MOVE.L	(a6),EXC_LV+EXC_A6(a6)

	BSR	_calc_ea_fout		* find the correct ea,update An
	MOVE.L	a0,a1
	MOVE.L	a0,EXC_EA(a6)		* stack correct <ea>

	MOVE.L	EXC_LV+EXC_A7(a6),a0
	MOVE.L	a0,usp			* restore user stack pointer

	MOVE.L	EXC_LV+EXC_A6(a6),(a6)

	**-------------------------------------------------------------------------------
fsnan_out_x_save:
	DBUG	15,"<SNAN EXC:out_x_save>"

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: ptr to operand
**$$$	MOVEQ	#12,d0			* pass: size of extended

	MOVE.L	(a0),(a1)
	MOVE.L	4(a0),4(a1)
	MOVE.L	8(a0),8(a1)

**$$$	bsr.l	_dmem_write		* write the default result
**$$$	tst.l	d1			* did dstore fail?
**$$$	bne.l	facc_out_x		* yes
	BRA	fsnan_exit

	**-------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------
fsnan_out_x_s:
	DBUG	15,"<SNAN EXC:out_x_s>"

	MOVE.L	(a6),EXC_LV+EXC_A6(a6)

	BSR	_calc_ea_fout			* find the correct ea,update An
	MOVE.L	a0,a1
	MOVE.L	a0,EXC_EA(a6)			* stack correct <ea>

	MOVE.L	EXC_LV+EXC_A6(a6),(a6)

	CMP.B	#mda7_flg,EXC_LV+SPCOND_FLG(a6)	* is <ea> mode -(a7)?
	BNE	fsnan_out_x_save		* no

	**-------------------------------------------------------------------------------
	* the operation was "fmove.x SNAN,-(a7)" from supervisor mode.

	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)

	MOVE.L	EXC_LV+EXC_A6(a6),a6		* restore frame pointer

**$$$ HEAVY MAGIC

	MOVE.L	EXC_SIZEOF+EXC_SR(sp),EXC_SIZEOF+EXC_SR-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_PC+2(sp),EXC_SIZEOF+EXC_PC+2-12(sp)
	MOVE.L	EXC_SIZEOF+EXC_EA(sp),EXC_SIZEOF+EXC_EA-12(sp)

	MOVE.L	EXC_SIZEOF+FP_SCR0_EX(sp),EXC_SIZEOF+EXC_SR(sp)
	MOVE.L	EXC_SIZEOF+FP_SCR0_HI(sp),EXC_SIZEOF+EXC_PC+2(sp)
	MOVE.L	EXC_SIZEOF+FP_SCR0_LO(sp),EXC_SIZEOF+EXC_EA(sp)

	ADD.L	#EXC_SIZEOF+4-12,sp	** free frame + EXC_LINK -12
	BRA	_real_snan









**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
**	_fpsp_inex(): 060FPSP entry point for FP Inexact exception.
**-------------------------------------------------------------------------------------------------
*	This handler should be the first code executed upon taking the
* 	FP Inexact exception in an operating system.
*
* XREF :
*	_imem_read_long() - read instruction longword
*	fix_skewed_ops() - adjust src operand in fsave frame
*	set_tag_x() - determine optype of src/dst operands
*	store_fpreg() - store opclass 0 or 2 result to FP regfile
*	unnorm_fix() - change UNNORM operands to NORM or ZERO
*	load_fpn2() - load dst operand from FP regfile
*	smovcr() - emulate an "fmovcr" instruction
*	fout() - emulate an opclass 3 instruction
*	tbl_unsupp - add of table of emulation routines for opclass 0,2
*	_real_inex() - "callout" to operating system inexact handler
*
* INPUT :
*	- The system stack contains the FP Inexact exception frame
*	- The fsave frame contains the source operand
*
* OUTPUT :
*	- The system stack is unchanged
*	- The fsave frame contains the adjusted src op for opclass 0,2
*
* ALGORITHM :
*  In  a  system where the FP Inexact exception is enabled, the goal is to get to the handler
* specified  at  _real_inex().   But, on the 060, for opclass zero and two instruction taking
* this  exception,  the  hardware  doesn't  store  the  correct  result to the destination FP
* register as did the '040 and '881/2.
*
*  This  handler must emulate the instruction in order to get this value and then store it to
* the correct register before calling _real_inex().
*
*  For opclass 3 instructions, the 060 doesn't store the default inexact result out to memory
* or  data register file as it should.  This code must emulate the move out by calling fout()
* before finally exiting through _real_inex().
*
**-------------------------------------------------------------------------------------------------

	xdef	_fpsp_inex
_fpsp_inex:
	DBUG	10,"<INEX EXC>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* grab the "busy" frame

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch the instruction words
	MOVE.L	d0,EXC_LV+EXC_OPWORD(a6)

	**---------------------------------------------------------------------------------

	BTST	#13,d0		* is instr an fmove out?
	BNE	finex_out	* fmove out


	**---------------------------------------------------------------------------------
	* the hardware, for "fabs" and "fneg" w/ a dc.l source format, puts the
	* longword integer directly into the upper longword of the mantissa along
	* w/ an exponent value of $401e. we convert this to extended precision here.

	BFEXTU	d0{19:3},d0		* fetch instr size
	BNE	finex_cont		* instr size is not dc.l

	CMP.w	#$40e1,EXC_LV+FP_SRC_EX(a6)	* is exponent $401e?
	BNE	finex_cont			* no

	FMOVE.L	#$0,fpcr
	FMOVE.L	EXC_LV+FP_SRC_HI(a6),fp0	* load integer src

	FMOVE.X	fp0,EXC_LV+FP_SRC(a6)		* store integer as extended precision
	MOVE.W	#$e001,EXC_LV+FP_SRC+2(a6)

finex_cont:
	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	fix_skewed_ops		* fix src op

	**---------------------------------------------------------------------------------
	* Here, we zero the ccode and exception byte field since we're going to
	* emulate the whole instruction. Notice, though, that we don't kill the
	* INEX1 bit. This is because a packed op has dc.l since been converted
	* to extended before arriving here. Therefore, we need to retain the
	* INEX1 bit from when the operand was first converted.

	ANDI.L	#$00ff01ff,EXC_LV+USER_FPSR(a6) * zero all but accured field

	FMOVE.L	#$0,fpcr			* zero current control regs
	FMOVE.L	#$0,fpsr

	BFEXTU	EXC_LV+EXC_EXTWORD(a6){0:6},d1 	* extract upper 6 of cmdreg
	CMP.B	#$17,d1				* is op an fmovecr?
	BEQ	finex_fmovcr			* yes

	LEA	EXC_LV+FP_SRC(a6),a0		* pass: ptr to src op
	BSR	set_tag_x			* tag the operand type
	MOVE.B	d0,EXC_LV+STAG(a6)		* maybe NORM,DENORM

	**---------------------------------------------------------------------------------
	* bits four and five of the fp extension word separate the monadic and dyadic
	* operations that can pass through fpsp_inex(). remember that fcmp and ftst
	* will never take this exception, but fsincos will.

	BTST	#$5,EXC_LV+EXC_CMDREG+1(a6)	* is operation monadic or dyadic?
	BEQ	finex_extract			* monadic

	BTST	#$4,EXC_LV+EXC_CMDREG+1(a6)	* is operation an fsincos?
	BNE	finex_extract			* yes

	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* dyadic; load dst reg
	BSR	load_fpn2			* load dst into EXC_LV+FP_DST

	LEA	EXC_LV+FP_DST(a6),a0	* pass: ptr to dst op
	BSR	set_tag_x		* tag the operand type
	CMP.B	#UNNORM,d0		* is operand an UNNORM?
	BNE	finex_op2_done		* no
	BSR	unnorm_fix		* yes; convert to NORM,DENORM,or ZERO
finex_op2_done:	MOVE.B	d0,EXC_LV+DTAG(a6)	* save dst optype tag

	**---------------------------------------------------------------------------------
finex_extract:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass rnd prec/mode

	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1
	ANDI.W	#$007f,d1			* extract extension

	LEA	EXC_LV+FP_SRC(a6),a0
	LEA	EXC_LV+FP_DST(a6),a1

	MOVE.L	((tbl_unsupp).w,pc,d1.w*4),d1 	* fetch routine addr
	jsr	((tbl_unsupp).w,pc,d1.l*1)

	**---------------------------------------------------------------------------------
	* the operation has been emulated. the result is in fp0.
finex_save:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3},d0
	BSR	store_fpreg

finex_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)

	UNLK	a6
	BRA	_real_inex

	**---------------------------------------------------------------------------------
finex_fmovcr:
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass rnd prec,mode
	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1
	ANDI.L	#$0000007f,d1			* pass rom offset
	BSR	smovcr
	BRA	finex_save


	**---------------------------------------------------------------------------------
	*
	*  the  hardware  does  not  save  the  default  result  to memory on enabled inexact
	* exceptions.  we do this here before passing control to the user inexact handler.
	*
	* byte,  word,  and dc.l destination format operations can pass through here.  so can
	* double and single precision.
	*
	* although  packed  opclass  three operations can take inexact exceptions, they won't
	* pass  through  here  since  they  are  caught  first by the unsupported data format
	* exception handler.  that handler sends them directly to _real_inex() if necessary.

finex_out:
	MOVE.B	#NORM,EXC_LV+STAG(a6)		* src is a NORM
	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0		* pass rnd prec,mode

	ANDI.L	#$ffff00ff,EXC_LV+USER_FPSR(a6) * zero exception field

	LEA	EXC_LV+FP_SRC(a6),a0	* pass ptr to src operand
	BSR	fout			* store the default result

	BRA	finex_exit








**-------------------------------------------------------------------------------------------------
**	_fpsp_dz(): 060FPSP entry point for FP DZ exception.
**-------------------------------------------------------------------------------------------------
*
*	This handler should be the first code executed upon taking
*	the FP DZ exception in an operating system.
*
* XREF :
*	_imem_read_long() - read instruction longword from memory
*	fix_skewed_ops() - adjust fsave operand
*	_real_dz() - "callout" exit point from FP DZ handler
*
* INPUT :
*	- The system stack contains the FP DZ exception stack.
*	- The fsave frame contains the source operand.
*
* OUTPUT :
*	- The system stack contains the FP DZ exception stack.
*	- The fsave frame contains the adjusted source operand.
*
* ALGORITHM ***********************************************************
*
* In a system where the DZ exception is enabled, the goal is to
* get to the handler specified at _real_dz(). But, on the 060, when the
* exception is taken, the input operand in the fsave state frame may
* be incorrect for some cases and need to be adjusted. So, this package
* adjusts the operand using fix_skewed_ops() and then branches to
* _real_dz().
*
**-------------------------------------------------------------------------------------------------

	xdef	_fpsp_dz
_fpsp_dz:
	DBUG	10,"<INEX EXC>"

	LINK	a6,#-EXC_SIZEOF		* init stack frame
	FSAVE	EXC_LV+FP_SRC(a6)	* grab the "busy" frame

 	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
 	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1 on stack

	* the FPIAR holds the "current PC" of the faulting instruction

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch the instruction words
	MOVE.l	d0,EXC_LV+EXC_OPWORD(a6)

	**-------------------------------------------------------------------------------
	* here, we simply see if the operand in the fsave frame needs to be "unskewed".
	* this would be the case for opclass two operations with a source zero
	* in the sgl or dbl format.

	LEA	EXC_LV+FP_SRC(a6),a0	* pass: ptr to src op
	BSR	fix_skewed_ops		* fix src op

fdz_exit:
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)

	UNLK	a6
	BRA	_real_dz





**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*	_fpsp_fline(): 060FPSP entry point for "Line F emulator" exc.
**-------------------------------------------------------------------------------------------------
*
*	This handler should be the first code executed upon taking the
*	"Line F Emulator" exception in an operating system.
*
* XREF :
*	_fpsp_unimp() - handle "FP Unimplemented" exceptions
*	_real_fpu_disabled() - handle "FPU disabled" exceptions
*	_real_fline() - handle "FLINE" exceptions
*	_imem_read_long() - read instruction longword
*
* INPUT :
*	- The system stack contains a "Line F Emulator" exception
*	  stack frame.
*
* OUTPUT :
*	- The system stack is unchanged
*
* ALGORITHM ***********************************************************
*
*  When  a  "Line  F  Emulator"  exception  occurs, there are 3 possible exception
* types, denoted by the exception stack frame format number:
*
*	(1) FPU unimplemented instruction (6 word stack frame)
*	(2) FPU disabled (8 word stack frame)
*	(3) Line F (4 word stack frame)
*
*  This  module  determines  which  and  forks  the  flow  off  to the appropriate
* "callout"  (for  "disabled"  and "Line F") or to the correct emulation code (for
* "FPU unimplemented").  This code also must check for "fmovecr" instructions w/ a
* non-zero  <ea>  field.   These  may get flagged as "Line F" but should really be
* flagged as "FPU Unimplemented".  (This is a "feature" on the '060).
*
**-------------------------------------------------------------------------------------------------

	xdef	_fpsp_fline

_fpsp_fline:
	**--------------------------------------------------------------------------------
	* check to see if this exception is a "FP Unimplemented Instruction"
	* exception. if so, branch directly to that handler's entry point.
	**--------------------------------------------------------------------------------

	CMP.w	#$202c,$6(sp)
	BEQ	_fpsp_unimp

	**--------------------------------------------------------------------------------
	* check to see if the FPU is disabled. if so, jump to the OS entry
	* point for that condition.
	**--------------------------------------------------------------------------------

	CMP.w	#$402c,$6(sp)
	BEQ	_real_fpu_disabled

	**--------------------------------------------------------------------------------
	* the exception was an "F-Line Illegal" exception. we check to see
	* if the F-Line instruction is an "fmovecr" w/ a non-zero <ea>. if
	* so, convert the F-Line exception stack frame to an FP Unimplemented
	* Instruction exception stack frame else branch to the OS entry
	* point for the F-Line exception handler.
	**--------------------------------------------------------------------------------

	LINK	a6,#-EXC_SIZEOF	* init stack frame

	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1

	MOVE.L	EXC_PC(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.l	(a0),d0         		* fetch instruction words

	BFEXTU	d0{0:10},d1		* is it an fmovecr?
	CMP.w	#$03c8,d1
	BNE	fline_fline		* no

	BFEXTU	d0{16:6},d1		* is it an fmovecr?
	CMP.b	#$17,d1
	BNE	fline_fline		* no

	**--------------------------------------------------------------------------------
	* it's an fmovecr w/ a non-zero <ea> that has entered through
	* the F-Line Illegal exception.
	* so, we need to convert the F-Line exception stack frame into an
	* FP Unimplemented Instruction stack frame and jump to that entry
	* point.
	*
	* but, if the FPU is disabled, then we need to jump to the FPU diabled
	* entry point.
	**--------------------------------------------------------------------------------

	MOVEC	pcr,d0
	BTST	#$1,d0
	BEQ	fline_fmovcr

	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1
	UNLK	a6

	SUB.L	#$8,sp			* make room for "Next PC", <ea>
	MOVE.W	$8(sp),(sp)
	MOVE.L	$a(sp),$2(sp)		* move "Current PC"
	MOVE.W	#$402c,$6(sp)
	MOVE.L	$2(sp),$c(sp)
	ADDQ.L	#$4,$2(sp)		* set "Next PC"

	BRA	_real_fpu_disabled

	**--------------------------------------------------------------------------------
fline_fmovcr:
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1
	UNLK	a6

	FMOVE.L	$2(sp),fpiar	* set current PC
	ADDQ.L	#$4,$2(sp)	* set Next PC

	MOVE.l	(sp),-(sp)
	MOVE.L	$8(sp),$4(sp)
	MOVE.B	#$20,$6(sp)

	BRA	_fpsp_unimp

	**--------------------------------------------------------------------------------
fline_fline:
	DBUG	10,"<FLINE EXC>"

	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1
	UNLK	a6
	BRA	_real_fline









**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*	_fpsp_unimp(): 060FPSP entry point for FP "Unimplemented Instruction" exception.
**-------------------------------------------------------------------------------------------------
*
*	This handler should be the first code executed upon taking the
*	FP Unimplemented Instruction exception in an operating system.
* XREF :
*	_imem_read_{word,dc.l}() - read instruction word/longword
*	load_fop() - load src/dst ops from memory and/or FP regfile
*	store_fpreg() - store opclass 0 or 2 result to FP regfile
*	tbl_trans - addr of table of emulation routines for trnscndls
*	_real_access() - "callout" for access error exception
*	_fpsp_done() - "callout" for exit; work all done
*	_real_trace() - "callout" for Trace enabled exception
*	smovcr() - emulate "fmovecr" instruction
*	funimp_skew() - adjust fsave src ops to "incorrect" value
*	_ftrapcc() - emulate an "ftrapcc" instruction
*	_fdbcc() - emulate an "fdbcc" instruction
*	_fscc() - emulate an "fscc" instruction
*	_real_trap() - "callout" for Trap exception
* 	_real_bsun() - "callout" for enabled Bsun exception
*
* INPUT :
*	- The system stack contains the "Unimplemented Instr" stk frame
*
* OUTPUT :
*	If access error:
*	   - The system stack is changed to an access error stack frame
*	If Trace exception enabled:
*	   - The system stack is changed to a Trace exception stack frame
*	Else: (normal case)
*	   - Correct result has been stored as appropriate
*
* ALGORITHM ***********************************************************
*
* There  are  two  main  cases of instructions that may enter here to be emulated:
* (1)  the  FPgen  instructions, most of which were also unimplemented on the 040,
*	and (2) "ftrapcc", "fscc", and "fdbcc".
*
*  For the first set, this handler calls the routine load_fop() to load the source
* and destination (for dyadic) operands to be used for instruction emulation.
*
*  The  correct  emulation routine is then chosen by decoding the instruction type
* and indexing into an emulation subroutine index table.
*
*  After  emulation  returns,  this  handler  checks to see if an exception should
* occur  as a result of the FP instruction emulation.  If so, then an FP exception
* of  the  correct  type is inserted into the FPU state frame using the "frestore"
* instruction before exiting through _fpsp_done().
*
*  In either the exceptional or non-exceptional cases, we must check to see if the
* Trace  exception is enabled.  If so, then we must create a Trace exception frame
* from the current exception frame and exit through _real_trace().
*
*  For  "fdbcc",  "ftrapcc",  and  "fscc",  the  emulation  subroutines  _fdbcc(),
* _ftrapcc(),  and  _fscc() respectively are used.  All three may flag that a BSUN
* exception  should  be  taken.   If so, then the current exception stack frame is
* converted  into  a  BSUN  exception  stack  frame  and  an  exit is made through
* _real_bsun().
*
* If  the  instruction  was  "ftrapcc"  and a Trap exception should result, a Trap
* exception  stack  frame  is  created  from the current frame and an exit is made
* through  _real_trap().   If a Trace exception is pending, then a Trace exception
* frame is created from the current frame and a jump is made to _real_trace().
*
*  Finally,  if  none of these conditions exist, then the handler exits though the
* callout _fpsp_done().
*
*  In  any  of  the  above  scenarios,  if a _mem_read() or _mem_write() "callout"
* returns  a  failing  value, then an access error stack frame is created from the
* current stack frame and an exit is made through _real_access().
**-------------------------------------------------------------------------------------------------
*
* FP UNIMPLEMENTED INSTRUCTION STACK FRAME:
*
*	*****************
*	*	* => <ea> of fp unimp instr.
*	-      EA	-
*	*
*	*****************
*	* $2 *  $02c	* => frame format and vector offset(vector *11)
*	*****************
*	*
*	-    Next PC	- => PC of instr to execute after exc handling
*	*
*	*****************
*	*      SR	* => SR at the time the exception was taken
*	*****************
*
* Note: the !NULL bit does not get set in the fsave frame when the
* machine encounters an fp unimp exception. Therefore, it must be set
* before leaving this handler.
*
	xdef	_fpsp_unimp
_fpsp_unimp:
	DBUG	10,"<UNIMP EXC>"

	LINK	a6,#-EXC_SIZEOF	* init stack frame

	MOVEM.L	d0-d1/a0-a1,EXC_LV+EXC_DREGS(a6)	* save d0-d1/a0-a1
	FMOVEM.L	fpcr/fpsr/fpiar,EXC_LV+USER_FPCR(a6) 	* save ctrl regs
	FMOVEM.X	fp0-fp1,EXC_LV+EXC_FPREGS(a6)		* save fp0-fp1

	BTST	#$5,EXC_SR(a6)				* user mode exception?
	BNE	funimp_s				* no; supervisor mode

	**--------------------------------------------------------------------------------
	* save the value of the user stack pointer onto the stack frame
funimp_u:
	MOVE.L	usp,a0			* fetch user stack pointer
	MOVE.L	a0,EXC_LV+EXC_A7(a6)	* store in stack frame
	BRA	funimp_cont

	**--------------------------------------------------------------------------------
	* store the value of the supervisor stack pointer BEFORE the exc occurred.
	* old_sp is address just above stacked effective address.
funimp_s:
	LEA	EXC_EA+4(a6),a0		* load old a7'
	move.l	a0,EXC_LV+EXC_A7(a6)	* store a7'
	move.l	a0,OLD_A7(a6)		* make a copy

funimp_cont:
	**--------------------------------------------------------------------------------
	* the FPIAR holds the "current PC" of the faulting instruction.

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_LV+EXC_EXTWPTR(a6)

	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$4,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.L	(a0),d0				* fetch the instruction words
	MOVE.L	d0,EXC_LV+EXC_OPWORD(a6)

	**--------------------------------------------------------------------------------

	FMOVE.L	#$0,fpcr		* clear FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	CLR.B	EXC_LV+SPCOND_FLG(a6)	* clear "special case" flag

	**--------------------------------------------------------------------------------
	* Divide the fp instructions into 8 types based on the TYPE field in
	* bits 6-8 of the opword(classes 6,7 are undefined).
	* (for the '060, only two types  can take this exception)
	*	bftst	d0(7:3}	* test TYPE

	BTST	#22,d0		* type 0 or 1 ?
	BNE	funimp_misc	* type 1

	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	**--------------------------------------------------------------------------------
	**--------------------------------------------------------------------------------
	* TYPE == 0: General instructions

funimp_gen:
	CLR.B	EXC_LV+STORE_FLG(a6)	* clear "store result" flag

	* clear the ccode byte and exception status byte

	ANDI.L	#$00ff00ff,EXC_LV+USER_FPSR(a6)

	BFEXTU	d0{16:6},d1		* extract upper 6 of cmdreg
	CMP.b	#$17,d1			* is op an fmovecr?
	BEQ	funimp_fmovcr		* yes

funimp_gen_op:
	BSR	_load_fop		* load

	CLR.L	d0
	MOVE.b	EXC_LV+FPCR_MODE(a6),d0	* fetch rnd mode

	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1
	ANDI.W	#$003f,d1			* extract extension bits
	LSL.W	#$3,d1			* shift right 3 bits
	OR.B	EXC_LV+STAG(a6),d1	* insert src optag bits

	LEA	EXC_LV+FP_DST(a6),a1	* pass dst ptr in a1
	LEA	EXC_LV+FP_SRC(a6),a0	* pass src ptr in a0

	MOVE.W	(tbl_trans.w,pc,d1.w*2),d1
	JSR	(tbl_trans.w,pc,d1.w*1) 	* emulate

funimp_fsave:
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d0	* fetch exceptions enabled
	BNE	funimp_ena			* some are enabled

funimp_store:
	BFEXTU	EXC_LV+EXC_CMDREG(a6){6:3},d0 	* fetch Dn
	BSR	store_fpreg			* store result to fp regfile

	**--------------------------------------------------------------------------------
funimp_gen_exit:
	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.l	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

funimp_gen_exit_cmp:
	CMP.b	#mia7_flg,EXC_LV+SPCOND_FLG(a6)		* was the ea mode (sp)+ ?
	BEQ	funimp_gen_exit_a7			* yes

	CMP.b	#mda7_flg,EXC_LV+SPCOND_FLG(a6)		* was the ea mode -(sp) ?
	BEQ	funimp_gen_exit_a7			* yes

funimp_gen_exit_cont:
	UNLK	a6

funimp_gen_exit_cont2:
	BTST	#$7,(sp)		* is trace on?
	BEQ	_fpsp_done		* no

	**--------------------------------------------------------------------------------
	* this catches a problem with the case where an exception will be re-inserted
	* into the machine. the frestore has already been executed...so, the fmove.l
	* alone of the control register would trigger an unwanted exception.
	* until I feel like fixing this, we'll sidestep the exception.

	FSAVE	-(sp)
	FMOVE.L	fpiar,$14(sp)	* "Current PC" is in FPIAR
	FRESTORE	(sp)+
	MOVE.W	#$2024,$6(sp)	* stk fmt = $2; voff = $24
	BRA	_real_trace

	**--------------------------------------------------------------------------------

funimp_gen_exit_a7:
	BTST	#$5,EXC_SR(a6)		* supervisor or user mode?
	BNE	funimp_gen_exit_a7_s	* supervisor

	MOVE.L	a0,-(sp)
	MOVE.L	EXC_LV+EXC_A7(a6),a0
	MOVE.L	a0,usp
	MOVE.L	(sp)+,a0
	BRA	funimp_gen_exit_cont

	**--------------------------------------------------------------------------------
	* if the instruction was executed from supervisor mode and the addressing
	* mode was (a7)+, then the stack frame for the rte must be shifted "up"
	* "n" bytes where "n" is the size of the src operand type.
	* f<op>.{b,w,l,s,d,x,p}

funimp_gen_exit_a7_s:
	MOVE.L	d0,-(sp)			* save d0
	MOVE.L	EXC_LV+EXC_A7(a6),d0		* load new a7'
	SUB.L	OLD_A7(a6),d0			* subtract old a7'

	MOVE.L	EXC_PC+2(a6),(EXC_PC+2,a6,d0) 	* shift stack frame
	MOVE.L	EXC_SR(a6),(EXC_SR,a6,d0) 	* shift stack frame
	MOVE.W	d0,EXC_SR(a6)			* store incr number
	MOVE.L	(sp)+,d0			* restore d0

	UNLK	a6

	ADD.W	(sp),sp				* stack frame shifted
	BRA	funimp_gen_exit_cont2

	**--------------------------------------------------------------------------------
                * fmovecr.x *ccc,fpn
	*
funimp_fmovcr:
	DBUG	15,"<FLINE EXC:fmovecr>"

	CLR.L	d0
	MOVE.B	EXC_LV+FPCR_MODE(a6),d0
	MOVE.B	EXC_LV+EXC_CMDREG+1(a6),d1
	ANDI.L	#$0000007f,d1	* pass rom offset in d1
	BSR	smovcr
	BRA	funimp_fsave


	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	* the user has enabled some exceptions. we figure not to see this too
	* often so that's why it gets lower priority.
funimp_ena:

	**-------------------------------------------------------------------------------------------------
	* was an exception set that was also enabled?

	AND.B	EXC_LV+FPSR_EXCEPT(a6),d0	* keep only ones enabled and set
	BFFFO	d0{24:8},d0			* find highest priority exception
	BNE	funimp_exc			* at least one was set

	**-------------------------------------------------------------------------------------------------
	* no exception that was enabled was set BUT if we got an exact overflow
	* and overflow wasn't enabled but inexact was (yech!) then this is
	* an inexact exception; otherwise, return to normal non-exception flow.

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did overflow occur?
	BEQ	funimp_store			 * no; return to normal flow

	**-------------------------------------------------------------------------------------------------
	* the overflow w/ exact result happened but was inexact set in the FPCR?
funimp_ovfl:
	BTST	#inex2_bit,EXC_LV+FPCR_ENABLE(a6) * is inexact enabled?
	BEQ	funimp_store			  * no; return to normal flow
	BRA	funimp_exc_ovfl			  * yes

	**-------------------------------------------------------------------------------------------------
	* some exception happened that was actually enabled.
	* we'll insert this new exception into the FPU and then return.
funimp_exc:
	SUBI.L	#24,d0			* fix offset to be 0-8
	CMP.B	#6,d0			* is exception INEX?
	BNE	funimp_exc_force	* no

	**-------------------------------------------------------------------------------------------------
	* the enabled exception was inexact. so, if it occurs with an overflow
	* or underflow that was disabled, then we have to force an overflow or
	* underflow frame. the eventual overflow or underflow handler will see that
	* it's actually an inexact and act appropriately. this is the only easy
	* way to have the EXOP available for the enabled inexact handler when
	* a disabled overflow or underflow has also happened.

	BTST	#ovfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did overflow occur?
	BNE	funimp_exc_ovfl			 * yes
	BTST	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * did underflow occur?
	BNE	funimp_exc_unfl			 * yes

	**-------------------------------------------------------------------------------------------------
	* force the fsave exception status bits to signal an exception of the
	* appropriate type. don't forget to "skew" the source operand in case we
	* "unskewed" the one the hardware initially gave us.

funimp_exc_force:
	MOVE.L	d0,-(sp)	* save d0
	BSR	funimp_skew	* check for special case
	MOVE.l	(sp)+,d0	* restore d0

	MOVE.W	((tbl_funimp_except).b,pc,d0.w*2),EXC_LV+FP_SRC+2(a6)
	BRA	funimp_gen_exit2
					* exit with frestore

tbl_funimp_except:
	dc.w	$e002, $e006, $e004, $e005
	dc.w	$e003, $e002, $e001, $e001

	**-------------------------------------------------------------------------------------------------
	* insert an overflow frame
funimp_exc_ovfl:
	BSR	funimp_skew			* check for special case
	MOVE.W	#$e005,2+EXC_LV+FP_SRC(a6)
	BRA	funimp_gen_exit2

	**-------------------------------------------------------------------------------------------------
	* insert an underflow frame
funimp_exc_unfl:
	BSR	funimp_skew			* check for special case
	MOVE.W	#$e003,2+EXC_LV+FP_SRC(a6)

	**-------------------------------------------------------------------------------------------------
	* this is the general exit point for an enabled exception that will be
	* restored into the machine for the instruction just emulated.
funimp_gen_exit2:
	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)	* insert exceptional status

	BRA	funimp_gen_exit_cmp





	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	*
	* TYPE == 1: FDB<cc>, FS<cc>, FTRAP<cc>
	*
	* These instructions were implemented on the '881/2 and '040 in hardware but
	* are emulated in software on the '060.
	*
funimp_misc:
	BFEXTU	d0{10:3},d1		* extract mode field

	CMP.b	#1,d1			* is it an fdb<cc>?
	BEQ	funimp_fdbcc		* yes

	CMP.b	#7,d1			* is it an fs<cc>?
	BNE	funimp_fscc		* yes

	BFEXTU	d0{13:3},d1
	CMP.b	#2,d1			* is it an fs<cc>?
	BLT	funimp_fscc		* yes

	**-------------------------------------------------------------------------------------------------
	* ftrap<cc>
	* ftrap<cc>.w *<data>
	* ftrap<cc>.l *<data>
funimp_ftrapcc:
	BSR	_ftrapcc		* FTRAP<cc>()

	CMP.b	#fbsun_flg,EXC_LV+SPCOND_FLG(a6) 	* is enabled bsun occurring?
	BEQ	funimp_bsun				* yes

	CMP.b	#ftrapcc_flg,EXC_LV+SPCOND_FLG(a6) 	* should a trap occur?
	BNE	funimp_done				* no

	**-------------------------------------------------------------------------------------------------
	*	 FP UNIMP FRAME	   TRAP  FRAME
	*	*****************	*****************
	*	**    <EA>     **	**  Current PC **
	*	*****************	*****************
	*	* $2 *  $02c	*	* $2 *  $01c  *
	*	*****************	*****************
	*	**   Next PC   **	**   Next PC   **
	*	*****************	*****************
	*	*      SR	*	*      SR
	*	*****************	*****************
	*	    (6 words)	    (6 words)
	*
	* the ftrapcc instruction should take a trap. so, here we must create a
	* trap stack frame from an unimplemented fp instruction stack frame and
	* jump to the user supplied entry point for the trap exception
funimp_ftrapcc_tp:
	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_EA(a6) 	* Address = Current PC
	MOVE.W	#$201c,EXC_VOFF(a6)			* Vector Offset = $01c

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	UNLK	a6
	BRA	_real_trap

	**-------------------------------------------------------------------------------------------------
	* fdb<cc> Dn,<label>
funimp_fdbcc:
	MOVE.L	EXC_LV+EXC_EXTWPTR(a6),a0	* fetch instruction addr
	ADDQ.L	#$2,EXC_LV+EXC_EXTWPTR(a6)	* incr instruction ptr
	MOVE.W	(a0),d0         		* read displacement

	EXT.L	d0				* sign extend displacement

	BSR	_fdbcc				* FDB<cc>()

	CMP.b	#fbsun_flg,EXC_LV+SPCOND_FLG(a6) * is enabled bsun occurring?
	BEQ	funimp_bsun

	BRA	funimp_done			* branch to finish

	**-------------------------------------------------------------------------------------------------
	* fs<cc>.b <ea>
funimp_fscc:
	BSR	_fscc				* FS<cc>()

	**-------------------------------------------------------------------------------------------------
	* I am assuming here that an "fs<cc>.b -(An)" or "fs<cc>.b (An)+" instruction
	* does not need to update "An" before taking a bsun exception.

	CMP.b	#fbsun_flg,EXC_LV+SPCOND_FLG(a6) * is enabled bsun occurring?
	BEQ	funimp_bsun

	BTST	#$5,EXC_SR(a6)		* yes; is it a user mode exception?
	BNE.B	funimp_fscc_s		* no

funimp_fscc_u:
	MOVE.L	EXC_LV+EXC_A7(a6),a0	* yes; set new USP
	MOVE.L	a0,usp
	BRA	funimp_done		* branch to finish

	**-------------------------------------------------------------------------------------------------
	* remember, I'm assuming that post-increment is bogus...(it IS!!!)
	* so, the least significant WORD of the stacked effective address got
	* overwritten by the "fs<cc> -(An)". We must shift the stack frame "down"
	* so that the rte will work correctly without destroying the result.
	* even though the operation size is byte, the stack ptr is decr by 2.
	*
	* remember, also, this instruction may be traced.
funimp_fscc_s:
	CMP.b	#mda7_flg,EXC_LV+SPCOND_FLG(a6) * was a7 modified?
	BNE	funimp_done			* no

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	UNLK	a6

	BTST	#$7,(sp)		* is trace enabled?
	BNE	funimp_fscc_s_trace	* yes

	SUBQ.L	#$2,sp
	MOVE.L	$2(sp),(sp)		* shift SR,hi(PC) "down"
	MOVE.L	$6(sp),$4(sp)		* shift lo(PC),voff "down"
**$$$	BRA	_fpsp_done
                RTE

	**-------------------------------------------------------------------------------------------------
funimp_fscc_s_trace:
	SUBQ.L	#$2,sp
	MOVE.L	$2(sp),(sp)	* shift SR,hi(PC) "down"
	MOVE.W	$6(sp),$4(sp)	* shift lo(PC)
	MOVE.W	#$2024,$6(sp)	* fmt/voff = $2024
	FMOVE.L	fpiar,$8(sp)	* insert "current PC"
	BRA	_real_trace

	**-------------------------------------------------------------------------------------------------
	*
	* The ftrap<cc>, fs<cc>, or fdb<cc> is to take an enabled bsun. we must convert
	* the fp unimplemented instruction exception stack frame into a bsun stack frame,
	* restore a bsun exception into the machine, and branch to the user
	* supplied bsun hook.
	*
	*	 FP UNIMP FRAME	   BSUN FRAME
	*	*****************	*****************
	*	**    <EA>     **	* $0 * $0c0
	*	*****************	*****************
	*	* $2 *  $02c  *	** Current PC  **
	*	*****************	*****************
	*	**   Next PC   **	*      SR
	*	*****************	*****************
	*	*      SR	*	    (4 words)
	*	*****************
	*	    (6 words)

funimp_bsun:
	MOVE.W	#$00c0,EXC_EA+2(a6)		* Fmt = $0; Vector Offset = $0c0
	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_VOFF(a6)  * PC = Current PC
	MOVE.W	EXC_SR(a6),EXC_PC+2(a6) 		* shift SR "up"

	MOVE.W	#$e000,EXC_LV+FP_SRC+2(a6)	* bsun exception enabled

	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	FRESTORE	EXC_LV+FP_SRC(a6)		* restore bsun exception

	UNLK	a6

	ADDQ.L	#$4,sp		* erase sludge

	BRA	_real_bsun	* branch to user bsun hook

	**-------------------------------------------------------------------------------------------------
	* all ftrapcc/fscc/fdbcc processing has been completed. unwind the stack frame
	* and return.
	*
	* as usual, we have to check for trace mode being on here. since instructions
	* modifying the supervisor stack frame don't pass through here, this is a
	* relatively easy task.

funimp_done:
	FMOVEM.X	EXC_LV+EXC_FP0(a6),fp0-fp1		* restore fp0-fp1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
 	MOVEM.l	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1 	* restore d0-d1/a0-a1

	UNLK	a6

	BTST	#$7,(sp)	* is trace enabled?
	BNE	funimp_trace	* yes

**$$	BRA	_fpsp_done
	RTE

	**-------------------------------------------------------------------------------------------------
	*	 FP UNIMP FRAME	  TRACE  FRAME
	*	*****************	*****************
	*	**    <EA>     **	**  Current PC **
	*	*****************	*****************
	*	* $2 *  $02c	*	* $2 *  $024  *
	*	*****************	*****************
	*	**   Next PC   **	**   Next PC   **
	*	*****************	*****************
	*	*      SR	*	*      SR
	*	*****************	*****************
	*	    (6 words)	    (6 words)
	*
	* the fscc instruction should take a trace trap. so, here we must create a
	* trace stack frame from an unimplemented fp instruction stack frame and
	* jump to the user supplied entry point for the trace exception
funimp_trace:
	FMOVE.l	fpiar,$8(sp)	* current PC is in fpiar
	MOVE.B	#$24,$7(sp)	* vector offset = $024
	BRA	_real_trace


	**-------------------------------------------------------------------------------------------------
	**-------------------------------------------------------------------------------------------------
	* the instruction fetch access for the displacement word for the
	* fdbcc emulation failed. here, we create an access error frame
	* from the current frame and branch to _real_access().

	XDEF	funimp_iacc
funimp_iacc:
	MOVEM.L	EXC_LV+EXC_DREGS(a6),d0-d1/a0-a1	* restore d0-d1/a0-a1
	FMOVEM.L	EXC_LV+USER_FPCR(a6),fpcr/fpsr/fpiar 	* restore ctrl regs
	FMOVEM.X	EXC_LV+EXC_FPREGS(a6),fp0-fp1		* restore fp0-fp1

	MOVE.L	EXC_LV+USER_FPIAR(a6),EXC_PC(a6) 	* store current PC

	UNLK	A6

	MOVE.L	(sp),-(sp)		* store SR,hi(PC)
	move.w	$8(sp),$4(sp)		* store lo(PC)
	move.w	#$4008,$6(sp)		* store voff
	move.l	$2(sp),$8(sp)		* store EA
	move.l	#$09428001,$c(sp)	* store FSLW

	btst	#$5,(sp)		* user or supervisor mode?
	beq.b	funimp_iacc_end		* user
	bset	#$2,$d(sp)		* set supervisor TM bit

funimp_iacc_end:
	BRA	_real_access



















