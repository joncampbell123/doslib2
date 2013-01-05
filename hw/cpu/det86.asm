; CPU detection (for 16-bit only) 8086 -> 286 -> 386

%if TARGET_BITS == 16
;================16-bit only==================
 %ifndef MMODE
  %error You must specify MMODE variable (memory model) for 16-bit real mode code
 %endif

 %ifidni MMODE,l
  %define retnative retf
 %else
  %ifidni MMODE,m
   %define retnative retf
  %else
   %define retnative ret
  %endif
 %endif

 %ifdef TARGET_WINDOWS_WIN16
  extern GETWINFLAGS
 %endif

segment _TEXT class=CODE
use16

;=====================================================================
;unsigned int _cdecl _probe_basic_cpu_0123_86();
;=====================================================================
; return value: 16-bit integer, lower 8 bits are 0, 2, 3 for 8086, 286, or 386
;               upper 8 bits become cpu_flags. this code will set the bit to
;               indicate protected mode if detected.
global _probe_basic_cpu_0123_86
_probe_basic_cpu_0123_86:
	push		cx
	push		bx
	pushf
	cli

 %ifdef TARGET_WINDOWS_WIN16
; As a Windows program: we might be more accurate using GetWinFlags() than trying to
; autodetect especially when it is known the 286 detection code ONLY works in real mode.
	call far	GETWINFLAGS	; => AX
	mov		cx,ax		; for the rest of this routine, CX holds the result
	xor		ax,ax		; pre-set AX == 0 to indicate 8086

	test		cx,0x0024	; WF_CPU386(0x4) | WF_ENHANCED(0x20)
	jnz		.is_386_winflags

  %ifndef TARGET_PROTMODE ; do not carry out these tests if targeting protected mode only, assume protected mode
	test		cx,0x0013	; WF_PMODE(0x1) | WF_CPU286(0x2) | WF_STANDARD(0x10)
	jnz		.is_286

	test		cx,0x0080	; WF_CPU186(0x80)
	jz		.detect_8086
	mov		al,1		; hm... well Windows says this is a 80186 so... why not?
	jmp		.done
  %endif
 %endif

;========================8086 will always set bits 12-15 in EFLAGS=====================
; skip this test if targeting Win16 and compiling ONLY for protected mode, since the fact
; that we're even running implies a 286 or later. If targeting DOS, or Win16 real or "auto"
; targets, then we carry out this test.
; 
; Win16 notes:
;   TARGET_REALMODE        Code intended for real mode (but tangientally compatible with protmode)
;   TARGET_AUTOMODE        Code intended to work properly in either real or protected mode (we auto-detect)
;   TARGET_PROTMODE        Code intended for protected mode only
 %ifndef TARGET_PROTMODE
.detect_8086:
	pushf				; FLAGS -> BX
	pop		bx

	and		bx,0x0FFF	; try to clear bits 12-15

	push		bx		; BX -> FLAGS
	popf
	pushf				; FLAGS -> BX
	pop		bx

	xor		ax,ax		; pre-set AX == 0 to indicate 8086
	and		bx,0xF000	; mask bits 12-15
	cmp		bx,0xF000	; if they are all 1's then this is an 8086
	je		.done		; and jump to end if so
 %endif

.is_286:
;=============================Detect real mode vs. protected mode vs. virtual 8086 mode================
; FIXME: This is fine so far BUT what do we do if the CPU is an 80186 that happens to pass the above test?
;        Executing SMSW on a 80186 will cause an invalid opcode exception. We need to hook INT 6 to catch that exception.
;        A bigger problem is that I do not have a 80186 on hand to test such cases.
;
;        If targeting Win16, then use GetWinFlags() to detect protected mode.
;        If GetWinFlags() doesn't indicate protected mode, or we're a DOS program, then use 'smsw'
;        instruction to detect virtual 8086 mode. It's very unlikely the GetWinFlags() function
;        would lie to us about the CPU mode or attempt to execute 16-bit realmode code in 286
;        protected mode, instead this early test lets us detect 386 virtual 8086 mode.
;
;        Finally, we do NOT carry out the test if targeting protected mode exclusively
 %ifdef TARGET_PROTMODE
	mov		ax,0x0402	; set CPU_FLAG_PROTMODE(0x04) and assume 286
 %else
	mov		al,2		; set AL=2 to indicate 286
  %ifdef TARGET_WINDOWS_WIN16
	test		cx,0x0031	; WF_PMODE(0x1) | WF_STANDARD(0x10) | WF_ENHANCED(0x20)
	jz		.chk_286_smsw	; if none of them are set, proceed to 'smsw' test
	or		ah,0x04		; set CPU_FLAG_PROTMODE(0x04)
	jmp		.chk_286_not_pe
  %endif
.chk_286_smsw:
	smsw		bx		; use SMSW to read the PE bit. We can't do "mov eax,cr0", we don't know if we're on a 386 yet.
	test		bx,1		; if PE is not set, then we're in real mode
	jz		.chk_286_not_pe
	or		ah,0x02		; set CPU_FLAG_V86(0x02)
					; the idea is: if Windows doesn't think we're in protected mode, then Windows must
					; be Windows 1.x/2.x/3.x in real mode running under a virtual 8086 monitor like EMM386.EXE.
					; this code path will also trigger for 16-bit DOS programs since they either run in real
					; mode or in virtual 8086 mode.
	jmp		short .is_386	; we're obviously on a 386, or else virtual 8086 mode wouldn't be possible
.chk_286_not_pe:
 %endif

;==============================A 286 will always clear bits 12-15 in real mode===============
;FIXME: In every case I've tested this works even in protected mode.
	pushf				; save FLAGS. experience says this test is possible but we must restore IOPL
					; or else Windows 3.1 will crash sometimes after this test.

	pushf				; FLAGS -> BX
	pop		bx

	or		bx,0xF000	; set bits 12-15

	push		bx		; BX -> FLAGS
	popf
	pushf				; FLAGS -> BX
	pop		bx

	popf				; restore FLAGS

	and		bx,0xF000	; check bits 12-15
	jz		.done		; if they're zero, then this is a 286

.is_386:
	mov		al,3		; this is a 386

.done:	popf
	pop		bx
	pop		cx
	retnative

; GetWinFlags() jumps here. we just need to parse WF_PROTMODE
.is_386_winflags:
	test		cx,0x0031	; WF_PMODE(0x1) | WF_STANDARD(0x10) | WF_ENHANCED(0x20)
	jz		.is_386		; if not protected mode, proceed directly
	or		ah,0x04		; set CPU_FLAG_PROTMODE(0x04)
	jmp		.is_386		; proceed

segment _DATA class=DATA

segment _BSS class=BSS

group DGROUP _DATA _BSS
;======================END 16-bit================
%endif

;==============32-bit stub to ensure that we show up as an empty 32-bit OBJ file===========
%if TARGET_BITS == 32
section .text
use32

section .data
use32
%endif

