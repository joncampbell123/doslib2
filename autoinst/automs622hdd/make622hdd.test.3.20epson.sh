#!/bin/bash

# WARNING: MS-DOS 3.2 and earlier do not support 1.44MB floppies.
# Unfortunately QEMU will only emulate a 1.44MB floppy drive.
# If you need to use disk images with MS-DOS please use the alternate
# "dosbox" perl script. DOSBox can emulate all varieties of floppy
# disk correctly.

qemu-system-i386 -hda ../../build/msdos320epsonhdd.vdi
