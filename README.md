# README

## Description

Bochs version: 2.6.2

## Some useful commands

### config and install

```sh
./configure --prefix=/home/crosscap/bochs --enable-debugger --enable-disasm --enable-iodebug --enable-x86-debugger --with-x --with-x11
make
make install
```

### run

```sh
bin/bochs -f bochsrc.disk
```

### generage image

```sh
bin/bximage -hd -mode="flat" -size=60 -q hd60M.img
```

### Assemble mbr source code

```sh
nasm -o src/mbr.bin src/mbr.S
```

### Write mbr to image

```sh
dd if=./src/mbr.bin of=./hd60M.img bs=512 count=1 conv=notrunc
```

### Show the content of a file

```sh
xxd -u -a -g 1 -s $2 -l $3 $1
```
