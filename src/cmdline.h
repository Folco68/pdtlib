; kate: replace-tabs false; syntax Motorola 68k (VASM/Devpac); tab-width 8;

;==================================================================================================
;	Definition of the CMDLINE structure
;==================================================================================================

ARGC	equ	0	; 2	== 4 * argc in "int main(int argc, char** argv)", because it's always used to read in a table of longwords
ARGV	equ	2	; 4
CURRENT	equ	6	; 2
