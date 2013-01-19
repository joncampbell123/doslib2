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
};								/* =20 bytes */
# pragma pack(pop)

extern struct _dos_dpmi_state dos_dpmi_state;

# define DPMI_SERVER_PROBED		0x01
# define DPMI_SERVER_PRESENT		0x02
# define DPMI_SERVER_INIT		0x04
# define DPMI_SERVER_CAN_DO_32BIT	0x08
# define DPMI_SERVER_INIT_32BIT		0x10

unsigned int dos_dpmi_probe();
unsigned int dos_dpmi_init_server32();
unsigned int dos_dpmi_init_server16();

#endif

