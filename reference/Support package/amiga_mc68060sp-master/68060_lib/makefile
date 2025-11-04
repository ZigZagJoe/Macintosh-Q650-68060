##-----------------------------------------------------------------------------
##  /\    |\     Silicon Department     
##  \_  o| \_ _  Software Entwicklung
##     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
## \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
## See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
##-----------------------------------------------------------------------------

.asm.o:
	phxass noexe $*.asm ds dl

##-------------------------------------------------------------------------------

AOPTS=
COPTS=
LOPTS= width 128 height 64 hwidth 16 swidth 16 fwidth 16 pwidth 16

##-------------------------------------------------------------------------------


HDR =	mc60_system.i mc60_libbase.i mc60_macros.i

CHDR = mc60_libbase.h

SRC =	mc60_startup.asm   mc60_patches.asm   mc60_dispatcher.asm \
 	mc60_misc.asm mc60_tagstub.asm

CSRC = 	mc60_init.c mc60_mmu.c

OBJ = 	mc60_startup.o ispemu/AmigaISP.ro fpuemu/AmigaFPSP.ro \
 	mc60_init.o mc60_patches.o mc60_dispatcher.o \
 	mc60_mmu.o mc60_misc.o

LIB = lib:amiga.lib lib:debug.lib mc60_tagstub.o

##-------------------------------------------------------------------------------

all: 68040.library 68060.library

ispemu/isp.o: ispemu/isp.asm
        echo "stop - build isp"
	#set RC 10

fpuemu/fpsp.o: fpuemu/fpsp.asm
	echo "stop - build fpsp"
	#set RC 10

##-------------------------------------------------------------------------------

68040.library : mc40_loader.o
	slink with <<
	from mc40_loader.o	to 68040.library.ld
	lib $(LIB)      	map 68040.library.map hsxflo $(LOPTS)
	noicons sc sd verbose addsym
	<
	slink 68040.library.ld to 68040.library nd sc sd

##-------------------------------------------------------------------------------

68060.library : $(OBJ) mc60_tagstub.o
	slink with <<
	from $(OBJ)		to 68060.library.ld
	lib $(LIB) 		map 68060.library.map hsxflo $(LOPTS)
	addsym noicons sc sd noalvs
        <
	slink 68060.library.ld to 68060.library nd sc sd
##-------------------------------------------------------------------------------

bump40:
	bumprevision projectname mc40 bump

bump60:
	bumprevision projectname mc60 bump

##-------------------------------------------------------------------------------

$(SRC) : $(HDR)

$(CSRC) : $(CHDR)

##-------------------------------------------------------------------------------

