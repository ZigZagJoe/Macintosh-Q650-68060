/* ################################################################################
ROM configuration
*/

/* patches */
#define PATCH_ROMENTRY          // initialize 68060 PCR. NOTE: this will prevent an 040 from booting! 
#define PATCH_INSTALLFPSP       // patch installFPSP to install SP vectors
#define PATCH_FLUSHCRANGE       // cache flush, replace ptest
#define PATCH_SANE_FLUSHIT      // SANE cache flush, replace ptest
#define PATCH_ENABLECACHES      // initialize 060 caches specifically (required for branch, loadstore fifo)
#define PATCH_LATEINIT          // replace SetupDockBases with LateInit
#define PATCH_ROM_MAP_8MB       // map 8MB of ROM space. note: 24 bit mode only has 1MB addr space still!
#define PATCH_FORCE_32BIT       // always run in 32 bit mode as 24 bit mode can't work ROM >1MB

/* features */
#define INSTALL_ISP             // include the ISP and patch TMVectors
#define DISABLE_RAMTEST         // no memory tests
#define DISABLE_CHECKSUM        // no ROM checksum
#define DISABLE_LOADSTOREBYPASS // rev5 and below require this per errata I14
#define DISABLE_FPU             // disable 68060 FPU and patch the Quadra 650 table, overrides installFPSP
#define ENABLE_LOADSTORE_FIFO   // enable load store FIFO
#define ENABLE_SUPERSCALAR      // enable pentium-like superscalar execution
#define ENABLE_BRANCH_CACHE     // enable branch prediction cache and install new bus error handler

/* TODOs / Unproven */
#define INSTALL_FPSP            // install the FPSP and enable FPU. (TODO-Not fully working)
#define PATCH_SLOTMGR_BERR_HACK // during slot manager, assume any bus errors are slot manager's fault (TODO)
#define CPUSH_NO_INVALIDATE     // CPUSH'd lines remain valid in cache. no performance impact/improvement seen

/* DEBUGGING */
//#define ENABLE_SERIAL_DEBUG     // enable serial debugging over modem port
//#define TRACE_SP_MEM          // log SP memory accesses
//#define TRACE_ISP             // log ISP calls
//#define TRACE_FPSP            // log FPSP calls
#define SERIAL_BAUD_57600       // use 57600 baud, otherwise 9600 is used

/* OLD hacks, no longer needed and can be removed */
//#define PATCH_SANE_FLUSHIT_HACK   // cache flush hack in SANE flushit just flush all caches
//#define PATCH_BADDIVIDES          // ugly hack out the early 64/32 divides in sound stuff
//#define PATCH_FLUSHCRANGE_HACK    // cache flush hack just flush all caches
