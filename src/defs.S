
#define INCLUDE_ISP             // include the ISP package
#define PATCH_INSTALLFPSP       // patch installFPSP to reload ISP vectors
#define PATCH_ROMENTRY          // patch initial entry point to set up for 68060
#define PATCH_TMVECTORS_ISP     // patch tmVectors to point to ISP
#define PATCH_NORAMTEST         // no memory tests
#define PATCH_NOCHECKSUM        // no ROM checksum
#define PATCH_ROM_MAP_8MB       // map 8MB of ROM space. note 24 bit mode only has 1MB addr space
#define PATCH_SLOTMGR_BERR_HACK // assume any bus errors are slot manager's fault (TODO)
#define PATCH_FLUSHCRANGE       // cache flush hack (avoid ptestr) - TODO
//#define PATCH_BADDIVIDES      // ugly hack out the early 64/32 divides

#define INITIAL_PC 0x0000002A

#define vectUnimpInteger 0xF4
#define noErr 0	

.macro _SwapMMUMode
 .short 0xA05D
.endm

true32b=1
false32b=0
