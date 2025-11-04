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

**-------------------------------------------------------------------------------

	XDEF	__060MMUFrame

**-------------------------------------------------------------------------------

	section          patches,code

**-------------------------------------------------------------------------------
*<	a5 = LibBase
*<	a6 = SysBase


	XDEF	_Install_Exec_Patches
_Install_Exec_Patches:
	MOVEM.L	D0-D7/A0-A6,-(SP)

	LEA	(cardname,PC),A0	; Store String for easy Access
	MOVE.L	A0,(mc60_CardName,A5)

	LEA	(cdstrapname,PC),A0	; Store String for easy Access
	MOVE.L	A0,(mc60_CdStrap,A5)

	LEA	(expansionname,PC),A0	; Store String for easy Access
	MOVE.L	A0,(mc60_Expansion,A5)

	*-----------------------------------------------------------------------------
	* fixed for proper code on Aztec C startup with FPU

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


	*-----------------------------------------------------------------------------
	* Taken from 68040.library

	LEA	(NewCachePreDMA,PC),A0         ; New CachePreDMA() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.W	#_LVOCachePreDMA,A0
	JSR	(_LVOSetFunction,A6)

	LEA	(NewCachePostDMA,PC),A0	; New CachePostDMA() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.W	#_LVOCachePostDMA,A0
	JSR	(_LVOSetFunction,A6)

	LEA	(NewCacheControl,PC),A0	; New CacheControl() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOCacheControl,A0
	JSR	(_LVOSetFunction,A6)

	**----------------------------------------------

	LEA	(NewAddLibrary,PC),A0	; New AddLibrary() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOAddLibrary,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldAddLibrary,PC),A0
	MOVE.L	D0,(A0)

	LEA	(NewAddDevice,PC),A0	; New AddDevice() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOAddDevice,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldAddDevice,PC),A0
	MOVE.L	D0,(A0)

	LEA	(NewAddResource,PC),A0	; New AddResource() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOAddResource,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldAddResource,PC),A0
	MOVE.L	D0,(A0)

	LEA	(NewAddTask,PC),A0           	; New AddTask() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOAddTask,A0
 	JSR	(_LVOSetFunction,A6)	; this patch is deadly....
	LEA	(OldAddTask,PC),A0
	MOVE.L	D0,(A0)

	LEA	(NewAddIntServer,PC),A0	; New AddIntServer() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOAddIntServer,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldAddIntServer,PC),A0
	MOVE.L	D0,(A0)

	LEA	(NewSetIntVector,PC),A0        ; New SetIntVector() code
	MOVE.L	A0,D0
	MOVEA.L	A6,A1
	MOVEA.L	#_LVOSetIntVector,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldSetIntVector,PC),A0
	MOVE.L	D0,(A0)


	LEA	(DeviceList,A6),A0           	; Check Device List for input.device
	LEA	(InputName,PC),A1              ; never wake sleeping dogs - do nothing
	JSR	(_LVOFindName,A6)              ; if not existent. Possible intended use.
	MOVEA.L	D0,A1	; with no device open
	TST.L	D0
	BEQ.B	.NoInputPatch                 	; - skip !

	LEA	(NewBeginIO,PC),A0	; New BeginIO() Vector code
	MOVE.L	A0,D0
	MOVEA.W	#$FFE2,A0
	JSR	(_LVOSetFunction,A6)
	LEA	(OldBeginIO,PC),A0
	MOVE.L	D0,(A0)
.NoInputPatch:

	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
** following code ripped from 68040.library

	XDEF	__CheckMMU

__CheckMMU:
	MOVEC	DTT1,D1	;transparent data set to nocache, precise
	AND.B	#$9F,D1
	OR.B	#$20,D1
	DBUG	10,"... set DTT1 to %08lx\n",d1,#0
	MOVEC	D1,DTT1

	MOVEQ	#0,D0
	ORI.W	#$0700,SR	;stop any irq

	MOVEC	TC,D1	;mmu paging on ?
	TST.W	D1
	DBUG	10,"... set TC to %08lx\n",d1,#0
	BMI.B	.is_set

	BSET	#15,D1	;set mmu paging
	MOVEC	D1,TC
	MOVEC	TC,D1	;set & readback
	MOVEC	D0,TC	;no mmu paging!
	TST.W	D1	;was paging set ?
	BPL.B	.no_MMU

.is_set:
*	MOVE.L	#$00F80000,D0	; Crash test
*	MOVEQ	#1,D1
*	MOVEC	D1,DFC
*	MOVEC	D1,SFC
*	MOVEA.L	D0,A0
*	FRESTORE	($4E7A,A0)
*	MOVE.B	D5,D4
*	BTST	#1,D1
*	BNE.B	.no_MMU
	AND.W	#$F000,D1
	MOVE.L	D1,D0
.no_MMU:	RTE


**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
** following code ripped from 68040.library

*>	d0 = __060MMUFrame

	XDEF	__Set060MMUTables
__Set060MMUTables:
	MOVE.L	(__060MMUFrame,PC),A0	; Load MMUFrame Ptr.
	ORI.W	#$0700,SR	; Stop IRqs
	PFLUSHA                                         ;
	MOVE.L	(A0)+,D0
	MOVEC	D0,URP	;SetUserRootPtr
	MOVE.L	(A0)+,D0
	MOVEC	D0,SRP	;Set RootPtr
	MOVE.L	(A0)+,D0	;set Translation Ctrl Reg - go !
	MOVEC	D0,TC
	DBUG	10,"... set TC to %08lx\n",d0,#0
	PFLUSHA		;MC68040
	MOVEQ	#0,D0	;Disable all transparent translation
	MOVEC	D0,ITT0
	MOVEC	D0,ITT1
	MOVEC	D0,DTT0
	MOVEC	D0,DTT1
	RTE

__060MMUFrame:	dc.l	0

**-------------------------------------------------------------------------------

OldSupervisor:	dc.l	0

NewSupervisor:	CMPI.L	#$42A7F35F,(A5)
	BNE.B	.oldcode
	CMPI.W	#$4E73,(4,A5)
	BNE.B	.oldcode	; no op.
	DBUG	10,"---------> New Supervisor()\n",#0,#0
	RTS

.oldcode:
	DBUG	20,"---------> Old Supervisor()\n",#0,#0
	MOVE.L	(OldSupervisor,PC),-(SP)
	RTS

**-------------------------------------------------------------------------------

OldAddLibrary:	dc.l	0

NewAddLibrary:	MOVE.L	(OldAddLibrary,PC),-(SP)
	MOVE.L	A1,-(SP)
	JSR	(_LVOCacheClearU,A6)
	MOVEA.L	(SP)+,A1
	DBUG	10,"---------> New AddLib()\n",#0,#0
	RTS

**-------------------------------------------------------------------------------

OldAddDevice:	dc.l	0

NewAddDevice:	MOVE.L	(OldAddDevice,PC),-(SP)
	MOVE.L	A1,-(SP)
	JSR	(_LVOCacheClearU,A6)
	MOVEA.L	(SP)+,A1
	DBUG	10,"---------> New AddDev()\n",#0,#0
	RTS

**-------------------------------------------------------------------------------

OldAddResource:	dc.l	0

NewAddResource:	MOVE.L	(OldAddResource,PC),-(SP)
	MOVE.L	A1,-(SP)
	JSR	(_LVOCacheClearU,A6)
	MOVEA.L	(SP)+,A1
	DBUG	10,"---------> New AddResource()\n",#0,#0
	RTS

**-------------------------------------------------------------------------------

OldAddTask:	dc.l	0

NewAddTask:
	DBUG	10,"---------> New AddTask(%08lx,%08lx,%08lx) :",a1,a2,a3
	PEA.L	(.postAddTask,PC)
	MOVE.L	(OldAddTask,PC),-(SP)
	MOVE.L	A1,-(SP)	* Flushcache & go forbid
	JSR	(_LVOForbid,A6)
	JSR	(_LVOCacheClearU,A6)
	MOVEA.L	(SP)+,A1
	RTS

.postAddTask:	MOVEM.L	D0/D1/A0/A1,-(SP)	* extent FPU frame now
	TST.L	D0
	BEQ.B            .notask

	MOVEA.L	D0,A0
	MOVEA.L	(pr_Task+TC_SPREG,A0),A1	*
	CLR.L	-(A1)                   	* Extend FPU Frame to idle 060
	CLR.L	-(A1)
	MOVE.L	A1,(pr_Task+TC_SPREG,A0)


.notask:	JSR	(_LVOPermit,A6)
	DBUG	10,"New AddTask.post(%08lx) - Added FPU Nullframe\n",a1
	MOVEM.L	(SP)+,D0/D1/A0/A1
	RTS

; --------------------------------------------------------------------------

OldAddIntServer:	dc.l	0

NewAddIntServer:	MOVE.L	(OldAddIntServer,PC),-(SP)
	MOVEM.L	D0/A1,-(SP)
	JSR	(_LVOCacheClearU,A6)
	MOVEM.L	(SP)+,D0/A1
	DBUG	10,"---------> New AddIntServe()\n",#0,#0
	RTS

; --------------------------------------------------------------------------

OldSetIntVector:	dc.l	0

NewSetIntVector:	MOVE.L	(OldSetIntVector,PC),-(SP)
	MOVEM.L	D0/A1,-(SP)
	JSR	(_LVOCacheClearU,A6)
	MOVEM.L	(SP)+,D0/A1
	DBUG	10,"---------> New SetIntVector()\n",#0,#0
	RTS

; --------------------------------------------------------------------------

OldBeginIO:	dc.l	0

NewBeginIO:	MOVE.L	(OldBeginIO,PC),-(SP)	; FlushCaches if new Handler.
	CMPI.W	#9,($001C,A1)
	BNE.B	.Not_ADDHANDLER

	DBUG	10,"---------> New InputDevice - AddHandler()\n",#0,#0
	MOVEM.L	A1/A6,-(SP)
	MOVEA.L	(4).W,A6
	JSR	(_LVOCacheClearU,A6)
	MOVEM.L	(SP)+,A1/A6
.Not_ADDHANDLER:	RTS

; --------------------------------------------------------------------------

NewCachePostDMA:
	DBUG	20,"---------> New CachePre(%08lx,%08lx,%08lx) :",a0,a1,d0
	BTST	#DMAB_ReadFromRAM,D0            ; Read from Ram
	BNE.W	Return_D0

	MOVE.L	A0,D1                          ; simply push caches if len <= 15
	OR.L	(A1),D1
	ANDI.B	#15,D1
	BEQ.W	Return_D0

	MOVE.L	(__060MMUFrame,PC),D1          ; trace tables to dec use cnter
	BNE.B	TraceMMUPostMapping	; we have tables

	LEA	(_DMAPending,PC),A1	; Dec Usage
	SUBQ.L	#1,(A1)
	BRA	Return_D0

	*---------------------------------------------------
TraceMMUPostMapping:	MOVE.L	A0,-(SP)
	MOVE.L	A4,-(SP)
	LEA	(UnLockPageDMA,PC),A4
	BRA.W	TraceTree

; --------------------------------------------------------------------------
NewCachePreDMA:
	DBUG	20,"---------> New CachePre(%08lx,%08lx,%08lx) :",a0,a1,d0
	BTST	#DMAB_Continue,D0
	BNE.B	Return_A0
	BTST	#DMAB_ReadFromRAM,D0
	BNE.B	Return_A0

	MOVE.L	A0,D1                  	;DMA_ADDR OR DMA_LEN
	OR.L	(A1),D1
	ANDI.B	#15,D1                         ;Get lower 4 bits of result
	BEQ.B	Return_A0                   	; no odd length

	MOVE.L	(__060MMUFrame,PC),D1          ; Trace Down MMU Tree for DMA run ?
	BNE.B	TraceMMUPreMapping

	LEA	(_DMAPending,PC),A1            ; Inc Usage
	ADDQ.L	#1,(A1)

Return_A0:	MOVE.L	A0,D0                          ;Called if no MMU tables installed
Return_D0:	MOVE.L	D0,-(SP)

TriggerExternalCache:	MOVEQ	#0,D0           	;Donothing call to trigger external caches
	MOVEQ	#0,D1                          ; or to to stall DC in noMMU Mode
	BSR.B	NewCacheControl

	MOVE.L	(SP)+,D0
	DBUG	20," (%08lx)\n",d0
	RTS

	*----------------------------------------------------------
TraceMMUPreMapping:
	MOVE.L	A0,-(SP)
	MOVE.L	A4,-(SP)
	LEA	(LockPageDMA,PC),A4
	MOVE.L	(A1),D2                	*@@@@@@@@@@@@@ extra

; --------------------------------------------------------------------------

TraceTree:	MOVE.L	A5,-(SP)
	LEA	(Trace_MMU_Tree,PC),A5
	JSR	(_LVOSupervisor,A6)
	MOVEA.L	(SP)+,A5
	MOVEA.L	(SP)+,A4
	BRA.B	TriggerExternalCache



; --------------------------------------------------------------------------

NewCacheControl:	MOVEM.L	D2-D4,-(SP)
	DBUG	20,"---------> New CacheControl(%08lx,%08lx) :",d0,d1
	AND.L	D1,D0
	NOT.L	D1
	MOVEA.L	A5,A1
	LEA	(ncc_Sup,PC),A5
	JSR	(_LVOSupervisor,A6)
	MOVE.L	D3,D0
	DBUG	20," return CACR $%08lx\n",d0
	MOVEM.L	(SP)+,D2-D4
	RTS

	cnop	0,4
_otherCCRFlags:	dc.l	0
_DMAPending:	dc.l	0


ncc_Sup:	ORI.W	#$0700,SR	; diable irqs
	MOVE.L	#$80008000,D4	; keep mask in register
	MOVEC	CACR,D2                        ; d000 c000
	AND.L	D4,D2   	; get data & inst cache enable
	SWAP	D2	; transform to datareg
	ROR.W	#8,D2
	ROL.L	#1,D2
	OR.L	(_otherCCRFlags,PC),D2         ; 0000 0d 0c

	MOVE.L	D2,D3
	ROL.L	#4,D3
	OR.L	D3,D2

	BTST	#8,D2   	; Set Datacache Enable ?
	BEQ.B	ncc_NoCB
	BSET	#31,D2	; Set EDC

ncc_NoCB:	MOVE.L	D2,D3	; Return state
	AND.L	D1,D2
	OR.L	D0,D2

	MOVE.L	#$00000100,D0   	; Store DataCache State
	AND.L	D2,D0
	MOVE.L	D0,(_otherCCRFlags-ncc_Sup,A5) ; Access data in front of code !

	TST.L	(_DMAPending,PC)     	;Disable Data Cache while in DMA Operation
	BEQ.B	ncc_Normal
	BCLR	#8,D2

ncc_Normal:	ROR.L	#1,D2                	; Reconstrukt the CACR
	ROL.W	#8,D2
	SWAP	D2
	AND.L	D4,D2

	MOVEC	CACR,D1	; Get other Flags
	NOT.L	D4                             ; to CACR
	AND.L	D4,D1
	OR.L	D1,D2

	NOP
	CPUSHA	BC	; PushBothCaches
	NOP
	MOVEC	D2,CACR
	NOP
	MOVEA.L	A1,A5
	RTE

; --------------------------------------------------------------------------

Trace_MMU_Tree:	MOVEA.L	D1,A5                      	;move mmutable to a5

	MOVE.L	A0,D0                          ;push virt address to sp
	MOVE.L	D0,-(SP)

	ADD.L	(A1),D0
	BSR.B	TrackDownMMU                   ;get virt END addr

	MOVE.L	(SP)+,D0
	BSR.B	TrackDownMMU
	RTE
*----------------------------------------------------------------------------

TrackDownMMU:	MOVEQ	#15,D1        	;
	AND.L	D0,D1
	BEQ.W	.quit

	MOVE.L	D0,-(SP)                       ; TargetAddr

	*-----------------------------------------------

	BFEXTU	D0{1:19},D0
	MOVE.L	($0030,A5),D1	*@@@@@@@@@@@@@@@@@

.searchSegment:	MOVEA.L	D1,A0        	; search for right segment
	MOVE.L	(LN_SUCC,A0),D1
	BEQ.W	.nosegment

	CMP.L	(8,A0),D0                      ; right range
	BCS.B	.searchSegment
	CMP.L	(12,A0),D0
	BHI.B	.searchSegment

	SUB.L	(8,A0),D0	; get offset
	LEA	($0010,A0),A1	; get table start of usage cnts
	ADDA.L	D0,A1
	ADDA.L	D0,A1                          ; * 2
                                                                        ; a1 = addr of dma use count


	*-----------------------------------------------

	MOVE.L	(SP)+,D0                       ; TargetAddr

	MOVEC	URP,A0	; Get UserRootPointer addr

	BFEXTU	D0{0:7},D1                     ; Get Root index Value
	ASL.L	#2,D1                          ; *4
	ADDA.L	D1,A0
	MOVE.L	(A0),D1                        ; Get RootDescriptor
	ANDI.L	#$FFFFFE00,D1
	MOVEA.L	D1,A0        	; get pointer array addr

	BFEXTU	D0{7:7},D1	; get pointer index value
	ASL.L	#2,D1	; *4
	ADDA.L	D1,A0
	MOVE.L	(A0),D1	; get page array addr
	ANDI.L	#$FFFFFF00,D1
	MOVEA.L	D1,A0                          ; get page array addr

	BFEXTU	D0{14:6},D1                    ; get page index
	ASL.L	#2,D1	; *4
	ADDA.L	D1,A0	; !!!! a0 = addr of pagedescriptor
	MOVE.L	(A0),D1                        ; get page descriptor

	BTST	#0,D1	; Indirect discriptor ???
	BNE.B	.no_indirect
	BCLR	#1,D1
	BEQ.B	.no_indirect

	MOVEA.L	D1,A0       	; yes load a0 with real desc addr

.no_indirect:	JMP	(A4)	; !!!! a0 = addr of pagedescriptor
			; !!!! a1 = addr of page DMA usagecnt

.nosegment:	MOVE.L	(SP)+,D0
.quit:	RTS

**-------------------------------------------------------------------------------

LockPageDMA:	MOVE.W	(A1),D0	; Inc Usage
	ADDQ.W	#1,(A1)
	TST.W	D0	; previously ZERO Cnt ???
	BNE.B            .quit	; return if already in use ...

	ADDQ.L	#3,A0                          ; go to control byte of desc
	CPUSHA	DC                             ;dump all caches to mem
	PFLUSHA		;MC68040
	BCLR	#5,(A0)	;precise/Writethrough page
	CPUSHL	DC,(A0)
.quit	RTS

**-------------------------------------------------------------------------------

UnLockPageDMA:	SUBQ.W	#1,(A1)	; Dec Usage
	MOVE.W	(A1),D0
	BNE.B            .quit                          ; return if still in use ....

	ADDQ.L	#3,A0	; go to control byte of desc
	PFLUSHA		;MC68040
	BSET	#5,(A0)
	CPUSHL	DC,(A0)	;copyback/imprecise page
.quit	RTS

**-------------------------------------------------------------------------------
                        even
cardname:	dc.b	'card.resource',0
cdstrapname:	dc.b	'cdstrap',0
expansionname:	dc.b	'expansion.library',0
InputName:	dc.b	'input.device',0,0
	even

*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------------------------------------


	XDEF	_Install_Caches
_Install_Caches:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	(Install_Caches_Doit,PC),A5
	JSR	(_LVOSupervisor,A6)
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

Install_Caches_Doit:
	MOVEC	CACR,D0	; Enable Store Buffer
	ORI.L	#$20000000,D0
	MOVEC	D0,CACR

	CINVA	BC	; Invalidate all Caches

	MOVEC	CACR,D0
	ORI.L	#$00400000,D0	; Flush all branch cache entries
	MOVEC	D0,CACR
	NOP
	ANDI.L	#$FFBFFFFF,D0	; Enable Branchcache
	ORI.L	#$00800000,D0
	MOVEC	D0,CACR
	NOP
	DBUG	10,"CACR=%08lx, ",d0

	MOVEC	PCR,D0	; Enable Superscalar Mode
	DBUG	10,"old PCR=$08lx, ",d0
	ORI.L	#1,D0
	MOVEC	d0,PCR
	NOP
	DBUG	10,"new PCR=$08lx\n",d0


	RTE

	end
