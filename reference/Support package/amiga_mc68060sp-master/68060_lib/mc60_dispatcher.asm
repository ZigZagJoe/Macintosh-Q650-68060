**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Carsten Schlote, 1990-2016
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------

	machine	68060
	near             code
	opt	1

	include	"mc60_system.i"
	include	"mc60_libbase.i"

MYDEBUG	SET              0
DEBUG_DETAIL 	set 	10

**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
**-------------------------------------------------------------------------------
* New Switch Code for Task Scheduling. Is Supervisor Code. Save Context to USP
* Entered at execPrivate4()     ;ExecPrivate4 (Dispatcher) := $f81402
*  With FPU  execprivate4_FPU() ;                          := $f815a8
*
* This is the standard code taken from V39 Exec. Modified for new Stackframe
* formats of 060FPU. Things became simpler :-)
*
* Code is partly optimized compared with Exec StdCode.

	XDEF	_FPU_Dispatcher
_FPU_Dispatcher:
	MOVE.W	#$2000,SR	; Set Supervisor State
	MOVE.L	A5,-(SP)               ; Save a5 to SSP !!!!!
	MOVE.L	USP,A5	; Get USP to a5

	MOVEM.L	D0-D7/A0-A6,-(A5)	; Save all regs to USP = 60
			; 15*8 = 60 Bytes
	MOVEA.L	(4).W,A6	; Get SysBase
	MOVE.W	(IDNestCnt,A6),D0	; get nest irq & diable next cnt
	MOVE.W	#$FFFF,(IDNestCnt,A6) 	; lock both cnts to max.
	MOVE.W	#$C000,(_custom+intena).L

	MOVE.L	(SP)+,(52,A5)	; (8*4)+(5*4)=32+20=52  correct A5 on USP
	MOVE.W	(SP)+,-(A5)	;  SR to USP 62
	MOVE.L	(SP)+,-(A5)            ;  PC to USP 64

	LEA	(2,SP),SP              * Ignore this field
*                       MOVE.W           (SP)+,d1               ; OBSOLETE exception frame

	FSAVE	-(A5)	; Save Stackframe

	TST.B	(2,A5)	* Test for 060 Nullframe
	BEQ.B	.SWITCH_FPU_NullFrame

	MOVEQ	#-1,D2                	; On 060 This is the only state IDEL

*	MOVE.W	d2,-(a5)	* Caution Stackframe changed !
*	AND.W	#$F000,D1              * As we check 2(a5), we must
*	CMP.W	#$9000,D1              * save a long word. otherwise
*	BNE.B	lbC0015F2              * we break the checks.
*	MOVE.L	(SP)+,-(A5)            * As D1 is OBSOLETE we can use
*	MOVE.L	(SP)+,-(A5)	* it's space
*	MOVE.L	(SP)+,-(A5)
*	MOVE.W	D1,D2

	FMOVEM.X	FP0/FP1/FP2/FP3/FP4/FP5/FP6/FP7,-(A5)  ; Save Registers
*	FMOVEM.L	FPIAR/FPSR/FPCR,-(A5)  	* Not supported
	FMOVE.L	FPIAR,-(A5)		* Use this now
	FMOVE.L	FPSR,-(A5)
*	FMOVE.L	FPCR,-(A5)

	MOVE.L	D2,-(A5)               * SAVE DUMMY FIELD -1
*	MOVE.W	D2,-(A5)               ; OBSOLETE

********************************************************************
** The following code is common to Std & FPU Dispatcher
********************************************************************

.SWITCH_FPU_NullFrame:
	MOVEA.L	(ex_LaunchPoint,A6),A4		; a4 = LaunchCOde

	MOVEA.L	(ThisTask,A6),A3
	MOVE.W	D0,(TC_IDNESTCNT,A3)		; Save nest count to task context
	MOVE.L	A5,(TC_SPREG,A3)		; Remember Task StackPtr

	BTST	#TB_SWITCH,(TC_FLAGS,A3)	; Set Custom Switch Code
	BEQ.B	.getNextTask
	MOVEA.L	(TC_SWITCH,A3),A5	; private switchcode
	JSR	(A5)

*lbC001450:	MOVEA.L	(ex_LaunchPoint,A6),A4  	;
*	MOVE.W	#$FFFF,(IDNestCnt,A6)          ; OBSOLETE
*	MOVE.W	#$C000,(_custom+intena).L      ;

.getNextTask:	LEA	(TaskReady,A6),A0		; get a ready Task
.taskloop:	MOVE.W	#$2700,SR      		; Travese ready list
	MOVEA.L	(LN_SUCC,A0),A3                ; wait until AddTail() added task
	MOVE.L	(LN_SUCC,A3),D0
	BNE.B	.taskendloop
	ADDQ.L	#1,(IdleCount,A6)
	BSET	#7,(SysFlags,A6)		; System in IDEL state
	STOP	#$2000		; Stop until next Irq
	BRA.B	.taskloop

.taskendloop:	MOVE.L	D0,(LN_SUCC,A0)                ; feed last task to end of ready queue
	MOVEA.L	D0,A1
	MOVE.L	A0,(LN_PRED,A1)

	MOVE.L	A3,(ThisTask,A6)		; Save to Aktual Task

	MOVE.W	(Quantum,A6),(Elapsed,A6)

	BCLR	#6,(SysFlags,A6)		; System state ??

	MOVE.B	#TS_RUN,(TC_STATE,A3)		; Set Taskstate

	MOVE.W	(TC_IDNESTCNT,A3),(IDNestCnt,A6) ; Restore Net Counts
	TST.B	(IDNestCnt,A6)                 ; restore IRQ state
	BMI.B	.idnest3
	MOVE.W	#$4000,(_custom+intena).L
.idnest3:	MOVE.W	#$2000,SR		; Set Superstate
	ADDQ.L	#1,(DispCount,A6)		; Inc DispCount

	MOVE.B	(TC_FLAGS,A3),D0
	ANDI.B	#(TF_EXCEPT|TF_LAUNCH),D0	; Launch this task ???
	BEQ.B	.conttask
	BSR.B	.launchnewtask		; launch new code

.conttask:	MOVEA.L	(TC_SPREG,A3),A5		; Get Task StackPtr
	JMP	(A4)                           ; ex_LaunchPoint code


	**----- Some obsolete Code deleted here


.launchnewtask:	BTST	#TB_LAUNCH,D0			; Launch new task ???
	BEQ.B	.nolaunch

	MOVE.B	D0,D2
	MOVEA.L	(TC_LAUNCH,A3),A5		; Launch new task
	JSR	(A5)
	MOVE.B	D2,D0

.nolaunch:	BTST	#TB_EXCEPT,D0                   	; do Exception state code
	BNE.B	.Exception
.endexception:	RTS                                              	; otherwise goon

.Exception:	BCLR	#TB_EXCEPT,(TC_FLAGS,A3)
	MOVE.L	(TC_EXCEPTCODE,A3),D1			; d1=ExeceptionCode
	BEQ.B	.endexception

	MOVE.W	#$4000,(_custom+intena).L		; DISABLE
	ADDQ.B	#1,(IDNestCnt,A6)

	MOVE.L	(TC_SIGRECVD,A3),D0 		; Get mask of exceptions
	AND.L	(TC_SIGEXCEPT,A3),D0
	EOR.L	D0,(TC_SIGEXCEPT,A3)		; reset flags set.
	EOR.L	D0,(TC_SIGRECVD,A3)

	SUBQ.B	#1,(IDNestCnt,A6)		; ENABLE
	BGE.B	.idnest
	MOVE.W	#$C000,(_custom+intena).L
.idnest:
	MOVEA.L	(TC_SPREG,A3),A1
	MOVE.L	(TC_FLAGS,A3),-(A1)

	TST.B	(IDNestCnt,A6)
	BNE.B	.idcont2

	SUBQ.B	#1,(IDNestCnt,A6)		; ENABLE
	BGE.B	.idcont2
	MOVE.W	#$C000,(_custom+intena).L
.idcont2:
	MOVE.L	#go_supervisor,-(A1)		; go supervisor
	MOVE.L	A1,USP

	BTST	#AFB_68010,(AttnFlags+1,A6)	;
	BEQ.B	.nofpuused
	MOVE.W	#$0020,-(SP)
.nofpuused:	MOVE.L	D1,-(SP)
	CLR.W	-(SP)
	MOVEA.L	(TC_EXCEPTDATA,A3),A1
	RTE

*------------------------------------------------------------------------------------------------

go_supervisor:	MOVEA.L	(4).W,A6	; Reenter SuperState after Execept Code
	LEA	(.supercode,PC),A5
	JMP	(_LVOSupervisor,A6)

.supercode:	MOVEA.L	(ex_LaunchPoint,A6),A4		; Get start of Launchcode
	BTST	#AFB_68010,(AttnFlags+1,A6)	; Care about FPU ???
	BEQ.B	.nofpuused

	ADDQ.L	#2,SP
.nofpuused:	ADDQ.L	#6,SP
	MOVEA.L	(ThisTask,A6),A3		; Set new Execept Bit if wanted
	OR.L	D0,(TC_SIGEXCEPT,A3)

	MOVE.L	USP,A1
	MOVE.L	(A1)+,(TC_FLAGS,A3)
	MOVE.L	A1,(TC_SPREG,A3)

	MOVE.W	(TC_IDNESTCNT,A3),(IDNestCnt,A6)
	TST.B	(IDNestCnt,A6)
	BMI.B	.end
	MOVE.W	#$4000,(_custom+intena).L
.end:	RTS

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
**
** This is the old ex_LaunchPoint Code with additions to load the extra
** Registers from the TaskStack, and then LaunchTask
** Information taken from Kickstart V39 Exec $F81600

** Some Code is removed because FPU Stackframes changed complettly, therefore
** many things simplefied. 060 FPU Frames are equal length :-)

	XDEF	_FPU_LaunchPoint
_FPU_LaunchPoint:
	MOVEQ	#$20,D1	; CPU Vector/Offset to save

	*** Each new Task has an NULL Frame at Stack at Buttom.
	***  So it should be zero.

	TST.B	(2,A5) 	; Test Frame Format NULL ?
	BEQ.B	.isNullFrame           ; yep. don't touch FPU

	*** CPU was used, and therefore a -1 longword is stored.
	*** Before only -1.w was stored as marker.
	*** The original source uses -1.w,regs,<frameformat>
	*** Changed ! Now  -1.L,regs,$0020 is used for 060.

	ADDQ.L	#4,A5                  ; SKIP DUMMY FIELD
*	ADDQ.L	#2,A5                  ; OBSOLETE -1.w Flag

	FMOVE.L	(A5)+,FPCR
	FMOVE.L	(A5)+,FPSR
	FMOVE.L	(A5)+,FPIAR
*	FMOVEM.L	(A5)+,FPIAR/FPSR/FPCR
	FMOVEM.X	(A5)+,FP0/FP1/FP2/FP3/FP4/FP5/FP6/FP7  ; load FPU regs

*	CMP.B	#$90,D0	; OBSOLETE
*	BNE.B	lbC001620
*	MOVE.L	(A5)+,-(SP)
*	MOVE.L	(A5)+,-(SP)
*	MOVE.L	(A5)+,-(SP)
*	MOVE.W	#$9020,D1
*lbC001620:
*	ADDQ.L	#2,A5

.isNullFrame:
	FRESTORE	(A5)+	; rebuild fpu state
	LEA	(66,A5),A2	; Goto Top of TaskFrame
	MOVE.L	A2,USP                 ; Set old USP
	MOVE.W	D1,-(SP)               ; CPU Frame $0020
	MOVE.L	(A5)+,-(SP)	; PC
	MOVE.W	(A5)+,-(SP)            ; SR Task
	MOVEM.L	(A5),D0-D7/A0-A6       ; load regs
	RTE


	end
