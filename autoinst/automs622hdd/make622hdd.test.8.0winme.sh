#!/bin/bash
modprobe kvm
modprobe kvm-intel
qemu-system-i386 -machine pc,accel=kvm -hda ../../build/msdos80winmehdd.vdi
