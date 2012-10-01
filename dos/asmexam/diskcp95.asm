;--------------------------------------------------------------------------------------
; DISKCP95.COM
;
; Ask for free disk space the Windows 95 FAT32 way.
;
; For more information:
; http://www.ctyme.com/intr/rb-3227.htm
; 
; CAUTION: This code requires a 386 or higher. This is a reasonable requirement when
;          you consider Windows 95 requires a 386 or higher anyway even in pure DOS mode.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		mov	di,fat32info	; clear the fat32info data area.
		mov	cx,0x30/2	; note that Windows 95 will fail the next call
		xor	ax,ax		; if we don't do this!
		cld
		rep	stosw

		mov	ah,0x19		; AH=0x19 get current default drive
		int	21h
		add	al,'A'		; convert 0..25 to A..Z
		mov	[drive_str],al	; change the drive_str to (for example) "C:\"

		mov	ax,0x7303	; Get FAT32 free disk space
		mov	dx,drive_str	; DS:DX = string to drive path (ex. "C:\")
		mov	di,fat32info	; ES:DI = buffer to hold FAT32 info
		mov	cx,0x30		; CX = length of buffer
		stc			; set carry just in case
		int	21h		; do it!
		jnc	drive_ok	; if no error, then proceed to print out info

		mov	dx,str_invalid_drv
		call	puts
		ret

; drive is OK, print out the contents
; NOTE: We use the success of this call as a sign that, yes, we're under Windows 95
;       and therefore we're free to use 386 32-bit registers as needed to do our job.
;       If that assumption is wrong, your 286 or older system will probably crash at
;       this point of the program and you will need to CTRL+ALT+DEL to restart.
drive_ok:	cmp	word [fat32info],0x2C	; make sure it's at least as large as we expect
		jae	fat32sz_ok
		mov	dx,str_fat32sz_inval
		jmp	short err_str_exit

fat32sz_ok:	cmp	word [fat32info+2],0	; make sure it's version 0
		jz	fat32ver_ok
		mov	dx,str_fat32ver_inval
		jmp	short err_str_exit

fat32ver_ok:	mov	eax,[fat32info+4]	; EAX = sectors per cluster
		mul	dword [fat32info+8]	; EAX *= bytes per sector
		mov	[bytes_per_cluster],eax

		mov	eax,[fat32info+12]	; EAX = number of available clusters
		mul	dword [bytes_per_cluster] ; EDX:EAX = free disk space available
		call	edx_eax_bytes_to_units	; convert to a 32-bit integer with units we can print
		call	putdec32		;  => EAX a number
		call	puts			;  => DX pointer to the suffix string
		mov	dx,str_ex_free
		call	puts

		mov	eax,[fat32info+16]	; EAX = number of total clusters
		mul	dword [bytes_per_cluster] ; EDX:EAX = total disk space available
		call	edx_eax_bytes_to_units	; convert to a 32-bit integer with units we can print
		call	putdec32		;  => EAX a number
		call	puts			;  => DX pointer to the suffix string
		mov	dx,str_ex_total
		call	puts

; EXIT to DOS
exit:		ret

err_str_exit:	call	puts
		mov	dx,crlf
		call	puts
		ret

;------------------------------------
; input: EDX:EAX = disk capacity in bytes
; output: EAX = 32-bit value to print on console
;         DS:DX = string to print as suffix
edx_eax_bytes_to_units:
		mov	di,str_suf_bytes	; assume by default, unit in bytes
		or	edx,edx			; if EDX:EAX <= 0xFFFFFFFF then we can stop right here
		jz	edx_eax_bytes_to_units_done

		shrd	eax,edx,10		; EDX:EAX >>= 10
		shr	edx,10
		mov	di,str_suf_kbytes	; now it's in kilobytes
		or	edx,edx			; small enough now?
		jz	edx_eax_bytes_to_units_done

		shrd	eax,edx,10		; EDX:EAX >>= 10
		shr	edx,10
		mov	di,str_suf_mbytes	; now it's in megabytes
		or	edx,edx			; small enough now?
		jz	edx_eax_bytes_to_units_done

		shrd	eax,edx,10		; EDX:EAX >>= 10
		shr	edx,10
		mov	di,str_suf_gbytes	; now it's in gigabytes (NTS: Think FAT32 partitions would ever get THIS big?)

edx_eax_bytes_to_units_done:
		mov	dx,di
		ret

;------------------------------------
puts:		push	ax
		push	bx
		push	cx
		mov	ah,0x09
		int	21h
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
; EAX = value to print
putdec32:	push	eax
		push	ebx
		push	ecx
		push	edx

		xor	edx,edx
		mov	cx,1
		mov	ebx,10
		div	ebx
		push	dx

putdec32_loop:	or	eax,eax
		jz	putdec32_pl
		xor	edx,edx
		inc	cx
		div	ebx
		push	dx
		jmp	short putdec32_loop

putdec32_pl:
putdec32_ploop:	pop	ax
		add	al,'0'
		call	putc
		loop	putdec32_ploop

		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		ret

		segment .data

str_invalid_drv:db	'Invalid drive',13,10,'$'
str_ex_free:	db	' free',13,10,'$'
str_ex_total:	db	' total',13,10,'$'
str_suf_bytes:	db	' bytes$'
str_suf_kbytes:	db	'KB$'
str_suf_mbytes:	db	'MB$'
str_suf_gbytes:	db	'GB$'
str_fat32sz_inval:db	'Invalid struct size$'
str_fat32ver_inval:db	'Invalid struct version$'
crlf:		db	13,10,'$'

; this will be overwritten with the drive letter
drive_str:	db	'?:\',0

		segment .bss

fat32info:	resb	0x30

bytes_per_cluster: resd 1

