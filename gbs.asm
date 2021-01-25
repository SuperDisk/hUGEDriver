include "include/HARDWARE.INC"

SECTION "GBS Header", ROM0[$0]
db "GBS" ; magic
db 1 ; version (always 1)
db 1 ; num songs
db 1 ; first song
dw $70+$400 ; load address
dw gbs_init ; init address
dw _hUGE_dosound ; play address
dw $fffe ; stack pointer
db 0
db 0
db GBS_TITLE
db GBS_AUTHOR
db GBS_COPYRIGHT

ds $400 ; padding bytes that will be removed manually

SECTION "Code", ROM0[$70+$400]
gbs_init:
    ld a, 0
    ld [rIF], a
    inc a
    ld [rIE], a
    halt
    nop

    ; Enable sound globally
    ld a, $80
    ld [rAUDENA], a
    ; Enable all channels in stereo
    ld a, $FF
    ld [rAUDTERM], a
    ; Set volume
    ld a, $77
    ld [rAUDVOL], a

    ld hl, SONG_DESCRIPTOR
    jp hUGE_init
