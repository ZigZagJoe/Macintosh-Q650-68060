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

	XREF	norm,_round,ovf_res

	XREF	fgen_except

**-------------------------------------------------------------------------------------------------

T1:	dc.l	$40C62D38,$D3D64634			* 16381 LOG2 LEAD
T2:	dc.l	$3D6F90AE,$B1E75CC7			* 16381 LOG2 TRAIL
TWOBYPI:	dc.l	$3FE45F30,$6DC9C883
PI:	dc.l	$40000000,$C90FDAA2,$2168C235,0
PIBY2:	dc.l	$3FFF0000,$C90FDAA2,$2168C235,0


**-------------------------------------------------------------------------------------------------

	XDEF	tbl_trans
tbl_trans:
	dc.w 	tbl_trans - tbl_trans	* $00-0 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-1 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-2 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-3 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-4 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-5 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-6 fmovecr all
	dc.w 	tbl_trans - tbl_trans	* $00-7 fmovecr all

	dc.w 	tbl_trans - tbl_trans	* $01-0 fint norm
	dc.w	tbl_trans - tbl_trans	* $01-1 fint zero
	dc.w	tbl_trans - tbl_trans	* $01-2 fint inf
	dc.w	tbl_trans - tbl_trans	* $01-3 fint qnan
	dc.w	tbl_trans - tbl_trans	* $01-5 fint denorm
	dc.w	tbl_trans - tbl_trans	* $01-4 fint snan
	dc.w	tbl_trans - tbl_trans	* $01-6 fint unnorm
	dc.w	tbl_trans - tbl_trans	* $01-7 ERROR

	dc.w	ssinh-tbl_trans		* $02-0 fsinh norm
	dc.w	src_zero - tbl_trans	* $02-1 fsinh zero
	dc.w	src_inf	 - tbl_trans	* $02-2 fsinh inf
	dc.w	src_qnan - tbl_trans	* $02-3 fsinh qnan
	dc.w	ssinhd	 - tbl_trans	* $02-5 fsinh denorm
	dc.w	src_snan - tbl_trans	* $02-4 fsinh snan
	dc.w	tbl_trans - tbl_trans	* $02-6 fsinh unnorm
	dc.w	tbl_trans - tbl_trans	* $02-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $03-0 fintrz norm
	dc.w	tbl_trans - tbl_trans	* $03-1 fintrz zero
	dc.w	tbl_trans - tbl_trans	* $03-2 fintrz inf
	dc.w	tbl_trans - tbl_trans	* $03-3 fintrz qnan
	dc.w	tbl_trans - tbl_trans	* $03-5 fintrz denorm
	dc.w	tbl_trans - tbl_trans	* $03-4 fintrz snan
	dc.w	tbl_trans - tbl_trans	* $03-6 fintrz unnorm
	dc.w	tbl_trans - tbl_trans	* $03-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $04-0 fsqrt norm
	dc.w	tbl_trans - tbl_trans	* $04-1 fsqrt zero
	dc.w	tbl_trans - tbl_trans	* $04-2 fsqrt inf
	dc.w	tbl_trans - tbl_trans	* $04-3 fsqrt qnan
	dc.w	tbl_trans - tbl_trans	* $04-5 fsqrt denorm
	dc.w	tbl_trans - tbl_trans	* $04-4 fsqrt snan
	dc.w	tbl_trans - tbl_trans	* $04-6 fsqrt unnorm
	dc.w	tbl_trans - tbl_trans	* $04-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $05-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $05-7 ERROR

	dc.w	slognp1	 - tbl_trans	* $06-0 flognp1 norm
	dc.w	src_zero - tbl_trans	* $06-1 flognp1 zero
	dc.w	sopr_inf - tbl_trans	* $06-2 flognp1 inf
	dc.w	src_qnan - tbl_trans	* $06-3 flognp1 qnan
	dc.w	slognp1d - tbl_trans	* $06-5 flognp1 denorm
	dc.w	src_snan - tbl_trans	* $06-4 flognp1 snan
	dc.w	tbl_trans - tbl_trans	* $06-6 flognp1 unnorm
	dc.w	tbl_trans - tbl_trans	* $06-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $07-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $07-7 ERROR

	dc.w	setoxm1	 - tbl_trans	* $08-0 fetoxm1 norm
	dc.w	src_zero - tbl_trans	* $08-1 fetoxm1 zero
	dc.w	setoxm1i - tbl_trans	* $08-2 fetoxm1 inf
	dc.w	src_qnan - tbl_trans	* $08-3 fetoxm1 qnan
	dc.w	setoxm1d - tbl_trans	* $08-5 fetoxm1 denorm
	dc.w	src_snan - tbl_trans	* $08-4 fetoxm1 snan
	dc.w	tbl_trans - tbl_trans	* $08-6 fetoxm1 unnorm
	dc.w	tbl_trans - tbl_trans	* $08-7 ERROR

	dc.w	stanh	 - tbl_trans	* $09-0 ftanh norm
	dc.w	src_zero - tbl_trans	* $09-1 ftanh zero
	dc.w	src_one	 - tbl_trans	* $09-2 ftanh inf
	dc.w	src_qnan - tbl_trans	* $09-3 ftanh qnan
	dc.w	stanhd	 - tbl_trans	* $09-5 ftanh denorm
	dc.w	src_snan - tbl_trans	* $09-4 ftanh snan
	dc.w	tbl_trans - tbl_trans	* $09-6 ftanh unnorm
	dc.w	tbl_trans - tbl_trans	* $09-7 ERROR

	dc.w	satan	 - tbl_trans	* $0a-0 fatan norm
	dc.w	src_zero - tbl_trans	* $0a-1 fatan zero
	dc.w	spi_2	 - tbl_trans	* $0a-2 fatan inf
	dc.w	src_qnan - tbl_trans	* $0a-3 fatan qnan
	dc.w	satand	 - tbl_trans	* $0a-5 fatan denorm
	dc.w	src_snan - tbl_trans	* $0a-4 fatan snan
	dc.w	tbl_trans - tbl_trans	* $0a-6 fatan unnorm
	dc.w	tbl_trans - tbl_trans	* $0a-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $0b-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $0b-7 ERROR

	dc.w	sasin	 - tbl_trans	* $0c-0 fasin norm
	dc.w	src_zero - tbl_trans	* $0c-1 fasin zero
	dc.w	t_operr	 - tbl_trans	* $0c-2 fasin inf
	dc.w	src_qnan - tbl_trans	* $0c-3 fasin qnan
	dc.w	sasind	 - tbl_trans	* $0c-5 fasin denorm
	dc.w	src_snan - tbl_trans	* $0c-4 fasin snan
	dc.w	tbl_trans - tbl_trans	* $0c-6 fasin unnorm
	dc.w	tbl_trans - tbl_trans	* $0c-7 ERROR

	dc.w	satanh	 - tbl_trans	* $0d-0 fatanh norm
	dc.w	src_zero - tbl_trans	* $0d-1 fatanh zero
	dc.w	t_operr	 - tbl_trans	* $0d-2 fatanh inf
	dc.w	src_qnan - tbl_trans	* $0d-3 fatanh qnan
	dc.w	satanhd	 - tbl_trans	* $0d-5 fatanh denorm
	dc.w	src_snan - tbl_trans	* $0d-4 fatanh snan
	dc.w	tbl_trans - tbl_trans	* $0d-6 fatanh unnorm
	dc.w	tbl_trans - tbl_trans	* $0d-7 ERROR

	dc.w	ssin	 - tbl_trans	* $0e-0 fsin norm
	dc.w	src_zero - tbl_trans	* $0e-1 fsin zero
	dc.w	t_operr	 - tbl_trans	* $0e-2 fsin inf
	dc.w	src_qnan - tbl_trans	* $0e-3 fsin qnan
	dc.w	ssind	 - tbl_trans	* $0e-5 fsin denorm
	dc.w	src_snan - tbl_trans	* $0e-4 fsin snan
	dc.w	tbl_trans - tbl_trans	* $0e-6 fsin unnorm
	dc.w	tbl_trans - tbl_trans	* $0e-7 ERROR

	dc.w	stan	 - tbl_trans	* $0f-0 ftan norm
	dc.w	src_zero - tbl_trans	* $0f-1 ftan zero
	dc.w	t_operr	 - tbl_trans	* $0f-2 ftan inf
	dc.w	src_qnan - tbl_trans	* $0f-3 ftan qnan
	dc.w	stand	 - tbl_trans	* $0f-5 ftan denorm
	dc.w	src_snan - tbl_trans	* $0f-4 ftan snan
	dc.w	tbl_trans - tbl_trans	* $0f-6 ftan unnorm
	dc.w	tbl_trans - tbl_trans	* $0f-7 ERROR

	dc.w	setox	 - tbl_trans	* $10-0 fetox norm
	dc.w	ld_pone	 - tbl_trans	* $10-1 fetox zero
	dc.w	szr_inf	 - tbl_trans	* $10-2 fetox inf
	dc.w	src_qnan - tbl_trans	* $10-3 fetox qnan
	dc.w	setoxd	 - tbl_trans	* $10-5 fetox denorm
	dc.w	src_snan - tbl_trans	* $10-4 fetox snan
	dc.w	tbl_trans - tbl_trans	* $10-6 fetox unnorm
	dc.w	tbl_trans - tbl_trans	* $10-7 ERROR

	dc.w	stwotox	 - tbl_trans	* $11-0 ftwotox norm
	dc.w	ld_pone	 - tbl_trans	* $11-1 ftwotox zero
	dc.w	szr_inf	 - tbl_trans	* $11-2 ftwotox inf
	dc.w	src_qnan - tbl_trans	* $11-3 ftwotox qnan
	dc.w	stwotoxd - tbl_trans	* $11-5 ftwotox denorm
	dc.w	src_snan - tbl_trans	* $11-4 ftwotox snan
	dc.w	tbl_trans - tbl_trans	* $11-6 ftwotox unnorm
	dc.w	tbl_trans - tbl_trans	* $11-7 ERROR

	dc.w	stentox	 - tbl_trans	* $12-0 ftentox norm
	dc.w	ld_pone	 - tbl_trans	* $12-1 ftentox zero
	dc.w	szr_inf	 - tbl_trans	* $12-2 ftentox inf
	dc.w	src_qnan - tbl_trans	* $12-3 ftentox qnan
	dc.w	stentoxd - tbl_trans	* $12-5 ftentox denorm
	dc.w	src_snan - tbl_trans	* $12-4 ftentox snan
	dc.w	tbl_trans - tbl_trans	* $12-6 ftentox unnorm
	dc.w	tbl_trans - tbl_trans	* $12-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $13-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $13-7 ERROR

	dc.w	slogn	 - tbl_trans	* $14-0 flogn norm
	dc.w	t_dz2	 - tbl_trans	* $14-1 flogn zero
	dc.w	sopr_inf - tbl_trans	* $14-2 flogn inf
	dc.w	src_qnan - tbl_trans	* $14-3 flogn qnan
	dc.w	slognd	 - tbl_trans	* $14-5 flogn denorm
	dc.w	src_snan - tbl_trans	* $14-4 flogn snan
	dc.w	tbl_trans - tbl_trans	* $14-6 flogn unnorm
	dc.w	tbl_trans - tbl_trans	* $14-7 ERROR

	dc.w	slog10	 - tbl_trans	* $15-0 flog10 norm
	dc.w	t_dz2	 - tbl_trans	* $15-1 flog10 zero
	dc.w	sopr_inf - tbl_trans	* $15-2 flog10 inf
	dc.w	src_qnan - tbl_trans	* $15-3 flog10 qnan
	dc.w	slog10d	 - tbl_trans	* $15-5 flog10 denorm
	dc.w	src_snan - tbl_trans	* $15-4 flog10 snan
	dc.w	tbl_trans - tbl_trans	* $15-6 flog10 unnorm
	dc.w	tbl_trans - tbl_trans	* $15-7 ERROR

	dc.w	slog2	 - tbl_trans	* $16-0 flog2 norm
	dc.w	t_dz2	 - tbl_trans	* $16-1 flog2 zero
	dc.w	sopr_inf - tbl_trans	* $16-2 flog2 inf
	dc.w	src_qnan - tbl_trans	* $16-3 flog2 qnan
	dc.w	slog2d	 - tbl_trans	* $16-5 flog2 denorm
	dc.w	src_snan - tbl_trans	* $16-4 flog2 snan
	dc.w	tbl_trans - tbl_trans	* $16-6 flog2 unnorm
	dc.w	tbl_trans - tbl_trans	* $16-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $17-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $17-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $18-0 fabs norm
	dc.w	tbl_trans - tbl_trans	* $18-1 fabs zero
	dc.w	tbl_trans - tbl_trans	* $18-2 fabs inf
	dc.w	tbl_trans - tbl_trans	* $18-3 fabs qnan
	dc.w	tbl_trans - tbl_trans	* $18-5 fabs denorm
	dc.w	tbl_trans - tbl_trans	* $18-4 fabs snan
	dc.w	tbl_trans - tbl_trans	* $18-6 fabs unnorm
	dc.w	tbl_trans - tbl_trans	* $18-7 ERROR

	dc.w	scosh	 - tbl_trans	* $19-0 fcosh norm
	dc.w	ld_pone	 - tbl_trans	* $19-1 fcosh zero
	dc.w	ld_pinf	 - tbl_trans	* $19-2 fcosh inf
	dc.w	src_qnan - tbl_trans	* $19-3 fcosh qnan
	dc.w	scoshd	 - tbl_trans	* $19-5 fcosh denorm
	dc.w	src_snan - tbl_trans	* $19-4 fcosh snan
	dc.w	tbl_trans - tbl_trans	* $19-6 fcosh unnorm
	dc.w	tbl_trans - tbl_trans	* $19-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $1a-0 fneg norm
	dc.w	tbl_trans - tbl_trans	* $1a-1 fneg zero
	dc.w	tbl_trans - tbl_trans	* $1a-2 fneg inf
	dc.w	tbl_trans - tbl_trans	* $1a-3 fneg qnan
	dc.w	tbl_trans - tbl_trans	* $1a-5 fneg denorm
	dc.w	tbl_trans - tbl_trans	* $1a-4 fneg snan
	dc.w	tbl_trans - tbl_trans	* $1a-6 fneg unnorm
	dc.w	tbl_trans - tbl_trans	* $1a-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $1b-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $1b-7 ERROR

	dc.w	sacos	 - tbl_trans	* $1c-0 facos norm
	dc.w	ld_ppi2	 - tbl_trans	* $1c-1 facos zero
	dc.w	t_operr	 - tbl_trans	* $1c-2 facos inf
	dc.w	src_qnan - tbl_trans	* $1c-3 facos qnan
	dc.w	sacosd	 - tbl_trans	* $1c-5 facos denorm
	dc.w	src_snan - tbl_trans	* $1c-4 facos snan
	dc.w	tbl_trans - tbl_trans	* $1c-6 facos unnorm
	dc.w	tbl_trans - tbl_trans	* $1c-7 ERROR

	dc.w	scos	 - tbl_trans	* $1d-0 fcos norm
	dc.w	ld_pone	 - tbl_trans	* $1d-1 fcos zero
	dc.w	t_operr	 - tbl_trans	* $1d-2 fcos inf
	dc.w	src_qnan - tbl_trans	* $1d-3 fcos qnan
	dc.w	scosd	 - tbl_trans	* $1d-5 fcos denorm
	dc.w	src_snan - tbl_trans	* $1d-4 fcos snan
	dc.w	tbl_trans - tbl_trans	* $1d-6 fcos unnorm
	dc.w	tbl_trans - tbl_trans	* $1d-7 ERROR

	dc.w	sgetexp	 - tbl_trans	* $1e-0 fgetexp norm
	dc.w	src_zero - tbl_trans	* $1e-1 fgetexp zero
	dc.w	t_operr	 - tbl_trans	* $1e-2 fgetexp inf
	dc.w	src_qnan - tbl_trans	* $1e-3 fgetexp qnan
	dc.w	sgetexpd - tbl_trans	* $1e-5 fgetexp denorm
	dc.w	src_snan - tbl_trans	* $1e-4 fgetexp snan
	dc.w	tbl_trans - tbl_trans	* $1e-6 fgetexp unnorm
	dc.w	tbl_trans - tbl_trans	* $1e-7 ERROR

	dc.w	sgetman	 - tbl_trans	* $1f-0 fgetman norm
	dc.w	src_zero - tbl_trans	* $1f-1 fgetman zero
	dc.w	t_operr	 - tbl_trans	* $1f-2 fgetman inf
	dc.w	src_qnan - tbl_trans	* $1f-3 fgetman qnan
	dc.w	sgetmand - tbl_trans	* $1f-5 fgetman denorm
	dc.w	src_snan - tbl_trans	* $1f-4 fgetman snan
	dc.w	tbl_trans - tbl_trans	* $1f-6 fgetman unnorm
	dc.w	tbl_trans - tbl_trans	* $1f-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $20-0 fdiv norm
	dc.w	tbl_trans - tbl_trans	* $20-1 fdiv zero
	dc.w	tbl_trans - tbl_trans	* $20-2 fdiv inf
	dc.w	tbl_trans - tbl_trans	* $20-3 fdiv qnan
	dc.w	tbl_trans - tbl_trans	* $20-5 fdiv denorm
	dc.w	tbl_trans - tbl_trans	* $20-4 fdiv snan
	dc.w	tbl_trans - tbl_trans	* $20-6 fdiv unnorm
	dc.w	tbl_trans - tbl_trans	* $20-7 ERROR

	dc.w	smod_snorm - tbl_trans	* $21-0 fmod norm
	dc.w	smod_szero - tbl_trans	* $21-1 fmod zero
	dc.w	smod_sinf - tbl_trans	* $21-2 fmod inf
	dc.w	sop_sqnan - tbl_trans	* $21-3 fmod qnan
	dc.w	smod_sdnrm - tbl_trans	* $21-5 fmod denorm
	dc.w	sop_ssnan - tbl_trans	* $21-4 fmod snan
	dc.w	tbl_trans - tbl_trans	* $21-6 fmod unnorm
	dc.w	tbl_trans - tbl_trans	* $21-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $22-0 fadd norm
	dc.w	tbl_trans - tbl_trans	* $22-1 fadd zero
	dc.w	tbl_trans - tbl_trans	* $22-2 fadd inf
	dc.w	tbl_trans - tbl_trans	* $22-3 fadd qnan
	dc.w	tbl_trans - tbl_trans	* $22-5 fadd denorm
	dc.w	tbl_trans - tbl_trans	* $22-4 fadd snan
	dc.w	tbl_trans - tbl_trans	* $22-6 fadd unnorm
	dc.w	tbl_trans - tbl_trans	* $22-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $23-0 fmul norm
	dc.w	tbl_trans - tbl_trans	* $23-1 fmul zero
	dc.w	tbl_trans - tbl_trans	* $23-2 fmul inf
	dc.w	tbl_trans - tbl_trans	* $23-3 fmul qnan
	dc.w	tbl_trans - tbl_trans	* $23-5 fmul denorm
	dc.w	tbl_trans - tbl_trans	* $23-4 fmul snan
	dc.w	tbl_trans - tbl_trans	* $23-6 fmul unnorm
	dc.w	tbl_trans - tbl_trans	* $23-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $24-0 fsgldiv norm
	dc.w	tbl_trans - tbl_trans	* $24-1 fsgldiv zero
	dc.w	tbl_trans - tbl_trans	* $24-2 fsgldiv inf
	dc.w	tbl_trans - tbl_trans	* $24-3 fsgldiv qnan
	dc.w	tbl_trans - tbl_trans	* $24-5 fsgldiv denorm
	dc.w	tbl_trans - tbl_trans	* $24-4 fsgldiv snan
	dc.w	tbl_trans - tbl_trans	* $24-6 fsgldiv unnorm
	dc.w	tbl_trans - tbl_trans	* $24-7 ERROR

	dc.w	srem_snorm - tbl_trans	* $25-0 frem norm
	dc.w	srem_szero - tbl_trans	* $25-1 frem zero
	dc.w	srem_sinf - tbl_trans	* $25-2 frem inf
	dc.w	sop_sqnan - tbl_trans	* $25-3 frem qnan
	dc.w	srem_sdnrm - tbl_trans	* $25-5 frem denorm
	dc.w	sop_ssnan - tbl_trans	* $25-4 frem snan
	dc.w	tbl_trans - tbl_trans	* $25-6 frem unnorm
	dc.w	tbl_trans - tbl_trans	* $25-7 ERROR

	dc.w	sscale_snorm - tbl_trans * $26-0 fscale norm
	dc.w	sscale_szero - tbl_trans * $26-1 fscale zero
	dc.w	sscale_sinf - tbl_trans	* $26-2 fscale inf
	dc.w	sop_sqnan - tbl_trans	* $26-3 fscale qnan
	dc.w	sscale_sdnrm - tbl_trans * $26-5 fscale denorm
	dc.w	sop_ssnan - tbl_trans	* $26-4 fscale snan
	dc.w	tbl_trans - tbl_trans	* $26-6 fscale unnorm
	dc.w	tbl_trans - tbl_trans	* $26-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $27-0 fsglmul norm
	dc.w	tbl_trans - tbl_trans	* $27-1 fsglmul zero
	dc.w	tbl_trans - tbl_trans	* $27-2 fsglmul inf
	dc.w	tbl_trans - tbl_trans	* $27-3 fsglmul qnan
	dc.w	tbl_trans - tbl_trans	* $27-5 fsglmul denorm
	dc.w	tbl_trans - tbl_trans	* $27-4 fsglmul snan
	dc.w	tbl_trans - tbl_trans	* $27-6 fsglmul unnorm
	dc.w	tbl_trans - tbl_trans	* $27-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $28-0 fsub norm
	dc.w	tbl_trans - tbl_trans	* $28-1 fsub zero
	dc.w	tbl_trans - tbl_trans	* $28-2 fsub inf
	dc.w	tbl_trans - tbl_trans	* $28-3 fsub qnan
	dc.w	tbl_trans - tbl_trans	* $28-5 fsub denorm
	dc.w	tbl_trans - tbl_trans	* $28-4 fsub snan
	dc.w	tbl_trans - tbl_trans	* $28-6 fsub unnorm
	dc.w	tbl_trans - tbl_trans	* $28-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $29-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $29-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2a-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2a-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2b-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2b-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2c-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2c-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2d-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2d-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2e-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2e-7 ERROR

	dc.w	tbl_trans - tbl_trans	* $2f-0 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-1 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-2 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-3 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-4 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-5 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-6 ERROR
	dc.w	tbl_trans - tbl_trans	* $2f-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $30-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $30-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $30-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $30-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $30-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $30-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $30-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $30-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $31-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $31-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $31-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $31-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $31-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $31-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $31-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $31-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $32-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $32-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $32-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $32-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $32-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $32-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $32-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $32-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $33-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $33-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $33-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $33-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $33-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $33-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $33-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $33-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $34-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $34-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $34-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $34-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $34-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $34-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $34-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $34-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $35-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $35-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $35-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $35-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $35-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $35-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $35-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $35-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $36-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $36-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $36-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $36-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $36-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $36-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $36-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $36-7 ERROR

	dc.w	ssincos	 - tbl_trans	* $37-0 fsincos norm
	dc.w	ssincosz - tbl_trans	* $37-1 fsincos zero
	dc.w	ssincosi - tbl_trans	* $37-2 fsincos inf
	dc.w	ssincosqnan - tbl_trans	* $37-3 fsincos qnan
	dc.w	ssincosd - tbl_trans	* $37-5 fsincos denorm
	dc.w	ssincossnan - tbl_trans	* $37-4 fsincos snan
	dc.w	tbl_trans - tbl_trans	* $37-6 fsincos unnorm
	dc.w	tbl_trans - tbl_trans	* $37-7 ERROR


**-------------------------------------------------------------------------------------------------
**-------------------------------------------------------------------------------------------------
* ssin():     computes the sine of a normalized input
* ssind():    computes the sine of a denormalized input
* scos():     computes the cosine of a normalized input
* scosd():    computes the cosine of a denormalized input
* ssincos():  computes the sine and cosine of a normalized input
* ssincosd(): computes the sine and cosine of a denormalized input
*
* INPUT *************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode
*
* OUTPUT ************************************************************** *
*	fp0 = sin(X) or cos(X)
*
*    For ssincos(X):
*	fp0 = sin(X)
*	fp1 = cos(X)
*
* ACCURACY and MONOTONICITY ******************************************* *
*	The returned result is within 1 ulp in 64 significant bit, i.e.
*	within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.
*
* ALGORITHM ***********************************************************
*
*	SIN and COS:
*	1. If SIN is invoked, set AdjN := 0; otherwise, set AdjN := 1.
*
*	2. If |X| >= 15Pi or |X| < 2**(-40), go to 7.
*
*	3. Decompose X as X = N(Pi/2) + r where |r| <= Pi/4. Let
*	k = N mod 4, so in particular, k = 0,1,2,or 3.
*	Overwrite k by k := k + AdjN.
*
*	4. If k is even, go to 6.
*
*	5. (k is odd) Set j := (k-1)/2, sgn := (-1)**j.
*	Return sgn*cos(r) where cos(r) is approximated by an
*	even polynomial in r, 1 + r*r*(B1+s*(B2+ ... + s*B8)),
*	s = r*r.
*	Exit.
*
*	6. (k is even) Set j := k/2, sgn := (-1)**j. Return sgn*sin(r)
*	where sin(r) is approximated by an odd polynomial in r
*	r + r*s*(A1+s*(A2+ ... + s*A7)),	s = r*r.
*	Exit.
*
*	7. If |X| > 1, go to 9.
*
*	8. (|X|<2**(-40)) If SIN is invoked, return X;
*	otherwise return 1.
*
*	9. Overwrite X by X := X rem 2Pi. Now that |X| <= Pi,
*	go back to 3.
*
*	SINCOS:
*	1. If |X| >= 15Pi or |X| < 2**(-40), go to 6.
*
*	2. Decompose X as X = N(Pi/2) + r where |r| <= Pi/4. Let
*	k = N mod 4, so in particular, k = 0,1,2,or 3.
*
*	3. If k is even, go to 5.
*
*	4. (k is odd) Set j1 := (k-1)/2, j2 := j1 (EOR) (k mod 2), ie.
*	j1 exclusive or with the l.s.b. of k.
*	sgn1 := (-1)**j1, sgn2 := (-1)**j2.
*	SIN(X) = sgn1 * cos(r) and COS(X) = sgn2*sin(r) where
*	sin(r) and cos(r) are computed as odd and even
*	polynomials in r, respectively. Exit
*
*	5. (k is even) Set j1 := k/2, sgn1 := (-1)**j1.
*	SIN(X) = sgn1 * sin(r) and COS(X) = sgn1*cos(r) where
*	sin(r) and cos(r) are computed as odd and even
*	polynomials in r, respectively. Exit
*
*	6. If |X| > 1, go to 8.
*
*	7. (|X|<2**(-40)) SIN(X) = X and COS(X) = 1. Exit.
*
*	8. Overwrite X by X := X rem 2Pi. Now that |X| <= Pi,
*	go back to 2.
*
**-------------------------------------------------------------------------------------------------

SINA7:	dc.l	$BD6AAA77,$CCC994F5
SINA6:	dc.l	$3DE61209,$7AAE8DA1
SINA5:	dc.l	$BE5AE645,$2A118AE4
SINA4:	dc.l	$3EC71DE3,$A5341531
SINA3:	dc.l	$BF2A01A0,$1A018B59,$00000000,$00000000
SINA2:	dc.l	$3FF80000,$88888888,$888859AF,$00000000
SINA1:	dc.l	$BFFC0000,$AAAAAAAA,$AAAAAA99,$00000000

COSB8:	dc.l	$3D2AC4D0,$D6011EE3
COSB7:	dc.l	$BDA9396F,$9F45AC19
COSB6:	dc.l	$3E21EED9,$0612C972
COSB5:	dc.l	$BE927E4F,$B79D9FCF
COSB4:	dc.l	$3EFA01A0,$1A01D423,$00000000,$00000000
COSB3:	dc.l	$BFF50000,$B60B60B6,$0B61D438,$00000000
COSB2:	dc.l	$3FFA0000,$AAAAAAAA,$AAAAAB5E
COSB1:	dc.l	$BF000000

INARG	equ	EXC_LV+FP_SCR0

X	equ	EXC_LV+FP_SCR0
*XDCARE	equ	X+2
XFRAC	equ	X+4

RPRIME	equ	EXC_LV+FP_SCR0
SPRIME	equ	EXC_LV+FP_SCR1

POSNEG1	equ	EXC_LV+L_SCR1
TWOTO63	equ	EXC_LV+L_SCR1

ENDFLAG	equ	EXC_LV+L_SCR2
INT	equ	EXC_LV+L_SCR2

ADJN	equ	EXC_LV+L_SCR3

********************************************
	xdef	ssin
ssin:
	move.l	#0,ADJN(a6)	* yes; SET ADJN TO 0
	bra.b	SINBGN

********************************************
	xdef	scos
scos:
	move.l	#1,ADJN(a6)	* yes; SET ADJN TO 1

********************************************
SINBGN:
*--SAVE FPCR, FP1. CHECK IF |X| IS TOO SMALL OR LARGE

	fmove.x	(a0),fp0	* LOAD INPUT
	fmove.x	fp0,X(a6)	* save input at X

* "COMPACTIFY" X
	move.l	(a0),d1	* put exp in hi word
	move.w	4(a0),d1	* fetch hi(man)
	and.l	#$7FFFFFFF,d1	* strip sign

	ICMP.l	d1,#$3FD78000	* is |X| >= 2**(-40)?
	bge.b	SOK1	* no
	bra.w	SINSM	* yes; input is very small

SOK1:
	ICMP.l	d1,#$4004BC7E	* is |X| < 15 PI?
	blt.b	SINMAIN	* no
	bra.w	SREDUCEX	* yes; input is very large

*--THIS IS THE USUAL CASE, |X| <= 15 PI.
*--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
SINMAIN:
	fmove.x	fp0,fp1
	fmul.d	TWOBYPI(pc),fp1 	* X*2/PI

	lea	PITBL+$200(pc),a1 	* TABLE OF N*PI/2, N = -32,...,32

	fmove.l	fp1,INT(a6)	* CONVERT TO INTEGER

	move.l	INT(a6),d1	* make a copy of N
	asl.l	#4,d1	* N *= 16
	add.l	d1,a1	* tbl_addr = a1 + (N*16)

* A1 IS THE ADDRESS OF N*PIBY2
* ...WHICH IS IN TWO PIECES Y1 # Y2
	fsub.x	(a1)+,fp0 	* X-Y1
	fsub.s	(a1),fp0 	* fp0 = R = (X-Y1)-Y2

SINCONT:
*--continuation from REDUCEX

*--GET N+ADJN AND SEE IF SIN(R) OR COS(R) IS NEEDED
	move.l	INT(a6),d1
	add.l	ADJN(a6),d1	* SEE IF D0 IS ODD OR EVEN
	ror.l	#1,d1	* D0 WAS ODD IFF D0 IS NEGATIVE
	cmp.l	#0,d1
	blt.w	COSPOLY

*--LET J BE THE LEAST SIG. BIT OF D0, LET SGN := (-1)**J.
*--THEN WE RETURN	SGN*SIN(R). SGN*SIN(R) IS COMPUTED BY
*--R' + R'*S*(A1 + S(A2 + S(A3 + S(A4 + ... + SA7)))), WHERE
*--R' = SGN*R, S=R*R. THIS CAN BE REWRITTEN AS
*--R' + R'*S*( [A1+T(A3+T(A5+TA7))] + [S(A2+T(A4+TA6))])
*--WHERE T=S*S.
*--NOTE THAT A3 THROUGH A7 ARE STORED IN DOUBLE PRECISION
*--WHILE A1 AND A2 ARE IN DOUBLE-EXTENDED FORMAT.
SINPOLY:
	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmove.x	fp0,X(a6)	* X IS R
	fmul.x	fp0,fp0	* FP0 IS S

	fmove.d	SINA7(pc),fp3
	fmove.d	SINA6(pc),fp2

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS T

	ror.l	#1,d1
	and.l	#$80000000,d1
* ...LEAST SIG. BIT OF D0 IN SIGN POSITION
	eor.l	d1,X(a6)	* X IS NOW R'= SGN*R

	fmul.x	fp1,fp3	* TA7
	fmul.x	fp1,fp2	* TA6

	fadd.d	SINA5(pc),fp3	* A5+TA7
	fadd.d	SINA4(pc),fp2	* A4+TA6

	fmul.x	fp1,fp3	* T(A5+TA7)
	fmul.x	fp1,fp2	* T(A4+TA6)

	fadd.d	SINA3(pc),fp3	* A3+T(A5+TA7)
	fadd.x	SINA2(pc),fp2	* A2+T(A4+TA6)

	fmul.x	fp3,fp1	* T(A3+T(A5+TA7))

	fmul.x	fp0,fp2	* S(A2+T(A4+TA6))
	fadd.x	SINA1(pc),fp1	* A1+T(A3+T(A5+TA7))
	fmul.x	X(a6),fp0	* R'*S

	fadd.x	fp2,fp1	* [A1+T(A3+T(A5+TA7))]+[S(A2+T(A4+TA6))]

	fmul.x	fp1,fp0	* SIN(R')-R'

	fmovem.x	(sp)+,fp2-fp3	* restore fp2/fp3

	fmove.l	d0,fpcr	* restore users round mode,prec
	fadd.x	X(a6),fp0	* last inst - possible exception set
	bra	t_inx2

*--LET J BE THE LEAST SIG. BIT OF D0, LET SGN := (-1)**J.
*--THEN WE RETURN	SGN*COS(R). SGN*COS(R) IS COMPUTED BY
*--SGN + S'*(B1 + S(B2 + S(B3 + S(B4 + ... + SB8)))), WHERE
*--S=R*R AND S'=SGN*S. THIS CAN BE REWRITTEN AS
*--SGN + S'*([B1+T(B3+T(B5+TB7))] + [S(B2+T(B4+T(B6+TB8)))])
*--WHERE T=S*S.
*--NOTE THAT B4 THROUGH B8 ARE STORED IN DOUBLE PRECISION
*--WHILE B2 AND B3 ARE IN DOUBLE-EXTENDED FORMAT, B1 IS -1/2
*--AND IS THEREFORE STORED AS SINGLE PRECISION.
COSPOLY:
	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmul.x	fp0,fp0	* FP0 IS S

	fmove.d	COSB8(pc),fp2
	fmove.d	COSB7(pc),fp3

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS T

	fmove.x	fp0,X(a6)	* X IS S
	ror.l	#1,d1
	and.l	#$80000000,d1
* ...LEAST SIG. BIT OF D0 IN SIGN POSITION

	fmul.x	fp1,fp2	* TB8

	eor.l	d1,X(a6)	* X IS NOW S'= SGN*S
	and.l	#$80000000,d1

	fmul.x	fp1,fp3	* TB7

	or.l	#$3F800000,d1	* D0 IS SGN IN SINGLE
	move.l	d1,POSNEG1(a6)

	fadd.d	COSB6(pc),fp2	* B6+TB8
	fadd.d	COSB5(pc),fp3	* B5+TB7

	fmul.x	fp1,fp2	* T(B6+TB8)
	fmul.x	fp1,fp3	* T(B5+TB7)

	fadd.d	COSB4(pc),fp2	* B4+T(B6+TB8)
	fadd.x	COSB3(pc),fp3	* B3+T(B5+TB7)

	fmul.x	fp1,fp2	* T(B4+T(B6+TB8))
	fmul.x	fp3,fp1	* T(B3+T(B5+TB7))

	fadd.x	COSB2(pc),fp2	* B2+T(B4+T(B6+TB8))
	fadd.s	COSB1(pc),fp1	* B1+T(B3+T(B5+TB7))

	fmul.x	fp2,fp0	* S(B2+T(B4+T(B6+TB8)))

	fadd.x	fp1,fp0

	fmul.x	X(a6),fp0

	fmovem.x	(sp)+,fp2-fp3	* restore fp2/fp3

	fmove.l	d0,fpcr	* restore users round mode,prec
	fadd.s	POSNEG1(a6),fp0	* last inst - possible exception set
	bra	t_inx2

**********************************************

* SINe: Big OR Small?
*--IF |X| > 15PI, WE USE THE GENERAL ARGUMENT REDUCTION.
*--IF |X| < 2**(-40), RETURN X OR 1.
SINBORS:
	ICMP.l	d1,#$3FFF8000
	bgt.l	SREDUCEX

SINSM:
	move.l	ADJN(a6),d1
	ICMP.l	d1,#0
	bgt.b	COSTINY

* here, the operation may underflow iff the precision is sgl or dbl.
* extended denorms are handled through another entry point.
SINTINY:
*	move.w	#$0000,XDCARE(a6)	* JUST IN CASE

	fmove.l	d0,fpcr	* restore users round mode,prec
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	X(a6),fp0	* last inst - possible exception set
	bra	t_catch

COSTINY:
	fmove.s	#$3F800000,fp0	* fp0 = 1.0
	fmove.l	d0,fpcr	* restore users round mode,prec
	fadd.s 	#$80800000,fp0	* last inst - possible exception set
	bra	t_pinx2

************************************************
	xdef	ssind
*--SIN(X) = X FOR DENORMALIZED X
ssind:
	bra	t_extdnrm

********************************************
	xdef	scosd
*--COS(X) = 1 FOR DENORMALIZED X
scosd:
	fmove.s	#$3F800000,fp0	* fp0 = 1.0
	bra	t_pinx2

**************************************************

	xdef	ssincos
ssincos:
*--SET ADJN TO 4
	move.l	#4,ADJN(a6)

	fmove.x	(a0),fp0	* LOAD INPUT
	fmove.x	fp0,X(a6)

	move.l	(a0),d1
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1	* COMPACTIFY X

	ICMP.l	d1,#$3FD78000	* |X| >= 2**(-40)?
	bge.b	SCOK1
	bra.w	SCSM

SCOK1:
	ICMP.l	d1,#$4004BC7E	* |X| < 15 PI?
	blt.b	SCMAIN
	bra.w	SREDUCEX


*--THIS IS THE USUAL CASE, |X| <= 15 PI.
*--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
SCMAIN:
	fmove.x	fp0,fp1

	fmul.d	TWOBYPI(pc),fp1	* X*2/PI

	lea	PITBL+$200(pc),a1	* TABLE OF N*PI/2, N = -32,...,32

	fmove.l	fp1,INT(a6)	* CONVERT TO INTEGER

	move.l	INT(a6),d1
	asl.l	#4,d1
	add.l	d1,a1	* ADDRESS OF N*PIBY2, IN Y1, Y2

	fsub.x	(a1)+,fp0	* X-Y1
	fsub.s	(a1),fp0	* FP0 IS R = (X-Y1)-Y2

SCCONT:
*--continuation point from REDUCEX

	move.l	INT(a6),d1
	ror.l	#1,d1
	ICMP.l	d1,#0	* D0 < 0 IFF N IS ODD
	bge.w	NEVEN

SNODD:
*--REGISTERS SAVED SO FAR: D0, A0, FP2.
	fmovem.x	fp2,-(sp)	* save fp2

	fmove.x	fp0,RPRIME(a6)
	fmul.x	fp0,fp0	* FP0 IS S = R*R
	fmove.d	SINA7(pc),fp1	* A7
	fmove.d	COSB8(pc),fp2	* B8
	fmul.x	fp0,fp1	* SA7
	fmul.x	fp0,fp2	* SB8

	move.l	d2,-(sp)
	move.l	d1,d2
	ror.l	#1,d2
	and.l	#$80000000,d2
	eor.l	d1,d2
	and.l	#$80000000,d2

	fadd.d	SINA6(pc),fp1	* A6+SA7
	fadd.d	COSB7(pc),fp2	* B7+SB8

	fmul.x	fp0,fp1	* S(A6+SA7)
	eor.l	d2,RPRIME(a6)
	move.l	(sp)+,d2
	fmul.x	fp0,fp2	* S(B7+SB8)
	ror.l	#1,d1
	and.l	#$80000000,d1
	move.l	#$3F800000,POSNEG1(a6)
	eor.l	d1,POSNEG1(a6)

	fadd.d	SINA5(pc),fp1	* A5+S(A6+SA7)
	fadd.d	COSB6(pc),fp2	* B6+S(B7+SB8)

	fmul.x	fp0,fp1	* S(A5+S(A6+SA7))
	fmul.x	fp0,fp2	* S(B6+S(B7+SB8))
	fmove.x	fp0,SPRIME(a6)

	fadd.d	SINA4(pc),fp1	* A4+S(A5+S(A6+SA7))
	eor.l	d1,SPRIME(a6)
	fadd.d	COSB5(pc),fp2	* B5+S(B6+S(B7+SB8))

	fmul.x	fp0,fp1	* S(A4+...)
	fmul.x	fp0,fp2	* S(B5+...)

	fadd.d	SINA3(pc),fp1	* A3+S(A4+...)
	fadd.d	COSB4(pc),fp2	* B4+S(B5+...)

	fmul.x	fp0,fp1	* S(A3+...)
	fmul.x	fp0,fp2	* S(B4+...)

	fadd.x	SINA2(pc),fp1	* A2+S(A3+...)
	fadd.x	COSB3(pc),fp2	* B3+S(B4+...)

	fmul.x	fp0,fp1	* S(A2+...)
	fmul.x	fp0,fp2	* S(B3+...)

	fadd.x	SINA1(pc),fp1	* A1+S(A2+...)
	fadd.x	COSB2(pc),fp2	* B2+S(B3+...)

	fmul.x	fp0,fp1	* S(A1+...)
	fmul.x	fp2,fp0	* S(B2+...)

	fmul.x	RPRIME(a6),fp1	* R'S(A1+...)
	fadd.s	COSB1(pc),fp0	* B1+S(B2...)
	fmul.x	SPRIME(a6),fp0	* S'(B1+S(B2+...))

	fmovem.x	(sp)+,fp2	* restore fp2

	fmove.l	d0,fpcr
	fadd.x	RPRIME(a6),fp1	* COS(X)
	bsr	sto_cos	* store cosine result
	fadd.s	POSNEG1(a6),fp0	* SIN(X)
	bra	t_inx2

NEVEN:
*--REGISTERS SAVED SO FAR: FP2.
	fmovem.x	fp2,-(sp)	* save fp2

	fmove.x	fp0,RPRIME(a6)
	fmul.x	fp0,fp0	* FP0 IS S = R*R

	fmove.d	COSB8(pc),fp1	* B8
	fmove.d	SINA7(pc),fp2	* A7

	fmul.x	fp0,fp1	* SB8
	fmove.x	fp0,SPRIME(a6)
	fmul.x	fp0,fp2	* SA7

	ror.l	#1,d1
	and.l	#$80000000,d1

	fadd.d	COSB7(pc),fp1	* B7+SB8
	fadd.d	SINA6(pc),fp2	* A6+SA7

	eor.l	d1,RPRIME(a6)
	eor.l	d1,SPRIME(a6)

	fmul.x	fp0,fp1	* S(B7+SB8)

	or.l	#$3F800000,d1
	move.l	d1,POSNEG1(a6)

	fmul.x	fp0,fp2	* S(A6+SA7)

	fadd.d	COSB6(pc),fp1	* B6+S(B7+SB8)
	fadd.d	SINA5(pc),fp2	* A5+S(A6+SA7)

	fmul.x	fp0,fp1	* S(B6+S(B7+SB8))
	fmul.x	fp0,fp2	* S(A5+S(A6+SA7))

	fadd.d	COSB5(pc),fp1	* B5+S(B6+S(B7+SB8))
	fadd.d	SINA4(pc),fp2	* A4+S(A5+S(A6+SA7))

	fmul.x	fp0,fp1	* S(B5+...)
	fmul.x	fp0,fp2	* S(A4+...)

	fadd.d	COSB4(pc),fp1	* B4+S(B5+...)
	fadd.d	SINA3(pc),fp2	* A3+S(A4+...)

	fmul.x	fp0,fp1	* S(B4+...)
	fmul.x	fp0,fp2	* S(A3+...)

	fadd.x	COSB3(pc),fp1	* B3+S(B4+...)
	fadd.x	SINA2(pc),fp2	* A2+S(A3+...)

	fmul.x	fp0,fp1	* S(B3+...)
	fmul.x	fp0,fp2	* S(A2+...)

	fadd.x	COSB2(pc),fp1	* B2+S(B3+...)
	fadd.x	SINA1(pc),fp2	* A1+S(A2+...)

	fmul.x	fp0,fp1	* S(B2+...)
	fmul.x	fp2,fp0	* s(a1+...)


	fadd.s	COSB1(pc),fp1	* B1+S(B2...)
	fmul.x	RPRIME(a6),fp0	* R'S(A1+...)
	fmul.x	SPRIME(a6),fp1	* S'(B1+S(B2+...))

	fmovem.x	(sp)+,fp2	* restore fp2

	fmove.l	d0,fpcr
	fadd.s	POSNEG1(a6),fp1	* COS(X)
	bsr	sto_cos	* store cosine result
	fadd.x	RPRIME(a6),fp0	* SIN(X)
	bra	t_inx2

************************************************

SCBORS:
	ICMP.l	d1,#$3FFF8000
	bgt.w	SREDUCEX

************************************************

SCSM:
*	move.w	#$0000,XDCARE(a6)
	fmove.s	#$3F800000,fp1

	fmove.l	d0,fpcr
	fsub.s	#$00800000,fp1
	bsr	sto_cos	* store cosine result
	fmove.l	fpcr,d0	* d0 must have fpcr,too
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	X(a6),fp0
	bra	t_catch

**********************************************

	xdef	ssincosd
*--SIN AND COS OF X FOR DENORMALIZED X
ssincosd:
	move.l	d0,-(sp)	* save d0
	fmove.s	#$3F800000,fp1
	bsr	sto_cos	* store cosine result
	move.l	(sp)+,d0	* restore d0
	bra	t_extdnrm

********************************************

*--WHEN REDUCEX IS USED, THE CODE WILL INEVITABLY BE SLOW.
*--THIS REDUCTION METHOD, HOWEVER, IS MUCH FASTER THAN USING
*--THE REMAINDER INSTRUCTION WHICH IS NOW IN SOFTWARE.
SREDUCEX:
	fmovem.x	fp2-fp5,-(sp)	* save {fp2-fp5}
	move.l	d2,-(sp)	* save d2
	fmove.s	#$00000000,fp1	* fp1 = 0

*--If compact form of abs(arg) in d0=$7ffeffff, argument is so large that
*--there is a danger of unwanted overflow in first LOOP iteration.  In this
*--case, reduce argument by one remainder step to make subsequent reduction
*--safe.
	ICMP.l	d1,#$7ffeffff	* is arg dangerously large?
	bne.b	SLOOP	* no

* yes; create 2**16383*PI/2
	move.w	#$7ffe,EXC_LV+FP_SCR0_EX(a6)
	move.l	#$c90fdaa2,EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)

* create low half of 2**16383*PI/2 at EXC_LV+FP_SCR1
	move.w	#$7fdc,EXC_LV+FP_SCR1_EX(a6)
	move.l	#$85a308d3,EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)

	ftst.x	fp0	* test sign of argument
	fblt.w	sred_neg

	or.b	#$80,EXC_LV+FP_SCR0_EX(a6)	* positive arg
	or.b	#$80,EXC_LV+FP_SCR1_EX(a6)
sred_neg:
	fadd.x	EXC_LV+FP_SCR0(a6),fp0	* high part of reduction is exact
	fmove.x	fp0,fp1	* save high result in fp1
	fadd.x	EXC_LV+FP_SCR1(a6),fp0	* low part of reduction
	fsub.x	fp0,fp1	* determine low component of result
	fadd.x	EXC_LV+FP_SCR1(a6),fp1	* fp0/fp1 are reduced argument.

*--ON ENTRY, FP0 IS X, ON RETURN, FP0 IS X REM PI/2, |X| <= PI/4.
*--integer quotient will be stored in N
*--Intermeditate remainder is 66-bit dc.l; (R,r) in (FP0,FP1)
SLOOP:
	fmove.x	fp0,INARG(a6)	* +-2**K * F, 1 <= F < 2
	move.w	INARG(a6),d1
	move.l	d1,a1	* save a copy of D0
	and.l	#$00007FFF,d1
	sub.l	#$00003FFF,d1	* d0 = K
	ICMP.l	d1,#28
	ble.b	SLASTLOOP
SCONTLOOP:
	sub.l	#27,d1	* d0 = L := K-27
	move.b	#0,ENDFLAG(a6)
	bra.b	SWORK
SLASTLOOP:
	clr.l	d1	* d0 = L := 0
	move.b	#1,ENDFLAG(a6)

SWORK:
*--FIND THE REMAINDER OF (R,r) W.R.T.	2**L * (PI/2). L IS SO CHOSEN
*--THAT	INT( X * (2/PI) / 2**(L) ) < 2**29.

*--CREATE 2**(-L) * (2/PI), SIGN(INARG)*2**(63),
*--2**L * (PIby2_1), 2**L * (PIby2_2)

	move.l	#$00003FFE,d2	* BIASED EXP OF 2/PI
	sub.l	d1,d2	* BIASED EXP OF 2**(-L)*(2/PI)

	move.l	#$A2F9836E,EXC_LV+FP_SCR0_HI(a6)
	move.l	#$4E44152A,EXC_LV+FP_SCR0_LO(a6)
	move.w	d2,EXC_LV+FP_SCR0_EX(a6)	* EXC_LV+FP_SCR0 = 2**(-L)*(2/PI)

	fmove.x	fp0,fp2
	fmul.x	EXC_LV+FP_SCR0(a6),fp2	* fp2 = X * 2**(-L)*(2/PI)

*--WE MUST NOW FIND INT(FP2). SINCE WE NEED THIS VALUE IN
*--FLOATING POINT FORMAT, THE TWO FMOVE'S	FMOVE.L FP <--> N
*--WILL BE TOO INEFFICIENT. THE WAY AROUND IT IS THAT
*--(SIGN(INARG)*2**63	+	FP2) - SIGN(INARG)*2**63 WILL GIVE
*--US THE DESIRED VALUE IN FLOATING POINT.
	move.l	a1,d2
	swap	d2
	and.l	#$80000000,d2
	or.l	#$5F000000,d2	* d2 = SIGN(INARG)*2**63 IN SGL
	move.l	d2,TWOTO63(a6)
	fadd.s	TWOTO63(a6),fp2	* THE FRACTIONAL PART OF FP1 IS ROUNDED
	fsub.s	TWOTO63(a6),fp2	* fp2 = N
*	fint.x	fp2

*--CREATING 2**(L)*Piby2_1 and 2**(L)*Piby2_2
	move.l	d1,d2	* d2 = L

	add.l	#$00003FFF,d2	* BIASED EXP OF 2**L * (PI/2)
	move.w	d2,EXC_LV+FP_SCR0_EX(a6)
	move.l	#$C90FDAA2,EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)	* EXC_LV+FP_SCR0 = 2**(L) * Piby2_1

	add.l	#$00003FDD,d1
	move.w	d1,EXC_LV+FP_SCR1_EX(a6)
	move.l	#$85A308D3,EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)	* EXC_LV+FP_SCR1 = 2**(L) * Piby2_2

	move.b	ENDFLAG(a6),d1

*--We are now ready to perform (R+r) - N*P1 - N*P2, P1 = 2**(L) * Piby2_1 and
*--P2 = 2**(L) * Piby2_2
	fmove.x	fp2,fp4	* fp4 = N
	fmul.x	EXC_LV+FP_SCR0(a6),fp4	* fp4 = W = N*P1
	fmove.x	fp2,fp5	* fp5 = N
	fmul.x	EXC_LV+FP_SCR1(a6),fp5	* fp5 = w = N*P2
	fmove.x	fp4,fp3	* fp3 = W = N*P1

*--we want P+p = W+w  but  |p| <= half ulp of P
*--Then, we need to compute  A := R-P   and  a := r-p
	fadd.x	fp5,fp3	* fp3 = P
	fsub.x	fp3,fp4	* fp4 = W-P

	fsub.x	fp3,fp0	* fp0 = A := R - P
	fadd.x	fp5,fp4	* fp4 = p = (W-P)+w

	fmove.x	fp0,fp3	* fp3 = A
	fsub.x	fp4,fp1	* fp1 = a := r - p

*--Now we need to normalize (A,a) to  "new (R,r)" where R+r = A+a but
*--|r| <= half ulp of R.
	fadd.x	fp1,fp0	* fp0 = R := A+a
*--No need to calculate r if this is the last loop
	ICMP.b	d1,#0
	bgt.w	SRESTORE

*--Need to calculate r
	fsub.x	fp0,fp3	* fp3 = A-R
	fadd.x	fp3,fp1	* fp1 = r := (A-R)+a
	bra.w	SLOOP

SRESTORE:
	fmove.l	fp2,INT(a6)
	move.l	(sp)+,d2	* restore d2
	fmovem.x	(sp)+,fp2-fp5	* restore {fp2-fp5}

	move.l	ADJN(a6),d1
	ICMP.l	d1,#4

	blt.w	SINCONT
	bra.w	SCCONT

**-------------------------------------------------------------------------------------------------
* sasin():  computes the inverse sine of a normalized input
* sasind(): computes the inverse sine of a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************	* 
*	fp0 = arcsin(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in	64 significant bit,
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*	ASIN	
*	1. If |X| >= 1, go to 3.	
*		
*	2. (|X| < 1) Calculate asin(X) by
*	z := sqrt( [1-X][1+X] )	
*	asin(X) = atan( x / z ).
*	Exit.	
*		
*	3. If |X| > 1, go to 5.	
*		
*	4. (|X| = 1) sgn := sign(X), return asin(X) := sgn * Pi/2. Exit.*
*		
*	5. (|X| > 1) Generate an invalid operation by 0 * infinity.
*	Exit.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	sasin
sasin:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1,#$3FFF8000
	bge.b	ASINBIG

* This catch is added here for the '060 QSP. Originally, the call to
* satan() would handle this case by causing the exception which would
* not be caught until gen_except(). Now, with the exceptions being 
* detected inside of satan(), the exception would have been handled there
* instead of inside sasin() as expected.
	ICMP.l	d1,#$3FD78000
	blt.w	ASINTINY

*--THIS IS THE USUAL CASE, |X| < 1
*--ASIN(X) = ATAN( X / SQRT( (1-X)(1+X) ) )

ASINMAIN:
	fmove.s	#$3F800000,fp1
	fsub.x	fp0,fp1	* 1-X
	fmovem.x	fp2,-(sp)	*  {fp2}
	fmove.s	#$3F800000,fp2
	fadd.x	fp0,fp2	* 1+X
	fmul.x	fp2,fp1	* (1+X)(1-X)
	fmovem.x	(sp)+,fp2	*  {fp2}
	fsqrt.x	fp1	* SQRT([1-X][1+X])
	fdiv.x	fp1,fp0	* X/SQRT([1-X][1+X])
	fmovem.x	fp0,-(sp)	* save X/SQRT(...)
	lea	(sp),a0	* pass ptr to X/SQRT(...)
	bsr	satan
	add.l	#$c,sp	* clear X/SQRT(...) from stack
	bra	t_inx2

ASINBIG:
	fabs.x	fp0	* |X|
	fcmp.s	#$3F800000,fp0
	fbgt	t_operr	* cause an operr exception

*--|X| = 1, ASIN(X) = +- PI/2.
ASINONE:
	fmove.x	PIBY2(pc),fp0
	move.l	(a0),d1
	and.l	#$80000000,d1	* SIGN BIT OF X
	or.l	#$3F800000,d1	* +-1 IN SGL FORMAT
	move.l	d1,-(sp)	* push SIGN(X) IN SGL-FMT
	fmove.l	d0,fpcr
	fmul.s	(sp)+,fp0
	bra	t_inx2

*--|X| < 2^(-40), ATAN(X) = X
ASINTINY:
	fmove.l	d0,fpcr	* restore users rnd mode,prec
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	(a0),fp0	* last inst - possible exception
	bra	t_catch

	xdef	sasind
*--ASIN(X) = X FOR DENORMALIZED X
sasind:
	bra	t_extdnrm

**-------------------------------------------------------------------------------------------------
* sacos():  computes the inverse cosine of a normalized input
* sacosd(): computes the inverse cosine of a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT ************************************************************** *
*	fp0 = arccos(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in	64 significant bit,
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM *********************************************************** *
*		
*	ACOS	
*	1. If |X| >= 1, go to 3.	
*		
*	2. (|X| < 1) Calculate acos(X) by
*	z := (1-X) / (1+X)	
*	acos(X) = 2 * atan( sqrt(z) ).
*	Exit.	
*		
*	3. If |X| > 1, go to 5.	
*		
*	4. (|X| = 1) If X > 0, return 0. Otherwise, return Pi. Exit.
*		
*	5. (|X| > 1) Generate an invalid operation by 0 * infinity.
*	Exit.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	sacos
sacos:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1	* pack exp w/ upper 16 fraction
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1,#$3FFF8000
	bge.b	ACOSBIG

*--THIS IS THE USUAL CASE, |X| < 1
*--ACOS(X) = 2 * ATAN(	SQRT( (1-X)/(1+X) ) )

ACOSMAIN:
	fmove.s	#$3F800000,fp1
	fadd.x	fp0,fp1	* 1+X
	fneg.x	fp0	* -X
	fadd.s	#$3F800000,fp0	* 1-X
	fdiv.x	fp1,fp0	* (1-X)/(1+X)
	fsqrt.x	fp0	* SQRT((1-X)/(1+X))
	move.l	d0,-(sp)	* save original users fpcr
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save SQRT(...) to stack
	lea	(sp),a0	* pass ptr to sqrt
	bsr	satan	* ATAN(SQRT([1-X]/[1+X]))
	add.l	#$c,sp	* clear SQRT(...) from stack

	fmove.l	(sp)+,fpcr	* restore users round prec,mode
	fadd.x	fp0,fp0	* 2 * ATAN( STUFF )
	bra	t_pinx2

ACOSBIG:
	fabs.x	fp0
	fcmp.s	#$3F800000,fp0
	fbgt	t_operr	* cause an operr exception

*--|X| = 1, ACOS(X) = 0 OR PI
	tst.b	(a0)	* is X positive or negative?
	bpl.b	ACOSP1

*--X = -1
*Returns PI and inexact exception
ACOSM1:
	fmove.x	PI(pc),fp0	* load PI
	fmove.l	d0,fpcr	* load round mode,prec
	fadd.s	#$00800000,fp0	* add a small value
	bra	t_pinx2

ACOSP1:
	bra	ld_pzero	* answer is positive zero

	xdef	sacosd
*--ACOS(X) = PI/2 FOR DENORMALIZED X
sacosd:
	fmove.l	d0,fpcr	* load user's rnd mode/prec
	fmove.x	PIBY2(pc),fp0
	bra	t_pinx2



**-------------------------------------------------------------------------------------------------
* stan():  computes the tangent of a normalized input
* stand(): computes the tangent of a denormalized input
*
* INPUT *************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode
*
* OUTPUT ************************************************************** *
*	fp0 = tan(X)
*
* ACCURACY and MONOTONICITY ******************************************* *
*	The returned result is within 3 ulp in 64 significant bit, i.e. *
*	within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.
*
* ALGORITHM *********************************************************** *
*
*	1. If |X| >= 15Pi or |X| < 2**(-40), go to 6.
*
*	2. Decompose X as X = N(Pi/2) + r where |r| <= Pi/4. Let
*	k = N mod 2, so in particular, k = 0 or 1.
*
*	3. If k is odd, go to 5.
*
*	4. (k is even) Tan(X) = tan(r) and tan(r) is approximated by a
*	rational function U/V where
*	U = r + r*s*(P1 + s*(P2 + s*P3)), and
*	V = 1 + s*(Q1 + s*(Q2 + s*(Q3 + s*Q4))),  s = r*r.
*	Exit.
*
*	4. (k is odd) Tan(X) = -cot(r). Since tan(r) is approximated by *
*	a rational function U/V where
*	U = r + r*s*(P1 + s*(P2 + s*P3)), and
*	V = 1 + s*(Q1 + s*(Q2 + s*(Q3 + s*Q4))), s = r*r,
*	-Cot(r) = -V/U. Exit.
*
*	6. If |X| > 1, go to 8.
*
*	7. (|X|<2**(-40)) Tan(X) = X. Exit.
*
*	8. Overwrite X by X := X rem 2Pi. Now that |X| <= Pi, go back
*	to 2.
*
**-------------------------------------------------------------------------------------------------

TANQ4:
	dc.l	$3EA0B759,$F50F8688
TANP3:
	dc.l	$BEF2BAA5,$A8924F04

TANQ3:
	dc.l	$BF346F59,$B39BA65F,$00000000,$00000000

TANP2:
	dc.l	$3FF60000,$E073D3FC,$199C4A00,$00000000

TANQ2:
	dc.l	$3FF90000,$D23CD684,$15D95FA1,$00000000

TANP1:
	dc.l	$BFFC0000,$8895A6C5,$FB423BCA,$00000000

TANQ1:
	dc.l	$BFFD0000,$EEF57E0D,$A84BC8CE,$00000000

INVTWOPI:
	dc.l	$3FFC0000,$A2F9836E,$4E44152A,$00000000

TWOPI1:
	dc.l	$40010000,$C90FDAA2,$00000000,$00000000
TWOPI2:
	dc.l	$3FDF0000,$85A308D4,$00000000,$00000000

*--N*PI/2, -32 <= N <= 32, IN A LEADING TERM IN EXT. AND TRAILING
*--TERM IN SGL. NOTE THAT PI IS 64-BIT LONG, THUS N*PI/2 IS AT
*--MOST 69 BITS LONG.
*	xdef	PITBL
PITBL:
	dc.l	$C0040000,$C90FDAA2,$2168C235,$21800000
	dc.l	$C0040000,$C2C75BCD,$105D7C23,$A0D00000
	dc.l	$C0040000,$BC7EDCF7,$FF523611,$A1E80000
	dc.l	$C0040000,$B6365E22,$EE46F000,$21480000
	dc.l	$C0040000,$AFEDDF4D,$DD3BA9EE,$A1200000
	dc.l	$C0040000,$A9A56078,$CC3063DD,$21FC0000
	dc.l	$C0040000,$A35CE1A3,$BB251DCB,$21100000
	dc.l	$C0040000,$9D1462CE,$AA19D7B9,$A1580000
	dc.l	$C0040000,$96CBE3F9,$990E91A8,$21E00000
	dc.l	$C0040000,$90836524,$88034B96,$20B00000
	dc.l	$C0040000,$8A3AE64F,$76F80584,$A1880000
	dc.l	$C0040000,$83F2677A,$65ECBF73,$21C40000
	dc.l	$C0030000,$FB53D14A,$A9C2F2C2,$20000000
	dc.l	$C0030000,$EEC2D3A0,$87AC669F,$21380000
	dc.l	$C0030000,$E231D5F6,$6595DA7B,$A1300000
	dc.l	$C0030000,$D5A0D84C,$437F4E58,$9FC00000
	dc.l	$C0030000,$C90FDAA2,$2168C235,$21000000
	dc.l	$C0030000,$BC7EDCF7,$FF523611,$A1680000
	dc.l	$C0030000,$AFEDDF4D,$DD3BA9EE,$A0A00000
	dc.l	$C0030000,$A35CE1A3,$BB251DCB,$20900000
	dc.l	$C0030000,$96CBE3F9,$990E91A8,$21600000
	dc.l	$C0030000,$8A3AE64F,$76F80584,$A1080000
	dc.l	$C0020000,$FB53D14A,$A9C2F2C2,$1F800000
	dc.l	$C0020000,$E231D5F6,$6595DA7B,$A0B00000
	dc.l	$C0020000,$C90FDAA2,$2168C235,$20800000
	dc.l	$C0020000,$AFEDDF4D,$DD3BA9EE,$A0200000
	dc.l	$C0020000,$96CBE3F9,$990E91A8,$20E00000
	dc.l	$C0010000,$FB53D14A,$A9C2F2C2,$1F000000
	dc.l	$C0010000,$C90FDAA2,$2168C235,$20000000
	dc.l	$C0010000,$96CBE3F9,$990E91A8,$20600000
	dc.l	$C0000000,$C90FDAA2,$2168C235,$1F800000
	dc.l	$BFFF0000,$C90FDAA2,$2168C235,$1F000000
	dc.l	$00000000,$00000000,$00000000,$00000000
	dc.l	$3FFF0000,$C90FDAA2,$2168C235,$9F000000
	dc.l	$40000000,$C90FDAA2,$2168C235,$9F800000
	dc.l	$40010000,$96CBE3F9,$990E91A8,$A0600000
	dc.l	$40010000,$C90FDAA2,$2168C235,$A0000000
	dc.l	$40010000,$FB53D14A,$A9C2F2C2,$9F000000
	dc.l	$40020000,$96CBE3F9,$990E91A8,$A0E00000
	dc.l	$40020000,$AFEDDF4D,$DD3BA9EE,$20200000
	dc.l	$40020000,$C90FDAA2,$2168C235,$A0800000
	dc.l	$40020000,$E231D5F6,$6595DA7B,$20B00000
	dc.l	$40020000,$FB53D14A,$A9C2F2C2,$9F800000
	dc.l	$40030000,$8A3AE64F,$76F80584,$21080000
	dc.l	$40030000,$96CBE3F9,$990E91A8,$A1600000
	dc.l	$40030000,$A35CE1A3,$BB251DCB,$A0900000
	dc.l	$40030000,$AFEDDF4D,$DD3BA9EE,$20A00000
	dc.l	$40030000,$BC7EDCF7,$FF523611,$21680000
	dc.l	$40030000,$C90FDAA2,$2168C235,$A1000000
	dc.l	$40030000,$D5A0D84C,$437F4E58,$1FC00000
	dc.l	$40030000,$E231D5F6,$6595DA7B,$21300000
	dc.l	$40030000,$EEC2D3A0,$87AC669F,$A1380000
	dc.l	$40030000,$FB53D14A,$A9C2F2C2,$A0000000
	dc.l	$40040000,$83F2677A,$65ECBF73,$A1C40000
	dc.l	$40040000,$8A3AE64F,$76F80584,$21880000
	dc.l	$40040000,$90836524,$88034B96,$A0B00000
	dc.l	$40040000,$96CBE3F9,$990E91A8,$A1E00000
	dc.l	$40040000,$9D1462CE,$AA19D7B9,$21580000
	dc.l	$40040000,$A35CE1A3,$BB251DCB,$A1100000
	dc.l	$40040000,$A9A56078,$CC3063DD,$A1FC0000
	dc.l	$40040000,$AFEDDF4D,$DD3BA9EE,$21200000
	dc.l	$40040000,$B6365E22,$EE46F000,$A1480000
	dc.l	$40040000,$BC7EDCF7,$FF523611,$21E80000
	dc.l	$40040000,$C2C75BCD,$105D7C23,$20D00000
	dc.l	$40040000,$C90FDAA2,$2168C235,$A1800000

*INT	equ	EXC_LV+L_SCR1
*ENDFLAG	equ	EXC_LV+L_SCR2

	xdef	stan
stan:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1

	ICMP.l	d1,#$3FD78000	* |X| >= 2**(-40)?
	bge.b	TANOK1
	bra.w	TANSM
TANOK1:
	ICMP.l	d1,#$4004BC7E	* |X| < 15 PI?
	blt.b	TANMAIN
	bra.w	REDUCEX

TANMAIN:
*--THIS IS THE USUAL CASE, |X| <= 15 PI.
*--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
	fmove.x	fp0,fp1
	fmul.d	TWOBYPI(pc),fp1	* X*2/PI

	lea.l	PITBL+$200(pc),a1	* TABLE OF N*PI/2, N = -32,...,32

	fmove.l	fp1,d1	* CONVERT TO INTEGER

	asl.l	#4,d1
	add.l	d1,a1	* ADDRESS N*PIBY2 IN Y1, Y2

	fsub.x	(a1)+,fp0	* X-Y1

	fsub.s	(a1),fp0	* FP0 IS R = (X-Y1)-Y2

	ror.l	#5,d1
	and.l	#$80000000,d1	* D0 WAS ODD IFF D0 < 0

TANCONT:
	fmovem.x	fp2-fp3,-(sp)	* save fp2,fp3

	ICMP.l	d1,#0
	blt.w	NODD

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* S = R*R

	fmove.d	TANQ4(pc),fp3
	fmove.d	TANP3(pc),fp2

	fmul.x	fp1,fp3	* SQ4
	fmul.x	fp1,fp2	* SP3

	fadd.d	TANQ3(pc),fp3	* Q3+SQ4
	fadd.x	TANP2(pc),fp2	* P2+SP3

	fmul.x	fp1,fp3	* S(Q3+SQ4)
	fmul.x	fp1,fp2	* S(P2+SP3)

	fadd.x	TANQ2(pc),fp3	* Q2+S(Q3+SQ4)
	fadd.x	TANP1(pc),fp2	* P1+S(P2+SP3)

	fmul.x	fp1,fp3	* S(Q2+S(Q3+SQ4))
	fmul.x	fp1,fp2	* S(P1+S(P2+SP3))

	fadd.x	TANQ1(pc),fp3	* Q1+S(Q2+S(Q3+SQ4))
	fmul.x	fp0,fp2	* RS(P1+S(P2+SP3))

	fmul.x	fp3,fp1	* S(Q1+S(Q2+S(Q3+SQ4)))

	fadd.x	fp2,fp0	* R+RS(P1+S(P2+SP3))

	fadd.s	#$3F800000,fp1	* 1+S(Q1+...)

	fmovem.x	(sp)+,fp2-fp3	* restore fp2,fp3

	fmove.l	d0,fpcr	* restore users round mode,prec
	fdiv.x	fp1,fp0	* last inst - possible exception set
	bra	t_inx2

NODD:
	fmove.x	fp0,fp1
	fmul.x	fp0,fp0	* S = R*R

	fmove.d	TANQ4(pc),fp3
	fmove.d	TANP3(pc),fp2

	fmul.x	fp0,fp3	* SQ4
	fmul.x	fp0,fp2	* SP3

	fadd.d	TANQ3(pc),fp3	* Q3+SQ4
	fadd.x	TANP2(pc),fp2	* P2+SP3

	fmul.x	fp0,fp3	* S(Q3+SQ4)
	fmul.x	fp0,fp2	* S(P2+SP3)

	fadd.x	TANQ2(pc),fp3	* Q2+S(Q3+SQ4)
	fadd.x	TANP1(pc),fp2	* P1+S(P2+SP3)

	fmul.x	fp0,fp3	* S(Q2+S(Q3+SQ4))
	fmul.x	fp0,fp2	* S(P1+S(P2+SP3))

	fadd.x	TANQ1(pc),fp3	* Q1+S(Q2+S(Q3+SQ4))
	fmul.x	fp1,fp2	* RS(P1+S(P2+SP3))

	fmul.x	fp3,fp0	* S(Q1+S(Q2+S(Q3+SQ4)))

	fadd.x	fp2,fp1	* R+RS(P1+S(P2+SP3))
	fadd.s	#$3F800000,fp0	* 1+S(Q1+...)

	fmovem.x	(sp)+,fp2-fp3	* restore fp2,fp3

	fmove.x	fp1,-(sp)
	eor.l	#$80000000,(sp)

	fmove.l	d0,fpcr	* restore users round mode,prec
	fdiv.x	(sp)+,fp0	* last inst - possible exception set
	bra	t_inx2

TANBORS:
*--IF |X| > 15PI, WE USE THE GENERAL ARGUMENT REDUCTION.
*--IF |X| < 2**(-40), RETURN X OR 1.
	ICMP.l	d1,#$3FFF8000
	bgt.b	REDUCEX

TANSM:
	fmove.x	fp0,-(sp)
	fmove.l	d0,fpcr	* restore users round mode,prec
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	(sp)+,fp0	* last inst - posibble exception set
	bra	t_catch

	xdef	stand
*--TAN(X) = X FOR DENORMALIZED X
stand:
	bra	t_extdnrm

*--WHEN REDUCEX IS USED, THE CODE WILL INEVITABLY BE SLOW.
*--THIS REDUCTION METHOD, HOWEVER, IS MUCH FASTER THAN USING
*--THE REMAINDER INSTRUCTION WHICH IS NOW IN SOFTWARE.
REDUCEX:
	fmovem.x	fp2-fp5,-(sp)	* save {fp2-fp5}
	move.l	d2,-(sp)	* save d2
	fmove.s	#$00000000,fp1	* fp1 = 0

*--If compact form of abs(arg) in d0=$7ffeffff, argument is so large that
*--there is a danger of unwanted overflow in first LOOP iteration.  In this
*--case, reduce argument by one remainder step to make subsequent reduction
*--safe.
	ICMP.l	d1,#$7ffeffff	* is arg dangerously large?
	bne.b	LOOP	* no

* yes; create 2**16383*PI/2
	move.w	#$7ffe,EXC_LV+FP_SCR0_EX(a6)
	move.l	#$c90fdaa2,EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)

* create low half of 2**16383*PI/2 at EXC_LV+FP_SCR1
	move.w	#$7fdc,EXC_LV+FP_SCR1_EX(a6)
	move.l	#$85a308d3,EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)

	ftst.x	fp0	* test sign of argument
	fblt.w	red_neg

	or.b	#$80,EXC_LV+FP_SCR0_EX(a6)	* positive arg
	or.b	#$80,EXC_LV+FP_SCR1_EX(a6)
red_neg:
	fadd.x	EXC_LV+FP_SCR0(a6),fp0	* high part of reduction is exact
	fmove.x	fp0,fp1	* save high result in fp1
	fadd.x	EXC_LV+FP_SCR1(a6),fp0	* low part of reduction
	fsub.x	fp0,fp1	* determine low component of result
	fadd.x	EXC_LV+FP_SCR1(a6),fp1	* fp0/fp1 are reduced argument.

*--ON ENTRY, FP0 IS X, ON RETURN, FP0 IS X REM PI/2, |X| <= PI/4.
*--integer quotient will be stored in N
*--Intermeditate remainder is 66-bit dc.l; (R,r) in (FP0,FP1)
LOOP:
	fmove.x	fp0,INARG(a6)	* +-2**K * F, 1 <= F < 2
	move.w	INARG(a6),d1
	move.l	d1,a1	* save a copy of D0
	and.l	#$00007FFF,d1
	sub.l	#$00003FFF,d1	* d0 = K
	ICMP.l	d1,#28
	ble.b	LASTLOOP
CONTLOOP:
	sub.l	#27,d1	* d0 = L := K-27
	move.b	#0,ENDFLAG(a6)
	bra.b	WORK
LASTLOOP:
	clr.l	d1	* d0 = L := 0
	move.b	#1,ENDFLAG(a6)

WORK:
*--FIND THE REMAINDER OF (R,r) W.R.T.	2**L * (PI/2). L IS SO CHOSEN
*--THAT	INT( X * (2/PI) / 2**(L) ) < 2**29.

*--CREATE 2**(-L) * (2/PI), SIGN(INARG)*2**(63),
*--2**L * (PIby2_1), 2**L * (PIby2_2)

	move.l	#$00003FFE,d2	* BIASED EXP OF 2/PI
	sub.l	d1,d2	* BIASED EXP OF 2**(-L)*(2/PI)

	move.l	#$A2F9836E,EXC_LV+FP_SCR0_HI(a6)
	move.l	#$4E44152A,EXC_LV+FP_SCR0_LO(a6)
	move.w	d2,EXC_LV+FP_SCR0_EX(a6)	* EXC_LV+FP_SCR0 = 2**(-L)*(2/PI)

	fmove.x	fp0,fp2
	fmul.x	EXC_LV+FP_SCR0(a6),fp2	* fp2 = X * 2**(-L)*(2/PI)

*--WE MUST NOW FIND INT(FP2). SINCE WE NEED THIS VALUE IN
*--FLOATING POINT FORMAT, THE TWO FMOVE'S	FMOVE.L FP <--> N
*--WILL BE TOO INEFFICIENT. THE WAY AROUND IT IS THAT
*--(SIGN(INARG)*2**63	+	FP2) - SIGN(INARG)*2**63 WILL GIVE
*--US THE DESIRED VALUE IN FLOATING POINT.
	move.l	a1,d2
	swap	d2
	and.l	#$80000000,d2
	or.l	#$5F000000,d2	* d2 = SIGN(INARG)*2**63 IN SGL
	move.l	d2,TWOTO63(a6)
	fadd.s	TWOTO63(a6),fp2	* THE FRACTIONAL PART OF FP1 IS ROUNDED
	fsub.s	TWOTO63(a6),fp2	* fp2 = N
*	fintrz.x	fp2,fp2

*--CREATING 2**(L)*Piby2_1 and 2**(L)*Piby2_2
	move.l	d1,d2	* d2 = L

	add.l	#$00003FFF,d2	* BIASED EXP OF 2**L * (PI/2)
	move.w	d2,EXC_LV+FP_SCR0_EX(a6)
	move.l	#$C90FDAA2,EXC_LV+FP_SCR0_HI(a6)
	clr.l	EXC_LV+FP_SCR0_LO(a6)	* EXC_LV+FP_SCR0 = 2**(L) * Piby2_1

	add.l	#$00003FDD,d1
	move.w	d1,EXC_LV+FP_SCR1_EX(a6)
	move.l	#$85A308D3,EXC_LV+FP_SCR1_HI(a6)
	clr.l	EXC_LV+FP_SCR1_LO(a6)	* EXC_LV+FP_SCR1 = 2**(L) * Piby2_2

	move.b	ENDFLAG(a6),d1

*--We are now ready to perform (R+r) - N*P1 - N*P2, P1 = 2**(L) * Piby2_1 and
*--P2 = 2**(L) * Piby2_2
	fmove.x	fp2,fp4	* fp4 = N
	fmul.x	EXC_LV+FP_SCR0(a6),fp4	* fp4 = W = N*P1
	fmove.x	fp2,fp5	* fp5 = N
	fmul.x	EXC_LV+FP_SCR1(a6),fp5	* fp5 = w = N*P2
	fmove.x	fp4,fp3	* fp3 = W = N*P1

*--we want P+p = W+w  but  |p| <= half ulp of P
*--Then, we need to compute  A := R-P   and  a := r-p
	fadd.x	fp5,fp3	* fp3 = P
	fsub.x	fp3,fp4	* fp4 = W-P

	fsub.x	fp3,fp0	* fp0 = A := R - P
	fadd.x	fp5,fp4	* fp4 = p = (W-P)+w

	fmove.x	fp0,fp3	* fp3 = A
	fsub.x	fp4,fp1	* fp1 = a := r - p

*--Now we need to normalize (A,a) to  "new (R,r)" where R+r = A+a but
*--|r| <= half ulp of R.
	fadd.x	fp1,fp0	* fp0 = R := A+a
*--No need to calculate r if this is the last loop
	ICMP.b	d1,#0
	bgt.w	RESTORE

*--Need to calculate r
	fsub.x	fp0,fp3	* fp3 = A-R
	fadd.x	fp3,fp1	* fp1 = r := (A-R)+a
	bra.w	LOOP

RESTORE:
	fmove.l	fp2,INT(a6)
	move.l	(sp)+,d2	* restore d2
	fmovem.x	(sp)+,fp2-fp5	* restore {fp2-fp5}

	move.l	INT(a6),d1
	ror.l	#1,d1

	bra.w	TANCONT






**-------------------------------------------------------------------------------------------------
* satan():  computes the arctangent of a normalized number
* satand(): computes the arctangent of a denormalized number
*		
* INPUT	*************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT ************************************************************** *
*	fp0 = arctan(X)	
*		
* ACCURACY and MONOTONICITY ******************************************* *
*	The returned result is within 2 ulps in	64 significant bit,
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision. 	
*		
* ALGORITHM *********************************************************** *
*	Step 1. If |X| >= 16 or |X| < 1/16, go to Step 5.
*		
*	Step 2. Let X = sgn * 2**k * 1.xxxxxxxx...x. 
*	Note that k = -4, -3,..., or 3.
*	Define F = sgn * 2**k * 1.xxxx1, i.e. the first 5 
*	significant bits of X with a bit-1 attached at the 6-th
*	bit position. Define u to be u = (X-F) / (1 + X*F).
*		
*	Step 3. Approximate arctan(u) by a polynomial poly.
*		
*	Step 4. Return arctan(F) + poly, arctan(F) is fetched from a 
*	table of values calculated beforehand. Exit.
*		
*	Step 5. If |X| >= 16, go to Step 7.
*		
*	Step 6. Approximate arctan(X) by an odd polynomial in X. Exit.
*		
*	Step 7. Define X' = -1/X. Approximate arctan(X') by an odd 
*	polynomial in X'.	
*	Arctan(X) = sign(X)*Pi/2 + arctan(X'). Exit.
*		
**-------------------------------------------------------------------------------------------------

ATANA3:	dc.l	$BFF6687E,$314987D8
ATANA2:	dc.l	$4002AC69,$34A26DB3
ATANA1:	dc.l	$BFC2476F,$4E1DA28E

ATANB6:	dc.l	$3FB34444,$7F876989
ATANB5:	dc.l	$BFB744EE,$7FAF45DB
ATANB4:	dc.l	$3FBC71C6,$46940220
ATANB3:	dc.l	$BFC24924,$921872F9
ATANB2:	dc.l	$3FC99999,$99998FA9
ATANB1:	dc.l	$BFD55555,$55555555

ATANC5:	dc.l	$BFB70BF3,$98539E6A
ATANC4:	dc.l	$3FBC7187,$962D1D7D
ATANC3:	dc.l	$BFC24924,$827107B8
ATANC2:	dc.l	$3FC99999,$9996263E
ATANC1:	dc.l	$BFD55555,$55555536

PPIBY2:	dc.l	$3FFF0000,$C90FDAA2,$2168C235,$00000000
NPIBY2:	dc.l	$BFFF0000,$C90FDAA2,$2168C235,$00000000

PTINY:	dc.l	$00010000,$80000000,$00000000,$00000000
NTINY:	dc.l	$80010000,$80000000,$00000000,$00000000

ATANTBL:
	dc.l	$3FFB0000,$83D152C5,$060B7A51,$00000000
	dc.l	$3FFB0000,$8BC85445,$65498B8B,$00000000
	dc.l	$3FFB0000,$93BE4060,$17626B0D,$00000000
	dc.l	$3FFB0000,$9BB3078D,$35AEC202,$00000000
	dc.l	$3FFB0000,$A3A69A52,$5DDCE7DE,$00000000
	dc.l	$3FFB0000,$AB98E943,$62765619,$00000000
	dc.l	$3FFB0000,$B389E502,$F9C59862,$00000000
	dc.l	$3FFB0000,$BB797E43,$6B09E6FB,$00000000
	dc.l	$3FFB0000,$C367A5C7,$39E5F446,$00000000
	dc.l	$3FFB0000,$CB544C61,$CFF7D5C6,$00000000
	dc.l	$3FFB0000,$D33F62F8,$2488533E,$00000000
	dc.l	$3FFB0000,$DB28DA81,$62404C77,$00000000
	dc.l	$3FFB0000,$E310A407,$8AD34F18,$00000000
	dc.l	$3FFB0000,$EAF6B0A8,$188EE1EB,$00000000
	dc.l	$3FFB0000,$F2DAF194,$9DBE79D5,$00000000
	dc.l	$3FFB0000,$FABD5813,$61D47E3E,$00000000
	dc.l	$3FFC0000,$8346AC21,$0959ECC4,$00000000
	dc.l	$3FFC0000,$8B232A08,$304282D8,$00000000
	dc.l	$3FFC0000,$92FB70B8,$D29AE2F9,$00000000
	dc.l	$3FFC0000,$9ACF476F,$5CCD1CB4,$00000000
	dc.l	$3FFC0000,$A29E7630,$4954F23F,$00000000
	dc.l	$3FFC0000,$AA68C5D0,$8AB85230,$00000000
	dc.l	$3FFC0000,$B22DFFFD,$9D539F83,$00000000
	dc.l	$3FFC0000,$B9EDEF45,$3E900EA5,$00000000
	dc.l	$3FFC0000,$C1A85F1C,$C75E3EA5,$00000000
	dc.l	$3FFC0000,$C95D1BE8,$28138DE6,$00000000
	dc.l	$3FFC0000,$D10BF300,$840D2DE4,$00000000
	dc.l	$3FFC0000,$D8B4B2BA,$6BC05E7A,$00000000
	dc.l	$3FFC0000,$E0572A6B,$B42335F6,$00000000
	dc.l	$3FFC0000,$E7F32A70,$EA9CAA8F,$00000000
	dc.l	$3FFC0000,$EF888432,$64ECEFAA,$00000000
	dc.l	$3FFC0000,$F7170A28,$ECC06666,$00000000
	dc.l	$3FFD0000,$812FD288,$332DAD32,$00000000
	dc.l	$3FFD0000,$88A8D1B1,$218E4D64,$00000000
	dc.l	$3FFD0000,$9012AB3F,$23E4AEE8,$00000000
	dc.l	$3FFD0000,$976CC3D4,$11E7F1B9,$00000000
	dc.l	$3FFD0000,$9EB68949,$3889A227,$00000000
	dc.l	$3FFD0000,$A5EF72C3,$4487361B,$00000000
	dc.l	$3FFD0000,$AD1700BA,$F07A7227,$00000000
	dc.l	$3FFD0000,$B42CBCFA,$FD37EFB7,$00000000
	dc.l	$3FFD0000,$BB303A94,$0BA80F89,$00000000
	dc.l	$3FFD0000,$C22115C6,$FCAEBBAF,$00000000
	dc.l	$3FFD0000,$C8FEF3E6,$86331221,$00000000
	dc.l	$3FFD0000,$CFC98330,$B4000C70,$00000000
	dc.l	$3FFD0000,$D6807AA1,$102C5BF9,$00000000
	dc.l	$3FFD0000,$DD2399BC,$31252AA3,$00000000
	dc.l	$3FFD0000,$E3B2A855,$6B8FC517,$00000000
	dc.l	$3FFD0000,$EA2D764F,$64315989,$00000000
	dc.l	$3FFD0000,$F3BF5BF8,$BAD1A21D,$00000000
	dc.l	$3FFE0000,$801CE39E,$0D205C9A,$00000000
	dc.l	$3FFE0000,$8630A2DA,$DA1ED066,$00000000
	dc.l	$3FFE0000,$8C1AD445,$F3E09B8C,$00000000
	dc.l	$3FFE0000,$91DB8F16,$64F350E2,$00000000
	dc.l	$3FFE0000,$97731420,$365E538C,$00000000
	dc.l	$3FFE0000,$9CE1C8E6,$A0B8CDBA,$00000000
	dc.l	$3FFE0000,$A22832DB,$CADAAE09,$00000000
	dc.l	$3FFE0000,$A746F2DD,$B7602294,$00000000
	dc.l	$3FFE0000,$AC3EC0FB,$997DD6A2,$00000000
	dc.l	$3FFE0000,$B110688A,$EBDC6F6A,$00000000
	dc.l	$3FFE0000,$B5BCC490,$59ECC4B0,$00000000
	dc.l	$3FFE0000,$BA44BC7D,$D470782F,$00000000
	dc.l	$3FFE0000,$BEA94144,$FD049AAC,$00000000
	dc.l	$3FFE0000,$C2EB4ABB,$661628B6,$00000000
	dc.l	$3FFE0000,$C70BD54C,$E602EE14,$00000000
	dc.l	$3FFE0000,$CD000549,$ADEC7159,$00000000
	dc.l	$3FFE0000,$D48457D2,$D8EA4EA3,$00000000
	dc.l	$3FFE0000,$DB948DA7,$12DECE3B,$00000000
	dc.l	$3FFE0000,$E23855F9,$69E8096A,$00000000
	dc.l	$3FFE0000,$E8771129,$C4353259,$00000000
	dc.l	$3FFE0000,$EE57C16E,$0D379C0D,$00000000
	dc.l	$3FFE0000,$F3E10211,$A87C3779,$00000000
	dc.l	$3FFE0000,$F919039D,$758B8D41,$00000000
	dc.l	$3FFE0000,$FE058B8F,$64935FB3,$00000000
	dc.l	$3FFF0000,$8155FB49,$7B685D04,$00000000
	dc.l	$3FFF0000,$83889E35,$49D108E1,$00000000
	dc.l	$3FFF0000,$859CFA76,$511D724B,$00000000
	dc.l	$3FFF0000,$87952ECF,$FF8131E7,$00000000
	dc.l	$3FFF0000,$89732FD1,$9557641B,$00000000
	dc.l	$3FFF0000,$8B38CAD1,$01932A35,$00000000
	dc.l	$3FFF0000,$8CE7A8D8,$301EE6B5,$00000000
	dc.l	$3FFF0000,$8F46A39E,$2EAE5281,$00000000
	dc.l	$3FFF0000,$922DA7D7,$91888487,$00000000
	dc.l	$3FFF0000,$94D19FCB,$DEDF5241,$00000000
	dc.l	$3FFF0000,$973AB944,$19D2A08B,$00000000
	dc.l	$3FFF0000,$996FF00E,$08E10B96,$00000000
	dc.l	$3FFF0000,$9B773F95,$12321DA7,$00000000
	dc.l	$3FFF0000,$9D55CC32,$0F935624,$00000000
	dc.l	$3FFF0000,$9F100575,$006CC571,$00000000
	dc.l	$3FFF0000,$A0A9C290,$D97CC06C,$00000000
	dc.l	$3FFF0000,$A22659EB,$EBC0630A,$00000000
	dc.l	$3FFF0000,$A388B4AF,$F6EF0EC9,$00000000
	dc.l	$3FFF0000,$A4D35F10,$61D292C4,$00000000
	dc.l	$3FFF0000,$A60895DC,$FBE3187E,$00000000
	dc.l	$3FFF0000,$A72A51DC,$7367BEAC,$00000000
	dc.l	$3FFF0000,$A83A5153,$0956168F,$00000000
	dc.l	$3FFF0000,$A93A2007,$7539546E,$00000000
	dc.l	$3FFF0000,$AA9E7245,$023B2605,$00000000
	dc.l	$3FFF0000,$AC4C84BA,$6FE4D58F,$00000000
	dc.l	$3FFF0000,$ADCE4A4A,$606B9712,$00000000
	dc.l	$3FFF0000,$AF2A2DCD,$8D263C9C,$00000000
	dc.l	$3FFF0000,$B0656F81,$F22265C7,$00000000
	dc.l	$3FFF0000,$B1846515,$0F71496A,$00000000
	dc.l	$3FFF0000,$B28AAA15,$6F9ADA35,$00000000
	dc.l	$3FFF0000,$B37B44FF,$3766B895,$00000000
	dc.l	$3FFF0000,$B458C3DC,$E9630433,$00000000
	dc.l	$3FFF0000,$B525529D,$562246BD,$00000000
	dc.l	$3FFF0000,$B5E2CCA9,$5F9D88CC,$00000000
	dc.l	$3FFF0000,$B692CADA,$7ACA1ADA,$00000000
	dc.l	$3FFF0000,$B736AEA7,$A6925838,$00000000
	dc.l	$3FFF0000,$B7CFAB28,$7E9F7B36,$00000000
	dc.l	$3FFF0000,$B85ECC66,$CB219835,$00000000
	dc.l	$3FFF0000,$B8E4FD5A,$20A593DA,$00000000
	dc.l	$3FFF0000,$B99F41F6,$4AFF9BB5,$00000000
	dc.l	$3FFF0000,$BA7F1E17,$842BBE7B,$00000000
	dc.l	$3FFF0000,$BB471285,$7637E17D,$00000000
	dc.l	$3FFF0000,$BBFABE8A,$4788DF6F,$00000000
	dc.l	$3FFF0000,$BC9D0FAD,$2B689D79,$00000000
	dc.l	$3FFF0000,$BD306A39,$471ECD86,$00000000
	dc.l	$3FFF0000,$BDB6C731,$856AF18A,$00000000
	dc.l	$3FFF0000,$BE31CAC5,$02E80D70,$00000000
	dc.l	$3FFF0000,$BEA2D55C,$E33194E2,$00000000
	dc.l	$3FFF0000,$BF0B10B7,$C03128F0,$00000000
	dc.l	$3FFF0000,$BF6B7A18,$DACB778D,$00000000
	dc.l	$3FFF0000,$BFC4EA46,$63FA18F6,$00000000
	dc.l	$3FFF0000,$C0181BDE,$8B89A454,$00000000
	dc.l	$3FFF0000,$C065B066,$CFBF6439,$00000000
	dc.l	$3FFF0000,$C0AE345F,$56340AE6,$00000000
	dc.l	$3FFF0000,$C0F22291,$9CB9E6A7,$00000000

*X	equ	EXC_LV+FP_SCR0
XDCARE	equ	X+2
*XFRAC	equ	X+4
XFRACLO	equ	X+8

ATANF	equ	EXC_LV+FP_SCR1
ATANFHI	equ	ATANF+4
ATANFLO	equ	ATANF+8

	xdef	satan
*--ENTRY POINT FOR ATAN(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S
satan:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	fmove.x	fp0,X(a6)
	and.l	#$7FFFFFFF,d1

	ICMP.l	d1,#$3FFB8000	* |X| >= 1/16?
	bge.b	ATANOK1
	bra.w	ATANSM

ATANOK1:
	ICMP.l	d1,#$4002FFFF	* |X| < 16 ?
	ble.b	ATANMAIN
	bra.w	ATANBIG

*--THE MOST LIKELY CASE, |X| IN [1/16, 16). WE USE TABLE TECHNIQUE
*--THE IDEA IS ATAN(X) = ATAN(F) + ATAN( [X-F] / [1+XF] ).
*--SO IF F IS CHOSEN TO BE CLOSE TO X AND ATAN(F) IS STORED IN
*--A TABLE, ALL WE NEED IS TO APPROXIMATE ATAN(U) WHERE
*--U = (X-F)/(1+XF) IS SMALL (REMEMBER F IS CLOSE TO X). IT IS
*--TRUE THAT A DIVIDE IS NOW NEEDED, BUT THE APPROXIMATION FOR
*--ATAN(U) IS A VERY dc.w POLYNOMIAL AND THE INDEXING TO
*--FETCH F AND SAVING OF REGISTERS CAN BE ALL HIDED UNDER THE
*--DIVIDE. IN THE END THIS METHOD IS MUCH FASTER THAN A TRADITIONAL
*--ONE. NOTE ALSO THAT THE TRADITIONAL SCHEME THAT APPROXIMATE
*--ATAN(X) DIRECTLY WILL NEED TO USE A RATIONAL APPROXIMATION
*--(DIVISION NEEDED) ANYWAY BECAUSE A POLYNOMIAL APPROXIMATION
*--WILL INVOLVE A VERY LONG POLYNOMIAL.

*--NOW WE SEE X AS +-2^K * 1.BBBBBBB....B <- 1. + 63 BITS
*--WE CHOSE F TO BE +-2^K * 1.BBBB1
*--THAT IS IT MATCHES THE EXPONENT AND FIRST 5 BITS OF X, THE
*--SIXTH BITS IS SET TO BE 1. SINCE K = -4, -3, ..., 3, THERE
*--ARE ONLY 8 TIMES 16 = 2^7 = 128 |F|'S. SINCE ATAN(-|F|) IS
*-- -ATAN(|F|), WE NEED TO STORE ONLY ATAN(|F|).

ATANMAIN:

	and.l	#$F8000000,XFRAC(a6)	* FIRST 5 BITS
	or.l	#$04000000,XFRAC(a6)	* SET 6-TH BIT TO 1
	move.l	#$00000000,XFRACLO(a6) * LOCATION OF X IS NOW F

	fmove.x	fp0,fp1	* FP1 IS X
	fmul.x	X(a6),fp1	* FP1 IS X*F, NOTE THAT X*F > 0
	fsub.x	X(a6),fp0	* FP0 IS X-F
	fadd.s	#$3F800000,fp1	* FP1 IS 1 + X*F
	fdiv.x	fp1,fp0	* FP0 IS U = (X-F)/(1+X*F)

*--WHILE THE DIVISION IS TAKING ITS TIME, WE FETCH ATAN(|F|)
*--CREATE ATAN(F) AND STORE IT IN ATANF, AND
*--SAVE REGISTERS FP2.

	move.l	d2,-(sp)	* SAVE d2 TEMPORARILY
	move.l	d1,d2	* THE EXP AND 16 BITS OF X
	and.l	#$00007800,d1	* 4 VARYING BITS OF F'S FRACTION
	and.l	#$7FFF0000,d2	* EXPONENT OF F
	sub.l	#$3FFB0000,d2	* K+4
	asr.l	#1,d2
	add.l	d2,d1	* THE 7 BITS IDENTIFYING F
	asr.l	#7,d1	* INDEX INTO TBL OF ATAN(|F|)
	lea	ATANTBL(pc),a1
	add.l	d1,a1	* ADDRESS OF ATAN(|F|)
	move.l	(a1)+,ATANF(a6)
	move.l	(a1)+,ATANFHI(a6)
	move.l	(a1)+,ATANFLO(a6)	* ATANF IS NOW ATAN(|F|)
	move.l	X(a6),d1	* LOAD SIGN AND EXPO. AGAIN
	and.l	#$80000000,d1	* SIGN(F)
	or.l	d1,ATANF(a6)	* ATANF IS NOW SIGN(F)*ATAN(|F|)
	move.l	(sp)+,d2	* RESTORE d2

*--THAT'S ALL I HAVE TO DO FOR NOW,
*--BUT ALAS, THE DIVIDE IS STILL CRANKING!

*--U IN FP0, WE ARE NOW READY TO COMPUTE ATAN(U) AS
*--U + A1*U*V*(A2 + V*(A3 + V)), V = U*U
*--THE POLYNOMIAL MAY LOOK STRANGE, BUT IS NEVERTHELESS CORRECT.
*--THE NATURAL FORM IS U + U*V*(A1 + V*(A2 + V*A3))
*--WHAT WE HAVE HERE IS MERELY	A1 = A3, A2 = A1/A3, A3 = A2/A3.
*--THE REASON FOR THIS REARRANGEMENT IS TO MAKE THE INDEPENDENT
*--PARTS A1*U*V AND (A2 + ... STUFF) MORE LOAD-BALANCED

	fmovem.x	fp2,-(sp)	* save fp2

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1
	fmove.d	ATANA3(pc),fp2
	fadd.x	fp1,fp2	* A3+V
	fmul.x	fp1,fp2	* V*(A3+V)
	fmul.x	fp0,fp1	* U*V
	fadd.d	ATANA2(pc),fp2	* A2+V*(A3+V)
	fmul.d	ATANA1(pc),fp1	* A1*U*V
	fmul.x	fp2,fp1	* A1*U*V*(A2+V*(A3+V))
	fadd.x	fp1,fp0	* ATAN(U), FP1 RELEASED

	fmovem.x 	(sp)+,fp2	* restore fp2

	fmove.l	d0,fpcr	* restore users rnd mode,prec
	fadd.x	ATANF(a6),fp0	* ATAN(X)
	bra	t_inx2

ATANBORS:
*--|X| IS IN d0 IN COMPACT FORM. FP1, d0 SAVED.
*--FP0 IS X AND |X| <= 1/16 OR |X| >= 16.
	ICMP.l	d1,#$3FFF8000
	bgt.w	ATANBIG	* I.E. |X| >= 16

ATANSM:
*--|X| <= 1/16
*--IF |X| < 2^(-40), RETURN X AS ANSWER. OTHERWISE, APPROXIMATE
*--ATAN(X) BY X + X*Y*(B1+Y*(B2+Y*(B3+Y*(B4+Y*(B5+Y*B6)))))
*--WHICH IS X + X*Y*( [B1+Z*(B3+Z*B5)] + [Y*(B2+Z*(B4+Z*B6)] )
*--WHERE Y = X*X, AND Z = Y*Y.

	ICMP.l	d1,#$3FD78000
	blt.w	ATANTINY

*--COMPUTE POLYNOMIAL
	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmul.x	fp0,fp0	* FPO IS Y = X*X

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS Z = Y*Y

	fmove.d	ATANB6(pc),fp2
	fmove.d	ATANB5(pc),fp3

	fmul.x	fp1,fp2	* Z*B6
	fmul.x	fp1,fp3	* Z*B5

	fadd.d	ATANB4(pc),fp2	* B4+Z*B6
	fadd.d	ATANB3(pc),fp3	* B3+Z*B5

	fmul.x	fp1,fp2	* Z*(B4+Z*B6)
	fmul.x	fp3,fp1	* Z*(B3+Z*B5)

	fadd.d	ATANB2(pc),fp2	* B2+Z*(B4+Z*B6)
	fadd.d	ATANB1(pc),fp1	* B1+Z*(B3+Z*B5)

	fmul.x	fp0,fp2	* Y*(B2+Z*(B4+Z*B6))
	fmul.x	X(a6),fp0	* X*Y

	fadd.x	fp2,fp1	* [B1+Z*(B3+Z*B5)]+[Y*(B2+Z*(B4+Z*B6))]

	fmul.x	fp1,fp0	* X*Y*([B1+Z*(B3+Z*B5)]+[Y*(B2+Z*(B4+Z*B6))])

	fmovem.x	(sp)+,fp2-fp3	* restore fp2/fp3

	fmove.l	d0,fpcr	* restore users rnd mode,prec
	fadd.x	X(a6),fp0
	bra	t_inx2

ATANTINY:
*--|X| < 2^(-40), ATAN(X) = X

	fmove.l	d0,fpcr	* restore users rnd mode,prec
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	X(a6),fp0	* last inst - possible exception set

	bra	t_catch

ATANBIG:
*--IF |X| > 2^(100), RETURN	SIGN(X)*(PI/2 - TINY). OTHERWISE,
*--RETURN SIGN(X)*PI/2 + ATAN(-1/X).
	ICMP.l	d1,#$40638000
	bgt.w	ATANHUGE

*--APPROXIMATE ATAN(-1/X) BY
*--X'+X'*Y*(C1+Y*(C2+Y*(C3+Y*(C4+Y*C5)))), X' = -1/X, Y = X'*X'
*--THIS CAN BE RE-WRITTEN AS
*--X'+X'*Y*( [C1+Z*(C3+Z*C5)] + [Y*(C2+Z*C4)] ), Z = Y*Y.

	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmove.s	#$BF800000,fp1	* LOAD -1
	fdiv.x	fp0,fp1	* FP1 IS -1/X

*--DIVIDE IS STILL CRANKING

	fmove.x	fp1,fp0	* FP0 IS X'
	fmul.x	fp0,fp0	* FP0 IS Y = X'*X'
	fmove.x	fp1,X(a6)	* X IS REALLY X'

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS Z = Y*Y

	fmove.d	ATANC5(pc),fp3
	fmove.d	ATANC4(pc),fp2

	fmul.x	fp1,fp3	* Z*C5
	fmul.x	fp1,fp2	* Z*B4

	fadd.d	ATANC3(pc),fp3	* C3+Z*C5
	fadd.d	ATANC2(pc),fp2	* C2+Z*C4

	fmul.x	fp3,fp1	* Z*(C3+Z*C5), FP3 RELEASED
	fmul.x	fp0,fp2	* Y*(C2+Z*C4)

	fadd.d	ATANC1(pc),fp1	* C1+Z*(C3+Z*C5)
	fmul.x	X(a6),fp0	* X'*Y

	fadd.x	fp2,fp1	* [Y*(C2+Z*C4)]+[C1+Z*(C3+Z*C5)]

	fmul.x	fp1,fp0	* X'*Y*([B1+Z*(B3+Z*B5)]
*		...	+[Y*(B2+Z*(B4+Z*B6))])
	fadd.x	X(a6),fp0

	fmovem.x	(sp)+,fp2-fp3	* restore fp2/fp3

	fmove.l	d0,fpcr	* restore users rnd mode,prec
	tst.b	(a0)
	bpl.b	pos_big

neg_big:
	fadd.x	NPIBY2(pc),fp0
	bra	t_minx2

pos_big:
	fadd.x	PPIBY2(pc),fp0
	bra	t_pinx2

ATANHUGE:
*--RETURN SIGN(X)*(PIBY2 - TINY) = SIGN(X)*PIBY2 - SIGN(X)*TINY
	tst.b	(a0)
	bpl.b	pos_huge

neg_huge:
	fmove.x	NPIBY2(pc),fp0
	fmove.l	d0,fpcr
	fadd.x	PTINY(pc),fp0
	bra	t_minx2

pos_huge:
	fmove.x	PPIBY2(pc),fp0
	fmove.l	d0,fpcr
	fadd.x	NTINY(pc),fp0
	bra	t_pinx2

	xdef	satand
*--ENTRY POINT FOR ATAN(X) FOR DENORMALIZED ARGUMENT
satand:
	bra	t_extdnrm



**-------------------------------------------------------------------------------------------------
* setox():    computes the exponential for a normalized input
* setoxd():   computes the exponential for a denormalized input	* 
* setoxm1():  computes the exponential minus 1 for a normalized input
* setoxm1d(): computes the exponential minus 1 for a denormalized input
*		
* INPUT	*************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT ************************************************************** *
*	fp0 = exp(X) or exp(X)-1	
*		
* ACCURACY and MONOTONICITY ******************************************* *
*	The returned result is within 0.85 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently *
*	rounded to double precision. The result is provably monotonic 
*	in double precision.	
*		
* ALGORITHM and IMPLEMENTATION **************************************** *
*		
*	setoxd	
*	------	
*	Step 1.	Set ans := 1.0	
*		
*	Step 2.	Return	ans := ans + sign(X)*2^(-126). Exit.
*	Notes:	This will always generate one exception -- inexact.
*		
*		
*	setox	
*	-----	
*		
*	Step 1.	Filter out extreme cases of input argument.
*	1.1	If |X| >= 2^(-65), go to Step 1.3.
*	1.2	Go to Step 7.	
*	1.3	If |X| < 16380 log(2), go to Step 2.
*	1.4	Go to Step 8.	
*	Notes:	The usual case should take the branches 1.1 -> 1.3 -> 2.*
*	To avoid the use of floating-point comparisons, a
*	compact representation of |X| is used. This format is a
*	32-bit integer, the upper (more significant) 16 bits 
*	are the sign and biased exponent field of |X|; the 
*	lower 16 bits are the 16 most significant fraction
*	(including the explicit bit) bits of |X|. Consequently,
*	the comparisons in Steps 1.1 and 1.3 can be performed
*	by integer comparison. Note also that the constant
*	16380 log(2) used in Step 1.3 is also in the compact
*	form. Thus taking the branch to Step 2 guarantees 
*	|X| < 16380 log(2). There is no harm to have a small
*	number of cases where |X| is less than,	but close to,
*	16380 log(2) and the branch to Step 9 is taken.
*		
*	Step 2.	Calculate N = round-to-nearest-int( X * 64/log2 ).
*	2.1	Set AdjFlag := 0 (indicates the branch 1.3 -> 2 *
*	was taken)	
*	2.2	N := round-to-nearest-integer( X * 64/log2 ).
*	2.3	Calculate	J = N mod 64; so J = 0,1,2,..., *
*	or 63.	
*	2.4	Calculate	M = (N - J)/64; so N = 64M + J.
*	2.5	Calculate the address of the stored value of 
*	2^(J/64).	
*	2.6	Create the value Scale = 2^M.
*	Notes:	The calculation in 2.2 is really performed by
*	Z := X * constant
*	N := round-to-nearest-integer(Z)
*	where	
*	constant := single-precision( 64/log 2 ).
*		
*	Using a single-precision constant avoids memory 
*	access. Another effect of using a single-precision
*	"constant" is that the calculated value Z is 
*		
*	Z = X*(64/log2)*(1+eps), |eps| <= 2^(-24).
*		
*	This error has to be considered later in Steps 3 and 4.
*		
*	Step 3.	Calculate X - N*log2/64.
*	3.1	R := X + N*L1, 	
*	where L1 := single-precision(-log2/64).
*	3.2	R := R + N*L2, 	
*	L2 := extended-precision(-log2/64 - L1).*
*	Notes:	a) The way L1 and L2 are chosen ensures L1+L2 
*	approximate the value -log2/64 to 88 bits of accuracy.
*	b) N*L1 is exact because N is no longer than 22 bits
*	and L1 is no longer than 24 bits.
*	c) The calculation X+N*L1 is also exact due to 
*	cancellation. Thus, R is practically X+N(L1+L2) to full
*	64 bits. 	
*	d) It is important to estimate how large can |R| be
*	after Step 3.2.	
*		
*	N = rnd-to-int( X*64/log2 (1+eps) ), |eps|<=2^(-24)
*	X*64/log2 (1+eps)	=	N + f,	|f| <= 0.5
*	X*64/log2 - N	=	f - eps*X 64/log2
*	X - N*log2/64	=	f*log2/64 - eps*X
*		
*		
*	Now |X| <= 16446 log2, thus
*		
*	|X - N*log2/64| <= (0.5 + 16446/2^(18))*log2/64
*		<= 0.57 log2/64.
*	 This bound will be used in Step 4.
*		
*	Step 4.	Approximate exp(R)-1 by a polynomial
*	p = R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*A5))))
*	Notes:	a) In order to reduce memory access, the coefficients 
*	are made as "dc.w" as possible: A1 (which is 1/2), A4
*	and A5 are single precision; A2 and A3 are double
*	precision. 	
*	b) Even with the restrictions above, 
*	   |p - (exp(R)-1)| < 2^(-68.8) for all |R| <= 0.0062.
*	Note that 0.0062 is slightly bigger than 0.57 log2/64.
*	c) To fully utilize the pipeline, p is separated into
*	two independent pieces of roughly equal complexities
*	p = [ R + R*S*(A2 + S*A4) ]	+
*	[ S*(A1 + S*(A3 + S*A5)) ]
*	where S = R*R.	
*		
*	Step 5.	Compute 2^(J/64)*exp(R) = 2^(J/64)*(1+p) by
*	ans := T + ( T*p + t)
*	where T and t are the stored values for 2^(J/64).
*	Notes:	2^(J/64) is stored as T and t where T+t approximates
*	2^(J/64) to roughly 85 bits; T is in extended precision
*	and t is in single precision. Note also that T is 
*	rounded to 62 bits so that the last two bits of T are 
*	zero. The reason for such a special form is that T-1, 
*	T-2, and T-8 will all be exact --- a property that will
*	give much more accurate computation of the function 
*	EXPM1.	
*		
*	Step 6.	Reconstruction of exp(X)
*	exp(X) = 2^M * 2^(J/64) * exp(R).
*	6.1	If AdjFlag = 0, go to 6.3
*	6.2	ans := ans * AdjScale
*	6.3	Restore the user FPCR
*	6.4	Return ans := ans * Scale. Exit.
*	Notes:	If AdjFlag = 0, we have X = Mlog2 + Jlog2/64 + R,
*	|M| <= 16380, and Scale = 2^M. Moreover, exp(X) will
*	neither overflow nor underflow. If AdjFlag = 1, that
*	means that	
*	X = (M1+M)log2 + Jlog2/64 + R, |M1+M| >= 16380.
*	Hence, exp(X) may overflow or underflow or neither.
*	When that is the case, AdjScale = 2^(M1) where M1 is
*	approximately M. Thus 6.2 will never cause 
*	over/underflow. Possible exception in 6.4 is overflow
*	or underflow. The inexact exception is not generated in
*	6.4. Although one can argue that the inexact flag
*	should always be raised, to simulate that exception 
*	cost to much than the flag is worth in practical uses.
*		
*	Step 7.	Return 1 + X.	
*	7.1	ans := X	
*	7.2	Restore user FPCR.
*	7.3	Return ans := 1 + ans. Exit
*	Notes:	For non-zero X, the inexact exception will always be
*	raised by 7.3. That is the only exception raised by 7.3.*
*	Note also that we use the FMOVEM instruction to move X
*	in Step 7.1 to avoid unnecessary trapping. (Although
*	the FMOVEM may not seem relevant since X is normalized,
*	the precaution will be useful in the library version of
*	this code where the separate entry for denormalized 
*	inputs will be done away with.)
*		
*	Step 8.	Handle exp(X) where |X| >= 16380log2.
*	8.1	If |X| > 16480 log2, go to Step 9.
*	(mimic 2.2 - 2.6)	
*	8.2	N := round-to-integer( X * 64/log2 )
*	8.3	Calculate J = N mod 64, J = 0,1,...,63
*	8.4	K := (N-J)/64, M1 := truncate(K/2), M = K-M1, 
*	AdjFlag := 1.	
*	8.5	Calculate the address of the stored value 
*	2^(J/64).	
*	8.6	Create the values Scale = 2^M, AdjScale = 2^M1.
*	8.7	Go to Step 3.	
*	Notes:	Refer to notes for 2.2 - 2.6.
*		
*	Step 9.	Handle exp(X), |X| > 16480 log2.
*	9.1	If X < 0, go to 9.3
*	9.2	ans := Huge, go to 9.4
*	9.3	ans := Tiny.	
*	9.4	Restore user FPCR.
*	9.5	Return ans := ans * ans. Exit.
*	Notes:	Exp(X) will surely overflow or underflow, depending on
*	X's sign. "Huge" and "Tiny" are respectively large/tiny
*	extended-precision numbers whose square over/underflow
*	with an inexact result. Thus, 9.5 always raises the
*	inexact together with either overflow or underflow.
*		
*	setoxm1d	
*	--------	
*		
*	Step 1.	Set ans := 0	
*		
*	Step 2.	Return	ans := X + ans. Exit.
*	Notes:	This will return X with the appropriate rounding
*	 precision prescribed by the user FPCR.
*		
*	setoxm1	
*	-------	
*		
*	Step 1.	Check |X|	
*	1.1	If |X| >= 1/4, go to Step 1.3.
*	1.2	Go to Step 7.	
*	1.3	If |X| < 70 log(2), go to Step 2.
*	1.4	Go to Step 10.	
*	Notes:	The usual case should take the branches 1.1 -> 1.3 -> 2.*
*	However, it is conceivable |X| can be small very often
*	because EXPM1 is intended to evaluate exp(X)-1 
*	accurately when |X| is small. For further details on 
*	the comparisons, see the notes on Step 1 of setox.
*		
*	Step 2.	Calculate N = round-to-nearest-int( X * 64/log2 ).
*	2.1	N := round-to-nearest-integer( X * 64/log2 ).
*	2.2	Calculate	J = N mod 64; so J = 0,1,2,..., *
*	or 63.	
*	2.3	Calculate	M = (N - J)/64; so N = 64M + J.
*	2.4	Calculate the address of the stored value of 
*	2^(J/64).	
*	2.5	Create the values Sc = 2^M and 
*	OnebySc := -2^(-M).
*	Notes:	See the notes on Step 2 of setox.
*		
*	Step 3.	Calculate X - N*log2/64.
*	3.1	R := X + N*L1, 	
*	where L1 := single-precision(-log2/64).
*	3.2	R := R + N*L2, 	
*	L2 := extended-precision(-log2/64 - L1).*
*	Notes:	Applying the analysis of Step 3 of setox in this case
*	shows that |R| <= 0.0055 (note that |X| <= 70 log2 in
*	this case).	
*		
*	Step 4.	Approximate exp(R)-1 by a polynomial
*	p = R+R*R*(A1+R*(A2+R*(A3+R*(A4+R*(A5+R*A6)))))
*	Notes:	a) In order to reduce memory access, the coefficients 
*	are made as "dc.w" as possible: A1 (which is 1/2), A5 
*	and A6 are single precision; A2, A3 and A4 are double 
*	precision. 	
*	b) Even with the restriction above,
*	|p - (exp(R)-1)| <	|R| * 2^(-72.7)
*	for all |R| <= 0.0055.	
*	c) To fully utilize the pipeline, p is separated into
*	two independent pieces of roughly equal complexity
*	p = [ R*S*(A2 + S*(A4 + S*A6)) ]	+
*	[ R + S*(A1 + S*(A3 + S*A5)) ]
*	where S = R*R.	
*		
*	Step 5.	Compute 2^(J/64)*p by	
*	p := T*p
*	where T and t are the stored values for 2^(J/64).
*	Notes:	2^(J/64) is stored as T and t where T+t approximates
*	2^(J/64) to roughly 85 bits; T is in extended precision
*	and t is in single precision. Note also that T is 
*	rounded to 62 bits so that the last two bits of T are 
*	zero. The reason for such a special form is that T-1, 
*	T-2, and T-8 will all be exact --- a property that will
*	be exploited in Step 6 below. The total relative error
*	in p is no bigger than 2^(-67.7) compared to the final
*	result.	
*		
*	Step 6.	Reconstruction of exp(X)-1
*	exp(X)-1 = 2^M * ( 2^(J/64) + p - 2^(-M) ).
*	6.1	If M <= 63, go to Step 6.3.
*	6.2	ans := T + (p + (t + OnebySc)). Go to 6.6
*	6.3	If M >= -3, go to 6.5.
*	6.4	ans := (T + (p + t)) + OnebySc. Go to 6.6
*	6.5	ans := (T + OnebySc) + (p + t).
*	6.6	Restore user FPCR.
*	6.7	Return ans := Sc * ans. Exit.
*	Notes:	The various arrangements of the expressions give 
*	accurate evaluations.	
*		
*	Step 7.	exp(X)-1 for |X| < 1/4.	
*	7.1	If |X| >= 2^(-65), go to Step 9.
*	7.2	Go to Step 8.	
*		
*	Step 8.	Calculate exp(X)-1, |X| < 2^(-65).
*	8.1	If |X| < 2^(-16312), goto 8.3
*	8.2	Restore FPCR; return ans := X - 2^(-16382).
*	Exit.	
*	8.3	X := X * 2^(140).
*	8.4	Restore FPCR; ans := ans - 2^(-16382).
*	 Return ans := ans*2^(140). Exit
*	Notes:	The idea is to return "X - tiny" under the user
*	precision and rounding modes. To avoid unnecessary
*	inefficiency, we stay away from denormalized numbers 
*	the best we can. For |X| >= 2^(-16312), the 
*	straightforward 8.2 generates the inexact exception as
*	the case warrants.	
*		
*	Step 9.	Calculate exp(X)-1, |X| < 1/4, by a polynomial
*	p = X + X*X*(B1 + X*(B2 + ... + X*B12))
*	Notes:	a) In order to reduce memory access, the coefficients
*	are made as "dc.w" as possible: B1 (which is 1/2), B9
*	to B12 are single precision; B3 to B8 are double 
*	precision; and B2 is double extended.
*	b) Even with the restriction above,
*	|p - (exp(X)-1)| < |X| 2^(-70.6)
*	for all |X| <= 0.251.	
*	Note that 0.251 is slightly bigger than 1/4.
*	c) To fully preserve accuracy, the polynomial is 
*	computed as	
*	X + ( S*B1 +	Q ) where S = X*X and
*	Q	=	X*S*(B2 + X*(B3 + ... + X*B12))
*	d) To fully utilize the pipeline, Q is separated into
*	two independent pieces of roughly equal complexity
*	Q = [ X*S*(B2 + S*(B4 + ... + S*B12)) ] +
*	[ S*S*(B3 + S*(B5 + ... + S*B11)) ]
*		
*	Step 10. Calculate exp(X)-1 for |X| >= 70 log 2.
*	10.1 If X >= 70log2 , exp(X) - 1 = exp(X) for all 
*	practical purposes. Therefore, go to Step 1 of setox.
*	10.2 If X <= -70log2, exp(X) - 1 = -1 for all practical
*	purposes. 	
*	ans := -1 	
*	Restore user FPCR	
*	Return ans := ans + 2^(-126). Exit.
*	Notes:	10.2 will always create an inexact and return -1 + tiny
*	in the user rounding precision and mode.
*		
**-------------------------------------------------------------------------------------------------

L2:	dc.l	$3FDC0000,$82E30865,$4361C4C6,$00000000

EEXPA3:	dc.l	$3FA55555,$55554CC1
EEXPA2:	dc.l	$3FC55555,$55554A54

EM1A4:	dc.l	$3F811111,$11174385
EM1A3:	dc.l	$3FA55555,$55554F5A

EM1A2:	dc.l	$3FC55555,$55555555,$00000000,$00000000

EM1B8:	dc.l	$3EC71DE3,$A5774682
EM1B7:	dc.l	$3EFA01A0,$19D7CB68

EM1B6:	dc.l	$3F2A01A0,$1A019DF3
EM1B5:	dc.l	$3F56C16C,$16C170E2

EM1B4:	dc.l	$3F811111,$11111111
EM1B3:	dc.l	$3FA55555,$55555555

EM1B2:	dc.l	$3FFC0000,$AAAAAAAA,$AAAAAAAB
	dc.l	$00000000

TWO140:	dc.l	$48B00000,$00000000
TWON140:
	dc.l	$37300000,$00000000

EEXPTBL:
	dc.l	$3FFF0000,$80000000,$00000000,$00000000
	dc.l	$3FFF0000,$8164D1F3,$BC030774,$9F841A9B
	dc.l	$3FFF0000,$82CD8698,$AC2BA1D8,$9FC1D5B9
	dc.l	$3FFF0000,$843A28C3,$ACDE4048,$A0728369
	dc.l	$3FFF0000,$85AAC367,$CC487B14,$1FC5C95C
	dc.l	$3FFF0000,$871F6196,$9E8D1010,$1EE85C9F
	dc.l	$3FFF0000,$88980E80,$92DA8528,$9FA20729
	dc.l	$3FFF0000,$8A14D575,$496EFD9C,$A07BF9AF
	dc.l	$3FFF0000,$8B95C1E3,$EA8BD6E8,$A0020DCF
	dc.l	$3FFF0000,$8D1ADF5B,$7E5BA9E4,$205A63DA
	dc.l	$3FFF0000,$8EA4398B,$45CD53C0,$1EB70051
	dc.l	$3FFF0000,$9031DC43,$1466B1DC,$1F6EB029
	dc.l	$3FFF0000,$91C3D373,$AB11C338,$A0781494
	dc.l	$3FFF0000,$935A2B2F,$13E6E92C,$9EB319B0
	dc.l	$3FFF0000,$94F4EFA8,$FEF70960,$2017457D
	dc.l	$3FFF0000,$96942D37,$20185A00,$1F11D537
	dc.l	$3FFF0000,$9837F051,$8DB8A970,$9FB952DD
	dc.l	$3FFF0000,$99E04593,$20B7FA64,$1FE43087
	dc.l	$3FFF0000,$9B8D39B9,$D54E5538,$1FA2A818
	dc.l	$3FFF0000,$9D3ED9A7,$2CFFB750,$1FDE494D
	dc.l	$3FFF0000,$9EF53260,$91A111AC,$20504890
	dc.l	$3FFF0000,$A0B0510F,$B9714FC4,$A073691C
	dc.l	$3FFF0000,$A2704303,$0C496818,$1F9B7A05
	dc.l	$3FFF0000,$A43515AE,$09E680A0,$A0797126
	dc.l	$3FFF0000,$A5FED6A9,$B15138EC,$A071A140
	dc.l	$3FFF0000,$A7CD93B4,$E9653568,$204F62DA
	dc.l	$3FFF0000,$A9A15AB4,$EA7C0EF8,$1F283C4A
	dc.l	$3FFF0000,$AB7A39B5,$A93ED338,$9F9A7FDC
	dc.l	$3FFF0000,$AD583EEA,$42A14AC8,$A05B3FAC
	dc.l	$3FFF0000,$AF3B78AD,$690A4374,$1FDF2610
	dc.l	$3FFF0000,$B123F581,$D2AC2590,$9F705F90
	dc.l	$3FFF0000,$B311C412,$A9112488,$201F678A
	dc.l	$3FFF0000,$B504F333,$F9DE6484,$1F32FB13
	dc.l	$3FFF0000,$B6FD91E3,$28D17790,$20038B30
	dc.l	$3FFF0000,$B8FBAF47,$62FB9EE8,$200DC3CC
	dc.l	$3FFF0000,$BAFF5AB2,$133E45FC,$9F8B2AE6
	dc.l	$3FFF0000,$BD08A39F,$580C36C0,$A02BBF70
	dc.l	$3FFF0000,$BF1799B6,$7A731084,$A00BF518
	dc.l	$3FFF0000,$C12C4CCA,$66709458,$A041DD41
	dc.l	$3FFF0000,$C346CCDA,$24976408,$9FDF137B
	dc.l	$3FFF0000,$C5672A11,$5506DADC,$201F1568
	dc.l	$3FFF0000,$C78D74C8,$ABB9B15C,$1FC13A2E
	dc.l	$3FFF0000,$C9B9BD86,$6E2F27A4,$A03F8F03
	dc.l	$3FFF0000,$CBEC14FE,$F2727C5C,$1FF4907D
	dc.l	$3FFF0000,$CE248C15,$1F8480E4,$9E6E53E4
	dc.l	$3FFF0000,$D06333DA,$EF2B2594,$1FD6D45C
	dc.l	$3FFF0000,$D2A81D91,$F12AE45C,$A076EDB9
	dc.l	$3FFF0000,$D4F35AAB,$CFEDFA20,$9FA6DE21
	dc.l	$3FFF0000,$D744FCCA,$D69D6AF4,$1EE69A2F
	dc.l	$3FFF0000,$D99D15C2,$78AFD7B4,$207F439F
	dc.l	$3FFF0000,$DBFBB797,$DAF23754,$201EC207
	dc.l	$3FFF0000,$DE60F482,$5E0E9124,$9E8BE175
	dc.l	$3FFF0000,$E0CCDEEC,$2A94E110,$20032C4B
	dc.l	$3FFF0000,$E33F8972,$BE8A5A50,$2004DFF5
	dc.l	$3FFF0000,$E5B906E7,$7C8348A8,$1E72F47A
	dc.l	$3FFF0000,$E8396A50,$3C4BDC68,$1F722F22
	dc.l	$3FFF0000,$EAC0C6E7,$DD243930,$A017E945
	dc.l	$3FFF0000,$ED4F301E,$D9942B84,$1F401A5B
	dc.l	$3FFF0000,$EFE4B99B,$DCDAF5CC,$9FB9A9E3
	dc.l	$3FFF0000,$F281773C,$59FFB138,$20744C05
	dc.l	$3FFF0000,$F5257D15,$2486CC2C,$1F773A19
	dc.l	$3FFF0000,$F7D0DF73,$0AD13BB8,$1FFE90D5
	dc.l	$3FFF0000,$FA83B2DB,$722A033C,$A041ED22
	dc.l	$3FFF0000,$FD3E0C0C,$F486C174,$1F853F3A

ADJFLAG	equ	EXC_LV+L_SCR2
SCALE	equ	EXC_LV+FP_SCR0
ADJSCALE	equ	EXC_LV+FP_SCR1
SC	equ	EXC_LV+FP_SCR0
ONEBYSC	equ	EXC_LV+FP_SCR1

	xdef	setox
setox:
*--entry point for EXP(X), here X is finite, non-zero, and not NaN's

*--Step 1.
	move.l	(a0),d1	* load part of input X
	and.l	#$7FFF0000,d1	* biased expo. of X
	ICMP.l	d1,#$3FBE0000	* 2^(-65)
	bge.b	EXPC1	* normal case
	bra	EXPSM

EXPC1:
*--The case |X| >= 2^(-65)
	move.w	4(a0),d1	* expo. and partial sig. of |X|
	ICMP.l	d1,#$400CB167	* 16380 log2 trunc. 16 bits
	blt.b	EXPMAIN	* normal case
	bra	EEXPBIG

EXPMAIN:
*--Step 2.
*--This is the normal branch:	2^(-65) <= |X| < 16380 log2.
	fmove.x	(a0),fp0	* load input from (a0)

	fmove.x	fp0,fp1
	fmul.s	#$42B8AA3B,fp0	* 64/log2 * X
	fmovem.x	fp2-fp3,-(sp)	* save fp2 {fp2/fp3}
	move.l	#0,ADJFLAG(a6)
	fmove.l	fp0,d1	* N = int( X * 64/log2 )
	lea	EEXPTBL(pc),a1
	fmove.l	d1,fp0	* convert to floating-format

	move.l	d1,EXC_LV+L_SCR1(a6)	* save N temporarily
	and.l	#$3F,d1	* D0 is J = N mod 64
	lsl.l	#4,d1
	add.l	d1,a1	* address of 2^(J/64)
	move.l	EXC_LV+L_SCR1(a6),d1
	asr.l	#6,d1	* D0 is M
	add.w	#$3FFF,d1	* biased expo. of 2^(M)
	move.w	L2(pc),EXC_LV+L_SCR1(a6)	* prefetch L2, no need in CB

EXPCONT1:
*--Step 3.
*--fp1,fp2 saved on the stack. fp0 is N, fp1 is X,
*--a0 points to 2^(J/64), D0 is biased expo. of 2^(M)
	fmove.x	fp0,fp2
	fmul.s	#$BC317218,fp0	* N * L1, L1 = lead(-log2/64)
	fmul.x	L2(pc),fp2	* N * L2, L1+L2 = -log2/64
	fadd.x	fp1,fp0	* X + N*L1
	fadd.x	fp2,fp0	* fp0 is R, reduced arg.

*--Step 4.
*--WE NOW COMPUTE EXP(R)-1 BY A POLYNOMIAL
*-- R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*A5))))
*--TO FULLY UTILIZE THE PIPELINE, WE COMPUTE S = R*R
*--[R+R*S*(A2+S*A4)] + [S*(A1+S*(A3+S*A5))]

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* fp1 IS S = R*R

	fmove.s	#$3AB60B70,fp2	* fp2 IS A5

	fmul.x	fp1,fp2	* fp2 IS S*A5
	fmove.x	fp1,fp3
	fmul.s	#$3C088895,fp3	* fp3 IS S*A4

	fadd.d	EEXPA3(pc),fp2	* fp2 IS A3+S*A5
	fadd.d	EEXPA2(pc),fp3	* fp3 IS A2+S*A4

	fmul.x	fp1,fp2	* fp2 IS S*(A3+S*A5)
	move.w	d1,SCALE(a6)	* SCALE is 2^(M) in extended
	move.l	#$80000000,SCALE+4(a6)
	clr.l	SCALE+8(a6)

	fmul.x	fp1,fp3	* fp3 IS S*(A2+S*A4)

	fadd.s	#$3F000000,fp2	* fp2 IS A1+S*(A3+S*A5)
	fmul.x	fp0,fp3	* fp3 IS R*S*(A2+S*A4)

	fmul.x	fp1,fp2	* fp2 IS S*(A1+S*(A3+S*A5))
	fadd.x	fp3,fp0	* fp0 IS R+R*S*(A2+S*A4),

	fmove.x	(a1)+,fp1	* fp1 is lead. pt. of 2^(J/64)
	fadd.x	fp2,fp0	* fp0 is EXP(R) - 1

*--Step 5
*--final reconstruction process
*--EXP(X) = 2^M * ( 2^(J/64) + 2^(J/64)*(EXP(R)-1) )

	fmul.x	fp1,fp0	* 2^(J/64)*(Exp(R)-1)
	fmovem.x	(sp)+,fp2-fp3	* fp2 restored {fp2/fp3}
	fadd.s	(a1),fp0	* accurate 2^(J/64)

	fadd.x	fp1,fp0	* 2^(J/64) + 2^(J/64)*...
	move.l	ADJFLAG(a6),d1

*--Step 6
	tst.l	d1
	beq.b	NORMAL
ADJUST:
	fmul.x	ADJSCALE(a6),fp0
NORMAL:
	fmove.l	d0,fpcr	* restore user FPCR
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	SCALE(a6),fp0	* multiply 2^(M)
	bra	t_catch

EXPSM:
*--Step 7
	fmovem.x	(a0),fp0	* load X
	fmove.l	d0,fpcr
	fadd.s	#$3F800000,fp0	* 1+X in user mode
	bra	t_pinx2

EEXPBIG:
*--Step 8
	ICMP.l	d1,#$400CB27C	* 16480 log2
	bgt.b	EXP2BIG
*--Steps 8.2 -- 8.6
	fmove.x	(a0),fp0	* load input from (a0)

	fmove.x	fp0,fp1
	fmul.s	#$42B8AA3B,fp0	* 64/log2 * X
	fmovem.x	fp2-fp3,-(sp)	* save fp2 {fp2/fp3}
	move.l	#1,ADJFLAG(a6)
	fmove.l	fp0,d1	* N = int( X * 64/log2 )
	lea	EEXPTBL(pc),a1
	fmove.l	d1,fp0	* convert to floating-format
	move.l	d1,EXC_LV+L_SCR1(a6)	* save N temporarily
	and.l	#$3F,d1	* D0 is J = N mod 64
	lsl.l	#4,d1
	add.l	d1,a1	* address of 2^(J/64)
	move.l	EXC_LV+L_SCR1(a6),d1
	asr.l	#6,d1	* D0 is K
	move.l	d1,EXC_LV+L_SCR1(a6)	* save K temporarily
	asr.l	#1,d1	* D0 is M1
	sub.l	d1,EXC_LV+L_SCR1(a6)	* a1 is M
	add.w	#$3FFF,d1	* biased expo. of 2^(M1)
	move.w	d1,ADJSCALE(a6)	* ADJSCALE := 2^(M1)
	move.l	#$80000000,ADJSCALE+4(a6)
	clr.l	ADJSCALE+8(a6)
	move.l	EXC_LV+L_SCR1(a6),d1	* D0 is M
	add.w	#$3FFF,d1	* biased expo. of 2^(M)
	bra.w	EXPCONT1	* go back to Step 3

EXP2BIG:
*--Step 9
	tst.b	(a0)	* is X positive or negative?
	bmi	t_unfl2
	bra	t_ovfl2

	xdef	setoxd
setoxd:
*--entry point for EXP(X), X is denormalized
	move.l	(a0),-(sp)
	andi.l	#$80000000,(sp)
	ori.l	#$00800000,(sp)	* sign(X)*2^(-126)

	fmove.s	#$3F800000,fp0

	fmove.l	d0,fpcr
	fadd.s	(sp)+,fp0
	bra	t_pinx2

	xdef	setoxm1
setoxm1:
*--entry point for EXPM1(X), here X is finite, non-zero, non-NaN

*--Step 1.
*--Step 1.1
	move.l	(a0),d1	* load part of input X
	and.l	#$7FFF0000,d1	* biased expo. of X
	ICMP.l	d1,#$3FFD0000	* 1/4
	bge.b	EM1CON1	* |X| >= 1/4
	bra	EM1SM

EM1CON1:
*--Step 1.3
*--The case |X| >= 1/4
	move.w	4(a0),d1	* expo. and partial sig. of |X|
	ICMP.l	d1,#$4004C215	* 70log2 rounded up to 16 bits
	ble.b	EM1MAIN	* 1/4 <= |X| <= 70log2
	bra	EM1BIG

EM1MAIN:
*--Step 2.
*--This is the case:	1/4 <= |X| <= 70 log2.
	fmove.x	(a0),fp0	* load input from (a0)

	fmove.x	fp0,fp1
	fmul.s	#$42B8AA3B,fp0	* 64/log2 * X
	fmovem.x	fp2-fp3,-(sp)	* save fp2 {fp2/fp3}
	fmove.l	fp0,d1	* N = int( X * 64/log2 )
	lea	EEXPTBL(pc),a1
	fmove.l	d1,fp0	* convert to floating-format

	move.l	d1,EXC_LV+L_SCR1(a6)	* save N temporarily
	and.l	#$3F,d1	* D0 is J = N mod 64
	lsl.l	#4,d1
	add.l	d1,a1	* address of 2^(J/64)
	move.l	EXC_LV+L_SCR1(a6),d1
	asr.l	#6,d1	* D0 is M
	move.l	d1,EXC_LV+L_SCR1(a6)	* save a copy of M

*--Step 3.
*--fp1,fp2 saved on the stack. fp0 is N, fp1 is X,
*--a0 points to 2^(J/64), D0 and a1 both contain M
	fmove.x	fp0,fp2
	fmul.s	#$BC317218,fp0	* N * L1, L1 = lead(-log2/64)
	fmul.x	L2(pc),fp2	* N * L2, L1+L2 = -log2/64
	fadd.x	fp1,fp0	* X + N*L1
	fadd.x	fp2,fp0	* fp0 is R, reduced arg.
	add.w	#$3FFF,d1	* D0 is biased expo. of 2^M

*--Step 4.
*--WE NOW COMPUTE EXP(R)-1 BY A POLYNOMIAL
*-- R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*(A5 + R*A6)))))
*--TO FULLY UTILIZE THE PIPELINE, WE COMPUTE S = R*R
*--[R*S*(A2+S*(A4+S*A6))] + [R+S*(A1+S*(A3+S*A5))]

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* fp1 IS S = R*R

	fmove.s	#$3950097B,fp2	* fp2 IS a6

	fmul.x	fp1,fp2	* fp2 IS S*A6
	fmove.x	fp1,fp3
	fmul.s	#$3AB60B6A,fp3	* fp3 IS S*A5

	fadd.d	EM1A4(pc),fp2	* fp2 IS A4+S*A6
	fadd.d	EM1A3(pc),fp3	* fp3 IS A3+S*A5
	move.w	d1,SC(a6)	* SC is 2^(M) in extended
	move.l	#$80000000,SC+4(a6)
	clr.l	SC+8(a6)

	fmul.x	fp1,fp2	* fp2 IS S*(A4+S*A6)
	move.l	EXC_LV+L_SCR1(a6),d1	* D0 is	M
	neg.w	d1	* D0 is -M
	fmul.x	fp1,fp3	* fp3 IS S*(A3+S*A5)
	add.w	#$3FFF,d1	* biased expo. of 2^(-M)
	fadd.d	EM1A2(pc),fp2	* fp2 IS A2+S*(A4+S*A6)
	fadd.s	#$3F000000,fp3	* fp3 IS A1+S*(A3+S*A5)

	fmul.x	fp1,fp2	* fp2 IS S*(A2+S*(A4+S*A6))
	or.w	#$8000,d1	* signed/expo. of -2^(-M)
	move.w	d1,ONEBYSC(a6)	* OnebySc is -2^(-M)
	move.l	#$80000000,ONEBYSC+4(a6)
	clr.l	ONEBYSC+8(a6)
	fmul.x	fp3,fp1	* fp1 IS S*(A1+S*(A3+S*A5))

	fmul.x	fp0,fp2	* fp2 IS R*S*(A2+S*(A4+S*A6))
	fadd.x	fp1,fp0	* fp0 IS R+S*(A1+S*(A3+S*A5))

	fadd.x	fp2,fp0	* fp0 IS EXP(R)-1

	fmovem.x	(sp)+,fp2-fp3	* fp2 restored {fp2/fp3}

*--Step 5
*--Compute 2^(J/64)*p

	fmul.x	(a1),fp0	* 2^(J/64)*(Exp(R)-1)

*--Step 6
*--Step 6.1
	move.l	EXC_LV+L_SCR1(a6),d1	* retrieve M
	ICMP.l	d1,#63
	ble.b	MLE63
*--Step 6.2	M >= 64
	fmove.s	12(a1),fp1	* fp1 is t
	fadd.x	ONEBYSC(a6),fp1	* fp1 is t+OnebySc
	fadd.x	fp1,fp0	* p+(t+OnebySc), fp1 released
	fadd.x	(a1),fp0	* T+(p+(t+OnebySc))
	bra	EM1SCALE
MLE63:
*--Step 6.3	M <= 63
	ICMP.l	d1,#-3
	bge.b	MGEN3
MLTN3:
*--Step 6.4	M <= -4
	fadd.s	12(a1),fp0	* p+t
	fadd.x	(a1),fp0	* T+(p+t)
	fadd.x	ONEBYSC(a6),fp0	* OnebySc + (T+(p+t))
	bra	EM1SCALE
MGEN3:
*--Step 6.5	-3 <= M <= 63
	fmove.x	(a1)+,fp1	* fp1 is T
	fadd.s	(a1),fp0	* fp0 is p+t
	fadd.x	ONEBYSC(a6),fp1	* fp1 is T+OnebySc
	fadd.x	fp1,fp0	* (T+OnebySc)+(p+t)

EM1SCALE:
*--Step 6.6
	fmove.l	d0,fpcr
	fmul.x	SC(a6),fp0
	bra	t_inx2

EM1SM:
*--Step 7	|X| < 1/4.
	ICMP.l	d1,#$3FBE0000	* 2^(-65)
	bge.b	EM1POLY

EM1TINY:
*--Step 8	|X| < 2^(-65)
	ICMP.l	d1,#$00330000	* 2^(-16312)
	blt.b	EM12TINY
*--Step 8.2
	move.l	#$80010000,SC(a6)	* SC is -2^(-16382)
	move.l	#$80000000,SC+4(a6)
	clr.l	SC+8(a6)
	fmove.x	(a0),fp0
	fmove.l	d0,fpcr
	move.b	#FADD_OP,d1	* last inst is ADD
	fadd.x	SC(a6),fp0
	bra	t_catch

EM12TINY:
*--Step 8.3
	fmove.x	(a0),fp0
	fmul.d	TWO140(pc),fp0
	move.l	#$80010000,SC(a6)
	move.l	#$80000000,SC+4(a6)
	clr.l	SC+8(a6)
	fadd.x	SC(a6),fp0
	fmove.l	d0,fpcr
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.d	TWON140(pc),fp0
	bra	t_catch

EM1POLY:
*--Step 9	exp(X)-1 by a simple polynomial
	fmove.x	(a0),fp0	* fp0 is X
	fmul.x	fp0,fp0	* fp0 is S := X*X
	fmovem.x	fp2-fp3,-(sp)	* save fp2 {fp2/fp3}
	fmove.s	#$2F30CAA8,fp1	* fp1 is B12
	fmul.x	fp0,fp1	* fp1 is S*B12
	fmove.s	#$310F8290,fp2	* fp2 is B11
	fadd.s	#$32D73220,fp1	* fp1 is B10+S*B12

	fmul.x	fp0,fp2	* fp2 is S*B11
	fmul.x	fp0,fp1	* fp1 is S*(B10 + ...

	fadd.s	#$3493F281,fp2	* fp2 is B9+S*...
	fadd.d	EM1B8(pc),fp1	* fp1 is B8+S*...

	fmul.x	fp0,fp2	* fp2 is S*(B9+...
	fmul.x	fp0,fp1	* fp1 is S*(B8+...

	fadd.d	EM1B7(pc),fp2	* fp2 is B7+S*...
	fadd.d	EM1B6(pc),fp1	* fp1 is B6+S*...

	fmul.x	fp0,fp2	* fp2 is S*(B7+...
	fmul.x	fp0,fp1	* fp1 is S*(B6+...

	fadd.d	EM1B5(pc),fp2	* fp2 is B5+S*...
	fadd.d	EM1B4(pc),fp1	* fp1 is B4+S*...

	fmul.x	fp0,fp2	* fp2 is S*(B5+...
	fmul.x	fp0,fp1	* fp1 is S*(B4+...

	fadd.d	EM1B3(pc),fp2	* fp2 is B3+S*...
	fadd.x	EM1B2(pc),fp1	* fp1 is B2+S*...

	fmul.x	fp0,fp2	* fp2 is S*(B3+...
	fmul.x	fp0,fp1	* fp1 is S*(B2+...

	fmul.x	fp0,fp2	* fp2 is S*S*(B3+...)
	fmul.x	(a0),fp1	* fp1 is X*S*(B2...

	fmul.s	#$3F000000,fp0	* fp0 is S*B1
	fadd.x	fp2,fp1	* fp1 is Q

	fmovem.x	(sp)+,fp2-fp3	* fp2 restored {fp2/fp3}

	fadd.x	fp1,fp0	* fp0 is S*B1+Q

	fmove.l	d0,fpcr
	fadd.x	(a0),fp0
	bra	t_inx2

EM1BIG:
*--Step 10	|X| > 70 log2
	move.l	(a0),d1
	ICMP.l	d1,#0
	bgt.w	EXPC1
*--Step 10.2
	fmove.s	#$BF800000,fp0	* fp0 is -1
	fmove.l	d0,fpcr
	fadd.s	#$00800000,fp0	* -1 + 2^(-126)
	bra	t_minx2

	xdef	setoxm1d
setoxm1d:
*--entry point for EXPM1(X), here X is denormalized
*--Step 0.
	bra	t_extdnrm



**-------------------------------------------------------------------------------------------------
* sgetexp():  returns the exponent portion of the input argument.
*	      The exponent bias is removed and the exponent value is
*	      returned as an extended precision number in fp0.
* sgetexpd(): handles denormalized numbers. 
*		
* sgetman():  extracts the mantissa of the input argument. The 
*	      mantissa is converted to an extended precision number w/ 
*	      an exponent of $3fff and is returned in fp0. The range of *
*	      the result is [1.0 - 2.0).
* sgetmand(): handles denormalized numbers.
*		
* INPUT *************************************************************** *
*	a0  = pointer to extended precision input
*		
* OUTPUT ************************************************************** *
*	fp0 = exponent(X) or mantissa(X)
*		
**-------------------------------------------------------------------------------------------------

	xdef	sgetexp
sgetexp:
	move.w	SRC_EX(a0),d0	* get the exponent
	bclr	#$f,d0	* clear the sign bit
	subi.w	#$3fff,d0	* subtract off the bias
	fmove.w	d0,fp0	* return exp in fp0
	blt.b	sgetexpn	* it's negative
	rts

sgetexpn:
	move.b	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	rts

	xdef	sgetexpd
sgetexpd:
	bsr	norm	* normalize
	neg.w	d0	* new exp = -(shft amt)
	subi.w	#$3fff,d0	* subtract off the bias
	fmove.w	d0,fp0	* return exp in fp0
	move.b	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	rts

	xdef	sgetman
sgetman:
	move.w	SRC_EX(a0),d0	* get the exp
	ori.w	#$7fff,d0	* clear old exp
	bclr	#$e,d0	* make it the new exp +-3fff

* here, we build the result in a tmp location so as not to disturb the input
	move.l	SRC_HI(a0),EXC_LV+FP_SCR0_HI(a6) * copy to tmp loc
	move.l	SRC_LO(a0),EXC_LV+FP_SCR0_LO(a6) * copy to tmp loc
	move.w	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent
	fmove.x	EXC_LV+FP_SCR0(a6),fp0	* put new value back in fp0
	bmi.b	sgetmann	* it's negative
	rts

sgetmann:
	move.b	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	rts

*
* For denormalized numbers, shift the mantissa until the j-bit = 1,
* then load the exponent with +/1 $3fff.
*
	xdef	sgetmand
sgetmand:
	bsr	norm	* normalize exponent
	bra.b	sgetman

**-------------------------------------------------------------------------------------------------
* scosh():  computes the hyperbolic cosine of a normalized input
* scoshd(): computes the hyperbolic cosine of a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************
*	fp0 = cosh(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic 
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*	COSH	
*	1. If |X| > 16380 log2, go to 3.
*		
*	2. (|X| <= 16380 log2) Cosh(X) is obtained by the formulae
*	y = |X|, z = exp(Y), and
*	cosh(X) = (1/2)*( z + 1/z ).
*	Exit.	
*		
*	3. (|X| > 16380 log2). If |X| > 16480 log2, go to 5.
*		
*	4. (16380 log2 < |X| <= 16480 log2)
*	cosh(X) = sign(X) * exp(|X|)/2.
*	However, invoking exp(|X|) may cause premature 
*	overflow. Thus, we calculate sinh(X) as follows:
*	Y	:= |X|	
*	Fact	:=	2**(16380)
*	Y'	:= Y - 16381 log2
*	cosh(X) := Fact * exp(Y').
*	Exit.	
*		
*	5. (|X| > 16480 log2) sinh(X) must overflow. Return
*	Huge*Huge to generate overflow and an infinity with
*	the appropriate sign. Huge is the largest finite number
*	in extended format. Exit.
*		
**-------------------------------------------------------------------------------------------------

TWO16380:
	dc.l	$7FFB0000,$80000000,$00000000,$00000000

	xdef	scosh
scosh:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1,#$400CB167
	bgt.b	COSHBIG

*--THIS IS THE USUAL CASE, |X| < 16380 LOG2
*--COSH(X) = (1/2) * ( EXP(X) + 1/EXP(X) )

	fabs.x	fp0	* |X|

	move.l	d0,-(sp)
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save |X| to stack
	lea	(sp),a0	* pass ptr to |X|
	bsr	setox	* FP0 IS EXP(|X|)
	add.l	#$c,sp	* erase |X| from stack
	fmul.s	#$3F000000,fp0	* (1/2)EXP(|X|)
	move.l	(sp)+,d0

	fmove.s	#$3E800000,fp1	* (1/4)
	fdiv.x	fp0,fp1	* 1/(2 EXP(|X|))

	fmove.l	d0,fpcr
	move.b	#FADD_OP,d1	* last inst is ADD
	fadd.x	fp1,fp0
	bra	t_catch

COSHBIG:
	ICMP.l	d1,#$400CB2B3
	bgt.b	COSHHUGE

	fabs.x	fp0
	fsub.d	T1(pc),fp0	* (|X|-16381LOG2_LEAD)
	fsub.d	T2(pc),fp0	* |X| - 16381 LOG2, ACCURATE

	move.l	d0,-(sp)
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save fp0 to stack
	lea	(sp),a0	* pass ptr to fp0
	bsr	setox
	add.l	#$c,sp	* clear fp0 from stack
	move.l	(sp)+,d0

	fmove.l	d0,fpcr
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	TWO16380(pc),fp0
	bra	t_catch

COSHHUGE:
	bra	t_ovfl2

	xdef	scoshd
*--COSH(X) = 1 FOR DENORMALIZED X
scoshd:
	fmove.s	#$3F800000,fp0

	fmove.l	d0,fpcr
	fadd.s	#$00800000,fp0
	bra	t_pinx2

**-------------------------------------------------------------------------------------------------
* ssinh():  computes the hyperbolic sine of a normalized input
* ssinhd(): computes the hyperbolic sine of a denormalized input
*		
* INPUT *************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT ************************************************************** *
*	fp0 = sinh(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently *
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM *********************************************************** *
*		
*       SINH	
*       1. If |X| > 16380 log2, go to 3.
*		
*       2. (|X| <= 16380 log2) Sinh(X) is obtained by the formula
*               y = |X|, sgn = sign(X), and z = expm1(Y),
*               sinh(X) = sgn*(1/2)*( z + z/(1+z) ).
*          Exit.	
*		
*       3. If |X| > 16480 log2, go to 5.
*		
*       4. (16380 log2 < |X| <= 16480 log2)
*               sinh(X) = sign(X) * exp(|X|)/2.
*          However, invoking exp(|X|) may cause premature overflow.
*          Thus, we calculate sinh(X) as follows:
*             Y       := |X|	
*             sgn     := sign(X)	
*             sgnFact := sgn * 2**(16380)
*             Y'      := Y - 16381 log2	
*             sinh(X) := sgnFact * exp(Y').
*          Exit.	
*		
*       5. (|X| > 16480 log2) sinh(X) must overflow. Return
*          sign(X)*Huge*Huge to generate overflow and an infinity with
*          the appropriate sign. Huge is the largest finite number in
*          extended format. Exit.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	ssinh
ssinh:
	fmove.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	move.l	d1,a1	* save (compacted) operand
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1,#$400CB167
	bgt.b	SINHBIG

*--THIS IS THE USUAL CASE, |X| < 16380 LOG2
*--Y = |X|, Z = EXPM1(Y), SINH(X) = SIGN(X)*(1/2)*( Z + Z/(1+Z) )

	fabs.x	fp0	* Y = |X|

	movem.l	a1/d0,-(sp)	* {a1/d0}
	fmovem.x	fp0,-(sp)	* save Y on stack
	lea	(sp),a0	* pass ptr to Y
	clr.l	d0
	bsr	setoxm1	* FP0 IS Z = EXPM1(Y)
	add.l	#$c,sp	* clear Y from stack
	fmove.l	#0,fpcr
	movem.l	(sp)+,a1/d0	* {a1/d0}

	fmove.x	fp0,fp1
	fadd.s	#$3F800000,fp1	* 1+Z
	fmove.x	fp0,-(sp)
	fdiv.x	fp1,fp0	* Z/(1+Z)
	move.l	a1,d1
	and.l	#$80000000,d1
	or.l	#$3F000000,d1
	fadd.x	(sp)+,fp0
	move.l	d1,-(sp)

	fmove.l	d0,fpcr
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.s	(sp)+,fp0	* last fp inst - possible exceptions set
	bra	t_catch

SINHBIG:
	ICMP.l	d1,#$400CB2B3
	bgt	t_ovfl
	fabs.x	fp0
	fsub.d	T1(pc),fp0	* (|X|-16381LOG2_LEAD)
	move.l	#0,-(sp)
	move.l	#$80000000,-(sp)
	move.l	a1,d1
	and.l	#$80000000,d1
	or.l	#$7FFB0000,d1
	move.l	d1,-(sp)	* EXTENDED FMT
	fsub.d	T2(pc),fp0	* |X| - 16381 LOG2, ACCURATE

	move.l	d0,-(sp)
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save fp0 on stack
	lea	(sp),a0	* pass ptr to fp0
	bsr	setox
	add.l	#$c,sp	* clear fp0 from stack

	move.l	(sp)+,d0
	fmove.l	d0,fpcr
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	(sp)+,fp0	* possible exception
	bra	t_catch

	xdef	ssinhd
*--SINH(X) = X FOR DENORMALIZED X
ssinhd:
	bra	t_extdnrm

**-------------------------------------------------------------------------------------------------
* stanh():  computes the hyperbolic tangent of a normalized input
* stanhd(): computes the hyperbolic tangent of a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************
*	fp0 = tanh(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently *
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*	TANH	
*	1. If |X| >= (5/2) log2 or |X| <= 2**(-40), go to 3.
*		
*	2. (2**(-40) < |X| < (5/2) log2) Calculate tanh(X) by
*	sgn := sign(X), y := 2|X|, z := expm1(Y), and
*	tanh(X) = sgn*( z/(2+z) ).
*	Exit.	
*		
*	3. (|X| <= 2**(-40) or |X| >= (5/2) log2). If |X| < 1,
*	go to 7.	
*		
*	4. (|X| >= (5/2) log2) If |X| >= 50 log2, go to 6.
*		
*	5. ((5/2) log2 <= |X| < 50 log2) Calculate tanh(X) by
*	sgn := sign(X), y := 2|X|, z := exp(Y),
*	tanh(X) = sgn - [ sgn*2/(1+z) ].
*	Exit.	
*		
*	6. (|X| >= 50 log2) Tanh(X) = +-1 (round to nearest). Thus, we
*	calculate Tanh(X) by	
*	sgn := sign(X), Tiny := 2**(-126),
*	tanh(X) := sgn - sgn*Tiny.
*	Exit.	
*		
*	7. (|X| < 2**(-40)). Tanh(X) = X.	Exit.
*		
**-------------------------------------------------------------------------------------------------

*X	equ	EXC_LV+FP_SCR0
*XFRAC	equ	X+4
SGN	equ	EXC_LV+L_SCR3
V	equ	EXC_LV+FP_SCR0

	xdef	stanh
stanh:
	fmove.x	(a0),fp0	* LOAD INPUT

	fmove.x	fp0,X(a6)
	move.l	(a0),d1
	move.w	4(a0),d1
	move.l	d1,X(a6)
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1, #$3fd78000	* is |X| < 2^(-40)?
	blt.w	TANHBORS	* yes
	ICMP.l	d1, #$3fffddce	* is |X| > (5/2)LOG2?
	bgt.w	TANHBORS	* yes

*--THIS IS THE USUAL CASE
*--Y = 2|X|, Z = EXPM1(Y), TANH(X) = SIGN(X) * Z / (Z+2).

	move.l	X(a6),d1
	move.l	d1,SGN(a6)
	and.l	#$7FFF0000,d1
	add.l	#$00010000,d1	* EXPONENT OF 2|X|
	move.l	d1,X(a6)
	and.l	#$80000000,SGN(a6)
	fmove.x	X(a6),fp0	* FP0 IS Y = 2|X|

	move.l	d0,-(sp)
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save Y on stack
	lea	(sp),a0	* pass ptr to Y
	bsr	setoxm1	* FP0 IS Z = EXPM1(Y)
	add.l	#$c,sp	* clear Y from stack
	move.l	(sp)+,d0

	fmove.x	fp0,fp1
	fadd.s	#$40000000,fp1	* Z+2
	move.l	SGN(a6),d1
	fmove.x	fp1,V(a6)
	eor.l	d1,V(a6)

	fmove.l	d0,fpcr	* restore users round prec,mode
	fdiv.x	V(a6),fp0
	bra	t_inx2

TANHBORS:
	ICMP.l	d1,#$3FFF8000
	blt.w	TANHSM

	ICMP.l	d1,#$40048AA1
	bgt.w	TANHHUGE

*-- (5/2) LOG2 < |X| < 50 LOG2,
*--TANH(X) = 1 - (2/[EXP(2X)+1]). LET Y = 2|X|, SGN = SIGN(X),
*--TANH(X) = SGN -	SGN*2/[EXP(Y)+1].

	move.l	X(a6),d1
	move.l	d1,SGN(a6)
	and.l	#$7FFF0000,d1
	add.l	#$00010000,d1	* EXPO OF 2|X|
	move.l	d1,X(a6)	* Y = 2|X|
	and.l	#$80000000,SGN(a6)
	move.l	SGN(a6),d1
	fmove.x	X(a6),fp0	* Y = 2|X|

	move.l	d0,-(sp)
	clr.l	d0
	fmovem.x	fp0,-(sp)	* save Y on stack
	lea	(sp),a0	* pass ptr to Y
	bsr	setox	* FP0 IS EXP(Y)
	add.l	#$c,sp	* clear Y from stack
	move.l	(sp)+,d0
	move.l	SGN(a6),d1
	fadd.s	#$3F800000,fp0	* EXP(Y)+1

	eor.l	#$c0000000,d1	* -SIGN(X)*2
	fmove.s	d1,fp1	* -SIGN(X)*2 IN SGL FMT
	fdiv.x	fp0,fp1	* -SIGN(X)2 / [EXP(Y)+1 ]

	move.l	SGN(a6),d1
	or.l	#$3F800000,d1	* SGN
	fmove.s	d1,fp0	* SGN IN SGL FMT

	fmove.l	d0,fpcr	* restore users round prec,mode
	move.b	#FADD_OP,d1	* last inst is ADD
	fadd.x	fp1,fp0
	bra	t_inx2

TANHSM:
	fmove.l	d0,fpcr	* restore users round prec,mode
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	X(a6),fp0	* last inst - possible exception set
	bra	t_catch

*---RETURN SGN(X) - SGN(X)EPS
TANHHUGE:
	move.l	X(a6),d1
	and.l	#$80000000,d1
	or.l	#$3F800000,d1
	fmove.s	d1,fp0
	and.l	#$80000000,d1
	eor.l	#$80800000,d1	* -SIGN(X)*EPS

	fmove.l	d0,fpcr	* restore users round prec,mode
	fadd.s	d1,fp0
	bra	t_inx2

	xdef	stanhd
*--TANH(X) = X FOR DENORMALIZED X
stanhd:
	bra	t_extdnrm

**-------------------------------------------------------------------------------------------------
* slogn():    computes the natural logarithm of a normalized input
* slognd():   computes the natural logarithm of a denormalized input
* slognp1():  computes the log(1+X) of a normalized input
* slognp1d(): computes the log(1+X) of a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************
*	fp0 = log(X) or log(1+X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 2 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*	LOGN:	
*	Step 1. If |X-1| < 1/16, approximate log(X) by an odd 
*	polynomial in u, where u = 2(X-1)/(X+1). Otherwise, 
*	move on to Step 2.	
*		
*	Step 2. X = 2**k * Y where 1 <= Y < 2. Define F to be the first
*	seven significant bits of Y plus 2**(-7), i.e. 
*	F = 1.xxxxxx1 in base 2 where the six "x" match those 
*	of Y. Note that |Y-F| <= 2**(-7).
*		
*	Step 3. Define u = (Y-F)/F. Approximate log(1+u) by a 
*	polynomial in u, log(1+u) = poly.
*		
*	Step 4. Reconstruct 	
*	log(X) = log( 2**k * Y ) = k*log(2) + log(F) + log(1+u)
*	by k*log(2) + (log(F) + poly). The values of log(F) are
*	calculated beforehand and stored in the program.
*		
*	lognp1:	
*	Step 1: If |X| < 1/16, approximate log(1+X) by an odd 
*	polynomial in u where u = 2X/(2+X). Otherwise, move on
*	to Step 2.	
*		
*	Step 2: Let 1+X = 2**k * Y, where 1 <= Y < 2. Define F as done
*	in Step 2 of the algorithm for LOGN and compute 
*	log(1+X) as k*log(2) + log(F) + poly where poly 
*	approximates log(1+u), u = (Y-F)/F. 
*		
*	Implementation Notes:	
*	Note 1. There are 64 different possible values for F, thus 64 
*	log(F)'s need to be tabulated. Moreover, the values of
*	1/F are also tabulated so that the division in (Y-F)/F
*	can be performed by a multiplication.
*		
*	Note 2. In Step 2 of lognp1, in order to preserved accuracy, 
*	the value Y-F has to be calculated carefully when 
*	1/2 <= X < 3/2. 	
*		
*	Note 3. To fully exploit the pipeline, polynomials are usually 
*	separated into two parts evaluated independently before
*	being added up.	
*		
**-------------------------------------------------------------------------------------------------
LOGOF2:
	dc.l	$3FFE0000,$B17217F7,$D1CF79AC,$00000000

one:
	dc.l	$3F800000
zero:
	dc.l	$00000000
infty:
	dc.l	$7F800000
negone:
	dc.l	$BF800000

LOGA6:
	dc.l	$3FC2499A,$B5E4040B
LOGA5:
	dc.l	$BFC555B5,$848CB7DB

LOGA4:
	dc.l	$3FC99999,$987D8730
LOGA3:
	dc.l	$BFCFFFFF,$FF6F7E97

LOGA2:
	dc.l	$3FD55555,$555555A4
LOGA1:
	dc.l	$BFE00000,$00000008

LOGB5:
	dc.l	$3F175496,$ADD7DAD6
LOGB4:
	dc.l	$3F3C71C2,$FE80C7E0

LOGB3:
	dc.l	$3F624924,$928BCCFF
LOGB2:
	dc.l	$3F899999,$999995EC

LOGB1:
	dc.l	$3FB55555,$55555555
TWO:
	dc.l	$40000000,$00000000

LTHOLD:
	dc.l	$3f990000,$80000000,$00000000,$00000000

LOGTBL:
	dc.l	$3FFE0000,$FE03F80F,$E03F80FE,$00000000
	dc.l	$3FF70000,$FF015358,$833C47E2,$00000000
	dc.l	$3FFE0000,$FA232CF2,$52138AC0,$00000000
	dc.l	$3FF90000,$BDC8D83E,$AD88D549,$00000000
	dc.l	$3FFE0000,$F6603D98,$0F6603DA,$00000000
	dc.l	$3FFA0000,$9CF43DCF,$F5EAFD48,$00000000
	dc.l	$3FFE0000,$F2B9D648,$0F2B9D65,$00000000
	dc.l	$3FFA0000,$DA16EB88,$CB8DF614,$00000000
	dc.l	$3FFE0000,$EF2EB71F,$C4345238,$00000000
	dc.l	$3FFB0000,$8B29B775,$1BD70743,$00000000
	dc.l	$3FFE0000,$EBBDB2A5,$C1619C8C,$00000000
	dc.l	$3FFB0000,$A8D839F8,$30C1FB49,$00000000
	dc.l	$3FFE0000,$E865AC7B,$7603A197,$00000000
	dc.l	$3FFB0000,$C61A2EB1,$8CD907AD,$00000000
	dc.l	$3FFE0000,$E525982A,$F70C880E,$00000000
	dc.l	$3FFB0000,$E2F2A47A,$DE3A18AF,$00000000
	dc.l	$3FFE0000,$E1FC780E,$1FC780E2,$00000000
	dc.l	$3FFB0000,$FF64898E,$DF55D551,$00000000
	dc.l	$3FFE0000,$DEE95C4C,$A037BA57,$00000000
	dc.l	$3FFC0000,$8DB956A9,$7B3D0148,$00000000
	dc.l	$3FFE0000,$DBEB61EE,$D19C5958,$00000000
	dc.l	$3FFC0000,$9B8FE100,$F47BA1DE,$00000000
	dc.l	$3FFE0000,$D901B203,$6406C80E,$00000000
	dc.l	$3FFC0000,$A9372F1D,$0DA1BD17,$00000000
	dc.l	$3FFE0000,$D62B80D6,$2B80D62C,$00000000
	dc.l	$3FFC0000,$B6B07F38,$CE90E46B,$00000000
	dc.l	$3FFE0000,$D3680D36,$80D3680D,$00000000
	dc.l	$3FFC0000,$C3FD0329,$06488481,$00000000
	dc.l	$3FFE0000,$D0B69FCB,$D2580D0B,$00000000
	dc.l	$3FFC0000,$D11DE0FF,$15AB18CA,$00000000
	dc.l	$3FFE0000,$CE168A77,$25080CE1,$00000000
	dc.l	$3FFC0000,$DE1433A1,$6C66B150,$00000000
	dc.l	$3FFE0000,$CB8727C0,$65C393E0,$00000000
	dc.l	$3FFC0000,$EAE10B5A,$7DDC8ADD,$00000000
	dc.l	$3FFE0000,$C907DA4E,$871146AD,$00000000
	dc.l	$3FFC0000,$F7856E5E,$E2C9B291,$00000000
	dc.l	$3FFE0000,$C6980C69,$80C6980C,$00000000
	dc.l	$3FFD0000,$82012CA5,$A68206D7,$00000000
	dc.l	$3FFE0000,$C4372F85,$5D824CA6,$00000000
	dc.l	$3FFD0000,$882C5FCD,$7256A8C5,$00000000
	dc.l	$3FFE0000,$C1E4BBD5,$95F6E947,$00000000
	dc.l	$3FFD0000,$8E44C60B,$4CCFD7DE,$00000000
	dc.l	$3FFE0000,$BFA02FE8,$0BFA02FF,$00000000
	dc.l	$3FFD0000,$944AD09E,$F4351AF6,$00000000
	dc.l	$3FFE0000,$BD691047,$07661AA3,$00000000
	dc.l	$3FFD0000,$9A3EECD4,$C3EAA6B2,$00000000
	dc.l	$3FFE0000,$BB3EE721,$A54D880C,$00000000
	dc.l	$3FFD0000,$A0218434,$353F1DE8,$00000000
	dc.l	$3FFE0000,$B92143FA,$36F5E02E,$00000000
	dc.l	$3FFD0000,$A5F2FCAB,$BBC506DA,$00000000
	dc.l	$3FFE0000,$B70FBB5A,$19BE3659,$00000000
	dc.l	$3FFD0000,$ABB3B8BA,$2AD362A5,$00000000
	dc.l	$3FFE0000,$B509E68A,$9B94821F,$00000000
	dc.l	$3FFD0000,$B1641795,$CE3CA97B,$00000000
	dc.l	$3FFE0000,$B30F6352,$8917C80B,$00000000
	dc.l	$3FFD0000,$B7047551,$5D0F1C61,$00000000
	dc.l	$3FFE0000,$B11FD3B8,$0B11FD3C,$00000000
	dc.l	$3FFD0000,$BC952AFE,$EA3D13E1,$00000000
	dc.l	$3FFE0000,$AF3ADDC6,$80AF3ADE,$00000000
	dc.l	$3FFD0000,$C2168ED0,$F458BA4A,$00000000
	dc.l	$3FFE0000,$AD602B58,$0AD602B6,$00000000
	dc.l	$3FFD0000,$C788F439,$B3163BF1,$00000000
	dc.l	$3FFE0000,$AB8F69E2,$8359CD11,$00000000
	dc.l	$3FFD0000,$CCECAC08,$BF04565D,$00000000
	dc.l	$3FFE0000,$A9C84A47,$A07F5638,$00000000
	dc.l	$3FFD0000,$D2420487,$2DD85160,$00000000
	dc.l	$3FFE0000,$A80A80A8,$0A80A80B,$00000000
	dc.l	$3FFD0000,$D7894992,$3BC3588A,$00000000
	dc.l	$3FFE0000,$A655C439,$2D7B73A8,$00000000
	dc.l	$3FFD0000,$DCC2C4B4,$9887DACC,$00000000
	dc.l	$3FFE0000,$A4A9CF1D,$96833751,$00000000
	dc.l	$3FFD0000,$E1EEBD3E,$6D6A6B9E,$00000000
	dc.l	$3FFE0000,$A3065E3F,$AE7CD0E0,$00000000
	dc.l	$3FFD0000,$E70D785C,$2F9F5BDC,$00000000
	dc.l	$3FFE0000,$A16B312E,$A8FC377D,$00000000
	dc.l	$3FFD0000,$EC1F392C,$5179F283,$00000000
	dc.l	$3FFE0000,$9FD809FD,$809FD80A,$00000000
	dc.l	$3FFD0000,$F12440D3,$E36130E6,$00000000
	dc.l	$3FFE0000,$9E4CAD23,$DD5F3A20,$00000000
	dc.l	$3FFD0000,$F61CCE92,$346600BB,$00000000
	dc.l	$3FFE0000,$9CC8E160,$C3FB19B9,$00000000
	dc.l	$3FFD0000,$FB091FD3,$8145630A,$00000000
	dc.l	$3FFE0000,$9B4C6F9E,$F03A3CAA,$00000000
	dc.l	$3FFD0000,$FFE97042,$BFA4C2AD,$00000000
	dc.l	$3FFE0000,$99D722DA,$BDE58F06,$00000000
	dc.l	$3FFE0000,$825EFCED,$49369330,$00000000
	dc.l	$3FFE0000,$9868C809,$868C8098,$00000000
	dc.l	$3FFE0000,$84C37A7A,$B9A905C9,$00000000
	dc.l	$3FFE0000,$97012E02,$5C04B809,$00000000
	dc.l	$3FFE0000,$87224C2E,$8E645FB7,$00000000
	dc.l	$3FFE0000,$95A02568,$095A0257,$00000000
	dc.l	$3FFE0000,$897B8CAC,$9F7DE298,$00000000
	dc.l	$3FFE0000,$94458094,$45809446,$00000000
	dc.l	$3FFE0000,$8BCF55DE,$C4CD05FE,$00000000
	dc.l	$3FFE0000,$92F11384,$0497889C,$00000000
	dc.l	$3FFE0000,$8E1DC0FB,$89E125E5,$00000000
	dc.l	$3FFE0000,$91A2B3C4,$D5E6F809,$00000000
	dc.l	$3FFE0000,$9066E68C,$955B6C9B,$00000000
	dc.l	$3FFE0000,$905A3863,$3E06C43B,$00000000
	dc.l	$3FFE0000,$92AADE74,$C7BE59E0,$00000000
	dc.l	$3FFE0000,$8F1779D9,$FDC3A219,$00000000
	dc.l	$3FFE0000,$94E9BFF6,$15845643,$00000000
	dc.l	$3FFE0000,$8DDA5202,$37694809,$00000000
	dc.l	$3FFE0000,$9723A1B7,$20134203,$00000000
	dc.l	$3FFE0000,$8CA29C04,$6514E023,$00000000
	dc.l	$3FFE0000,$995899C8,$90EB8990,$00000000
	dc.l	$3FFE0000,$8B70344A,$139BC75A,$00000000
	dc.l	$3FFE0000,$9B88BDAA,$3A3DAE2F,$00000000
	dc.l	$3FFE0000,$8A42F870,$5669DB46,$00000000
	dc.l	$3FFE0000,$9DB4224F,$FFE1157C,$00000000
	dc.l	$3FFE0000,$891AC73A,$E9819B50,$00000000
	dc.l	$3FFE0000,$9FDADC26,$8B7A12DA,$00000000
	dc.l	$3FFE0000,$87F78087,$F78087F8,$00000000
	dc.l	$3FFE0000,$A1FCFF17,$CE733BD4,$00000000
	dc.l	$3FFE0000,$86D90544,$7A34ACC6,$00000000
	dc.l	$3FFE0000,$A41A9E8F,$5446FB9F,$00000000
	dc.l	$3FFE0000,$85BF3761,$2CEE3C9B,$00000000
	dc.l	$3FFE0000,$A633CD7E,$6771CD8B,$00000000
	dc.l	$3FFE0000,$84A9F9C8,$084A9F9D,$00000000
	dc.l	$3FFE0000,$A8489E60,$0B435A5E,$00000000
	dc.l	$3FFE0000,$83993052,$3FBE3368,$00000000
	dc.l	$3FFE0000,$AA59233C,$CCA4BD49,$00000000
	dc.l	$3FFE0000,$828CBFBE,$B9A020A3,$00000000
	dc.l	$3FFE0000,$AC656DAE,$6BCC4985,$00000000
	dc.l	$3FFE0000,$81848DA8,$FAF0D277,$00000000
	dc.l	$3FFE0000,$AE6D8EE3,$60BB2468,$00000000
	dc.l	$3FFE0000,$80808080,$80808081,$00000000
	dc.l	$3FFE0000,$B07197A2,$3C46C654,$00000000

ADJK	equ	EXC_LV+L_SCR1

*X	equ	EXC_LV+FP_SCR0
*XDCARE	equ	X+2
*XFRAC	equ	X+4

F	equ	EXC_LV+FP_SCR1
FFRAC	equ	F+4

KLOG2	equ	EXC_LV+FP_SCR0

SAVEU	equ	EXC_LV+FP_SCR0

	xdef	slogn
*--ENTRY POINT FOR LOG(X) FOR X FINITE, NON-ZERO, NOT NAN'S
slogn:
	fmove.x	(a0),fp0	* LOAD INPUT
	move.l	#$00000000,ADJK(a6)

LOGBGN:
*--FPCR SAVED AND CLEARED, INPUT IS 2^(ADJK)*FP0, FP0 CONTAINS
*--A FINITE, NON-ZERO, NORMALIZED NUMBER.

	move.l	(a0),d1
	move.w	4(a0),d1

	move.l	(a0),X(a6)
	move.l	4(a0),X+4(a6)
	move.l	8(a0),X+8(a6)

	ICMP.l	d1,#0	* CHECK IF X IS NEGATIVE
	blt.w	LOGNEG	* LOG OF NEGATIVE ARGUMENT IS INVALID
* X IS POSITIVE, CHECK IF X IS NEAR 1
	ICMP.l	d1,#$3ffef07d 	* IS X < 15/16?
	blt.b	LOGMAIN	* YES
	ICMP.l	d1,#$3fff8841 	* IS X > 17/16?
	ble.w	LOGNEAR1	* NO

LOGMAIN:
*--THIS SHOULD BE THE USUAL CASE, X NOT VERY CLOSE TO 1

*--X = 2^(K) * Y, 1 <= Y < 2. THUS, Y = 1.XXXXXXXX....XX IN BINARY.
*--WE DEFINE F = 1.XXXXXX1, I.E. FIRST 7 BITS OF Y AND ATTACH A 1.
*--THE IDEA IS THAT LOG(X) = K*LOG2 + LOG(Y)
*--	 = K*LOG2 + LOG(F) + LOG(1 + (Y-F)/F).
*--NOTE THAT U = (Y-F)/F IS VERY SMALL AND THUS APPROXIMATING
*--LOG(1+U) CAN BE VERY EFFICIENT.
*--ALSO NOTE THAT THE VALUE 1/F IS STORED IN A TABLE SO THAT NO
*--DIVISION IS NEEDED TO CALCULATE (Y-F)/F. 

*--GET K, Y, F, AND ADDRESS OF 1/F.
	asr.l	#8,d1
	asr.l	#8,d1	* SHIFTED 16 BITS, BIASED EXPO. OF X
	sub.l	#$3FFF,d1	* THIS IS K
	add.l	ADJK(a6),d1	* ADJUST K, ORIGINAL INPUT MAY BE  DENORM.
	lea	LOGTBL(pc),a0	* BASE ADDRESS OF 1/F AND LOG(F)
	fmove.l	d1,fp1	* CONVERT K TO FLOATING-POINT FORMAT

*--WHILE THE CONVERSION IS GOING ON, WE GET F AND ADDRESS OF 1/F
	move.l	#$3FFF0000,X(a6)	* X IS NOW Y, I.E. 2^(-K)*X
	move.l	XFRAC(a6),FFRAC(a6)
	and.l	#$FE000000,FFRAC(a6)	* FIRST 7 BITS OF Y
	or.l	#$01000000,FFRAC(a6)	* GET F: ATTACH A 1 AT THE EIGHTH BIT
	move.l	FFRAC(a6),d1	* READY TO GET ADDRESS OF 1/F
	and.l	#$7E000000,d1
	asr.l	#8,d1
	asr.l	#8,d1
	asr.l	#4,d1	* SHIFTED 20, D0 IS THE DISPLACEMENT
	add.l	d1,a0	* A0 IS THE ADDRESS FOR 1/F

	fmove.x	X(a6),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0	* Y-F
	fmovem.x	fp2-fp3,-(sp)	* SAVE FP2-3 WHILE FP0 IS NOT READY
*--SUMMARY: FP0 IS Y-F, A0 IS ADDRESS OF 1/F, FP1 IS K
*--REGISTERS SAVED: FPCR, FP1, FP2

LP1CONT1:
*--AN RE-ENTRY POINT FOR LOGNP1
	fmul.x	(a0),fp0	* FP0 IS U = (Y-F)/F
	fmul.x	LOGOF2(pc),fp1	* GET K*LOG2 WHILE FP0 IS NOT READY
	fmove.x	fp0,fp2
	fmul.x	fp2,fp2	* FP2 IS V=U*U
	fmove.x	fp1,KLOG2(a6)	* PUT K*LOG2 IN MEMEORY, FREE FP1

*--LOG(1+U) IS APPROXIMATED BY
*--U + V*(A1+U*(A2+U*(A3+U*(A4+U*(A5+U*A6))))) WHICH IS
*--[U + V*(A1+V*(A3+V*A5))]  +  [U*V*(A2+V*(A4+V*A6))]

	fmove.x	fp2,fp3
	fmove.x	fp2,fp1

	fmul.d	LOGA6(pc),fp1	* V*A6
	fmul.d	LOGA5(pc),fp2	* V*A5

	fadd.d	LOGA4(pc),fp1	* A4+V*A6
	fadd.d	LOGA3(pc),fp2	* A3+V*A5

	fmul.x	fp3,fp1	* V*(A4+V*A6)
	fmul.x	fp3,fp2	* V*(A3+V*A5)

	fadd.d	LOGA2(pc),fp1	* A2+V*(A4+V*A6)
	fadd.d	LOGA1(pc),fp2	* A1+V*(A3+V*A5)

	fmul.x	fp3,fp1	* V*(A2+V*(A4+V*A6))
	add.l	#16,a0	* ADDRESS OF LOG(F)
	fmul.x	fp3,fp2	* V*(A1+V*(A3+V*A5))

	fmul.x	fp0,fp1	* U*V*(A2+V*(A4+V*A6))
	fadd.x	fp2,fp0	* U+V*(A1+V*(A3+V*A5))

	fadd.x	(a0),fp1	* LOG(F)+U*V*(A2+V*(A4+V*A6))
	fmovem.x	(sp)+,fp2-fp3	* RESTORE FP2-3
	fadd.x	fp1,fp0	* FP0 IS LOG(F) + LOG(1+U)

	fmove.l	d0,fpcr
	fadd.x	KLOG2(a6),fp0	* FINAL ADD
	bra	t_inx2


LOGNEAR1:

* if the input is exactly equal to one, then exit through ld_pzero.
* if these 2 lines weren't here, the correct answer would be returned
* but the INEX2 bit would be set.
	fcmp.b	#1,fp0	* is it equal to one?
	fbeq.l	ld_pzero	* yes

*--REGISTERS SAVED: FPCR, FP1. FP0 CONTAINS THE INPUT.
	fmove.x	fp0,fp1
	fsub.s	one(pc),fp1	* FP1 IS X-1
	fadd.s	one(pc),fp0	* FP0 IS X+1
	fadd.x	fp1,fp1	* FP1 IS 2(X-1)
*--LOG(X) = LOG(1+U/2)-LOG(1-U/2) WHICH IS AN ODD POLYNOMIAL
*--IN U, U = 2(X-1)/(X+1) = FP1/FP0

LP1CONT2:
*--THIS IS AN RE-ENTRY POINT FOR LOGNP1
	fdiv.x	fp0,fp1	* FP1 IS U
	fmovem.x	fp2-fp3,-(sp)	* SAVE FP2-3
*--REGISTERS SAVED ARE NOW FPCR,FP1,FP2,FP3
*--LET V=U*U, W=V*V, CALCULATE
*--U + U*V*(B1 + V*(B2 + V*(B3 + V*(B4 + V*B5)))) BY
*--U + U*V*(  [B1 + W*(B3 + W*B5)]  +  [V*(B2 + W*B4)]  )
	fmove.x	fp1,fp0
	fmul.x	fp0,fp0	* FP0 IS V
	fmove.x	fp1,SAVEU(a6)	* STORE U IN MEMORY, FREE FP1
	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS W

	fmove.d	LOGB5(pc),fp3
	fmove.d	LOGB4(pc),fp2

	fmul.x	fp1,fp3	* W*B5
	fmul.x	fp1,fp2	* W*B4

	fadd.d	LOGB3(pc),fp3	* B3+W*B5
	fadd.d	LOGB2(pc),fp2	* B2+W*B4

	fmul.x	fp3,fp1	* W*(B3+W*B5), FP3 RELEASED

	fmul.x	fp0,fp2	* V*(B2+W*B4)

	fadd.d	LOGB1(pc),fp1	* B1+W*(B3+W*B5)
	fmul.x	SAVEU(a6),fp0	* FP0 IS U*V

	fadd.x	fp2,fp1	* B1+W*(B3+W*B5) + V*(B2+W*B4), FP2 RELEASED
	fmovem.x	(sp)+,fp2-fp3	* FP2-3 RESTORED

	fmul.x	fp1,fp0	* U*V*( [B1+W*(B3+W*B5)] + [V*(B2+W*B4)] )

	fmove.l	d0,fpcr
	fadd.x	SAVEU(a6),fp0
	bra	t_inx2

*--REGISTERS SAVED FPCR. LOG(-VE) IS INVALID
LOGNEG:
	bra	t_operr

	xdef	slognd
slognd:
*--ENTRY POINT FOR LOG(X) FOR DENORMALIZED INPUT

	move.l	#-100,ADJK(a6)	* INPUT = 2^(ADJK) * FP0

*----normalize the input value by left shifting k bits (k to be determined
*----below), adjusting exponent and storing -k to  ADJK
*----the value TWOTO100 is no longer needed.
*----Note that this code assumes the denormalized input is NON-ZERO.

	movem.l	d2-d7,-(sp)	* save some registers  {d2-d7}
	move.l	(a0),d3	* D3 is exponent of smallest norm. *
	move.l	4(a0),d4
	move.l	8(a0),d5	* (D4,D5) is (Hi_X,Lo_X)
	clr.l	d2	* D2 used for holding K

	tst.l	d4
	bne.b	Hi_not0

Hi_0:
	move.l	d5,d4
	clr.l	d5
	move.l	#32,d2
	clr.l	d6
	bfffo	d4{0:32},d6
	lsl.l	d6,d4
	add.l	d6,d2	* (D3,D4,D5) is normalized

	move.l	d3,X(a6)
	move.l	d4,XFRAC(a6)
	move.l	d5,XFRAC+4(a6)
	neg.l	d2
	move.l	d2,ADJK(a6)
	fmove.x	X(a6),fp0
	movem.l	(sp)+,d2-d7	* restore registers {d2-d7}
	lea	X(a6),a0
	bra.w	LOGBGN	* begin regular log(X)

Hi_not0:
	clr.l	d6
	bfffo	d4{0:32},d6	* find first 1
	move.l	d6,d2	* get k
	lsl.l	d6,d4
	move.l	d5,d7	* a copy of D5
	lsl.l	d6,d5
	neg.l	d6
	add.l	#32,d6
	lsr.l	d6,d7
	or.l	d7,d4	* (D3,D4,D5) normalized

	move.l	d3,X(a6)
	move.l	d4,XFRAC(a6)
	move.l	d5,XFRAC+4(a6)
	neg.l	d2
	move.l	d2,ADJK(a6)
	fmove.x	X(a6),fp0
	movem.l	(sp)+,d2-d7	* restore registers {d2-d7}
	lea	X(a6),a0
	bra.w	LOGBGN	* begin regular log(X)

	xdef	slognp1
*--ENTRY POINT FOR LOG(1+X) FOR X FINITE, NON-ZERO, NOT NAN'S
slognp1:
	fmove.x	(a0),fp0	* LOAD INPUT
	fabs.x	fp0	* test magnitude
	fcmp.x	LTHOLD(pc),fp0	* compare with min threshold
	fbgt.w	LP1REAL	* if greater, continue
	fmove.l	d0,fpcr
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	(a0),fp0	* return signed argument
	bra	t_catch

LP1REAL:
	fmove.x	(a0),fp0	* LOAD INPUT
	move.l	#$00000000,ADJK(a6)
	fmove.x	fp0,fp1	* FP1 IS INPUT Z
	fadd.s	one(pc),fp0	* X := ROUND(1+Z)
	fmove.x	fp0,X(a6)
	move.w	XFRAC(a6),XDCARE(a6)
	move.l	X(a6),d1
	ICMP.l	d1,#0
	ble.w	LP1NEG0	* LOG OF ZERO OR -VE
	ICMP.l	d1,#$3ffe8000 	* IS BOUNDS [1/2,3/2]?
	blt.w	LOGMAIN
	ICMP.l	d1,#$3fffc000
	bgt.w	LOGMAIN 
*--IF 1+Z > 3/2 OR 1+Z < 1/2, THEN X, WHICH IS ROUNDING 1+Z,
*--CONTAINS AT LEAST 63 BITS OF INFORMATION OF Z. IN THAT CASE,
*--SIMPLY INVOKE LOG(X) FOR LOG(1+Z).

LP1NEAR1:
*--NEXT SEE IF EXP(-1/16) < X < EXP(1/16)
	ICMP.l	d1,#$3ffef07d
	blt.w	LP1CARE
	ICMP.l	d1,#$3fff8841
	bgt.w	LP1CARE

LP1ONE16:
*--EXP(-1/16) < X < EXP(1/16). LOG(1+Z) = LOG(1+U/2) - LOG(1-U/2)
*--WHERE U = 2Z/(2+Z) = 2Z/(1+X).
	fadd.x	fp1,fp1	* FP1 IS 2Z
	fadd.s	one(pc),fp0	* FP0 IS 1+X
*--U = FP1/FP0
	bra.w	LP1CONT2

LP1CARE:
*--HERE WE USE THE USUAL TABLE DRIVEN APPROACH. CARE HAS TO BE
*--TAKEN BECAUSE 1+Z CAN HAVE 67 BITS OF INFORMATION AND WE MUST
*--PRESERVE ALL THE INFORMATION. BECAUSE 1+Z IS IN [1/2,3/2],
*--THERE ARE ONLY TWO CASES.
*--CASE 1: 1+Z < 1, THEN K = -1 AND Y-F = (2-F) + 2Z
*--CASE 2: 1+Z > 1, THEN K = 0  AND Y-F = (1-F) + Z
*--ON RETURNING TO LP1CONT1, WE MUST HAVE K IN FP1, ADDRESS OF
*--(1/F) IN A0, Y-F IN FP0, AND FP2 SAVED.

	move.l	XFRAC(a6),FFRAC(a6)
	and.l	#$FE000000,FFRAC(a6)
	or.l	#$01000000,FFRAC(a6)	* F OBTAINED
	ICMP.l	d1,#$3FFF8000	* SEE IF 1+Z > 1
	bge.b	KISZERO

KISNEG1:
	fmove.s	TWO(pc),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0	* 2-F
	move.l	FFRAC(a6),d1
	and.l	#$7E000000,d1
	asr.l	#8,d1
	asr.l	#8,d1
	asr.l	#4,d1	* D0 CONTAINS DISPLACEMENT FOR 1/F
	fadd.x	fp1,fp1	* GET 2Z
	fmovem.x	fp2-fp3,-(sp)	* SAVE FP2  {fp2/fp3}
	fadd.x	fp1,fp0	* FP0 IS Y-F = (2-F)+2Z
	lea	LOGTBL(pc),a0	* A0 IS ADDRESS OF 1/F
	add.l	d1,a0
	fmove.s	negone(pc),fp1	* FP1 IS K = -1
	bra.w	LP1CONT1

KISZERO:
	fmove.s	one(pc),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0	* 1-F
	move.l	FFRAC(a6),d1
	and.l	#$7E000000,d1
	asr.l	#8,d1
	asr.l	#8,d1
	asr.l	#4,d1
	fadd.x	fp1,fp0	* FP0 IS Y-F
	fmovem.x	fp2-fp3,-(sp)	* FP2 SAVED {fp2/fp3}
	lea	LOGTBL(pc),a0
	add.l	d1,a0	* A0 IS ADDRESS OF 1/F
	fmove.s	zero(pc),fp1	* FP1 IS K = 0
	bra.w	LP1CONT1

LP1NEG0:
*--FPCR SAVED. D0 IS X IN COMPACT FORM.
	ICMP.l	d1,#0
	blt.b	LP1NEG
LP1ZERO:
	fmove.s	negone(pc),fp0

	fmove.l	d0,fpcr
	bra	t_dz

LP1NEG:
	fmove.s	zero(pc),fp0

	fmove.l	d0,fpcr
	bra	t_operr

	xdef	slognp1d
*--ENTRY POINT FOR LOG(1+Z) FOR DENORMALIZED INPUT
* Simply return the denorm
slognp1d:
	bra	t_extdnrm

**-------------------------------------------------------------------------------------------------
* satanh():  computes the inverse hyperbolic tangent of a norm input
* satanhd(): computes the inverse hyperbolic tangent of a denorm input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************	* 
*	fp0 = arctanh(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 3 ulps in	64 significant bit,
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*	ATANH	
*	1. If |X| >= 1, go to 3.	
*		
*	2. (|X| < 1) Calculate atanh(X) by
*	sgn := sign(X)	
*	y := |X|	
*	z := 2y/(1-y)	
*	atanh(X) := sgn * (1/2) * logp1(z)
*	Exit.	
*		
*	3. If |X| > 1, go to 5.	
*		
*	4. (|X| = 1) Generate infinity with an appropriate sign and
*	divide-by-zero by	
*	sgn := sign(X)	
*	atan(X) := sgn / (+0).	
*	Exit.	
*		
*	5. (|X| > 1) Generate an invalid operation by 0 * infinity.
*	Exit.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	satanh
satanh:
	move.l	(a0),d1
	move.w	4(a0),d1
	and.l	#$7FFFFFFF,d1
	ICMP.l	d1,#$3FFF8000
	bge.b	ATANHBIG

*--THIS IS THE USUAL CASE, |X| < 1
*--Y = |X|, Z = 2Y/(1-Y), ATANH(X) = SIGN(X) * (1/2) * LOG1P(Z).

	fabs.x	(a0),fp0	* Y = |X|
	fmove.x	fp0,fp1
	fneg.x	fp1	* -Y
	fadd.x	fp0,fp0	* 2Y
	fadd.s	#$3F800000,fp1	* 1-Y
	fdiv.x	fp1,fp0	* 2Y/(1-Y)
	move.l	(a0),d1
	and.l	#$80000000,d1
	or.l	#$3F000000,d1	* SIGN(X)*HALF
	move.l	d1,-(sp)

	move.l	d0,-(sp)	* save rnd prec,mode
	clr.l	d0	* pass ext prec,RN
	fmovem.x	fp0,-(sp)	* save Z on stack
	lea	(sp),a0	* pass ptr to Z
	bsr	slognp1	* LOG1P(Z)
	add.l	#$c,sp	* clear Z from stack

	move.l	(sp)+,d0	* fetch old prec,mode
	fmove.l	d0,fpcr	* load it
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.s	(sp)+,fp0
	bra	t_catch

ATANHBIG:
	fabs.x	(a0),fp0	* |X|
	fcmp.s	#$3F800000,fp0
	fbgt	t_operr
	bra	t_dz

	xdef	satanhd
*--ATANH(X) = X FOR DENORMALIZED X
satanhd:
	bra	t_extdnrm

**-------------------------------------------------------------------------------------------------
* slog10():  computes the base-10 logarithm of a normalized input
* slog10d(): computes the base-10 logarithm of a denormalized input
* slog2():   computes the base-2 logarithm of a normalized input
* slog2d():  computes the base-2 logarithm of a denormalized input
*		
* INPUT *************************************************************** *
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************
*	fp0 = log_10(X) or log_2(X)	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 1.7 ulps in 64 significant bit,
*	i.e. within 0.5003 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*       slog10d:	
*		
*       Step 0.	If X < 0, create a NaN and raise the invalid operation
*               flag. Otherwise, save FPCR in D1; set FpCR to default.
*       Notes:  Default means round-to-nearest mode, no floating-point
*               traps, and precision control = double extended.
*		
*       Step 1. Call slognd to obtain Y = log(X), the natural log of X.
*       Notes:  Even if X is denormalized, log(X) is always normalized.
*		
*       Step 2.  Compute log_10(X) = log(X) * (1/log(10)).
*            2.1 Restore the user FPCR	
*            2.2 Return ans := Y * INV_L10.
*		
*       slog10: 	
*		
*       Step 0. If X < 0, create a NaN and raise the invalid operation
*               flag. Otherwise, save FPCR in D1; set FpCR to default.
*       Notes:  Default means round-to-nearest mode, no floating-point
*               traps, and precision control = double extended.
*		
*       Step 1. Call sLogN to obtain Y = log(X), the natural log of X.
*		
*       Step 2.   Compute log_10(X) = log(X) * (1/log(10)).
*            2.1  Restore the user FPCR	
*            2.2  Return ans := Y * INV_L10.
*		
*       sLog2d:	
*		
*       Step 0. If X < 0, create a NaN and raise the invalid operation
*               flag. Otherwise, save FPCR in D1; set FpCR to default.
*       Notes:  Default means round-to-nearest mode, no floating-point
*               traps, and precision control = double extended.
*		
*       Step 1. Call slognd to obtain Y = log(X), the natural log of X.
*       Notes:  Even if X is denormalized, log(X) is always normalized.
*		
*       Step 2.   Compute log_10(X) = log(X) * (1/log(2)).
*            2.1  Restore the user FPCR	
*            2.2  Return ans := Y * INV_L2.
*		
*       sLog2:	
*		
*       Step 0. If X < 0, create a NaN and raise the invalid operation
*               flag. Otherwise, save FPCR in D1; set FpCR to default.
*       Notes:  Default means round-to-nearest mode, no floating-point
*               traps, and precision control = double extended.
*		
*       Step 1. If X is not an integer power of two, i.e., X != 2^k,
*               go to Step 3.	
*		
*       Step 2.   Return k.	
*            2.1  Get integer k, X = 2^k.
*            2.2  Restore the user FPCR.
*            2.3  Return ans := convert-to-double-extended(k).
*		
*       Step 3. Call sLogN to obtain Y = log(X), the natural log of X.
*		
*       Step 4.   Compute log_2(X) = log(X) * (1/log(2)).
*            4.1  Restore the user FPCR	
*            4.2  Return ans := Y * INV_L2.
*		
**-------------------------------------------------------------------------------------------------

INV_L10:
	dc.l	$3FFD0000,$DE5BD8A9,$37287195,$00000000

INV_L2:
	dc.l	$3FFF0000,$B8AA3B29,$5C17F0BC,$00000000

	xdef	slog10
*--entry point for Log10(X), X is normalized
slog10:
	fmove.b	#$1,fp0
	fcmp.x	(a0),fp0	* if operand == 1,
	fbeq.l	ld_pzero	* return an EXACT zero

	move.l	(a0),d1
	blt.w	invalid
	move.l	d0,-(sp)
	clr.l	d0
	bsr	slogn	* log(X), X normal.
	fmove.l	(sp)+,fpcr
	fmul.x	INV_L10(pc),fp0
	bra	t_inx2

	xdef	slog10d
*--entry point for Log10(X), X is denormalized
slog10d:
	move.l	(a0),d1
	blt.w	invalid
	move.l	d0,-(sp)
	clr.l	d0
	bsr	slognd	* log(X), X denorm.
	fmove.l	(sp)+,fpcr
	fmul.x	INV_L10(pc),fp0
	bra	t_minx2

	xdef	slog2
*--entry point for Log2(X), X is normalized
slog2:
	move.l	(a0),d1
	blt.w	invalid

	move.l	8(a0),d1
	bne.b	continue	* X is not 2^k

	move.l	4(a0),d1
	and.l	#$7FFFFFFF,d1
	bne.b	continue

*--X = 2^k.
	move.w	(a0),d1
	and.l	#$00007FFF,d1
	sub.l	#$3FFF,d1
	beq.l	ld_pzero
	fmove.l	d0,fpcr
	fmove.l	d1,fp0
	bra	t_inx2

continue:
	move.l	d0,-(sp)
	clr.l	d0
	bsr	slogn	* log(X), X normal.
	fmove.l	(sp)+,fpcr
	fmul.x	INV_L2(pc),fp0
	bra	t_inx2

invalid:
	bra	t_operr

	xdef	slog2d
*--entry point for Log2(X), X is denormalized
slog2d:
	move.l	(a0),d1
	blt.w	invalid
	move.l	d0,-(sp)
	clr.l	d0
	bsr	slognd	* log(X), X denorm.
	fmove.l	(sp)+,fpcr
	fmul.x	INV_L2(pc),fp0
	bra	t_minx2

**-------------------------------------------------------------------------------------------------
* stwotox():  computes 2**X for a normalized input
* stwotoxd(): computes 2**X for a denormalized input
* stentox():  computes 10**X for a normalized input
* stentoxd(): computes 10**X for a denormalized input
*		
* INPUT ***************************************************************
*	a0 = pointer to extended precision input
*	d0 = round precision,mode	
*		
* OUTPUT **************************************************************
*	fp0 = 2**X or 10**X	
*		
* ACCURACY and MONOTONICITY *******************************************
*	The returned result is within 2 ulps in 64 significant bit, 
*	i.e. within 0.5001 ulp to 53 bits if the result is subsequently
*	rounded to double precision. The result is provably monotonic
*	in double precision.	
*		
* ALGORITHM ***********************************************************
*		
*	twotox	
*	1. If |X| > 16480, go to ExpBig.
*		
*	2. If |X| < 2**(-70), go to ExpSm.
*		
*	3. Decompose X as X = N/64 + r where |r| <= 1/128. Furthermore
*	decompose N as	
*	 N = 64(M + M') + j,  j = 0,1,2,...,63.
*		
*	4. Overwrite r := r * log2. Then
*	2**X = 2**(M') * 2**(M) * 2**(j/64) * exp(r).
*	Go to expr to compute that expression.
*		
*	tentox	
*	1. If |X| > 16480*log_10(2) (base 10 log of 2), go to ExpBig.
*		
*	2. If |X| < 2**(-70), go to ExpSm.
*		
*	3. Set y := X*log_2(10)*64 (base 2 log of 10). Set
*	N := round-to-int(y). Decompose N as
*	 N = 64(M + M') + j,  j = 0,1,2,...,63.
*		
*	4. Define r as	
*	r := ((X - N*L1)-N*L2) * L10
*	where L1, L2 are the leading and trailing parts of 
*	log_10(2)/64 and L10 is the natural log of 10. Then
*	10**X = 2**(M') * 2**(M) * 2**(j/64) * exp(r).
*	Go to expr to compute that expression.
*		
*	expr	
*	1. Fetch 2**(j/64) from table as Fact1 and Fact2.
*		
*	2. Overwrite Fact1 and Fact2 by	
*	Fact1 := 2**(M) * Fact1	
*	Fact2 := 2**(M) * Fact2	
*	Thus Fact1 + Fact2 = 2**(M) * 2**(j/64).
*		
*	3. Calculate P where 1 + P approximates exp(r):
*	P = r + r*r*(A1+r*(A2+...+r*A5)).
*		
*	4. Let AdjFact := 2**(M'). Return
*	AdjFact * ( Fact1 + ((Fact1*P) + Fact2) ).
*	Exit.	
*		
*	ExpBig	
*	1. Generate overflow by Huge * Huge if X > 0; otherwise, 
*	        generate underflow by Tiny * Tiny.
*		
*	ExpSm	
*	1. Return 1 + X.	
*		
**-------------------------------------------------------------------------------------------------

L2TEN64:
	dc.l	$406A934F,$0979A371	* 64LOG10/LOG2
L10TWO1:
	dc.l	$3F734413,$509F8000	* LOG2/64LOG10

L10TWO2:
	dc.l	$BFCD0000,$C0219DC1,$DA994FD2,$00000000

LOG10:	dc.l	$40000000,$935D8DDD,$AAA8AC17,$00000000

LOG2:	dc.l	$3FFE0000,$B17217F7,$D1CF79AC,$00000000

EXPA5:	dc.l	$3F56C16D,$6F7BD0B2
EXPA4:	dc.l	$3F811112,$302C712C
EXPA3:	dc.l	$3FA55555,$55554CC1
EXPA2:	dc.l	$3FC55555,$55554A54
EXPA1:	dc.l	$3FE00000,$00000000,$00000000,$00000000

TEXPTBL:
	dc.l	$3FFF0000,$80000000,$00000000,$3F738000
	dc.l	$3FFF0000,$8164D1F3,$BC030773,$3FBEF7CA
	dc.l	$3FFF0000,$82CD8698,$AC2BA1D7,$3FBDF8A9
	dc.l	$3FFF0000,$843A28C3,$ACDE4046,$3FBCD7C9
	dc.l	$3FFF0000,$85AAC367,$CC487B15,$BFBDE8DA
	dc.l	$3FFF0000,$871F6196,$9E8D1010,$3FBDE85C
	dc.l	$3FFF0000,$88980E80,$92DA8527,$3FBEBBF1
	dc.l	$3FFF0000,$8A14D575,$496EFD9A,$3FBB80CA
	dc.l	$3FFF0000,$8B95C1E3,$EA8BD6E7,$BFBA8373
	dc.l	$3FFF0000,$8D1ADF5B,$7E5BA9E6,$BFBE9670
	dc.l	$3FFF0000,$8EA4398B,$45CD53C0,$3FBDB700
	dc.l	$3FFF0000,$9031DC43,$1466B1DC,$3FBEEEB0
	dc.l	$3FFF0000,$91C3D373,$AB11C336,$3FBBFD6D
	dc.l	$3FFF0000,$935A2B2F,$13E6E92C,$BFBDB319
	dc.l	$3FFF0000,$94F4EFA8,$FEF70961,$3FBDBA2B
	dc.l	$3FFF0000,$96942D37,$20185A00,$3FBE91D5
	dc.l	$3FFF0000,$9837F051,$8DB8A96F,$3FBE8D5A
	dc.l	$3FFF0000,$99E04593,$20B7FA65,$BFBCDE7B
	dc.l	$3FFF0000,$9B8D39B9,$D54E5539,$BFBEBAAF
	dc.l	$3FFF0000,$9D3ED9A7,$2CFFB751,$BFBD86DA
	dc.l	$3FFF0000,$9EF53260,$91A111AE,$BFBEBEDD
	dc.l	$3FFF0000,$A0B0510F,$B9714FC2,$3FBCC96E
	dc.l	$3FFF0000,$A2704303,$0C496819,$BFBEC90B
	dc.l	$3FFF0000,$A43515AE,$09E6809E,$3FBBD1DB
	dc.l	$3FFF0000,$A5FED6A9,$B15138EA,$3FBCE5EB
	dc.l	$3FFF0000,$A7CD93B4,$E965356A,$BFBEC274
	dc.l	$3FFF0000,$A9A15AB4,$EA7C0EF8,$3FBEA83C
	dc.l	$3FFF0000,$AB7A39B5,$A93ED337,$3FBECB00
	dc.l	$3FFF0000,$AD583EEA,$42A14AC6,$3FBE9301
	dc.l	$3FFF0000,$AF3B78AD,$690A4375,$BFBD8367
	dc.l	$3FFF0000,$B123F581,$D2AC2590,$BFBEF05F
	dc.l	$3FFF0000,$B311C412,$A9112489,$3FBDFB3C
	dc.l	$3FFF0000,$B504F333,$F9DE6484,$3FBEB2FB
	dc.l	$3FFF0000,$B6FD91E3,$28D17791,$3FBAE2CB
	dc.l	$3FFF0000,$B8FBAF47,$62FB9EE9,$3FBCDC3C
	dc.l	$3FFF0000,$BAFF5AB2,$133E45FB,$3FBEE9AA
	dc.l	$3FFF0000,$BD08A39F,$580C36BF,$BFBEAEFD
	dc.l	$3FFF0000,$BF1799B6,$7A731083,$BFBCBF51
	dc.l	$3FFF0000,$C12C4CCA,$66709456,$3FBEF88A
	dc.l	$3FFF0000,$C346CCDA,$24976407,$3FBD83B2
	dc.l	$3FFF0000,$C5672A11,$5506DADD,$3FBDF8AB
	dc.l	$3FFF0000,$C78D74C8,$ABB9B15D,$BFBDFB17
	dc.l	$3FFF0000,$C9B9BD86,$6E2F27A3,$BFBEFE3C
	dc.l	$3FFF0000,$CBEC14FE,$F2727C5D,$BFBBB6F8
	dc.l	$3FFF0000,$CE248C15,$1F8480E4,$BFBCEE53
	dc.l	$3FFF0000,$D06333DA,$EF2B2595,$BFBDA4AE
	dc.l	$3FFF0000,$D2A81D91,$F12AE45A,$3FBC9124
	dc.l	$3FFF0000,$D4F35AAB,$CFEDFA1F,$3FBEB243
	dc.l	$3FFF0000,$D744FCCA,$D69D6AF4,$3FBDE69A
	dc.l	$3FFF0000,$D99D15C2,$78AFD7B6,$BFB8BC61
	dc.l	$3FFF0000,$DBFBB797,$DAF23755,$3FBDF610
	dc.l	$3FFF0000,$DE60F482,$5E0E9124,$BFBD8BE1
	dc.l	$3FFF0000,$E0CCDEEC,$2A94E111,$3FBACB12
	dc.l	$3FFF0000,$E33F8972,$BE8A5A51,$3FBB9BFE
	dc.l	$3FFF0000,$E5B906E7,$7C8348A8,$3FBCF2F4
	dc.l	$3FFF0000,$E8396A50,$3C4BDC68,$3FBEF22F
	dc.l	$3FFF0000,$EAC0C6E7,$DD24392F,$BFBDBF4A
	dc.l	$3FFF0000,$ED4F301E,$D9942B84,$3FBEC01A
	dc.l	$3FFF0000,$EFE4B99B,$DCDAF5CB,$3FBE8CAC
	dc.l	$3FFF0000,$F281773C,$59FFB13A,$BFBCBB3F
	dc.l	$3FFF0000,$F5257D15,$2486CC2C,$3FBEF73A
	dc.l	$3FFF0000,$F7D0DF73,$0AD13BB9,$BFB8B795
	dc.l	$3FFF0000,$FA83B2DB,$722A033A,$3FBEF84B
	dc.l	$3FFF0000,$FD3E0C0C,$F486C175,$BFBEF581

*INT	equ	EXC_LV+L_SCR1

*X	equ	EXC_LV+FP_SCR0
*XDCARE	equ	X+2
*XFRAC	equ	X+4

ADJFACT	equ	EXC_LV+FP_SCR0

FACT1	equ	EXC_LV+FP_SCR0
FACT1HI	equ	FACT1+4
FACT1LOW	equ	FACT1+8

FACT2	equ	EXC_LV+FP_SCR1
FACT2HI	equ	FACT2+4
FACT2LOW	equ	FACT2+8

	xdef	stwotox
*--ENTRY POINT FOR 2**(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S
stwotox:
	fmovem.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	fmove.x	fp0,X(a6)
	and.l	#$7FFFFFFF,d1

	ICMP.l	d1,#$3FB98000	* |X| >= 2**(-70)?
	bge.b	TWOOK1
	bra.w	EXPBORS

TWOOK1:
	ICMP.l	d1,#$400D80C0	* |X| > 16480?
	ble.b	TWOMAIN
	bra.w	EXPBORS

TWOMAIN:
*--USUAL CASE, 2^(-70) <= |X| <= 16480

	fmove.x	fp0,fp1
	fmul.s	#$42800000,fp1	* 64 * X
	fmove.l	fp1,INT(a6)	* N = ROUND-TO-INT(64 X)
	move.l	d2,-(sp)
	lea	TEXPTBL(pc),a1	* LOAD ADDRESS OF TABLE OF 2^(J/64)
	fmove.l	INT(a6),fp1	* N --> FLOATING FMT
	move.l	INT(a6),d1
	move.l	d1,d2
	and.l	#$3F,d1	* D0 IS J
	asl.l	#4,d1	* DISPLACEMENT FOR 2^(J/64)
	add.l	d1,a1	* ADDRESS FOR 2^(J/64)
	asr.l	#6,d2	* d2 IS L, N = 64L + J
	move.l	d2,d1
	asr.l	#1,d1	* D0 IS M
	sub.l	d1,d2	* d2 IS M', N = 64(M+M') + J
	add.l	#$3FFF,d2

*--SUMMARY: a1 IS ADDRESS FOR THE LEADING PORTION OF 2^(J/64),
*--D0 IS M WHERE N = 64(M+M') + J. NOTE THAT |M| <= 16140 BY DESIGN.
*--ADJFACT = 2^(M').
*--REGISTERS SAVED SO FAR ARE (IN ORDER) FPCR, D0, FP1, a1, AND FP2.

	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmul.s	#$3C800000,fp1	* (1/64)*N
	move.l	(a1)+,FACT1(a6)
	move.l	(a1)+,FACT1HI(a6)
	move.l	(a1)+,FACT1LOW(a6)
	move.w	(a1)+,FACT2(a6)

	fsub.x	fp1,fp0	* X - (1/64)*INT(64 X)

	move.w	(a1)+,FACT2HI(a6)
	clr.w	FACT2HI+2(a6)
	clr.l	FACT2LOW(a6)
	add.w	d1,FACT1(a6)
	fmul.x	LOG2(pc),fp0	* FP0 IS R
	add.w	d1,FACT2(a6)

	bra.w	expr

EXPBORS:
*--FPCR, D0 SAVED
	ICMP.l	d1,#$3FFF8000
	bgt.b	TEXPBIG

*--|X| IS SMALL, RETURN 1 + X

	fmove.l	d0,fpcr	* restore users round prec,mode
	fadd.s	#$3F800000,fp0	* RETURN 1 + X
	bra	t_pinx2

TEXPBIG:
*--|X| IS LARGE, GENERATE OVERFLOW IF X > 0; ELSE GENERATE UNDERFLOW
*--REGISTERS SAVE SO FAR ARE FPCR AND  D0
	move.l	X(a6),d1
	ICMP.l	d1,#0
	blt.b	EXPNEG

	bra	t_ovfl2	* t_ovfl expects positive value

EXPNEG:
	bra	t_unfl2	* t_unfl expects positive value

	xdef	stwotoxd
stwotoxd:
*--ENTRY POINT FOR 2**(X) FOR DENORMALIZED ARGUMENT

	fmove.l	d0,fpcr	* set user's rounding mode/precision
	fmove.s	#$3F800000,fp0	* RETURN 1 + X
	move.l	(a0),d1
	or.l	#$00800001,d1
	fadd.s	d1,fp0
	bra	t_pinx2

	xdef	stentox
*--ENTRY POINT FOR 10**(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S
stentox:
	fmovem.x	(a0),fp0	* LOAD INPUT

	move.l	(a0),d1
	move.w	4(a0),d1
	fmove.x	fp0,X(a6)
	and.l	#$7FFFFFFF,d1

	ICMP.l	d1,#$3FB98000	* |X| >= 2**(-70)?
	bge.b	TENOK1
	bra.w	EXPBORS

TENOK1:
	ICMP.l	d1,#$400B9B07	* |X| <= 16480*log2/log10 ?
	ble.b	TENMAIN
	bra.w	EXPBORS

TENMAIN:
*--USUAL CASE, 2^(-70) <= |X| <= 16480 LOG 2 / LOG 10

	fmove.x	fp0,fp1
	fmul.d	L2TEN64(pc),fp1	* X*64*LOG10/LOG2
	fmove.l	fp1,INT(a6)	* N=INT(X*64*LOG10/LOG2)
	move.l	d2,-(sp)
	lea	TEXPTBL(pc),a1	* LOAD ADDRESS OF TABLE OF 2^(J/64)
	fmove.l	INT(a6),fp1	* N --> FLOATING FMT
	move.l	INT(a6),d1
	move.l	d1,d2
	and.l	#$3F,d1	* D0 IS J
	asl.l	#4,d1	* DISPLACEMENT FOR 2^(J/64)
	add.l	d1,a1	* ADDRESS FOR 2^(J/64)
	asr.l	#6,d2	* d2 IS L, N = 64L + J
	move.l	d2,d1
	asr.l	#1,d1	* D0 IS M
	sub.l	d1,d2	* d2 IS M', N = 64(M+M') + J
	add.l	#$3FFF,d2

*--SUMMARY: a1 IS ADDRESS FOR THE LEADING PORTION OF 2^(J/64),
*--D0 IS M WHERE N = 64(M+M') + J. NOTE THAT |M| <= 16140 BY DESIGN.
*--ADJFACT = 2^(M').
*--REGISTERS SAVED SO FAR ARE (IN ORDER) FPCR, D0, FP1, a1, AND FP2.
	fmovem.x	fp2-fp3,-(sp)	* save fp2/fp3

	fmove.x	fp1,fp2

	fmul.d	L10TWO1(pc),fp1	* N*(LOG2/64LOG10)_LEAD
	move.l	(a1)+,FACT1(a6)

	fmul.x	L10TWO2(pc),fp2	* N*(LOG2/64LOG10)_TRAIL

	move.l	(a1)+,FACT1HI(a6)
	move.l	(a1)+,FACT1LOW(a6)
	fsub.x	fp1,fp0	* X - N L_LEAD
	move.w	(a1)+,FACT2(a6)

	fsub.x	fp2,fp0	* X - N L_TRAIL

	move.w	(a1)+,FACT2HI(a6)
	clr.w	FACT2HI+2(a6)
	clr.l	FACT2LOW(a6)

	fmul.x	LOG10(pc),fp0	* FP0 IS R
	add.w	d1,FACT1(a6)
	add.w	d1,FACT2(a6)

expr:
*--FPCR, FP2, FP3 ARE SAVED IN ORDER AS SHOWN.
*--ADJFACT CONTAINS 2**(M'), FACT1 + FACT2 = 2**(M) * 2**(J/64).
*--FP0 IS R. THE FOLLOWING CODE COMPUTES
*--	2**(M'+M) * 2**(J/64) * EXP(R)

	fmove.x	fp0,fp1
	fmul.x	fp1,fp1	* FP1 IS S = R*R

	fmove.d	EXPA5(pc),fp2	* FP2 IS A5
	fmove.d	EXPA4(pc),fp3	* FP3 IS A4

	fmul.x	fp1,fp2	* FP2 IS S*A5
	fmul.x	fp1,fp3	* FP3 IS S*A4

	fadd.d	EXPA3(pc),fp2	* FP2 IS A3+S*A5
	fadd.d	EXPA2(pc),fp3	* FP3 IS A2+S*A4

	fmul.x	fp1,fp2	* FP2 IS S*(A3+S*A5)
	fmul.x	fp1,fp3	* FP3 IS S*(A2+S*A4)

	fadd.d	EXPA1(pc),fp2	* FP2 IS A1+S*(A3+S*A5)
	fmul.x	fp0,fp3	* FP3 IS R*S*(A2+S*A4)

	fmul.x	fp1,fp2	* FP2 IS S*(A1+S*(A3+S*A5))
	fadd.x	fp3,fp0	* FP0 IS R+R*S*(A2+S*A4)
	fadd.x	fp2,fp0	* FP0 IS EXP(R) - 1

	fmovem.x	(sp)+,fp2-fp3	* restore fp2/fp3

*--FINAL RECONSTRUCTION PROCESS
*--EXP(X) = 2^M*2^(J/64) + 2^M*2^(J/64)*(EXP(R)-1)  -  (1 OR 0)

	fmul.x	FACT1(a6),fp0
	fadd.x	FACT2(a6),fp0
	fadd.x	FACT1(a6),fp0

	fmove.l	d0,fpcr	* restore users round prec,mode
	move.w	d2,ADJFACT(a6)	* INSERT EXPONENT
	move.l	(sp)+,d2
	move.l	#$80000000,ADJFACT+4(a6)
	clr.l	ADJFACT+8(a6)
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	ADJFACT(a6),fp0	* FINAL ADJUSTMENT
	bra	t_catch

	xdef	stentoxd
stentoxd:
*--ENTRY POINT FOR 10**(X) FOR DENORMALIZED ARGUMENT

	fmove.l	d0,fpcr	* set user's rounding mode/precision
	fmove.s	#$3F800000,fp0	* RETURN 1 + X
	move.l	(a0),d1
	or.l	#$00800001,d1
	fadd.s	d1,fp0
	bra	t_pinx2

**-------------------------------------------------------------------------------------------------
* smovcr(): returns the ROM constant at the offset specified in d1
*	    rounded to the mode and precision specified in d0. 
*		
* INPUT	***************************************************************
* 	d0 = rnd prec,mode	
*	d1 = ROM offset	
*		
* OUTPUT **************************************************************
*	fp0 = the ROM constant rounded to the user's rounding mode,prec
*		
**-------------------------------------------------------------------------------------------------

	xdef	smovcr
smovcr:
	move.l	d1,-(sp)	* save rom offset for a sec

	lsr.b	#$4,d0	* shift ctrl bits to lo
	move.l	d0,d1	* make a copy 
	andi.w	#$3,d1	* extract rnd mode
	andi.w	#$c,d0	* extract rnd prec
	swap	d0	* put rnd prec in hi
	move.w	d1,d0	* put rnd mode in lo

	move.l	(sp)+,d1	* get rom offset

*
* check range of offset
*
	tst.b	d1	* if zero, offset is to pi
	beq.b	pi_tbl	* it is pi
	ICMP.b	d1,#$0a	* check range $01 - $0a
	ble.b	z_val	* if in this range, return zero
	ICMP.b	d1,#$0e	* check range $0b - $0e
	ble.b	sm_tbl	* valid constants in this range
	ICMP.b	d1,#$2f	* check range $10 - $2f
	ble.b	z_val	* if in this range, return zero
	ICMP.b	d1,#$3f	* check range $30 - $3f
	ble.b	bg_tbl	* valid constants in this range

z_val:
	bra	ld_pzero	* return a zero

*
* the answer is PI rounded to the proper precision.
*
* fetch a pointer to the answer table relating to the proper rounding
* precision.
*
pi_tbl:
	tst.b	d0	* is rmode RN?
	bne.b	pi_not_rn	* no
pi_rn:
	lea.l	PIRN(pc),a0	* yes; load PI RN table addr
	bra.w	set_finx
pi_not_rn:
	ICMP.b	d0,#rp_mode	* is rmode RP?
	beq.b	pi_rp	* yes
pi_rzrm:
	lea.l	PIRZRM(pc),a0	* no; load PI RZ,RM table addr
	bra.b	set_finx
pi_rp:
	lea.l	PIRP(pc),a0	* load PI RP table addr
	bra.b	set_finx

*
* the answer is one of:
*	$0B	log10(2)	(inexact)
*	$0C	e	(inexact)
*	$0D	log2(e)	(inexact)
*	$0E	log10(e)	(exact)
* 
* fetch a pointer to the answer table relating to the proper rounding
* precision.
*
sm_tbl:
	subi.b	#$b,d1	* make offset in 0-4 range
	tst.b	d0	* is rmode RN?
	bne.b	sm_not_rn	* no
sm_rn:
	lea.l	SMALRN(pc),a0	* yes; load RN table addr
sm_tbl_cont:
	ICMP.b	d1,#$2	* is result log10(e)?
	ble.b	set_finx	* no; answer is inexact
	bra.b	no_finx	* yes; answer is exact
sm_not_rn:
	ICMP.b	d0,#rp_mode	* is rmode RP?
	beq.b	sm_rp	* yes
sm_rzrm:
	lea.l	SMALRZRM(pc),a0	* no; load RZ,RM table addr
	bra.b	sm_tbl_cont
sm_rp:
	lea.l	SMALRP(pc),a0	* load RP table addr
	bra.b	sm_tbl_cont

*
* the answer is one of:
*	$30	ln(2)	(inexact)
*	$31	ln(10)	(inexact)
*	$32	10^0	(exact)
*	$33	10^1	(exact)
*	$34	10^2	(exact)
*	$35	10^4	(exact)
*	$36	10^8	(exact)
*	$37	10^16	(exact)
*	$38	10^32	(inexact)
*	$39	10^64	(inexact)
*	$3A	10^128	(inexact)
*	$3B	10^256	(inexact)
*	$3C	10^512	(inexact)
*	$3D	10^1024	(inexact)
*	$3E	10^2048	(inexact)
*	$3F	10^4096	(inexact)
*
* fetch a pointer to the answer table relating to the proper rounding
* precision.
*
bg_tbl:
	subi.b	#$30,d1	* make offset in 0-f range
	tst.b	d0	* is rmode RN?
	bne.b	bg_not_rn	* no
bg_rn:
	lea.l	BIGRN(pc),a0	* yes; load RN table addr
bg_tbl_cont:
	ICMP.b	d1,#$1	* is offset <= $31?
	ble.b	set_finx	* yes; answer is inexact
	ICMP.b	d1,#$7	* is $32 <= offset <= $37?
	ble.b	no_finx	* yes; answer is exact
	bra.b	set_finx	* no; answer is inexact
bg_not_rn:
	ICMP.b	d0,#rp_mode	* is rmode RP?
	beq.b	bg_rp	* yes
bg_rzrm:
	lea.l	BIGRZRM(pc),a0	* no; load RZ,RM table addr
	bra.b	bg_tbl_cont
bg_rp:
	lea.l	BIGRP(pc),a0	* load RP table addr
	bra.b	bg_tbl_cont

* answer is inexact, so set INEX2 and AINEX in the user's FPSR.
set_finx:
	ori.l	#inx2a_mask,EXC_LV+USER_FPSR(a6) * set INEX2/AINEX
no_finx:
	mulu.w	#$c,d1	* offset points into tables
	swap	d0	* put rnd prec in lo word
	tst.b	d0	* is precision extended?

	bne.b	not_ext	* if xprec, do not call round

* Precision is extended
	fmovem.x	(a0,d1.w),fp0	* return result in fp0
	rts

* Precision is single or double
not_ext:
	swap	d0	* rnd prec in upper word

* call round() to round the answer to the proper precision.
* exponents out of range for single or double DO NOT cause underflow 
* or overflow.
	move.w	$0(a0,d1.w),EXC_LV+FP_SCR1_EX(a6) * load first word
	move.l	$4(a0,d1.w),EXC_LV+FP_SCR1_HI(a6) * load second word
	move.l	$8(a0,d1.w),EXC_LV+FP_SCR1_LO(a6) * load third word
	move.l	d0,d1
	clr.l	d0	* clear g,r,s
	lea	EXC_LV+FP_SCR1(a6),a0	* pass ptr to answer
	clr.w	LOCAL_SGN(a0)	* sign always positive
	bsr	_round	* round the mantissa

	fmovem.x	(a0),fp0	* return rounded result in fp0
	rts

	cnop	0,$4

PIRN:	dc.l	$40000000,$c90fdaa2,$2168c235	* pi
PIRZRM:	dc.l	$40000000,$c90fdaa2,$2168c234	* pi
PIRP:	dc.l	$40000000,$c90fdaa2,$2168c235	* pi

SMALRN:	dc.l	$3ffd0000,$9a209a84,$fbcff798	* log10(2)
	dc.l	$40000000,$adf85458,$a2bb4a9a	* e
	dc.l	$3fff0000,$b8aa3b29,$5c17f0bc	* log2(e)
	dc.l	$3ffd0000,$de5bd8a9,$37287195	* log10(e)
	dc.l	$00000000,$00000000,$00000000	* 0.0

SMALRZRM:
	dc.l	$3ffd0000,$9a209a84,$fbcff798	* log10(2)
	dc.l	$40000000,$adf85458,$a2bb4a9a	* e
	dc.l	$3fff0000,$b8aa3b29,$5c17f0bb	* log2(e)
	dc.l	$3ffd0000,$de5bd8a9,$37287195	* log10(e)
	dc.l	$00000000,$00000000,$00000000	* 0.0

SMALRP:	dc.l	$3ffd0000,$9a209a84,$fbcff799	* log10(2)
	dc.l	$40000000,$adf85458,$a2bb4a9b	* e
	dc.l	$3fff0000,$b8aa3b29,$5c17f0bc	* log2(e)
	dc.l	$3ffd0000,$de5bd8a9,$37287195	* log10(e)
	dc.l	$00000000,$00000000,$00000000	* 0.0

BIGRN:	dc.l	$3ffe0000,$b17217f7,$d1cf79ac	* ln(2)
	dc.l	$40000000,$935d8ddd,$aaa8ac17	* ln(10)

	dc.l	$3fff0000,$80000000,$00000000	* 10 ^ 0
	dc.l	$40020000,$A0000000,$00000000	* 10 ^ 1
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

BIGRZRM:
	dc.l	$3ffe0000,$b17217f7,$d1cf79ab	* ln(2)
	dc.l	$40000000,$935d8ddd,$aaa8ac16	* ln(10)

	dc.l	$3fff0000,$80000000,$00000000	* 10 ^ 0
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

BIGRP:
	dc.l	$3ffe0000,$b17217f7,$d1cf79ac	* ln(2)
	dc.l	$40000000,$935d8ddd,$aaa8ac17	* ln(10)

	dc.l	$3fff0000,$80000000,$00000000	* 10 ^ 0
	dc.l	$40020000,$A0000000,$00000000	* 10 ^ 1
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

**-------------------------------------------------------------------------------------------------
* sscale(): computes the destination operand scaled by the source
*	    operand. If the absoulute value of the source operand is 
*	    >= 2^14, an overflow or underflow is returned.
*		
* INPUT *************************************************************** *
*	a0  = pointer to double-extended source operand X
*	a1  = pointer to double-extended destination operand Y
*		
* OUTPUT ************************************************************** *
*	fp0 =  scale(X,Y)	
*		
**-------------------------------------------------------------------------------------------------

SIGN	equ	EXC_LV+L_SCR1

	xdef	sscale
sscale:
	move.l	d0,-(sp)	* store off ctrl bits for now

	move.w	DST_EX(a1),d1	* get dst exponent
	smi.b	SIGN(a6)	* use SIGN to hold dst sign
	andi.l	#$00007fff,d1	* strip sign from dst exp

	move.w	SRC_EX(a0),d0	* check src bounds
	andi.w	#$7fff,d0	* clr src sign bit
	ICMP.w	d0,#$3fff	* is src ~ ZERO?
	blt.w	src_small	* yes
	ICMP.w	d0,#$400c	* no; is src too big?
	bgt.w	src_out	* yes

*
* Source is within 2^14 range.
*
src_ok:
	fintrz.x	SRC(a0),fp0	* calc int of src
	fmove.l	fp0,d0	* int src to d0
* don't want any accrued bits from the fintrz showing up later since
* we may need to read the fpsr for the last fp op in t_catch2().
	fmove.l	#$0,fpsr

	tst.b	DST_HI(a1)	* is dst denormalized?
	bmi.b	sok_norm

* the dst is a DENORM. normalize the DENORM and add the adjustment to
* the src value. then, jump to the norm part of the routine.
sok_dnrm:
	move.l	d0,-(sp)	* save src for now

	move.w	DST_EX(a1),EXC_LV+FP_SCR0_EX(a6) * make a copy
	move.l	DST_HI(a1),EXC_LV+FP_SCR0_HI(a6)
	move.l	DST_LO(a1),EXC_LV+FP_SCR0_LO(a6)

	lea	EXC_LV+FP_SCR0(a6),a0	* pass ptr to DENORM
	bsr	norm	* normalize the DENORM
	neg.l	d0
	add.l	(sp)+,d0	* add adjustment to src

	fmovem.x	EXC_LV+FP_SCR0(a6),fp0	* load normalized DENORM

	ICMP.w	d0,#-$3fff	* is the shft amt really low?
	bge.b	sok_norm2	* thank goodness no

* the multiply factor that we're trying to create should be a denorm
* for the multiply to work. therefore, we're going to actually do a 
* multiply with a denorm which will cause an unimplemented data type
* exception to be put into the machine which will be caught and corrected
* later. we don't do this with the DENORMs above because this method
* is slower. but, don't fret, I don't see it being used much either.
	fmove.l	(sp)+,fpcr	* restore user fpcr
	move.l	#$80000000,d1	* load normalized mantissa
	subi.l	#-$3fff,d0	* how many should we shift?
	neg.l	d0	* make it positive
	ICMP.b	d0,#$20	* is it > 32?
	bge.b	sok_dnrm_32	* yes
	lsr.l	d0,d1	* no; bit stays in upper lw
	clr.l	-(sp)	* insert zero low mantissa
	move.l	d1,-(sp)	* insert new high mantissa
	clr.l	-(sp)	* make zero exponent
	bra.b	sok_norm_cont	
sok_dnrm_32:
	subi.b	#$20,d0	* get shift count
	lsr.l	d0,d1	* make low mantissa longword
	move.l	d1,-(sp)	* insert new low mantissa
	clr.l	-(sp)	* insert zero high mantissa
	clr.l	-(sp)	* make zero exponent
	bra.b	sok_norm_cont
	
* the src will force the dst to a DENORM value or worse. so, let's
* create an fp multiply that will create the result.
sok_norm:
	fmovem.x	DST(a1),fp0	* load fp0 with normalized src
sok_norm2:
	fmove.l	(sp)+,fpcr	* restore user fpcr

	addi.w	#$3fff,d0	* turn src amt into exp value
	swap	d0	* put exponent in high word
	clr.l	-(sp)	* insert new exponent
	move.l	#$80000000,-(sp)	* insert new high mantissa
	move.l	d0,-(sp)	* insert new lo mantissa

sok_norm_cont:
	fmove.l	fpcr,d0	* d0 needs fpcr for t_catch2
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	(sp)+,fp0	* do the multiply
	bra	t_catch2	* catch any exceptions

*
* Source is outside of 2^14 range.  Test the sign and branch
* to the appropriate exception handler.
*
src_out:
	move.l	(sp)+,d0	* restore ctrl bits
	exg	a0,a1	* swap src,dst ptrs
	tst.b	SRC_EX(a1)	* is src negative?
	bmi	t_unfl	* yes; underflow
	bra	t_ovfl_sc	* no; overflow

*
* The source input is below 1, so we check for denormalized numbers
* and set unfl.
*
src_small:
	tst.b	DST_HI(a1)	* is dst denormalized?
	bpl.b	ssmall_done	* yes

	move.l	(sp)+,d0
	fmove.l	d0,fpcr	* no; load control bits
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	DST(a1),fp0	* simply return dest
	bra	t_catch2
ssmall_done:
	move.l	(sp)+,d0	* load control bits into d1
	move.l	a1,a0	* pass ptr to dst
	bra	t_resdnrm

**-------------------------------------------------------------------------------------------------
* smod(): computes the fp MOD of the input values X,Y.
* srem(): computes the fp (IEEE) REM of the input values X,Y.
*		
* INPUT *************************************************************** *
*	a0 = pointer to extended precision input X
*	a1 = pointer to extended precision input Y
*	d0 = round precision,mode	
*		
* 	The input operands X and Y can be either normalized or 
*	denormalized.	
*		
* OUTPUT ************************************************************** *
*      fp0 = FREM(X,Y) or FMOD(X,Y)	
*		
* ALGORITHM *********************************************************** *
*		
*       Step 1.  Save and strip signs of X and Y: signX := sign(X),
*                signY := sign(Y), X := |X|, Y := |Y|, 
*                signQ := signX EOR signY. Record whether MOD or REM
*                is requested.	
*		
*       Step 2.  Set L := expo(X)-expo(Y), k := 0, Q := 0.
*                If (L < 0) then	
*                   R := X, go to Step 4.
*                else	
*                   R := 2^(-L)X, j := L.
*                endif	
*		
*       Step 3.  Perform MOD(X,Y)	
*            3.1 If R = Y, go to Step 9.
*            3.2 If R > Y, then { R := R - Y, Q := Q + 1}
*            3.3 If j = 0, go to Step 4.
*            3.4 k := k + 1, j := j - 1, Q := 2Q, R := 2R. Go to
*                Step 3.1.	
*		
*       Step 4.  At this point, R = X - QY = MOD(X,Y). Set
*                Last_Subtract := false (used in Step 7 below). If
*                MOD is requested, go to Step 6. 
*		
*       Step 5.  R = MOD(X,Y), but REM(X,Y) is requested.
*            5.1 If R < Y/2, then R = MOD(X,Y) = REM(X,Y). Go to
*                Step 6.	
*            5.2 If R > Y/2, then { set Last_Subtract := true,
*                Q := Q + 1, Y := signY*Y }. Go to Step 6.
*            5.3 This is the tricky case of R = Y/2. If Q is odd,
*                then { Q := Q + 1, signX := -signX }.
*		
*       Step 6.  R := signX*R.	
*		
*       Step 7.  If Last_Subtract = true, R := R - Y.
*		
*       Step 8.  Return signQ, last 7 bits of Q, and R as required.
*		
*       Step 9.  At this point, R = 2^(-j)*X - Q Y = Y. Thus,
*                X = 2^(j)*(Q+1)Y. set Q := 2^(j)*(Q+1),
*                R := 0. Return signQ, last 7 bits of Q, and R.
*		
**-------------------------------------------------------------------------------------------------

Mod_Flag	equ	EXC_LV+L_SCR3
Sc_Flag	equ	EXC_LV+L_SCR3+1

SignY	equ	EXC_LV+L_SCR2
SignX	equ	EXC_LV+L_SCR2+2
SignQ	equ	EXC_LV+L_SCR3+2

Y	equ	EXC_LV+FP_SCR0
Y_Hi	equ	Y+4
Y_Lo	equ	Y+8

R	equ	EXC_LV+FP_SCR1
R_Hi	equ	R+4
R_Lo	equ	R+8

Scale:
	dc.l	$00010000,$80000000,$00000000,$00000000

	xdef	smod
smod:
	clr.b	EXC_LV+FPSR_QBYTE(a6)
	move.l	d0,-(sp)	* save ctrl bits
	clr.b	Mod_Flag(a6)
	bra.b	Mod_Rem

	xdef	srem
srem:
	clr.b	EXC_LV+FPSR_QBYTE(a6)
	move.l	d0,-(sp)	* save ctrl bits
	move.b	#$1,Mod_Flag(a6)

Mod_Rem:
*..Save sign of X and Y
	movem.l	d2-d7,-(sp)	* save data registers
	move.w	SRC_EX(a0),d3
	move.w	d3,SignY(a6)
	and.l	#$00007FFF,d3	* Y := |Y|

*
	move.l	SRC_HI(a0),d4
	move.l	SRC_LO(a0),d5	* (D3,D4,D5) is |Y|

	tst.l	d3
	bne.b	Y_Normal

	move.l	#$00003FFE,d3	* $3FFD + 1
	tst.l	d4
	bne.b	HiY_not0

HiY_0:
	move.l	d5,d4
	clr.l	d5
	sub.l	#32,d3
	clr.l	d6
	bfffo	d4{0:32},d6
	lsl.l	d6,d4
	sub.l	d6,d3	* (D3,D4,D5) is normalized
*	                                        ...with bias $7FFD
	bra.b	Chk_X

HiY_not0:
	clr.l	d6
	bfffo	d4{0:32},d6
	sub.l	d6,d3
	lsl.l	d6,d4
	move.l	d5,d7	* a copy of D5
	lsl.l	d6,d5
	neg.l	d6
	add.l	#32,d6
	lsr.l	d6,d7
	or.l	d7,d4	* (D3,D4,D5) normalized
*                                       ...with bias $7FFD
	bra.b	Chk_X

Y_Normal:
	add.l	#$00003FFE,d3	* (D3,D4,D5) normalized
*                                       ...with bias $7FFD

Chk_X:
	move.w	DST_EX(a1),d0
	move.w	d0,SignX(a6)
	move.w	SignY(a6),d1
	eor.l	d0,d1
	and.l	#$00008000,d1
	move.w	d1,SignQ(a6)	* sign(Q) obtained
	and.l	#$00007FFF,d0
	move.l	DST_HI(a1),d1
	move.l	DST_LO(a1),d2	* (D0,D1,D2) is |X|
	tst.l	d0
	bne.b	X_Normal
	move.l	#$00003FFE,d0
	tst.l	d1
	bne.b	HiX_not0

HiX_0:
	move.l	d2,d1
	clr.l	d2
	sub.l	#32,d0
	clr.l	d6
	bfffo	d1{0:32},d6
	lsl.l	d6,d1
	sub.l	d6,d0	* (D0,D1,D2) is normalized
*                                       ...with bias $7FFD
	bra.b	Init

HiX_not0:
	clr.l	d6
	bfffo	d1{0:32},d6
	sub.l	d6,d0
	lsl.l	d6,d1
	move.l	d2,d7	* a copy of D2
	lsl.l	d6,d2
	neg.l	d6
	add.l	#32,d6
	lsr.l	d6,d7
	or.l	d7,d1	* (D0,D1,D2) normalized
*                                       ...with bias $7FFD
	bra.b	Init

X_Normal:
	add.l	#$00003FFE,d0	* (D0,D1,D2) normalized
*                                       ...with bias $7FFD

Init:
*
	move.l	d3,EXC_LV+L_SCR1(a6)	* save biased exp(Y)
	move.l	d0,-(sp)	* save biased exp(X)
	sub.l	d3,d0	* L := expo(X)-expo(Y)

	clr.l	d6	* D6 := carry <- 0
	clr.l	d3	* D3 is Q
	move.l	#0,a1	* A1 is k; j+k=L, Q=0

*..(Carry,D1,D2) is R
	tst.l	d0
	bge.b	Mod_Loop_pre

*..expo(X) < expo(Y). Thus X = mod(X,Y)
*
	move.l	(sp)+,d0	* restore d0
	bra.w	Get_Mod

Mod_Loop_pre:
	addq.l	#$4,sp	* erase exp(X)
*..At this point  R = 2^(-L)X; Q = 0; k = 0; and  k+j = L
Mod_Loop:
	tst.l	d6	* test carry bit
	bgt.b	R_GT_Y

*..At this point carry = 0, R = (D1,D2), Y = (D4,D5)
	ICMP.l	d1,d4	* compare hi(R) and hi(Y)
	bne.b	R_NE_Y
	ICMP.l	d2,d5	* compare lo(R) and lo(Y)
	bne.b	R_NE_Y

*..At this point, R = Y
	bra.w	Rem_is_0

R_NE_Y:
*..use the borrow of the previous compare
	bcs.b	R_LT_Y	* borrow is set iff R < Y

R_GT_Y:
*..If Carry is set, then Y < (Carry,D1,D2) < 2Y. Otherwise, Carry = 0
*..and Y < (D1,D2) < 2Y. Either way, perform R - Y
	sub.l	d5,d2	* lo(R) - lo(Y)
	subx.l	d4,d1	* hi(R) - hi(Y)
	clr.l	d6	* clear carry
	addq.l	#1,d3	* Q := Q + 1

R_LT_Y:
*..At this point, Carry=0, R < Y. R = 2^(k-L)X - QY; k+j = L; j >= 0.
	tst.l	d0	* see if j = 0.
	beq.b	PostLoop

	add.l	d3,d3	* Q := 2Q
	add.l	d2,d2	* lo(R) = 2lo(R)
	roxl.l	#1,d1	* hi(R) = 2hi(R) + carry
	scs	d6	* set Carry if 2(R) overflows
	addq.l	#1,a1	* k := k+1
	subq.l	#1,d0	* j := j - 1
*..At this point, R=(Carry,D1,D2) = 2^(k-L)X - QY, j+k=L, j >= 0, R < 2Y.

	bra.b	Mod_Loop

PostLoop:
*..k = L, j = 0, Carry = 0, R = (D1,D2) = X - QY, R < Y.

*..normalize R.
	move.l	EXC_LV+L_SCR1(a6),d0	* new biased expo of R
	tst.l	d1
	bne.b	HiR_not0

HiR_0:
	move.l	d2,d1
	clr.l	d2
	sub.l	#32,d0
	clr.l	d6
	bfffo	d1{0:32},d6
	lsl.l	d6,d1
	sub.l	d6,d0	* (D0,D1,D2) is normalized
*                                       ...with bias $7FFD
	bra.b	Get_Mod

HiR_not0:
	clr.l	d6
	bfffo	d1{0:32},d6
	bmi.b	Get_Mod	* already normalized
	sub.l	d6,d0
	lsl.l	d6,d1
	move.l	d2,d7	* a copy of D2
	lsl.l	d6,d2
	neg.l	d6
	add.l	#32,d6
	lsr.l	d6,d7
	or.l	d7,d1	* (D0,D1,D2) normalized

*
Get_Mod:
	ICMP.l	d0,#$000041FE
	bge.b	No_Scale
Do_Scale:
	move.w	d0,R(a6)
	move.l	d1,R_Hi(a6)
	move.l	d2,R_Lo(a6)
	move.l	EXC_LV+L_SCR1(a6),d6
	move.w	d6,Y(a6)
	move.l	d4,Y_Hi(a6)
	move.l	d5,Y_Lo(a6)
	fmove.x	R(a6),fp0	* no exception
	move.b	#1,Sc_Flag(a6)
	bra.b	ModOrRem
No_Scale:
	move.l	d1,R_Hi(a6)
	move.l	d2,R_Lo(a6)
	sub.l	#$3FFE,d0
	move.w	d0,R(a6)
	move.l	EXC_LV+L_SCR1(a6),d6
	sub.l	#$3FFE,d6
	move.l	d6,EXC_LV+L_SCR1(a6)
	fmove.x	R(a6),fp0
	move.w	d6,Y(a6)
	move.l	d4,Y_Hi(a6)
	move.l	d5,Y_Lo(a6)
	clr.b	Sc_Flag(a6)

*
ModOrRem:
	tst.b	Mod_Flag(a6)
	beq.b	Fix_Sign

	move.l	EXC_LV+L_SCR1(a6),d6	* new biased expo(Y)
	subq.l	#1,d6	* biased expo(Y/2)
	ICMP.l	d0,d6
	blt.b	Fix_Sign
	bgt.b	Last_Sub

	ICMP.l	d1,d4
	bne.b	Not_EQ
	ICMP.l	d2,d5
	bne.b	Not_EQ
	bra.w	Tie_Case

Not_EQ:
	bcs.b	Fix_Sign

Last_Sub:
*
	fsub.x	Y(a6),fp0	* no exceptions
	addq.l	#1,d3	* Q := Q + 1

*
Fix_Sign:
*..Get sign of X
	move.w	SignX(a6),d6
	bge.b	Get_Q
	fneg.x	fp0

*..Get Q
*
Get_Q:
	clr.l	d6
	move.w	SignQ(a6),d6	* D6 is sign(Q)
	move.l	#8,d7
	lsr.l	d7,d6
	and.l	#$0000007F,d3	* 7 bits of Q
	or.l	d6,d3	* sign and bits of Q
*	swap	d3
*	fmove.l	fpsr,d6
*	and.l	#$FF00FFFF,d6
*	or.l	d3,d6
*	fmove.l	d6,fpsr	* put Q in fpsr
	move.b	d3,EXC_LV+FPSR_QBYTE(a6)	* put Q in fpsr

*
Restore:
	movem.l	(sp)+,d2-d7	*  {d2-d7}
	move.l	(sp)+,d0
	fmove.l	d0,fpcr
	tst.b	Sc_Flag(a6)
	beq.b	Finish
	move.b	#FMUL_OP,d1	* last inst is MUL
	fmul.x	Scale(pc),fp0	* may cause underflow
	bra	t_catch2
* the '040 package did this apparently to see if the dst operand for the 
* preceding fmul was a denorm. but, it better not have been since the 
* algorithm just got done playing with fp0 and expected no exceptions
* as a result. trust me...
*	bra	t_avoid_unsupp	* check for denorm as a
*		;result of the scaling

Finish:
	move.b	#FMOV_OP,d1	* last inst is MOVE
	fmove.x	fp0,fp0	* capture exceptions # round
	bra	t_catch2

Rem_is_0:
*..R = 2^(-j)X - Q Y = Y, thus R = 0 and quotient = 2^j (Q+1)
	addq.l	#1,d3
	ICMP.l	d0,#8	* D0 is j 
	bge.b	Q_Big

	lsl.l	d0,d3
	bra.b	Set_R_0

Q_Big:
	clr.l	d3

Set_R_0:
	fmove.s	#$00000000,fp0
	clr.b	Sc_Flag(a6)
	bra.w	Fix_Sign

Tie_Case:
*..Check parity of Q
	move.l	d3,d6
	and.l	#$00000001,d6
	tst.l	d6
	beq.w	Fix_Sign	* Q is even

*..Q is odd, Q := Q + 1, signX := -signX
	addq.l	#1,d3
	move.w	SignX(a6),d6
	eor.l	#$00008000,d6
	move.w	d6,SignX(a6)
	bra.w	Fix_Sign

qnan:	dc.l	$7fff0000, $ffffffff, $ffffffff

**-------------------------------------------------------------------------------------------------
* XDEF **
*	t_dz(): Handle DZ exception during transcendental emulation.
*	        Sets N bit according to sign of source operand.
*	t_dz2(): Handle DZ exception during transcendental emulation.
*	 Sets N bit always.	
*		
* xdef **
*	None	
*		
* INPUT ***************************************************************
*	a0 = pointer to source operand	
* 		
* OUTPUT **************************************************************
*	fp0 = default result	
*		
* ALGORITHM ***********************************************************
*	- Store properly signed INF into fp0.
*	- Set FPSR exception status dz bit, ccode inf bit, and 
*	  accrued dz bit.	
*		
**-------------------------------------------------------------------------------------------------

	xdef	t_dz
t_dz:
	tst.b	SRC_EX(a0) 	* no; is src negative?
	bmi.b	t_dz2	* yes

dz_pinf:
	fmove.s	#$7f800000,fp0	* return +INF in fp0
	ori.l	#dzinf_mask,EXC_LV+USER_FPSR(a6) * set I/DZ/ADZ
	rts

	xdef	t_dz2
t_dz2:
	fmove.s	#$ff800000,fp0	* return -INF in fp0
	ori.l	#dzinf_mask+neg_mask,EXC_LV+USER_FPSR(a6) * set N/I/DZ/ADZ
	rts

***
* OPERR exception:	
*	- set FPSR exception status operr bit, condition code 
*	  nan bit; Store default NAN into fp0
***
	xdef	t_operr
t_operr:
	ori.l	#opnan_mask,EXC_LV+USER_FPSR(a6) * set NaN/OPERR/AIOP
	fmovem.x	qnan(pc),fp0	* return default NAN in fp0
	rts

***
* Extended DENORM:	
* 	- For all functions that have a denormalized input and
*	  that f(x)=x, this is the entry point.
*	- we only return the EXOP here if either underflow or
*	  inexact is enabled.	
***

* Entry point for scale w/ extended denorm. The function does
* NOT set INEX2/AUNFL/AINEX.
	xdef	t_resdnrm
t_resdnrm:
	ori.l	#unfl_mask,EXC_LV+USER_FPSR(a6) * set UNFL
	bra.b	xdnrm_con

	xdef	t_extdnrm
t_extdnrm:
	ori.l	#unfinx_mask,EXC_LV+USER_FPSR(a6) * set UNFL/INEX2/AUNFL/AINEX

xdnrm_con:
	move.l	a0,a1	* make copy of src ptr
	move.l	d0,d1	* make copy of rnd prec,mode
	andi.b	#$c0,d1	* extended precision?
	bne.b	xdnrm_sd	* no

* result precision is extended.
	tst.b	LOCAL_EX(a0)	* is denorm negative?
	bpl.b	xdnrm_exit	* no

	bset	#neg_bit,EXC_LV+FPSR_CC(a6)	* yes; set 'N' ccode bit
	bra.b	xdnrm_exit

* result precision is single or double
xdnrm_sd:
	move.l	a1,-(sp)
	tst.b	LOCAL_EX(a0)	* is denorm pos or neg?
	smi.b	d1	* set d0 accodingly
	bsr	unf_sub
	move.l	(sp)+,a1
xdnrm_exit:
	fmovem.x	(a0),fp0	* return default result in fp0

	move.b	EXC_LV+FPCR_ENABLE(a6),d0
	andi.b	#$0a,d0	* is UNFL or INEX enabled?
	bne.b	xdnrm_ena	* yes
	rts

****************
* unfl enabled *
****************
* we have a DENORM that needs to be converted into an EXOP.
* so, normalize the mantissa, add $6000 to the new exponent,
* and return the result in fp1.
xdnrm_ena:
	move.w	LOCAL_EX(a1),EXC_LV+FP_SCR0_EX(a6)
	move.l	LOCAL_HI(a1),EXC_LV+FP_SCR0_HI(a6)
	move.l	LOCAL_LO(a1),EXC_LV+FP_SCR0_LO(a6)

	lea	EXC_LV+FP_SCR0(a6),a0
	bsr	norm	* normalize mantissa
	addi.l	#$6000,d0	* add extra bias
	andi.w	#$8000,EXC_LV+FP_SCR0_EX(a6)	* keep old sign
	or.w	d0,EXC_LV+FP_SCR0_EX(a6)	* insert new exponent

	fmovem.x	EXC_LV+FP_SCR0(a6),fp1	* return EXOP in fp1
	rts

***
* UNFL exception:
* 	- This routine is for cases where even an EXOP isn't
*  	  large enough to hold the range of this result.
*	  In such a case, the EXOP equals zero.
*  	- Return the default result to the proper precision 
*	  with the sign of this result being the same as that
*	  of the src operand.	
* 	- t_unfl2() is provided to force the result sign to
*	  positive which is the desired result for fetox().
***
	xdef	t_unfl
t_unfl:
	ori.l	#unfinx_mask,EXC_LV+USER_FPSR(a6) * set UNFL/INEX2/AUNFL/AINEX

	tst.b	(a0)	* is result pos or neg?
	smi.b	d1	* set d1 accordingly
	bsr	unf_sub	* calc default unfl result
	fmovem.x	(a0),fp0	* return default result in fp0

	fmove.s	#$00000000,fp1	* return EXOP in fp1
	rts

* t_unfl2 ALWAYS tells unf_sub to create a positive result
	xdef	t_unfl2
t_unfl2:
	ori.l	#unfinx_mask,EXC_LV+USER_FPSR(a6) * set UNFL/INEX2/AUNFL/AINEX

	sf.b	d1	* set d0 to represent positive
	bsr	unf_sub	* calc default unfl result
	fmovem.x	(a0),fp0	* return default result in fp0

	fmove.s	#$0000000,fp1	* return EXOP in fp1
	rts

***
* OVFL exception:
* 	- This routine is for cases where even an EXOP isn't
*  	  large enough to hold the range of this result.
* 	- Return the default result to the proper precision
*	  with the sign of this result being the same as that
*	  of the src operand.
* 	- t_ovfl2() is provided to force the result sign to
*	  positive which is the desired result for fcosh().
* 	- t_ovfl_sc() is provided for scale() which only sets 
*	  the inexact bits if the number is inexact for the 
*	  precision indicated.	
***

	xdef	t_ovfl_sc
t_ovfl_sc:
	ori.l	#ovfl_inx_mask,EXC_LV+USER_FPSR(a6) * set OVFL/AOVFL/AINEX

	move.b	d0,d1	* fetch rnd mode/prec
	andi.b	#$c0,d1	* extract rnd prec
	beq.b	ovfl_work	* prec is extended

	tst.b	LOCAL_HI(a0)	* is dst a DENORM?
	bmi.b	ovfl_sc_norm	* no

* dst op is a DENORM. we have to normalize the mantissa to see if the
* result would be inexact for the given precision. make a copy of the
* dst so we don't screw up the version passed to us.
	move.w	LOCAL_EX(a0),EXC_LV+FP_SCR0_EX(a6)
	move.l	LOCAL_HI(a0),EXC_LV+FP_SCR0_HI(a6)
	move.l	LOCAL_LO(a0),EXC_LV+FP_SCR0_LO(a6)
	lea	EXC_LV+FP_SCR0(a6),a0	* pass ptr to EXC_LV+FP_SCR0
	movem.l	d0-d1/a0,-(sp)	* save d0-d1/a0
	bsr	norm	* normalize mantissa
	movem.l	(sp)+,d0-d1/a0	* restore d0-d1/a0

ovfl_sc_norm:
	ICMP.b	d1,#$40	* is prec dbl?
	bne.b	ovfl_sc_dbl	* no; sgl
ovfl_sc_sgl:
	tst.l	LOCAL_LO(a0)	* is lo lw of sgl set?
	bne.b	ovfl_sc_inx	* yes
	tst.b	3+LOCAL_HI(a0)	* is lo byte of hi lw set?
	bne.b	ovfl_sc_inx	* yes
	bra.b	ovfl_work	* don't set INEX2
ovfl_sc_dbl:
	move.l	LOCAL_LO(a0),d1	* are any of lo 11 bits of
	andi.l	#$7ff,d1	* dbl mantissa set?
	beq.b	ovfl_work	* no; don't set INEX2
ovfl_sc_inx:
	ori.l	#inex2_mask,EXC_LV+USER_FPSR(a6) * set INEX2
	bra.b	ovfl_work	* continue

	xdef	t_ovfl
t_ovfl:
	ori.l	#ovfinx_mask,EXC_LV+USER_FPSR(a6) * set OVFL/INEX2/AOVFL/AINEX

ovfl_work:
	tst.b	LOCAL_EX(a0)	* what is the sign?
	smi.b	d1	* set d1 accordingly
	bsr	ovf_res	* calc default ovfl result
	move.b	d0,EXC_LV+FPSR_CC(a6)	* insert new ccodes
	fmovem.x	(a0),fp0	* return default result in fp0

	fmove.s	#$00000000,fp1	* return EXOP in fp1
	rts

* t_ovfl2 ALWAYS tells ovf_res to create a positive result
	xdef	t_ovfl2
t_ovfl2:
	ori.l	#ovfinx_mask,EXC_LV+USER_FPSR(a6) * set OVFL/INEX2/AOVFL/AINEX

	sf.b	d1	* clear sign flag for positive
	bsr	ovf_res	* calc default ovfl result
	move.b	d0,EXC_LV+FPSR_CC(a6)	* insert new ccodes
	fmovem.x	(a0),fp0	* return default result in fp0

	fmove.s	#$00000000,fp1	* return EXOP in fp1
	rts

***
* t_catch(): 	
*	- the last operation of a transcendental emulation
* 	  routine may have caused an underflow or overflow. 
* 	  we find out if this occurred by doing an fsave and 
*	  checking the exception bit. if one did occur, then we
*	  jump to fgen_except() which creates the default
*	  result and EXOP for us.
***
	xdef	t_catch
t_catch:

	fsave	-(sp)
	tst.b	$2(sp)
	bmi.b	catch
	add.l	#$c,sp

***
* INEX2 exception:
*	- The inex2 and ainex bits are set.
***
	xdef	t_inx2
t_inx2:
	fblt.w	t_minx2
	fbeq.w	inx2_zero

	xdef	t_pinx2
t_pinx2:
	ori.w	#inx2a_mask,2+EXC_LV+USER_FPSR(a6) * set INEX2/AINEX
	rts

	xdef	t_minx2
t_minx2:
	ori.l	#inx2a_mask+neg_mask,EXC_LV+USER_FPSR(a6) * set N/INEX2/AINEX
	rts

inx2_zero:
	move.b	#z_bmask,EXC_LV+FPSR_CC(a6)
	ori.w	#inx2a_mask,2+EXC_LV+USER_FPSR(a6) * set INEX2/AINEX
	rts

* an underflow or overflow exception occurred.
* we must set INEX/AINEX since the fmul/fdiv/fmov emulation may not!
catch:
	ori.w	#inx2a_mask,EXC_LV+FPSR_EXCEPT(a6)
catch2:
	bsr	fgen_except
	add.l	#$c,sp
	rts

	xdef	t_catch2
t_catch2:

	fsave	-(sp)

	tst.b	$2(sp)
	bmi.b	catch2
	add.l	#$c,sp

	fmove.l	fpsr,d0
	or.l	d0,EXC_LV+USER_FPSR(a6)

	rts

**-------------------------------------------------------------------------------------------------

**-------------------------------------------------------------------------------------------------
* unf_subres(): underflow default result calculation for transcendentals
*
* INPUT:
* 	d0   : rnd mode,precision
* 	d1.b : sign bit of result ('11111111 = (-) ; '00000000 = (+))
* OUTPUT:
*	a0   : points to result (in instruction memory)
**-------------------------------------------------------------------------------------------------
unf_sub:
	ori.l	#unfinx_mask,EXC_LV+USER_FPSR(a6)

	andi.w	#$10,d1	* keep sign bit in 4th spot

	lsr.b	#$4,d0	* shift rnd prec,mode to lo bits
	andi.b	#$f,d0	* strip hi rnd mode bit
	or.b	d1,d0	* concat {sgn,mode,prec}

	move.l	d0,d1	* make a copy
	lsl.b	#$1,d1	* mult index 2 by 2

	move.b	((tbl_unf_cc).b,pc,d0.w*1),EXC_LV+FPSR_CC(a6) * insert ccode bits
	lea	((tbl_unf_result).b,pc,d1.w*8),a0 * grab result ptr
	rts

tbl_unf_cc:
	dc.b	$4, $4, $4, $0
	dc.b	$4, $4, $4, $0
	dc.b	$4, $4, $4, $0
	dc.b	$0, $0, $0, $0
	dc.b	$8+$4, $8+$4, $8, $8+$4
	dc.b	$8+$4, $8+$4, $8, $8+$4
	dc.b	$8+$4, $8+$4, $8, $8+$4

tbl_unf_result:
	dc.l	$00000000, $00000000, $00000000, $0 * ZERO;ext
	dc.l	$00000000, $00000000, $00000000, $0 * ZERO;ext
	dc.l	$00000000, $00000000, $00000000, $0 * ZERO;ext
	dc.l	$00000000, $00000000, $00000001, $0 * MIN; ext

	dc.l	$3f810000, $00000000, $00000000, $0 * ZERO;sgl
	dc.l	$3f810000, $00000000, $00000000, $0 * ZERO;sgl
	dc.l	$3f810000, $00000000, $00000000, $0 * ZERO;sgl
	dc.l	$3f810000, $00000100, $00000000, $0 * MIN; sgl

	dc.l	$3c010000, $00000000, $00000000, $0 * ZERO;dbl
	dc.l	$3c010000, $00000000, $00000000, $0 * ZER0;dbl
	dc.l	$3c010000, $00000000, $00000000, $0 * ZERO;dbl
	dc.l	$3c010000, $00000000, $00000800, $0 * MIN; dbl

	dc.l	$0,$0,$0,$0
	dc.l	$0,$0,$0,$0
	dc.l	$0,$0,$0,$0
	dc.l	$0,$0,$0,$0
	
	dc.l	$80000000, $00000000, $00000000, $0 * ZERO;ext
	dc.l	$80000000, $00000000, $00000000, $0 * ZERO;ext
	dc.l	$80000000, $00000000, $00000001, $0 * MIN; ext
	dc.l	$80000000, $00000000, $00000000, $0 * ZERO;ext

	dc.l	$bf810000, $00000000, $00000000, $0 * ZERO;sgl
	dc.l	$bf810000, $00000000, $00000000, $0 * ZERO;sgl
	dc.l	$bf810000, $00000100, $00000000, $0 * MIN; sgl
	dc.l	$bf810000, $00000000, $00000000, $0 * ZERO;sgl

	dc.l	$bc010000, $00000000, $00000000, $0 * ZERO;dbl
	dc.l	$bc010000, $00000000, $00000000, $0 * ZERO;dbl
	dc.l	$bc010000, $00000000, $00000800, $0 * MIN; dbl
	dc.l	$bc010000, $00000000, $00000000, $0 * ZERO;dbl

************************************************************

**-------------------------------------------------------------------------------------------------
* src_zero(): Return signed zero according to sign of src operand.
**-------------------------------------------------------------------------------------------------
	xdef	src_zero
src_zero:
	tst.b	SRC_EX(a0)	* get sign of src operand
	bmi.b	ld_mzero	* if neg, load neg zero

*
* ld_pzero(): return a positive zero.
*
	xdef	ld_pzero
ld_pzero:
	fmove.s	#$00000000,fp0	* load +0
	move.b	#z_bmask,EXC_LV+FPSR_CC(a6)	* set 'Z' ccode bit
	rts

* ld_mzero(): return a negative zero.
	xdef	ld_mzero
ld_mzero:
	fmove.s	#$80000000,fp0	* load -0
	move.b	#neg_bmask+z_bmask,EXC_LV+FPSR_CC(a6) * set 'N','Z' ccode bits
	rts

**-------------------------------------------------------------------------------------------------
* dst_zero(): Return signed zero according to sign of dst operand.
**-------------------------------------------------------------------------------------------------
	xdef	dst_zero
dst_zero:
	tst.b	DST_EX(a1) 	* get sign of dst operand
	bmi.b	ld_mzero	* if neg, load neg zero
	bra.b	ld_pzero	* load positive zero

**-------------------------------------------------------------------------------------------------
* src_inf(): Return signed inf according to sign of src operand.
**-------------------------------------------------------------------------------------------------
	xdef	src_inf
src_inf:
	tst.b	SRC_EX(a0) 	* get sign of src operand
	bmi.b	ld_minf	* if negative branch

*
* ld_pinf(): return a positive infinity.
*
	xdef	ld_pinf
ld_pinf:
	fmove.s	#$7f800000,fp0	* load +INF
	move.b	#inf_bmask,EXC_LV+FPSR_CC(a6)	* set 'INF' ccode bit
	rts

*
* ld_minf():return a negative infinity.
*
	xdef	ld_minf
ld_minf:
	fmove.s	#$ff800000,fp0	* load -INF
	move.b	#neg_bmask+inf_bmask,EXC_LV+FPSR_CC(a6) * set 'N','I' ccode bits
	rts

**-------------------------------------------------------------------------------------------------
* dst_inf(): Return signed inf according to sign of dst operand.
**-------------------------------------------------------------------------------------------------
	xdef	dst_inf
dst_inf:
	tst.b	DST_EX(a1) 	* get sign of dst operand
	bmi.b	ld_minf	* if negative branch
	bra.b	ld_pinf

	xdef	szr_inf
***
* szr_inf(): Return +ZERO for a negative src operand or
*	            +INF for a positive src operand.
*	     Routine used for fetox, ftwotox, and ftentox.
***
szr_inf:
	tst.b	SRC_EX(a0)	* check sign of source
	bmi.b	ld_pzero
	bra.b	ld_pinf

**-------------------------------------------------------------------------------------------------
* sopr_inf(): Return +INF for a positive src operand or
*	      jump to operand error routine for a negative src operand.
*	      Routine used for flogn, flognp1, flog10, and flog2.
**-------------------------------------------------------------------------------------------------
	xdef	sopr_inf
sopr_inf:
	tst.b	SRC_EX(a0)	* check sign of source
	bmi.w	t_operr
	bra.b	ld_pinf

***
* setoxm1i(): Return minus one for a negative src operand or
*	      positive infinity for a positive src operand.
*	      Routine used for fetoxm1.
***
	xdef	setoxm1i
setoxm1i:
	tst.b	SRC_EX(a0)	* check sign of source
	bmi.b	ld_mone
	bra.b	ld_pinf

**-------------------------------------------------------------------------------------------------
* src_one(): Return signed one according to sign of src operand.
**-------------------------------------------------------------------------------------------------
	xdef	src_one
src_one:
	tst.b	SRC_EX(a0) 	* check sign of source
	bmi.b	ld_mone

*
* ld_pone(): return positive one.
*
	xdef	ld_pone
ld_pone:
	fmove.s	#$3f800000,fp0	* load +1
	clr.b	EXC_LV+FPSR_CC(a6)
	rts

*
* ld_mone(): return negative one.
*
	xdef	ld_mone
ld_mone:
	fmove.s	#$bf800000,fp0	* load -1
	move.b	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode bit
	rts

ppiby2:	dc.l	$3fff0000, $c90fdaa2, $2168c235
mpiby2:	dc.l	$bfff0000, $c90fdaa2, $2168c235

***
* spi_2(): Return signed PI/2 according to sign of src operand.
***
	xdef	spi_2
spi_2:
	tst.b	SRC_EX(a0) 	* check sign of source
	bmi.b	ld_mpi2

*
* ld_ppi2(): return positive PI/2.
*
	xdef	ld_ppi2
ld_ppi2:
	fmove.l	d0,fpcr
	fmove.x	ppiby2(pc),fp0	* load +pi/2
	bra.w	t_pinx2	* set INEX2

*
* ld_mpi2(): return negative PI/2.
*
	xdef	ld_mpi2
ld_mpi2:
	fmove.l	d0,fpcr
	fmove.x	mpiby2(pc),fp0	* load -pi/2
	bra.w	t_minx2	* set INEX2

****************************************************
* The following routines give support for fsincos. *
****************************************************

*
* ssincosz(): When the src operand is ZERO, store a one in the
* 	      cosine register and return a ZERO in fp0 w/ the same sign
*	      as the src operand.
*
	xdef	ssincosz
ssincosz:
	fmove.s	#$3f800000,fp1
	tst.b	SRC_EX(a0)	* test sign
	bpl.b	sincoszp
	fmove.s	#$80000000,fp0	* return sin result in fp0
	move.b	#z_bmask+neg_bmask,EXC_LV+FPSR_CC(a6)
	bra.b	sto_cos	* store cosine result
sincoszp:
	fmove.s	#$00000000,fp0	* return sin result in fp0
	move.b	#z_bmask,EXC_LV+FPSR_CC(a6)
	bra.b	sto_cos	* store cosine result

*
* ssincosi(): When the src operand is INF, store a QNAN in the cosine
*	      register and jump to the operand error routine for negative
*	      src operands.
*
	xdef	ssincosi
ssincosi:
	fmove.x	qnan(pc),fp1	* load NAN
	bsr	sto_cos	* store cosine result
	bra.w	t_operr

*
* ssincosqnan(): When the src operand is a QNAN, store the QNAN in the cosine
* 	 register and branch to the src QNAN routine.
*
	xdef	ssincosqnan
ssincosqnan:
	fmove.x	LOCAL_EX(a0),fp1
	bsr	sto_cos
	bra.w	src_qnan

*
* ssincossnan(): When the src operand is an SNAN, store the SNAN w/ the SNAN bit set
*	 in the cosine register and branch to the src SNAN routine.
*
	xdef	ssincossnan
ssincossnan:
	fmove.x	LOCAL_EX(a0),fp1
	bsr	sto_cos
	bra.w	src_snan

**********

**-------------------------------------------------------------------------------------------------
* sto_cos(): store fp1 to the fpreg designated by the CMDREG dst field.
*	     fp1 holds the result of the cosine portion of ssincos().
*	     the value in fp1 will not take any exceptions when moved.
* INPUT:
*	fp1 : fp value to store
* MODIFIED:
*	d0
**-------------------------------------------------------------------------------------------------
	xdef	sto_cos
sto_cos:
	move.b	1+EXC_LV+EXC_CMDREG(a6),d0
	andi.w	#$7,d0
	move.w	((tbl_sto_cos).b,pc,d0.w*2),d0
	jmp	((tbl_sto_cos).b,pc,d0.w*1)

tbl_sto_cos:
	dc.w	sto_cos_0 - tbl_sto_cos
	dc.w	sto_cos_1 - tbl_sto_cos
	dc.w	sto_cos_2 - tbl_sto_cos
	dc.w	sto_cos_3 - tbl_sto_cos
	dc.w	sto_cos_4 - tbl_sto_cos
	dc.w	sto_cos_5 - tbl_sto_cos
	dc.w	sto_cos_6 - tbl_sto_cos
	dc.w	sto_cos_7 - tbl_sto_cos

sto_cos_0:
	fmovem.x	fp1,EXC_LV+EXC_FP0(a6)
	rts
sto_cos_1:
	fmovem.x	fp1,EXC_LV+EXC_FP1(a6)
	rts
sto_cos_2:
	fmove.x 	fp1,fp2
	rts
sto_cos_3:
	fmove.x	fp1,fp3
	rts
sto_cos_4:
	fmove.x	fp1,fp4
	rts
sto_cos_5:
	fmove.x	fp1,fp5
	rts
sto_cos_6:
	fmove.x	fp1,fp6
	rts
sto_cos_7:
	fmove.x	fp1,fp7
	rts

****
	xdef	smod_sdnrm
	xdef	smod_snorm
smod_sdnrm:
smod_snorm:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	smod
	ICMP.b	d1,#ZERO
	beq.w	smod_zro
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	smod
	ICMP.b	d1,#SNAN
	beq.l	dst_snan
	bra	dst_qnan

	xdef	smod_szero
smod_szero:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	t_operr
	ICMP.b	d1,#ZERO
	beq.l	t_operr
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	t_operr
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

	xdef	smod_sinf
smod_sinf:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	smod_fpn
	ICMP.b	d1,#ZERO
	beq.l	smod_zro
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	smod_fpn
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

smod_zro:
srem_zro:
	move.b	SRC_EX(a0),d1	* get src sign
	move.b	DST_EX(a1),d0	* get dst sign
	eor.b	d0,d1	* get qbyte sign
	andi.b	#$80,d1
	move.b	d1,EXC_LV+FPSR_QBYTE(a6)
	tst.b	d0
	bpl.w	ld_pzero
	bra.w	ld_mzero

smod_fpn:
srem_fpn:
	clr.b	EXC_LV+FPSR_QBYTE(a6)
	move.l	d0,-(sp)
	move.b	SRC_EX(a0),d1	* get src sign
	move.b	DST_EX(a1),d0	* get dst sign
	eor.b	d0,d1	* get qbyte sign
	andi.b	#$80,d1
	move.b	d1,EXC_LV+FPSR_QBYTE(a6)
	ICMP.b	EXC_LV+DTAG(a6),#DENORM
	bne.b	smod_nrm
	lea	DST(a1),a0
	move.l	(sp)+,d0
	bra	t_resdnrm
smod_nrm:
	fmove.l	(sp)+,fpcr
	fmove.x	DST(a1),fp0
	tst.b	DST_EX(a1)
	bmi.b	smod_nrm_neg
	rts

smod_nrm_neg:
	move.b	#neg_bmask,EXC_LV+FPSR_CC(a6)	* set 'N' ccode
	rts

**-------------------------------------------------------------------------------------------------
	xdef	srem_snorm
	xdef	srem_sdnrm
srem_sdnrm:
srem_snorm:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	srem
	ICMP.b	d1,#ZERO
	beq.w	srem_zro
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	srem
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

	xdef	srem_szero
srem_szero:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	t_operr
	ICMP.b	d1,#ZERO
	beq.l	t_operr
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	t_operr
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

	xdef	srem_sinf
srem_sinf:
	move.b	EXC_LV+DTAG(a6),d1
	beq.w	srem_fpn
	ICMP.b	d1,#ZERO
	beq.w	srem_zro
	ICMP.b	d1,#INF
	beq.l	t_operr
	ICMP.b	d1,#DENORM
	beq.l	srem_fpn
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

**-------------------------------------------------------------------------------------------------
	xdef	sscale_snorm
	xdef	sscale_sdnrm
sscale_snorm:
sscale_sdnrm:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	sscale
	ICMP.b	d1,#ZERO
	beq.l	dst_zero
	ICMP.b	d1,#INF
	beq.l	dst_inf
	ICMP.b	d1,#DENORM
	beq.l	sscale
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

	xdef	sscale_szero
sscale_szero:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	sscale
	ICMP.b	d1,#ZERO
	beq.l	dst_zero
	ICMP.b	d1,#INF
	beq.l	dst_inf
	ICMP.b	d1,#DENORM
	beq.l	sscale
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	bra	dst_snan

	xdef	sscale_sinf
sscale_sinf:
	move.b	EXC_LV+DTAG(a6),d1
	beq.l	t_operr
	ICMP.b	d1,#QNAN
	beq.l	dst_qnan
	ICMP.b	d1,#SNAN
	beq.l	dst_snan
	bra	t_operr

**********

*
* sop_sqnan(): The src op for frem/fmod/fscale was a QNAN.
*
	xdef	sop_sqnan
sop_sqnan:
	move.b	EXC_LV+DTAG(a6),d1
	ICMP.b	d1,#QNAN
	beq.b	dst_qnan
	ICMP.b	d1,#SNAN
	beq.b	dst_snan
	bra.b	src_qnan

*
* sop_ssnan(): The src op for frem/fmod/fscale was an SNAN.
*
	xdef	sop_ssnan
sop_ssnan:
	move.b	EXC_LV+DTAG(a6),d1
	ICMP.b	d1,#QNAN
	beq.b	dst_qnan_src_snan
	ICMP.b	d1,#SNAN
	beq.b	dst_snan
	bra.b	src_snan

dst_qnan_src_snan:
	ori.l	#snaniop_mask,EXC_LV+USER_FPSR(a6) * set NAN/SNAN/AIOP
	bra.b	dst_qnan

*
* dst_qnan(): Return the dst SNAN w/ the SNAN bit set.
*
	xdef	dst_snan
dst_snan:
	fmove.x	DST(a1),fp0	* the fmove sets the SNAN bit
	fmove.l	fpsr,d0	* catch resulting status
	or.l	d0,EXC_LV+USER_FPSR(a6)	* store status
	rts

*
* dst_qnan(): Return the dst QNAN.
*
	xdef	dst_qnan
dst_qnan:
	fmove.x	DST(a1),fp0	* return the non-signalling nan
	tst.b	DST_EX(a1)	* set ccodes according to QNAN sign
	bmi.b	dst_qnan_m
dst_qnan_p:
	move.b	#nan_bmask,EXC_LV+FPSR_CC(a6)
	rts
dst_qnan_m:
	move.b	#neg_bmask+nan_bmask,EXC_LV+FPSR_CC(a6)
	rts

*
* src_snan(): Return the src SNAN w/ the SNAN bit set.
*
	xdef	src_snan
src_snan:
	fmove.x	SRC(a0),fp0	* the fmove sets the SNAN bit
	fmove.l	fpsr,d0	* catch resulting status
	or.l	d0,EXC_LV+USER_FPSR(a6)	* store status
	rts

*
* src_qnan(): Return the src QNAN.
*
	xdef	src_qnan
src_qnan:
	fmove.x	SRC(a0),fp0	* return the non-signalling nan
	tst.b	SRC_EX(a0)	* set ccodes according to QNAN sign
	bmi.b	dst_qnan_m
src_qnan_p:
	move.b	#nan_bmask,EXC_LV+FPSR_CC(a6)
	rts
src_qnan_m:
	move.b	#neg_bmask+nan_bmask,EXC_LV+FPSR_CC(a6)
	rts












