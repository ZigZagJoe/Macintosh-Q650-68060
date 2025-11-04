**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

**
**	Code Taken from RKM Companium
**
	machine 68060    * compile for 060
	opt ds dl        * create debug info
	near

	include     	mc60_system.i
	include	mc60_libbase.i

**-------------------------------------------------------------------------------

	XREF	_LibInit

**-------------------------------------------------------------------------------

	SECTION	startup,CODE
	XDEF	LibStart

LibStart:	MOVEQ	#0,D0	; Return to caller : no exec
	RTS


**-------------------------------------------------------------------------------

	XREF	RomTagEnd              ; End of Small Data Module

RomTag:	ILLEGAL
	dc.l	RomTag	; MAGIC !!
	dc.l	RomTagEnd
	dc.b	RTF_AUTOINIT	; Mode
	dc.b	VERSION                ; Version
	dc.b	NT_LIBRARY             ; Typ
	dc.b             130	; Pri
	dc.l	LibName	; Name of Library
	dc.l	IDString	; Version Tag
	dc.l	InitTable

**-------------------------------------------------------------------------------

LibName:	dc.b	'68060.library',0
IDString:	VERS
	dc.b	" ("
	DATE
	dc.b	")
	dc.b	"©1997 by Carsten Schlote, Coenobium Developments",0
                        even
**-------------------------------------------------------------------------------

InitTable:	dc.l	mc60_SIZEOF	; Size of LibBase
	dc.l	funcTable                      ; auto init stuff
	dc.l	dataTable
	dc.l	_LibInit	; external InitCode in C .. asm sux.

**-------------------------------------------------------------------------------


funcTable:	dc.l	_LibOpen	; Standard Funktions
	dc.l	_LibClose                      ; Standard Close
	dc.l	_LibExpunge                    ; Standard Expunge
	dc.l	_LibNop                        ; reserved * ARexx ??? ;-)
	dc.l	-1
	cnop	0,4

**-------------------------------------------------------------------------------

dataTable:	INITBYTE	LN_TYPE,NT_LIBRARY             ; Init some values...
	INITLONG	LN_NAME,LibName
                        INITBYTE	LIB_FLAGS,(LIBF_CHANGED|LIBF_SUMUSED),
	INITWORD	LIB_VERSION,VERSION
	INITWORD	LIB_REVISION,REVISION
	INITLONG	LIB_IDSTRING,IDString
                        dc.w	0
                        cnop	0,4

**-------------------------------------------------------------------------------

_LibOpen:	ADDQ.W	#1,(LIB_OPENCNT,A6)	; Lib Opened - inc count
	MOVE.L	A6,D0                        	; return
	RTS

**-------------------------------------------------------------------------------

_LibClose:	MOVEQ	#0,D0
	SUBQ.W	#1,(LIB_OPENCNT,A6)        	; != 0 - still in use
	BNE.B            .quit
                        BTST.B	#LIBB_DELEXP,(LIB_FLAGS,A6)    ; only for delayed expunge
                        BEQ	.quit
	BSR.W	_LibExpunge	; dispose lib.
.quit:	RTS

**-------------------------------------------------------------------------------

_LibExpunge:	* Code removed and RCSed ......

**-------------------------------------------------------------------------------

_LibNop:
	MOVEQ	#0,D0
	RTS

