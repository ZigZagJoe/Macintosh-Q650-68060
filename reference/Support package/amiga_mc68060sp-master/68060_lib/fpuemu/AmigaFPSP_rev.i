;** $Revision Header *** Header built automatically - do not edit! ***********
;**
;** © Copyright Silicon Department
;**
;** File             : AmigaFPSP_rev.i
;** Created on       : Montag, 21-Apr-97 
;** Created by       : Carsten Schlote
;** Current revision : V 1.01
;**
;** Purpose
;** -------
;**   - Empty log message -
;**
;** Date        Author                 Comment
;** =========   ====================   ====================
;** 21-Apr-97    Carsten Schlote        - Empty log message -
;** 21-Apr-97    Carsten Schlote        --- Initial release ---
;**
;** $Revision Header ********************************************************
VERSION  EQU	40
REVISION EQU	2
DATE     MACRO
		dc.b	'21.04.97'
    ENDM
VERS     MACRO
		dc.b	'AmigaFPSP 40.02'
    ENDM
VSTRING  MACRO
		dc.b	'AmigaFPSP 40.02 (21.04.97)',13,10,0
    ENDM
VERSTAG  MACRO
		dc.b	0,'$VER: AmigaFPSP 40.02 (21.04.97)',0
    ENDM
AUTHOR   MACRO
		dc.b	'Carsten Schlote'
    ENDM
PROJECT  MACRO
		dc.b	'AmigaFPSP'
    ENDM
