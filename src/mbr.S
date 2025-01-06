; Master boot loader
; ---------------------------------------------
%include "boot.inc"
SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

; Clear the screen using the 0x06 function,
; all rows can be cleared when roll up the screen
; -----------------------------------------------
;  INT 0x10    Function number: 0x06    Function Description: Roll up window
; -----------------------------------------------
; input
; AH function number = 0x06
; AL = Number of rows on the roll (if zero, all)
; BH = up-roll row attribute
; (CL, CH) = (X, Y) position in the upper-left corner of the window
; (DL, DH) = (X, Y) position in the lower-right corner of the window
; There is no return value
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0                       ; Top Left: (0, 0)
    mov dx, 0x184f                  ; Bottom right: (80, 25)


    int 0x10

    ; Print flashing "1 MBR" with green background and red front
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0xA4

    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xA4

    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0xA4

    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0xA4

    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0xA4

    mov eax, LOADER_START_SECTOR    ; Starting sector LAB address
    mov bx, LOADER_BASE_ADDR        ; Write address
    mov cx, 4                       ; Number of sectors to be read in
    call rd_disk_m_16               ; Read the first sector of the loader

    jmp LOADER_BASE_ADDR

; -----------------------------------------------
; function: read n sectors from hard disk
rd_disk_m_16:
; -----------------------------------------------
        ; eax=LBA sector code
        ; bx=memory address where data will wirte
        ; cx=number of sectors to be read in
    mov esi, eax
    mov di, cx
; Wait and read the hard disk
; Step 1: Set the number of sectors to be read in
    mov dx, 0x1f2
    mov al, cl  ; number of sectors to be read in
    out dx, al  ; write to the 0x1f2 port

    mov eax, esi

; Step 2: Load the LBA address to the 0x1f3-0x1f6 port

    ; 0-7 bits of LBA address
    mov dx, 0x1f3
    out dx, al

    ; 8-15 bits of LBA address
    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    ; 16-23 bits of LBA address
    shr eax, cl
    mov dx, 0x1f5
    out dx, al

    shr eax, cl
    and al, 0x0f    ; 24-27 bits of LBA address
    or al, 0xe0     ; set 4-7 bits to 1110 which means lba mode
    mov dx, 0x1f6
    out dx, al

; Step 3: Set the read command 0x20 to the 0x1f7 port
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

; Step 4: Check if the hard disk is ready
.not_ready:
    ; write command when writing and disk status when reading
    nop
    in al, dx
    and al, 0x88    ; bit 3 = 1: ready, bit 7 = 1:busy
    cmp al, 0x08
    jnz .not_ready  ; if not ready, continue to check

; Step 5: Read the data from the hard disk using the 0x1f0 port
    mov ax, di      ; Store the number of sectors in di
    mov dx, 256     ; 512 bytes per sector, 256 words per sector
    mul dx
    mov cx, ax

    mov dx, 0x1f0
.go_on_read:
    in ax, dx
    mov [bx], ax
    add bx, 2
    loop .go_on_read
    ret

    times 510-($-$$) db 0
    db 0x55, 0xaa
