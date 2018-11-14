	include "tios.h"
	include "romcalls.h"
	include "krnlramc.h"
	include "cmdline.h"
	include	"internal.h"
	include "pdtlib.h"
	
	xdef	_ti89
	xdef	_ti89ti
	xdef	_ti92plus
	xdef	_v200
	
	xdef	_library
	DEFINE	_flag_3		; Read-only
	DEFINE	_version02	; Version 2 of Pdtlib
	xdef	_comment

	include "cmdline.asm"
	include "libs.asm"
	include "parsing.asm"
	include "files.asm"

_comment:	dc.b	"pdtlib 2.0 by Folco",0
