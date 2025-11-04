**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

	machine	68060
	near

	include	"mc60_system.i"
	include	"mc60_libbase.i"
	include	"devices/input.i"

**-------------------------------------------------------------------------------

	XDEF	_MMUFrame

**-------------------------------------------------------------------------------

	section          patches,code

CALLSYS	MACRO
	jsr	(_LVO\1,A6)
	ENDM

ARP_FIX	= 	0

**-------------------------------------------------------------------------------
*<	a5 = LibBase
*<	a6 = SysBase

MYDEBUG	SET              0
DEBUG_DETAIL 	set 	10

	XDEF	_PatchExec
_PatchExec:
	MOVEM.L	D0-D7/A0-A6,-(SP)

*-------------------------------------------------------------------------------------------------------------
*
*   The  following  patches  are  made  by  68040.library in order to help keep software working.  The
*   descriptions  and  the code to the patch are given here, however the code is not 100% complete and
*   requires  that  the  programmer put this into the correct places in the CPU library initialization
*   code, after the correct checks as to if the library should initialize.
*
*   Note  that  on  the CachePreDMA and CachePostDMA patches, these functions were design specifically
*   for  this  purpose (along with virtual memory mapping, which I did not have the chance to complete
*   before Commodore started to fall to pieces.)
*
*   Note  also  that the CachePreDMA/CachePostDMA patches are those that are described in the COPYBACK
*   mode and DMA link.
*
*-------------------------------------------------------------------------------------------------------------
*   Taken from 68040.library - Thanx to Michael Sinz for Code
*-------------------------------------------------------------------------------------------------------------

	* CachePreDMA
	*
	* This adds the special patch to make 68040 and DMA devices
	* work with CopyBack modes turned on...

	DBUG    10,'\t\tInstalling CachePreDMA() patch\n'
	lea     NewCachePreDMA(pc),a0
	move.l  a0,d0                   ; Get pointer to new routine
	move.l  a6,a1                   ; Get library to be patched
	move.w  #_LVOCachePreDMA,a0     ; Get LVO offset...
	CALLSYS SetFunction             ; Install new code...

	* CachePostDMA
	*
	* This adds the special patch to make 68040 and DMA devices
	* work with CopyBack modes turned on...

	DBUG    10,'\t\tInstalling CachePostDMA() patch\n'
	lea     NewCachePostDMA(pc),a0
	move.l  a0,d0                   ; Get pointer to new routine
	move.l  a6,a1                   ; Get library to be patched
	move.w  #_LVOCachePostDMA,a0    ; Get LVO offset...
	CALLSYS SetFunction             ; Install new code...

	* CacheControl
	*
	* It fixes the return values from CacheControl to correctly return
	* the BURST ENABLE bit if the cache bit is on.  (68040 bursts all
	* caches)  It also deals with the cache settings vs DMA.

       	DBUG    10,'\t\tInstalling CacheControl() patch\n'
       	lea     NewCacheControl(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOCacheControl,a0    ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...

 	* AddLibrary
                        *
	* This fixes programs/libraries that do not use
	* MakeLibrary() to generate the library structure.

       	DBUG    10,'\t\tInstalling AddLibrary() patch\n'
	lea     NewAddLibrary(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOAddLibrary,a0      ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldAddLibrary(pc),a0    ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* CloseLibrary

	* This fixes arp.library on 68040 machines since it
	* places some code onto the stack and then runs it to close
	* a library...

	IFNE    ARP_FIX
       	DBUG    10,'\t\tInstalling CloseLibrary() patch\n'>
	lea     NewCloseLibrary(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOCloseLibrary,a0    ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldCloseLibrary(pc),a0  ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...
       	ENDC

	* AddDevice

	* This fixes programs/libraries that do not use
	* MakeLibrary() to generate the library structure.

       	DBUG    10,'\t\tInstalling AddDevice() patch\n'
       	lea     NewAddDevice(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOAddDevice,a0       ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldAddDevice(pc),a0     ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* AddResource

	* This fixes programs/libraries that do not use
	* CacheClearU() after generating the resource.

       	DBUG    10,'\t\tInstalling AddResource() patch\n'
       	lea     NewAddResource(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOAddResource,a0     ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldAddResource(pc),a0   ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* AddTask

	* This fixes programs that install the code into memory
	* without flushing the caches.  This happens to also fix
	* the most common problem like this:  Fake seglist generation
	* for calls to CreateProc()  (A trick needed in pre-2.0 days)

       	DBUG   10,'\t\tInstalling AddTask() patch\n'
	lea     NewAddTask(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOAddTask,a0         ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldAddTask(pc),a0       ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* AddIntServer

	* Once again, people had generated code that was then
	* installed as a server for the interrupts.  This should
	* be a very minor hit since very few call AddIntServer()

       	DBUG    10,'\t\tInstalling AddIntServer() patch\n'
       	lea     NewAddIntServer(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOAddIntServer,a0    ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldAddIntServer(pc),a0  ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* SetIntVector

	* Same issues as AddIntServer above...

       	DBUG    10,'\t\tInstalling SetIntVector() patch\n'
       	lea     NewSetIntVector(pc),a0
       	move.l  a0,d0                   ; Get pointer to new routine
       	move.l  a6,a1                   ; Get library to be patched
       	move.w  #_LVOSetIntVector,a0    ; Get LVO offset...
       	CALLSYS SetFunction             ; Install new code...
       	lea     OldSetIntVector(pc),a0  ; Get storage slot...
       	move.l  d0,(a0)                 ; Save old code address...

	* Now, patch input.device so that a IND_ADDHANDLER will flush
	* the caches.  (Arg!  But this is a big payoff)
 	* First, we need to find input.device on the list

                        DBUG    10,'\t\tInstalling input.device/IND_ADDHANDLER patch\n'
       	lea     DeviceList(a6),a0       ; Get list structure
       	lea     InputName(pc),a1        ; Get input.device string
       	CALLSYS FindName                ; Find it on the list
       	move.l  d0,a1                   ; This is the device we patch
       	tst.l   d0                      ; Check if NULL
       	beq.s   NoINDPatch              ; If NULL, no Patch...

	* We patch BeginIO in input.device to check for ADDHANDLER
	* as the command.  Since many tools copy up code for use as
	* input handlers and just ADDHANDLER them, this will fix
	* all of those caching issues.

	lea     NewBeginIO(pc),a0       ; Get new code
       	move.l  a0,d0                   ; address for SetPatch...
       	move.w  #DEV_BEGINIO,a0         ; LVO offset for BeginIO...
       	CALLSYS SetFunction             ; Install it...
       	lea     OldBeginIO(pc),a0       ; Save old code address
       	move.l  d0,(a0)                 ; ...for the patch.
NoINDPatch:
	*-----------------------------------------------------------------------------
	* fixed for proper code on Aztec C startup with FPU

                        DBUG    10,'\t\tInstalling supervisor patch\n'
	LEA	(OldSupervisor,PC),A0
	move.l	(_LVOSupervisor+2,A6),(a0)	; save old destination
	LEA	(NewSupervisor,PC),A0
	move.l	a0,(_LVOSupervisor+2,A6)	; set new destination

*	LEA	(NewSupervisor,PC),A0
*	MOVE.L	A0,d0
*	MOVE.L	a6,a1
*	MOVE.W	#_LVOSupervisor,a0
*	JSR	(_LVOSetFunction,A6)
*	LEA	(OldSupervisor,PC),A0
*	MOVE.L	D0,(A0)


	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS



******************************************************************************

InputName:	dc.b	'input.device',0
	even

******************************************************************************
*
* This is the MMU frame.  NULL on systems without MMU setup.

_MMUFrame:	dc.l	0
	even

******************************************************************************
*
* AddLibrary patch code
*
OldAddLibrary:          dc.l    0                       ; Storage for old
NewAddLibrary:          move.l  OldAddLibrary(pc),-(sp) ; Set so RTS to old code
                	move.l  a1,-(sp)                ; Only A1 is needed...
                	CALLSYS CacheClearU             ; Clear the caches
                	move.l  (sp)+,a1                ; Restore
                	rts
*
******************************************************************************
*
        IFNE    ARP_FIX
*
* CloseLibrary patch code
*
OldCloseLibrary:       	dc.l    0                       ; Storage for old
NewCloseLibrary:       	move.l  OldCloseLibrary(pc),-(sp)       ; Set so RTS to old
                	move.l  a1,-(sp)                ; Only A1 is needed...
                	CALLSYS CacheClearU             ; Clear the caches
                	move.l  (sp)+,a1                ; Restore
                	rts
*
        ENDC
*
******************************************************************************
*
* AddDevice patch code
*
OldAddDevice:   	dc.l    0                       ; Storage for old
NewAddDevice:   	move.l  OldAddDevice(pc),-(sp)  ; Set so RTS to old code
                	move.l  a1,-(sp)                ; Only A1 is needed...
                	CALLSYS CacheClearU             ; Clear the caches
                	move.l  (sp)+,a1                ; Restore
                	rts
*
******************************************************************************
*
* AddResource patch code
*
OldAddResource:	 dc.l    0                       ; Storage for old
NewAddResource:	 move.l  OldAddResource(pc),-(sp) ;Set so RTS to old code
               	 move.l  a1,-(sp)                ; Only A1 is needed...
               	 CALLSYS CacheClearU             ; Clear the caches
               	 move.l  (sp)+,a1                ; Restore
               	 rts
*
******************************************************************************
*
* AddTask patch code
*
OldAddTask:     	dc.l    0                       ; Storage for old
NewAddTask:     	pea     .patchstack(pc)         ;
                	move.l  OldAddTask(pc),-(sp)    ; Set so RTS to old code
                	move.l  a1,-(sp)                ; Only A1 is needed...
                	CALLSYS Forbid                  ; No one may disturb now.
                	CALLSYS CacheClearU             ; Clear the caches
                	move.l  (sp)+,a1                ; Restore a1
                	rts

.patchstack:	movem.l	A1/A5,-(SP)	; Back from System Call
	tst.l	D0
	beq	.noaddr	; check for valid TaskStruct Addr..

	movea.l	D0,A1          	; Task Struct
	MOVEA.L	(TC_SPREG,A1),A5	; Ok, get Task Stack
	CLR.L	-(A5)                  ; and complete Nullframe to
	CLR.L	-(A5)                  ; three longs for 68060
	MOVE.L	A5,(TC_SPREG,A1)	; Now the ex_Launchpoint is happy :-)

.noaddr:	JSR	(_LVOPermit,A6)	; Go on system.
	MOVEM.L	(SP)+,A1/A5
	RTS

*
******************************************************************************
*
* AddIntServer patch code
*
OldAddIntServer:      	dc.l    0                       ; Storage for old
NewAddIntServer:       	move.l  OldAddIntServer(pc),-(sp)       ; Set so RTS to old code
                	movem.l d0/a1,-(sp)             ; Only D0/A1 are needed...
                	CALLSYS CacheClearU             ; Clear the caches
                	movem.l (sp)+,d0/a1             ; Restore a1
                	rts
*
******************************************************************************
*
* SetIntVector patch code
*
OldSetIntVector:
                dc.l    0                       ; Storage for old
NewSetIntVector:
                move.l  OldSetIntVector(pc),-(sp)       ; Set so RTS to old code
                movem.l d0/a1,-(sp)             ; Only D0/A1 are needed...
                CALLSYS CacheClearU             ; Clear the caches
                movem.l (sp)+,d0/a1             ; Restore a1
                rts
*
******************************************************************************
*
* input.device BeginIO patch code to trap/flush on IND_ADDHANDLER
*
OldBeginIO:     dc.l    0                       ; Storage for old
NewBeginIO:     move.l  OldBeginIO(pc),-(sp)    ; Set so RTS to old code
                ; Now, check if it is IND_ADDHANDLER
                cmp.w   #IND_ADDHANDLER,IO_COMMAND(a1)
                bne.s   Not_ADDHANDLER          ; If not ADDHANDLER, skip...
                movem.l a1/a6,-(sp)             ; save these
                move.l  4.w,a6                  ; Get EXECBASE
                CALLSYS CacheClearU             ; Clear the caches
                movem.l (sp)+,a1/a6             ; Restore...
Not_ADDHANDLER: rts

******************************************************************************
*
* Patch stupid Aztec Startup
*
OldSupervisor:	dc.l	0
NewSupervisor:	CMPI.L	#$42A7F35F,(A5)
	BNE.B	.oldcode
	CMPI.W	#$4E73,(4,A5)
	BNE.B	.oldcode	; no op.
	DBUG	10,"### Patch: Aztek C FPU Startup Code\n",#0,#0
	RTS

.oldcode:
	DBUG	20,"### Old Supervisor()\n"
	MOVE.L	(OldSupervisor,PC),-(SP)
	RTS

******************************************************************************
*
*   NAME
*       CachePostDMA - Take actions after to hardware DMA  (V37)
*
*   SYNOPSIS
*       CachePostDMA(vaddress,&length,flags)
*                    a0       a1      d0
*
*       CachePostDMA(APTR,LONG *,ULONG);
*
*   FUNCTION
*       Take all appropriate steps after Direct Memory Access (DMA).  This
*       function is primarily intended for writers of DMA device drivers.  The
*       action will depend on the CPU type installed, caching modes, and the
*       state of any Memory Management Unit (MMU) activity.
*
*       As implemented
*               68000 - Do nothing
*               68010 - Do nothing
*               68020 - Do nothing
*               68030 - Flush the data cache
*               68040 - Flush matching areas of the data cache
*               ????? - External cache boards, Virtual Memory Systems, or
*                       future hardware may patch this vector to best emulate
*                       the intended behavior.
*                       With a Bus-Snooping CPU, this function my end up
*                       doing nothing.
*
*   INPUTS
*       address - Same as initially passed to CachePreDMA
*       length  - Same as initially passed to CachePreDMA
*       flags   - Values:
*                       DMA_NoModify - If the area was not modified (and
*                       thus there is no reason to flush the cache) set
*                       this bit.
*
*   SEE ALSO
*       exec/execbase.i, CachePreDMA, CacheClearU, CacheClearE
*
******************************************************************************
*
* Replace CachePostDMA to handle the 68040 CopyBack vs DMA problem...
*
* This is a real nasty problem:  We have to watch out for DMA to memory
* while the CPU is accessing memory within the same cache line.
* This all mixes in with the CacheControl function since what we
* will do is to have PreDMA turn off CopyBack mode and PostDMA
* turn it back on...  (only if needed as CacheControl() may have
* been called too...  arg!!!)  If we have an MMU we will play
* with the MMU tables...
*

NewCachePostDMA:
                	btst.l  #DMAB_ReadFromRAM,d0    ; Check if READ DMA
                	bne.s   dma_Caches              ; If so, skip...
                	move.l  a0,d1                   ; Get address...
                	or.l    (a1),d1                 ; or in length...
                	and.b   #$0F,d1                 ; Check for non-aligned...
                	beq.s   dma_Caches              ; Don't count if aligned...
	*
	* Now, we check if we can do the MMU trick...
	*
                	move.l  _MMUFrame(pc),d1         ; Get MMU frame
                	bne.s   On_MMU_Way              ; Do it the MMU way...
	*
                	lea     Nest_Count(pc),a1       ; We trash a1...
                	subq.l  #1,(a1)                 ; Subtract the nest count...
                	bra.s   dma_Caches              ; Do the DMA work...
	*
	* Ok, so we have an MMU and need to deal with turning on the pages
	*
On_MMU_Way:     	move.l  a0,-(sp)                ; (result, fake)
	move.l  a4,-(sp)                ; Save a4
                	lea     On_MMU_Page(pc),a4      ; Address of Cache ON code
                	bra.s   MMU_Way                 ; Do the common code...

******************************************************************************
*
*   NAME
*       CachePreDMA - Take actions prior to hardware DMA  (V37)
*
*   SYNOPSIS
*       paddress = CachePreDMA(vaddress,&length,flags)
*       d0                     a0       a1      d0
*
*       APTR CachePreDMA(APTR,LONG *,ULONG);
*
*
*   INPUTS
*       address - Base address to start the action.
*       length  - Pointer to a longword with a length.
*       flags   - Values:
*                       DMA_Continue - Indicates this call is to complete
*                       a prior request that was broken up.
*
*   RESULTS
*       paddress- Physical address that coresponds to the input virtual
*                 address.
*       &length - This length value will be updated to reflect the contiguous
*                 length of physical memory present at paddress.  This may
*                 be smaller than the requested length.  To get the mapping
*                 for the next chunk of memory, call the function again with
*                 a new address, length, and the DMA_Continue flag.
*
******************************************************************************
*
* Replace CachePreDMA to handle the 68040 CopyBack vs DMA problem...
*

NewCachePreDMA:
                	btst.l  #DMAB_Continue,d0       ; Check if we are continue mode
                	bne.s   ncp_Continue            ; Skip the Continue case...
                	btst.l  #DMAB_ReadFromRAM,d0    ; Check if READ DMA
                	bne.s   ncp_Continue            ; Skip if read...
                	move.l  a0,d1                   ; Get address...
                	or.l    (a1),d1                 ; or in length...
                	and.b   #$0F,d1                 ; Check of non-alignment
                	beq.s   ncp_Continue            ; Don't count if aligned

	* Now, we check if we can do the MMU trick...

                	move.l  _MMUFrame(pc),d1         ; Get MMU frame...
                	bne.s   Off_MMU_Way             ; If so, do MMU way...

                	lea     Nest_Count(pc),a1       ; Get a1...
                	addq.l  #1,(a1)                 ; Nest this...
ncp_Continue:   	move.l  a0,d0                   ; Get result...
dma_Caches:     	move.l  d0,-(sp)                ; Save result...
ncp_DoWork:     	moveq.l #0,d0                   ; Clear bits
                	moveq.l #0,d1                   ; Clear mask
                	bsr.s   NewCacheControl         ; Do the cache setting/clear
                	move.l  (sp)+,d0                ; Restore d0
                	rts                             ; Return...

	* Ok, so we have an MMU and need to deal with turning off the pages
	* given...

Off_MMU_Way:    	move.l  a0,-(sp)                ; Save result
                	move.l  a4,-(sp)                ; Save a4
                	lea     Off_MMU_Page(pc),a4     ; Address of Cache OFF code

MMU_Way:        	move.l  a5,-(sp)                ; Save a5
                	lea     Do_MMU_Way(pc),a5       ; Get addres of code
                	CALLSYS Supervisor              ; Do it...
                	move.l  (sp)+,a5                ; Restore a5
                	move.l  (sp)+,a4                ; Restore a4
                	bra.s   ncp_DoWork              ; Return with result on stack


******************************************************************************
*
*   NAME
*       CacheControl - Instruction & data cache control
*
*   SYNOPSIS
*       oldBits = CacheControl(cacheBits,cacheMask)
*       D0                     D0        D1
*
******************************************************************************

	* This new cache control completely replaces the ROM version.
	* There is no reason to support the other chips here.
	* If there was an external cache, it would be handled here...

NewCacheControl:        movem.l d2-d4,-(sp)     ; Save...
                        and.l   d1,d0           ; Destroy irrelevant bits
                        not.l   d1              ; Change mask to preserve bits
                        move.l  a5,a1           ; Save a5...
                        lea.l   ncc_Sup(pc),a5  ; Code that runs in supervisor
                        CALLSYS Supervisor      ; Do it...
                        move.l  d3,d0           ; Set return value...
                        movem.l (sp)+,d2-d4     ; Restore...
                        rts                     ; Done...

	* Some storage for these features...

	cnop    0,4             ; Long align them...
Base_Cache:     	dc.l    0               ; Base cache settings...
Nest_Count:     	dc.l    0               ; Nest count of the cache...

	* d0-mask d1-bits d2-scratch d3-result
	* a1-Saved a5...

ncc_Sup:        	or.w    #$0700,SR       ;DISABLE
                	movec   CACR,d2         ; Get cache control register
                	move.l  #$80008000,d4   ; Keep Mask for 040/060 Cache Enable Bits (CACRF_040_ICache!CACRF_040_DCache)
                	and.l   d4,d2 ;!BIT ASUMPTIONS!

	*                ;10987654321098765432109876543210
	*                ;D000000000000000I000000000000000

                	swap    d2      	;I000000000000000D000000000000000 CACRF_040
                	ror.w   #8,d2   	;I00000000000000000000000D0000000 CACRF_040
                	rol.l   #1,d2   	;00000000000000000000000D0000000I CACRF_040

	* Add in the "ghost" cache setting...

                	or.l    Base_Cache(pc),d2       ; Base cache mode...

	* Now, set the burst modes too...  (040 always bursts the cache)

                	move.l  d2,d3           ; Move it over...
                	rol.l   #4,d3           ; Shift cache info into burst info
                	or.l    d3,d2           ; Store with the burst bits as needed

	* Mirror the Data Cache into the CopyBack bit...

                	btst.l  #CACRB_EnableD,d2
                	beq.s   ncc_NoCB        ; If no data cache, no copyback...
                	bset.l  #CACRB_CopyBack,d2
ncc_NoCB:       	move.l  d2,d3           ; Set result: old cache settings

	* Now, mask out what we want to change and change it...

                	and.l   d1,d2           ; Mask out what we want to change...
                	or.l    d0,d2           ; Change those...

	* Now store the "asked for" new setting in Base_Cache...

                	move.l  #CACRF_EnableD,d0       ; Get data cache...
                	and.l   d2,d0                   ; Mask it...
                	move.l  d0,Base_Cache-ncc_Sup(a5)       ; Store it...

	* Now, check if data cache should be off due to DMA...

                	tst.l   Nest_Count(pc)          ; Check for PreDMA nest
                	beq.s   ncc_Normal              ; If not, we just do it...
                	bclr.l  #CACRB_EnableD,d2       ; If set, we don't do DCache
ncc_Normal:
	* Now, take the 68030 settings and go back to 68040 settings...
	*
	*                ;10987654321098765432109876543210
	*                ;XXXXXXXXXXXXXXXXXXXXXXXDXXXXXXXI
                	ror.l   #1,d2   	;IXXXXXXXXXXXXXXXXXXXXXXXDXXXXXXX CACRF_040
                	rol.w   #8,d2    ;IXXXXXXXXXXXXXXXDXXXXXXXXXXXXXXX CACRF_040
                	swap    d2       ;DXXXXXXXXXXXXXXXIXXXXXXXXXXXXXXX CACRF_040

                	and.l   d4,d2 	;!BIT ASUMPTIONS!

	* All we need to do is play with the internal cache settings...

ncc_NoECache:
 	movec	CACR,D1	; Get other Flags
 	not.l	D4                     ; to CACR
 	and.l	D4,D1
 	or.l	D1,D2

   	nop                     ;68040 BUG KLUDGE. Mask 14D43B
                	cpusha  BC              ; Push data and instruction cache...
                	nop                     ;68040 BUG KLUDGE. Mask 14D43B
                	movec   d2,CACR         ; Set the new cache control reg bits
                	nop                     ;68040 BUG KLUDGE. Mask 14D43B
                	move.l  a1,a5           ; Restore a5...
                	rte                     ;rte restores SR
	*
	******************************************************************************
	*
	* The magic for MMU based Pre/PostDMA calls...
	*
	* This routine is the general page manager.  It will deal with the
	* start and end pages as needed.
	* Input:        a4 - Routine to manipulate the page
	*               d1 - MMU Frame
	*               a0 - Start address
	*               *a1- Size
	*               a5 - Scrap...
	*               d0 - SCrap...
	*               a6 - ExecBase
	*
Do_MMU_Way:     	move.l  d1,a5                   ; Get MMU Frame into a5...
                	move.l  a0,d0                   ; Get start address...
                	move.l  d0,-(sp)                ; Save start address...
                	add.l   (a1),d0                 ; Calculate end address...
                	bsr.s   Do_MMU_d0               ; d0 is address; do it...
                	move.l  (sp)+,d0                ; Get start again...
                	bsr.s   Do_MMU_d0               ; d0 is address; do it...
                	rte                             ; We be done...
	*
	* Ok, so now we are called as follows:
	*
	*       a6 - ExecBase
	*       a5 - MMU Frame pointer
	*       a4 - Routine to manipulate the page
	*       d0 - Address which needs protection
	*       d1 - Scrap
	*       a0 - Scrap
	*       a1 - Scrap
	*
	*       a0/a1/d0/d1 may all be trashed :-)
	*
Do_MMU_d0:      	moveq.l #$0F,d1                 ; Mask...
                	and.l   d0,d1                   ; Check for cache line address
                	beq.s   Do_MMU_RTS              ; If on line address, no-op.

                	move.l  d0,-(sp)                ; Save address...
                	bfextu  d0{1:19},d0             ; Get page number
                	move.l  mmu_NestCounts(a5),d1   ; Point at list head
dmd_Loop:       	move.l  d1,a0                   ; Get into address register
                	move.l  (a0),d1                 ; Get Next pointer
                	beq.s   dmd_NoFind              ; Did not find it...
                	cmp.l   nc_Low(a0),d0           ; Are we above low?     0
                	bcs.s   dmd_Loop                ; Not this one...
                	cmp.l   nc_High(a0),d0          ; Are we below limit?   12
                	bhi.s   dmd_Loop                ; Not this one...
                	sub.l   nc_Low(a0),d0           ; Subtract low...           8
                	lea     nc_Count(a0),a1         ; Point at start of space   16
                	add.l   d0,a1                   ; Adjust for page offset
                	add.l   d0,a1                   ; (*2 since they are words)
                	move.l  (sp)+,d0                ; Restore address...

                	movec.l urp,a0                  ; Get ROOT pointer...
                	bfextu  d0{0:7},d1              ; Get the root index...
                	asl.l   #2,d1                   ; *4
                	add.l   d1,a0                   ; Add to root pointer...
                	move.l  (a0),d1                 ; Get page entry
                	and.w   #$FE00,d1               ; Mask into the page table
                	move.l  d1,a0                   ; Store pointer...
                	bfextu  d0{7:7},d1              ; Get the pointer index...
                	asl.l   #2,d1                   ; *4
                	add.l   d1,a0                   ; Add to table pointer...
                	move.l  (a0),d1                 ; Get page entry...
                	and.w   #$FF00,d1               ; Mask to the pointer...
                	move.l  d1,a0                   ; Put into address register...
                	bfextu  d0{14:6},d1             ; Get index into page table
                	asl.l   #2,d1                   ; *4
                	add.l   d1,a0                   ; a0 now points at the page...
                	move.l  (a0),d1                 ; Get page entry...
                	btst.l  #0,d1                   ; Check if bit 0 is set...
                	bne.s   dmd_skip                ; If set, we are valid...
                	bclr.l  #1,d1                   ; Check if indirect...
                	beq.s   dmd_skip                ; If not indirect, A0 is valid
                	move.l  d1,a0                   ; a0 is now the page entry...
dmd_skip:       	jmp     (a4)                    ; Ok, so now do the page work

dmd_NoFind:     	move.l  (sp)+,d0                ; Restore d0...
Do_MMU_RTS:     	rts                             ; Done...

	* At this point we are being called as follows:
	*       a0 - Points to the page entry in the MMU table for the address
	*       a1 - Points at the WORD size nest count for this page in the MMU
	*       d0 - Scrap
	*       d1 - Scrap
	*       STACK - Ready to RTS...

Off_MMU_Page:   	move.w  (a1),d0                 ; Get the count...
                	addq.w  #1,(a1)                 ; Bump the count...
                	tst.w   d0                      ; Are we 0?
                	bne.s   Do_MMU_RTS              ; If not, we already are nested
                	addq.l  #3,a0                   ; Point at last byte of long
                	cpusha  dc                      ; Push the data cache before ATC
                	pflusha                         ; Flush the ATC...
                	bclr.b  #5,(a0)                 ; Clear the copyback bit...
                	cpushl  dc,(a0)                 ; Push the cache...
                	rts
	*
	* This routine is called just like Off_MMU_Page is...
	*
On_MMU_Page:    	subq.w  #1,(a1)                 ; Drop count...
                	move.w  (a1),d0                 ; Get count...
                	bne.s   Do_MMU_RTS              ; If not 0, still nested...
                	addq.l  #3,a0                   ; Point at last byte of long
                	pflusha                         ; Flush the ATC...
                	bset.b  #5,(a0)                 ; Set the copyback bit...
                	cpushl  dc,(a0)                 ; Push the cache...
                	rts
*
******************************************************************************

	end






