;==================================================================================================
;
;	pdtlib::InstallTrampolines
;
;	This function opens a library, and creates trampolines, using a table of functions
;	to load, and a table of offsets to know where the trampolines must be located
;
;	in	a0	libname
;		d1.b	minimum version
;		a1	table of functions which need a trampoline
;		a2	table of offsets of the trampolines, starting from the base address
;		a3	base address
;
;	out	a0	lib descriptor, or null if the lib couldn't be opened
;
;	destroy	a0/d0-d1
;
;==================================================================================================

	DEFINE	pdtlib@0000
	
	RAMC	kernel_LibsBegin		; Try to open the library
	move.l	a0,-(sp)			; Test and save the descriptor
	beq.s	\End				; Return if it failed

	moveq.l	#0,d1				; Offset in the tables (tables of word)
\Loop:	movea.l	(sp),a0				; Read descriptor
	move.w	0(a1,d1.w),d0			; Read function rank
	bmi.s	\End				; End of table
		RAMC	kernel_LibsPtr		; Get a pointer to the function
		move.w	0(a2,d1.w),d0		; Offset from the base address
		move.w	#$4EF9,0(a3,d0.w)	; Write jmp x.l opcode
		move.l	a0,2(a3,d0.w)		; Write address
		addq.l	#2,d1			; Update offset in the tables
		bra.s	\Loop

\End:	move.l	(sp)+,a0			; Lib descriptor, return value
	rts
