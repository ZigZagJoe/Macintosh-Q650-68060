/*
#
# $NetBSD: fnetbsd.S,v 1.5 2000/11/30 21:00:51 scw Exp $
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MOTOROLA MICROPROCESSOR & MEMORY TECHNOLOGY GROUP
# M68000 Hi-Performance Microprocessor Division
# M68060 Software Package Production Release 
# 
# M68060 Software Package Copyright (C) 1993, 1994, 1995, 1996 Motorola Inc.
# All rights reserved.
# 
# THE SOFTWARE is provided on an "AS IS" basis and without warranty.
# To the maximum extent permitted by applicable law,
# MOTOROLA DISCLAIMS ALL WARRANTIES WHETHER EXPRESS OR IMPLIED,
# INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS
# FOR A PARTICULAR PURPOSE and any warranty against infringement with
# regard to the SOFTWARE (INCLUDING ANY MODIFIED VERSIONS THEREOF)
# and any accompanying written materials. 
# 
# To the maximum extent permitted by applicable law,
# IN NO EVENT SHALL MOTOROLA BE LIABLE FOR ANY DAMAGES WHATSOEVER
# (INCLUDING WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
# BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS)
# ARISING OF THE USE OR INABILITY TO USE THE SOFTWARE.
# 
# Motorola assumes no responsibility for the maintenance and support
# of the SOFTWARE.  
# 
# You are hereby granted a copyright license to use, modify, and distribute the
# SOFTWARE so long as this entire notice is retained without alteration
# in any modified and/or redistributed versions, and that such modified
# versions are clearly identified as such.
# No licenses are granted by implication, estoppel or otherwise under any
# patents or trademarks of Motorola, Inc.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
# Derived from: 
# fskeleton.s
#
# This file contains:
#	(1) example "Call-out"s
#	(2) example package entry code
#	(3) example "Call-out" table
#


#################################
# (1) EXAMPLE CALL-OUTS		#
#				#
# _060_fpsp_done()		#
# _060_real_ovfl()		#
# _060_real_unfl()		#
# _060_real_operr()		#
# _060_real_snan()		#
# _060_real_dz()		#
# _060_real_inex()		#
# _060_real_bsun()		#
# _060_real_fline()		#
# _060_real_fpu_disabled()	#
# _060_real_trap()		#
#################################
*/

.macro _fpsp_rte_noerr_todo
    fsave	-(%sp)
	move.w	#0x6000,2(%sp)
	frestore (%sp)+
	rte
.endm

/*
#
# _060_fpsp_done():
#
# This is the main exit point for the 68060 Floating-Point
# Software Package. For a normal exit, all 060FPSP routines call this
# routine. The operating system can do system dependent clean-up or
# simply execute an "rte" as with the sample code below.
#
*/
_060_fpsp_done:
	DBG_TRACE_FPSP "_060_fpsp_done\n"
    rte

/*
#
# _060_real_ovfl():
#
# This is the exit point for the 060FPSP when an enabled overflow exception
# is present. The routine below should point to the operating system handler 
# for enabled overflow conditions. The exception stack frame is an overflow
# stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_ovfl:
    DBG_TRACE_FPSP "_060_real_ovfl\n"
    _fpsp_rte_noerr_todo

	move.l	(FPOVFL_VEC040).W,-(%sp)	| push vector to user OVFL handler <1/8/91, JPO>
	rts				| execute user handler <1/8/91, JPO>

/*
#
# _060_real_unfl():
#
# This is the exit point for the 060FPSP when an enabled underflow exception
# is present. The routine below should point to the operating system handler 
# for enabled underflow conditions. The exception stack frame is an underflow
# stack frame. The FP state frame holds the EXCEPTIONAL OPERAND.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_unfl:
    DBG_TRACE_FPSP "_060_real_unfl\n"
    _fpsp_rte_noerr_todo
	move.l	(FPUNFL_VEC040).W,-(%sp)	| push vector to user UNFL handler <1/9/91, JPO>
	rts				| execute user handler <1/9/91, JPO>

/*
#
# _060_real_operr():
#
# This is the exit point for the 060FPSP when an enabled operand error exception
# is present. The routine below should point to the operating system handler 
# for enabled operand error exceptions. The exception stack frame is an operand error
# stack frame. The FP state frame holds the source operand of the faulting
# instruction.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_operr:
    DBG_TRACE_FPSP "_060_real_operr\n"
    _fpsp_rte_noerr_todo
	move.l	(FPOPERR_VEC040).W,-(%sp)	| push vector to user's handler <1/9/91, JPO>
	rts					| execute user's handler <1/9/91, JPO>

/*
#
# _060_real_snan():
#
# This is the exit point for the 060FPSP when an enabled signalling NaN exception
# is present. The routine below should point to the operating system handler 
# for enabled signalling NaN exceptions. The exception stack frame is a signalling NaN
# stack frame. The FP state frame holds the source operand of the faulting
# instruction.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_snan:
    DBG_TRACE_FPSP "_060_real_snan\n"
    _fpsp_rte_noerr_todo
	move.l	(FPSNAN_VEC040).W,-(%sp)	| push vector to user handler <1/9/91, JPO>
	rts				| execute user handler <1/9/91, JPO>

/*
#
# _060_real_dz():
#
# This is the exit point for the 060FPSP when an enabled divide-by-zero exception
# is present. The routine below should point to the operating system handler 
# for enabled divide-by-zero exceptions. The exception stack frame is a divide-by-zero
# stack frame. The FP state frame holds the source operand of the faulting
# instruction.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_dz:
    DBG_TRACE_FPSP "_060_real_dz\n"
    _fpsp_rte_noerr_todo

/*
#
# _060_real_inex():
#
# This is the exit point for the 060FPSP when an enabled inexact exception
# is present. The routine below should point to the operating system handler 
# for enabled inexact exceptions. The exception stack frame is an inexact
# stack frame. The FP state frame holds the source operand of the faulting
# instruction.
#
# The sample routine below simply clears the exception status bit and
# does an "rte".
#
*/
_060_real_inex:
    DBG_TRACE_FPSP "_060_real_inex\n"
    _fpsp_rte_noerr_todo

/*
#
# _060_real_bsun():
#
# This is the exit point for the 060FPSP when an enabled bsun exception
# is present. The routine below should point to the operating system handler 
# for enabled bsun exceptions. The exception stack frame is a bsun
# stack frame.
#
# The sample routine below clears the exception status bit, clears the NaN
# bit in the FPSR, and does an "rte". The instruction that caused the 
# bsun will now be re-executed but with the NaN FPSR bit cleared.
#
*/
_060_real_bsun:
    DBG_TRACE_FPSP "_060_real_bsun\n"
    _fpsp_rte_noerr_todo
    move.l	(FPBSUN_VEC040).W,-(%sp)	| push vector to user's handler <1/8/91, JPO>
	rts				| execute user's handler <1/8/91, JPO>

/*
#
# _060_real_fline():
#
# This is the exit point for the 060FPSP when an F-Line Illegal exception is 
# encountered. Three different types of exceptions can enter the F-Line exception
# vector number 11: FP Unimplemented Instructions, FP implemented instructions when
# the FPU is disabled, and F-Line Illegal instructions. The 060FPSP module
# _fpsp_fline() distinguishes between the three and acts appropriately. F-Line
# Illegals branch here.
# 
*/
_060_real_fline:
    DBG_TRACE_FPSP "_060_real_fline\n"
    _fpsp_rte_noerr_todo
	move.l	(FLINE_VEC040).W,-(%sp)	| push vector to user's handler <1/8/91, JPO>
	rts				| execute user's handler <1/8/91, JPO>

/*
#
# _060_real_fpu_disabled():
#
# This is the exit point for the 060FPSP when an FPU disabled exception is 
# encountered. Three different types of exceptions can enter the F-Line exception
# vector number 11: FP Unimplemented Instructions, FP implemented instructions when
# the FPU is disabled, and F-Line Illegal instructions. The 060FPSP module
# _fpsp_fline() distinguishes between the three and acts appropriately. FPU disabled
# exceptions branch here.
#
# The sample code below enables the FPU, sets the PC field in the exception stack
# frame to the PC of the instruction causing the exception, and does an "rte".
# The execution of the instruction then proceeds with an enabled floating-point
# unit.
#
*/
_060_real_fpu_disabled:
    DBG_TRACE_FPSP "_060_real_fpu_disabled\n"
    movel	%d0,-(%sp)
	movec.l %pcr,%d0		|* movec.l pcr,d0
	bclr	#1,%d0		    |# enable the fpu
	movec.l %d0,%pcr		|* movec.l d0,pcr
	movel	(%sp)+,%d0

	movel	0xC(%sp),2(%sp)	|# set "Current PC"
	rte

/*
#
# _060_real_trap():
#
# This is the exit point for the 060FPSP when an emulated "ftrapcc" instruction
# discovers that the trap condition is true and it should branch to the operating
# system handler for the trap exception vector number 7.
#
# The sample code below simply executes an "rte".
#
*/
_060_real_trap:
	DBG_TRACE_FPSP "_060_real_trap\n"
    rte

/*
#############################################################################

##################################
# (2) EXAMPLE PACKAGE ENTRY CODE #
##################################
*/

#ifdef TRACE_FPSP
_060_fpsp_snan: 
	DBG_TRACE_FPSP "_060_fpsp_snan\n"
    bral	FP_CALL_TOP+0x80+0x00

_060_fpsp_operr: 
	DBG_TRACE_FPSP "_060_fpsp_operr\n"
    bral	FP_CALL_TOP+0x80+0x08

_060_fpsp_ovfl: 
	DBG_TRACE_FPSP "_060_fpsp_ovfl\n"
    bral	FP_CALL_TOP+0x80+0x10

_060_fpsp_unfl: 
	DBG_TRACE_FPSP "_060_fpsp_unfl\n"
    bral	FP_CALL_TOP+0x80+0x18

_060_fpsp_dz:
	DBG_TRACE_FPSP "_060_fpsp_dz\n"
    bral	FP_CALL_TOP+0x80+0x20

_060_fpsp_inex:
	DBG_TRACE_FPSP "_060_fpsp_inex\n"
    bral	FP_CALL_TOP+0x80+0x28

_060_fpsp_unsupp: 
	DBG_TRACE_FPSP "_060_fpsp_unsupp\n"
    bral	FP_CALL_TOP+0x80+0x38

_060_fpsp_effadd: 
	DBG_TRACE_FPSP "_060_fpsp_effadd\n"
    bral	FP_CALL_TOP+0x80+0x40

_060_fpsp_fline: 
	DBG_TRACE_FPSP "_060_fpsp_fline\n"
    bral	FP_CALL_TOP+0x80+0x30

#else
    /* go straight into the package routines */
    _060_fpsp_snan=(FP_CALL_TOP+0x80+0x00) /* signalling not a number */
    _060_fpsp_operr=(FP_CALL_TOP+0x80+0x08) /* FP Operand Error */
    _060_fpsp_ovfl=(FP_CALL_TOP+0x80+0x10) /* overflow */
    _060_fpsp_unfl=(FP_CALL_TOP+0x80+0x18) /* underflow */
    _060_fpsp_dz=(FP_CALL_TOP+0x80+0x20) /* FP DZ (/0) exception. */
    _060_fpsp_inex=(FP_CALL_TOP+0x80+0x28) /* FP Inexact exception */
    _060_fpsp_fline=(FP_CALL_TOP+0x80+0x30) /* "Line F emulator", handles bsun, unimpl, etc */
    _060_fpsp_unsupp=(FP_CALL_TOP+0x80+0x38) /* Unimplemented Data Type" exception */
    _060_fpsp_effadd=(FP_CALL_TOP+0x80+0x40) /* unimplemented effective address */
#endif

/*
#############################################################################

################################
# (3) EXAMPLE CALL-OUT SECTION #
################################

# The size of this section MUST be 128 bytes!!!
*/
.global FP_CALL_TOP
FP_CALL_TOP:
	.long	_060_real_bsun		- FP_CALL_TOP
	.long	_060_real_snan		- FP_CALL_TOP
	.long	_060_real_operr		- FP_CALL_TOP
	.long	_060_real_ovfl		- FP_CALL_TOP
	.long	_060_real_unfl		- FP_CALL_TOP
	.long	_060_real_dz		- FP_CALL_TOP
	.long	_060_real_inex		- FP_CALL_TOP
	.long	_060_real_fline		- FP_CALL_TOP
	.long	_060_real_fpu_disabled	- FP_CALL_TOP
	.long	_060_real_trap		- FP_CALL_TOP
	.long	_060_real_trace		- FP_CALL_TOP     | shared with ISP
	.long	_060_real_access	- FP_CALL_TOP     | shared with ISP
	.long	_060_fpsp_done		- FP_CALL_TOP

	.long	0x00000000,0x00000000,0x00000000

	.long	_060_imem_read-FP_CALL_TOP       | shared with ISP
	.long	_060_dmem_read-FP_CALL_TOP       | shared with ISP
	.long	_060_dmem_write-FP_CALL_TOP      | shared with ISP
	.long	_060_imem_read_word-FP_CALL_TOP  | shared with ISP
	.long	_060_imem_read_long-FP_CALL_TOP  | shared with ISP
	.long	_060_dmem_read_byte-FP_CALL_TOP  | shared with ISP
	.long	_060_dmem_read_word-FP_CALL_TOP  | shared with ISP
	.long	_060_dmem_read_long-FP_CALL_TOP  | shared with ISP
	.long	_060_dmem_write_byte-FP_CALL_TOP | shared with ISP
	.long	_060_dmem_write_word-FP_CALL_TOP | shared with ISP
	.long	_060_dmem_write_long-FP_CALL_TOP | shared with ISP

	.long	0x00000000

	.long	0x00000000,0x00000000,0x00000000,0x00000000

/*
#############################################################################

# 060 FPSP KERNEL PACKAGE NEEDS TO GO HERE!!!
*/

#include "fpsp-bin.S"
