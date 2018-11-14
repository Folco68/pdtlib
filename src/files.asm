;==================================================================================================
;
;	pdtlib::GetFilePtr
;
;	Return a pointer to file data. Return 0 if the filename was invalid or couldn't br found
;
;	in	a0	C-style filename
;
;	out	a0	point to the first data byte of the file
;
;	destroy	a0
;
;==================================================================================================

GetFilePtr:	DEFINE	pdtlib@0006

	movem.l	a1/d0-d2,-(sp)
	bsr	CreateSymStr						; Create the SYM_STR
	move.l	a0,d0							; Check it
	bne.s	\SymStrCreated						; Process it if the name is valid
\End:		lea	20(sp),sp
		movem.l	(sp)+,a1/d0-d2
		rts

\SymStrCreated:
	clr.w	-(sp)							; Flags
	pea	(a0)							; SYM_STR*
	ROMC	SymFindPtr
	addq.l	#6,sp							; Pop args
	move.l	a0,d0							; Check the SYM_ENTRY*
	beq.s	\End							; The file was not found
	movea.w	12(a0),a0						; Read the handle
	trap	#3							; Dereference it
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
