OUTPUT_FORMAT("binary");
ENTRY(BASEOFROM);

MEMORY {
  ROM (rx)  : ORIGIN = 0x40800000, LENGTH = 8M
}

SECTIONS {
  /DISCARD/ : { 
    *(.comment) 
  }

 .text : SUBALIGN (4) {
    *F1ACAD13.o (.text)
 } > ROM

  /DISCARD/ : { *(*) }
}

#ASSERT((ROMEND - BASEOFROM) == 0x100000,"ROM Length Incorrect")