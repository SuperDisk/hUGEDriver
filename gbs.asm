include "include/hardware.inc"

SECTION "GBS Header", ROM0[$0]
db "GBS" ; magic
db 1 ; version (always 1)
db 1 ; num songs
db 1 ; first song
dw $70+$400 ; load address
dw gbs_init ; init address
dw _hUGE_dosound ; play address
dw $fffe ; stack pointer
db TIMER_MODULO ; timer modulo
db TIMER_CONTROL ; timer control
db "{GBS_TITLE}"
db "{GBS_AUTHOR}"
db "{GBS_COPYRIGHT}"

ds $400 ; padding bytes that will be removed manually

SECTION "Code", ROM0[$70+$400]
gbs_init:
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
