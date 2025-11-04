**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

** Call into emu module : <modul>,<vector>,<Debug text>

CALL_IN:	MACRO

	IFGE	MYDEBUG-20				; Get Debug Output on Call In
	MOVEM.L	A0-a1,-(SP)
	MOVEA.L	(8,SP),A0				; Get Stackframe
	MOVEA.L	(8+4,SP),A1
	DBUG        20,\3,a0,a1
	MOVEM.L	(SP)+,A0-a1
	ENDC

	BRA.L	\1+(\2*8)
	ENDM

**-------------------------------------------------------------------------------

**  <call in stub for module>,<cpu exception vector in VBR A2>

SETVECTOR:	MACRO       ; vector
	LEA	(Vector_\2,PC),A1			; get old vector
	MOVE.L	(\2*4,A2),(A1)                      ; and store for further use.

	LEA	(\1,PC),A1                          ; Get Addr of call in
	MOVE.L	A1,(\2*4,A2)			; set vbr vector
	MOVE.L	A1,(\2*4).W                         ; set to 'base' vbr
	ENDM

