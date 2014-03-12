;--------------------------------------------------------------------------------------
; SANITY7.COM
;
; 386 or higher: test whether it catches attempts to execute MOV CR0, ...
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP

		xor	eax,eax
		mov	cr3,eax		; should not trigger the TF disable

		xor	eax,eax
		mov	cr0,eax
		xor	ebx,ebx
		mov	cr0,ebx
		xor	ecx,ecx
		mov	cr0,ecx
		xor	edx,edx
		mov	cr0,edx
		xor	esi,esi
		mov	cr0,esi
		xor	edi,edi
		mov	cr0,edi

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

		segment .bss

tmp:		resd	1

