#!/bin/sh

if [[ ! -f ./src/hd60M.img ]]; then
  bin/bximage -hd -mode="flat" -size=60 -q hd60M.img

fi

if [[ ! -f ./src/mbr.bin ]]; then
  nasm -I src/include/ -o src/mbr.bin src/mbr.S
fi

if [[ ! -f ./src/loader.bin ]]; then
  nasm -I src/include/ -o src/loader.bin src/loader.S
fi

if [[ ! -f ./src/kernel/kernel.bin ]]; then
  gcc -m32 -c -o src/kernel/main.o src/kernel/main.c
  ld src/kernel/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o src/kernel/kernel.bin
fi

dd if=./src/mbr.bin of=./hd60M.img bs=512 count=1 conv=notrunc
dd if=./src/loader.bin of=./hd60M.img bs=512 count=4 seek=2 conv=notrunc
dd if=./src/kernel/kernel.bin of=./hd60M.img bs=512 count=200 seek=9 conv=notrunc
