; Master boot loader
;
; LOADER_BASE_ADDR equ 0xA000
; LOADER_START_SECTOR equ 0x2
; ---------------------------------------------
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

    jmp $    ; Infinite loop

    times 510-($-$$) db 0
    db 0x55, 0xaa
