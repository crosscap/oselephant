%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR

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

    ; The address of this data is 0xb00
    ; Will be used in the kernel
    ;
    total_mem_bytes dd 0
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; GDT pointer 2 bytes limit, 4 bytes base
    gdt_ptr   dw GDT_LIMIT
              dd GDT_BASE

    ; Manual alignment: total_mem_bytes + gdt_ptr + ards_buf + ards_nr = 256 bytes
    ards_buf times 244 db 0
    ards_nr dw 0    ; Number of ARDS entries

loader_start:

; int 15h eax = 0xe820, edx = 0x534d4150 (SMAP) to get memory map

    xor ebx, ebx
    mov edx, 0x534d4150
    mov di,  ards_buf
.e820_mem_get_loop:
    mov eax, 0x0000e820
    mov ecx, 20
    int 0x15
    jc  .e820_failed_so_try_e801
    add di,  cx
    inc word [ards_nr]
    cmp ebx, 0
    jnz .e820_mem_get_loop

; find out the maximum value of (base_addr_low + length_low) as the memory area
    mov cx,  [ards_nr]
    mov ebx, ards_buf
    xor edx, edx
.find_max_mem_area:
    mov eax, [ebx]
    add eax, [ebx+8]
    add ebx, 20
    cmp edx, eax
    ja .next_ards
    mov edx, eax
.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

; int 15h ax = 0xe801 to get memory size, maximum 4GB
;
;
.e820_failed_so_try_e801:
    mov ax,  0xe801
    int 0x15
    jc  .e801_failed_so_try88

; calculate the low 16MB memory
    mov cx,  0x400
    mul cx
    shl edx, 16
    and eax, 0x0000ffff
    or  edx, eax
    add edx, 0x100000
    mov esi, edx

; calculate the high memory
    xor eax, eax
    mov ax,  bx
    mov ecx, 0x10000
    mul ecx
    add esi, eax
    mov edx, esi
    jmp .mem_get_ok

; int 15h ax = 0xe88 to get memory size, maximum 64MB
.e801_failed_so_try88:
    ; ax = memory size in KB after the call
    mov ah,  0x88
    int 0x15
    jc  .error_hlt
    and eax, 0x0000ffff

    ; calculate the memory size in bytes
    mov cx,  0x400
    mul cx
    shl edx, 16
    or  edx, eax
    add edx, 0x100000

.mem_get_ok:
    mov [total_mem_bytes], edx

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

.error_hlt:
    hlt

[bits 32]
p_mode_start:
    mov ax,  SELECTOR_DATA
    mov ds,  ax
    mov es,  ax
    mov ss,  ax
    mov esp, LOADER_STACK_TOP
    mov ax,  SELECTOR_VIDEO
    mov gs,  ax

; -------------- Load kernel --------------
    mov eax, KERNEL_START_SECTOR
    mov ebx, KERNEL_BIN_BASE_ADDR
    mov ecx, 200

    call rd_disk_m_32

; Create page directory and page table, and initialize page memory bitmap
    call setup_page

; Put descriptor table into memory gdt_ptr
    sgdt [gdt_ptr]

; Set the segment base address in the video segment descriptor in the gdt descriptor + 0xc0000000
    mov ebx, [gdt_ptr + 2]
    or dword [ebx + 8 * 3 + 4], 0xc0000000
;

; Add 0xc0000000 to the base address of gdt to make it the high address where the kernel is located
    add dword [gdt_ptr + 2], 0xc0000000

    add esp, 0xc0000000

; Set the page directory address to cr3
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

; Set the PE bit of cr0 to 1
    mov eax, cr0
    or  eax, 0x80000000
    mov cr0, eax

; Load new gdt address
    lgdt [gdt_ptr]

;;;;;;;;;;; Refresh the pipeline ;;;;;;;;;;;;
;
;
    jmp SELECTOR_CODE:enter_kernel
enter_kernel:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    call kernel_init
    mov esp, 0xc009f000
    jmp KERNEL_ENTRY_POINT


; --------- Copy kernel to compiled address in memory ---------
kernel_init:
    xor eax, eax
    xor ebx, ebx    ; ebx is the offset of kernel.bin in memory
    xor ecx, ecx    ; ecx is the number of program header entries
    xor edx, edx    ; edx is the size of program header entry

    mov dx,  [KERNEL_BIN_BASE_ADDR + 42]
    mov ebx, [KERNEL_BIN_BASE_ADDR + 28]

    add ebx, KERNEL_BIN_BASE_ADDR
    mov cx,  [KERNEL_BIN_BASE_ADDR + 44]
.each_segment:
    cmp byte [ebx + 0], PT_NULL
    je .PTNULL


    push dword [ebx + 16]
    mov  eax,  [ebx + 4]
    add  eax,  KERNEL_BIN_BASE_ADDR
    push eax
    push dword [ebx + 8]
    call mem_cpy
    add esp, 12
.PTNULL:
    add ebx, edx
    loop .each_segment
    ret

; --------- Copy memory for each byte ---------
; Parameters: Three parameters in the stack (dst, src, size)
; Return: None
; -----------------------------------------------
mem_cpy:
    cld
    push ebp
    mov  ebp, esp
    push ecx
    mov  edi, [ebp + 8]
    mov  esi, [ebp + 12]
    mov  ecx, [ebp + 16]
    rep movsb

    ; Recover environment
    pop ecx
    pop ebp
    ret


; --------- Create page directory and page table ---------
setup_page:
; Clear page directory
    mov ecx, 4096
    mov esi, 0
  .clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS + esi], 0
    inc esi
    loop .clear_page_dir

; Create page directory entry (PDE)
.create_pde:
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x1000
    mov ebx, eax

;
; The addresses below 0xc03ffff and 0x003ffff both point to the same page table
; Prepare the page table for the kernel
    or eax, PG_US_U | PG_RW_W | PG_P
    mov [PAGE_DIR_TABLE_POS + 0x0], eax
    mov [PAGE_DIR_TABLE_POS + 0xc00], eax

    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_POS + 4092], eax

; Create page table entry (PTE)
    mov ecx, 256
    mov esi, 0
    mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx+esi*4], edx
    add edx, 4096
    inc esi
    loop .create_pte

; Create other kernel page directory entry (PDE)
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000
    or eax, PG_US_U | PG_RW_W | PG_P
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254
    mov esi, 769
.create_krnel_pde:
    mov [ebx+esi*4], eax
    inc esi
    add eax, 0x1000
    loop .create_krnel_pde
    ret


; -----------------------------------------------
; function: read n sectors from hard disk
rd_disk_m_32:
; -----------------------------------------------
        ; eax=LBA sector code
        ; ebx=memory address where data will wirte
        ; ecx=number of sectors to be read in
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
    or  al, 0xe0     ; set 4-7 bits to 1110 which means lba mode
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
    in  al, dx
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
    in  ax, dx
    mov [ebx], ax
    add ebx, 2
    loop .go_on_read
    ret
