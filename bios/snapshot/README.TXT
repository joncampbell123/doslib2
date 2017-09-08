These programs allow you to take snapshots of locations
of RAM or adapter ROM where your BIOS might reside.

GET1M               Capture 8086-compatible adapter ROM (256KB below 1MB boundary).
GET16286            Capture 286-compatible ROM (1MB below 16MB boundary). For use with 286 systems.
GET16M              Capture 286 or 386SX compatible ROM (1MB below 16MB boundary). For use with 386 systems.
GET64M              Capture 486SX compatible ROM (1MB below 64MB boundary). For use with 486 systems.
GET4G               Capture 1MB below 4GB boundary. For use with 386 or higher with 32-bit address bus.
GET4G_2M            Capture 2MB below 4GB boundary (newer BIOSes that are that large)
GET4G_4M            Capture 4MB below 4GB boundary (newer BIOSes might be that large)
GET4G_8M            Capture 8MB below 4GB boundary (recent BIOSes might be that large)

MS-DOS version notice:

Please note that these programs will not work with EMM386.EXE or any virtual 8086 environment.
For best results, boot MS-DOS from a boot disk or recovery disk and then use these tools.


Please use the version appropriate for your system.


For IBM PC/XT/AT compatible systems (MS-DOS mode only):

GET1M.COM
GET16286.COM
GET16M.COM
GET64M.COM
GET4G.COM
GET4G_2M.COM
GET4G_4M.COM
GET4G_8M.COM


For NEC-9801 and NEC-9821 compatible systems (MS-DOS mode only):

PC98_1M.COM
PC98_16M.COM
PC98_64M.COM
PC98_4G1.COM
PC98_4G2.COM
PC98_4G4.COM
PC98_4G8.COM


For taking snapshots from within the Linux operating system (from root or supervisor only):

linux_get1m
linux_get4g
linux_get4g_2m
linux_get4g_4m
linux_get4g_8m


For taking snapshots from within Windows NT/2000/XP (from an Administrator or System level account only):

winnt_get1m.exe
winnt_get4g.exe

