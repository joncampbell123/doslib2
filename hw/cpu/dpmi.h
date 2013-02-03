#if defined(TARGET_MSDOS) && TARGET_BITS == 16
# define DOS_DPMI_AVAILABLE 1

# pragma pack(push,1)
struct _dos_dpmi_state {
	unsigned char			flags;
	unsigned short			entry_ip,entry_cs;
	unsigned short			dpmi_private_size;	/* in paragraphs */
	unsigned short			dpmi_version;
	unsigned char			dpmi_processor;
	unsigned short			dpmi_private_segment;
	unsigned short			dpmi_cs;		/* code segment given by DPMI server */
	unsigned short			dpmi_ds;		/* data segment given by DPMI server */
	unsigned short			dpmi_es;		/* ES segment given by DPMI server */
	unsigned short			dpmi_ss;		/* SS segment given by DPMI server */
	unsigned short			r2p_entry_ip,r2p_entry_cs; /* real-to-prot raw switch */
	unsigned short			p2r_entry[3];		/* prot-to-real raw switch (16:16 if 16-bit, 16:32 if 32-bit) */
	unsigned short			my_psp;			/* PSP segment */
	unsigned short			selector_increment;	/* selector increment value (usually 8) */
	unsigned short			call_cs,call_ds;	/* alternate CS and DS for calling subroutines */
};								/* =38 bytes */
# pragma pack(pop)

extern struct _dos_dpmi_state dos_dpmi_state;

# define DPMI_SERVER_PROBED		0x01
# define DPMI_SERVER_PRESENT		0x02
# define DPMI_SERVER_INIT		0x04
# define DPMI_SERVER_CAN_DO_32BIT	0x08
# define DPMI_SERVER_INIT_32BIT		0x10
# define DPMI_SERVER_NEEDS_PROT_TERM	0x20
/* ^ Explanation: Most DPMI servers assume the DOS program will stay in protected mode
 *   and will only terminate from protected mode. If the DOS program terminates from
 *   real mode the DPMI server will most likely not get the message and remain in memory.
 *   Memory leaks and (in the case of Windows 3.1 or XP) descriptor leaks will occur.
 *   This flag will be set for those scenarios. In the few known cases where the DPMI
 *   server will actually catch the realmode case (such as the Windows 95/98/ME DOS box)
 *   this flag will NOT be set. */

unsigned int dos_dpmi_probe();
unsigned int dos_dpmi_init_server32();
unsigned int dos_dpmi_init_server16();

/* once you init DPMI, you can make subroutine calls back into protected mode */
void __cdecl dos_dpmi_protcall16(void far *proc);

void dos_dpmi_protcall16_test();
extern unsigned char dos_dpmi_protcall_test_flag;

#endif

