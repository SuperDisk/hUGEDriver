
SECTION "Sound driver variables", WRAM0

pattern1:: dw
pattern2:: dw
pattern3:: dw
pattern4:: dw

ticks_per_row:: db
current_order:: dw
next_order:: dw
row_break:: db

;; TODO: Find some way to get rid of this thing.
temp_note_value:: dw

channels::

;;;;;;;;;;;
;;Channel 1
;;;;;;;;;;;
channel1::
channel_period1:: dw
toneporta_target1:: dw
channel_note1:: db
vibrato_tremolo_phase1:: db
envelope1:: db
highmask1:: db

;;;;;;;;;;;
;;Channel 2
;;;;;;;;;;;
channel2::
channel_period2:: dw
toneporta_target2:: dw
channel_note2:: db
vibrato_tremolo_phase2:: db
envelope2:: db
highmask2:: db

;;;;;;;;;;;
;;Channel 3
;;;;;;;;;;;
channel3::
channel_period3:: dw
toneporta_target3:: dw
channel_note3:: db
vibrato_tremolo_phase3:: db
envelope3:: db
highmask3:: db

;;;;;;;;;;;
;;Channel 4
;;;;;;;;;;;
channel4::
channel_period4:: dw
toneporta_target4:: dw
channel_note4:: db
vibrato_tremolo_phase4:: db
envelope4:: db
highmask4:: db

row:: ds 1
tick:: ds 1
