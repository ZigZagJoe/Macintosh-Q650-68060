VERSION  EQU	40
REVISION EQU	16   ;*  ß 1 
DATE     MACRO
		dc.b	'22.05.97'
    ENDM
VERS     MACRO
		dc.b	'mc60 40.16 ß 1'
    ENDM
VSTRING  MACRO
		dc.b	'mc60 40.16 ß 1 (22.05.97)',13,10,0
    ENDM
VERSTAG  MACRO
		dc.b	0,'$VER: mc60 40.16 ß 1 (22.05.97)',0
    ENDM
AUTHOR   MACRO
		dc.b	'Carsten Schlote'
    ENDM
PROJECT  MACRO
		dc.b	'mc60'
    ENDM
