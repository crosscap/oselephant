# README

## Description

Bochs version: 2.6.2

## Some useful commands

### Config and install

```sh
./configure --prefix=/home/crosscap/bochs --enable-debugger --enable-disasm --enable-iodebug --enable-x86-debugger --with-x --with-x11
make
make install
```

### Run

```sh
bin/bochs -f bochsrc.disk
```

### Generate image

```sh
bin/bximage -hd -mode="flat" -size=60 -q hd60M.img
```

### Assemble mbr source code

```sh
nasm -I src/include/ -o src/mbr.bin src/mbr.S
```

### Write mbr to image

```sh
dd if=./src/mbr.bin of=./hd60M.img bs=512 count=1 conv=notrunc
```

### Show the content of a file

```sh
xxd -u -a -g 1 -s $2 -l $3 $1
```

### Assemble loader source

```sh
nasm -I src/include/ -o src/loader.bin src/loader.S
```

### Write loader to image

```sh
dd if=./src/loader.bin of=./hd60M.img bs=512 count=4 seek=2 conv=notrunc
```

### Compile kernel to object file

```sh
gcc -m32 -c -o src/kernel/main.o src/kernel/main.c
```

### Link kernel object file to kernel.bin

```sh
ld src/kernel/main.o -m elf_i386 -Ttext 0xc0001500 -e main -o src/kernel/kernel.bin
```

### Write kernel to image

```sh
dd if=./src/kernel/kernel.bin of=./hd60M.img bs=512 count=200 seek=9 conv=notrunc
```

### Read elf file kernel.bin

```sh
readelf -e src/kernel/kernel.bin
```
