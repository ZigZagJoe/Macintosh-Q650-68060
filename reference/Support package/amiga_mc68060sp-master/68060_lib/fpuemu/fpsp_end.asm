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
**------------------------------------------------------------------------------------------------------
	NOLIST

	incdir	include:
	include	all_lvo.i
	include	exec/exec.i
	include	exec/types.i
	include	exec/nodes.i
	include	exec/resident.i

**------------------------------------------------------------------------------------------------------

	include          fpsp_debug.i
MYDEBUG	SET         	0	; Current Debug Level
DEBUG_DETAIL 	set 	10	; Detail Level

**------------------------------------------------------------------------------------------------------

	SECTION	FPSP060,CODE
	NEAR	CODE
	XDEF	FPSP060_End
	XDEF	___stub
___stub:
FPSP060_End:
	NOP
                RTS
	end
