; Master boot loader
; ---------------------------------------------
SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00

; Clear the screen using the 0x06 function, all rows can be cleared when roll up the screen
; -----------------------------------------------
;  INT 0x10      Function number: 0x06      Function Description: Roll up window
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

;;;;;;;;      Get the cursor position      ;;;;;;;;
; .get_cursor
    mov ah, 3   ; Function number: 0x03 Get cursor position
    mov bh, 0   ; Page number

    int 0x10    ; Output: CH = beginning row, CL = end row
                ;         DH = row of cursor, DL = column of cursor

;;;;;;;;    End of get the cursor position    ;;;;;;;;

;;;;;;;;      Print strings      ;;;;;;;;;

    mov ax, message
    mov bp, ax



    mov cx, 5
    mov ax, 0x1301

    mov bx, 0x2

    int 0x10
;;;;;;;;    End of printing string    ;;;;;;;;;

    jmp $    ; Infinite loop

    message db "1 MBR"
    times 510-($-$$) db 0
    db 0x55, 0xaa
