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

	LIST
MYDEBUG	SET         	0	; Current Debug Level
DEBUG_DETAIL 	set 	10	; Detail Level




**-------------------------------------------------------------------------------------------------

	XREF	ssinh,src_zero,src_inf,ssinhd,src_qnan,src_snan,slognp1,sopr_inf
	XREF	slognp1d,setoxm1,setoxm1i,setoxm1d,stanh,stanhd,satan
	XREF	spi_2,satand,src_one,sasin,t_operr,sasind,satanh,satanhd
	XREF	satanhd,ssin,ssind,stan,stand,setox,ld_pone,szr_inf,setoxd,stwotox
	XREF	stwotoxd,stentox,stentoxd,slogn,t_dz2,slognd,slog10,slog10d,slog2
	XREF	slog2d,scosh,ld_pinf,scoshd,sacos,ld_ppi2,sacosd,scos,scosd,sgetexp
	XREF	sgetexpd,sgetman,sgetmand,ssincos,ssincosz,ssincosi,ssincosd,ssincosqnan
	XREF	smod_snorm,smod_szero,ssincossnan,smod_sinf,smod_sdnrm,sop_sqnan,sop_ssnan
	XREF	srem_snorm,srem_szero,srem_sinf,srem_sdnrm,sscale_snorm,sscale_szero
	XREF	sscale_sinf,sscale_sdnrm

	XREF	ovf_res,unf_res,norm,unf_res4

**-------------------------------------------------------------------------------------------------
*
* fkern2.s:
*
*  These  entry  points  are  used  by the exception handler routines where an instruction is
* selected by an index into a large jump table corresponding to a given instruction which has
* been  decoded.   Flow  continues  here  where  we now decode further accoding to the source
* operand type.
*

	xdef	fsinh
fsinh:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	ssinh
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	src_inf
	CMP.B	#DENORM,d1
	BEQ	ssinhd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	flognp1
flognp1:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	slognp1
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	sopr_inf
	CMP.B	#DENORM,d1
	BEQ	slognp1d
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fetoxm1
fetoxm1:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	setoxm1
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	setoxm1i
	CMP.B	#DENORM,d1
	BEQ	setoxm1d
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	ftanh
ftanh:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	stanh
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	src_one
	CMP.B	#DENORM,d1
	BEQ	stanhd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fatan
fatan:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	satan
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	spi_2
	CMP.B	#DENORM,d1
	BEQ	satand
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fasin
fasin:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	sasin
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	sasind
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fatanh
fatanh:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	satanh
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	satanhd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fsine
fsine:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	ssin
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	ssind
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	ftan
ftan:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	stan
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	stand
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fetox
fetox:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	setox
	CMP.B	#ZERO,d1
	BEQ	ld_pone
	CMP.B	#INF,d1
	BEQ	szr_inf
	CMP.B	#DENORM,d1
	BEQ	setoxd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	ftwotox
ftwotox:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	stwotox
	CMP.B	#ZERO,d1
	BEQ	ld_pone
	CMP.B	#INF,d1
	BEQ	szr_inf
	CMP.B	#DENORM,d1
	BEQ	stwotoxd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	ftentox
ftentox:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	stentox
	CMP.B	#ZERO,d1
	BEQ	ld_pone
	CMP.B	#INF,d1
	BEQ	szr_inf
	CMP.B	#DENORM,d1
	BEQ	stentoxd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	flogn
flogn:  	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	slogn
	CMP.B	#ZERO,d1
	BEQ	t_dz2
	CMP.B	#INF,d1
	BEQ	sopr_inf
	CMP.B	#DENORM,d1
	BEQ	slognd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	flog10
flog10: 	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	slog10
	CMP.B	#ZERO,d1
	BEQ	t_dz2
	CMP.B	#INF,d1
	BEQ	sopr_inf
	CMP.B	#DENORM,d1
	BEQ	slog10d
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	flog2
flog2:  	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	slog2
	CMP.B	#ZERO,d1
	BEQ	t_dz2
	CMP.B	#INF,d1
	BEQ	sopr_inf
	CMP.B	#DENORM,d1
	BEQ	slog2d
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fcosh
fcosh:  	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	scosh
	CMP.B	#ZERO,d1
	BEQ	ld_pone
	CMP.B	#INF,d1
	BEQ	ld_pinf
	CMP.B	#DENORM,d1
	BEQ	scoshd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	facos
facos:  	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	sacos
	CMP.B	#ZERO,d1
	BEQ	ld_ppi2
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	sacosd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fcos
fcos:   	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	scos
	CMP.B	#ZERO,d1
	BEQ	ld_pone
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	scosd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fgetexp
fgetexp:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	sgetexp
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	sgetexpd
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fgetman
fgetman:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	sgetman
	CMP.B	#ZERO,d1
	BEQ	src_zero
	CMP.B	#INF,d1
	BEQ	t_operr
	CMP.B	#DENORM,d1
	BEQ	sgetmand
	CMP.B	#QNAN,d1
	BEQ	src_qnan
	BRA	src_snan

	xdef	fsincos
fsincos:	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	ssincos
	CMP.B	#ZERO,d1
	BEQ	ssincosz
	CMP.B	#INF,d1
	BEQ	ssincosi
	CMP.B	#DENORM,d1
	BEQ	ssincosd
	CMP.B	#QNAN,d1
	BEQ	ssincosqnan
	BRA	ssincossnan

	xdef	fmod
fmod:   	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	smod_snorm
	CMP.B	#ZERO,d1
	BEQ	smod_szero
	CMP.B	#INF,d1
	BEQ	smod_sinf
	CMP.B	#DENORM,d1
	BEQ	smod_sdnrm
	CMP.B	#QNAN,d1
	BEQ	sop_sqnan
	BRA	sop_ssnan

	xdef	frem
frem:   	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	srem_snorm
	CMP.B	#ZERO,d1
	BEQ	srem_szero
	CMP.B	#INF,d1
	BEQ	srem_sinf
	CMP.B	#DENORM,d1
	BEQ	srem_sdnrm
	CMP.B	#QNAN,d1
	BEQ	sop_sqnan
	BRA	sop_ssnan

	xdef	fscale
fscale: 	MOVE.B	EXC_LV+STAG(a6),d1
	BEQ	sscale_snorm
	CMP.B	#ZERO,d1
	BEQ	sscale_szero
	CMP.B	#INF,d1
	BEQ	sscale_sinf
	CMP.B	#DENORM,d1
	BEQ	sscale_sdnrm
	CMP.B	#QNAN,d1
	BEQ	sop_sqnan
	BRA	sop_ssnan



**-------------------------------------------------------------------------------------------------
* XDEF **
* fgen_except(): catch an exception during transcendental  emulation
*
* xdef **
*	fmul() - emulate a multiply instruction
*	fadd() - emulate an add instruction
*	fin() - emulate an fmove instruction
*
* INPUT ***************************************************************
*	fp0 = destination operand
*	d0  = type of instruction that took exception
*	fsave frame = source operand
*
* OUTPUT **************************************************************
*	fp0 = result
*	fp1 = EXOP
*
* ALGORITHM ***********************************************************
* 	An exception occurred on the last instruction of the
* transcendental emulation. hopefully, this won't be happening much
* because it will be VERY slow.
* 	The only exceptions capable of passing through here are
* Overflow, Underflow, and Unsupported Data Type.
*
**-------------------------------------------------------------------------------------------------

	xdef	fgen_except
fgen_except:	CMP.b	#7,$3(sp)		* is exception UNSUPP?
	BEQ	fge_unsupp		* yes

	MOVE.B	#NORM,EXC_LV+STAG(a6)
fge_cont:	MOVE.B	#NORM,EXC_LV+DTAG(a6)

	**--------------------------------------------------------------------------------
	* ok, I have a problem with putting the dst op at EXC_LV+FP_DST. the emulation
	* routines aren't supposed to alter the operands but we've just squashed
	* EXC_LV+FP_DST here...
	* 8/17/93 - this turns out to be more of a "cleanliness" standpoint
	* then a potential bug. to begin with, only the dyadic functions
	* frem,fmod, and fscale would get the dst trashed here. But, for
	* the 060SP, the EXC_LV+FP_DST is never used again anyways.

	FMOVEM.X	fp0,EXC_LV+FP_DST(a6)	* dst op is in fp0

	LEA	$4(sp),a0		* pass: ptr to src op
	LEA	EXC_LV+FP_DST(a6),a1	* pass: ptr to dst op

	CMP.b	#FMOV_OP,d1
	BEQ	fge_fin			* it was an "fmov"
	CMP.b	#FADD_OP,d1
	BEQ	fge_fadd		* it was an "fadd"

fge_fmul:	BSR	fmul
	RTS

fge_fadd:	BSR	fadd
	RTS

fge_fin:	BSR	fin
	RTS

fge_unsupp:	MOVE.B	#DENORM,EXC_LV+STAG(a6)
	BRA.b	fge_cont

	**--------------------------------------------------------------------------------
	* This table holds the offsets of the emulation routines for each individual
	* math operation relative to the address of this table. Included are
	* routines like fadd/fmul/fabs as well as the transcendentals.
	* The location within the table is determined by the extension bits of the
	* operation longword.
	*
	XDEF	tbl_unsupp
tbl_unsupp:
	dc.l	fin		- tbl_unsupp	* 00: fmove
	dc.l	fint		- tbl_unsupp	* 01: fint
	dc.l	fsinh		- tbl_unsupp	* 02: fsinh
	dc.l	fintrz		- tbl_unsupp	* 03: fintrz
	dc.l	fsqrt		- tbl_unsupp	* 04: fsqrt
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	flognp1		- tbl_unsupp	* 06: flognp1
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fetoxm1		- tbl_unsupp	* 08: fetoxm1
	dc.l	ftanh		- tbl_unsupp	* 09: ftanh
	dc.l	fatan		- tbl_unsupp	* 0a: fatan
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fasin		- tbl_unsupp	* 0c: fasin
	dc.l	fatanh		- tbl_unsupp	* 0d: fatanh
	dc.l	fsine		- tbl_unsupp	* 0e: fsin
	dc.l	ftan		- tbl_unsupp	* 0f: ftan
	dc.l	fetox		- tbl_unsupp	* 10: fetox
	dc.l	ftwotox		- tbl_unsupp	* 11: ftwotox
	dc.l	ftentox		- tbl_unsupp	* 12: ftentox
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	flogn		- tbl_unsupp	* 14: flogn
	dc.l	flog10		- tbl_unsupp	* 15: flog10
	dc.l	flog2		- tbl_unsupp	* 16: flog2
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fabs		- tbl_unsupp 	* 18: fabs
	dc.l	fcosh		- tbl_unsupp	* 19: fcosh
	dc.l	fneg		- tbl_unsupp 	* 1a: fneg
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	facos		- tbl_unsupp	* 1c: facos
	dc.l	fcos		- tbl_unsupp	* 1d: fcos
	dc.l	fgetexp		- tbl_unsupp	* 1e: fgetexp
	dc.l	fgetman		- tbl_unsupp	* 1f: fgetman
	dc.l	fdiv		- tbl_unsupp 	* 20: fdiv
	dc.l	fmod		- tbl_unsupp	* 21: fmod
	dc.l	fadd		- tbl_unsupp 	* 22: fadd
	dc.l	fmul		- tbl_unsupp 	* 23: fmul
	dc.l	fsgldiv		- tbl_unsupp 	* 24: fsgldiv
	dc.l	frem		- tbl_unsupp	* 25: frem
	dc.l	fscale		- tbl_unsupp	* 26: fscale
	dc.l	fsglmul		- tbl_unsupp 	* 27: fsglmul
	dc.l	fsub		- tbl_unsupp 	* 28: fsub
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsincos		- tbl_unsupp	* 30: fsincos
	dc.l	fsincos		- tbl_unsupp	* 31: fsincos
	dc.l	fsincos		- tbl_unsupp	* 32: fsincos
	dc.l	fsincos		- tbl_unsupp	* 33: fsincos
	dc.l	fsincos		- tbl_unsupp	* 34: fsincos
	dc.l	fsincos		- tbl_unsupp	* 35: fsincos
	dc.l	fsincos		- tbl_unsupp	* 36: fsincos
	dc.l	fsincos		- tbl_unsupp	* 37: fsincos
	dc.l	fcmp		- tbl_unsupp 	* 38: fcmp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	ftst		- tbl_unsupp 	* 3a: ftst
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsin		- tbl_unsupp 	* 40: fsmove
	dc.l	fssqrt		- tbl_unsupp 	* 41: fssqrt
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fdin		- tbl_unsupp	* 44: fdmove
	dc.l	fdsqrt		- tbl_unsupp 	* 45: fdsqrt
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsabs		- tbl_unsupp 	* 58: fsabs
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsneg		- tbl_unsupp 	* 5a: fsneg
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fdabs		- tbl_unsupp	* 5c: fdabs
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fdneg		- tbl_unsupp 	* 5e: fdneg
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsdiv		- tbl_unsupp	* 60: fsdiv
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fsadd		- tbl_unsupp	* 62: fsadd
	dc.l	fsmul		- tbl_unsupp	* 63: fsmul
	dc.l	fddiv		- tbl_unsupp 	* 64: fddiv
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fdadd		- tbl_unsupp	* 66: fdadd
	dc.l	fdmul		- tbl_unsupp 	* 67: fdmul
	dc.l	fssub		- tbl_unsupp	* 68: fssub
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	tbl_unsupp	- tbl_unsupp
	dc.l	fdsub		- tbl_unsupp 	* 6c: fdsub


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* 	fmul(): emulates the fmul instruction
*	fsmul(): emulates the fsmul instruction
*	fdmul(): emulates the fdmul instruction
**-------------------------------------------------------------------------------------------------
*
* xdef **
*	scale_to_zero_src() - scale src exponent to zero
*	scale_to_zero_dst() - scale dst exponent to zero
*	unf_res() - return default underflow result
*	ovf_res() - return default overflow result
* 	res_qnan() - return QNAN result
* 	res_snan() - return SNAN result
*
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	a1 = pointer to extended precision destination operand
*	d0  rnd prec,mode
*
* OUTPUT **************************************************************
*	fp0 = result
*	fp1 = EXOP (if exception occurred)
*
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms/denorms into ext/sgl/dbl precision.
*	For norms/denorms, scale the exponents such that a multiply
* instruction won't cause an exception. Use the regular fmul to
* compute a result. Check if the regular operands would have taken
* an exception. If so, return the default overflow/underflow result
* and return the EXOP if exceptions are enabled. Else, scale the
* result operand to the proper exponent.
*
**-------------------------------------------------------------------------------------------------

	cnop	0,$10
tbl_fmul_ovfl:	dc.l	$3fff - $7ffe	* ext_max
	dc.l	$3fff - $407e	* sgl_max
	dc.l	$3fff - $43fe	* dbl_max
tbl_fmul_unfl:	dc.l	$3fff + $0001	* ext_unfl
	dc.l	$3fff - $3f80	* sgl_unfl
	dc.l	$3fff - $3c00	* dbl_unfl


	xdef	fsmul
fsmul:	AND.B	#$30,d0			* clear rnd prec
	OR.B	#s_mode*$10,d0		* insert sgl prec
	BRA.b	fmul

	xdef	fdmul
fdmul:	AND.B	#$30,d0
	OR.B	#d_mode*$10,d0		* insert dbl prec

	xdef	fmul
fmul:	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	CLR.W	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	LSL.B	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1	* combine src tags
	BNE	fmul_not_norm		* optimize on non-norm input

fmul_norm:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_to_zero_src	* scale src exponent
	MOVE.L	d0,-(sp)		* save scale factor 1

	BSR	scale_to_zero_dst	* scale dst exponent
	ADD.L	d0,(sp)			* SCALE_FACTOR = scale1 + scale2

	MOVE.W	2+EXC_LV+L_SCR3(a6),d1	* fetch precision
	LSR.B	#$6,d1			* shift to lo bits
	MOVE.L	(sp)+,d0			* load S.F.
	CMP.l	(tbl_fmul_ovfl.w,pc,d1.w*4),d0 	* would result ovfl?
	BEQ	fmul_may_ovfl			* result may rnd to overflow
	BLT	fmul_ovfl			* result will overflow

	CMP.l	(tbl_fmul_unfl.w,pc,d1.w*4),d0	* would result unfl?
	BEQ	fmul_may_unfl			* result may rnd to no unfl
	BGT	fmul_unfl			* result will underflow

	**---------------------------------------------------------------------------
	* NORMAL:
	* - the result of the multiply operation will neither overflow nor underflow.
	* - do the multiply to the proper precision and rounding mode.
	* - scale the result exponent using the scale factor. if both operands were
	* normalized then we really don't need to go through this scaling. but for now,
	* this will do.

fmul_normal:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst operand

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0	* execute multiply

	FMOVE.L	fpsr,d1			* save status
	FMOVE.L	#$0,fpcr		* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fmul_normal_exit:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result
	MOVE.L	d2,-(sp)		* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load {sgn,exp}
	MOVE.L	d1,d2			* make a copy
	AND.L	#$7fff,d1		* strip sign
	AND.W	#$8000,d2		* keep old sign
	SUB.L	d0,d1			* add scale factor
	OR.W	d2,d1			* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2		* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS

	**---------------------------------------------------------------------------
	* OVERFLOW:
	* - the result of the multiply operation is an overflow.
	* - do the multiply to the proper precision and rounding mode in order to
	* set the inexact bits.
	* - calculate the default result and return it in fp0.
	* - if overflow or inexact is enabled, we need a multiply result rounded to
	* extended precision. if the original operation was extended, then we have this
	* result. if the original operation was single or double, we have to do another
	* multiply using extended precision and the correct rounding mode. the result
	* of this operation then has its exponent scaled by -$6000 to create the
	* exceptional operand.
	*
fmul_ovfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst operand

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0	* execute multiply

	FMOVE.L	fpsr,d1			* save status
	FMOVE.L	#$0,fpcr		* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	**---------------------------------------------------------------------------
	* save setting this until now because this is where fmul_may_ovfl may jump in
fmul_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1			* is OVFL or INEX enabled?
	BNE	fmul_ovfl_ena			* yes

	**---------------------------------------------------------------------------
	* calculate the default result
fmul_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	SNE	d1				* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0		* pass rnd prec,mode
	BSR	ovf_res				* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)		* set INF,N if applicable
	FMOVEM.X	(a0),fp0			* return default result in fp0
	RTS

	**---------------------------------------------------------------------------
	* OVFL is enabled; Create EXOP:
	* - if precision is extended, then we have the EXOP. simply bias the exponent
	* with an extra -$6000. if the precision is single or double, we need to
	* calculate a result rounded to extended precision.

fmul_ovfl_ena:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1				* test the rnd prec
	BNE	fmul_ovfl_ena_sd		* it's sgl or dbl

fmul_ovfl_ena_cont:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)		* move result to stack

	MOVE.L	d2,-(sp)			* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.W	d1,d2				* make a copy
	AND.L	#$7fff,d1			* strip sign
	SUB.L	d0,d1				* add scale factor
	SUB.L	#$6000,d1			* subtract bias
	AND.W	#$7fff,d1			* clear sign bit
	AND.W	#$8000,d2			* keep old sign
	OR.W	d2,d1				* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2			* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1		* return EXOP in fp1
	BRA.b	fmul_ovfl_dis

fmul_ovfl_ena_sd:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0		* load dst operand

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1				* keep rnd mode only
	FMOVE.L	d1,fpcr				* set FPCR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0		* execute multiply

	FMOVE.L	#$0,fpcr			* clear FPCR
	BRA.b	fmul_ovfl_ena_cont

	**---------------------------------------------------------------------------
	* may OVERFLOW:
	* - the result of the multiply operation MAY overflow.
	* - do the multiply to the proper precision and rounding mode in order to
	* set the inexact bits.
	* - calculate the default result and return it in fp0.
	*
fmul_may_ovfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0		* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr		* set FPCR
	FMOVE.L	#$0,fpsr			* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0		* execute multiply

	FMOVE.L	fpsr,d1				* save status
	FMOVE.L	#$0,fpcr			* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)		* save INEX2,N

	FABS.X	fp0,fp1				* make a copy of result
	FCMP.B	#$2,fp1				* is |result| >= 2.b?
	FBGE.W	fmul_ovfl_tst			* yes; overflow has occurred

	* no, it didn't overflow; we have correct result

	BRA	fmul_normal_exit

	**---------------------------------------------------------------------------
	* UNDERFLOW:
	* - the result of the multiply operation is an underflow.
	* - do the multiply to the proper precision and rounding mode in order to
	* set the inexact bits.
	* - calculate the default result and return it in fp0.
	* - if overflow or inexact is enabled, we need a multiply result rounded to
	* extended precision. if the original operation was extended, then we have this
	* result. if the original operation was single or double, we have to do another
	* multiply using extended precision and the correct rounding mode. the result
	* of this operation then has its exponent scaled by -$6000 to create the
	* exceptional operand.
	*
fmul_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	**---------------------------------------------------------------------------
	* for fun, let's use only extended precision, round to zero. then, let
	* the unf_res() routine figure out all the rest.
	* will we get the correct answer.

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst operand

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0	* execute multiply

	FMOVE.L	fpsr,d1			* save status
	FMOVE.L	#$0,fpcr		* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1			* is UNFL or INEX enabled?
	BNE	fmul_unfl_ena		* yes

fmul_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res			* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* unf_res2 may have set 'Z'
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS

	**---------------------------------------------------------------------------
	* UNFL is enabled.
	*
fmul_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1			* is precision extended?
	BNE	fmul_unfl_ena_sd	* no, sgl or dbl

	**---------------------------------------------------------------------------
	* if the rnd mode is anything but RZ, then we have to re-do the above
	* multiplication becuase we used RZ for all.

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

fmul_unfl_ena_cont:
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp1	* execute multiply

	FMOVE.L	#$0,fpcr		* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* save result to stack
	MOVE.L	d2,-(sp)		* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2			* make a copy
	AND.L	#$7fff,d1		* strip sign
	AND.W	#$8000,d2		* keep old sign
	SUB.L	d0,d1			* add scale factor
	ADD.L	#$6000,d1		* add bias
	AND.W	#$7fff,d1
	OR.W	d2,d1			* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2		* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fmul_unfl_dis

fmul_unfl_ena_sd:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1			* use only rnd mode
	FMOVE.L	d1,fpcr			* set FPCR
	BRA	fmul_unfl_ena_cont

	**---------------------------------------------------------------------------
	* MAY UNDERFLOW:
	* -use the correct rounding mode and precision. this code favors operations
	* that do not underflow.
fmul_may_unfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst operand

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp0	* execute multiply

	FMOVE.L	fpsr,d1			* save status
	FMOVE.L	#$0,fpcr		* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1			* make a copy of result
	FCMP.B	#$2,fp1			* is |result| > 2.b?
	FBGT	fmul_normal_exit	* no; no underflow occurred
	FBLT	fmul_unfl		* yes; underflow occurred

	**---------------------------------------------------------------------------
	* we still don't know if underflow occurred. result is ~ equal to 2. but,
	* we don't know if the result was an underflow that rounded up to a 2 or
	* a normalized number that rounded down to a 2. so, redo the entire operation
	* using RZ as the rounding mode to see what the pre-rounded result is.
	* this case should be relatively rare.
	*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst operand

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1			* keep rnd prec
	OR.B	#rz_mode*$10,d1		* insert RZ

	FMOVE.L	d1,fpcr			* set FPCR
	FMOVE.L	#$0,fpsr		* clear FPSR

	FMUL.X	EXC_LV+FP_SCR0(a6),fp1	* execute multiply

	FMOVE.L	#$0,fpcr		* clear FPCR
	FABS.X	fp1			* make absolute value
	FCMP.B	#$2,fp1			* is |result| < 2.b?
	FBGE	fmul_normal_exit	* no; no underflow occurred
	BRA	fmul_unfl		* yes, underflow occurred

	**--------------------------------------------------------------------------
	*
	* Multiply: inputs are not both normalized; what are they?
	*
fmul_not_norm:
	MOVE.W	((tbl_fmul_op).b,pc,d1.w*2),d1
	jmp	((tbl_fmul_op).b,pc,d1.w)

tbl_fmul_op:
	dc.w	fmul_norm	- tbl_fmul_op * NORM x NORM
	dc.w	fmul_zero	- tbl_fmul_op * NORM x ZERO
	dc.w	fmul_inf_src	- tbl_fmul_op * NORM x INF
	dc.w	fmul_res_qnan	- tbl_fmul_op * NORM x QNAN
	dc.w	fmul_norm	- tbl_fmul_op * NORM x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * NORM x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

	dc.w	fmul_zero	- tbl_fmul_op * ZERO x NORM
	dc.w	fmul_zero	- tbl_fmul_op * ZERO x ZERO
	dc.w	fmul_res_operr	- tbl_fmul_op * ZERO x INF
	dc.w	fmul_res_qnan	- tbl_fmul_op * ZERO x QNAN
	dc.w	fmul_zero	- tbl_fmul_op * ZERO x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * ZERO x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

	dc.w	fmul_inf_dst	- tbl_fmul_op * INF x NORM
	dc.w	fmul_res_operr	- tbl_fmul_op * INF x ZERO
	dc.w	fmul_inf_dst	- tbl_fmul_op * INF x INF
	dc.w	fmul_res_qnan	- tbl_fmul_op * INF x QNAN
	dc.w	fmul_inf_dst	- tbl_fmul_op * INF x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * INF x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

	dc.w	fmul_res_qnan	- tbl_fmul_op * QNAN x NORM
	dc.w	fmul_res_qnan	- tbl_fmul_op * QNAN x ZERO
	dc.w	fmul_res_qnan	- tbl_fmul_op * QNAN x INF
	dc.w	fmul_res_qnan	- tbl_fmul_op * QNAN x QNAN
	dc.w	fmul_res_qnan	- tbl_fmul_op * QNAN x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * QNAN x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

	dc.w	fmul_norm	- tbl_fmul_op * NORM x NORM
	dc.w	fmul_zero	- tbl_fmul_op * NORM x ZERO
	dc.w	fmul_inf_src	- tbl_fmul_op * NORM x INF
	dc.w	fmul_res_qnan	- tbl_fmul_op * NORM x QNAN
	dc.w	fmul_norm	- tbl_fmul_op * NORM x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * NORM x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x NORM
	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x ZERO
	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x INF
	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x QNAN
	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x DENORM
	dc.w	fmul_res_snan	- tbl_fmul_op * SNAN x SNAN
	dc.w	tbl_fmul_op	- tbl_fmul_op *
	dc.w	tbl_fmul_op	- tbl_fmul_op *

fmul_res_operr:	BRA	res_operr
fmul_res_snan:	BRA	res_snan
fmul_res_qnan:	BRA	res_qnan

	**--------------------------------------------------------------------------
                * Multiply: (Zero x Zero) || (Zero x norm) || (Zero x denorm)
	*
	xdef	fmul_zero	* xdef for fsglmul
fmul_zero:
	MOVE.B	SRC_EX(a0),d0	* exclusive or the signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	BPL	fmul_zero_p	* result ZERO is pos.
fmul_zero_n:	FMOVE.S	#$80000000,fp0	* load -ZERO
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set Z/N
	RTS
fmul_zero_p:	FMOVE.S	#$00000000,fp0	* load +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS

	**--------------------------------------------------------------------------
	* Multiply: (inf x inf) || (inf x norm) || (inf x denorm)
	*
	* Note: The j-bit for an infinity is a don't-care. However, to be
	* strictly compatible w/ the 68881/882, we make sure to return an
	* INF w/ the j-bit set if the input INF j-bit was set. Destination
	* INFs take priority.
	*
	xdef	fmul_inf_dst	* xdef for fsglmul
fmul_inf_dst:
	FMOVEM.X	DST(a1),fp0	* return INF result in fp0
	MOVE.B	SRC_EX(a0),d0	* exclusive or the signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	BPL	fmul_inf_dst_p	* result INF is pos.
fmul_inf_dst_n: FABS.X	fp0		* clear result sign
	FNEG.X	fp0		* set result sign
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set INF/N
	RTS
fmul_inf_dst_p:	FABS.X	fp0		* clear result sign
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set INF
	RTS

	xdef	fmul_inf_src	* xdef for fsglmul
fmul_inf_src:	FMOVEM.X	SRC(a0),fp0	* return INF result in fp0
	MOVE.B	SRC_EX(a0),d0	* exclusive or the signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	BPL	fmul_inf_dst_p	* result INF is pos.
	BRA	fmul_inf_dst_n




**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
*	fin(): emulates the fmove instruction
*	fsin(): emulates the fsmove instruction
*	fdin(): emulates the fdmove instruction
**-------------------------------------------------------------------------------------------------
*
* xdef **
*	norm() - normalize mantissa for EXOP on denorm
*	scale_to_zero_src() - scale src exponent to zero
*	ovf_res() - return default overflow result
* 	unf_res() - return default underflow result
*	res_qnan_1op() - return QNAN result
*	res_snan_1op() - return SNAN result
*
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	d0 = round prec/mode
*
* OUTPUT **************************************************************
*	fp0 = result
*	fp1 = EXOP (if exception occurred)
*
* ALGORITHM ***********************************************************
* 	Handle NANs, infinities, and zeroes as special cases. Divide
* norms into extended, single, and double precision.
* 	Norms can be emulated w/ a regular fmove instruction. For
* sgl/dbl, must scale exponent and perform an "fmove". Check to see
* if the result would have overflowed/underflowed. If so, use unf_res()
* or ovf_res() to return the default result. Also return EXOP if
* exception is enabled. If no exception, return the default result.
*	Unnorms don't pass through here.
*
**-------------------------------------------------------------------------------------------------

	xdef	fsin

fsin:	AND.B	#$30,d0		* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl precision
	BRA	fin

	xdef	fdin
fdin:	AND.B	#$30,d0		* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl precision

	xdef	fin
fin: 	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info
	MOVE.B	EXC_LV+STAG(a6),d1	* fetch src optype tag
	BNE	fin_not_norm		* optimize on non-norm input

	**-------------------------------------------------------------------------------
	* FP MOVE IN: NORMs and DENORMs ONLY!
	*
fin_norm:	AND.B	#$c0,d0			* is precision extended?
	BNE	fin_not_ext		* no, so go handle dbl or sgl

	**-------------------------------------------------------------------------------
	* precision selected is extended. so...we cannot get an underflow
	* or overflow because of rounding to the correct precision. so...
	* skip the scaling and unscaling...

	TST.B	SRC_EX(a0)			* is the operand negative?
	BPL	fin_norm_done			* no
	BSET	#neg_bit,EXC_LV+FPSR_CC(a6)	* yes, so set 'N' ccode bit
fin_norm_done:	FMOVEM.X	SRC(a0),fp0			* return result in fp0
	RTS

	**-------------------------------------------------------------------------------
	* for an extended precision DENORM, the UNFL exception bit is set
	* the accrued bit is NOT set in this instance(no inexactness!)
	*
fin_denorm:	AND.B	#$c0,d0				* is precision extended?
	BNE	fin_not_ext			* no, so go handle dbl or sgl

	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit
	TST.B	SRC_EX(a0)			* is the operand negative?
	BPL	fin_denorm_done			* no
	BSET	#neg_bit,EXC_LV+FPSR_CC(a6)	* yes, so set 'N' ccode bit
fin_denorm_done:
	FMOVEM.X	SRC(a0),fp0			* return result in fp0
	BTST	#unfl_bit,EXC_LV+FPCR_ENABLE(a6) * is UNFL enabled?
	BNE	fin_denorm_unfl_ena		* yes
	RTS

	**-------------------------------------------------------------------------------
	* the input is an extended DENORM and underflow is enabled in the FPCR.
	* normalize the mantissa and add the bias of $6000 to the resulting negative
	* exponent and insert back into the operand.
	*
fin_denorm_unfl_ena:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: ptr to operand
	BSR	norm				* normalize result
	NEG.W	d0				* new exponent = -(shft val)
	addi.w	#$6000,d0			* add new bias to exponent
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch old sign,exp
	AND.W	#$8000,d1			* keep old sign
	AND.W	#$7fff,d0			* clear sign position
	OR.W	d1,d0				* concat new exo,old sign
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1		* return EXOP in fp1
	RTS

	**-------------------------------------------------------------------------------
	* operand is to be rounded to single or double precision
	*
fin_not_ext:	CMP.b	#s_mode*$10,d0 			* separate sgl/dbl prec
	BNE	fin_dbl

	**-------------------------------------------------------------------------------
	* operand is to be rounded to single precision
	*
fin_sgl:    	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src		* calculate scale factor

	CMP.l	#$3fff-$3f80,d0			* will move in underflow?
	BGE	fin_sd_unfl			* yes; go handle underflow
	CMP.l	#$3fff-$407e,d0			* will move in overflow?
	BEQ	fin_sd_may_ovfl			* maybe; go check
	BLT	fin_sd_ovfl			* yes; go handle overflow

	**-------------------------------------------------------------------------------
	* operand will NOT overflow or underflow when moved into the fp reg file
	*
fin_sd_normal:
	FMOVE.L	#$0,fpsr			* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr		* set FPCR

	FMOVE.X	EXC_LV+FP_SCR0(a6),fp0		* perform move

	FMOVE.L	fpsr,d1				* save FPSR
	FMOVE.L	#$0,fpcr			* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)		* save INEX2,N

fin_sd_normal_exit:
	MOVE.L	d2,-(sp)			* save d2
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)		* store out result
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load {sgn,exp}
	MOVE.W	d1,d2				* make a copy
	AND.L	#$7fff,d1			* strip sign
	SUB.L	d0,d1				* add scale factor
	AND.W	#$8000,d2			* keep old sign
	OR.W	d1,d2				* concat old sign,new exponent
	MOVE.W	d2,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2			* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0		* return result in fp0
	RTS

	**-------------------------------------------------------------------------------
	* operand is to be rounded to double precision
	*
fin_dbl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src		* calculate scale factor

	CMP.l	#$3fff-$3c00,d0			* will move in underflow?
	BGE	fin_sd_unfl			* yes; go handle underflow
	CMP.l	#$3fff-$43fe,d0			* will move in overflow?
	BEQ	fin_sd_may_ovfl			* maybe; go check
	BLT	fin_sd_ovfl			* yes; go handle overflow
	BRA	fin_sd_normal			* no; ho handle normalized op

	**-------------------------------------------------------------------------------
	* operand WILL underflow when moved in to the fp register file
	*
fin_sd_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	TST.B	EXC_LV+FP_SCR0_EX(a6)		* is operand negative?
	BPL	fin_sd_unfl_tst
	BSET	#neg_bit,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit

	**-------------------------------------------------------------------------------
	* if underflow or inexact is enabled, then go calculate the EXOP first.
fin_sd_unfl_tst:
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1				* is UNFL or INEX enabled?
	BNE	fin_sd_unfl_ena			* yes

fin_sd_unfl_dis:
	LEA	EXC_LV+FP_SCR0(a6),a0		* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1		* pass: rnd prec,mode
	BSR	unf_res				* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)		* unf_res may have set 'Z'
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0		* return default result in fp0
	RTS

	**-------------------------------------------------------------------------------
	* operand will underflow AND underflow or inexact is enabled.
	* therefore, we must return the result rounded to extended precision.
	*
fin_sd_unfl_ena:
	MOVE.L	EXC_LV+FP_SCR0_HI(a6),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	EXC_LV+FP_SCR0_LO(a6),EXC_LV+FP_SCR1_LO(a6)
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load current exponent

	MOVE.L	d2,-(sp)			* save d2
	MOVE.W	d1,d2				* make a copy
	AND.L	#$7fff,d1			* strip sign
	SUB.L	d0,d1				* subtract scale factor
	AND.W	#$8000,d2			* extract old sign
	addi.l	#$6000,d1			* add new bias
	AND.W	#$7fff,d1
	OR.W	d1,d2				* concat old sign,new exp
	MOVE.W	d2,EXC_LV+FP_SCR1_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1		* return EXOP in fp1
	MOVE.L	(sp)+,d2			* restore d2
	BRA	fin_sd_unfl_dis

	**-------------------------------------------------------------------------------
	*
	* operand WILL overflow.
	*
fin_sd_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FMOVE.X	EXC_LV+FP_SCR0(a6),fp0	* perform move

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save FPSR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fin_sd_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fin_sd_ovfl_ena	* yes

@@@
*
* OVFL is not enabled; therefore, we must create the default result by
* calling ovf_res().
*
fin_sd_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass: prec,mode
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

*
* OVFL is enabled.
* the INEX2 bit has already been updated by the round to the correct precision.
* now, round to extended(and don't alter the FPSR).
*
fin_sd_ovfl_ena:
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1
	OR.W	d2,d1
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fin_sd_ovfl_dis

*
* the move in MAY overflow. so...
*
fin_sd_may_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FMOVE.X	EXC_LV+FP_SCR0(a6),fp0	* perform the move

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#2,fp1	* is |result| >= 2.b?
	fbge.w	fin_sd_ovfl_tst	* yes; overflow has occurred

* no, it didn't overflow; we have correct result
	BRA	fin_sd_normal_exit

**-------------------------------------------------------------------------------------------------*

*
* operand is not a NORM: check its optype and branch accordingly
*
fin_not_norm:
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fin_denorm
	CMP.b	#SNAN,d1	* weed out SNANs
	BEQ	res_snan_1op
	CMP.B	#QNAN,d1	* weed out QNANs
	BEQ	res_qnan_1op

*
* do the fmove in; at this point, only possible ops are ZERO and INF.
* use fmov to determine ccodes.
* prec:mode should be zero at this point but it won't affect answer anyways.
*
	FMOVE.X	SRC(a0),fp0	* do fmove in
	FMOVE.L	fpsr,d0	* no exceptions possible
	rol.l	#$8,d0	* put ccodes in lo byte
	MOVE.B	d0,EXC_LV+FPSR_CC(a6)	* insert correct ccodes
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	fdiv(): emulates the fdiv instruction
*	fsdiv(): emulates the fsdiv instruction
*	fddiv(): emulates the fddiv instruction
*
* xdef **
*	scale_to_zero_src() - scale src exponent to zero
*	scale_to_zero_dst() - scale dst exponent to zero
*	unf_res() - return default underflow result
*	ovf_res() - return default overflow result
* 	res_qnan() - return QNAN result
* 	res_snan() - return SNAN result
*
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	a1 = pointer to extended precision destination operand
*	d0  rnd prec,mode
*
* OUTPUT **************************************************************
*	fp0 = result
*	fp1 = EXOP (if exception occurred)
*
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms/denorms into ext/sgl/dbl precision.
*	For norms/denorms, scale the exponents such that a divide
* instruction won't cause an exception. Use the regular fdiv to
* compute a result. Check if the regular operands would have taken
* an exception. If so, return the default overflow/underflow result
* and return the EXOP if exceptions are enabled. Else, scale the
* result operand to the proper exponent.
*
**-------------------------------------------------------------------------------------------------

	cnop	0,$10
tbl_fdiv_unfl:
	dc.l	$3fff - 0	* ext_unfl
	dc.l	$3fff - $3f81	* sgl_unfl
	dc.l	$3fff - $3c01	* dbl_unfl

tbl_fdiv_ovfl:
	dc.l	$3fff - $7ffe	* ext overflow exponent
	dc.l	$3fff - $407e	* sgl overflow exponent
	dc.l	$3fff - $43fe	* dbl overflow exponent

	xdef	fsdiv
fsdiv:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl prec
	BRA	fdiv

	xdef	fddiv
fddiv:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl prec

	xdef	fdiv
fdiv:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1	* combine src tags

	BNE	fdiv_not_norm	* optimize on non-norm input

*
* DIVIDE: NORMs and DENORMs ONLY!
*
fdiv_norm:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_to_zero_src	* scale src exponent
	MOVE.L	d0,-(sp)	* save scale factor 1

	BSR	scale_to_zero_dst	* scale dst exponent

	neg.l	(sp)	* SCALE FACTOR = scale1 - scale2
	ADD.L	d0,(sp)

	MOVE.W	2+EXC_LV+L_SCR3(a6),d1	* fetch precision
	lsr.b	#$6,d1	* shift to lo bits
	MOVE.L	(sp)+,d0	* load S.F.
	CMP.l	((tbl_fdiv_ovfl).b,pc,d1.w*4),d0 * will result overflow?
	ble.w	fdiv_may_ovfl	* result will overflow

	CMP.l	(tbl_fdiv_unfl.w,pc,d1.w*4),d0 * will result underflow?
	BEQ	fdiv_may_unfl	* maybe
	BGT	fdiv_unfl	* yes; go handle underflow

fdiv_normal:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* save FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp0	* perform divide

	FMOVE.L	fpsr,d1	* save FPSR
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fdiv_normal_exit:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store result on stack
	MOVE.L	d2,-(sp)	* store d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

tbl_fdiv_ovfl2:
	dc.l	$7fff
	dc.l	$407f
	dc.l	$43ff

fdiv_no_ovfl:
	MOVE.L	(sp)+,d0	* restore scale factor
	BRA	fdiv_normal_exit

fdiv_may_ovfl:
	MOVE.L	d0,-(sp)	* save scale factor

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* set FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute divide

	FMOVE.L	fpsr,d0
	FMOVE.L	#$0,fpcr

	OR.L	d0,EXC_LV+USER_FPSR(a6)	* save INEX,N

	FMOVEM.X	fp0,-(sp)	* save result to stack
	MOVE.W	(sp),d0	* fetch new exponent
	ADD.L	#$c,sp	* clear result from stack
	AND.L	#$7fff,d0	* strip sign
	SUB.L	(sp),d0	* add scale factor
	CMP.l	((tbl_fdiv_ovfl2).b,pc,d1.w*4),d0
	blt.b	fdiv_no_ovfl
	MOVE.L	(sp)+,d0

fdiv_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fdiv_ovfl_ena	* yes

fdiv_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6) 	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass prec:rnd
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

fdiv_ovfl_ena:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fdiv_ovfl_ena_sd	* no, do sgl or dbl

fdiv_ovfl_ena_cont:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* move result to stack

	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.W	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1	* clear sign bit
	AND.W	#$8000,d2	* keep old sign
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fdiv_ovfl_dis

fdiv_ovfl_ena_sd:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst operand

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* keep rnd mode
	FMOVE.L	d1,fpcr	* set FPCR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute divide

	FMOVE.L	#$0,fpcr	* clear FPCR
	BRA	fdiv_ovfl_ena_cont

fdiv_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute divide

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fdiv_unfl_ena	* yes

fdiv_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* 'Z' may have been set
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS

*
* UNFL is enabled.
*
fdiv_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fdiv_unfl_ena_sd	* no, sgl or dbl

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

fdiv_unfl_ena_cont:
	FMOVE.L	#$0,fpsr	* clear FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp1	* execute divide

	FMOVE.L	#$0,fpcr	* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* save result to stack
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factoer
	addi.l	#$6000,d1	* add bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exp
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fdiv_unfl_dis

fdiv_unfl_ena_sd:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* use only rnd mode
	FMOVE.L	d1,fpcr	* set FPCR

	BRA	fdiv_unfl_ena_cont

*
* the divide operation MAY underflow:
*
fdiv_may_unfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute divide

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#1,fp1	* is |result| > 1.b?
	fbgt.w	fdiv_normal_exit	* no; no underflow occurred
	fblt.w	fdiv_unfl	* yes; underflow occurred

*
* we still don't know if underflow occurred. result is ~ equal to 1. but,
* we don't know if the result was an underflow that rounded up to a 1
* or a normalized number that rounded down to a 1. so, redo the entire
* operation using RZ as the rounding mode to see what the pre-rounded
* result is. this case should be relatively rare.
*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op into fp1

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* keep rnd prec
	OR.B	#rz_mode*$10,d1	* insert RZ

	FMOVE.L	d1,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fdiv.x	EXC_LV+FP_SCR0(a6),fp1	* execute divide

	FMOVE.L	#$0,fpcr	* clear FPCR
	FABS.X	fp1	* make absolute value
	fcmp.b	#1,fp1	* is |result| < 1.b?
	fbge.w	fdiv_normal_exit	* no; no underflow occurred
	BRA	fdiv_unfl	* yes; underflow occurred

**-------------------------------------------------------------------------------------------------***

*
* Divide: inputs are not both normalized; what are they?
*
fdiv_not_norm:
	MOVE.W	((tbl_fdiv_op).b,pc,d1.w*2),d1
	jmp	((tbl_fdiv_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fdiv_op:
	dc.w	fdiv_norm	- tbl_fdiv_op * NORM / NORM
	dc.w	fdiv_inf_load	- tbl_fdiv_op * NORM / ZERO
	dc.w	fdiv_zero_load	- tbl_fdiv_op * NORM / INF
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * NORM / QNAN
	dc.w	fdiv_norm	- tbl_fdiv_op * NORM / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * NORM / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

	dc.w	fdiv_zero_load	- tbl_fdiv_op * ZERO / NORM
	dc.w	fdiv_res_operr	- tbl_fdiv_op * ZERO / ZERO
	dc.w	fdiv_zero_load	- tbl_fdiv_op * ZERO / INF
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * ZERO / QNAN
	dc.w	fdiv_zero_load	- tbl_fdiv_op * ZERO / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * ZERO / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

	dc.w	fdiv_inf_dst	- tbl_fdiv_op * INF / NORM
	dc.w	fdiv_inf_dst	- tbl_fdiv_op * INF / ZERO
	dc.w	fdiv_res_operr	- tbl_fdiv_op * INF / INF
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * INF / QNAN
	dc.w	fdiv_inf_dst	- tbl_fdiv_op * INF / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * INF / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

	dc.w	fdiv_res_qnan	- tbl_fdiv_op * QNAN / NORM
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * QNAN / ZERO
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * QNAN / INF
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * QNAN / QNAN
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * QNAN / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * QNAN / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

	dc.w	fdiv_norm	- tbl_fdiv_op * DENORM / NORM
	dc.w	fdiv_inf_load	- tbl_fdiv_op * DENORM / ZERO
	dc.w	fdiv_zero_load	- tbl_fdiv_op * DENORM / INF
	dc.w	fdiv_res_qnan	- tbl_fdiv_op * DENORM / QNAN
	dc.w	fdiv_norm	- tbl_fdiv_op * DENORM / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * DENORM / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / NORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / ZERO
	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / INF
	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / QNAN
	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / DENORM
	dc.w	fdiv_res_snan	- tbl_fdiv_op * SNAN / SNAN
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *
	dc.w	tbl_fdiv_op	- tbl_fdiv_op *

fdiv_res_qnan:
	BRA	res_qnan
fdiv_res_snan:
	BRA	res_snan
fdiv_res_operr:
	BRA	res_operr

	xdef	fdiv_zero_load	* xdef for fsgldiv
fdiv_zero_load:
	MOVE.B	SRC_EX(a0),d0	* result sign is exclusive
	MOVE.B	DST_EX(a1),d1	* or of input signs.
	EOR.B	d0,d1
	BPL	fdiv_zero_load_p	* result is positive
	fmove.s	#$80000000,fp0	* load a -ZERO
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6)	* set Z/N
	RTS
fdiv_zero_load_p:
	fmove.s	#$00000000,fp0	* load a +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS

*
* The destination was In Range and the source was a ZERO. The result,
* therefore, is an INF w/ the proper sign.
* So, determine the sign and return a new INF (w/ the j-bit cleared).
*
	xdef	fdiv_inf_load	* xdef for fsgldiv
fdiv_inf_load:
	ori.w	#dz_mask+adz_mask,2+EXC_LV+USER_FPSR(a6) * no; set DZ/ADZ
	MOVE.B	SRC_EX(a0),d0	* load both signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	BPL	fdiv_inf_load_p	* result is positive
	fmove.s	#$ff800000,fp0	* make result -INF
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set INF/N
	RTS
fdiv_inf_load_p:
	fmove.s	#$7f800000,fp0	* make result +INF
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set INF
	RTS

*
* The destination was an INF w/ an In Range or ZERO source, the result is
* an INF w/ the proper sign.
* The 68881/882 returns the destination INF w/ the new sign(if the j-bit of the
* dst INF is set, then then j-bit of the result INF is also set).
*
	xdef	fdiv_inf_dst	* xdef for fsgldiv
fdiv_inf_dst:
	MOVE.B	DST_EX(a1),d0	* load both signs
	MOVE.B	SRC_EX(a0),d1
	EOR.B	d0,d1
	BPL	fdiv_inf_dst_p	* result is positive

	FMOVEM.X	DST(a1),fp0	* return result in fp0
	FABS.X	fp0	* clear sign bit
	FNEG.X	fp0	* set sign bit
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set INF/NEG
	RTS

fdiv_inf_dst_p:
	FMOVEM.X	DST(a1),fp0	* return result in fp0
	FABS.X	fp0	* return positive INF
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6) * set INF
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fneg(): emulates the fneg instruction
*	fsneg(): emulates the fsneg instruction
*	fdneg(): emulates the fdneg instruction
*
* xdef **
* 	norm() - normalize a denorm to provide EXOP
*	scale_to_zero_src() - scale sgl/dbl source exponent
*	ovf_res() - return default overflow result
*	unf_res() - return default underflow result
* 	res_qnan_1op() - return QNAN result
*	res_snan_1op() - return SNAN result
*
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	d0 = rnd prec,mode
*
* OUTPUT **************************************************************
*	fp0 = result
*	fp1 = EXOP (if exception occurred)
*
* ALGORITHM ***********************************************************
*	Handle NANs, zeroes, and infinities as special cases. Separate
* norms/denorms into ext/sgl/dbl precisions. Extended precision can be
* emulated by simply setting sign bit. Sgl/dbl operands must be scaled
* and an actual fneg performed to see if overflow/underflow would have
* occurred. If so, return default underflow/overflow result. Else,
* scale the result exponent and return result. FPSR gets set based on
* the result value.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	fsneg
fsneg:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl precision
	BRA	fneg

	xdef	fdneg
fdneg:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl prec

	xdef	fneg
fneg:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	fneg_not_norm	* optimize on non-norm input
	
*
* NEGATE SIGN : norms and denorms ONLY!
*
fneg_norm:
	AND.B	#$c0,d0	* is precision extended?
	BNE	fneg_not_ext	* no; go handle sgl or dbl

*
* precision selected is extended. so...we can not get an underflow
* or overflow because of rounding to the correct precision. so...
* skip the scaling and unscaling...
*
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.W	SRC_EX(a0),d0
	eori.w	#$8000,d0	* negate sign
	BPL	fneg_norm_load	* sign is positive
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
fneg_norm_load:
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

*
* for an extended precision DENORM, the UNFL exception bit is set
* the accrued bit is NOT set in this instance(no inexactness!)
*
fneg_denorm:
	AND.B	#$c0,d0	* is precision extended?
	BNE	fneg_not_ext	* no; go handle sgl or dbl

	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.W	SRC_EX(a0),d0
	eori.w	#$8000,d0	* negate sign
	BPL	fneg_denorm_done	* no
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* yes, set 'N' ccode bit
fneg_denorm_done:
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0

	BTST	#unfl_bit,EXC_LV+FPCR_ENABLE(a6) * is UNFL enabled?
	BNE	fneg_ext_unfl_ena	* yes
	RTS

*
* the input is an extended DENORM and underflow is enabled in the FPCR.
* normalize the mantissa and add the bias of $6000 to the resulting negative
* exponent and insert back into the operand.
*
fneg_ext_unfl_ena:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: ptr to operand
	BSR	norm	* normalize result
	neg.w	d0	* new exponent = -(shft val)
	addi.w	#$6000,d0	* add new bias to exponent
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch old sign,exp
	AND.W	#$8000,d1	 	* keep old sign
	AND.W	#$7fff,d0	* clear sign position
	OR.W	d1,d0	* concat old sign, new exponent
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	RTS

*
* operand is either single or double
*
fneg_not_ext:
	CMP.b	#s_mode*$10,d0	* separate sgl/dbl prec
	BNE	fneg_dbl

*
* operand is to be rounded to single precision
*
fneg_sgl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* calculate scale factor

	CMP.l	#$3fff-$3f80,d0		* will move in underflow?
	bge.w	fneg_sd_unfl		* yes; go handle underflow
	CMP.l	#$3fff-$407e,d0		* will move in overflow?
	BEQ	fneg_sd_may_ovfl	* maybe; go check
	BLT	fneg_sd_ovfl	* yes; go handle overflow

*
* operand will NOT overflow or underflow when moved in to the fp reg file
*
fneg_sd_normal:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FNEG.X	EXC_LV+FP_SCR0(a6),fp0	* perform negation

	FMOVE.L	fpsr,d1	* save FPSR
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fneg_sd_normal_exit:
	MOVE.L	d2,-(sp)	* save d2
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load sgn,exp
	MOVE.W	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	AND.W	#$8000,d2	* keep old sign
	OR.W	d1,d2	* concat old sign,new exp
	MOVE.W	d2,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

*
* operand is to be rounded to double precision
*
fneg_dbl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* calculate scale factor

	CMP.l	#$3fff-$3c00,d0	* will move in underflow?
	bge.b	fneg_sd_unfl	* yes; go handle underflow
	CMP.l	#$3fff-$43fe,d0	* will move in overflow?
	BEQ	fneg_sd_may_ovfl	* maybe; go check
	BLT	fneg_sd_ovfl	* yes; go handle overflow
	BRA	fneg_sd_normal	* no; ho handle normalized op

*
* operand WILL underflow when moved in to the fp register file
*
fneg_sd_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	eori.b	#$80,EXC_LV+FP_SCR0_EX(a6)	* negate sign
	BPL	fneg_sd_unfl_tst
	BSET	#neg_bit,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit

* if underflow or inexact is enabled, go calculate EXOP first.
fneg_sd_unfl_tst:
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fneg_sd_unfl_ena	* yes

fneg_sd_unfl_dis:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* unf_res may have set 'Z'
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS	

*
* operand will underflow AND underflow is enabled. 
* therefore, we must return the result rounded to extended precision.
*
fneg_sd_unfl_ena:
	MOVE.L	EXC_LV+FP_SCR0_HI(a6),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	EXC_LV+FP_SCR0_LO(a6),EXC_LV+FP_SCR1_LO(a6)
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load current exponent

	MOVE.L	d2,-(sp)	* save d2
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* subtract scale factor
	addi.l	#$6000,d1	* add new bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat new sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR1_EX(a6)	* insert new exp
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fneg_sd_unfl_dis

*
* operand WILL overflow.
*
fneg_sd_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FNEG.X	EXC_LV+FP_SCR0(a6),fp0	* perform negation

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save FPSR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fneg_sd_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fneg_sd_ovfl_ena	* yes

*
* OVFL is not enabled; therefore, we must create the default result by
* calling ovf_res().
*
fneg_sd_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass: prec,mode
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

*
* OVFL is enabled.
* the INEX2 bit has already been updated by the round to the correct precision.
* now, round to extended(and don't alter the FPSR).
*
fneg_sd_ovfl_ena:
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat sign,exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fneg_sd_ovfl_dis

*
* the move in MAY underflow. so...
*
fneg_sd_may_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FNEG.X	EXC_LV+FP_SCR0(a6),fp0	* perform negation

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#2,fp1	* is |result| >= 2.b?
	fbge.w	fneg_sd_ovfl_tst	* yes; overflow has occurred

* no, it didn't overflow; we have correct result
	BRA	fneg_sd_normal_exit

**-------------------------------------------------------------------------------------------------*

*
* input is not normalized; what is it?
*
fneg_not_norm:
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fneg_denorm
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	CMP.B	#QNAN,d1	* weed out QNAN
	BEQ	res_qnan_1op

*
* do the fneg; at this point, only possible ops are ZERO and INF.
* use fneg to determine ccodes.
* prec:mode should be zero at this point but it won't affect answer anyways.
*
	FNEG.X	SRC_EX(a0),fp0	* do fneg
	FMOVE.L	fpsr,d0
	rol.l	#$8,d0	* put ccodes in lo byte
	MOVE.B	d0,EXC_LV+FPSR_CC(a6)	* insert correct ccodes
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	ftst(): emulates the ftst instruction
*		
* xdef **
* 	res{s,q}nan_1op() - set NAN result for monadic instruction
*		
* INPUT ***************************************************************
* 	a0 = pointer to extended precision source operand
*		
* OUTPUT **************************************************************
*	none	
*
* ALGORITHM ***********************************************************
* 	Check the source operand tag (EXC_LV+STAG) and set the FPCR according
* to the operand type and sign.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	ftst
ftst:
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	ftst_not_norm	* optimize on non-norm input
	
*
* Norm:
*
ftst_norm:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.b	ftst_norm_m	* yes
	RTS
ftst_norm_m:
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	RTS

*
* input is not normalized; what is it?
*
ftst_not_norm:
	CMP.B	#ZERO,d1	* weed out ZERO
	BEQ	ftst_zero
	CMP.B	#INF,d1	* weed out INF
	BEQ	ftst_inf
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	CMP.B	#QNAN,d1	* weed out QNAN
	BEQ	res_qnan_1op

*
* Denorm:
*
ftst_denorm:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.b	ftst_denorm_m	* yes
	RTS
ftst_denorm_m:
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	RTS

*
* Infinity:
*
ftst_inf:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.b	ftst_inf_m	* yes
ftst_inf_p:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'I' ccode bit
	RTS
ftst_inf_m:
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set 'I','N' ccode bits
	RTS
	
*
* Zero:
*
ftst_zero:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.b	ftst_zero_m	* yes
ftst_zero_p:
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	RTS
ftst_zero_m:
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z','N' ccode bits
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fint(): emulates the fint instruction
*		
* xdef **
*	res_{s,q}nan_1op() - set NAN result for monadic operation
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	d0 = round precision/mode	
*		
* OUTPUT **************************************************************
*	fp0 = result	
*		
* ALGORITHM ***********************************************************
* 	Separate according to operand type. Unnorms don't pass through 
* here. For norms, load the rounding mode/prec, execute a "fint", then 
* store the resulting FPSR bits.	
* 	For denorms, force the j-bit to a one and do the same as for
* norms. Denorms are so low that the answer will either be a zero or a 
* one.		
* 	For zeroes/infs/NANs, return the same while setting the FPSR
* as appropriate.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	fint
fint:
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	fint_not_norm	* optimize on non-norm input
	
*
* Norm:
*
fint_norm:
	AND.B	#$30,d0	* set prec = ext

	FMOVE.L	d0,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fint.x 	SRC(a0),fp0	* execute fint

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d0	* save FPSR
	OR.L	d0,EXC_LV+USER_FPSR(a6)	* set exception bits

	RTS

*
* input is not normalized; what is it?
*
fint_not_norm:
	CMP.B	#ZERO,d1	* weed out ZERO
	BEQ	fint_zero
	CMP.B	#INF,d1	* weed out INF
	BEQ	fint_inf
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fint_denorm
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	BRA	res_qnan_1op	* weed out QNAN

*
* Denorm:
*
* for DENORMs, the result will be either (+/-)ZERO or (+/-)1.
* also, the INEX2 and AINEX exception bits will be set.
* so, we could either set these manually or force the DENORM
* to a very small NORM and ship it to the NORM routine.
* I do the latter.
*
fint_denorm:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6) * copy sign, zero exp
	MOVE.B	#$80,EXC_LV+FP_SCR0_HI(a6)	* force DENORM ==> small NORM
	LEA	EXC_LV+FP_SCR0(a6),a0
	BRA	fint_norm

*
* Zero:
*
fint_zero:
	TST.B	SRC_EX(a0)	* is ZERO negative?
	bmi.b	fint_zero_m	* yes
fint_zero_p:
	fmove.s	#$00000000,fp0	* return +ZERO in fp0
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS
fint_zero_m:
	fmove.s	#$80000000,fp0	* return -ZERO in fp0
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set 'Z','N' ccode bits
	RTS

*
* Infinity:
*
fint_inf:
	FMOVEM.X	SRC(a0),fp0	* return result in fp0
	TST.B	SRC_EX(a0)	* is INF negative?
	bmi.b	fint_inf_m	* yes
fint_inf_p:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'I' ccode bit
	RTS
fint_inf_m:
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set 'N','I' ccode bits
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fintrz(): emulates the fintrz instruction
*		
* xdef **
*	res_{s,q}nan_1op() - set NAN result for monadic operation
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	d0 = round precision/mode	
*		
* OUTPUT **************************************************************
* 	fp0 = result	
*		
* ALGORITHM ***********************************************************
*	Separate according to operand type. Unnorms don't pass through
* here. For norms, load the rounding mode/prec, execute a "fintrz", 
* then store the resulting FPSR bits.	
* 	For denorms, force the j-bit to a one and do the same as for
* norms. Denorms are so low that the answer will either be a zero or a
* one.		
* 	For zeroes/infs/NANs, return the same while setting the FPSR
* as appropriate.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	fintrz
fintrz:
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	fintrz_not_norm	* optimize on non-norm input
	
*
* Norm:
*
fintrz_norm:
	FMOVE.L	#$0,fpsr	* clear FPSR

	fintrz.x	SRC(a0),fp0	* execute fintrz

	FMOVE.L	fpsr,d0	* save FPSR
	OR.L	d0,EXC_LV+USER_FPSR(a6)	* set exception bits

	RTS

*
* input is not normalized; what is it?
*
fintrz_not_norm:
	CMP.B	#ZERO,d1	* weed out ZERO
	BEQ	fintrz_zero
	CMP.B	#INF,d1	* weed out INF
	BEQ	fintrz_inf
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fintrz_denorm
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	BRA	res_qnan_1op	* weed out QNAN

*
* Denorm:
*
* for DENORMs, the result will be (+/-)ZERO.
* also, the INEX2 and AINEX exception bits will be set.
* so, we could either set these manually or force the DENORM
* to a very small NORM and ship it to the NORM routine.
* I do the latter.
*
fintrz_denorm:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6) * copy sign, zero exp
	MOVE.B	#$80,EXC_LV+FP_SCR0_HI(a6)	* force DENORM ==> small NORM
	LEA	EXC_LV+FP_SCR0(a6),a0
	BRA	fintrz_norm

*
* Zero:
*
fintrz_zero:
	TST.B	SRC_EX(a0)	* is ZERO negative?
	bmi.b	fintrz_zero_m	* yes
fintrz_zero_p:
	fmove.s	#$00000000,fp0	* return +ZERO in fp0
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS
fintrz_zero_m:
	fmove.s	#$80000000,fp0	* return -ZERO in fp0
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set 'Z','N' ccode bits
	RTS

*
* Infinity:
*
fintrz_inf:
	FMOVEM.X	SRC(a0),fp0	* return result in fp0
	TST.B	SRC_EX(a0)	* is INF negative?
	bmi.b	fintrz_inf_m	* yes
fintrz_inf_p:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'I' ccode bit
	RTS
fintrz_inf_m:
	MOVE.B	#inf_bmask+neg_bmask,EXC_LV+FPSR_CC(a6) * set 'N','I' ccode bits
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fabs():  emulates the fabs instruction
*	fsabs(): emulates the fsabs instruction
*	fdabs(): emulates the fdabs instruction
*		
* xdef ** *
*	norm() - normalize denorm mantissa to provide EXOP
*	scale_to_zero_src() - make exponent. = 0; get scale factor
*	unf_res() - calculate underflow result
*	ovf_res() - calculate overflow result
*	res_{s,q}nan_1op() - set NAN result for monadic operation
*		
* INPUT *************************************************************** *
*	a0 = pointer to extended precision source operand
*	d0 = rnd precision/mode	
*		
* OUTPUT ************************************************************** *
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms into extended, single, and double precision. 
* 	Simply clear sign for extended precision norm. Ext prec denorm
* gets an EXOP created for it since it's an underflow.
*	Double and single precision can overflow and underflow. First,
* scale the operand such that the exponent is zero. Perform an "fabs"
* using the correct rnd mode/prec. Check to see if the original 
* exponent would take an exception. If so, use unf_res() or ovf_res()
* to calculate the default result. Also, create the EXOP for the
* exceptional case. If no exception should occur, insert the correct 
* result exponent and return.	
* 	Unnorms don't pass through here.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fsabs
fsabs:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl precision
	BRA	fabs

	xdef	fdabs
fdabs:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl precision

	xdef	fabs
fabs:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	fabs_not_norm	* optimize on non-norm input
	
*
* ABSOLUTE VALUE: norms and denorms ONLY!
*
fabs_norm:
	AND.B	#$c0,d0	* is precision extended?
	BNE	fabs_not_ext	* no; go handle sgl or dbl

*
* precision selected is extended. so...we can not get an underflow
* or overflow because of rounding to the correct precision. so...
* skip the scaling and unscaling...
*
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.W	SRC_EX(a0),d1
	bclr	#15,d1	* force absolute value
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

*
* for an extended precision DENORM, the UNFL exception bit is set
* the accrued bit is NOT set in this instance(no inexactness!)
*
fabs_denorm:
	AND.B	#$c0,d0	* is precision extended?
	BNE	fabs_not_ext	* no

	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.W	SRC_EX(a0),d0
	bclr	#15,d0	* clear sign
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert exponent

	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0

	BTST	#unfl_bit,EXC_LV+FPCR_ENABLE(a6) * is UNFL enabled?
	BNE	fabs_ext_unfl_ena
	RTS

*
* the input is an extended DENORM and underflow is enabled in the FPCR.
* normalize the mantissa and add the bias of $6000 to the resulting negative
* exponent and insert back into the operand.
*
fabs_ext_unfl_ena:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: ptr to operand
	BSR	norm	* normalize result
	neg.w	d0	* new exponent = -(shft val)
	addi.w	#$6000,d0	* add new bias to exponent
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch old sign,exp
	AND.W	#$8000,d1	* keep old sign
	AND.W	#$7fff,d0	* clear sign position
	OR.W	d1,d0	* concat old sign, new exponent
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	RTS

*
* operand is either single or double
*
fabs_not_ext:
	CMP.b	#s_mode*$10,d0	* separate sgl/dbl prec
	BNE	fabs_dbl

*
* operand is to be rounded to single precision
*
fabs_sgl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* calculate scale factor

	CMP.l	#$3fff-$3f80,d0	* will move in underflow?
	bge.w	fabs_sd_unfl	* yes; go handle underflow
	CMP.l	#$3fff-$407e,d0	* will move in overflow?
	BEQ	fabs_sd_may_ovfl	* maybe; go check
	BLT	fabs_sd_ovfl	* yes; go handle overflow

*
* operand will NOT overflow or underflow when moved in to the fp reg file
*
fabs_sd_normal:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FABS.X	EXC_LV+FP_SCR0(a6),fp0	* perform absolute

	FMOVE.L	fpsr,d1	* save FPSR
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fabs_sd_normal_exit:
	MOVE.L	d2,-(sp)	* save d2
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load sgn,exp
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	AND.W	#$8000,d2	* keep old sign
	OR.W	d1,d2	* concat old sign,new exp
	MOVE.W	d2,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

*
* operand is to be rounded to double precision
*
fabs_dbl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* calculate scale factor

	CMP.l	#$3fff-$3c00,d0	* will move in underflow?
	bge.b	fabs_sd_unfl	* yes; go handle underflow
	CMP.l	#$3fff-$43fe,d0	* will move in overflow?
	BEQ	fabs_sd_may_ovfl	* maybe; go check
	BLT	fabs_sd_ovfl	* yes; go handle overflow
	BRA	fabs_sd_normal	* no; ho handle normalized op

*
* operand WILL underflow when moved in to the fp register file
*
fabs_sd_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	bclr	#$7,EXC_LV+FP_SCR0_EX(a6)	* force absolute value

* if underflow or inexact is enabled, go calculate EXOP first.
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fabs_sd_unfl_ena	* yes

fabs_sd_unfl_dis:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set possible 'Z' ccode
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS	

*
* operand will underflow AND underflow is enabled.
* therefore, we must return the result rounded to extended precision.
*
fabs_sd_unfl_ena:
	MOVE.L	EXC_LV+FP_SCR0_HI(a6),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	EXC_LV+FP_SCR0_LO(a6),EXC_LV+FP_SCR1_LO(a6)
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load current exponent

	MOVE.L	d2,-(sp)	* save d2
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* subtract scale factor
	addi.l	#$6000,d1	* add new bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat new sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR1_EX(a6)	* insert new exp
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fabs_sd_unfl_dis

*
* operand WILL overflow.
*
fabs_sd_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FABS.X	EXC_LV+FP_SCR0(a6),fp0	* perform absolute

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save FPSR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fabs_sd_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fabs_sd_ovfl_ena	* yes

*
* OVFL is not enabled; therefore, we must create the default result by
* calling ovf_res().
*
fabs_sd_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass: prec,mode
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

*
* OVFL is enabled.
* the INEX2 bit has already been updated by the round to the correct precision.
* now, round to extended(and don't alter the FPSR).
*
fabs_sd_ovfl_ena:
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat sign,exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fabs_sd_ovfl_dis

*
* the move in MAY underflow. so...
*
fabs_sd_may_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	FABS.X	EXC_LV+FP_SCR0(a6),fp0	* perform absolute

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#2,fp1	* is |result| >= 2.b?
	fbge.w	fabs_sd_ovfl_tst	* yes; overflow has occurred

* no, it didn't overflow; we have correct result
	BRA	fabs_sd_normal_exit

**-------------------------------------------------------------------------------------------------*

*
* input is not normalized; what is it?
*
fabs_not_norm:
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fabs_denorm
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	CMP.B	#QNAN,d1	* weed out QNAN
	BEQ	res_qnan_1op

	FABS.X	SRC(a0),fp0	* force absolute value

	CMP.B	#INF,d1	* weed out INF
	BEQ	fabs_inf
fabs_zero:
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS
fabs_inf:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'I' ccode bit
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	fcmp(): fp compare op routine	
*		
* xdef **
* 	res_qnan() - return QNAN result	
*	res_snan() - return SNAN result	
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	a1 = pointer to extended precision destination operand
*	d0 = round prec/mode	
*		
* OUTPUT ************************************************************** *
*	None	
*		
* ALGORITHM ***********************************************************
* 	Handle NANs and denorms as special cases. For everything else,
* just use the actual fcmp instruction to produce the correct condition
* codes.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	fcmp
fcmp:
	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1
	BNE	fcmp_not_norm	* optimize on non-norm input
	
*
* COMPARE FP OPs : NORMs, ZEROs, INFs, and "corrected" DENORMs
*
fcmp_norm:
	FMOVEM.X	DST(a1),fp0	* load dst op

	fcmp.x 	SRC(a0),fp0	* do compare

	FMOVE.L	fpsr,d0	* save FPSR
	rol.l	#$8,d0	* extract ccode bits
	MOVE.B	d0,EXC_LV+FPSR_CC(a6)	* set ccode bits(no exc bits are set)

	RTS

*
* fcmp: inputs are not both normalized; what are they?
*
fcmp_not_norm:
	MOVE.W	((tbl_fcmp_op).b,pc,d1.w*2),d1
	jmp	((tbl_fcmp_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fcmp_op:
	dc.w	fcmp_norm	- tbl_fcmp_op * NORM - NORM
	dc.w	fcmp_norm	- tbl_fcmp_op * NORM - ZERO
	dc.w	fcmp_norm	- tbl_fcmp_op * NORM - INF
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * NORM - QNAN
	dc.w	fcmp_nrm_dnrm 	- tbl_fcmp_op * NORM - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * NORM - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

	dc.w	fcmp_norm	- tbl_fcmp_op * ZERO - NORM
	dc.w	fcmp_norm	- tbl_fcmp_op * ZERO - ZERO
	dc.w	fcmp_norm	- tbl_fcmp_op * ZERO - INF
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * ZERO - QNAN
	dc.w	fcmp_dnrm_s	- tbl_fcmp_op * ZERO - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * ZERO - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

	dc.w	fcmp_norm	- tbl_fcmp_op * INF - NORM
	dc.w	fcmp_norm	- tbl_fcmp_op * INF - ZERO
	dc.w	fcmp_norm	- tbl_fcmp_op * INF - INF
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * INF - QNAN
	dc.w	fcmp_dnrm_s	- tbl_fcmp_op * INF - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * INF - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

	dc.w	fcmp_res_qnan	- tbl_fcmp_op * QNAN - NORM
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * QNAN - ZERO
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * QNAN - INF
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * QNAN - QNAN
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * QNAN - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * QNAN - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

	dc.w	fcmp_dnrm_nrm	- tbl_fcmp_op * DENORM - NORM
	dc.w	fcmp_dnrm_d	- tbl_fcmp_op * DENORM - ZERO
	dc.w	fcmp_dnrm_d	- tbl_fcmp_op * DENORM - INF
	dc.w	fcmp_res_qnan	- tbl_fcmp_op * DENORM - QNAN
	dc.w	fcmp_dnrm_sd	- tbl_fcmp_op * DENORM - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * DENORM - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - NORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - ZERO
	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - INF
	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - QNAN
	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - DENORM
	dc.w	fcmp_res_snan	- tbl_fcmp_op * SNAN - SNAN
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *
	dc.w	tbl_fcmp_op	- tbl_fcmp_op *

* unlike all other functions for QNAN and SNAN, fcmp does NOT set the
* 'N' bit for a negative QNAN or SNAN input so we must squelch it here.
fcmp_res_qnan:
	BSR	res_qnan
	AND.B	#$f7,EXC_LV+FPSR_CC(a6)
	RTS
fcmp_res_snan:
	BSR	res_snan
	AND.B	#$f7,EXC_LV+FPSR_CC(a6)
	RTS

*
* DENORMs are a little more difficult. 
* If you have a 2 DENORMs, then you can just force the j-bit to a one 
* and use the fcmp_norm routine.
* If you have a DENORM and an INF or ZERO, just force the DENORM's j-bit to a one
* and use the fcmp_norm routine.
* If you have a DENORM and a NORM with opposite signs, then use fcmp_norm, also.
* But with a DENORM and a NORM of the same sign, the neg bit is set if the
* (1) signs are (+) and the DENORM is the dst or
* (2) signs are (-) and the DENORM is the src
*

fcmp_dnrm_s:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),d0
	BSET	#31,d0	* DENORM src; make into small norm
	MOVE.L	d0,EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	LEA	EXC_LV+FP_SCR0(a6),a0
	BRA	fcmp_norm

fcmp_dnrm_d:
	MOVE.L	DST_EX(a1),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	DST_HI(a1),d0
	BSET	#31,d0	* DENORM src; make into small norm
	MOVE.L	d0,EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR0_LO(a6)
	LEA	EXC_LV+FP_SCR0(a6),a1
	BRA	fcmp_norm

fcmp_dnrm_sd:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	DST_HI(a1),d0
	BSET	#31,d0	* DENORM dst; make into small norm
	MOVE.L	d0,EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	SRC_HI(a0),d0
	BSET	#31,d0	* DENORM dst; make into small norm
	MOVE.L	d0,EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	LEA	EXC_LV+FP_SCR1(a6),a1
	LEA	EXC_LV+FP_SCR0(a6),a0
	BRA	fcmp_norm	

fcmp_nrm_dnrm:
	MOVE.B	SRC_EX(a0),d0	* determine if like signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	bmi.w	fcmp_dnrm_s

* signs are the same, so must determine the answer ourselves.
	TST.B	d0	* is src op negative?
	bmi.b	fcmp_nrm_dnrm_m	* yes
	RTS
fcmp_nrm_dnrm_m:
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS

fcmp_dnrm_nrm:
	MOVE.B	SRC_EX(a0),d0	* determine if like signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	bmi.w	fcmp_dnrm_d

* signs are the same, so must determine the answer ourselves.
	TST.B	d0	* is src op negative?
	BPL	fcmp_dnrm_nrm_m	* no
	RTS
fcmp_dnrm_nrm_m:
	MOVE.B	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	fsglmul(): emulates the fsglmul instruction
*		
* xdef **
*	scale_to_zero_src() - scale src exponent to zero
*	scale_to_zero_dst() - scale dst exponent to zero
*	unf_res4() - return default underflow result for sglop
*	ovf_res() - return default overflow result
* 	res_qnan() - return QNAN result	
* 	res_snan() - return SNAN result	
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	a1 = pointer to extended precision destination operand
*	d0  rnd prec,mode	
*		
* OUTPUT **************************************************************
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms/denorms into ext/sgl/dbl precision.
*	For norms/denorms, scale the exponents such that a multiply
* instruction won't cause an exception. Use the regular fsglmul to
* compute a result. Check if the regular operands would have taken
* an exception. If so, return the default overflow/underflow result
* and return the EXOP if exceptions are enabled. Else, scale the 
* result operand to the proper exponent.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fsglmul
fsglmul:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1

	BNE	fsglmul_not_norm	* optimize on non-norm input

fsglmul_norm:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_to_zero_src	* scale exponent
	MOVE.L	d0,-(sp)	* save scale factor 1

	BSR	scale_to_zero_dst	* scale dst exponent

	ADD.L	(sp)+,d0	* SCALE_FACTOR = scale1 + scale2

	CMP.l	#$3fff-$7ffe,d0 	* would result ovfl?
	BEQ	fsglmul_may_ovfl	* result may rnd to overflow
	BLT	fsglmul_ovfl	* result will overflow

	CMP.l	#$3fff+$0001,d0 	* would result unfl?
	BEQ	fsglmul_may_unfl	* result may rnd to no unfl
	BGT	fsglmul_unfl	* result will underflow

fsglmul_normal:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl multiply

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fsglmul_normal_exit:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

fsglmul_ovfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl multiply

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fsglmul_ovfl_tst:

* save setting this until now because this is where fsglmul_may_ovfl may jump in
	OR.L	#ovfl_inx_mask, EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fsglmul_ovfl_ena	* yes

fsglmul_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass prec:rnd
	AND.B	#$30,d0	* force prec = ext
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

fsglmul_ovfl_ena:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* move result to stack

	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1
	AND.W	#$8000,d2	* keep old sign
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fsglmul_ovfl_dis

fsglmul_may_ovfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl multiply
	
	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#2,fp1	* is |result| >= 2.b?
	fbge.w	fsglmul_ovfl_tst	* yes; overflow has occurred
	
* no, it didn't overflow; we have correct result
	BRA	fsglmul_normal_exit

fsglmul_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl multiply

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fsglmul_unfl_ena	* yes

fsglmul_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res4	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* 'Z' bit may have been set
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS

*
* UNFL is enabled. 
*
fsglmul_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp1	* execute sgl multiply	

	FMOVE.L	#$0,fpcr	* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* save result to stack
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	addi.l	#$6000,d1	* add bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fsglmul_unfl_dis

fsglmul_may_unfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl multiply	

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#2,fp1	* is |result| > 2.b?
	fbgt.w	fsglmul_normal_exit	* no; no underflow occurred
	fblt.w	fsglmul_unfl	* yes; underflow occurred

*
* we still don't know if underflow occurred. result is ~ equal to 2. but,
* we don't know if the result was an underflow that rounded up to a 2 or
* a normalized number that rounded down to a 2. so, redo the entire operation
* using RZ as the rounding mode to see what the pre-rounded result is.
* this case should be relatively rare.
*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op into fp1

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* keep rnd prec
	OR.B	#rz_mode*$10,d1	* insert RZ
	
	FMOVE.L	d1,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsglmul.x	EXC_LV+FP_SCR0(a6),fp1	* execute sgl multiply	

	FMOVE.L	#$0,fpcr	* clear FPCR
	FABS.X	fp1	* make absolute value
	fcmp.b	#2,fp1	* is |result| < 2.b?
	fbge.w	fsglmul_normal_exit	* no; no underflow occurred
	BRA	fsglmul_unfl	* yes, underflow occurred

**-------------------------------------------------------------------------------------------------*****

*
* Single Precision Multiply: inputs are not both normalized; what are they?
*
fsglmul_not_norm:
	MOVE.W	((tbl_fsglmul_op).b,pc,d1.w*2),d1
	jmp	((tbl_fsglmul_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fsglmul_op:
	dc.w	fsglmul_norm	- tbl_fsglmul_op * NORM x NORM
	dc.w	fsglmul_zero	- tbl_fsglmul_op * NORM x ZERO
	dc.w	fsglmul_inf_src	- tbl_fsglmul_op * NORM x INF
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * NORM x QNAN
	dc.w	fsglmul_norm	- tbl_fsglmul_op * NORM x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * NORM x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

	dc.w	fsglmul_zero	- tbl_fsglmul_op * ZERO x NORM
	dc.w	fsglmul_zero	- tbl_fsglmul_op * ZERO x ZERO
	dc.w	fsglmul_res_operr	- tbl_fsglmul_op * ZERO x INF
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * ZERO x QNAN
	dc.w	fsglmul_zero	- tbl_fsglmul_op * ZERO x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * ZERO x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

	dc.w	fsglmul_inf_dst	- tbl_fsglmul_op * INF x NORM
	dc.w	fsglmul_res_operr	- tbl_fsglmul_op * INF x ZERO
	dc.w	fsglmul_inf_dst	- tbl_fsglmul_op * INF x INF
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * INF x QNAN
	dc.w	fsglmul_inf_dst	- tbl_fsglmul_op * INF x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * INF x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * QNAN x NORM
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * QNAN x ZERO
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * QNAN x INF
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * QNAN x QNAN
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * QNAN x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * QNAN x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

	dc.w	fsglmul_norm	- tbl_fsglmul_op * NORM x NORM
	dc.w	fsglmul_zero	- tbl_fsglmul_op * NORM x ZERO
	dc.w	fsglmul_inf_src	- tbl_fsglmul_op * NORM x INF
	dc.w	fsglmul_res_qnan	- tbl_fsglmul_op * NORM x QNAN
	dc.w	fsglmul_norm	- tbl_fsglmul_op * NORM x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * NORM x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x NORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x ZERO
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x INF
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x QNAN
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x DENORM
	dc.w	fsglmul_res_snan	- tbl_fsglmul_op * SNAN x SNAN
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *
	dc.w	tbl_fsglmul_op	- tbl_fsglmul_op *

fsglmul_res_operr:
	BRA	res_operr
fsglmul_res_snan:
	BRA	res_snan
fsglmul_res_qnan:
	BRA	res_qnan
fsglmul_zero:
	BRA	fmul_zero
fsglmul_inf_src:
	BRA	fmul_inf_src
fsglmul_inf_dst:
	BRA	fmul_inf_dst

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	fsgldiv(): emulates the fsgldiv instruction
*		
* xdef **
*	scale_to_zero_src() - scale src exponent to zero
*	scale_to_zero_dst() - scale dst exponent to zero
*	unf_res4() - return default underflow result for sglop
*	ovf_res() - return default overflow result
* 	res_qnan() - return QNAN result	
* 	res_snan() - return SNAN result	
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	a1 = pointer to extended precision destination operand
*	d0  rnd prec,mode	
*		
* OUTPUT **************************************************************
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms/denorms into ext/sgl/dbl precision.
*	For norms/denorms, scale the exponents such that a divide
* instruction won't cause an exception. Use the regular fsgldiv to
* compute a result. Check if the regular operands would have taken
* an exception. If so, return the default overflow/underflow result
* and return the EXOP if exceptions are enabled. Else, scale the 
* result operand to the proper exponent.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fsgldiv
fsgldiv:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1	* combine src tags

	BNE	fsgldiv_not_norm	* optimize on non-norm input
	
*
* DIVIDE: NORMs and DENORMs ONLY!
*
fsgldiv_norm:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_to_zero_src	* calculate scale factor 1
	MOVE.L	d0,-(sp)	* save scale factor 1

	BSR	scale_to_zero_dst	* calculate scale factor 2

	neg.l	(sp)	* S.F. = scale1 - scale2
	ADD.L	d0,(sp)

	MOVE.W	2+EXC_LV+L_SCR3(a6),d1	* fetch precision,mode
	lsr.b	#$6,d1
	MOVE.L	(sp)+,d0
	CMP.l	#$3fff-$7ffe,d0
	ble.w	fsgldiv_may_ovfl

	CMP.l	#$3fff-0,d0 	* will result underflow?
	BEQ	fsgldiv_may_unfl	* maybe
	BGT	fsgldiv_unfl	* yes; go handle underflow

fsgldiv_normal:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* save FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp0	* perform sgl divide

	FMOVE.L	fpsr,d1	* save FPSR
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fsgldiv_normal_exit:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store result on stack
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

fsgldiv_may_ovfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* set FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute divide

	FMOVE.L	fpsr,d1
	FMOVE.L	#$0,fpcr

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX,N

	FMOVEM.X	fp0,-(sp)	* save result to stack
	MOVE.W	(sp),d1	* fetch new exponent
	ADD.L	#$c,sp	* clear result
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	CMP.l	#$7fff,d1	* did divide overflow?
	blt.b	fsgldiv_normal_exit

fsgldiv_ovfl_tst:
	OR.W	#ovfl_inx_mask,2+EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fsgldiv_ovfl_ena	* yes

fsgldiv_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6) 	* is result negative
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass prec:rnd
	AND.B	#$30,d0	* kill precision
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

fsgldiv_ovfl_ena:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* move result to stack

	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract new bias
	AND.W	#$7fff,d1	* clear ms bit
	OR.W	d2,d1	* concat old sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fsgldiv_ovfl_dis

fsgldiv_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl divide

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fsgldiv_unfl_ena	* yes

fsgldiv_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res4	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* 'Z' bit may have been set
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS

*
* UNFL is enabled. 
*
fsgldiv_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp1	* execute sgl divide

	FMOVE.L	#$0,fpcr	* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* save result to stack
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	addi.l	#$6000,d1	* add bias
	AND.W	#$7fff,d1	* clear top bit
	OR.W	d2,d1	* concat old sign, new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fsgldiv_unfl_dis

*
* the divide operation MAY underflow:
*
fsgldiv_may_unfl:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp0	* execute sgl divide

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FABS.X	fp0,fp1	* make a copy of result
	fcmp.b	#1,fp1	* is |result| > 1.b?
	fbgt.w	fsgldiv_normal_exit	* no; no underflow occurred
	fblt.w	fsgldiv_unfl	* yes; underflow occurred

*
* we still don't know if underflow occurred. result is ~ equal to 1. but,
* we don't know if the result was an underflow that rounded up to a 1
* or a normalized number that rounded down to a 1. so, redo the entire 
* operation using RZ as the rounding mode to see what the pre-rounded
* result is. this case should be relatively rare.
*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op into fp1

	clr.l	d1	* clear scratch register
	OR.B	#rz_mode*$10,d1	* force RZ rnd mode

	FMOVE.L	d1,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsgldiv.x	EXC_LV+FP_SCR0(a6),fp1	* execute sgl divide

	FMOVE.L	#$0,fpcr	* clear FPCR
	FABS.X	fp1	* make absolute value
	fcmp.b	#1,fp1	* is |result| < 1.b?
	fbge.w	fsgldiv_normal_exit	* no; no underflow occurred
	BRA	fsgldiv_unfl	* yes; underflow occurred

**-------------------------------------------------------------------------------------------------***

*
* Divide: inputs are not both normalized; what are they?
*
fsgldiv_not_norm:
	MOVE.W	((tbl_fsgldiv_op).b,pc,d1.w*2),d1
	jmp	((tbl_fsgldiv_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fsgldiv_op:
	dc.w	fsgldiv_norm	- tbl_fsgldiv_op * NORM / NORM
	dc.w	fsgldiv_inf_load	- tbl_fsgldiv_op * NORM / ZERO
	dc.w	fsgldiv_zero_load	- tbl_fsgldiv_op * NORM / INF
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * NORM / QNAN
	dc.w	fsgldiv_norm	- tbl_fsgldiv_op * NORM / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * NORM / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

	dc.w	fsgldiv_zero_load	- tbl_fsgldiv_op * ZERO / NORM
	dc.w	fsgldiv_res_operr	- tbl_fsgldiv_op * ZERO / ZERO
	dc.w	fsgldiv_zero_load	- tbl_fsgldiv_op * ZERO / INF
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * ZERO / QNAN
	dc.w	fsgldiv_zero_load	- tbl_fsgldiv_op * ZERO / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * ZERO / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

	dc.w	fsgldiv_inf_dst	- tbl_fsgldiv_op * INF / NORM
	dc.w	fsgldiv_inf_dst	- tbl_fsgldiv_op * INF / ZERO
	dc.w	fsgldiv_res_operr	- tbl_fsgldiv_op * INF / INF
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * INF / QNAN
	dc.w	fsgldiv_inf_dst	- tbl_fsgldiv_op * INF / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * INF / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * QNAN / NORM
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * QNAN / ZERO
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * QNAN / INF
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * QNAN / QNAN
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * QNAN / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * QNAN / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

	dc.w	fsgldiv_norm	- tbl_fsgldiv_op * DENORM / NORM
	dc.w	fsgldiv_inf_load	- tbl_fsgldiv_op * DENORM / ZERO
	dc.w	fsgldiv_zero_load	- tbl_fsgldiv_op * DENORM / INF
	dc.w	fsgldiv_res_qnan	- tbl_fsgldiv_op * DENORM / QNAN
	dc.w	fsgldiv_norm	- tbl_fsgldiv_op * DENORM / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * DENORM / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / NORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / ZERO
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / INF
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / QNAN
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / DENORM
	dc.w	fsgldiv_res_snan	- tbl_fsgldiv_op * SNAN / SNAN
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *
	dc.w	tbl_fsgldiv_op	- tbl_fsgldiv_op *

fsgldiv_res_qnan:
	BRA	res_qnan
fsgldiv_res_snan:
	BRA	res_snan
fsgldiv_res_operr:
	BRA	res_operr
fsgldiv_inf_load:
	BRA	fdiv_inf_load
fsgldiv_zero_load:
	BRA	fdiv_zero_load
fsgldiv_inf_dst:
	BRA	fdiv_inf_dst

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fadd(): emulates the fadd instruction
*	fsadd(): emulates the fadd instruction
*	fdadd(): emulates the fdadd instruction
*		
* xdef **
* 	addsub_scaler2() - scale the operands so they won't take exc
*	ovf_res() - return default overflow result
*	unf_res() - return default underflow result
*	res_qnan() - set QNAN result	
* 	res_snan() - set SNAN result	
*	res_operr() - set OPERR result	
*	scale_to_zero_src() - set src operand exponent equal to zero
*	scale_to_zero_dst() - set dst operand exponent equal to zero
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
* 	a1 = pointer to extended precision destination operand
*		
* OUTPUT **************************************************************
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
* 	Handle NANs, infinities, and zeroes as special cases. Divide
* norms into extended, single, and double precision.
*	Do addition after scaling exponents such that exception won't
* occur. Then, check result exponent to see if exception would have
* occurred. If so, return default result and maybe EXOP. Else, insert
* the correct result exponent and return. Set FPSR bits as appropriate.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fsadd
fsadd:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl prec
	BRA	fadd

	xdef	fdadd
fdadd:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl prec

	xdef	fadd
fadd:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1	* combine src tags

	BNE	fadd_not_norm	* optimize on non-norm input

*
* ADD: norms and denorms
*
fadd_norm:
	BSR	addsub_scaler2	* scale exponents

fadd_zero_entry:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	fadd.x	EXC_LV+FP_SCR0(a6),fp0	* execute add

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* fetch INEX2,N,Z

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save exc and ccode bits

	fbeq.w	fadd_zero_exit	* if result is zero, end now

	MOVE.L	d2,-(sp)	* save d2

	FMOVEM.X	fp0,-(sp)	* save result to stack

	MOVE.W	2+EXC_LV+L_SCR3(a6),d1
	lsr.b	#$6,d1

	MOVE.W	(sp),d2	* fetch new sign, exp
	AND.L	#$7fff,d2	* strip sign
	SUB.L	d0,d2	* add scale factor

	CMP.l	((tbl_fadd_ovfl).b,pc,d1.w*4),d2 * is it an overflow?
	bge.b	fadd_ovfl	* yes

	CMP.l	((tbl_fadd_unfl).b,pc,d1.w*4),d2 * is it an underflow?
	BLT	fadd_unfl	* yes
	BEQ	fadd_may_unfl	* maybe; go find out

fadd_normal:
	MOVE.W	(sp),d1
	AND.W	#$8000,d1	* keep sign
	OR.W	d2,d1	* concat sign,new exp
	MOVE.W	d1,(sp)	* insert new exponent

	FMOVEM.X	(sp)+,fp0	* return result in fp0

	MOVE.L	(sp)+,d2	* restore d2
	RTS

fadd_zero_exit:
*	fmove.s	#$00000000,fp0	* return zero in fp0
	RTS

tbl_fadd_ovfl:
	dc.l	$7fff	* ext ovfl
	dc.l	$407f	* sgl ovfl
	dc.l	$43ff	* dbl ovfl

tbl_fadd_unfl:
	dc.l	        0	* ext unfl
	dc.l	$3f81	* sgl unfl
	dc.l	$3c01	* dbl unfl

fadd_ovfl:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fadd_ovfl_ena	* yes

	ADD.L	#$c,sp
fadd_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass prec:rnd
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	MOVE.L	(sp)+,d2	* restore d2
	RTS

fadd_ovfl_ena:
	MOVE.B	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fadd_ovfl_ena_sd	* no; prec = sgl or dbl

fadd_ovfl_ena_cont:
	MOVE.W	(sp),d1
	AND.W	#$8000,d1	* keep sign
	SUB.L	#$6000,d2	* add extra bias
	AND.W	#$7fff,d2
	OR.W	d2,d1	* concat sign,new exp
	MOVE.W	d1,(sp)	* insert new exponent

	FMOVEM.X	(sp)+,fp1	* return EXOP in fp1
	BRA	fadd_ovfl_dis

fadd_ovfl_ena_sd:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* keep rnd mode
	FMOVE.L	d1,fpcr	* set FPCR

	fadd.x	EXC_LV+FP_SCR0(a6),fp0	* execute add

	FMOVE.L	#$0,fpcr	* clear FPCR

	ADD.L	#$c,sp
	FMOVEM.X	fp0,-(sp)
	BRA	fadd_ovfl_ena_cont

fadd_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	ADD.L	#$c,sp

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fadd.x	EXC_LV+FP_SCR0(a6),fp0	* execute add

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save status

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX,N

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fadd_unfl_ena	* yes

fadd_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* 'Z' bit may have been set
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	MOVE.L	(sp)+,d2	* restore d2
	RTS

fadd_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fadd_unfl_ena_sd	* no; sgl or dbl

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

fadd_unfl_ena_cont:
	FMOVE.L	#$0,fpsr	* clear FPSR

	fadd.x	EXC_LV+FP_SCR0(a6),fp1	* execute multiply

	FMOVE.L	#$0,fpcr	* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* save result to stack
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	addi.l	#$6000,d1	* add new bias
	AND.W	#$7fff,d1	* clear top bit
	OR.W	d2,d1	* concat sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fadd_unfl_dis

fadd_unfl_ena_sd:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* use only rnd mode
	FMOVE.L	d1,fpcr	* set FPCR

	BRA	fadd_unfl_ena_cont

*
* result is equal to the smallest normalized number in the selected precision
* if the precision is extended, this result could not have come from an 
* underflow that rounded up.
*
fadd_may_unfl:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1
	BEQ	fadd_normal	* yes; no underflow occurred

	MOVE.L	$4(sp),d1	* extract hi(man)
	CMP.l	#$80000000,d1	* is hi(man) = $80000000?
	BNE	fadd_normal	* no; no underflow occurred

	tst.l	$8(sp)	* is lo(man) = $0?
	BNE	fadd_normal	* no; no underflow occurred

	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6) * is INEX2 set?
	BEQ	fadd_normal	* no; no underflow occurred

*
* ok, so now the result has a exponent equal to the smallest normalized
* exponent for the selected precision. also, the mantissa is equal to
* $8000000000000000 and this mantissa is the result of rounding non-zero
* g,r,s. 
* now, we must determine whether the pre-rounded result was an underflow
* rounded "up" or a normalized number rounded "down".
* so, we do this be re-executing the add using RZ as the rounding mode and
* seeing if the new result is smaller or equal to the current result.
*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op into fp1

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* keep rnd prec
	OR.B	#rz_mode*$10,d1	* insert rnd mode
	FMOVE.L	d1,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fadd.x	EXC_LV+FP_SCR0(a6),fp1	* execute add

	FMOVE.L	#$0,fpcr	* clear FPCR

	FABS.X	fp0	* compare absolute values
	FABS.X	fp1
	fcmp.x	fp0,fp1	* is first result > second?

	fbgt.w	fadd_unfl	* yes; it's an underflow
	BRA	fadd_normal	* no; it's not an underflow

**-------------------------------------------------------------------------------------------------*

*
* Add: inputs are not both normalized; what are they?
*
fadd_not_norm:
	MOVE.W	((tbl_fadd_op).b,pc,d1.w*2),d1
	jmp	((tbl_fadd_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fadd_op:
	dc.w	fadd_norm	- tbl_fadd_op * NORM + NORM
	dc.w	fadd_zero_src	- tbl_fadd_op * NORM + ZERO
	dc.w	fadd_inf_src	- tbl_fadd_op * NORM + INF
	dc.w	fadd_res_qnan	- tbl_fadd_op * NORM + QNAN
	dc.w	fadd_norm	- tbl_fadd_op * NORM + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * NORM + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

	dc.w	fadd_zero_dst	- tbl_fadd_op * ZERO + NORM
	dc.w	fadd_zero_2	- tbl_fadd_op * ZERO + ZERO
	dc.w	fadd_inf_src	- tbl_fadd_op * ZERO + INF
	dc.w	fadd_res_qnan	- tbl_fadd_op * NORM + QNAN
	dc.w	fadd_zero_dst	- tbl_fadd_op * ZERO + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * NORM + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

	dc.w	fadd_inf_dst	- tbl_fadd_op * INF + NORM
	dc.w	fadd_inf_dst	- tbl_fadd_op * INF + ZERO
	dc.w	fadd_inf_2	- tbl_fadd_op * INF + INF
	dc.w	fadd_res_qnan	- tbl_fadd_op * NORM + QNAN
	dc.w	fadd_inf_dst	- tbl_fadd_op * INF + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * NORM + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

	dc.w	fadd_res_qnan	- tbl_fadd_op * QNAN + NORM
	dc.w	fadd_res_qnan	- tbl_fadd_op * QNAN + ZERO
	dc.w	fadd_res_qnan	- tbl_fadd_op * QNAN + INF
	dc.w	fadd_res_qnan	- tbl_fadd_op * QNAN + QNAN
	dc.w	fadd_res_qnan	- tbl_fadd_op * QNAN + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * QNAN + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

	dc.w	fadd_norm	- tbl_fadd_op * DENORM + NORM
	dc.w	fadd_zero_src	- tbl_fadd_op * DENORM + ZERO
	dc.w	fadd_inf_src	- tbl_fadd_op * DENORM + INF
	dc.w	fadd_res_qnan	- tbl_fadd_op * NORM + QNAN
	dc.w	fadd_norm	- tbl_fadd_op * DENORM + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * NORM + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + NORM
	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + ZERO
	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + INF
	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + QNAN
	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + DENORM
	dc.w	fadd_res_snan	- tbl_fadd_op * SNAN + SNAN
	dc.w	tbl_fadd_op	- tbl_fadd_op *
	dc.w	tbl_fadd_op	- tbl_fadd_op *

fadd_res_qnan:
	BRA	res_qnan
fadd_res_snan:
	BRA	res_snan

*
* both operands are ZEROes
*
fadd_zero_2:
	MOVE.B	SRC_EX(a0),d0	* are the signs opposite
	MOVE.B	DST_EX(a1),d1
	EOR.B	d0,d1
	bmi.w	fadd_zero_2_chk_rm	* weed out (-ZERO)+(+ZERO)

* the signs are the same. so determine whether they are positive or negative
* and return the appropriately signed zero.
	TST.B	d0	* are ZEROes positive or negative?
	bmi.b	fadd_zero_rm	* negative
	fmove.s	#$00000000,fp0	* return +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS
	
*
* the ZEROes have opposite signs:
* - therefore, we return +ZERO if the rounding modes are RN,RZ, or RP.
* - -ZERO is returned in the case of RM.
*
fadd_zero_2_chk_rm:
	MOVE.B	3+EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* extract rnd mode
	CMP.b	#rm_mode*$10,d1		* is rnd mode == RM?
	BEQ	fadd_zero_rm	* yes
	fmove.s	#$00000000,fp0	* return +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS

fadd_zero_rm:
	fmove.s	#$80000000,fp0	* return -ZERO
	MOVE.B	#neg_bmask+z_bmask,EXC_LV+FPSR_CC(a6) * set NEG/Z
	RTS

*
* one operand is a ZERO and the other is a DENORM or NORM. scale
* the DENORM or NORM and jump to the regular fadd routine.
*
fadd_zero_dst:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* scale the operand
	clr.w	EXC_LV+FP_SCR1_EX(a6)
	clr.l	EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)
	BRA	fadd_zero_entry	* go execute fadd

fadd_zero_src:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)
	BSR	scale_to_zero_dst	* scale the operand
	clr.w	EXC_LV+FP_SCR0_EX(a6)
	clr.l	EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)
	BRA	fadd_zero_entry	* go execute fadd

*
* both operands are INFs. an OPERR will result if the INFs have
* different signs. else, an INF of the same sign is returned
*
fadd_inf_2:
	MOVE.B	SRC_EX(a0),d0	* exclusive or the signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d1,d0
	bmi.l	res_operr	* weed out (-INF)+(+INF)

* ok, so it's not an OPERR. but, we do have to remember to return the 
* src INF since that's where the 881/882 gets the j-bit from...

*
* operands are INF and one of {ZERO, INF, DENORM, NORM}
*
fadd_inf_src:
	FMOVEM.X	SRC(a0),fp0	* return src INF
	TST.B	SRC_EX(a0)	* is INF positive?
	BPL	fadd_inf_done	* yes; we're done
	MOVE.B	#neg_bmask+inf_bmask,EXC_LV+FPSR_CC(a6) * set INF/NEG
	RTS

*
* operands are INF and one of {ZERO, INF, DENORM, NORM}
*
fadd_inf_dst:
	FMOVEM.X	DST(a1),fp0	* return dst INF
	TST.B	DST_EX(a1)	* is INF positive?
	BPL	fadd_inf_done	* yes; we're done
	MOVE.B	#neg_bmask+inf_bmask,EXC_LV+FPSR_CC(a6) * set INF/NEG
	RTS

fadd_inf_done:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6) * set INF
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
*	fsub(): emulates the fsub instruction
*	fssub(): emulates the fssub instruction
*	fdsub(): emulates the fdsub instruction
*		
* xdef **
* 	addsub_scaler2() - scale the operands so they won't take exc
*	ovf_res() - return default overflow result
*	unf_res() - return default underflow result
*	res_qnan() - set QNAN result	
* 	res_snan() - set SNAN result	
*	res_operr() - set OPERR result	
*	scale_to_zero_src() - set src operand exponent equal to zero
*	scale_to_zero_dst() - set dst operand exponent equal to zero
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
* 	a1 = pointer to extended precision destination operand
*		
* OUTPUT **************************************************************
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
* 	Handle NANs, infinities, and zeroes as special cases. Divide
* norms into extended, single, and double precision.
*	Do subtraction after scaling exponents such that exception won't*
* occur. Then, check result exponent to see if exception would have
* occurred. If so, return default result and maybe EXOP. Else, insert
* the correct result exponent and return. Set FPSR bits as appropriate.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fssub
fssub:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl prec
	BRA	fsub

	xdef	fdsub
fdsub:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl prec

	xdef	fsub
fsub:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info

	clr.w	d1
	MOVE.B	EXC_LV+DTAG(a6),d1
	lsl.b	#$3,d1
	OR.B	EXC_LV+STAG(a6),d1	* combine src tags

	BNE	fsub_not_norm	* optimize on non-norm input

*
* SUB: norms and denorms
*
fsub_norm:
	BSR	addsub_scaler2	* scale exponents

fsub_zero_entry:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	fsub.x	EXC_LV+FP_SCR0(a6),fp0	* execute subtract

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* fetch INEX2, N, Z

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save exc and ccode bits

	fbeq.w	fsub_zero_exit	* if result zero, end now

	MOVE.L	d2,-(sp)	* save d2

	FMOVEM.X	fp0,-(sp)	* save result to stack

	MOVE.W	2+EXC_LV+L_SCR3(a6),d1
	lsr.b	#$6,d1

	MOVE.W	(sp),d2	* fetch new exponent
	AND.L	#$7fff,d2	* strip sign
	SUB.L	d0,d2	* add scale factor

	CMP.l	((tbl_fsub_ovfl).b,pc,d1.w*4),d2 * is it an overflow?
	bge.b	fsub_ovfl	* yes

	CMP.l	((tbl_fsub_unfl).b,pc,d1.w*4),d2 * is it an underflow?
	BLT	fsub_unfl	* yes
	BEQ	fsub_may_unfl	* maybe; go find out

fsub_normal:
	MOVE.W	(sp),d1
	AND.W	#$8000,d1	* keep sign
	OR.W	d2,d1	* insert new exponent
	MOVE.W	d1,(sp)	* insert new exponent

	FMOVEM.X	(sp)+,fp0	* return result in fp0

	MOVE.L	(sp)+,d2	* restore d2
	RTS

fsub_zero_exit:
*	fmove.s	#$00000000,fp0	* return zero in fp0
	RTS

tbl_fsub_ovfl:
	dc.l	$7fff	* ext ovfl
	dc.l	$407f	* sgl ovfl
	dc.l	$43ff	* dbl ovfl

tbl_fsub_unfl:
	dc.l	        0	* ext unfl
	dc.l	$3f81	* sgl unfl
	dc.l	$3c01	* dbl unfl

fsub_ovfl:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fsub_ovfl_ena	* yes

	ADD.L	#$c,sp
fsub_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass prec:rnd
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	MOVE.L	(sp)+,d2	* restore d2
	RTS

fsub_ovfl_ena:
	MOVE.B	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fsub_ovfl_ena_sd	* no

fsub_ovfl_ena_cont:
	MOVE.W	(sp),d1	* fetch {sgn,exp}
	AND.W	#$8000,d1	* keep sign
	SUB.L	#$6000,d2	* subtract new bias
	AND.W	#$7fff,d2	* clear top bit
	OR.W	d2,d1	* concat sign,exp
	MOVE.W	d1,(sp)	* insert new exponent

	FMOVEM.X	(sp)+,fp1	* return EXOP in fp1
	BRA	fsub_ovfl_dis

fsub_ovfl_ena_sd:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* clear rnd prec
	FMOVE.L	d1,fpcr	* set FPCR

	fsub.x	EXC_LV+FP_SCR0(a6),fp0	* execute subtract

	FMOVE.L	#$0,fpcr	* clear FPCR

	ADD.L	#$c,sp
	FMOVEM.X	fp0,-(sp)
	BRA	fsub_ovfl_ena_cont

fsub_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	ADD.L	#$c,sp

	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp0	* load dst op
	
	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsub.x	EXC_LV+FP_SCR0(a6),fp0	* execute subtract

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save status

	OR.L	d1,EXC_LV+USER_FPSR(a6)

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fsub_unfl_ena	* yes

fsub_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* 'Z' may have been set
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	MOVE.L	(sp)+,d2	* restore d2
	RTS

fsub_unfl_ena:
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* is precision extended?
	BNE	fsub_unfl_ena_sd	* no

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

fsub_unfl_ena_cont:
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsub.x	EXC_LV+FP_SCR0(a6),fp1	* execute subtract

	FMOVE.L	#$0,fpcr	* clear FPCR

	FMOVEM.X	fp1,EXC_LV+FP_SCR0(a6)	* store result to stack
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	addi.l	#$6000,d1	* subtract new bias
	AND.W	#$7fff,d1	* clear top bit
	OR.W	d2,d1	* concat sgn,exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	BRA	fsub_unfl_dis

fsub_unfl_ena_sd:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* clear rnd prec
	FMOVE.L	d1,fpcr	* set FPCR

	BRA	fsub_unfl_ena_cont

*
* result is equal to the smallest normalized number in the selected precision
* if the precision is extended, this result could not have come from an
* underflow that rounded up.
*
fsub_may_unfl:
	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* fetch rnd prec
	BEQ	fsub_normal	* yes; no underflow occurred

	MOVE.L	$4(sp),d1
	CMP.l	#$80000000,d1	* is hi(man) = $80000000?
	BNE	fsub_normal	* no; no underflow occurred

	tst.l	$8(sp)	* is lo(man) = $0?
	BNE	fsub_normal	* no; no underflow occurred

	BTST	#inex2_bit,EXC_LV+FPSR_EXCEPT(a6) * is INEX2 set?
	BEQ	fsub_normal	* no; no underflow occurred

*
* ok, so now the result has a exponent equal to the smallest normalized
* exponent for the selected precision. also, the mantissa is equal to
* $8000000000000000 and this mantissa is the result of rounding non-zero
* g,r,s. 
* now, we must determine whether the pre-rounded result was an underflow
* rounded "up" or a normalized number rounded "down".
* so, we do this be re-executing the add using RZ as the rounding mode and
* seeing if the new result is smaller or equal to the current result.
*
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* load dst op into fp1

	MOVE.L	EXC_LV+L_SCR3(a6),d1
	AND.B	#$c0,d1	* keep rnd prec
	OR.B	#rz_mode*$10,d1	* insert rnd mode
	FMOVE.L	d1,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsub.x	EXC_LV+FP_SCR0(a6),fp1	* execute subtract

	FMOVE.L	#$0,fpcr	* clear FPCR

	FABS.X	fp0	* compare absolute values
	FABS.X	fp1
	fcmp.x	fp0,fp1	* is first result > second?

	fbgt.w	fsub_unfl	* yes; it's an underflow
	BRA	fsub_normal	* no; it's not an underflow

**-------------------------------------------------------------------------------------------------*

*
* Sub: inputs are not both normalized; what are they?
*
fsub_not_norm:
	MOVE.W	((tbl_fsub_op).b,pc,d1.w*2),d1
	jmp	((tbl_fsub_op).b,pc,d1.w*1)

	illegal
	dc.w	$48
tbl_fsub_op:
	dc.w	fsub_norm	- tbl_fsub_op * NORM - NORM
	dc.w	fsub_zero_src	- tbl_fsub_op * NORM - ZERO
	dc.w	fsub_inf_src	- tbl_fsub_op * NORM - INF
	dc.w	fsub_res_qnan	- tbl_fsub_op * NORM - QNAN
	dc.w	fsub_norm	- tbl_fsub_op * NORM - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * NORM - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

	dc.w	fsub_zero_dst	- tbl_fsub_op * ZERO - NORM
	dc.w	fsub_zero_2	- tbl_fsub_op * ZERO - ZERO
	dc.w	fsub_inf_src	- tbl_fsub_op * ZERO - INF
	dc.w	fsub_res_qnan	- tbl_fsub_op * NORM - QNAN
	dc.w	fsub_zero_dst	- tbl_fsub_op * ZERO - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * NORM - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

	dc.w	fsub_inf_dst	- tbl_fsub_op * INF - NORM
	dc.w	fsub_inf_dst	- tbl_fsub_op * INF - ZERO
	dc.w	fsub_inf_2	- tbl_fsub_op * INF - INF
	dc.w	fsub_res_qnan	- tbl_fsub_op * NORM - QNAN
	dc.w	fsub_inf_dst	- tbl_fsub_op * INF - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * NORM - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

	dc.w	fsub_res_qnan	- tbl_fsub_op * QNAN - NORM
	dc.w	fsub_res_qnan	- tbl_fsub_op * QNAN - ZERO
	dc.w	fsub_res_qnan	- tbl_fsub_op * QNAN - INF
	dc.w	fsub_res_qnan	- tbl_fsub_op * QNAN - QNAN
	dc.w	fsub_res_qnan	- tbl_fsub_op * QNAN - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * QNAN - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

	dc.w	fsub_norm	- tbl_fsub_op * DENORM - NORM
	dc.w	fsub_zero_src	- tbl_fsub_op * DENORM - ZERO
	dc.w	fsub_inf_src	- tbl_fsub_op * DENORM - INF
	dc.w	fsub_res_qnan	- tbl_fsub_op * NORM - QNAN
	dc.w	fsub_norm	- tbl_fsub_op * DENORM - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * NORM - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - NORM
	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - ZERO
	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - INF
	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - QNAN
	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - DENORM
	dc.w	fsub_res_snan	- tbl_fsub_op * SNAN - SNAN
	dc.w	tbl_fsub_op	- tbl_fsub_op *
	dc.w	tbl_fsub_op	- tbl_fsub_op *

fsub_res_qnan:
	BRA	res_qnan
fsub_res_snan:
	BRA	res_snan

*
* both operands are ZEROes
*
fsub_zero_2:
	MOVE.B	SRC_EX(a0),d0
	MOVE.B	DST_EX(a1),d1
	EOR.B	d1,d0
	BPL	fsub_zero_2_chk_rm

* the signs are opposite, so, return a ZERO w/ the sign of the dst ZERO
	TST.B	d0	* is dst negative?
	bmi.b	fsub_zero_2_rm	* yes
	fmove.s	#$00000000,fp0	* no; return +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS

*
* the ZEROes have the same signs:
* - therefore, we return +ZERO if the rounding mode is RN,RZ, or RP
* - -ZERO is returned in the case of RM.
*
fsub_zero_2_chk_rm:
	MOVE.B	3+EXC_LV+L_SCR3(a6),d1
	AND.B	#$30,d1	* extract rnd mode
	CMP.b	#rm_mode*$10,d1	* is rnd mode = RM?
	BEQ	fsub_zero_2_rm	* yes
	fmove.s	#$00000000,fp0	* no; return +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set Z
	RTS

fsub_zero_2_rm:
	fmove.s	#$80000000,fp0	* return -ZERO
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6)	* set Z/NEG
	RTS

*
* one operand is a ZERO and the other is a DENORM or a NORM.
* scale the DENORM or NORM and jump to the regular fsub routine.
*
fsub_zero_dst:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	BSR	scale_to_zero_src	* scale the operand
	clr.w	EXC_LV+FP_SCR1_EX(a6)
	clr.l	EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)
	BRA	fsub_zero_entry	* go execute fsub

fsub_zero_src:
	MOVE.W	DST_EX(a1),EXC_LV+FP_SCR1_EX(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)
	BSR	scale_to_zero_dst	* scale the operand
	clr.w	EXC_LV+FP_SCR0_EX(a6)
	clr.l	EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)
	BRA	fsub_zero_entry	* go execute fsub

*
* both operands are INFs. an OPERR will result if the INFs have the
* same signs. else,
*
fsub_inf_2:
	MOVE.B	SRC_EX(a0),d0	* exclusive or the signs
	MOVE.B	DST_EX(a1),d1
	EOR.B	d1,d0
	bpl.l	res_operr	* weed out (-INF)+(+INF)

* ok, so it's not an OPERR. but we do have to remember to return
* the src INF since that's where the 881/882 gets the j-bit.

fsub_inf_src:
	FMOVEM.X	SRC(a0),fp0	* return src INF
	FNEG.X	fp0	* invert sign
	fbge.w	fsub_inf_done	* sign is now positive
	MOVE.B	#neg_bmask+inf_bmask,EXC_LV+FPSR_CC(a6) * set INF/NEG
	RTS

fsub_inf_dst:
	FMOVEM.X	DST(a1),fp0	* return dst INF
	TST.B	DST_EX(a1)	* is INF negative?
	BPL	fsub_inf_done	* no
	MOVE.B	#neg_bmask+inf_bmask,EXC_LV+FPSR_CC(a6) * set INF/NEG
	RTS

fsub_inf_done:
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set INF
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	fsqrt(): emulates the fsqrt instruction
*	fssqrt(): emulates the fssqrt instruction
*	fdsqrt(): emulates the fdsqrt instruction
*		
* xdef **
*	scale_sqrt() - scale the source operand
*	unf_res() - return default underflow result
*	ovf_res() - return default overflow result
* 	res_qnan_1op() - return QNAN result
* 	res_snan_1op() - return SNAN result
*
* INPUT ***************************************************************
*	a0 = pointer to extended precision source operand
*	d0  rnd prec,mode	
*		
* OUTPUT **************************************************************
*	fp0 = result	
*	fp1 = EXOP (if exception occurred)
*		
* ALGORITHM ***********************************************************
*	Handle NANs, infinities, and zeroes as special cases. Divide
* norms/denorms into ext/sgl/dbl precision.
*	For norms/denorms, scale the exponents such that a sqrt
* instruction won't cause an exception. Use the regular fsqrt to
* compute a result. Check if the regular operands would have taken
* an exception. If so, return the default overflow/underflow result
* and return the EXOP if exceptions are enabled. Else, scale the 
* result operand to the proper exponent.
*		
**-------------------------------------------------------------------------------------------------

	xdef	fssqrt
fssqrt:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#s_mode*$10,d0	* insert sgl precision
	BRA	fsqrt

	xdef	fdsqrt
fdsqrt:
	AND.B	#$30,d0	* clear rnd prec
	OR.B	#d_mode*$10,d0	* insert dbl precision

	xdef	fsqrt
fsqrt:
	MOVE.L	d0,EXC_LV+L_SCR3(a6)	* store rnd info
	clr.w	d1
	MOVE.B	EXC_LV+STAG(a6),d1
	BNE	fsqrt_not_norm	* optimize on non-norm input

*
* SQUARE ROOT: norms and denorms ONLY!
*
fsqrt_norm:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.l	res_operr	* yes

	AND.B	#$c0,d0	* is precision extended?
	BNE	fsqrt_not_ext	* no; go handle sgl or dbl

	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsqrt.x	(a0),fp0	* execute square root

	FMOVE.L	fpsr,d1
	OR.L	d1,EXC_LV+USER_FPSR(a6)	* set N,INEX

	RTS

fsqrt_denorm:
	TST.B	SRC_EX(a0)	* is operand negative?
	bmi.l	res_operr	* yes

	AND.B	#$c0,d0	* is precision extended?
	BNE	fsqrt_not_ext	* no; go handle sgl or dbl

	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_sqrt	* calculate scale factor

	BRA	fsqrt_sd_normal

*
* operand is either single or double
*
fsqrt_not_ext:
	CMP.b	#s_mode*$10,d0	* separate sgl/dbl prec
	BNE	fsqrt_dbl

*
* operand is to be rounded to single precision
*
fsqrt_sgl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_sqrt	* calculate scale factor

	CMP.l	#$3fff-$3f81,d0	* will move in underflow?
	BEQ	fsqrt_sd_may_unfl
	BGT	fsqrt_sd_unfl	* yes; go handle underflow
	CMP.l	#$3fff-$407f,d0	* will move in overflow?
	BEQ	fsqrt_sd_may_ovfl	* maybe; go check
	BLT	fsqrt_sd_ovfl	* yes; go handle overflow

*
* operand will NOT overflow or underflow when moved in to the fp reg file
*
fsqrt_sd_normal:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	fsqrt.x	EXC_LV+FP_SCR0(a6),fp0	* perform absolute

	FMOVE.L	fpsr,d1	* save FPSR
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fsqrt_sd_normal_exit:
	MOVE.L	d2,-(sp)	* save d2
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load sgn,exp
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	SUB.L	d0,d1	* add scale factor
	AND.W	#$8000,d2	* keep old sign
	OR.W	d1,d2	* concat old sign,new exp
	MOVE.W	d2,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	MOVE.L	(sp)+,d2	* restore d2
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return result in fp0
	RTS

*
* operand is to be rounded to double precision
*
fsqrt_dbl:
	MOVE.W	SRC_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)

	BSR	scale_sqrt	* calculate scale factor

	CMP.l	#$3fff-$3c01,d0	* will move in underflow?
	BEQ	fsqrt_sd_may_unfl
	bgt.b	fsqrt_sd_unfl	* yes; go handle underflow
	CMP.l	#$3fff-$43ff,d0	* will move in overflow?
	BEQ	fsqrt_sd_may_ovfl	* maybe; go check
	BLT	fsqrt_sd_ovfl	* yes; go handle overflow
	BRA	fsqrt_sd_normal	* no; ho handle normalized op

* we're on the line here and the distinguising characteristic is whether
* the exponent is 3fff or 3ffe. if it's 3ffe, then it's a safe number
* elsewise fall through to underflow.
fsqrt_sd_may_unfl:
	BTST	#$0,1+EXC_LV+FP_SCR0_EX(a6)	* is exponent $3fff?
	BNE	fsqrt_sd_normal	* yes, so no underflow

*
* operand WILL underflow when moved in to the fp register file
*
fsqrt_sd_unfl:
	BSET	#unfl_bit,EXC_LV+FPSR_EXCEPT(a6) * set unfl exc bit

	FMOVE.L	#rz_mode*$10,fpcr	* set FPCR
	FMOVE.L	#$0,fpsr	* clear FPSR

	fsqrt.x 	EXC_LV+FP_SCR0(a6),fp0	* execute square root

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

* if underflow or inexact is enabled, go calculate EXOP first.
	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$0b,d1	* is UNFL or INEX enabled?
	BNE	fsqrt_sd_unfl_ena	* yes

fsqrt_sd_unfl_dis:
	FMOVEM.X	fp0,EXC_LV+FP_SCR0(a6)	* store out result

	LEA	EXC_LV+FP_SCR0(a6),a0	* pass: result addr
	MOVE.L	EXC_LV+L_SCR3(a6),d1	* pass: rnd prec,mode
	BSR	unf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set possible 'Z' ccode
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp0	* return default result in fp0
	RTS	

*
* operand will underflow AND underflow is enabled. 
* therefore, we must return the result rounded to extended precision.
*
fsqrt_sd_unfl_ena:
	MOVE.L	EXC_LV+FP_SCR0_HI(a6),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	EXC_LV+FP_SCR0_LO(a6),EXC_LV+FP_SCR1_LO(a6)
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* load current exponent

	MOVE.L	d2,-(sp)	* save d2
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* subtract scale factor
	addi.l	#$6000,d1	* add new bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat new sign,new exp
	MOVE.W	d1,EXC_LV+FP_SCR1_EX(a6)	* insert new exp
	FMOVEM.X	EXC_LV+FP_SCR1(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fsqrt_sd_unfl_dis

*
* operand WILL overflow.
*
fsqrt_sd_ovfl:
	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	fsqrt.x	EXC_LV+FP_SCR0(a6),fp0	* perform square root

	FMOVE.L	#$0,fpcr	* clear FPCR
	FMOVE.L	fpsr,d1	* save FPSR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

fsqrt_sd_ovfl_tst:
	OR.L	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set ovfl/aovfl/ainex

	MOVE.B	EXC_LV+FPCR_ENABLE(a6),d1
	AND.B	#$13,d1	* is OVFL or INEX enabled?
	BNE	fsqrt_sd_ovfl_ena	* yes

*
* OVFL is not enabled; therefore, we must create the default result by
* calling ovf_res().
*
fsqrt_sd_ovfl_dis:
	BTST	#neg_bit,EXC_LV+FPSR_CC(a6)	* is result negative?
	sne	d1	* set sign param accordingly
	MOVE.L	EXC_LV+L_SCR3(a6),d0	* pass: prec,mode
	BSR	ovf_res	* calculate default result
	OR.B	d0,EXC_LV+FPSR_CC(a6)	* set INF,N if applicable
	FMOVEM.X	(a0),fp0	* return default result in fp0
	RTS

*
* OVFL is enabled.
* the INEX2 bit has already been updated by the round to the correct precision.
* now, round to extended(and don't alter the FPSR).
*
fsqrt_sd_ovfl_ena:
	MOVE.L	d2,-(sp)	* save d2
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* fetch {sgn,exp}
	MOVE.L	d1,d2	* make a copy
	AND.L	#$7fff,d1	* strip sign
	AND.W	#$8000,d2	* keep old sign
	SUB.L	d0,d1	* add scale factor
	SUB.L	#$6000,d1	* subtract bias
	AND.W	#$7fff,d1
	OR.W	d2,d1	* concat sign,exp
	MOVE.W	d1,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	FMOVEM.X	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	MOVE.L	(sp)+,d2	* restore d2
	BRA	fsqrt_sd_ovfl_dis

*
* the move in MAY underflow. so...
*
fsqrt_sd_may_ovfl:
	BTST	#$0,1+EXC_LV+FP_SCR0_EX(a6)	* is exponent $3fff?
	BNE	fsqrt_sd_ovfl	* yes, so overflow

	FMOVE.L	#$0,fpsr	* clear FPSR
	FMOVE.L	EXC_LV+L_SCR3(a6),fpcr	* set FPCR

	fsqrt.x	EXC_LV+FP_SCR0(a6),fp0	* perform absolute

	FMOVE.L	fpsr,d1	* save status
	FMOVE.L	#$0,fpcr	* clear FPCR

	OR.L	d1,EXC_LV+USER_FPSR(a6)	* save INEX2,N

	FMOVE.X	fp0,fp1	* make a copy of result
	fcmp.b	#1,fp1	* is |result| >= 1.b?
	fbge.w	fsqrt_sd_ovfl_tst	* yes; overflow has occurred

* no, it didn't overflow; we have correct result
	BRA	fsqrt_sd_normal_exit

**-------------------------------------------------------------------------------------------------*

*
* input is not normalized; what is it?
*
fsqrt_not_norm:
	CMP.B	#DENORM,d1	* weed out DENORM
	BEQ	fsqrt_denorm
	CMP.B	#ZERO,d1	* weed out ZERO
	BEQ	fsqrt_zero
	CMP.B	#INF,d1	* weed out INF
	BEQ	fsqrt_inf
	CMP.b	#SNAN,d1	* weed out SNAN
	BEQ	res_snan_1op
	BRA	res_qnan_1op

*
* 	fsqrt(+0) = +0
* 	fsqrt(-0) = -0
*	fsqrt(+INF) = +INF
* 	fsqrt(-INF) = OPERR
*
fsqrt_zero:
	TST.B	SRC_EX(a0)	* is ZERO positive or negative?
	bmi.b	fsqrt_zero_m	* negative
fsqrt_zero_p:	
	fmove.s	#$00000000,fp0	* return +ZERO
	MOVE.B	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	RTS
fsqrt_zero_m:
	fmove.s	#$80000000,fp0	* return -ZERO
	MOVE.B	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z','N' ccode bits
	RTS

fsqrt_inf:
	TST.B	SRC_EX(a0)	* is INF positive or negative?
	bmi.l	res_operr	* negative
fsqrt_inf_p:
	FMOVEM.X	SRC(a0),fp0	* return +INF in fp0
	MOVE.B	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'I' ccode bit
	RTS

**-------------------------------------------------------------------------------------------------*

**-------------------------------------------------------------------------------------------------
* XDEF **
*	addsub_scaler2(): scale inputs to fadd/fsub such that no
*	  OVFL/UNFL exceptions will result
*		
* xdef **
*	norm() - normalize mantissa after adjusting exponent
*		
* INPUT ***************************************************************
*	EXC_LV+FP_SRC(a6) = fp op1(src)	
*	EXC_LV+FP_DST(a6) = fp op2(dst)	
* 		
* OUTPUT **************************************************************
*	EXC_LV+FP_SRC(a6) = fp op1 scaled(src)	
*	EXC_LV+FP_DST(a6) = fp op2 scaled(dst)	
*	d0         = scale amount	
*		
* ALGORITHM ***********************************************************
* 	If the DST exponent is > the SRC exponent, set the DST exponent
* equal to $3fff and scale the SRC exponent by the value that the
* DST exponent was scaled by. If the SRC exponent is greater or equal,
* do the opposite. Return this scale factor in d0.
*	If the two exponents differ by > the number of mantissa bits
* plus two, then set the smallest exponent to a very small value as a
* quick shortcut.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	addsub_scaler2
addsub_scaler2:
	MOVE.L	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	MOVE.L	DST_HI(a1),EXC_LV+FP_SCR1_HI(a6)
	MOVE.L	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	MOVE.L	DST_LO(a1),EXC_LV+FP_SCR1_LO(a6)
	MOVE.W	SRC_EX(a0),d0
	MOVE.W	DST_EX(a1),d1
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)
	MOVE.W	d1,EXC_LV+FP_SCR1_EX(a6)

	AND.W	#$7fff,d0
	AND.W	#$7fff,d1
	MOVE.W	d0,EXC_LV+L_SCR1(a6)	* store src exponent
	MOVE.W	d1,2+EXC_LV+L_SCR1(a6)	* store dst exponent

	CMP.w	d1,d0			* is src exp >= dst exp?
	bge.l	src_exp_ge2

* dst exp is >  src exp; scale dst to exp = $3fff
dst_exp_gt2:
	BSR	scale_to_zero_dst
	MOVE.L	d0,-(sp)	* save scale factor

	CMP.b	#DENORM,EXC_LV+STAG(a6)	* is dst denormalized?
	BNE	cmpexp12

	LEA	EXC_LV+FP_SCR0(a6),a0
	BSR	norm	* normalize the denorm; result is new exp
	neg.w	d0	* new exp = -(shft val)
	MOVE.W	d0,EXC_LV+L_SCR1(a6)	* inset new exp

cmpexp12:
	MOVE.W	2+EXC_LV+L_SCR1(a6),d0
	subi.w	#mantissalen+2,d0	* subtract mantissalen+2 from larger exp

	CMP.w	EXC_LV+L_SCR1(a6),d0	* is difference >= len(mantissa)+2?
	bge.b	quick_scale12

	MOVE.W	EXC_LV+L_SCR1(a6),d0
	add.w	$2(sp),d0	* scale src exponent by scale factor
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1
	and.w	#$8000,d1
	OR.W	d1,d0	* concat {sgn,new exp}
	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new dst exponent

	MOVE.L	(sp)+,d0	* return SCALE factor
	RTS

quick_scale12:
	AND.W	#$8000,EXC_LV+FP_SCR0_EX(a6)	* zero src exponent
	BSET	#$0,1+EXC_LV+FP_SCR0_EX(a6)	* set exp = 1

	MOVE.L	(sp)+,d0	* return SCALE factor
	RTS

* src exp is >= dst exp; scale src to exp = $3fff
src_exp_ge2:
	BSR	scale_to_zero_src
	MOVE.L	d0,-(sp)	* save scale factor

	CMP.b	#DENORM,EXC_LV+DTAG(a6)	* is dst denormalized?
	BNE	cmpexp22
	LEA	EXC_LV+FP_SCR1(a6),a0
	BSR	norm	* normalize the denorm; result is new exp
	neg.w	d0	* new exp = -(shft val)
	MOVE.W	d0,2+EXC_LV+L_SCR1(a6)	* inset new exp

cmpexp22:
	MOVE.W	EXC_LV+L_SCR1(a6),d0
	subi.w	#mantissalen+2,d0	* subtract mantissalen+2 from larger exp

	CMP.w	2+EXC_LV+L_SCR1(a6),d0	* is difference >= len(mantissa)+2?
	bge.b	quick_scale22

	MOVE.W	2+EXC_LV+L_SCR1(a6),d0
	add.w	$2(sp),d0	* scale dst exponent by scale factor
	MOVE.W	EXC_LV+FP_SCR1_EX(a6),d1
	AND.W	#$8000,d1
	OR.W	d1,d0	* concat {sgn,new exp}
	MOVE.W	d0,EXC_LV+FP_SCR1_EX(a6)	* insert new dst exponent

	MOVE.L	(sp)+,d0	* return SCALE factor
	RTS

quick_scale22:
	AND.W	#$8000,EXC_LV+FP_SCR1_EX(a6)	* zero dst exponent
	BSET	#$0,1+EXC_LV+FP_SCR1_EX(a6)	* set exp = 1

	MOVE.L	(sp)+,d0	* return SCALE factor	
	RTS

**-------------------------------------------------------------------------------------------------*

**-------------------------------------------------------------------------------------------------
* XDEF **
*	scale_to_zero_src(): scale the exponent of extended precision
*	     value at EXC_LV+FP_SCR0(a6).
*		
* xdef **
*	norm() - normalize the mantissa if the operand was a DENORM
*		
* INPUT ***************************************************************
*	EXC_LV+FP_SCR0(a6) = extended precision operand to be scaled
* 		
* OUTPUT **************************************************************
*	EXC_LV+FP_SCR0(a6) = scaled extended precision operand
*	d0	    = scale value	
*		
* ALGORITHM ***********************************************************
* 	Set the exponent of the input operand to $3fff. Save the value
* of the difference between the original and new exponent. Then, 
* normalize the operand if it was a DENORM. Add this normalization
* value to the previous value. Return the result.
*		
**-------------------------------------------------------------------------------------------------

	xdef	scale_to_zero_src
scale_to_zero_src:
	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* extract operand's {sgn,exp}
	MOVE.W	d1,d0	* make a copy

	AND.L	#$7fff,d1	* extract operand's exponent

	AND.W	#$8000,d0	* extract operand's sgn
	OR.W	#$3fff,d0	* insert new operand's exponent(=0)

	MOVE.W	d0,EXC_LV+FP_SCR0_EX(a6)	* insert biased exponent

	CMP.b	#DENORM,EXC_LV+STAG(a6)	* is operand normalized?
	BEQ	stzs_denorm	* normalize the DENORM

stzs_norm:
	MOVE.L	#$3fff,d0
	SUB.L	d1,d0	* scale = BIAS + (-exp)

	RTS

stzs_denorm:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass ptr to src op
	BSR	norm	* normalize denorm
	neg.l	d0	* new exponent = -(shft val)
	MOVE.L	d0,d1	* prepare for op_norm call
	BRA	stzs_norm	* finish scaling

***

**-------------------------------------------------------------------------------------------------
* XDEF **
*	scale_sqrt(): scale the input operand exponent so a subsequent
*	      fsqrt operation won't take an exception.
*		
* xdef **
*	norm() - normalize the mantissa if the operand was a DENORM
*		
* INPUT ***************************************************************
*	EXC_LV+FP_SCR0(a6) = extended precision operand to be scaled
*
* OUTPUT **************************************************************
*	EXC_LV+FP_SCR0(a6) = scaled extended precision operand
*	d0	    = scale value	
*		
* ALGORITHM ***********************************************************
*	If the input operand is a DENORM, normalize it.
* 	If the exponent of the input operand is even, set the exponent
* to $3ffe and return a scale factor of "(exp-$3ffe)/2". If the 
* exponent of the input operand is off, set the exponent to ox3fff and
* return a scale factor of "(exp-$3fff)/2". 
*		
**-------------------------------------------------------------------------------------------------

	xdef	scale_sqrt
scale_sqrt:
	CMP.b	#DENORM,EXC_LV+STAG(a6)		* is operand normalized?
	BEQ	ss_denorm	* normalize the DENORM

	MOVE.W	EXC_LV+FP_SCR0_EX(a6),d1	* extract operand's {sgn,exp}
	AND.L	#$7fff,d1	* extract operand's exponent

	AND.W	#$8000,EXC_LV+FP_SCR0_EX(a6)	* extract operand's sgn

	BTST	#$0,d1	* is exp even or odd?
	BEQ	ss_norm_even

	ori.w	#$3fff,EXC_LV+FP_SCR0_EX(a6)	* insert new operand's exponent(=0)

	MOVE.L	#$3fff,d0
	SUB.L	d1,d0	* scale = BIAS + (-exp)
	asr.l	#$1,d0	* divide scale factor by 2
	RTS

ss_norm_even:
	ori.w	#$3ffe,EXC_LV+FP_SCR0_EX(a6)	* insert new operand's exponent(=0)

	MOVE.L	#$3ffe,d0
	SUB.L	d1,d0	* scale = BIAS + (-exp)
	asr.l	#$1,d0	* divide scale factor by 2
	RTS

ss_denorm:
	LEA	EXC_LV+FP_SCR0(a6),a0	* pass ptr to src op
	BSR	norm	* normalize denorm

	BTST	#$0,d0	* is exp even or odd?
	BEQ	ss_denorm_even

	ori.w	#$3fff,EXC_LV+FP_SCR0_EX(a6)	* insert new operand's exponent(=0)

	ADD.L	#$3fff,d0
	asr.l	#$1,d0	* divide scale factor by 2
	RTS

ss_denorm_even:
	ori.w	#$3ffe,EXC_LV+FP_SCR0_EX(a6)	* insert new operand's exponent(=0)

	ADD.L	#$3ffe,d0
	asr.l	#$1,d0	* divide scale factor by 2
	RTS

***

**-------------------------------------------------------------------------------------------------
* XDEF **
*	scale_to_zero_dst(): scale the exponent of extended precision
*	     value at EXC_LV+FP_SCR1(a6).
*		
* xdef **
*	norm() - normalize the mantissa if the operand was a DENORM
*		
* INPUT ***************************************************************
*	EXC_LV+FP_SCR1(a6) = extended precision operand to be scaled
* 		
* OUTPUT **************************************************************
*	EXC_LV+FP_SCR1(a6) = scaled extended precision operand
*	d0	    = scale value	
*		
* ALGORITHM ***********************************************************
* 	Set the exponent of the input operand to $3fff. Save the value
* of the difference between the original and new exponent. Then, 
* normalize the operand if it was a DENORM. Add this normalization
* value to the previous value. Return the result.
*		
**-------------------------------------------------------------------------------------------------

	xdef	scale_to_zero_dst
scale_to_zero_dst:
	MOVE.W	EXC_LV+FP_SCR1_EX(a6),d1	* extract operand's {sgn,exp}
	MOVE.W	d1,d0	* make a copy

	AND.L	#$7fff,d1	* extract operand's exponent

	AND.W	#$8000,d0	* extract operand's sgn
	OR.W	#$3fff,d0	* insert new operand's exponent(=0)

	MOVE.W	d0,EXC_LV+FP_SCR1_EX(a6)	* insert biased exponent

	CMP.b	#DENORM,EXC_LV+DTAG(a6)	* is operand normalized?
	BEQ	stzd_denorm	* normalize the DENORM

stzd_norm:
	MOVE.L	#$3fff,d0
	SUB.L	d1,d0	* scale = BIAS + (-exp)
	RTS

stzd_denorm:
	LEA	EXC_LV+FP_SCR1(a6),a0	* pass ptr to dst op
	BSR	norm	* normalize denorm
	neg.l	d0	* new exponent = -(shft val)
	MOVE.L	d0,d1	* prepare for op_norm call
	BRA	stzd_norm	* finish scaling

**-------------------------------------------------------------------------------------------------*

**-------------------------------------------------------------------------------------------------
* XDEF **
*	res_qnan(): return default result w/ QNAN operand for dyadic
*	res_snan(): return default result w/ SNAN operand for dyadic
*	res_qnan_1op(): return dflt result w/ QNAN operand for monadic
*	res_snan_1op(): return dflt result w/ SNAN operand for monadic
*		
* xdef **
*	None	
*		
* INPUT ***************************************************************
*	EXC_LV+FP_SRC(a6) = pointer to extended precision src operand
*	EXC_LV+FP_DST(a6) = pointer to extended precision dst operand
* 		
* OUTPUT **************************************************************
*	fp0 = default result	
*		
* ALGORITHM ***********************************************************
* 	If either operand (but not both operands) of an operation is a
* nonsignalling NAN, then that NAN is returned as the result. If both
* operands are nonsignalling NANs, then the destination operand 
* nonsignalling NAN is returned as the result.
* 	If either operand to an operation is a signalling NAN (SNAN),
* then, the SNAN bit is set in the FPSR EXC byte. If the SNAN trap
* enable bit is set in the FPCR, then the trap is taken and the 
* destination is not modified. If the SNAN trap enable bit is not set,
* then the SNAN is converted to a nonsignalling NAN (by setting the 
* SNAN bit in the operand to one), and the operation continues as 
* described in the preceding paragraph, for nonsignalling NANs.
*	Make sure the appropriate FPSR bits are set before exiting.
*		
**-------------------------------------------------------------------------------------------------

	xdef	res_qnan
	xdef	res_snan
res_qnan:
res_snan:
	CMP.b	#SNAN,EXC_LV+DTAG(a6)	* is the dst an SNAN?
	BEQ	dst_snan2
	CMP.b	#QNAN,EXC_LV+DTAG(a6)	* is the dst a  QNAN?
	BEQ	dst_qnan2
src_nan:	CMP.b	#QNAN,EXC_LV+STAG(a6)
	BEQ	src_qnan2

	xdef	res_snan_1op
res_snan_1op:
src_snan2:
	BSET	#$6, EXC_LV+FP_SRC_HI(a6)	* set SNAN bit
	OR.L	#nan_mask+aiop_mask+snan_mask, EXC_LV+USER_FPSR(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	BRA	nan_comp
	xdef	res_qnan_1op
res_qnan_1op:
src_qnan2:
	OR.L	#nan_mask, EXC_LV+USER_FPSR(a6)
	LEA	EXC_LV+FP_SRC(a6), a0
	BRA	nan_comp
dst_snan2:
	OR.L	#nan_mask+aiop_mask+snan_mask, EXC_LV+USER_FPSR(a6)
	BSET	#$6, EXC_LV+FP_DST_HI(a6)	* set SNAN bit
	LEA	EXC_LV+FP_DST(a6), a0
	BRA	nan_comp
dst_qnan2:
	LEA	EXC_LV+FP_DST(a6), a0
	CMP.b	#SNAN,EXC_LV+STAG(a6),
	bne	nan_done
	OR.L	#aiop_mask+snan_mask, EXC_LV+USER_FPSR(a6)
nan_done:
	OR.L	#nan_mask, EXC_LV+USER_FPSR(a6)
nan_comp:
	BTST	#$7, FTEMP_EX(a0)	* is NAN neg?
	BEQ	nan_not_neg
	OR.L	#neg_mask, EXC_LV+USER_FPSR(a6)
nan_not_neg:
	FMOVEM.X	(a0),fp0
	RTS

**-------------------------------------------------------------------------------------------------
* XDEF **
* 	res_operr(): return default result during operand error
*		
* xdef **
*	None	
*		
* INPUT ***************************************************************
*	None	
* 		
* OUTPUT **************************************************************
*	fp0 = default operand error result
*		
* ALGORITHM ***********************************************************
*	An nonsignalling NAN is returned as the default result when
* an operand error occurs for the following cases:
*		
* 	Multiply: (Infinity x Zero)	
* 	Divide  : (Zero / Zero) || (Infinity / Infinity)
*		
**-------------------------------------------------------------------------------------------------

	xdef	res_operr
res_operr:
	OR.L	#nan_mask+operr_mask+aiop_mask, EXC_LV+USER_FPSR(a6)
	FMOVEM.X	nan_return(pc),fp0
	RTS

nan_return:
	dc.l	$7fff0000, $ffffffff, $ffffffff




