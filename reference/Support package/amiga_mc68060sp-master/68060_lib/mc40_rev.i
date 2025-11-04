VERSION  EQU	40
REVISION EQU	2
DATE     MACRO
		dc.b	'14.04.97'
    ENDM
VERS     MACRO
		dc.b	'mc40 40.02'
    ENDM
VSTRING  MACRO
		dc.b	'mc40 40.02 (14.04.97)',13,10,0
    ENDM
VERSTAG  MACRO
		dc.b	0,'$VER: mc40 40.3 (14.04.97)',0
    ENDM
AUTHOR   MACRO
		dc.b	'Carsten Schlote'
    ENDM
PROJECT  MACRO
		dc.b	'mc40'
    ENDM
