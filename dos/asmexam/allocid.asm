;--------------------------------------------------------------------------------------
; ALLOCID.COM
;
; Get allocation information for default drive.
; INT 21h AH=0x1B. Returns DS:BX which is a pointer to a media ID byte.
; It is said that in DOS 1.x DS:BX points to an actual copy of the FAT (where the first
; byte is the media ID)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		clc
		mov	ax,0x1B00	; AH=0x1B get allocation information for default drive
		xor	cx,cx		; clear all output registers. it's not clear from Ralph's
		mov	dx,cx		; list how this syscall signals an error condition.
		mov	bx,cx
		int	21h
		jc	info_cf		; error?

		test	bx,bx
		jnz	info_ok
		push	cs
		pop	ds
		mov	dx,str_failed
		call	puts
		mov	dx,crlf
		call	puts
info_cf:	jmp	exit
info_ok: ; <=== it worked. print the info
		; output: DS:BX = pointer to media ID byte
		;         AL = sectors per cluster
		;         CX = bytes per sector
		;         DX = total number of clusters
		mov	ah,[bx]		; read media ID byte
		push	cs		; restore DS
		pop	ds
		mov	[media_id],ah	; store it
		xor	ah,ah

		push	ax
		push	dx
		mov	dx,str_total_clusters
		call	puts
		pop	dx
		mov	ax,dx		; print total cluster count
		call	puthex16
		push	dx
		mov	dx,crlf
		call	puts
		pop	dx
		pop	ax

		push	ax
		mov	dx,str_sectors_per_cluster
		call	puts
		pop	ax
		call	puthex8
		mov	dx,crlf
		call	puts

		mov	dx,str_bytes_per_sector
		call	puts
		mov	ax,cx
		call	puthex16
		mov	dx,crlf
		call	puts

		mov	dx,str_media_id
		call	puts
		mov	al,[media_id]
		call	puthex8
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
		ret			; in case 0x4C fails

;------------------------------------
puts:		mov	ah,0x09
		int	21h
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
puthex8:	push	ax
		push	bx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes]
		call	putc
		pop	bx
		pop	ax
		ret

;------------------------------------
puthex16:	push	ax
		xchg	al,ah
		call	puthex8
		pop	ax
		call	puthex8
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
str_failed:	db	'Failed$'
str_total_clusters:db	'Total clusters: 0x$'
str_sectors_per_cluster:db 'Sectors/cluster: 0x$'
str_bytes_per_sector:db	'Bytes/sector: 0x$'
str_media_id:	db	'Media ID byte: 0x$'
crlf:		db	13,10,'$'

		segment .bss

media_id	resb	1

