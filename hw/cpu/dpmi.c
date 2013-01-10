
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <hw/cpu/cpu.h>
#include <hw/cpu/cpusse.h>
#include <misc/useful.h>
#include <hw/cpu/dpmi.h>

#if defined(TARGET_MSDOS) && TARGET_BITS == 16

struct _dos_dpmi_state		dos_dpmi_state = {
	0,			/* +0 flags */
	0,0,			/* +1 IP:CS */
	0,			/* +5 dpmi_private_size */ 
	0,			/* +7 dpmi_version */
	0,			/* +9 dpmi_cpu */
	0			/* +10 dpmi_private_segment */
};

unsigned int dos_dpmi_probe() {
	if (!(dos_dpmi_state.flags & DPMI_SERVER_PROBED)) {
		dos_dpmi_state.flags |= DPMI_SERVER_PROBED;

		__asm {
			push		ax
			push		bx
			push		si
			push		di
			push		es

			mov		ax,0x1687
			int		0x2F
			or		ax,ax
			jnz		nodpmi

			; NTS: We access the structure in this way because Watcoms inline assembler
			;      offers no way to directly refer to structure members, apparently.
			mov		ax,bx					; save BX
#  if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
			mov		bx,seg dos_dpmi_state
			mov		ds,bx
#  endif
			mov		bx,offset dos_dpmi_state
			or		byte ptr [bx],DPMI_SERVER_PRESENT	; .flags |= PRESENT
			mov		word ptr [bx+1],di			; .entry_ip = DI
			mov		word ptr [bx+3],es			; .entry_cs = ES
			mov		word ptr [bx+5],si			; .dpmi_private_size = SI
			mov		word ptr [bx+7],dx			; .dpmi_version = DX (DH,DL)
			mov		byte ptr [bx+9],cl			; .dpmi_processor = CL

			test		ax,1					; does the DPMI server support 32-bit?
			jz		no32bit
			or		byte ptr [bx],DPMI_SERVER_CAN_DO_32BIT
no32bit:

nodpmi:			pop		es
			pop		di
			pop		si
			pop		bx
			pop		ax
		}
	}

	return dos_dpmi_state.flags;
}

unsigned int dos_dpmi_init_server32() {
	return 0;
}

unsigned int dos_dpmi_init_server16() {
	return 0;
}

#endif

