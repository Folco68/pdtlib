; kate: indent-width 8; replace-tabs false; syntax Motorola 68k (VASM/Devpac); tab-width 8;

;==================================================================================================
;
;	pdtlib::GetFilePtr
;
;	Return a pointer to file data. Return 0 if the filename was invalid or couldn't be found
;
;	in	a0	C-style filename
;
;	out	a0	point to the first data byte of the file
;
;	destroy	a0
;
;==================================================================================================

GetFilePtr:	DEFINE	pdtlib@0006

	bsr	GetFileHandle						; Get handle in d0
	movea.w	d0,a0							; a0 = NULL if handle was not found
	tst.w	d0							; Check
	beq.s	\End							; Don't deref if not found
	trap	#3							; Deref
\End:	rts


;==================================================================================================
;
;	pdtlib::GetFileHandel
;
;	Return the handle of a file. Return H_NULL if the filename was invalid or couldn't be found
;
;	in	a0	C-style filename
;
;	out	d0.w	handle
;
;	destroy	d0.l
;
;==================================================================================================

GetFileHandle:	DEFINE	pdtlib@000A

	movem.l	a0-a1/d1-d2,-(sp)
	bsr	CreateSymStr						; Create the SYM_STR
	move.l	a0,d0							; Check it
	bne.s	\SymStrCreated						; Process it if the name is valid
\End:		lea	20(sp),sp
		movem.l	(sp)+,a0-a1/d1-d2
		rts

\SymStrCreated:
	clr.w	-(sp)							; Flags
	pea	(a0)							; SYM_STR*
	ROMC	SymFindPtr
	addq.l	#6,sp							; Pop args
	move.l	a0,d0							; Check the SYM_ENTRY*
	beq.s	\End							; The file was not found
	move.w	12(a0),d0						; Read the handle
	bra.s	\End



;==================================================================================================
;
;	CreateSymStr
;
;	Internal function which creates a SYM_STR, starting from a C-style filename
;
;	in	a0	C-style filename
;
;	out	a0	point to the terminal 0 of the SMY_STR.
;			null if the filename is too long
;
;	destroy	a0-a1/sp
;
;	WARNING: sp is decreased by 20 after the call.
;	It's the responsibility of the caller to restore it
;
;==================================================================================================

CreateSymStr:

	tst.b	(a0)							; Check if it's not a null-string
	beq.s	\Fail
	lea	-20(sp),sp						; Create a buffer
	move.l	20(sp),(sp)						; Restore the return pointer
	lea	4(sp),a1						; First byte of the buffer
	clr.b	(a1)+							; The first byte of a SYM_STR is null
	moveq.l	#8+1+8+1-1,d0						; Counter, to avoid a buffer overflow
\Copy:	move.b	(a0)+,(a1)+						; Copy the filename
	beq.s	\End							; Jump out when the end of the filename is reached
	dbf.w	d0,\Copy
\Fail:		suba.l	a0,a0						; Else the line is too long, return 0
		rts
\End:	lea	-1(a1),a0						; a1 points to the terminal 0
	rts


;==================================================================================================
;
;	pdtlib::CheckFileType
;
;	Check if a file has the requested type\WrongType:

;
;	in	a0	C-style filename
;		a1	custom tag string if d2 is OTH_TAG
;		d2.b	tag
;
;
;	out	d0.w	= 0 if the file is found and the type is ok
;			> 0 if the file is found, but the type is bad or invalid
;			< 0 if the file can't be found
;
;	destroy	std
;
;==================================================================================================

CheckFileType:	DEFINE	pdtlib@0007

	;------------------------------------------------------------------------------------------
	;	Try to get a pointer to file content
	;------------------------------------------------------------------------------------------
	moveq.l	#-1,d0							; Prepare "file not found" return code
	bsr	GetFilePtr						; Get a pointer to file data
	move.l	a0,d1							; Check if the file was found
	beq.s	\End

	;------------------------------------------------------------------------------------------
	;	Basic check of the type (no custom extension)
	;------------------------------------------------------------------------------------------
	moveq.l	#0,d1							; Clear upper part
	move.w	(a0),d1							; Read file size
	lea	1(a0,d1.w),a0						; Tag pointer
	cmp.b	(a0),d2							; Check with argument tag
	bne.s	\WrongType						; Mismatch

	;------------------------------------------------------------------------------------------
	;	Check for OTH_TAG
	;------------------------------------------------------------------------------------------
	moveq.l	#0,d0							; Prepare "type ok" return code
	cmpi.b	#OTH_TAG,d2						; Is this OTH_TAG ?
	bne.s	\End							; No, no further check required

	;------------------------------------------------------------------------------------------
	;	Else the tag is OTH_TAG, we must check the custom extension pointed to by a1
	;	First, get the first byte of the extension in the file
	;------------------------------------------------------------------------------------------
	subq.l	#2,a0							; Last byte of the custom extension
	moveq.l	#4,d1							; The length of a custom extension is 4 bytes max
\Loop:	tst.b	-(a0)
	beq.s	\CheckExtension
	dbf.w	d1,\Loop
\WrongType:	moveq.l	#1,d0						; If the counter is exhausted, the extension is invalid
		bra.s	\End

	;------------------------------------------------------------------------------------------
	;	Check if the extensions match
	;------------------------------------------------------------------------------------------
\CheckExtension:
	move.b	(a0),d0							; Read a byte of the extension
	beq.s	\Check0							; If it's the last one, check that it's the same for the target extension
	cmp.b	(a1)+,d0						; Else compare string bytes
	bne.s	\WrongType						; If they mismatch, type is wrong
	bra.s	\CheckExtension						; Continue to check
\Check0:
	tst.b	(a1)							; We must find a terminal 0 in the second extension
	bne.s	\WrongType						; Else types mismatch

	; d0.w is already 0

\End:	rts
