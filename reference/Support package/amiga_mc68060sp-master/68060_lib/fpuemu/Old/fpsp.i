**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------


**------------------------------------------------------------------------------------------------------
*
* define statements for constants
* in order to promote readability within the core code itself.
*
**------------------------------------------------------------------------------------------------------

** CAUTION: Frame is accessed via EXC_LV+EXC_* !!!!

SFF0_ISR	equ	4	* W: stack status register
SFF0_IPC	equ	6	* L: stack pc
SFF0_IVOFF	equ	10	* stacked vector offset

EXC_SR	equ	4	* stack status register
EXC_PC	equ	6	* stack pc
EXC_VOFF	equ	10	* stacked vector offset
EXC_EA	equ	12	* stacked <ea>

	STRUCTURE 	fpsp_Stack,0	*
	UWORD	EXC_OPWORD	* saved operation word
	LABEL	EXC_EXTWORD	* saved extension word
	UWORD	EXC_CMDREG	* saved extension word
	ULONG	EXC_EXTWPTR	* saved current PC (active)
	UWORD	EXC_CC	* saved condition codes

	ULONG	SPCOND_FLG	* flag: special case (see below)

	UBYTE	STAG 	* source operand type
	UBYTE	DTAG	* destination operand type
	UBYTE	STORE_FLG	* flag: operand store (ie. not fcmp/ftst)
	UBYTE	EXC_TEMP	* temporary space

	ULONG	L_SCR1	* integer scratch 1
	ULONG	L_SCR2	* integer scratch 2
	LABEL	EXC_TEMP2	* temporary space
	ULONG	L_SCR3	* integer scratch 3

	LABEL	USER_FPCR	* FP control register
	UBYTE	FPCR_MODE	* FPCR rounding mode control
	UBYTE	FPCR_ENABLE	* FPCR exception enable
	UBYTE	pad0
	UBYTE	pad1

	LABEL	USER_FPSR	* FP status register
	UBYTE	FPSR_AEXCEPT	* FPSR accrued exception byte
	UBYTE	FPSR_EXCEPT	* FPSR exception status byte
	UBYTE	FPSR_QBYTE	* FPSR qoutient byte
	UBYTE	FPSR_CC	* FPSR condition codes

	ULONG	USER_FPIAR	* FP instr address register

	LABEL	FP_SRC 	* fp source operand
	UWORD	FP_SRC_EX
	UWORD	FP_SRC_SGN
	UWORD	FP_SRC_HI
	UWORD	FP_SRC_LO


	LABEL	FP_DST	* fp destination operand
	UWORD	FP_DST_EX
	UWORD	FP_DST_SGN
	UWORD	FP_DST_HI
	UWORD	FP_DST_LO

	LABEL	FP_SCR0	* fp scratch 0
	UWORD	FP_SCR0_EX
	UWORD	FP_SCR0_SGN
	UWORD	FP_SCR0_HI
	UWORD	FP_SCR0_LO

	LABEL	FP_SCR1	* fp scratch 1
	UWORD	FP_SCR1_EX
	UWORD	FP_SCR1_SGN
	UWORD	FP_SCR1_HI
	UWORD	FP_SCR1_LO

	LABEL	EXC_DREGS	* offset of all data regs
	ULONG	EXC_D0
	ULONG	EXC_D1
	ULONG	EXC_D2
	ULONG	EXC_D3
	ULONG	EXC_D4
	ULONG	EXC_D5
	ULONG	EXC_D6
	ULONG	EXC_D7

	LABEL	EXC_AREGS	* offset of all address regs
	ULONG	EXC_A0
	ULONG	EXC_A1
	ULONG	EXC_A2
	ULONG	EXC_A3
	ULONG	EXC_A4
	ULONG	EXC_A5
	LABEL	EXC_A6	* offset of saved a6
	ULONG	OLD_A7	* || extra copy of saved a7
	ULONG	EXC_A7	* offset of saved a7

	LABEL	EXC_FPREGS	* offset of all fp regs
	STRUCT	EXC_FP0,3*4	* offset of saved fp0
	STRUCT	EXC_FP1,3*4 	* offset of saved fp1
	STRUCT	EXC_FP2,3*4 	* offset of saved fp2 (not used)

	LABEL            EXC_SIZEOF	* stack frame size(bytes)
	ULONG	EXC_FP	* stack link register <a6> store

EXC_LV	EQU	-EXC_SIZEOF	* ACESSS Data (EXC_LV+EXC_*,a6)

**------------------------------------------------------------------------------------------------------
*LOCAL_SIZE	equ	192	* stack frame size(bytes)


********************************************************************************
* Helpful macros
********************************************************************************

FTEMP	equ	0	* offsets within an
FTEMP_EX	equ 	0	* extended precision
FTEMP_SGN	equ	2	* value saved in memory.
FTEMP_HI	equ 	4
FTEMP_LO	equ 	8
FTEMP_GRS	equ	12

LOCAL	equ	0	* off within an
LOCAL_EX 	equ	0	* extended precision
LOCAL_SGN	equ	2	* value saved in memory.
LOCAL_HI	equ 	4
LOCAL_LO	equ 	8
LOCAL_GRS	equ	12

DST	equ	0	* offsets within an
DST_EX	equ	0	* extended precision
DST_HI	equ	4	* value saved in memory.
DST_LO	equ	8

SRC	equ	0	* offsets within an
SRC_EX	equ	0	* extended precision
SRC_HI	equ	4	* value saved in memory.
SRC_LO	equ	8

SGL_LO	equ	$3f81	* min sgl prec exponent
SGL_HI	equ	$407e	* max sgl prec exponent
DBL_LO	equ	$3c01	* min dbl prec exponent
DBL_HI	equ	$43fe	* max dbl prec exponent
EXT_LO	equ	$0	* min ext prec exponent
EXT_HI	equ	$7ffe	* max ext prec exponent

EXT_BIAS	equ	$3fff	* extended precision bias
SGL_BIAS	equ	$007f	* single precision bias
DBL_BIAS	equ	$03ff	* double precision bias

NORM	equ	$00	* operand type for STAG/DTAG
ZERO	equ	$01	* operand type for STAG/DTAG
INF	equ	$02	* operand type for STAG/DTAG
QNAN	equ	$03	* operand type for STAG/DTAG
DENORM	equ	$04	* operand type for STAG/DTAG
SNAN	equ	$05	* operand type for STAG/DTAG
UNNORM	equ	$06	* operand type for STAG/DTAG

*****************************************************************************
* FPSR/FPCR bits *
*****************************************************************************

neg_bit	equ	$3	* negative result
z_bit	equ	$2	* zero result
inf_bit	equ	$1	* infinite result
nan_bit	equ	$0	* NAN result

q_sn_bit	equ	$7	* sign bit of quotient byte

bsun_bit	equ	7	* branch on unordered
snan_bit	equ	6	* signalling NAN
operr_bit	equ	5	* operand error
ovfl_bit	equ	4	* overflow
unfl_bit	equ	3	* underflow
dz_bit	equ	2	* divide by zero
inex2_bit	equ	1	* inexact result 2
inex1_bit	equ	0	* inexact result 1

aiop_bit	equ	7	* accrued inexact operation bit
aovfl_bit	equ	6	* accrued overflow bit
aunfl_bit	equ	5	* accrued underflow bit
adz_bit	equ	4	* accrued dz bit
ainex_bit	equ	3	* accrued inexact bit

*****************************************************************************
* FPSR individual bit masks *
*****************************************************************************

neg_mask	equ	$08000000	* negative bit mask (lw)
inf_mask	equ	$02000000	* infinity bit mask (lw)
z_mask	equ	$04000000	* zero bit mask (lw)
nan_mask	equ	$01000000	* nan bit mask (lw)

neg_bmask	equ	$08	* negative bit mask (byte)
inf_bmask	equ	$02	* infinity bit mask (byte)
z_bmask	equ	$04	* zero bit mask (byte)
nan_bmask	equ	$01	* nan bit mask (byte)

bsun_mask	equ	$00008000	* bsun exception mask
snan_mask	equ	$00004000	* snan exception mask
operr_mask	equ	$00002000	* operr exception mask
ovfl_mask	equ	$00001000	* overflow exception mask
unfl_mask	equ	$00000800	* underflow exception mask
dz_mask	equ	$00000400	* dz exception mask
inex2_mask	equ	$00000200	* inex2 exception mask
inex1_mask	equ	$00000100	* inex1 exception mask

aiop_mask	equ	$00000080	* accrued illegal operation
aovfl_mask	equ	$00000040	* accrued overflow
aunfl_mask	equ	$00000020	* accrued underflow
adz_mask	equ	$00000010	* accrued divide by zero
ainex_mask	equ	$00000008	* accrued inexact

*****************************************************************************
* FPSR combinations used in the FPSP *
*****************************************************************************

dzinf_mask	equ	inf_mask+dz_mask+adz_mask
opnan_mask	equ	nan_mask+operr_mask+aiop_mask
nzi_mask	equ	$01ffffff 		*clears N, Z, and I
unfinx_mask	equ	unfl_mask+inex2_mask+aunfl_mask+ainex_mask
unf2inx_mask	equ	unfl_mask+inex2_mask+ainex_mask
ovfinx_mask	equ	ovfl_mask+inex2_mask+aovfl_mask+ainex_mask
inx1a_mask	equ	inex1_mask+ainex_mask
inx2a_mask	equ	inex2_mask+ainex_mask
snaniop_mask	equ 	nan_mask+snan_mask+aiop_mask
snaniop2_mask	equ	snan_mask+aiop_mask
naniop_mask	equ	nan_mask+aiop_mask
neginf_mask	equ	neg_mask+inf_mask
infaiop_mask	equ 	inf_mask+aiop_mask
negz_mask	equ	neg_mask+z_mask
opaop_mask	equ	operr_mask+aiop_mask
unfl_inx_mask	equ	unfl_mask+aunfl_mask+ainex_mask
ovfl_inx_mask	equ	ovfl_mask+aovfl_mask+ainex_mask

*****************************************************************************
* misc. *
*****************************************************************************

rnd_stky_bit	equ	29	* stky bit pos in longword

sign_bit	equ	$7	* sign bit
signan_bit	equ	$6	* signalling nan bit

sgl_thresh	equ	$3f81	* minimum sgl exponent
dbl_thresh	equ	$3c01	* minimum dbl exponent

x_mode	equ	$0	* extended precision
s_mode	equ	$4	* single precision
d_mode	equ	$8	* double precision

rn_mode	equ	$0	* round-to-nearest
rz_mode	equ	$1	* round-to-zero
rm_mode	equ	$2	* round-tp-minus-infinity
rp_mode	equ	$3	* round-to-plus-infinity

mantissalen	equ	64	* length of mantissa in bits

; @@@@@@@@@@ Care about it....
sizeBYTE	equ	1	* len(byte) == 1 byte
sizeWORD	equ 	2	* len(word) == 2 bytes
sizeLONG	equ 	4	* len(longword) == 2 bytes

BSUN_VEC	equ	$c0	* bsun    vector offset
INEX_VEC	equ	$c4	* inexact vector offset
DZ_VEC	equ	$c8	* dz      vector offset
UNFL_VEC	equ	$cc	* unfl    vector offset
OPERR_VEC	equ	$d0	* operr   vector offset
OVFL_VEC	equ	$d4	* ovfl    vector offset
SNAN_VEC	equ	$d8	* snan    vector offset

*****************************************************************************
* SPecial CONDition FLaGs *
*****************************************************************************

ftrapcc_flg	equ	$01	* flag bit: ftrapcc exception
fbsun_flg	equ	$02	* flag bit: bsun exception
mia7_flg	equ	$04	* flag bit: (a7)+ <ea>
mda7_flg	equ	$08	* flag bit: -(a7) <ea>
fmovm_flg	equ	$40	* flag bit: fmovm instruction
immed_flg	equ	$80	* flag bit: &<data> <ea>

ftrapcc_bit	equ	$0
fbsun_bit	equ	$1
mia7_bit	equ	$2
mda7_bit	equ	$3
immed_bit	equ	$7

*****************************************************************************
* TRANSCENDENTAL "LAST-OP" FLAGS *
*****************************************************************************

FMUL_OP	equ	$0	* fmul instr performed last
FDIV_OP	equ	$1	* fdiv performed last
FADD_OP	equ	$2	* fadd performed last
FMOV_OP	equ	$3	* fmov performed last

**------------------------------------------------------------------------------------------------------

TOPOFF          equ	(_060FPSP_TABLE-$80)

_off_bsun	equ	$00
_off_snan	equ	$04
_off_operr	equ	$08
_off_ovfl	equ	$0c
_off_unfl	equ	$10
_off_dz	equ	$14
_off_inex	equ	$18
_off_fline	equ	$1c
_off_fpu_dis	equ	$20
_off_trap	equ	$24
_off_trace	equ	$28
_off_access	equ	$2c
_off_done	equ	$30

_off_imr	equ	$40
_off_dmr	equ	$44
_off_dmw	equ	$48
_off_irw	equ	$4c
_off_irl	equ	$50
_off_drb	equ	$54
_off_drw	equ	$58
_off_drl	equ	$5c
_off_dwb	equ	$60
_off_dww	equ	$64
_off_dwl	equ	$68

**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------


**------------------------------------------------------------------------------------------------------
** Misc.
**------------------------------------------------------------------------------------------------------

size_BYTE	equ	1	* len(byte) == 1 byte
size_WORD	equ 	2	* len(word) == 2 bytes
size_LONG	equ 	4	* len(longword) == 4 bytes


**------------------------------------------------------------------------------------------------------
CALL_IN:	MACRO

	IFGE	MYDEBUG-20				; Get Debug Output on Call In
	MOVEM.L	A0-a1,-(SP)
	MOVEA.L	(8,SP),A0				; Get Stackframe
	MOVEA.L	(8+4,SP),A1
	DBUG        	20,\3,a0,a1
	MOVEM.L	(SP)+,A0-a1
	ENDC

	BRA.L	\1+(\2*8)
	ENDM

SETVECTOR:	MACRO       	; vector
	LEA	(Vector_\2,PC),A1	; get old vector
	MOVE.L	(\2*4,A2),(A1)    ; and store for further use.
	LEA	(\1,PC),A1   	; Get Addr of call in
	MOVE.L	A1,(\2*4,A2)	; set vbr vector
	MOVE.L	A1,(\2*4).W       ; set to 'base' vbr
	ENDM

