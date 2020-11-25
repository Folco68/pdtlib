; kate: indent-width 8; replace-tabs false; syntax Motorola 68k (VASM/Devpac); tab-width 8;

;==================================================================================================
;
;	pdtlib::InitCmdline
;
;	This function initializes a structure, allowing to parse command line inputs
;
;	in	a0	CMDLINE*
;		a1	char** argv
;		d0	int argc
;
;	out	nothing
;
;	destroy	nothing
;
;==================================================================================================

InitCmdline:	DEFINE	pdtlib@0001

	move.w	d0,ARGC(a0)		; Save argc
	move.l	a1,ARGV(a0)		; Save argv


;==================================================================================================
;
;	pdtlib::ResetCmdline
;
;	Reset a structure of CLI parsing
;
;	in	a0	CMDLINE*
;
;	out	nothing
;
;	destroy	nothing
;
;==================================================================================================

ResetCmdline:	DEFINE	pdtlib@0002

	clr.w	CURRENT(a0)		; Reset parser
	rts


;==================================================================================================
;
;	pdtlib::GetNextArg
;
;	Return a pointer to the next argument of the command line
;
;	in	a0	CMDLINE*
;
;	out	a0	arg, or null if no arg remains
;
;	destroy	d0/a0
;
;==================================================================================================

GetNextArg:	DEFINE	pdtlib@0003

	addq.w	#1,CURRENT(a0)		; Next argument


;==================================================================================================
;
;	pdtlib::GetCurrentArg
;
;	Return a pointer to the current argument of the command line
;
;	in	a0	CMDLINE*
;
;	out	a0	arg, or null if no arg remains
;
;	destroy	d0/a0
;
;==================================================================================================

GetCurrentArg:	DEFINE	pdtlib@0004

	move.w	CURRENT(a0),d0			; Read # current arg
	cmp.w	ARGC(a0),d0			; Does it exist ?
	bcs.s	\GetArg				; Yes
		move.w	ARGC(a0),CURRENT(a0)	; Ensure that CURRENT is not > ARGC (spec)
		suba.l	a0,a0			; No more arg, return null
		rts
\GetArg:
	add.w	d0,d0				; argv is a table of longwords
	add.w	d0,d0
	movea.l	ARGV(a0),a0			; argv**
	movea.l	0(a0,d0.w),a0			; arg
	rts


;==================================================================================================
;
;	pdtlib::ParseCmdline
;
;	Parse a command line, calling a callback for each switch or command found
;	Also call a callback for arguments which are not a switch
;
;	Callback prototypes
;		int callback_not_switch(a0 = void* data);
;		int callbak_switch(a0 = void* data, d0.w = int sign);
;
;	Callback return value (d0.w):
;	PDTLIB_CONTINUE_PARSING		Pdtlib must continue the parsing of the CLI
;	PDTLIB_STOP_PARSING		Pdtlib must stop the parsing of the CLI
;
;	in	4(sp)	CMDLINE* cli
;		8(sp)	(void*)data
;		12(sp)	char* switch table
;		16(sp)	callback is not a switch
;		20(sp)	callback of the first switch
;		24(sp)	callback of the second switch, etc...
;
;	out	d0.w	PDTLIB_END_OF_PARSING
;			PDTLIB_INVALID_SWITCH
;			PDTLIB_SWITCH_NOT_FOUND
;			PDTLIB_INVALID_RETURN_VALUE
;			PDTLIB_STOPPED_BY_CALLBACK
;
;	destroy	std
;
;==================================================================================================

	;------------------------------------------------------------------------------------------
	;	Define some constants to access the args in the stack
	;------------------------------------------------------------------------------------------

CLI			equ	2*4+4
DATA			equ	2*4+8
SWITCH_TABLE		equ	2*4+12
CALLBACK_NO_SWITCH	equ	2*4+16
CALLBACK_SWITCH		equ	2*4+20

	;------------------------------------------------------------------------------------------
	;	Entry point
	;------------------------------------------------------------------------------------------

ParseCmdline:	DEFINE	pdtlib@0005

	movem.l	d3/a2,-(sp)

	;------------------------------------------------------------------------------------------
	;	Start to parse an arg
	;------------------------------------------------------------------------------------------

\NextArg:
	movea.l	CLI(sp),a0					; CMDLINE*
	bsr.s	GetNextArg					; Get the next arg
	move.l	a0,d0						; Is there one ?
	bne.s	\ParseArg					; Yes, parse it
		moveq.l	#PDTLIB_END_OF_PARSING,d0		; Else, we're done with parsing
\EndOfParsing:	movem.l	(sp)+,d3/a2
		rts

	;------------------------------------------------------------------------------------------
	;	Initialize some vars
	;------------------------------------------------------------------------------------------

\ParseArg:
	moveq.l	#0,d1						; Offset in the callback table
	movea.l	SWITCH_TABLE(sp),a2				; Beginning of the table
	move.b	1(a0),d2					; This char may be the second sign in case of a long switch
								; else this is the character of the short switch

	;------------------------------------------------------------------------------------------
	;	Check if we have zero, one or two '+' signs
	;------------------------------------------------------------------------------------------

	moveq.l	#'+',d3						; Start with the '+' sign
	cmp.b	(a0),d3						; First char is '+' ?
	bne.s	\NoPlus						; No, will try with '-'
		cmp.b	d2,d3					; Is this a double sign ?
		beq.s	\LongSwitch				; Yes, so this is a long switch

	;------------------------------------------------------------------------------------------
	;	We have only one sign, check that the switch is 1 char long and null-terminated
	;------------------------------------------------------------------------------------------

\CheckShortSwitch:
	moveq.l	#PDTLIB_INVALID_SWITCH,d0			; Prepare error code
	tst.b	1(a0)						; We need one non-null char
	beq.s	\EndOfParsing
	tst.b	2(a0)						; We need only one char
	bne.s	\EndOfParsing

	;------------------------------------------------------------------------------------------
	;	We have found a short switch, let's try to find it in the table
	;------------------------------------------------------------------------------------------

\ShortSwitchLoop:
	cmp.b	(a2)+,d2					; Is this that switch ?
	beq.s	\SwitchFound					; Yes, call its callback
		bsr.s	\SkipSwitch				; Else we skip this switch
		bra.s	\ShortSwitchLoop			; And we continue with the next one

	;------------------------------------------------------------------------------------------
	;	Check if we have zero, one or two '-' signs
	;------------------------------------------------------------------------------------------

\NoPlus:
	addq.w	#'-'-'+',d3					; '+' to '-' sign
	cmp.b	(a0),d3						; First char is '-' ?
	bne.s	\NoSign						; No, so this arg has no sign
		cmp.b	d2,d3					; Is this a double sign ?
		bne.s	\CheckShortSwitch			; No, so check that it's a valid short switch

	;------------------------------------------------------------------------------------------
	;	We have found a long switch, let's try to find it in the table
	;------------------------------------------------------------------------------------------

\LongSwitch:
	lea	2(a0),a1					; Skip the double sign
\LongSwitchLoop:
	movea.l	a1,a0						; First char of the switch to find
	addq.l	#1,a2						; Skip short switch
\StrCmp:
	move.b	(a0)+,d0					; Switch in CLI
	cmp.b	(a2)+,d0					; Compare with the switch of the table
	beq.s	\Equal
		bsr	\SkipSwitch				; If they are different, try with the next switch
		bra.s	\LongSwitchLoop
\Equal:	tst.b	d0						; End of the switch ?
	beq.s	\SwitchFound					; Yes, so we found the right one
	bra.s	\StrCmp						; Else compare next chars

	;------------------------------------------------------------------------------------------
	;	We have an argument which has no sign
	;------------------------------------------------------------------------------------------

\NoSign:
	movea.l	DATA(sp),a0					; (void*)data
	movea.l	CALLBACK_NO_SWITCH(sp),a1			; Callback ptr
	move.l	a1,d0						; Check if there is a callback for non-switch args
	beq.s	\NextArg					; No
		jsr	(a1)					; int (*)(void*)

	;------------------------------------------------------------------------------------------
	;	We must check that the callback return value is valid
	;------------------------------------------------------------------------------------------

\CheckCallbackReturnValue:
	move.w	d0,d1						; PDTLIB_CONTINUE_PARSING ?
	beq.s	\NextArg					; Yes, continue with next arg

	moveq.l	#PDTLIB_INVALID_RETURN_VALUE,d0			; Prepare for invalid return value
	subq.w	#1,d1						; We get 0 if this is PDTLIB_STOP_PARSING
	bne.s	\EndOfParsing					; But this value is invalid

	moveq.l	#PDTLIB_STOPPED_BY_CALLBACK,d0			; Else the callback stopped the parsing
\EOP:	bra.s	\EndOfParsing					; (Trampoline for far jumps)

	;------------------------------------------------------------------------------------------
	;	We found the switch we're looking for, so call its callback
	;------------------------------------------------------------------------------------------

\SwitchFound:
	move.l	CALLBACK_SWITCH(sp,d1.w),d1			; (*callback)
	beq.s	\NextArg					; Don't run the callback if it's null
		move.w	d3,d0					; (int)sign
		movea.l	DATA(sp),a0				; (void*)data
		movea.l	d1,a1					; (*callback)
		jsr	(a1)					; int (*)(void*, int)
		bra.s	\CheckCallbackReturnValue		; We need to test the return value of the callback

	;------------------------------------------------------------------------------------------
	;	Skip a switch in the table
	;	a2 points somewhere in the long switch
	;	Update the offset register
	;	Throw an error if the table is exhausted
	;------------------------------------------------------------------------------------------

\SkipSwitch:
	tst.b	(a2)+						; Skip current switch
	bne.s	\SkipSwitch
		tst.b	(a2)					; Does another switch exist ?
		bne.s	\NextSwitch				; Yes, there is a short form
			tst.b	1(a2)				; Is there a long form at least ?
			beq.s	\SwitchNotFound			; No, so the current switch wasn't found
\NextSwitch:			addq.w	#4,d1			; Offset in the callback table
				rts

\SwitchNotFound:
	moveq.l	#PDTLIB_SWITCH_NOT_FOUND,d0			; Error code
	addq.l	#4,sp						; Drop the return address of \SkipSwitch
	bra.s	\EOP						; Goto EndOfParsing


;==================================================================================================
;
;	pdtlib::RemoveCurrentArg
;
;	Remove the current arg from the argv table. Usefull when parsing the CLI multiple times
;	The previous arg becomes the current one. First arg (the program name) can't be removed
;
;	in	a0	CMDLINE*
;
;	out	d0	0 if no current arg or current arg is #0
;
;	destroy	nothing
;
;==================================================================================================

RemoveCurrentArg:	DEFINE pdtlib@0009

	movem.l	a0/d1,-(sp)					; Save regs

	;------------------------------------------------------------------------------------------
	;	Safety checks: is there an arg to remove?
	;------------------------------------------------------------------------------------------

	move.w	ARGC(a0),d1
	move.w	CURRENT(a0),d0
	beq.s	\Fail						; Cannot remove program name
	cmp.w	d0,d1
	beq.s	\Fail						; No current arg to remove

	;------------------------------------------------------------------------------------------
	;	Now we can adjust CMDLINE vars
	;------------------------------------------------------------------------------------------

	subq.w	#1,ARGC(a0)					; One less arg
	subq.w	#1,CURRENT(a0)					; Previous arg becomes the current one

	;------------------------------------------------------------------------------------------
	;	Get the number of args to move, then move them
	;------------------------------------------------------------------------------------------

	sub.w	d0,d1						; ARGC - CURRENT
	subq.w	#2,d1						; Remove one arg + counter adjustment =
	bmi.s	\End						; The arg to remove is the last one, nothing to do on the list
	bmi.s	\Fail						; The arg to remove is the last one, nothing to do on the list
		add.w	d0,d0					; CURRENT * 2
		add.w	d0,d0					; CURRENT * 4 (table of pointers)
		movea.l	ARGV(a0),a0				; Read argv**
		lea	0(a0,d0.w),a0				; Pointer to the current arg, which is removed
\Loop:	move.l	4(a0),(a0)+					; Move the next arg to the previous position
	dbra.w	d1,\Loop

\End:	movem.l	(sp)+,a0/d1					; Restore regs
	rts

\Fail:	moveq.l	#0,d0
	bra.s	\End
