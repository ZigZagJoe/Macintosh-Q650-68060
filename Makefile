################
# config
################

# path to the retro68 toolchain
RETRO68_TOOLCHAIN=/home/zigzagjoe/Retro68-Build/toolchain

CC = ${RETRO68_TOOLCHAIN}/bin/m68k-apple-macos-gcc
LD = ${RETRO68_TOOLCHAIN}/bin/m68k-apple-macos-ld

CSRC = $(wildcard *.c)
ASRC = src/F1ACAD13.S

COMFLAGS = -c -march=68060 -mcpu=68060 -I ./src -I . ${BUILD_FLAGS}
ASFLAGS = ${COMFLAGS}
CFLAGS  = ${COMFLAGS} -O2 -mpcrel 

# output files 

COBJ = $(CSRC:%.c=obj/%.o)
SOBJ = $(ASRC:%.S=obj/%.o)

# ROM files
FULLROM = obj/Q650.ROM

# targets
all: ${FULLROM}

obj/%.o: %.S
	@mkdir -p $(@D)
	${CC} ${ASFLAGS} $< -o $@

obj/%.o: %.c
	@mkdir -p $(@D)
	${CC} ${CFLAGS} $< -o $@

${FULLROM}: linker.ld ${COBJ} ${SOBJ} 
# linker script must be first
	${LD} -o $@ -T $^ -Map $(FULLROM:%.ROM=%.map)
	@echo -n 'Binary size: '
	@stat -c %s $@ | sed 's/$$/ bytes/'
	@grep ROMEND $(FULLROM:%.ROM=%.map)

clean:
	rm -rf ./obj

upload: ${FULLROM}
	powershell.exe "`/usr/bin/wslpath -w ./tool/Bin2UF2.ps1`" "`wslpath -w ./${FULLROM}`" -Outdir auto

listing: all
	#${CC} -c -march=68040 -mcpu=68040 -I ./include -I .  F1ACAD13.S -fverbose-asm -S > obj/F1ACAD13.S 
	${RETRO68_TOOLCHAIN}/bin/m68k-apple-macos-objdump -d obj/Q650.ROM -b binary -m m68k:68060 -D > obj/listing.txt
	