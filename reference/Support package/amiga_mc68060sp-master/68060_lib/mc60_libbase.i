**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

**
**
**-------------------------------------------------------------------------------
** This is the lib vector table for mc60.lib. The jump table is just in front of
** this structure. Keep care


	STRUCTURE 	mc60_Lib,LIB_SIZE
                        BPTR	mc60_SegList
	APTR	mc60_SysBase
	APTR	mc60_MMUFrame
	LABEL	mc60_SIZEOF


**-------------------------------------------------------------------------------
**
** This is the MMU Frame Structure

	STRUCTURE	mmu,0
	ULONG	mmu_URP		; $00	mc68k URP
	ULONG	mmu_SRP		; $04  mc68k SRP
	ULONG	mmu_TCR		; $08

	APTR	mmu_RootTable		; $0C
	APTR	mmu_PointerTable		; $10
	APTR	mmu_PageTable		; $14

	ULONG	mmu_IllPageDesc		; $18
	APTR	mmu_IllegalPage		; $1C

	ULONG	mmu_RootTableDesc		; $20
	ULONG	mmu_PointerTableDesc	; $24
	ULONG	mmu_IndIllPageDesc	; $28

	STRUCT	mmu_NestCounts,MLH_SIZE 	; $2c

	STRUCT 	mmu_PageList,MLH_SIZE
	APTR	mmu_MemPage
	WORD	mmu_MemPageOffset

	LABEL	mmu_SIZEOF		;

**-------------------------------------------------------------------------------
** Allocated in Chip Mem to save memory - it's only resource tracking !
**-------------------------------------------------------------------------------

	STRUCTURE 	pl_MinNode,MLN_SIZE
	APTR	pl_PageAddr
	LABEL	pl_SIZEOF

**-------------------------------------------------------------------------------
** Must be fast memory !!!! Allocate them last to save memory
**-------------------------------------------------------------------------------

	STRUCTURE	nc_MinNode,MLN_SIZE      ; 0
                        ULONG	nc_Low                   ; 8
                        ULONG            nc_High                  ; 12
                        LABEL	nc_Count	       ; 16


