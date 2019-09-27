
INCLUDE "hardware.inc/hardware.inc"


SECTION "Vectors", ROM0[$0000]

rst00:
    ret
	ds 7

rst08:
    ret
	ds 7
rst10:
    ret
	ds 7

rst18:
    ret
	ds 7

rst20:
    ret
	ds 7

rst28:
    ret
	ds 7

rst30:
    ret
    ds 7

rst38:
    ret
    ds 7


; VBlank
    call _dosound
    reti
    ds 4

; STAT
    reti
    ds 7

; Timer
    reti
    ds 7

; Serial
    reti
    ds 7

; Joypad
    reti


; Control starts here, but there's more ROM header several bytes later, so the
; only thing we can really do is immediately jump to after the header
SECTION "init", ROM0[$0100]
    di
    jr EntryPoint
    nop

    ds $150 - $104 ; Allocate header space


DiagonalTile:
    dw `10000000
    dw `01000000
    dw `00100000
    dw `00010000
    dw `00001000
    dw `00000100
    dw `00000010
    dw `00000001

EntryPoint:
    ; Set LCD palette for grayscale mode; yes, it has a palette
    ld a, %11100100
    ld [rBGP], a

    ;; Fill with pattern
    ld hl, $8000
    ld de, DiagonalTile
    ld c, 16
.copyTile
    ldh a, [rSTAT]
    and STATF_BUSY
    jr nz, .copyTile
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, .copyTile


    ; Enable sound globally
    ld a, $80
    ld [rAUDENA], a
    ; Enable all channels in stereo
    ld a, $FF
    ld [rAUDTERM], a
    ; Set volume
    ld a, $77
    ld [rAUDVOL], a

    ;; Load some wave data (or code) into _AUD3WAVERAM
    ld hl, $000 ;; note_table
_addr = _AUD3WAVERAM
    REPT 16
    ld a, [hl+]
    ld [_addr], a
_addr = _addr + 1
    ENDR

    ;;; TODO: remove this!
    ld a, %11110000
    ld [envelope1], a
    ld a, %11110000
    ld [envelope2], a

    ;; Load starting speed (7 ticks per row)
    ld a, 7
    ld [ticks_per_row], a
    ;;; END OF TODO

    ld c, 0 ;; Current order index
    call _refresh_patterns


    ld a, IEF_VBLANK
    ld [rIE], a
    xor a
    ei
    ldh [rIF], a

.wait
    halt
    jr .wait


STACK_SIZE equ $20
SECTION "Stack space", WRAM0[$E000 - STACK_SIZE]

    ds STACK_SIZE
wStackBottom:
