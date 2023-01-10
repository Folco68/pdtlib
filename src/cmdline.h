; kate: replace-tabs false; syntax Motorola 68k (VASM/Devpac); tab-width 8;

;==================================================================================================
;	Definition of the CMDLINE structure
;==================================================================================================

ARGC	equ	0	; 2	; Can be 0, if RemoveCurrentArg is used. Cannot be negative
ARGV	equ	2	; 4
CURRENT	equ	6	; 2	; Cannot be greater than ARGC
