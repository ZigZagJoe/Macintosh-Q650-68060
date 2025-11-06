/* Tested patches */
#define INSTALL_ISP             // include the ISP
#define PATCH_INSTALLFPSP       // patch installFPSP to install SP vectors
#define PATCH_TMVECTORS_ISP     // patch tmVectors (test manager ROM vectors) to point to ISP
#define PATCH_NORAMTEST         // no memory tests
#define PATCH_NOCHECKSUM        // no ROM checksum
#define PATCH_ROM_MAP_8MB       // map 8MB of ROM space. note 24 bit mode only has 1MB addr space still!
#define PATCH_FLUSHCRANGE       // cache flush replace ptest correctly
#define PATCH_SANE_FLUSHIT      // sane cache flush replace ptest correctly
#define ENABLE_SUPERSCALAR      // enable pentium-like superscalar execution
#define PATCH_FORCE_32BIT       // always run in 32 bit mode as known issues will prevent 24 bit mode
#define PATCH_060CACHE          // initialize 060 caches specifically (required for branch, loadstore)

/* TODOs / Unproven */
#define PATCH_ROMENTRY          // disable 68060 FPU initially. NOTE: this will prevent an 040 from booting! 
#define INSTALL_FPSP            // install the FPSP and vectors and enable FPU. (TODO-Not fully working)
//#define ENABLE_BRANCH_CACHE     // enable branch prediction cache  (TODO, will break things)
//#define ENABLE_LOADSTORE_FIFO   // enable load store FIFO (unproven), don't use on rev5 and earlier due to errata
#define PATCH_SLOTMGR_BERR_HACK // during slot manager, assume any bus errors are slot manager's fault (TODO)

/* OLD hacks, no longer needed */
//#define PATCH_SANE_FLUSHIT_HACK   // cache flush hack in SANE flushit just flush all caches
//#define PATCH_BADDIVIDES          // ugly hack out the early 64/32 divides in sound stuff
//#define PATCH_FLUSHCRANGE_HACK    // cache flush hack just flush all caches
//#define PATCH_NOTESTFORFPU        // do not test for FPU in testforFPU

/* constants */

#define INITIAL_PC 0x0000002A

#define	VECI_ACCERR		    0x08	/* Access Error AKA Bus Error */
#define	VECI_LINE1111		0x2C	/* Line 1111 Emulator */
#define	VECI_FP_BSUN		0xC0	/* FPCP Branch or Set on Unordered */
#define	VECI_FP_INEX		0xC4	/* FPCP Inexact Result */
#define	VECI_FP_DZ		    0xC8	/* FPCP Divide by Zero */
#define	VECI_FP_UNFL		0xCC	/* FPCP Underflow */
#define	VECI_FP_OPERR		0xD0	/* FPCP Operand Error */
#define	VECI_FP_OVFL		0xD4	/* FPCP Overflow */
#define	VECI_FP_SNAN		0xD8	/* FPCP Signalling NaN */
#define	VECI_UNIMP_FP_DATA	0xDC	/* FP Unimplemented Data Type */
#define	VECI_UNIMP_EA		0xF0	/* Unimplemented Effective Address */
#define	VECI_UNIMP_II		0xF4	/* Unimplemented Integer Instruction */

/* sp entry points */
_060_isp_unimp=(I_CALL_TOP+0x80+0x00) /* unimplemented integer */
_060_fpsp_snan=(FP_CALL_TOP+0x80+0x00) /* signalling not a number */
_060_fpsp_operr=(FP_CALL_TOP+0x80+0x08) /* FP Operand Error */
_060_fpsp_ovfl=(FP_CALL_TOP+0x80+0x10) /* overflow */
_060_fpsp_unfl=(FP_CALL_TOP+0x80+0x18) /* underflow */
_060_fpsp_dz=(FP_CALL_TOP+0x80+0x20) /* FP DZ (/0) exception. */
_060_fpsp_inex=(FP_CALL_TOP+0x80+0x28) /* FP Inexact exception */
_060_fpsp_fline=(FP_CALL_TOP+0x80+0x30) /* "Line F emulator", handles bsun, unimpl, etc */
_060_fpsp_unsupp=(FP_CALL_TOP+0x80+0x38) /* Unimplemented Data Type" exception */
_060_fpsp_effadd=(FP_CALL_TOP+0x80+0x40) /* unimplemented effective address */

| SANE vector stuff
| fpPriv
| almost certainly TODO.
| https://github.com/elliotnunn/supermario/blob/9dd3c4bef84df2ea30f5ec2c5e97b043e8267b3f/base/SuperMarioProj.1994-02-09/Toolbox/InSANE/FPPrivTrap.a#L216
| FLINE exception vector for system  <1/03/91, JPO>
FLINE_VEC040	=	0x1FC8
FPBSUN_VEC040	=	0x1FCC
FPUNFL_VEC040	=	0x1FD0
FPOPERR_VEC040	=	0x1FD4
FPOVFL_VEC040	=	0x1FD8
FPSNAN_VEC040	=	0x1FDC

noErr = 0	

 /* defaults for 32 bit */
MMFlagsDefault	=       0x25 /* (1<<mmFigEnable) | (1<<MMSysheap) | (1<<MMStartMode) */
MMPRAMloc       =       0x0001008A

/* CACR bits for 060 */
#define CACR060_EDC     31  /* 1=enable data cache */
#define CACR060_NAD     30  /* 1=misses don't allocate */
#define CACR060_ESB     29  /* 1=enable store buffer: DANGEROUS on <rev6 */
#define CACR060_DPI     28  /* 1=cpush doesn't invalidate */
#define CACR060_FOC     27  /* 1=half data cache mode */
#define CACR060_EBC     23  /* 1=enable branch cache */
#define CACR060_CABC    22  /* 1=clear branch cache */
#define CACR060_CUBC    21  /* 1=clear user branch cache only */
#define CACR060_EIC     15  /* 1=enable instruction cache */
#define CACR060_NAI     14  /* 1=misses don't allocate */
#define CACR060_FIC     13  /* 1=half inst cache mode */

/* memory location for old access handler (long) */
Old_AccessFault=0x40
