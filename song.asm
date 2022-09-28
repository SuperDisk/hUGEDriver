include "include/hUGE.inc"

SECTION "Song Data", ROMX

;; song descriptor

SONG_DESCRIPTOR::
db TICKS  ; tempo
dw order_cnt
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

;;;;;;;;;;;
;; Orders
;;;;;;;;;;;

include "order.htt"

;;;;;;;;;;;;
;; Patterns
;;;;;;;;;;;;

include "pattern.htt"
include "subpattern.htt"

;;;;;;;;;;;;;;;;
;; Instruments
;;;;;;;;;;;;;;;;

duty_instruments:

include "duty_instrument.htt"

wave_instruments:

include "wave_instrument.htt"

noise_instruments:

include "noise_instrument.htt"

;;;;;;;;;;;;;
;; Routines
;;;;;;;;;;;;;

MACRO loadRoutine
__hUGE_Routine_\1:
include "routine\1.htt"
__end_hUGE_Routine_\1:
  ret
ENDM

  loadRoutine 0
  loadRoutine 1
  loadRoutine 2
  loadRoutine 3
  loadRoutine 4
  loadRoutine 5
  loadRoutine 6
  loadRoutine 7
  loadRoutine 8
  loadRoutine 9
  loadRoutine 10
  loadRoutine 11
  loadRoutine 12
  loadRoutine 13
  loadRoutine 14
  loadRoutine 15

routines:
dw __hUGE_Routine_0, __hUGE_Routine_1, __hUGE_Routine_2, __hUGE_Routine_3, __hUGE_Routine_4, __hUGE_Routine_5, __hUGE_Routine_6, __hUGE_Routine_7
dw __hUGE_Routine_8, __hUGE_Routine_9, __hUGE_Routine_10, __hUGE_Routine_11, __hUGE_Routine_12, __hUGE_Routine_13, __hUGE_Routine_14, __hUGE_Routine_15

;;;;;;;;;
;; Waves
;;;;;;;;;

waves:

include "wave.htt"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
