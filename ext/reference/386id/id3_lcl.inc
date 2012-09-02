
; Equates for LCL_FLAG

LCL_REC  record  $LCL_I06 :1,	\
		 $LCL_MC  :1,	\
		 $LCL_XT  :1,	\
		 $LCL_BIOS:1,	\
		 $LCL_XFTB:1,	\
		 $LCL_CPU :1,	\
		 $LCL_ROMINT:1

@LCL_I06  equ	 (mask $LCL_I06)    ; INT 06h handler invoked
@LCL_MC   equ	 (mask $LCL_MC)     ; System is Micro Channel
@LCL_XT   equ	 (mask $LCL_XT)     ; System is PC/XT
@LCL_BIOS equ	 (mask $LCL_BIOS)   ; ID came from BIOS
@LCL_XFTB equ	 (mask $LCL_XFTB)   ; System does not have a fully-terminated bus
@LCL_CPU  equ	 (mask $LCL_CPU)    ; ID came from CPUID instruction
@LCL_ROMINT equ  (mask $LCL_ROMINT) ; System ROM INT instruction found

