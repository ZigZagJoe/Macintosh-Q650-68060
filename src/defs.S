/* ################################################################################
ROM definitions
*/

#include "config.S"

/* Config sanity checks */
#ifdef DISABLE_FPU
    #undef INSTALL_FPSP     // no FPSP if we disable the FPU
#endif

#if !defined(DISABLE_FPU) && !defined(INSTALL_FPSP) && defined(PROC_686060)
    #warning "FPU not disabled but FPSP not installed"
#endif

#if !defined(FORCE_DRAM_TIMINGS) && (defined(DRAM_TIMINGS_SPEEDBUMP) || defined(DRAM_TIMINGS_CPUSPEED))
    #warning Ignoring DRAM_TIMINGS_SPEEDBUMP and DRAM_TIMINGS_CPUSPEED as FORCE_DRAM_TIMINGS is undefined
#endif

#if defined(SP_MEM_TRACE) || defined(TRACE_ISP) || defined(TRACE_FPSP)
    #ifndef ENABLE_SERIAL_DEBUG
        #error Must define ENABLE_SERIAL_DEBUG to trace
    #endif
    #if defined(SP_MEM_TRACE) || defined(TRACE_ISP) 
        #define PATCH_BADDIVIDES   // will cause ISP logs before serial is ready
    #endif
#endif

#if defined(INSTALL_FPSP) && !defined(PATCH_FORCE_32BIT)
    #define PATCH_FORCE_32BIT
    #warning "PATCH_FORCE_32BIT forced due to FPSP length"
#endif

#if defined(INSTALL_ISP) && !defined(PATCH_FORCE_32BIT) && !defined(REPLACE_040FPSP) 
    #define PATCH_FORCE_32BIT
    #warning "PATCH_FORCE_32BIT forced due to ISP"
#endif

#if defined(ENABLE_SUPERSCALAR) || defined(ENABLE_BRANCH_CACHE)
    #define PATCH_LATEINIT
#endif

#if defined (DRAM_TIMINGS_CUSTOM) && !defined(FORCE_DRAM_TIMINGS)
    #warning DRAM_TIMINGS_CUSTOM forces FORCE_DRAM_TIMINGS
    #define FORCE_DRAM_TIMINGS
#endif

#if defined(DRAM_TIMINGS_CUSTOM) && (defined(DRAM_TIMINGS_SPEEDBUMP) || defined(DRAM_TIMINGS_CPUSPEED))
    #warning DRAM_TIMINGS_CUSTOM overrides DRAM_TIMINGS_CPUSPEED / DRAM_TIMINGS_SPEEDBUMP
    #undef DRAM_TIMINGS_SPEEDBUMP
    #undef DRAM_TIMINGS_CPUSPEED
    #define DRAM_TIMINGS_CPUSPEED 0
#elif defined(DRAM_TIMINGS_CUSTOM)
    #define DRAM_TIMINGS_CPUSPEED 0
#endif

/* Preproc Macros */
#define xpandstr(s) str(s)
#define str(s) #s

/* ################################################################################ 
| constants */
/* vector table (partial) */
#define	VECI_ACCERR		    0x08	/* Access Error AKA Bus Error */
#define VECI_ADDRERR        0x0C
#define VECI_ILLEGAL        0x10
#define VECI_DIV0           0x14
#define VECI_CHK            0x18
#define VECI_TRAP           0x1C
#define VECI_PRIV           0x20
#define VECI_TRACE          0x24
#define VECI_LINE1010       0x28
#define	VECI_LINE1111		0x2C	/* Line 1111 Emulator */
/* ... */
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

/* helper macro to get us to a vector based off VBR */
.macro RTS_TO_VECTOR vec
    clr.l -(%sp)            | allocate space for the address
    move.l %a0, -(%sp)      | save %a0
    movec %vbr, %a0         | get vbr
    move.l \vec(%a0), 4(%sp)| retrieve vector with offset from VBR and store it in the space
    move.l (%sp)+, %a0      | restore %a0
    rts                     | ... and go to the vector 
.endm

#define TimeVIADB 		0x0CEA

/* CACR bits for 060 */
#define CACR060_EDC     31  /* 1=enable data cache */
#define CACR060_NAD     30  /* 1=misses don't allocate */
#define CACR060_ESB     29  /* 1=enable store buffer */
#define CACR060_DPI     28  /* 1=cpush doesn't invalidate */
#define CACR060_FOC     27  /* 1=half data cache mode */
#define CACR060_EBC     23  /* 1=enable branch cache */
#define CACR060_CABC    22  /* 1=clear branch cache */
#define CACR060_CUBC    21  /* 1=clear user branch cache only */
#define CACR060_EIC     15  /* 1=enable instruction cache */
#define CACR060_NAI     14  /* 1=misses don't allocate */
#define CACR060_FIC     13  /* 1=half inst cache mode */

/* ################################################################################
| APPLE CONSTANTS */

 /* defaults for 32 bit https://github.com/elliotnunn/sys7.1-doc-wip/blob/62f7e0d5dc1d9a047822d5e73ffa8aa50a97e3fa/Internal/Asm/InternalOnlyEqu.a#L205 */
#define MMFlagsDefault  0x25    /* 0b100101 0x25 = (1<<mmFigEnable) | (1<<MMSysheap) | (1<<MMStartMode) */
#define MMPRAMloc       0x8A    /* xpram */
#define MMFlags_Write   0x8001008A 
/* #(1<<31)|\			; write													
	(1<<16)|\			; 1 byte from %A3										
	(MMPRAMloc<<0)		; starting at PRAM address MMPRAMloc*/

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

/* ################################################################################
| patch macros to allow putting our code in place and padding it to a constant length */

/* define the start of a patch section */
.macro .patchStart
9:
.endm

/* define the end of a patch section and pad it to length with NOPs or another word 
| all branches must use explicit lengths or you get "non-constant expression" as the opcode size 
| won't be known until link time */
.macro .patchEnd lengthBytes fill=0x4e71
    .ifgt \lengthBytes % 2
        .error "Padding \lengthBytes is not divisible by 2"
    .endif

    .iflt (\lengthBytes - (. - 9b))
        .error "Patch overflowed max length of \lengthBytes"
    .endif

    .ifgt (\lengthBytes - (. - 9b)) % 2
        .error "Patch contains unaligned code (data?)"
    .endif

    .ifgt (\lengthBytes - (. - 9b))
        .fill (\lengthBytes - (. - 9b)) / 2, 2, \fill
    .endif
.endm

/* just fill with nops */
.macro .nopFill length 
    .ifgt \length % 2
        .error "Padding \length is not divisible by 2"
    .endif

    .fill \length / 2, 2, 0x4e71
.endm

/* ################################################################################
| Serial constant macros for debugging. */
.macro INIT_SERIAL
#ifdef ENABLE_SERIAL_DEBUG
    jsr InitSerialFunc
#endif
.endm

.macro PUT_CHAR ch
#ifdef ENABLE_SERIAL_DEBUG
	move.b	#0x30,(aCtl)	|reset any errors			
	move.b	#\ch,(aData)	|send character			

1:			                |wait until all sent 		
	move.b	#1,(aCtl)		|select RR1			
	
	btst	#0,(aCtl)		|All Sent?			
	beq.s	1b
#endif
.endm
		
.macro PUT_STRING str 
#ifdef ENABLE_SERIAL_DEBUG
    move.l %a0, -(%sp)
    lea (1f, %pc), %a0
    jsr _puts
    bra 2f
1:
    .string "\str"
    .align 2
2:
    move.l (%sp)+,%a0
#endif
.endm

.macro DBG_TRACE_MEM arg
#ifdef TRACE_SP_MEM
    PUT_STRING \arg
#endif
.endm

.macro DBG_TRACE_ISP arg
#ifdef TRACE_ISP
    PUT_STRING \arg
#endif
.endm

.macro DBG_TRACE_FPSP arg
#ifdef TRACE_FPSP
    PUT_STRING \arg
#endif
.endm