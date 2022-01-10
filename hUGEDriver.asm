include "include/hardware.inc"
include "include/hUGE.inc"

add_a_to_r16: MACRO
    add \2
    ld \2, a
    adc \1
    sub \2
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
    and a ; Clear carry to avoid calling `play_chX_note`
    push af
    jp hl
ENDM

add_a_ind_ret_hl: MACRO
    ld hl, \1
    add [hl]
    inc hl
    ld h, [hl]
    ld l, a
    adc h
    sub l
    ld h, a
ENDM

load_hl_ind: MACRO
    ld hl, \1
    ld a, [hl+]
    ld h, [hl]
    ld l, a
ENDM

load_de_ind: MACRO
    ld a, [\1]
    ld e, a
    ld a, [\1+1]
    ld d, a
ENDM

retMute: MACRO
    bit \1, a
    ret nz
ENDM

checkMute: MACRO
    ld a, [mute_channels]
    bit \1, a
    jr nz, \2
ENDM

;; Maximum pattern length
PATTERN_LENGTH EQU 64
;; Amount to be shifted in order to skip a channel.
CHANNEL_SIZE_EXPONENT EQU 3

SECTION "Playback variables", WRAM0
;; Active song descriptor
order_cnt: db
_start_song_descriptor_pointers:
;; Pointers to the song's current four orders (one per channel)
order1: dw
order2: dw
order3: dw
order4: dw

;; Pointers to the instrument tables
duty_instruments: dw
wave_instruments: dw
noise_instruments: dw

;; Misc. pointers
routines: dw
waves: dw
_end_song_descriptor_pointers:

;; Pointers to the current patterns (sort of a cache)
pattern1: dw
pattern2: dw
pattern3: dw
pattern4: dw

;; How long a row lasts in ticks (1 = one row per call to `hUGE_dosound`, etc. 0 translates to 256)
ticks_per_row: db

_hUGE_current_wave::
hUGE_current_wave::
;; ID of the wave currently loaded into wave RAM
current_wave: db
hUGE_NO_WAVE equ 100
    EXPORT hUGE_NO_WAVE

;; Everything between this and `end_zero` is zero-initialized by `hUGE_init`
start_zero:

mute_channels: db
current_order: db
next_order: db
row_break: db

temp_note_value: dw
row: db
tick: db
counter: db

channels:
;;;;;;;;;;;
;;Channel 1
;;;;;;;;;;;
channel1:
channel_period1: dw
toneporta_target1: dw
channel_note1: db
vibrato_tremolo_phase1: db
envelope1: db
highmask1: db

;;;;;;;;;;;
;;Channel 2
;;;;;;;;;;;
channel2:
channel_period2: dw
toneporta_target2: dw
channel_note2: db
vibrato_tremolo_phase2: db
envelope2: db
highmask2: db

;;;;;;;;;;;
;;Channel 3
;;;;;;;;;;;
channel3:
channel_period3: dw
toneporta_target3: dw
channel_note3: db
vibrato_tremolo_phase3: db
envelope3: db
highmask3: db

;;;;;;;;;;;
;;Channel 4
;;;;;;;;;;;
channel4:
channel_period4: dw
toneporta_target4: dw
channel_note4: db
vibrato_tremolo_phase4: db
envelope4: db
highmask4: db

end_zero:

SECTION "Sound Driver", ROM0

;;; Sets up hUGEDriver to play a song.
;;; !!! BE SURE THAT `hUGE_dosound` WILL NOT BE CALLED WHILE THIS RUNS !!!
;;; Param: HL = Pointer to the "song descriptor" you wish to load (typically exported by hUGETracker).
;;; Destroys: AF C DE HL
hUGE_init::
    ld a, [hl+] ; tempo
    ld [ticks_per_row], a

    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    ld a, [de]
    ld [order_cnt], a

    ld c, _end_song_descriptor_pointers - (_start_song_descriptor_pointers)
    ld de, order1

.copy_song_descriptor_loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .copy_song_descriptor_loop

IF !DEF(PREVIEW_MODE)
    ;; Zero some ram
    ld c, end_zero - start_zero
    ld hl, start_zero
    xor a
.fill_loop:
    ld [hl+], a
    dec c
    jr nz, .fill_loop
ENDC

    ;; These two are zero-initialized by the loop above, so these two writes must come after
    ld a, %11110000
    ld [envelope1], a
    ld [envelope2], a

    ;; Force loading the next wave
    ld a, hUGE_NO_WAVE
    ld [current_wave], a

;; Preview mode needs to load the order ID from memory
IF !DEF(PREVIEW_MODE)
    ld c, 0
ELSE
    ld a, [current_order]
    ld c, a
ENDC
    ;; fallthrough (load the pattern pointers)

;;; Sets all 4 pattern pointers from a certain index in the respective 4 orders.
;;; Param: C = The index (in increments of 2)
;;; Destroy: AF DE HL
load_patterns:
IF DEF(PREVIEW_MODE)
    db $fc ; signal order update to tracker
ENDC

    ld hl, order1
    ld de, pattern1
    call .load_pattern

    ld hl, order2
    call .load_pattern

    ld hl, order3
    call .load_pattern

    ld hl, order4
    ;; fallthrough

.load_pattern:
    ld a, [hl+]
    add c
    ld h, [hl]
    ld l, a
    adc h
    sub l
    ld h, a

    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    inc de
    ret


;;; Sets a channel's muting status.
;;; Muted channels are left entirely alone by the driver, so that you can repurpose them,
;;; for example for sound effects, CH3 sample playback, etc.
;;; If muting the channel, the note being played will be cut.
;;; Param: B = Which channel to enable; 0 for CH1, 1 for CH2, etc.
;;; Param: C = 0 to unmute the channel, 1 to mute it
;;; Destroy: A C E HL
hUGE_mute_channel::
    ld e, $fe
    ld a, b
    or a
    jr z, .enable_cut
.enable_loop:
    sla c
    rlc e
    dec a
    jr nz, .enable_loop
.enable_cut:
    ld a, [mute_channels]
    and e
    or  c
    ld [mute_channels], a
    and c
    jp nz, note_cut
    ret


;;; Reads a pattern's current row.
;;; Param: BC = Pointer to the pattern
;;; Param: [row] = Index of the current ro<
;;; Return: A = Note ID
;;; Return: B = Instrument (upper nibble) & effect code (lower nibble)
;;; Return: C = Effect parameter
;;; Destroy: HL
get_current_row:
    ld a, [row]
    ld h, a
    ;; Multiply by 3 for the note value
    add h
    add h

    ld h, 0
    ld l, a
    add hl, bc ; HL now points at the 3rd byte of the note
    ld a, [hl+]
    ld b, [hl]
    inc hl
    ld c, [hl]
    ret

;;; Gets the "period" of a pattern's current note.
;;; Param: HL = Pointer to the pattern pointer
;;; Param: [row] = Index of the current row
;;; Param: DE = Location to write the note's index to, if applicable
;;; Return: HL = Note's period
;;; Return: CF = Set if and only if a "valid" note (i.e. not a "rest")
;;; Return: [DE] = Note's ID, not updated if a "rest"
;;; Return: B = Instrument (upper nibble) & effect code (lower nibble)
;;; Return: C = Effect parameter
;;; Destroy: AF
get_current_note:
    ld a, [hl+]
    ld c, a
    ld b, [hl]

    call get_current_row
    ld hl, 0

    ;; If the note we found is greater than LAST_NOTE, then it's not a valid note
    ;; and nothing needs to be updated.
    cp LAST_NOTE
    ret nc

    ;; Store the loaded note value in channel_noteX
    ld [de], a

;;; Gets a note's "period", i.e. what should be written to NRx3 and NRx4.
;;; Param: A = Note ID
;;; Return: HL = Note's period
;;; Return: CF = 1
;;; Destroy: AF
get_note_period:
    add a ;; double it to get index into hi/lo table
    add LOW(note_table)
    ld l, a
    adc HIGH(note_table)
    sub l
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    scf
    ret

;;; Gets a note's "polynomial counter", i.e. what should be written to NR44.
;;; Param: A = Note ID
;;; Return: A = Note's poly
;;; Destroy: F HL
get_note_poly:
    ;; Invert the order of the numbers
    add 192 ; (255 - 63)
    cpl

    ;; Thanks to RichardULZ for this formula
    ;; https://docs.google.com/spreadsheets/d/1O9OTAHgLk1SUt972w88uVHp44w7HKEbS/edit#gid=75028951
    ; if A > 7 then begin
    ;   B := (A-4) div 4;
    ;   C := (A mod 4)+4;
    ;   A := (C or (B shl 4))
    ; end;

    ; if A < 7 then return
    cp 7
    ret c

    ld h, a

    ; B := (A-4) div 4;
    sub 4
    srl a
    srl a
    ld l, a

    ; C := (A mod 4)+4;
    ld a, h
    and 3 ; mod 4
    add 4

    ; A := (C or (B shl 4))
    swap l
    or l
    ret


;;; Computes the pointer to a member of a channel.
;;; Param: B = Which channel (0 = CH1, 1 = CH2, etc.)
;;; Param: D = Offset within the channel struct
;;; Return: HL = Pointer to the channel's member
;;; Destroy: AF
ptr_to_channel_member:
    ld a, b
REPT CHANNEL_SIZE_EXPONENT
    add a
ENDR
    add d
    add LOW(channels)
    ld l, a
    adc HIGH(channels)
    sub l
    ld h, a
    ret


;;; Updates a channel's frequency, and possibly restarts it.
;;; Note that CH4 is *never* restarted by this!
;;; Param: B = Which channel to update (0 = CH1, 1 = CH2, etc.)
;;; Param: (ignored for CH4) A = ORed to the value written to NRx4
;;; Param: (for CH4) E = Note ID
;;; Param: (otherwise) DE = Note period
;;; Destroy: AF B
;;; Destroy: (for CH4) HL
update_channel_freq:
    ld c, a
    ld a, [mute_channels]
    dec b
    jr z, .update_channel2
    dec b
    jr z, .update_channel3
    dec b
    jr z, .update_channel4

.update_channel1:
    retMute 0

    ld a, e
    ldh [rAUD1LOW], a
    ld a, d
    or c
    ldh [rAUD1HIGH], a
    ret

.update_channel2:
    retMute 1

    ld a, e
    ldh [rAUD2LOW], a
    ld a, d
    or c
    ldh [rAUD2HIGH], a
    ret

.update_channel3:
    retMute 2

    ld a, e
    ldh [rAUD3LOW], a
    ld a, d
    or c
    ldh [rAUD3HIGH], a
    ret

.update_channel4:
    retMute 3

    ld a, e
    call get_note_poly
    ldh [rAUD4POLY], a
    xor a
    ldh [rAUD4GO], a
    ret


play_note_routines:
    jr play_ch1_note
    jr play_ch2_note
    jr play_ch3_note
    jr play_ch4_note

play_ch1_note:
    ld a, [mute_channels]
    retMute 0

    ;; Play a note on channel 1 (square wave)
    ld a, [temp_note_value]
    ld [channel_period1], a
    ldh [rAUD1LOW], a

    ld a, [temp_note_value+1]
    ld [channel_period1+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask1
    or [hl]
    ldh [rAUD1HIGH], a

    ret

play_ch2_note:
    ld a, [mute_channels]
    retMute 1

    ;; Play a note on channel 2 (square wave)
    ld a, [temp_note_value]
    ld [channel_period2], a
    ldh [rAUD2LOW], a

    ld a, [temp_note_value+1]
    ld [channel_period2+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask2
    or [hl]
    ldh [rAUD2HIGH], a

    ret

play_ch3_note:
    ld a, [mute_channels]
    retMute 2

    ;; Triggering CH3 while it's reading a byte corrupts wave RAM.
    ;; To avoid this, we kill the wave channel (0 → NR30), then re-enable it.
    ;; This way, CH3 will be paused when we trigger it by writing to NR34.
    ;; TODO: what if `highmask3` bit 7 is not set, though?
    xor a
    ldh [rAUD3ENA], a
    cpl
    ldh [rAUD3ENA], a

    ;; Play a note on channel 3 (waveform)
    ld a, [temp_note_value]
    ld [channel_period3], a
    ldh [rAUD3LOW], a

    ld a, [temp_note_value+1]
    ld [channel_period3+1], a

    ;; Get the highmask and apply it.
    ld hl, highmask3
    or [hl]
    ldh [rAUD3HIGH], a

    ret

play_ch4_note:
    ld a, [mute_channels]
    retMute 3

    ;; Play a "note" on channel 4 (noise)
    ld a, [temp_note_value]
    ld [channel_period4+1], a
    ldh [rAUD4POLY], a

    ;; Get the highmask and apply it.
    ld a, [highmask4]
    ldh [rAUD4GO], a

    ret


;;; Performs an effect on a given channel.
;;; Param: E = Channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: B = Effect type (upper 4 bits ignored)
;;; Param: C = Effect parameters (depend on FX type)
;;; Destroy: AF BC DE HL
do_effect:
    ;; Strip the instrument bits off leaving only effect code
    ld a, b
    and %00001111
    ;; Multiply by 2 to get offset into table
    add a

    add LOW(.jump)
    ld l, a
    adc HIGH(.jump)
    sub l
    ld h, a

    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld b, e
    ld a, [tick]
    or a ; We can return right off the bat if it's tick zero
    jp hl

.jump:
    ;; Jump table for effect
    dw fx_arpeggio                     ;0xy
    dw fx_porta_up                     ;1xy
    dw fx_porta_down                   ;2xy
    dw fx_toneporta                    ;3xy
    dw fx_vibrato                      ;4xy
    dw fx_set_master_volume            ;5xy ; global
    dw fx_call_routine                 ;6xy
    dw fx_note_delay                   ;7xy
    dw fx_set_pan                      ;8xy ; global
    dw fx_set_duty                     ;9xy
    dw fx_vol_slide                    ;Axy
    dw fx_pos_jump                     ;Bxy ; global
    dw fx_set_volume                   ;Cxy
    dw fx_pattern_break                ;Dxy ; global
    dw fx_note_cut                     ;Exy
    dw fx_set_speed                    ;Fxy ; global


;;; Processes (global) effect 5, "set master volume".
;;; Param: C = Value to write to NR50
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A
fx_set_master_volume:
    ret nz

    ld a, c
    ldh [rAUDVOL], a
    ret


;;; Processes effect 6, "call routine".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Routine ID
;;; Param: A = Current tick
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: Anything the routine does
fx_call_routine:
    sla c
    ld a, [routines]
    add c
    ld l, a
    ld a, [routines+1]
    adc 0
    ld h, a

    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld a, [tick]
    or a ; set zero flag if tick 0 for compatibility
IF DEF(GBDK) ; Pass the tick counter as a SDCC call parameter
    push af
    inc sp
    push bc
    call .call_hl
    add sp, 3
    ret

.call_hl:
ENDC
    jp hl


;;; Processes (global) effect 8, "set pan".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Value to write to NR51
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A
fx_set_pan:
    ret nz

    ;; Pretty simple. The editor can create the correct value here without a bunch
    ;; of bit shifting manually.
    ld a, c
    ldh [rAUDTERM], a
    ret


;;; Processes effect 9, "set duty cycle".
;;; Param: B = Current channel ID (0 = CH1, anything else = CH2)
;;; Param: C = Value to write to NRx1
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF
fx_set_duty:
    ret nz

    ;; $900 = 12.5%
    ;; $940 = 25%
    ;; $980 = 50%
    ;; $9C0 = 75%

    ld a, b
    or a
    ld a, [mute_channels]
    jr z, .chan1
.chan2:
    retMute 1
    ld a, c
    ldh [rAUD2LEN], a
    ret
.chan1:
    retMute 0
    ld a, c
    ldh [rAUD1LEN], a
    ret


;;; Processes effect A, "volume slide".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = FX param; either nibble should be 0, otherwise weird (unspecified) behavior may arise
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF C DE HL
fx_vol_slide:
    ret nz

    ;; This is really more of a "retrigger note with lower volume" effect and thus
    ;; isn't really that useful. Instrument envelopes should be used instead.
    ;; Might replace this effect with something different if a new effect is
    ;; ever needed.

    ;; check channel mute

    ;; 0 → $01, 1 → $02, 2 → $04, 3 → $05
    ;; Overall, these two instructions add 1 to the number.
    ;; However, the first instruction will generate a carry for inputs of $02 and $03;
    ;; the `adc` will pick the carry up, and "separate" 0 / 1 from 2 / 3 by an extra 1.
    ;; Luckily, this yields correct results for 0 ($01), 1 ($02), and 2 ($03 + 1 = $04).
    ;; We'll see about fixing 3 afterwards.
    add -2
    adc 3
    ;; After being shifted left, the inputs are $02, $04, $08 and $0A; all are valid BCD,
    ;; except for $0A. Since we just performed `add a`, DAA will correct the latter to $10.
    ;; (This should be correctly emulated everywhere, since the inputs are identical to
    ;; "regular" BCD.)
    ;; When shifting the results back, we'll thus get $01, $02, $04 and $08!
    add a
    daa
    rra
    ld d, a
    ld a, [mute_channels]
    and d
    ret nz

    ;; setup the up and down params
    ld a, c
    and %00001111
    ld d, a

    ld a, c
    and %11110000
    ld e, a
    swap e

    ; There are 5 bytes between each envelope register
    ld a, b
    add a
    add a
    add b
    add LOW(rAUD1ENV)
    ld c, a

    ldh a, [c]
    and %11110000
    swap a
    sub d
    jr nc, .cont1
    xor a
.cont1:
    add e
    cp $10
    jr c, .cont2
    ld a, $F
.cont2:
    swap a
    ldh [c], a

    ; Go to rAUDxGO, which is 2 bytes after
    inc c
    inc c
    ldh a, [c]
    or %10000000
    ldh [c], a

    jr play_note


;;; Processes effect 7, "note delay".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Amount of ticks by which to delay the note
;;;            Caveats: 0 never plays the note, and a delay longer than a row's duration skips the note entirely
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF D HL
fx_note_delay:
    jr nz, .play_note

    ;; Just store the note into the channel period, and don't play a note.
    ld d, 0
    call ptr_to_channel_member

    ld a, [temp_note_value]
    ld [hl+], a
    ld a, [temp_note_value+1]
    ld [hl], a

    ;; Don't call _playnote. This is done by grabbing the return
    ;; address and manually skipping the next call instruction.
    ret_dont_call_playnote

.play_note:
    cp c
    ret nz ; wait until the correct tick to play the note

    ;; fallthrough


;;; Plays a channel's current note.
;;; Param: B = Which channel (0 = CH1, 1 = CH2, etc.)
;;; Destroy: AF D HL
play_note:
    ld d, 0
    call ptr_to_channel_member

    ;; TODO: Change this to accept HL instead?
    ld a, [hl+]
    ld [temp_note_value], a
    ld a, [hl]
    ld [temp_note_value+1], a

    ld a, b
    add a
    add LOW(play_note_routines)
    ld l, a
    adc HIGH(play_note_routines)
    sub l
    ld h, a
    jp hl


;;; Processes (global) effect F, "set speed".
;;; Param: C = New amount of ticks per row
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A
fx_set_speed:
    ret nz

    ld a, c
    ld [ticks_per_row], a
    ret


hUGE_set_position::
;;; Processes (global) effect B, "position jump".
;;; Param: C = ID of the order to jump to
;;; Destroy: A
fx_pos_jump:
    ld a, 1
    ld [row_break], a
    ld a, c
    ld [next_order], a
    ret


;;; Processes (global) effect D, "pattern break".
;;; Param: C = ID of the next order's row to start on
;;; Destroy: A
fx_pattern_break:
    ld a, c
    ld [row_break], a
    ret


;;; Processes effect E, "note cut".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Tick to cut the note on (TODO: what does cutting on tick 0 do?)
;;; Param: A = Current tick
;;; Destroy: A
fx_note_cut:
    cp c
    ret nz

    ;; check channel mute

    ;; 0 → $01, 1 → $02, 2 → $04, 3 → $05
    ;; Overall, these two instructions add 1 to the number.
    ;; However, the first instruction will generate a carry for inputs of $02 and $03;
    ;; the `adc` will pick the carry up, and "separate" 0 / 1 from 2 / 3 by an extra 1.
    ;; Luckily, this yields correct results for 0 ($01), 1 ($02), and 2 ($03 + 1 = $04).
    ;; We'll see about fixing 3 afterwards.
    add -2
    adc 3
    ;; After being shifted left, the inputs are $02, $04, $08 and $0A; all are valid BCD,
    ;; except for $0A. Since we just performed `add a`, DAA will correct the latter to $10.
    ;; (This should be correctly emulated everywhere, since the inputs are identical to
    ;; "regular" BCD.)
    ;; When shifting the results back, we'll thus get $01, $02, $04 and $08!
    add a
    daa
    rra
    ld d, a
    ld a, [mute_channels]
    and d
    ret nz

    ;; fallthrough


;;; Cuts note on a channel.
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Destroy: AF HL
note_cut:
    ld a, b
    add a
    add a
    add b ; multiply by 5
    add LOW(rAUD1ENV)
    ld l, a
    ld h, HIGH(rAUD1ENV)
    xor a
    ld [hl+], a
    ld a, b
    cp 2
    ret z ; return early if CH3-- no need to retrigger note

    ;; Retrigger note
    inc l ; Not `inc hl` because H stays constant (= $FF)
    ld [hl], $FF
    ret


;;; Processes effect C, "set volume".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Volume to set the channel to
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF BC
fx_set_volume:
    ret nz ; Return if we're not on tick zero.

    swap c
    ld a, [mute_channels]
    dec b
    jr z, .set_chn_2_vol
    dec b
    jr z, .set_chn_3_vol
    dec b
    jr z, .set_chn_4_vol

.set_chn_1_vol:
    retMute 0

    ldh a, [rAUD1ENV]
    and %00001111
    or c
    ldh [rAUD1ENV], a
    ret

.set_chn_2_vol:
    retMute 1

    ldh a, [rAUD2ENV]
    and %00001111
    or c
    ldh [rAUD2ENV], a
    ret

.set_chn_3_vol:
    retMute 2

    ;; "Quantize" the more finely grained volume control down to one of 4 values.
    ld a, c
    cp 10 << 4
    jr nc, .one
    cp 5 << 4
    jr nc, .two
    or a
    jr z, .done ; Zero maps to zero
.three:
    ld a, %01100000
    jr .done
.two:
    ld a, %01000000
    jr .done
.one:
    ld a, %00100000
.done:
    ldh [rAUD3LEVEL], a
    ret

.set_chn_4_vol:
    retMute 3

    ld a, c
    ldh [rAUD4ENV], a
    ret


;;; Processes effect 4, "vibrato".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = FX param
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF B DE HL
fx_vibrato:
    ret z

    ;; Extremely poor man's vibrato.
    ;; Speed values:
    ;; (0x0  = 1.0)
    ;; (0x1  = 0.5)
    ;; (0x3  = 0.25)
    ;; (0x7  = 0.125)
    ;; (0xf  = 0.0625)
    ld d, 4
    call ptr_to_channel_member

    ld a, c
    and %11110000
    swap a
    ld e, a

    ld a, [counter]
    and e
    ld a, [hl]
    jr z, .go_up
.restore:
    call get_note_period
    jr .finish_vibrato
.go_up:
    call get_note_period
    ld a, c
    and %00001111
    add_a_to_hl
.finish_vibrato:
    ld d, h
    ld e, l
    xor a
    jp update_channel_freq


;;; Processes effect 8, "arpeggio".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Offsets in semitones (each nibble)
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: AF B DE HL
fx_arpeggio:
    ret z

    ld d, 4
    call ptr_to_channel_member
    ld d, [hl]

    ld a, [tick]
    dec a

    ;; TODO: A crappy modulo, because it's not a multiple of four :(

    jr .test_greater_than_two
.greater_than_two:
    sub 3
.test_greater_than_two:
    cp 3
    jr nc, .greater_than_two

    ;; Multiply by 2 to get offset into table
    add a

    add LOW(.arp_options)
    ld l, a
    adc HIGH(.arp_options)
    sub l
    ld h, a
    jp hl

.arp_options:
    jr .set_arp1
    jr .set_arp2
    ;; No `jr .reset_arp`

.reset_arp:
    ld a, d
    jr .finish_skip_add

.set_arp2:
    ld a, c
    swap a
    db $FE ; cp <imm8> gobbles next byte

.set_arp1:
    ld a, c
.finish_arp:
    and %00001111
    add d
.finish_skip_add:
    call get_note_period
    ld d, h
    ld e, l
    xor a
    jp update_channel_freq


;;; Processes effect 1, "portamento up".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = How many units to slide the pitch by per tick
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A B DE HL
fx_porta_up:
    ret z

    ld d, 0
    call ptr_to_channel_member

    ;; Add C to 16-bit value at HL
    ld a, [hl+]
    add c
    ld e, a
    adc [hl]
    sub e

    ;; Write back
.finish:
    ld d, a ; Store A for call to `update_channel_freq`
    ld [hl-], a
    ld [hl], e

    xor a
    jp update_channel_freq


;;; Processes (global) effect 2, "portamento down".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = How many units to slide the pitch down by per tick
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A B DE HL
fx_porta_down:
    ret z

    ld d, 0
    call ptr_to_channel_member

    ;; Subtract C from 16-bit value at [HL]
    ld a, [hl+]
    sub c
    ld e, a
    sbc a
    add [hl]

    ;; Write back
    jr fx_porta_up.finish


;;; Processes effect 2, "tone portamento".
;;; Param: B = Current channel ID (0 = CH1, 1 = CH2, etc.)
;;; Param: C = Target note
;;; Param: ZF = Set if and only if on tick 0
;;; Destroy: A B DE HL
fx_toneporta:
    jr nz, .do_toneporta

    ;; We're on tick zero, so just move the temp note value into the toneporta target.
    ld d, 2
    call ptr_to_channel_member

    ;; If the note is nonexistent, then just return
    ld a, [temp_note_value]
    or a
    jr z, .return_skip

    ld [hl+], a
    ld a, [temp_note_value+1]
    ld [hl], a

    ;; Don't call _playnote. This is done by grabbing the return
    ;; address and manually skipping the next call instruction.
.return_skip:
    ret_dont_call_playnote

.do_toneporta:
    ld d, 0
    call ptr_to_channel_member
    push hl

    ;; Read current period
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a

    ;; Read target period
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ;; Do we need to porta up, or down? Compute (current - target) and check carry to know
    sub e
    ld a, h
    sbc d
    jr c, .porta_down ; Current period (DE) is higher than target one (HL), so down we go!

    ;; Add offset to current freq
    ld a, e
    add c
    ld e, a
    adc d
    sub e
    ld d, a
    ;; We don't need to worry about overflow given the relatively low values we work with

    ld c, 0 ; The overshoot comparison should yield no carry, like the above one
    jr .check_overshoot

.porta_down:
    ;; Subtract offset from current freq
    ld a, e
    sub c
    ld e, a
    sbc a
    add d
    ld d, a
    jr c, .overshot ; There will be no underflows under my watch!

    ld c, $FF ; The overshoot comparison should yield carry, like the above one

.check_overshoot:
    ld a, l
    sub e
    ld a, h
    sbc d
    rra ; Shift carry into bit 7
    xor c ; XOR it with provided value
    rla ; Shift maybe-toggled carry back
    jr nc, .no_overshoot
.overshot:
    ;; Override computed new period with target
    ld d, h
    ld e, l
.no_overshoot:

    pop hl
    ld a, e
    ld [hl+], a
    ld [hl], d

    ;; Do not retrigger channel
    ld a, 6
    add_a_to_hl
    ld a, [hl]
    res 7, [hl]
    ;; B must be preserved for this
    jp update_channel_freq


;; TODO: Find some way to de-duplicate this code!
;;; Computes the pointer to a CH4 instrument.
;;; Param: B = The instrument's ID
;;; Param: DE = Instrument pointer table
;;; Return: DE = Pointer to the instrument
;;; Return: ZF = Set if and only if there was no instrument (ID == 0)
;;; Destroy: AF
setup_instrument_pointer_ch4:
    ;; Call with:
    ;; Instrument/High nibble of effect in B
    ;; Stores whether the instrument was real in the Z flag
    ;; Stores the instrument pointer in DE
    ld a, b
    and %11110000
    swap a
    ret z ; If there's no instrument, then return early.

    dec a ; Instrument 0 is "no instrument"
    add a
    jr setup_instrument_pointer.finish

;;; Computes the pointer to an instrument.
;;; Param: B = The instrument's ID
;;; Param: DE = Instrument pointer table
;;; Return: DE = Pointer to the instrument
;;; Return: ZF = Set if and only if there was no instrument (ID == 0)
;;; Destroy: AF
setup_instrument_pointer:
    ;; Call with:
    ;; Instrument/High nibble of effect in B
    ;; Stores whether the instrument was real in the Z flag
    ;; Stores the instrument pointer in DE
    ld a, b
    and %11110000
    swap a
    ret z ; If there's no instrument, then return early.

    dec a ; Instrument 0 is "no instrument"
.finish:
    ;; Shift left twice to multiply by 4
    add a
    add a

    add_a_to_de

    rla ; reset the Z flag
    ret


_hUGE_dosound_banked::
_hUGE_dosound::
;;; Ticks the sound engine once.
;;; Destroy: AF BC DE HL
hUGE_dosound::
    ld a, [tick]
    or a
    jp nz, process_effects

    ;; Note playback
    ld hl, pattern1
    ld de, channel_note1
    call get_current_note
    push af
    jr nc, .do_setvol1

    load_de_ind duty_instruments
    call setup_instrument_pointer
    ld a, [highmask1]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask1

    checkMute 0, .do_setvol1

    ld a, [de]
    inc de
    ldh [rAUD1SWEEP], a
    ld a, [de]
    inc de
    ldh [rAUD1LEN], a
    ld a, [de]
    ldh [rAUD1ENV], a
    inc de
    ld a, [de]

.write_mask1:
    ld [highmask1], a

.do_setvol1:
    ld a, l
    ld [temp_note_value], a
    ld a, h
    ld [temp_note_value+1], a

    ld e, 0
    call do_effect

    pop af
    call c, play_ch1_note

process_ch2:
    ;; Note playback
    ld hl, pattern2
    ld de, channel_note2
    call get_current_note
    push af
    jr nc, .do_setvol2

    load_de_ind duty_instruments
    call setup_instrument_pointer
    ld a, [highmask2]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask2

    checkMute 1, .do_setvol2

    inc de
    ld a, [de]
    inc de
    ldh [rAUD2LEN], a
    ld a, [de]
    ldh [rAUD2ENV], a
    inc de
    ld a, [de]

.write_mask2:
    ld [highmask2], a

.do_setvol2:
    ld a, l
    ld [temp_note_value], a
    ld a, h
    ld [temp_note_value+1], a

    ld e, 1
    call do_effect

    pop af
    call c, play_ch2_note

process_ch3:
    ld hl, pattern3
    ld de, channel_note3
    call get_current_note

    ld a, l
    ld [temp_note_value], a
    ld a, h
    ld [temp_note_value+1], a

    push af

    jr nc, .do_setvol3

    load_de_ind wave_instruments
    call setup_instrument_pointer
    ld a, [highmask3]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask3

    checkMute 2, .do_setvol3

    ld a, [de]
    inc de
    ldh [rAUD3LEN], a
    ld a, [de]
    inc de
    ldh [rAUD3LEVEL], a
    ld a, [de]
    inc de

    ;; Check to see if we need to copy a wave and then do so
    ld hl, current_wave
    cp [hl]
    jr z, .no_wave_copy
    ld [hl], a
    swap a
    add_a_ind_ret_hl waves

    xor a
    ldh [rAUD3ENA], a

FOR OFS, 16
    ld a, [hl+]
    ldh [_AUD3WAVERAM + OFS], a
ENDR

    ld a, %10000000
    ldh [rAUD3ENA], a

.no_wave_copy:
    ld a, [de]

.write_mask3:
    ld [highmask3], a

.do_setvol3:
    ld e, 2
    call do_effect

    pop af
    call c, play_ch3_note

process_ch4:
    ld hl, pattern4
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call get_current_row
    ld [channel_note4], a
    cp LAST_NOTE
    push af
    jr nc, .do_setvol4

    call get_note_poly
    ld [temp_note_value], a

    ld de, 0
    call setup_instrument_pointer

    ld a, [highmask4]
    res 7, a ; Turn off the "initial" flag
    jr z, .write_mask4

    checkMute 3, .do_setvol4

    load_hl_ind noise_instruments
    sla e
    add hl, de

    ld a, [hl+]
    ldh [rAUD4ENV], a

    ld a, [hl]
    and %00111111
    ldh [rAUD4LEN], a

    ld a, [temp_note_value]
    ld d, a
    ld a, [hl]
    and %10000000
    swap a
    or d
    ld [temp_note_value], a

    ld a, [hl]
    and %01000000
    or  %10000000
.write_mask4:
    ld [highmask4], a

.do_setvol4:
    ld e, 3
    call do_effect

    pop af
    call c, play_ch4_note

    ;; finally just update the tick/order/row values
    jp process_tick

process_effects:
    ;; Only do effects if not on tick zero
    checkMute 0, .after_effect1

    ld hl, pattern1
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call get_current_row

    ld a, c
    or a
    jr z, .after_effect1

    ld e, 0
    call do_effect      ; make sure we never return with ret_dont_call_playnote macro

.after_effect1:
    checkMute 1, .after_effect2

    ld hl, pattern2
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call get_current_row

    ld a, c
    or a
    jr z, .after_effect2

    ld e, 1
    call do_effect      ; make sure we never return with ret_dont_call_playnote macro

.after_effect2:
    checkMute 2, .after_effect3

    ld hl, pattern3
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call get_current_row

    ld a, c
    or a
    jr z, .after_effect3

    ld e, 2
    call do_effect      ; make sure we never return with ret_dont_call_playnote macro

.after_effect3:
    checkMute 3, .after_effect4

    ld hl, pattern4
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call get_current_row
    cp LAST_NOTE
    jr nc, .done_macro
    ld h, a

    load_de_ind noise_instruments
    call setup_instrument_pointer_ch4
    jr z, .done_macro ; No instrument, thus no macro

    ld a, [tick]
    cp 7
    jr nc, .done_macro

    inc de

    ld l, a
    ld a, h
    ld h, 0
    add hl, de
    add [hl]
    call get_note_poly
    ld l, a
    ld a, [de]
    ld e, a
    and %10000000
    swap a
    or l
    ldh [rAUD4POLY], a

    ld a, e
    and %01000000
    ldh [rAUD4GO], a

.done_macro:
    ld a, c
    or a
    jr z, .after_effect4

    ld e, 3
    call do_effect      ; make sure we never return with ret_dont_call_playnote macro

.after_effect4:

process_tick:
    ld hl, counter
    inc [hl]

    ld a, [ticks_per_row]
    ld b, a

    ld hl, tick
    ld a, [hl]
    inc a

    cp b
    jr z, .newrow

    ld [hl], a
    ret

.newrow:
    ;; Reset tick to 0
    ld [hl], 0

    ;; Check if we need to perform a row break or pattern break
    ld a, [row_break]
    or a
    jr z, .no_break

    ;; These are offset by one so we can check to see if they've
    ;; been modified
    dec a
    ld b, a

    ld hl, row_break
    xor a
    ld [hl-], a
    or [hl]     ; a = [next_order], zf = ([next_order] == 0)
    ld [hl], 0

    jr z, .neworder

    dec a
    add a ; multiply order by 2 (they are words)

    jr .update_current_order

.no_break:
    ;; Increment row.
    ld a, [row]
    inc a
    ld b, a
    cp PATTERN_LENGTH
    jr nz, .noreset

    ld b, 0
.neworder:
    ;; Increment order and change loaded patterns
    ld a, [order_cnt]
    ld c, a
    ld a, [current_order]
    add 2
    cp c
    jr nz, .update_current_order
    xor a
.update_current_order:
    ;; Call with:
    ;; A: The order to load
    ;; B: The row for the order to start on
    ld [current_order], a
    ld c, a
    call load_patterns

.noreset:
    ld a, b
    ld [row], a

IF DEF(PREVIEW_MODE)
    db $fd ; signal row update to tracker
ENDC
    ret

note_table:
include "include/hUGE_note_table.inc"


IF DEF(GBDK)

SECTION "hUGEDriver GBDK wrappers", ROM0

_hUGE_init_banked::
    ld hl, sp+2+4
    jr continue_init
_hUGE_init::
    ld hl, sp+2
continue_init:
    push bc
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call hUGE_init
    pop bc
    ret

_hUGE_mute_channel_banked::
    ld hl, sp+3+4
    jr continue_mute
_hUGE_mute_channel::
    ld hl, sp+3
continue_mute:
    push bc
    ld a, [hl-]
    and 1
    ld c, a
    ld b, [hl]
    call hUGE_mute_channel
    pop  bc
    ret

_hUGE_set_position_banked::
    ld hl, sp+2+4
    jr continue_set_position
_hUGE_set_position::
    ld hl, sp+2
continue_set_position:
    push bc
    ld c, [hl]
    call hUGE_set_position
    pop  bc
    ret

ENDC
