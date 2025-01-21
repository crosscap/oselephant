#!/bin/sh

bin/bximage -hd -mode="flat" -size=60 -q hd60M.img
nasm -I src/include/ -o src/mbr.bin src/mbr.S
dd if=./src/mbr.bin of=./hd60M.img bs=512 count=1 conv=notrunc
nasm -I src/include/ -o src/loader.bin src/loader.S
dd if=./src/loader.bin of=./hd60M.img bs=512 count=4 seek=2 conv=notrunc
gcc -m32 -c -o src/kernel/main.o src/kernel/main.c
ld src/kernel/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o src/kernel/kernel.bin
dd if=./src/kernel/kernel.bin of=./hd60M.img bs=512 count=200 seek=9 conv=notrunc
