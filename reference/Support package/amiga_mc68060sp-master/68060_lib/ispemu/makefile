##-----------------------------------------------------------------------------
##  /\    |\     Silicon Department     
##  \_  o| \_ _  Software Entwicklung
##     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
## \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
## See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
##-----------------------------------------------------------------------------

.asm.o:
	phxass noexe $(AOPTS) $*.asm

##-------------------------------------------------------------------------------

SRC	= isp.asm
HDR	= isp.i isp_debug.i AmigaISP_rev.i
OBJ	= isp.o
LIB	= lib:debug.lib lib:amiga.lib
EXE	= AmigaIsp
AOPTS	= ds dl SET "TESTCODE=1"


##-------------------------------------------------------------------------------

all: $(EXE).ld $(EXE).ro $(EXE)_test

$(EXE).ld : $(OBJ)
	slink from $(OBJ) to $(EXE).ld noicons addsym sc sd lib $(LIB)
	slink from $(EXE).ld to $(EXE) nd sc sd LIB $(LIB)

##-------------------------------------------------------------------------------


$(EXE).ro : $(OBJ)
	phxass $(SRC) to $(EXE).ro noexe

##-------------------------------------------------------------------------------

$(EXE)_test: isp_test.sa
	phxass ds noexe isp_test.sa
	slink with <<
	from lib:startup.o isp_test.o
	to $(EXE)_test addsym
	lib $(LIB) lib:sc.lib lib:startup_stubs.o
<

##-------------------------------------------------------------------------------

$(SRC): $(HDR) makefile

bump:
	bumprevision bump file AmigaIsp_rev.i noc

