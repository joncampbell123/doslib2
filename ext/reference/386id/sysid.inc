
BIOS_SEG segment use16 at 0F000h ; Start BIOS_SEG segment

	 org	 0FFFEh
SYSID	 db	 ?		; The CPU's identification byte

; System ID equates for byte at F000:FFFE

.xcref @SYS_PC,@SYS_XT,@SYS_JR,@SYS_AT,@SYS_XT2,@SYS_M30,@SYS_CNV,@SYS_M80
@SYS_PC  equ	 0FFh		; IBM PC
@SYS_XT  equ	 0FEh		; IBM PC XT
@SYS_JR  equ	 0FDh		; IBM PCjr
@SYS_AT  equ	 0FCh		; IBM PC AT & PS/2 Model 50/60
@SYS_XT2 equ	 0FBh		; IBM PC XT with 256/640 system board
@SYS_M30 equ	 0FAh		; IBM PS/2 Model 30
@SYS_CNV equ	 0F9h		; IBM PC Convertible
@SYS_M80 equ	 0F8h		; IBM PS/2 Model 80

BIOS_SEG ends			; End BIOS_SEG segment

