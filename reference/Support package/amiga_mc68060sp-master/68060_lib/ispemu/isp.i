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

	STRUCTURE 	isp_Stack,0	*
	UWORD	EXC_OPWORD	* offset of current opword
	UWORD	EXC_EXTWORD	* offset of current ext opword
	ULONG	EXC_EXTWPTR	* offset of current PC
	UWORD	EXC_CC	* offset of cc register

	UBYTE	SPCOND_FLG	* offset of spc condition flg
	UBYTE	EXC_SAVREG	* offset of old areg index
	UBYTE	EXC_SAVVAL	* offset of old areg value
	UBYTE	EXC_PAD2	* allign stack
	UWORD	EXC_PAD3	* allign to 16 Byte

	STRUCT	EXC_TEMP,16	* offset of temp stack space


	LABEL	EXC_REGS	* offset of all regs         MOVEM <>,(-EXC_REGS,A6)

	LABEL	EXC_DREGS	* offset of all data regs
	ULONG	EXC_D0	* offset of d0
	ULONG	EXC_D1	* offset of d1
	ULONG	EXC_D2	* offset of d2
	ULONG	EXC_D3	* offset of d3
	ULONG	EXC_D4	* offset of d4
	ULONG	EXC_D5	* offset of d5
	ULONG	EXC_D6	* offset of d6
	ULONG	EXC_D7	* offset of d7

	LABEL	EXC_AREGS	* offset of all address regs
	ULONG	EXC_A0	* offset of a0
	ULONG	EXC_A1	* offset of a1
	ULONG	EXC_A2	* offset of a2
	ULONG	EXC_A3	* offset of a3
	ULONG	EXC_A4	* offset of a4
	ULONG	EXC_A5	* offset of a5
	ULONG	EXC_A6	* offset of a6
	ULONG	EXC_A7	* offset of a7

	LABEL            EXC_SIZEOF	* stack frame size(bytes)
	ULONG	EXC_A6OLD	* stack link register <a6> store  LINK MNE

EXC_LV	EQU	-EXC_SIZEOF	* ACESSS Data (EXC_LV+EXC_*,a6)


**------------------------------------------------------------------------------------------------------
** SPecial CONDition FLaGs
**------------------------------------------------------------------------------------------------------

mia7_flg	equ	$04	* (a7)+ flag
mda7_flg	equ	$08	* -(a7) flag
ichk_flg	equ	$10	* chk exception flag
idbyz_flg	equ	$20	* divbyzero flag
restore_flg	equ	$40	* restore -(an)+ flag
immed_flg	equ	$80	* immediate data flag

mia7_bit	equ	$2	* (a7)+ bit
mda7_bit	equ	$3	* -(a7) bit
ichk_bit	equ	$4	* chk exception bit
idbyz_bit	equ	$5	* divbyzero bit
restore_bit	equ	$6	* restore -(a7)+ bit
immed_bit	equ	$7	* immediate data bit

**------------------------------------------------------------------------------------------------------
** Misc.
**------------------------------------------------------------------------------------------------------

size_BYTE	equ	1	* len(byte) == 1 byte
size_WORD	equ 	2	* len(word) == 2 bytes
size_LONG	equ 	4	* len(longword) == 4 bytes


**------------------------------------------------------------------------------------------------------

