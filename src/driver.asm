;; hUGETracker playback routine
;; Written by SuperDisk 2019

include "hardware.inc/hardware.inc"
include "include/notes.inc"

;; Size of a channel in bytes
CHANNEL_SIZE EQU 8
;; Amount to be shifted in order to skip a channel.
CHANNEL_SIZE_EXPONENT EQU 3

add_a_to_r16: MACRO
    add a, \2
    ld \2, a
    adc a, \1
    sub \2
    ld \1, a
ENDM

;; TODO: See if there's a way to shave off a byte.
sub_from_r16: MACRO ;; (high, low, value)
    ld a, \2
    sub \3
    ld \2, a
    ld a, \1
    sbc a, 0
    ld \1, a
ENDM

add_a_to_hl: MACRO
    add_a_to_r16 h, l
ENDM

add_a_to_de: MACRO
    add_a_to_r16 d, e
ENDM

ret_dont_call_playnote: MACRO
    pop hl
    pop af
    ld a, 6 ; How many bytes until the next channel's code
    add_a_to_hl
    jp hl
ENDM

; Constants

PATTERN_LENGTH EQU 64
; TICKS EQU 4


SECTION "Sound driver", ROM0

_refresh_patterns::
;; Loads pattern registers with pointers to correct pattern based on
;; an order index

;; Call with c set to what order to load
load_pattern: MACRO
    ld hl, 0
    ld l, c
    ld de, \1
    add hl, de

    ld a, [hl+]
    ld [\2], a
    ld a, [hl+]
    ld [\2+1], a
ENDM
    load_pattern order1, pattern1
    load_pattern order2, pattern2
    load_pattern order3, pattern3
    load_pattern order4, pattern4
    ret

_load_note_data:
    ;; Call with:
    ;; Pattern pointer in BC

    ;; Stores instrument/effect code in B
    ;; Stores effect params in C
    ;; Stores note number in A
    ld a, [row]
    ld h, a
    ;; Multiply by 3 for the note value
    add h
    add h

    add 2
    ld h, 0
    ld l, a
    add hl, bc ; HL now points at the 3rd byte of the note
    ld a, [hl-]
    ld c, a
    ld a, [hl-]
    ld b, a

    ld a, [hl]

    ret

_lookup_note:
    ;; Call with:
    ;; Pattern pointer in BC
    ;; channel_noteX pointer in DE

    ;; Stores note period value in HL
    ;; Stores instrument/effect code in B
    ;; Stores effect params in C
    ;; Stores note number in the memory pointed to by DE
    call _load_note_data
    ld hl, 0

    ;; If the note we found is greater than LAST_NOTE, then it's not a valid note
    ;; and nothing needs to be updated.
    cp LAST_NOTE
    ret nc

    ;; Store the loaded note value in channel_noteX
    ld h, d
    ld l, e
    ld [hl], a

_convert_note:
    ;; Call with:
    ;; Note number in A
    ;; Stores note period value in HL

    add a ;; double it to get index into hi/lo table

    ld hl, note_table
    add_a_to_hl
    ld     a, [hl+]
    ld     h, [hl]
    ld     l, a

    ;; Need to clear the carry flag-- this complements it, but since the last
    ;; thing that modified the flag always sets it, this will clear it.
    ccf
    ret

_update_channel:
    ;; Call with:
    ;; Channel in B
    ;; Note tone in DE

    ;; TODO: Turn this into a jump table? Or find some other way to optimize
    ld a, b

    cp 3
    jp z, _update_channel4
    cp 2
    jp z, _update_channel3
    cp 1
    jp z, _update_channel2

_update_channel1:
    ld hl, highmask1
    ld a, e
    ld [rAUD1LOW], a
    ld a, d
    ; or [hl]
    ; and %01111111
    ld [rAUD1HIGH], a
    ret
_update_channel2:
    ld hl, highmask2
    ld a, e
    ld [rAUD2LOW], a
    ld a, d
    ; or [hl]
    ; and %01111111
    ld [rAUD2HIGH], a
    ret
_update_channel3:
    ld hl, highmask3
    ld a, e
    ld [rAUD3LOW], a
    ld a, d
    ; or [hl]
    ; and %01111111
    ld [rAUD3HIGH], a
    ret
_update_channel4:
    ld hl, highmask4
    call _quantize_channel4_note
    ld [rAUD4POLY], a
    ; ld a, [hl]
    ; and %01111111
    ld a, 0
    ld [rAUD4GO], a
    ret

    ;;;;;;;
    ;; Note playing routines. Need to either consolidate these or find some
    ;; better way of doing effects that happen on the first tick.
    ;;;;;;;

_playnote1:
    ;; Call with:

    ;; Play a note on channel 1 (square wave)
    ld a, [temp_note_value+1]
    ld [channel_period1], a
    ld [rAUD1LOW], a

    ld a, [temp_note_value]
    ld [channel_period1+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask1
    or [hl]
    ld [rAUD1HIGH], a

    ret

_playnote2:
    ;; Play a note on channel 2 (square wave)
    ld a, [temp_note_value+1]
    ld [channel_period2], a
    ld [rAUD2LOW], a

    ld a, [temp_note_value]
    ld [channel_period2+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask2
    or [hl]
    ld [rAUD2HIGH], a

    ret

_playnote3:
    ;; Play a note on channel 3 (waveform)
    ld a, [temp_note_value+1]
    ld [channel_period3], a
    ld [rAUD3LOW], a

    ld a, [temp_note_value]
    ld [channel_period3+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask3
    or [hl]
    ld [rAUD3HIGH], a

    ret

_playnote4:
    ;; Play a "note" on channel 4 (noise)

    ld a, [temp_note_value+1]
    ld [channel_period4], a
    ld e, a

    ld a, [temp_note_value]
    ld [channel_period4+1], a
    ld d, a

    call _quantize_channel4_note
    ld b, a

    ld a, [rAUD4POLY]
    or b
    ld [rAUD4POLY], a

    ;; Get the highmask and apply it.
    ld hl, highmask4
    or [hl]
    ld [rAUD4GO], a

    ret

_quantize_channel4_note:
    ;; Shift the "note value" right by 7 to get a spread from 0 to 15.
    ;; Keep just the upmost bit of the lower byte
    ld a, e
    and %10000000
    rla
    ld c, a

    ;; Keep the entire upper byte (but it's never the full 8 bits)
    ld a, d
    rla
    or c
    swap a
    ret

_doeffect:
    ;; Call with:
    ;; B: instrument nibble + effect type nibble
    ;; C: effect parameters
    ;; E: channel

    ;; free: A, D, H, L

    ;; Strip the instrument bits off leaving only effect code
    ld a, b
    and %00001111
    ld b, a

    ;; Multiply by 3 to get offset into table
    ld a, b
    add a, b
    add a, b

    ld hl, .jump
    add_a_to_hl

    ld b, e
    ld a, [tick]
    cp 0
    ; or a ; We can return right off the bat if it's tick zero
    jp hl

.jump:
    ;; Jump table for effect
    jp fx_arpeggio                     ;0xy
    jp fx_porta_up                     ;1xy
    jp fx_porta_down                   ;2xy
    jp fx_toneporta                    ;3xy
    jp fx_vibrato                      ;4xy
    jp fx_set_master_volume            ;5xy
    jp fx_call_routine                 ;6xy
    jp fx_note_delay                   ;7xy
    jp fx_set_pan                      ;8xy
    jp fx_set_duty                     ;9xy
    jp fx_vol_slide                    ;Axy
    jp fx_pos_jump                     ;Bxy
    jp fx_set_volume                   ;Cxy
    jp fx_pattern_break                ;Dxy
    jp fx_note_cut                     ;Exy
    jp fx_set_speed                    ;Fxy

setup_channel_pointer:
    ;; Call with:
    ;; Channel value in B
    ;; Offset in D
    ;; Returns value in HL

    ld a, b
    REPT CHANNEL_SIZE_EXPONENT
        sla a
    ENDR
    add d
    ld hl, channels
    add_a_to_hl
    ret

fx_set_master_volume:
    ret nz
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; Upper 4 bits contain volume for left, lower 4 bits for right
    ;; Format is ?LLL ?RRR where ? is just a random bit, since we don't use
    ;; the Vin

    ;; This can be used as a more fine grained control over channel 3's output,
    ;; if you pan it completely.

    ld a, c
    ld [rAUDVOL], a
    ret

fx_call_routine:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; Routines are 16 bytes. Shift left to multiply by 16, then
    ;; jump to that location.

    ld hl, routines
    ld a, c
    swap a
    ; and %11110000 is this necessary?
    ; sla c
    ; sla c
    ; sla c
    ; sla c
    ; ld a, c
    add_a_to_hl
    jp hl

fx_set_pan:
    ret nz

    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; Pretty simple. The editor can create the correct value here without a bunch
    ;; of bit shifting manually.

    ld a, c
    ld [rAUDTERM], a
    ret

fx_set_duty:
    ret nz

    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; $900 = 12.5%
    ;; $940 = 25%
    ;; $980 = 50%
    ;; $9C0 = 75%

    ld a, b
    or a ; cp 0
    jp z, .chan1
.chan2:
    ld a, c
    ld [rAUD2LEN], a
    ret
.chan1:
    ld a, c
    ld [rAUD1LEN], a
    ret

fx_vol_slide:
    ret nz

    ;; This is really more of a "retrigger note with lower volume" effect and thus
    ;; isn't really that useful. Instrument envelopes should be used instead.
    ;; Might replace this effect with something different if a new effect is
    ;; ever needed.

    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld d, 0
    call setup_channel_pointer
    ld a, [hl+]
    ld e, [hl]
    ld d, a

    ld a, b
    add a
    ld hl, .envelope_registers
    add_a_to_hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ;; setup the up and down params
    ld a, c
    and %00001111
    ld d, a

    ld a, c
    and %11110000
    ld e, a

    ld a, [hl]
    and %11110000
    swap a
    sub d
    jp nc, .cont1
    ld a, 0
.cont1:
    add e
    jp nc, .cont2
    ld a, $F
.cont2:
    swap a
    ld [hl+], a

    ld [hl], d
    inc hl
    ld a, e
    or %10000000
    ld [hl], a

    ret

.envelope_registers:
    dw rAUD1ENV
    dw rAUD2ENV
    dw rAUD4ENV
    dw rAUD4ENV

fx_note_delay:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    jp nz, .play_note

    ;; Just store the note into the channel period, and don't play a note.
    ld d, 0
    call setup_channel_pointer

    ld a, [temp_note_value]
    ld [hl+], a
    ld a, [temp_note_value+1]
    ld [hl], a

    ;; Don't call _playnote. This is done by grabbing the return
    ;; address and manually skipping the next call instruction.
    ret_dont_call_playnote

.play_note:
    ld a, [tick]
    cp c
    ret nz ; wait until the correct tick to play the note

    ld d, 0
    call setup_channel_pointer

    ;; TODO: Change this to accept HL instead?
    ld a, [hl+]
    ld [temp_note_value], a
    ld a, [hl]
    ld [temp_note_value+1], a

    ;; Generalize this somehow?

    ld hl, .play_note_routines
    ld a, b
    add b
    add b
    add_a_to_hl
    jp hl

.play_note_routines:
    jp _playnote1
    jp _playnote2
    jp _playnote3
    jp _playnote4

fx_set_speed:
    ret nz

    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L
    ld a, c
    ld [ticks_per_row], a
    ret

fx_pos_jump:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld a, 1
    ld [row_break], a
    ld a, c
    ld [next_order], a

    ret

fx_pattern_break:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld a, c
    ld [row_break], a

    ret

;; TODO: Fix this
fx_note_cut:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L
    ;; ld a, [tick]
    cp c
    ret nz

    ld d, 0
    jp set_channel_volume

fx_set_volume:
    ret nz ;; Return if we're not on tick zero.

    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; Arguments to this effect will be massaged to correct form for the channel
    ;; in the editor so we don't have to AND and SWAP and stuff.

set_channel_volume:
    ;; Call with:
    ;; Correct volume value in D
    ;; Channel number in B

    ld a, b
    cp 1 ; check if it's channel 2
    jr c, set_chn_1_vol
    jr z, set_chn_2_vol
set_chn_3_vol:
    ;; "Quantize" the more finely grained volume control down to one of 4 values.
    ld a, c
    swap a
    cp 0
    jr z, .zero
    cp 5
    jr nc, .one
    cp 10
    jr nc, .two
.three:
    ld a, %01100000
    jr .done
.two:
    ld a, %01000000
    jr .done
.one:
    ld a, %00100000
    jr .done
.zero:
    ld a, 0
.done:
    ld [rAUD3LEVEL], a
    ret
set_chn_2_vol:
    ; ld a, d
    ; and %00001111
    ; or c
    ld a, c
    ld [rAUD2ENV], a

    ret
set_chn_1_vol:
    ; ld a, d
    ; and %00001111
    ; or c
    ld a, c
    ld [rAUD1ENV], a

    ret

fx_vibrato:
    ret z
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; Extremely poor man's vibrato.
    ;; Speed values:
    ;; (0x0  = 1.0)
    ;; (0x1  = 0.5)
    ;; (0x3  = 0.25)
    ;; (0x7  = 0.125)
    ;; (0xf  = 0.0625)
    ld d, 4
    call setup_channel_pointer

    ld a, c
    and %11110000
    swap a
    ld d, a

    ld a, [tick] ; Probably should change to some constantly ticking thing
    and d
    ld a, [hl-]
    jr z, .go_up
.restore:
    dec hl
    dec hl
    ld a, [hl-]
    ld l, [hl]
    ld h, a
    jr .finish_vibrato
.go_up:
    call _convert_note ; TODO: Find a way to grab it directly rather than recompute
    ld a, c
    and %00001111
    add_a_to_hl
.finish_vibrato:
    ld d, h
    ld e, l
    jp _update_channel

fx_arpeggio:
    ret z
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld d, 4
    call setup_channel_pointer

    ld a, [tick]
    dec a

    ;; Multiply by 2 to get offset into table
    add a

    ld d, [hl]

    ld hl, .arp_options
    add_a_to_hl
    jp hl

    ;; TODO: Make this work when TICKS != 6
.arp_options:
    jr .set_arp1
    jr .set_arp2
    jr .reset_arp
    jr .set_arp1
    jr .set_arp2
.reset_arp:
    ld a, d
    jr .finish_skip_add
.set_arp2:
    ld a, c
    swap a
    jr .finish_arp
.set_arp1:
    ld a, c
.finish_arp:
    and %00001111
    add d
.finish_skip_add:
    call _convert_note
    ld d, h
    ld e, l
    jp _update_channel

fx_porta_up:
    ret z
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld d, 0
    call setup_channel_pointer

    ld a, [hl+]
    ld e, a
    ld d, [hl]

    ld a, c
    add_a_to_de

    ld a, d
    ld [hl-], a
    ld [hl], e

    jp _update_channel

;; TODO: Maybe merge with fx_porta_up, since they're so similar? Would need
;; to find a way to compare against effect code.
fx_porta_down:
    ret z
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ld d, 0
    call setup_channel_pointer

    ld a, [hl+]
    ld e, a
    ld d, [hl]

    ld a, c
    sub_from_r16 d, e, c

    ld a, d
    ld [hl-], a
    ld [hl], e

    jp _update_channel

fx_toneporta:
    jr nz, .do_toneporta

    ;; We're on tick zero, so just move the temp note value into the toneporta target.
    ld d, 2
    call setup_channel_pointer

    ;; If the note is nonexistent, then just return
    ld a, [temp_note_value+1]
    or a
    jr z, .return_skip

    ld [hl+], a
    ld a, [temp_note_value]
    ld [hl], a

    ;; Don't call _playnote. This is done by grabbing the return
    ;; address and manually skipping the next call instruction.
.return_skip:
    ret_dont_call_playnote

.do_toneporta:
    ;; B: channel
    ;; C: effect parameters

    ;; free registers: A, D, E, H, L

    ;; TODO: Optimize. This usage of the stack isn't great but IMO it's
    ;; better than using the stack hack which forces all effects to screw with
    ;; pushing and popping. Most effects won't need to do this.
    ld d, 0
    call setup_channel_pointer
    push hl

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a

    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ;; Comparing which direction to move the current value
    ;; TODO: Optimize this!!!!

    ;; Compare high byte
    ld a, h

    cp d
    jr c, .subtract ; target is less than the current period
    jr z, .high_byte_same
    jr .add
.high_byte_same:
    ld a, l
    cp e
    jr c, .subtract ; the target is less than the current period
    jr z, .done ; both nibbles are the same so no portamento
.add:
    ld a, c
    add a, e
    ld e, a
    adc a, d
    sub e
    ld d, a

    ld a, h
    cp d
    jr c, .set_exact
    ld a, l
    cp e
    jr c, .set_exact

    jr .done

.subtract:
    ld a, e
    sub c
    ld e, a

    ld a, d
    sbc a, 0
    ld d, a

    ld a, h
    cp d
    jr nc, .set_exact
    ld a, l
    cp e
    jr nc, .set_exact

    jr .done

.set_exact:
    ld d, h
    ld e, l
.done:
    pop hl
    ld a, e
    ld [hl+], a
    ld [hl], d

    jp _update_channel

loadShort: MACRO
    ld a, [\1]
    ld \3, a
    ld a, [\1 + 1]
    ld \2, a
ENDM

_setup_instrument_pointer:
    ld a, b
    and %11110000
    swap a
    ret z ; If there's no instrument, then return early.

    dec a ; Instrument 0 is "no instrument"

    ;; Shift left twice to multiply by 4
    sla a
    sla a

    ld de, instruments
    add_a_to_de
    rla ; reset the Z flag
    ret

_dosound::
    ld a, [tick]
    or a
    jp nz, .process_effects

    ;; Note playback

    loadShort pattern1, b, c
    ld de, channel_note1
    call _lookup_note
    push af
    jr nc, .do_setvol1

    call _setup_instrument_pointer
    ld a, [highmask1]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask1

    ld a, [de]
    inc de
    ld [rAUD1SWEEP], a
    ld a, [de]
    inc de
    ld [rAUD1LEN], a
    ld a, [de]
    ld [rAUD1ENV], a
    inc de
    ld a, [de]

.write_mask1:
    ld [highmask1], a

.do_setvol1:
    ld a, h
    ld [temp_note_value], a
    ld a, l
    ld [temp_note_value+1], a

    ld e, 0
    call _doeffect

    pop af

    jr nc, .after_note1

    call _playnote1 ; 3 bytes

.after_note1:
    loadShort pattern2, b, c
    ld de, channel_note2
    call _lookup_note
    push af
    jr nc, .do_setvol2

    call _setup_instrument_pointer
    ld a, [highmask2]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask2

    inc de
    ld a, [de]
    inc de
    ld [rAUD2LEN], a
    ld a, [de]
    ld [rAUD2ENV], a
    inc de
    ld a, [de]

.write_mask2:
    ld [highmask2], a

.do_setvol2:
    ld a, h
    ld [temp_note_value], a
    ld a, l
    ld [temp_note_value+1], a

    ld e, 1
    call _doeffect

    pop af

    jr nc, .after_note2

    call _playnote2 ; 3 bytes

.after_note2:
    loadShort pattern3, b, c
    ld de, channel_note3
    call _lookup_note
    push af

    jr nc, .do_setvol3

    call _setup_instrument_pointer
    ld a, [highmask3]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask3

    ld a, [de]
    inc de
    ld [rAUD3LEN], a
    ld a, [de]
    inc de
    ld [rAUD3LEVEL], a
    ;; TODO: Write to _AUD3WAVERAM
    ; ld a, [de]
    ; ld [rAUD3ENV], a
    inc de
    ld a, [de]

.write_mask3:
    ld [highmask3], a

.do_setvol3:
    ld a, h
    ld [temp_note_value], a
    ld a, l
    ld [temp_note_value+1], a


    ld e, 2
    call _doeffect

    pop af

    jr nc, .after_note3

    call _playnote3 ; 3 bytes

.after_note3:
    loadShort pattern4, b, c
    ld de, channel_note4
    call _lookup_note
    push af

    jr nc, .do_setvol4

    call _setup_instrument_pointer
    ld a, [highmask4]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask4

    ld a, [de]
    inc de
    ld [rAUD4LEN], a
    ld a, [de]
    inc de
    ld [rAUD4ENV], a
    ld a, [de]
    ld [rAUD4POLY], a
    inc de
    ld a, [de]

.write_mask4:
    ld [highmask4], a

.do_setvol4:
    ld a, h
    ld [temp_note_value], a
    ld a, l
    ld [temp_note_value+1], a

    ld e, 3
    call _doeffect

    pop af

    jr nc, .after_note4

    call _playnote4 ; 3 bytes

.after_note4:
    ;; finally just update the tick/order/row values
    jp process_tick

.process_effects:
    ;; Only do effects if not on tick zero

    loadShort pattern1, b, c
    ld de, channel_note1
    call _load_note_data

    ld a, c
    cp 0
    jr z, .after_effect1

    ld e, 0
    call _doeffect

.after_effect1:
    loadShort pattern2, b, c
    ld de, channel_note2
    call _load_note_data

    ld a, c
    cp 0
    jr z, .after_effect2

    ld e, 1
    call _doeffect

.after_effect2:
    loadShort pattern3, b, c
    ld de, channel_note3
    call _load_note_data

    ld a, c
    cp 0
    jr z, .after_effect3

    ld e, 2
    call _doeffect

.after_effect3:
    loadShort pattern4, b, c
    ld de, channel_note4
    call _load_note_data

    ld a, c
    cp 0
    jr z, .after_effect4

    ld e, 3
    call _doeffect

.after_effect4:

process_tick:
    ld a, [ticks_per_row]
    ld b, a

    ld a, [tick]
    inc a

    cp b
    jp z, _newrow

    ld [tick], a
    ret

_newrow:
    ;; Reset tick to 0
    xor a ; ld a, 0
    ld [tick], a

    ;; Check if we need to perform a row break or pattern break
    ld a, [row_break]
    cp 0
    jr z, .no_break

    ;; These are offset by one so we can check to see if they've
    ;; been modified
    dec a
    ld b, a

    ld a, [next_order]
    cp 0

    ;; Maybe use HL instead?
    push af
    ld a, 0
    ld [next_order], a
    ld [row_break], a
    pop af

    jr z, _neworder

    dec a
    sla a ;; Multiply the order by 2 (they are words)

    jr _update_current_order

.no_break:
    ;; Increment row.
    ld a, [row]
    inc a
    ld b, a
    cp PATTERN_LENGTH
    jr nz, _noreset

    ld b, 0
_neworder:
    ;; Increment order and change loaded patterns
    ld a, [order_cnt]
    ld c, a
    ld a, [current_order]
    add a, 2
    cp c
    jr nz, _update_current_order
    ld a, 0
_update_current_order:
    ;; Call with:
    ;; A: The order to load
    ;; B: The row for the order to start on
    ld [current_order], a
    ld c, a
    call _refresh_patterns

_noreset:
    ld a, b
    ld [row], a
    ret


SECTION "Note Table", ROM0
note_table:
include "note_table.inc"
