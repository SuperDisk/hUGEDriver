include "include/hardware.inc"

DEF SINGLE_INTERRUPT EQU 1

; Constants
DEF STACK_SIZE EQU $7A
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
    ; nop
    ; jp isr_wrapper
    nop
    reti

SECTION "Timer overflow interrupt", ROM0[$0050]
    nop
    jp isr_timer

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


SECTION "sample playback", WRAM0
_play_sample:: dw
_play_length:: dw

call_counter: db

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

    ; cleanup sample player
    ld hl, _play_sample
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

    ; setup timer
    ld a, $c0
    ldh [rTMA], a
    ld a, 7
    ldh [rTAC], a

    ld hl, SONG_DESCRIPTOR
    call hUGE_init

    if !DEF(SINGLE_INTERRUPT)
        ;; Enable the HBlank interrupt on scanline 0
        ld a, [rSTAT]
        or a, STATF_LYC
        ld [rSTAT], a
        xor a ; ld a, 0
        ld [rLYC], a
        ld a, IEF_LCDC | IEF_TIMER
    else
        ld a, IEF_TIMER
    ENDC

    ld [rIE], a
    ei


_halt:
    ; Do nothing, forever
    halt
    nop
    jr _halt


isr_timer:
    push af
    push hl
    push bc
    push de

    ld hl, _play_length     ;; something left to play?
    ld a, [hl+]
    or [hl]
    jr z, .timer02

    ld hl, _play_sample
    ld a, [hl+]
    ld h, [hl]
    ld l, a                 ;; HL = current position inside the sample

    xor a
    ldh [rAUD3ENA],a

FOR OFS, 16
    ld a, [hl+]
    ldh [_AUD3WAVERAM + OFS], a
ENDR

    ld a, $80               ; retrigger wave channel
    ldh [rAUD3ENA],a
    xor a
    ld [rAUD3ENA], a

    ld a, $80
    ldh [rAUD3ENA],a
    ld a, $FE               ; length of wave
    ldh [rAUD3LEN],a
    ld a, $20               ; volume
    ldh [rAUD3LEVEL],a
    xor a                   ; low freq bits are zero
    ldh [rAUD3LOW],a
    ld a, $C7               ; start; no loop; high freq bits are 111
    ldh [rAUD3HIGH],a

    ld a, l                 ; save current position
    ld [_play_sample], a
    ld a, h
    ld [_play_sample+1], a

    ld hl, _play_length     ; decrement length variable
    ld a, [hl]
    sub 1
    ld [hl+], a
    ld a, [hl]
    sbc 0
    ld [hl-], a

.timer02:
    if DEF(SINGLE_INTERRUPT)
        ld a, [call_counter]
        inc a
        and 3
        ld [call_counter], a
        call z, _hUGE_dosound
    ENDC

    pop de
    pop bc
    pop hl
    pop af
    reti