; Spec:
;
;	- Internal: 0 <= CMDLINE.CURRENT <= CMDLINE.ARGC
;	- Internal: CMDLINE.ARGC == 4 * argc in "int main(int argc, char** argv)"
;	- Internal: CMDLINE.CURRENT is an offset, so it starts at 0 and is increased by 4 for the next arg
;	- All the args can be disabled, even the first one (program name)
;	- GetNextArg always returns the first enabled arg
;	- GetCurrentArg returns the first available arg after RewindCmdlineParser is called
;	- GetCurrentArg returns the first available arg, even after a call to DisableArg


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
;	destroy	d0
;
;==================================================================================================

InitCmdline:	DEFINE	pdtlib@0001

	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,ARGC(a0)		; argc * 4
	move.l	a1,ARGV(a0)		; argv


;==================================================================================================
;
;	pdtlib::RewindCmdlineParser
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

RewindCmdlineParser:	DEFINE	pdtlib@0002

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

	addq.w	#4,CURRENT(a0)


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

	pea	(a0)				; Save CMDLINE*

\Loop:	move.w	CURRENT(a0),d0			; Read current index
	cmp.w	ARGC(a0),d0			; Is it over the last one?
	bcs.s	\NotEnd				; No
		move.w	ARGC(a0),CURRENT(a0)	; Ensure spec
		suba.l	a0,a0			; And return null
		bra.s	\End
\NotEnd:
	movea.l	ARGV(a0),a0			; argv
	move.l	0(a0,d0.w),d0			; arg*
	bpl.s	\Ok				; >0 means that the arg is enabled, we can return it
		movea.l	(sp)+,a0		; Restore CMDLINE* and reset sp
		bra.s	GetNextArg		; Try to get the next arg
\Ok:	movea.l	d0,a0				; Current arg ptr
\End:	addq.l	#4,sp				; Pop stack
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
	movea.l	CLI(sp),a0
	bsr.s	GetCurrentArg
	bra.s	\CurrentArg

	;------------------------------------------------------------------------------------------
	;	Start to parse an arg
	;------------------------------------------------------------------------------------------

\NextArg:
	movea.l	CLI(sp),a0					; CMDLINE*
	bsr.s	GetNextArg					; Get the next arg
\CurrentArg:
	move.l	a0,d0						; Is there one ?
	bne.s	\ParseArg					; Yes, parse it
		moveq	#PDTLIB_END_OF_PARSING,d0		; Else, we're done with parsing
\EndOfParsing:	movem.l	(sp)+,d3/a2
		rts

	;------------------------------------------------------------------------------------------
	;	Initialize some vars
	;------------------------------------------------------------------------------------------

\ParseArg:
	moveq	#0,d1						; Offset in the callback table
	movea.l	SWITCH_TABLE(sp),a2				; Beginning of the table
	move.b	1(a0),d2					; This char may be the second sign in case of a long switch
								; else this is the character of the short switch

	;------------------------------------------------------------------------------------------
	;	Check if we have zero, one or two '+' signs
	;------------------------------------------------------------------------------------------

	moveq	#'+',d3						; Start with the '+' sign
	cmp.b	(a0),d3						; First char is '+' ?
	bne.s	\NoPlus						; No, will try with '-'
		cmp.b	d2,d3					; Is this a double sign ?
		beq.s	\LongSwitch				; Yes, so this is a long switch

	;------------------------------------------------------------------------------------------
	;	We have only one sign, check that the switch is 1 char long and null-terminated
	;------------------------------------------------------------------------------------------

\CheckShortSwitch:
	moveq	#PDTLIB_INVALID_SWITCH,d0			; Prepare error code
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
\Jump:		jsr	(a1)					; Trampoline for int (*)(void*) or int (*)(void*, int)

	;------------------------------------------------------------------------------------------
	;	We must check that the callback return value is valid
	;------------------------------------------------------------------------------------------

\CheckCallbackReturnValue:
	move.w	d0,d1						; PDTLIB_CONTINUE_PARSING ?
	beq.s	\NextArg					; Yes, continue with next arg

	moveq	#PDTLIB_INVALID_RETURN_VALUE,d0			; Prepare for invalid return value
	subq.w	#1,d1						; We get 0 if this is PDTLIB_STOP_PARSING
	bne.s	\EndOfParsing					; But this value is invalid

	moveq	#PDTLIB_STOPPED_BY_CALLBACK,d0			; Else the callback stopped the parsing
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
		bra.s	\Jump

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
	moveq	#PDTLIB_SWITCH_NOT_FOUND,d0			; Error code
	addq.l	#4,sp						; Drop the return address of \SkipSwitch
	bra.s	\EOP						; Goto EndOfParsing


;==================================================================================================
;
;	pdtlib::DisableCurrentArg
;
;	Disable the current arg from the argv table by setting its upper byte to $FF (16 MB < $FFxxxxxx < 4GB).
; 	It won't be returned anymore by GetNextArg until ResetCmdlineParser is called
;
;	in	a0	CMDLINE*
;
;	out	d0	0 if no current arg or current arg is #0
;
;	destroy	nothing
;
;==================================================================================================

DisableCurrentArg:	DEFINE pdtlib@0009

	pea	(a0)				; Don't want to destroy a0
	move.w	CURRENT(a0),d0
	cmp.w	ARGC(a0),d0			; Parser at the end?
	bne.s	\Disable			; No, so we can disable the arg
		moveq	#0,d0			; Else set error code
		bra.s	\End
\Disable:
	movea.l	ARGV(a0),a0
	st	0(a0,d0.w)			; Set upper byte of the arg ptr to $FF
	moveq	#1,d0				; Ensure a correct return value when disabling first arg
\End:	movea.l	(sp)+,a0
	rts


;==================================================================================================
;
;	pdtlib::ResetCmdlineParser
;
;	Restore the disabled arg and reset the parser to the first element
;
;	in	a0	CMDLINE*
;
;	out	nothing
;
;	destroy	nothing
;
;==================================================================================================

ResetCmdlineParser:	DEFINE pdtlib@000D

	movem.l	d0-d1/a0,-(sp)
	clr.w	CURRENT(a0)			; Reset parser to first arg
	move.w	ARGC(a0),d0
	subq.w	#4,d0				; ARGC - 4 = offset
	move.w	d0,d1
	lsr.w	#2,d1				; argc - 1 = dbf counter
	movea.l	ARGV(a0),a0
\Loop:	clr.b	0(a0,d0.w)			; Enable each arg
	subq.w	#4,d0				; Offset of the previous arg
	dbf.w	d1,\Loop
	movem.l	(sp)+,d0-d1/a0
	rts
