COMMENT|   MASM Macros	 |

.xcref REGSAVE,REGREST,NPPROC,FPPROC,MEND

	 if1
REGSAVE  macro	 LIST		; Register save macro

	 irp	 XX,<LIST>
	 push	 XX
	 endm

	 endm			; REGSAVE


REGREST  macro	 LIST		; Register restore macro

	 irp	 XX,<LIST>
	 pop	 XX
	 endm

	 endm			; REGREST


NPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 near
	 endm			; NPPROC


FPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 far
	 endm			; FPPROC


MEND	 macro	 @START

	 if1
%OUT Pass 1 complete
	 else
%OUT Pass 2 complete
	 endif

	 end	 @START

	 endm			; MEND


.xcref CPUID
CPUID	 macro

	 db	 0Fh,0A2h	; MASM doesn't support CPUID as yet

	 endm			; CPUID


STROUT	 macro	 TEXT

	 lea	 dx,TEXT	; DS:DX ==> string to display
	 mov	 ah,09h 	; Function code to display string
	 int	 21h		; Request DOS service

	 endm			; STROUT


GETINT	 macro	 NN

	 mov	 ah,35h 	; Function code to get interrupt handler
	 mov	 al,NN		; Get interrupt #
	 int	 21h		; Request DOS service

	 endm			; GETINT


SETINT	 macro	 NN,FCN

ifnb <FCN>
	 lea	 dx,FCN 	; DS:DX ==> interrupt handler
endif
	 mov	 ah,25h 	; Function code to set interrupt handler
	 mov	 al,NN		; Get interrupt #
	 int	 21h		; Request DOS service

	 endm			; SETINT


.xcref PUSHD
PUSHD	 macro	 NN		; 32-bit PUSH

	 db	 66h
	 push	 NN

	 endm			; PUSHD


.xcref SGDTD
SGDTD	 macro	 I,J,K,L,M,N

	 db	 66h		; Use 32-bit pointer
	 sgdt	  I J K L M N

	 endm			; SGDTD


.xcref SIDTD
SIDTD	 macro	 I,J,K,L,M,N

	 db	 66h		; Use 32-bit pointer
	 sidt	  I J K L M N

	 endm			; SIDTD


.xcref LGDTD
LGDTD	 macro	 I,J,K,L,M,N

	 db	 66h		; Use 32-bit pointer
	 lgdt	  I J K L M N

	 endm			; LGDTD


.xcref LIDTD
LIDTD	 macro	 I,J,K,L,M,N

	 db	 66h		; Use 32-bit pointer
	 lidt	  I J K L M N

	 endm			; LIDTD


	 endif			; IF1 ******************************


; Useful equates

.xcref @OPCOD_JMPF
@OPCOD_INT  equ  0CDh		; Opcode for INT
@OPCOD_JMPF equ  0EAh		; Opcode for immediate far jump

.xcref @BIT0
@BIT0	 equ	 01h		; Bit #0 in a byte

.xcref BEL,TAB,CR,LF,EOS
BEL	 equ	 07h		; Bell
TAB	 equ	 09h		; Tab
CR	 equ	 0Dh		; Carriage return
LF	 equ	 0Ah		; Linefeed
EOS	 equ	 '$'            ; End of string

.xcref @IMR,@IMR2
@IMR	 equ	 21h		; 8259 port for Master Mask Register
@IMR2	 equ	 21h+80h	; ...		Slave  Mask Register

.xcref @8255_A,@8255_B,@8042_ST,@PS2_A
@8255_A  equ	 60h		; Read-only in PC/XT, Read/write in AT
@8255_B  equ	 61h		; Read/write
@8042_ST equ	 64h		; Status port
@PS2_A	 equ	 92h		; PS/2 System Control Port A

.xcref @S2C_DIS,@S2C_ENA,@S2C_ROUT,@S2C_WOUT
.xcref @S2C_SHUT,@S2C_RESET
@S2C_DIS    equ  0ADh		; Keyboard disable
@S2C_ENA    equ  0AEh		; Keyboard enable
@S2C_ROUT   equ  0D0h		; Read	output port
@S2C_WOUT   equ  0D1h		; Write output port
@S2C_SHUT   equ  0FEh		; Shutdown
@S2C_RESET  equ  0FFh		; Ensure in stable state

.xcref @S2K_LED,@S2K_ENABLE
@S2K_LED    equ  0EDh		; Set/reset LEDs
@S2K_ENABLE equ  0F4h		; Enable keyboard

.xcref @K2S_RESEND
@K2S_RESEND equ  0FEh	; Resend last command

.xcref CPL0_DATA,CPL0_CODE,CPL0_BUSY3
CPL0_DATA equ	 10010010b	; Data, writable
CPL0_CODE equ	 10011010b	; Code, nonconforming, readable
CPL0_BUSY3 equ	 10001011b	; Busy 386 TSS		B


; Records and Structures

.xcref @8255_B_REC
@8255_B_REC record $KEYB:1,$FILLB:1,$XTPAR:2,$ATPAR:2,$SPKR:1,$TIMER2:1


.xcref @8042_ST_REC
@8042_ST_REC record $PAR:1,$RCVTIM:1,$TRNTIM:1,$KINH:1,$DATA:1,$SYSTST:1,$INPFULL:1,$OUTFULL:1


.xcref @8042_OUT
@8042_OUT record $S2O_DATA:1,$S2O_CLOCK:1,$S2O_IBFMT:1,$S2O_OBFUL:1,$S2O_UNDEF:2,$S2O_GATE:1,$S2O_RESET:1

.xcref @S2O_D20,@S2O_E20
@S2O_D20    equ  0DDh	; Disable A20
@S2O_E20    equ  0DFh	; Enable A20


; PS/2 System Control Port A

.xcref PS2SCP_A
PS2SCP_A record  $PS2_FD0:1,$PS2_FD1:1,$PS2_RSV0:1,$PS2_WD:1,$PDS2_LOCK:1,$PS2_RSV1:1,$PS2_GATE:1,$PS2_RESET:1


.xcref CPUFLAGS,$AC,$VM,$RF
.xcref		$R0,$NT,$IOPL,$OF,$DF,$IF,$TF,$SF,$ZF,$R1,$AF,$R2,$PF,$R3,$CF
CPUFLAGS record  $ID:1,$VIP:1,$VIF:1,$AC:1,$VM:1,$RF:1, \
		 $R0:1,$NT:1,$IOPL:2,$OF:1,$DF:1,$IF:1,$TF:1,$SF:1,$ZF:1,$R1:1,$AF:1,$R2:1,$PF:1,$R3:1,$CF:1


.xcref CR0FLAGS,$PG,$CD,$NW,$CR0RSV0,$AM,$CR0RSV1,$WP
.xcref $CR0RSV2,$NE,$ET,$TS,$EM,$MP,$PE
CR0FLAGS record  $PG:1,$CD:1,$NW:1,$CR0RSV0:10,$AM:1,$CR0RSV1:1,$WP:1,\
		 $CR0RSV2:10,$NE:1,$ET:1,$TS:1,$EM:1,$MP:1,$PE:1


; Descriptor type record for system GDT entries

.xcref DSYS_REC,$DS_386,$DS_GATE,$DS_BUSY,$DS_TASK
DSYS_REC record  $DS_386:1,$DS_GATE:1,$DS_BUSY:1,$DS_TASK:1


; Move block Descriptor Table Entry structure

.xcref MDTE_STR,MDTE_DUMMY,MDTE_GDT,MDTE_DS,MDTE_ES,MDTE_BIOS,MDTE_SS
MDTE_STR struc

MDTE_DUMMY dq	 ?		; 00:  First entry not accessible
MDTE_GDT  dq	 ?		; 08:  Global descriptor table
MDTE_DS   dq	 ?		; 10:  DS ...
MDTE_ES   dq	 ?		; 18:  ES ...
MDTE_BIOS dq	 ?		; 20:  Temporary BIOS ...
MDTE_SS   dq	 ?		; 28:  SS ...

MDTE_STR ends


; Dscriptor table structure

.xcref DESC_STR,DESC_SEGLM0,DESC_BASE01,DESC_BASE2,DESC_ACCESS,DESC_SEGLM1,DESC_BASE3
DESC_STR struc

DESC_SEGLM0 dw	 ?		; 0-1: Segment limit, 0-15
DESC_BASE01 dw	 ?		; 2-3: Segment base bytes 0-1
DESC_BASE2  db	 ?		; 4  :		    byte  2
DESC_ACCESS db	 ?		; 5  : Access rights
DESC_SEGLM1 db	 ?		; 6  : Segment limit, 16-19, and flags
DESC_BASE3  db	 ?		; 7  :		    byte  3

DESC_STR ends


; Descriptor Table Register Structure

.xcref DTR_STR,DTR_LIM,DTR_BASE
DTR_STR  struc

DTR_LIM  dw	 ?		; Limit (#bytes - 1)
DTR_BASE dd	 ?		; Base offset

DTR_STR  ends


; Structures for Virtual DMA Services

.xcref XDDS_STR,XDDS_SIZE,XDDS_FVEC,XDDS_AVL,XDDS_USED,XDDS_ADDR0,XDDS_SIZE0
XDDS_STR struc

XDDS_SIZE dd	 ?		; 00-03:  Region size
XDDS_FVEC df	 ?		; 04-09:  Linear segment/selector:offset
	  dw	 ?		; 0A-0B:  (reserved)
XDDS_AVL  dw	 1		; 0C-0D:  # entries available
XDDS_USED dw	 ?		; 0E-0F:  # entries used (or would be used)
XDDS_ADDR0 dd	 ?		; 10-13:  Region #0 physical address
XDDS_SIZE0 dd	 ?		; 14-17:  Region #0 size in bytes

XDDS_STR ends


; Equate for testing VDS presence byte at 40:7B

.xcref @VDS_ENA
@VDS_ENA equ	 00100000b	; Virtual DMA services enabled


; Equates for calling VDS functions

.xcref @VDS_SLOCK,@VDS_SUNLK
@VDS_SLOCK equ	 8105h		; Scatter/gather lock DMA region
@VDS_SUNLK equ	 8106h		; Scatter/gather unlock DMA region


.xcref VECTOR,VOFF,VSEG
VECTOR	 struc

VOFF	 dw	 ?		; Offset
VSEG	 dw	 ?		; Segment

VECTOR	 ends


.xcref HILO_STR,LO,HI
HILO_STR struc

LO	 db	 ?		; Register low-order byte
HI	 db	 ?		; Register high-order byte

HILO_STR ends


.xcref EGP_STR,ELO,EHI
EGP_STR  struc

ELO	 dw	 ?		; Extended register low-order word
EHI	 dw	 ?		; Extended register high-order word

EGP_STR  ends


.xcref EDD_STR,EDD
EDD_STR struc

EDD	 dd	 ?		; Doubleword

EDD_STR ends


.xcref EDF_STR,EDF
EDF_STR struc

EDF	 df	 ?		; Six-bytes

EDF_STR ends


.xcref EDQ_STR,EDQLO,EDQHI
EDQ_STR struc

EDQLO	 dd	 ?		; Low-order dword
EDQHI	 dd	 ?		; High-...

EDQ_STR ends


