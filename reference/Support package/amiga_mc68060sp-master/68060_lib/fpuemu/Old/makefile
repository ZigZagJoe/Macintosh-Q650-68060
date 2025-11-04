##-----------------------------------------------------------------------------
##  /\    |\     Silicon Department     
##  \_  o| \_ _  Software Entwicklung
##     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
## \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
## See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
##-----------------------------------------------------------------------------


.asm.o:
	phxass $*.asm noexe $(AOPTS)

##-------------------------------------------------------------------------------

SRC	= fpsp.asm
HDR	= fpsp.i fpsp_debug.i AmigaFPSP_rev.i
OBJ	= fpsp.o
LIB	= lib:debug.lib lib:amiga.lib
EXE	= AmigaFPSP
AOPTS	= ds dl SET "TESTCODE=1"


##-------------------------------------------------------------------------------

all: $(EXE).ld $(EXE).ro

$(EXE).ld : $(OBJ)
	slink from $(OBJ) to $(EXE).ld noicons addsym sc sd lib $(LIB)
	slink from $(EXE).ld to $(EXE) nd sc sd LIB $(LIB)

##-------------------------------------------------------------------------------


$(EXE).ro : $(EXE)
	phxass $(SRC) to $(EXE).ro noexe

##-------------------------------------------------------------------------------

$(SRC): $(HDR) makefile

bump:
	bumprevision bump file AmigaFPSP_rev.i noc

