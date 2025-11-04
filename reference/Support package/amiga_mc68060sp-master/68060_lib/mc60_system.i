**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

**
**
**-------------------------------------------------------------------------------

_custom:	EQU	$00DFF000

	incdir	include:
	linedebug


	include 	mc60_rev.i			; Check in revision
	include	mc60_debug.i

                        NOLIST
	include	all_lvo.i                   ; All System LVO offsets

	include	exec/initializers.i		; Needed system includes follow
	include	exec/types.i
	include	exec/lists.i
	include	exec/nodes.i
	include	exec/exec.i
	include	exec/tasks.i

	include	dos/dosextens.i

	include	hardware/custom.i

	include          libraries/configvars.i
	LIST


**-------------------------------------------------------------------------------

_LVOexecPrivate4:	EQU	-$00000036			; For Operation the following privates
_LVOexecPrivate6:	EQU	-$00000042			; are patched.
_LVOexecPrivate8:	EQU	-$000001FE
_LVOexecPrivate9:	EQU	-$00000204

**-------------------------------------------------------------------------------


**-------------------------------------------------------------------------------

