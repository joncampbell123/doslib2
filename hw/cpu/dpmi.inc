%ifdef TARGET_MSDOS
 %if TARGET_BITS == 16

; DEBUG: Enable this %define to replace the SSE instruction with a deliberate
;        bad opcode to ensure the exception handler works even on modern CPUs
;        that do in fact support SSE, such as using Windows XP to test this code.
;%define TEST_EXCEPTION_HANDLER

struc s_dos_dpmi_state
	.flags			resb	1	; +0 unsigned char	flags;
	.entry_ip		resw	1	; +1 unsigned short	entry_ip;
	.entry_cs		resw	1	; +3 unsigned short	entry_cs;
	.dpmi_private_size	resw	1	; +5 unsigned short	dpmi_private_size;
	.dpmi_version		resw	1	; +7 unsigned short	dpmi_version;
	.dpmi_processor		resb	1	; +9 unsigned char	dpmi_processor;
	.dpmi_private_segment	resw	1	; +10 unsigned short	dpmi_private_segment;
	.dpmi_cs		resw	1	; +12 unsigned short	dpmi_cs;
	.dpmi_ds		resw	1	; +14 unsigned short	dpmi_ds;
	.dpmi_es		resw	1	; +16 unsigned short	dpmi_es;
	.dpmi_ss		resw	1	; +18 unsigned short	dpmi_ss;
	.r2p_entry_ip		resw	1	; +20 unsigned short	r2p_entry_ip;
	.r2p_entry_cs		resw	1	; +22 unsigned short	r2p_entry_cs;
	.p2r_entry		resw	3	; +24 unsigned short	p2r_entry[3];
	.my_psp			resw	1	; +30 unsigned short	my_psp;
	.selector_increment	resw	1	; +32 unsigned short	selector_increment;
	.call_cs		resw	1	; +34 unsigned short	call_cs;
	.call_ds		resw	1	; +36 unsigned short	call_ds;
						; +38
endstruc

  %ifndef DPMIE16_ASM
extern _dos_dpmi_state
  %endif

 %define DPMI_SERVER_PROBED		0x01
 %define DPMI_SERVER_PRESENT		0x02
 %define DPMI_SERVER_INIT		0x04
 %define DPMI_SERVER_CAN_DO_32BIT	0x08
 %define DPMI_SERVER_INIT_32BIT		0x10

 %endif
%endif

