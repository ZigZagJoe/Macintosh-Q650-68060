/* ################################################################################
ROM build configuration */

#define PROC_686060             // build for 060, comment to disable 060 modifications 

/* Generic features for 040/060 */
#define DISABLE_RAMTEST         // no memory tests
#define DISABLE_CHECKSUM        // no ROM checksum
#define PATCH_ROM_MAP_8MB       // map 8MB of ROM space. note: 24 bit mode only has 1MB addr space still!
//#define PATCH_FORCE_32BIT     // force booting in 32 bit mode always
    
/* DRAM Configuration */
//#define PATCH_BIGSIMMS_HACK    // allow sizing 64/128MB simms, but may fail to size <64mb simms
//#define PATCH_DRAM_SIMMONLY      // disable onboard RAM
//#define FORCE_DRAM_TIMINGS       // override djmemc configuration based on values below instead of resistors
//#define DRAM_TIMINGS_SPEEDBUMP   // use speedbump timing table for 80ns RAM instead of 60ns
//#define DRAM_TIMINGS_CPUSPEED 2  // specify timing table index. 0 = 20, 1 = 25, 2 = 33, 4 = 40. undefine to use strap resistor as usual     
//#define DRAM_TIMINGS_CUSTOM     // overrides timings per values below. ignores other DRAM_TIMINGS_ settings
//                       09876543210   
TIMING_DJCONFIG = 0b0000000100000011    /* 33mhz RAM OC: fastwr=1, romspeed=3 */
//TIMING_DJCONFIG = 0b0000000000001100  /* 40mhz RAM OC: drpw=1, romspeed=4 */
TIMING_BIOSTIMEOUT = 0x00D5 /* 33 */
TIMING_BIOSCFG = 0          /* 33 */
TIMING_DJREFRESH = 0x01E7   /* 33 */

#ifdef PROC_686060                  // these patches will cause an 040 to not work
    /* PATCHES */
    #define PATCH_ROMENTRY          // initialize 68060 PCR 
    #define PATCH_INSTALLFPSP       // patch installFPSP to install 060SP vectors
    //#define PATCH_FLUSHCRANGE       // (TODO??) cache flush, replace ptest
    #define PATCH_FLUSHCRANGE_HACK    // cache flush, flush all caches
    #define PATCH_SANE_FLUSHIT      // SANE cache flush, replace ptest
    #define PATCH_ENABLECACHES      // initialize 060 caches specifically
    #define REPLACE_040FPSP         // replace 040FPSP with ISP and addcode

    /* FEATURES */
    #define INSTALL_ISP             // include the ISP and patch TMVectors
    #define DISABLE_LOADSTOREBYPASS // rev5 and below require this per errata I14
    #define DISABLE_FPU             // disable 68060 FPU and patch the Quadra 650 table, overrides installFPSP
    #define ENABLE_LOADSTORE_FIFO   // enable load store FIFO
    #define ENABLE_SUPERSCALAR      // enable pentium-like superscalar execution
    #define ENABLE_BRANCH_CACHE     // enable branch prediction cache and install new bus error handler

    /* TODOs / Unproven */
    //#define INSTALL_FPSP            // install the FPSP and enable FPU. (TODO-Not fully working)
    #define PATCH_SLOTMGR_BERR_HACK // during slot manager, assume any bus errors are slot manager's fault (TODO)
    //#define CPUSH_NO_INVALIDATE     // CPUSH'd lines remain valid in cache. no performance impact/improvement seen
    //#define LATE_ENABLE_FPU         // enable FPU late in boot, for netbsd/etc. may cause issues with some mac os apps
#endif /* PROC_686060 */

/* DEBUGGING */
//#define ENABLE_SERIAL_DEBUG     // enable serial debugging over modem port
//#define TRACE_SP_MEM          // log SP memory accesses
//#define TRACE_ISP             // log ISP calls
//#define TRACE_FPSP              // log FPSP calls
#define SERIAL_BAUD_57600       // use 57600 baud, otherwise 9600 is used
//#define DEBUG_VBLTASK         // calls DebugVBLTask 60 times per second...

/* MISC */
//#define PATCH_BADDIVIDES          // ugly hack out the early 64/32 divides in sound routine

/* OLD hacks, no longer needed and can be removed */
//#define PATCH_SANE_FLUSHIT_HACK   // cache flush hack in SANE flushit just flush all caches
