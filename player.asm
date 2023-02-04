include "include/hardware.inc"

; Constants
STACK_SIZE EQU $7A
;; Stack starts at $FFFE

; $0000 - $003F: RST handlers.

SECTION "restarts", ROM0[$0000]
ret
REPT 7
    nop
ENDR
; $0008
ret
REPT 7
    nop
ENDR
; $0010
ret
REPT 7
    nop
ENDR
; $0018
ret
REPT 7
    nop
ENDR
; $0020
ret
REPT 7
    nop
ENDR
; $0028
ret
REPT 7
    nop
ENDR
; $0030
ret
REPT 7
    nop
ENDR
; $0038
ret
REPT 7
    nop
ENDR

; Interrupt addresses
SECTION "Vblank interrupt", ROM0[$0040]
    reti

SECTION "LCD controller status interrupt", ROM0[$0048]
    ;; HACK!!!!!!!!!!!!!
    ;; there's some sort of bug in the emulator which needs to be fixed,
    ;; which screws up the program counter immediately after it exits a halt.
    ;; this nop protects against that for now.
    nop
    jp isr_wrapper

SECTION "Timer overflow interrupt", ROM0[$0050]
    nop
    jp isr_wrapper

SECTION "Serial transfer completion interrupt", ROM0[$0058]
    reti

SECTION "P10-P13 signal low edge interrupt", ROM0[$0060]
    reti

; Reserved stack space
SECTION "Stack", HRAM[$FFFE - STACK_SIZE]
    ds STACK_SIZE

; Control starts here, but there's more ROM header several bytes later, so the
; only thing we can really do is immediately jump to after the header

SECTION "Header", ROM0[$0100]
    nop
    jp $0150

    NINTENDO_LOGO

; $0134 - $013E: The title, in upper-case letters, followed by zeroes.
DB "HUGE"
DS 7 ; padding
; $013F - $0142: The manufacturer code. Empty for now
DS 4
DS 1
; $0144 - $0145: "New" Licensee Code, a two character name.
DB "NF"

; Initialization
SECTION "main", ROM0[$0150]
    jp _init

isr_wrapper:
    push af
    push hl
    push bc
    push de
    call hUGE_dosound
    pop de
    pop bc
    pop hl
    pop af
    reti

_paint_tile:
    ld a, b
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ret

_init:
    xor a
    ldh [rIF], a
    inc a
    ldh [rIE], a
    halt
    nop

    ; Set LCD palette for grayscale mode; yes, it has a palette
    ld a, %11100100
    ldh [$FF47], a

    ;; Fill with pattern
    ld hl, $8000
    ld bc, `10000000
    call _paint_tile
    ld bc, `01000000
    call _paint_tile
    ld bc, `00100000
    call _paint_tile
    ld bc, `00010000
    call _paint_tile
    ld bc, `00001000
    call _paint_tile
    ld bc, `00000100
    call _paint_tile
    ld bc, `00000010
    call _paint_tile
    ld bc, `00000001
    call _paint_tile

    ; Enable sound globally
    ld a, $80
    ldh [rAUDENA], a
    ; Enable all channels in stereo
    ld a, $FF
    ldh [rAUDTERM], a
    ; Set volume
    ld a, $77
    ldh [rAUDVOL], a

    ld hl, SONG_DESCRIPTOR
    call hUGE_init

IF DEF(USE_TIMER)
    ld a, TIMER_MODULO
    ldh [rTMA], a
    ld a, 4 ; 4096 hz
    ldh [rTAC], a

    ld a, IEF_TIMER
    ldh [rIE], a
    ei
ELSE
    ;; Enable the HBlank interrupt on scanline 0
    ldh a, [rSTAT]
    or a, STATF_LYC
    ldh [rSTAT], a
    xor a ; ld a, 0
    ldh [rLYC], a

    ld a, IEF_LCDC
    ldh [rIE], a
    ei
ENDC

_halt:
    ; Do nothing, forever
    halt
    nop
    jr _halt
