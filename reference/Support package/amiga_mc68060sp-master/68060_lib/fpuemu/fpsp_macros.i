**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------


**------------------------------------------------------------------------------------------------------
**------------------------------------------------------------------------------------------------------


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


CALLOUT:	MACRO
	move.l	d0,-(sp)
                        move.l	(((_060FPSP_TABLE-$80)+\1).W,PC),d0
                        pea.l	((_060FPSP_TABLE-$80).L,PC,d0.l)
                        move.l           (4,SP),d0
                        RTD	#(4).L
	ENDM

ICMP	macro			* Simplefy things.
	cmp.\0 \2,\1
	endm
