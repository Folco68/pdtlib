;==================================================================================================
;	ROM call macro. It's ROM_THROW, but shorter to avoid breaking indentation
;==================================================================================================

ROMC	macro
	ROM_THROW	\1
	endm


;==================================================================================================
;	Constant
;==================================================================================================

OTH_TAG	equ	$F8	; AMS tag for files which have a custom extension
