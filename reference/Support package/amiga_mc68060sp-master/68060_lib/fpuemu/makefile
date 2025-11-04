##-----------------------------------------------------------------------------
##  /\    |\     Silicon Department     
##  \_  o| \_ _  Software Entwicklung
##     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
## \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
## See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
##-----------------------------------------------------------------------------

##
##
##-------------------------------------------------------------------------------

.asm.o:
	phxass $*.asm noexe $(AOPTS)

##-------------------------------------------------------------------------------

HDR	= fpsp_macros.i fpsp_emu.i fpsp_debug.i AmigaFPSP_rev.i
SRC	= fpsp_init.asm fpsp_end.asm fpsp_excepts.asm fpsp_subs.asm fpsp_fxcc.asm fpsp_temp.asm
OBJ	= \
 fpsp_init.o \
 fpsp_temp.o fpsp_excepts.o fpsp_trans.o fpsp_base.o fpsp_fxcc.o fpsp_fouts.o fpsp_subs.o \
 fpsp_end.o
LIB	= lib:debug.lib lib:amiga.lib
EXE	= AmigaFPSP
AOPTS	= SET "TESTCODE=1"
MAP	= MAP $(EXE).map hsxflo hwidth 12 Height 60 width 115 fwidth 12 pwidth 12 swidth 12

##-------------------------------------------------------------------------------

all: $(EXE).ro

$(EXE).ld : $(OBJ)
#	phxlnk from $(OBJ) to $(EXE).ld noicons addsym sc sd lib $(LIB)
	slink from $(OBJ) to $(EXE).ld lib $(LIB) noicons addsym sc sd verbose $(MAP)
	slink from $(EXE).ld to $(EXE) noicons nd sc sd LIB $(LIB)

##-------------------------------------------------------------------------------

$(EXE).ro : $(EXE).ld
	slink from $(OBJ) to $(EXE).ro noicons addsym sc sd lib $(LIB) prelink noicons

##-------------------------------------------------------------------------------

$(SRC): $(HDR) makefile

bump:
	bumprevision bump file AmigaFPSP_rev.i noc

