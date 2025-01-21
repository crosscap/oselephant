#!/bin/sh
# This script is used to update the kernal of the in image

gcc -m32 -c -o src/kernel/main.o src/kernel/main.c
ld src/kernel/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o src/kernel/kernel.bin
dd if=./src/kernel/kernel.bin of=./hd60M.img bs=512 count=200 seek=9 conv=notrunc
