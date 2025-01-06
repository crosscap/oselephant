; ----------   loader and kernel   ----------
LOADER_BASE_ADDR equ 0x900
LOADER_START_SECTOR equ 0x2

; -------- GDT descriptor attribute ---------
DESC_G_4k           equ 1000_0000_0000_0000_0000_0000b
DESC_D_32           equ  100_0000_0000_0000_0000_0000b
DESC_L              equ   00_0000_0000_0000_0000_0000b
DESC_AVL            equ    0_0000_0000_0000_0000_0000b
DESC_LIMIT_CODE2    equ      1111_0000_0000_0000_0000b
DESC_LIMIT_DATA2    equ      DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2   equ      0000_0000_0000_0000_0000b
DESC_P              equ           1000_0000_0000_0000b
DESC_DEL_0          equ            000_0000_0000_0000b
DESC_DEL_1          equ            010_0000_0000_0000b
DESC_DEL_2          equ            100_0000_0000_0000b
DESC_DEL_3          equ            110_0000_0000_0000b
DESC_S_CODE         equ              1_0000_0000_0000b
DESC_S_DATA         equ              DESC_S_CODE
DESC_S_sys          equ              0_0000_0000_0000b
DESC_TYPE_CODE      equ                1000_0000_0000b
DESC_TYPE_DATA      equ                0010_0000_0000b

DESC_CODE_HIGH4  equ  (0x00<<24)+DESC_G_4k+DESC_D_32+DESC_L+DESC_AVL+DESC_LIMIT_CODE2 +DESC_P+DESC_DEL_0+DESC_S_CODE+DESC_TYPE_CODE+0x00
DESC_DATA_HIGH4  equ  (0x00<<24)+DESC_G_4k+DESC_D_32+DESC_L+DESC_AVL+DESC_LIMIT_DATA2 +DESC_P+DESC_DEL_0+DESC_S_DATA+DESC_TYPE_DATA+0x00
DESC_VIDEO_HIGH4 equ  (0x00<<24)+DESC_G_4k+DESC_D_32+DESC_L+DESC_AVL+DESC_LIMIT_VIDEO2+DESC_P+DESC_DEL_0+DESC_S_DATA+DESC_TYPE_DATA+0x0b

; ---------- Selector attributes ----------
RPL0 equ 00b
RPL1 equ 01b
RPL2 equ 10b
RPL3 equ 11b
TI_DGT equ 000b
TI_LGT equ 100b
