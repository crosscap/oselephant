%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    jmp loader_start

; Build gdt and its internal descriptors
    GDT_BASE:  dd 0x00000000
               dd 0x00000000

    CODE_DESC: dd 0x0000ffff
               dd DESC_CODE_HIGH4

    DATA_STACK_DESC: dd 0x0000ffff
                     dd DESC_DATA_HIGH4

    VIDEO_DESC: dd 0x80000007
                dd DESC_VIDEO_HIGH4

    GDT_SIZE    equ $ - GDT_BASE
    GDT_LIMIT   equ GDT_SIZE - 1
    times 60 dq 0
    SELECTOR_CODE   equ (0x0001 << 3) + TI_DGT + RPL0
    SELECTOR_DATA   equ (0x0002 << 3) + TI_DGT + RPL0
    SELECTOR_VIDEO  equ (0x0003 << 3) + TI_DGT + RPL0

    ; GDT pointer

    gdt_ptr   dw GDT_LIMIT
              dd GDT_BASE
    loadermsg db "2 loader in real."

loader_start:

; ----------------------------------------------------------------
;  INT 0x10    Function number: 0x13    Function description: Print string
; -----------------------------------------------
; Input
; AH = sub function number 0x13
; BH = page number
; BL = attribute (when AL = 00H or 01H)
; CX = string length
; (DL, DH) = coordinates (row, column)
; ES:BP = string address
; AL = string output mode
;   0: only characters in string, attribute in BL, cursor does not move
;   1: only characters in string, attribute in BL, cursor moves
;   2: characters and attribute in string, cursor does not move
;   3: characters and attribute in string, cursor moves
; No return value
    mov sp, LOADER_BASE_ADDR
    mov bp, loadermsg
    mov cx, 17
    mov ax, 0x1301
    mov bx, 0x001f
    mov dx, 0x1800
    int 0x10

; ------------- will be switched to protected mode ----------------
; 1 open A20
; 2 load gdt
; 3 set cr0's PE bit to 1


    ; ------------- open A20 ----------------
    in al, 0x92
    or al, 0000_0010b
    out 0x92, al

    ; ------------- load gdt ----------------
    lgdt [gdt_ptr]


    ; ---- set cr0's PE bit (0 bit) to 1 ----
    mov eax, cr0
    or eax,  0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE : p_mode_start ; clear the prefetch queue


[bits 32]
p_mode_start:
    mov ax,  SELECTOR_DATA
    mov ds,  ax
    mov es,  ax
    mov ss,  ax
    mov esp, LOADER_STACK_TOP
    mov ax,  SELECTOR_VIDEO
    mov gs,  ax

    mov byte [gs:160], 'P'

    jmp $
