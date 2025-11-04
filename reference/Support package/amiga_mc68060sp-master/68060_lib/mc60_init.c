/*-------------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**      \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**------------------------------------------------------------------------------
*/

//#define __USE_SYSBASE

#include	<clib/alib_protos.h>

#include	<proto/exec.h>
#include <exec/exec.h>
#include <exec/execbase.h>
#include <exec/ports.h>

#include <dos.h>

//**------------------------------------------------------------------------------------------------

#include "mc60_rev.h"
#include	"mc60_Debug.h"
#include	"mc60_LibBase.h"

//**------------------------------------------------------------------------------------------------

#define REG(x) register __ ## x


//**----------------------------------------------------------------------------
//** This code is directly taken from M.Sinz and left as is, with some
//** Patches. MMUFrame is set with valid MMUFrame or NOT !

extern 	void	__asm 		PatchExec(REG(a6) struct ExecBase*SysBase);
extern   struct mc60_mmu 	*MMUFrame;

extern void __asm 			FPU_Dispatcher(void);			// New Dispatcher
extern void __asm 			FPU_LaunchPoint(void);			// New Launchcode

//**----------------------------------------------------------------------------
//** This are the enry points for the Amiga ISP/FPSP

extern 	void	__asm 		Install_AmigaISP(void);
extern 	void	__asm 		Install_AmigaFPSP(void);

//**----------------------------------------------------------------------------
//** This is some misc routines for PCR/VBR crap. Supervisor Code

extern	void  __asm			GetVBR(void);
extern	void  __asm			SetVBR(void);
extern	BOOL  __asm 		CheckMMU(void);			// Check MMU and set DTTR1 for all data no caache
extern	void  __asm  		SetMMUTables(void);		// Load URP/SRP(TCR with _valid_ MMUFrame
extern 	void	__asm 		EnableCaches(void);

//**----------------------------------------------------------------------------
//** This routine will return a _valid_ MMUFrame or NULL

extern 	struct mc60_mmu* 	BuildMMUTables(void);


//**-----------------------------------------------------------------------------
//**-----------------------------------------------------------------------------

static 
void MoveVBR(void)
{
APTR vbr;
	vbr = (APTR)Supervisor( (APTR)GetVBR );
	if (vbr==NULL)
	{
		if ( vbr = AllocMem( 256*4, MEMF_PUBLIC ) )
		{
			CopyMem( (APTR)NULL, vbr, 256*4 );
			CacheClearU();
			putreg(REG_D0,(LONG)vbr),Supervisor( (APTR)SetVBR );
		}
	}
}

//**-----------------------------------------------------------------------------
//**-----------------------------------------------------------------------------

#define LVOexecPrivate4 (ULONG)(-54)									// Dispatcher Entry to Exec

static
void ConvertStack(struct Task*task)
{
ULONG *stack;
	D(bug("Patch Stack : %s\n",task->tc_Node.ln_Name ));
	stack = task->tc_SPReg;
	*(--stack) = NULL;
	*(--stack) = NULL;
	*(--stack) = NULL;
	task->tc_SPReg = stack;
}
void SetDispatcher(struct ExecBase*SysBase)
{
struct Task*task;

	if ( !(SysBase->AttnFlags & AFF_PRIVATE) )
	{
		Disable();
      CacheClearU();															// Be sure....
		SysBase->AttnFlags |= (AFF_68060|AFF_FPU40);					//	Set AttnFlags
		SysBase->AttnFlags |= AFF_PRIVATE;
      D(bug("Attn: %04lx\n",SysBase->AttnFlags));

		SetFunction(SysBase,LVOexecPrivate4,(APTR)FPU_Dispatcher);		// Install FPU Dispatcher
      SysBase->ex_LaunchPoint = (ULONG)&FPU_LaunchPoint;				// Setup Launchcode

      for ( task = (struct Task*)SysBase->TaskReady.lh_Head;
            task->tc_Node.ln_Succ; task = (struct Task*)task->tc_Node.ln_Succ
			 ) ConvertStack(task);

      for ( task = (struct Task*)SysBase->TaskWait.lh_Head;
            task->tc_Node.ln_Succ; task = (struct Task*)task->tc_Node.ln_Succ
			 ) ConvertStack(task);


      CacheClearU();															// Be sure....
      Enable();
	}
}

//**-----------------------------------------------------------------------------

struct mc60_Lib*  __asm LibInit(	REG(d0) struct mc60_Lib *base,
					                  REG(a0) BPTR seglist,
					                  REG(a6) struct ExecBase*SysBase)
{
	D(bug("\n\n\nMC68060 Support Library (Version%ld.%ld)\n"
			"\tLibInit(Base:%08lx,SegList:%08lx,SysBase:%08lx)\n"
			"\t\tAttnFlags = %04lx\n"
			"\t\tChecking Kickstart version :",
			VERSION,REVISION,base,seglist,SysBase,SysBase->AttnFlags));

   if (	!(  ( SysBase->LibNode.lib_Version >= 37 ) &&				// right Kicklevel ?
   		  	 ( SysBase->AttnFlags & AFF_68040     )	 )   )		// right CPU ???
	{
		D(bug("Kickstart Version < 37 - upgrade your Kickstart\n"));
		Alert(AN_Unknown|AG_OpenLib|AO_ExecLib);							// Alert User
		FreeMem(  (VOID*)((int)base-base->Lib.lib_NegSize),			// Free Library Data immediatly and rc=NULL
					base->Lib.lib_NegSize+base->Lib.lib_PosSize);
      base = NULL;
   }
   else //**----------------------------------------------------------------------
	{
   ULONG cachebits;															// Remember CacheState
		D(bug("Kickstart Version >=37 - setup MC68060\n\n",base));

		base->SegList		= seglist;								// store seglist
		base->SysBase 		= SysBase;								// for fast access
		base->MMUFrame 	= &MMUFrame;							// for fun

		D(bug("\tGo forbid(), Disable/Flush Caches...\n"));

		Forbid(); cachebits = CacheControl(0,-1);				// Stall and disable caches.

		//**----------------------------------------------
		//** Install CPU 68060 Patches from Motorola

		DQ(bug("\tInstalling ISP & FPSP Code to Base & VBR\n"));
		Install_AmigaISP();											// Install Amiga ISP
		Install_AmigaFPSP();
		SysBase->AttnFlags |= (AFF_68882|AFF_68881); 		//	Set AttnFlags

		//**----------------------------------------------
		//** Do Exec Patches.

		DQ(bug("\tPatching exec.library : \n"));
		MMUFrame = NULL;												// No MMU yet.
		PatchExec(SysBase);                     				// patches from 68040.library

		DQ(bug("\tMoving VBR:\n"));
		MoveVBR();

		DQ(bug("\tSetup new dispatcher\n"));
		SetDispatcher(SysBase);									// Install the new dispatcher


		//**----------------------------------------------
		//** Setup MMU Tables if possible

		DQ(bug("\tInstalling MMU support\n"));


		if ( Supervisor( (void*)CheckMMU ) )			// Check for existent MMU
		{
			 MMUFrame = BuildMMUTables(); 	// Store at local code for exec patches !!!!
		}
      DQ(bug("\tMMUStruct=$%08lx\n",MMUFrame));	// Was nu

		if ( MMUFrame ) 	Supervisor( (void*)SetMMUTables );

		//**----------------------------------------------

		DQ(bug("\tInstall 060 caches.\n"));
		Supervisor( (void*)EnableCaches);

		//**----------------------------------------------

		CacheControl(cachebits,-1);
		Permit();

   }
   D(bug("SYSTEM SET UP.  RC=%08lx\n",base));
	return base;
}



