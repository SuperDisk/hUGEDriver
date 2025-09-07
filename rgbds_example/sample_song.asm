include "hUGE.inc"

SECTION "sample_song Song Data", ROMX

sample_song::
db 7, 7, 7, 7
db 2
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

order1: dw P0
order2: dw P20
order3: dw P40
order4: dw P60

duty_instruments:
itSquareinst1:
db 8
db 0
db 144
dw itSquareSP1
db 128

itSquareinst2:
db 8
db 128
db 112
dw itSquareSP2
db 128

itSquareinst3:
db 8
db 0
db 48
dw 0
db 128



wave_instruments:
itWaveinst1:
db 0
db 32
db 0
dw 0
db 128

itWaveinst2:
db 0
db 32
db 1
dw itWaveSP2
db 128



noise_instruments:
itNoiseinst1:
db 98
dw itNoiseSP1
db 0
ds 2

itNoiseinst2:
db 65
dw 0
db 0
ds 2



routines:
__hUGE_Routine_0:

__end_hUGE_Routine_0:
ret

__hUGE_Routine_1:

__end_hUGE_Routine_1:
ret

__hUGE_Routine_2:

__end_hUGE_Routine_2:
ret

__hUGE_Routine_3:

__end_hUGE_Routine_3:
ret

__hUGE_Routine_4:

__end_hUGE_Routine_4:
ret

__hUGE_Routine_5:

__end_hUGE_Routine_5:
ret

__hUGE_Routine_6:

__end_hUGE_Routine_6:
ret

__hUGE_Routine_7:

__end_hUGE_Routine_7:
ret

__hUGE_Routine_8:

__end_hUGE_Routine_8:
ret

__hUGE_Routine_9:

__end_hUGE_Routine_9:
ret

__hUGE_Routine_10:

__end_hUGE_Routine_10:
ret

__hUGE_Routine_11:

__end_hUGE_Routine_11:
ret

__hUGE_Routine_12:

__end_hUGE_Routine_12:
ret

__hUGE_Routine_13:

__end_hUGE_Routine_13:
ret

__hUGE_Routine_14:

__end_hUGE_Routine_14:
ret

__hUGE_Routine_15:

__end_hUGE_Routine_15:
ret

waves:
wave0: db 137,172,222,239,255,238,220,169,134,83,33,16,0,17,35,86
wave1: db 18,68,86,103,119,103,120,136,153,154,170,187,204,204,204,204

P0:
 dn A_5,3,$047
 dn ___,0,$047
 dn ___,0,$047
 dn ___,0,$047
 dn G_5,2,$000
 dn ___,0,$000
 dn ___,0,$C02
 dn G_5,2,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn E_5,2,$000
 dn ___,0,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn A_5,3,$047
 dn ___,0,$047
 dn ___,0,$047
 dn ___,0,$047
 dn G_5,2,$000
 dn ___,0,$000
 dn ___,0,$C02
 dn G_5,2,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn E_5,2,$000
 dn ___,0,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn A_5,3,$047
 dn ___,0,$047
 dn ___,0,$047
 dn ___,0,$047
 dn G_5,2,$000
 dn ___,0,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C01
 dn E_5,2,$000
 dn ___,0,$C01
 dn G_4,2,$E04
 dn G_4,2,$E04
 dn G_4,2,$E04
 dn A_5,3,$047
 dn ___,0,$047
 dn ___,0,$047
 dn ___,0,$047
 dn G_5,2,$000
 dn ___,0,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C02
 dn F#5,2,$000
 dn ___,0,$C01
 dn E_5,2,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P20:
 dn A_4,2,$000
 dn ___,0,$000
 dn A_4,2,$000
 dn A_4,2,$000
 dn E_5,0,$330
 dn ___,0,$000
 dn E_5,2,$C02
 dn E_5,2,$000
 dn ___,0,$C02
 dn D_5,2,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn C#5,2,$000
 dn ___,0,$000
 dn C#5,2,$C01
 dn ___,0,$000
 dn G_4,2,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn A_4,2,$000
 dn E_5,0,$330
 dn ___,0,$000
 dn C#5,2,$C02
 dn E_5,2,$000
 dn ___,0,$C02
 dn C#5,2,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn A_5,2,$000
 dn ___,0,$000
 dn ___,0,$C01
 dn ___,0,$000
 dn A_4,2,$000
 dn E_4,2,$000
 dn A_4,2,$000
 dn A_4,2,$000
 dn E_5,0,$330
 dn ___,0,$000
 dn C#5,2,$C02
 dn D_5,2,$000
 dn ___,0,$C02
 dn D_5,2,$000
 dn ___,0,$C01
 dn C#5,2,$000
 dn ___,0,$C01
 dn D_4,2,$E04
 dn D_4,2,$E04
 dn D_4,2,$E04
 dn G_4,2,$000
 dn ___,0,$000
 dn G_4,2,$000
 dn A_4,2,$000
 dn E_5,0,$330
 dn ___,0,$000
 dn C#5,2,$C02
 dn C#5,2,$000
 dn ___,0,$C02
 dn C#5,2,$000
 dn ___,0,$C01
 dn A_5,2,$000
 dn ___,0,$C01
 dn G_5,2,$000
 dn F#5,2,$000
 dn E_5,2,$000

P40:
 dn B_6,1,$270
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn B_6,1,$270
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn A_4,2,$000
 dn B_6,1,$270
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn B_6,1,$270
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn A_3,2,$000
 dn G_4,2,$000
 dn A_4,2,$000

P60:
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C44
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C14
 dn A_7,2,$C44
 dn A_7,2,$C14
 dn A_7,1,$000
 dn A_7,2,$C14
 dn A_7,2,$C44
 dn A_7,2,$C14

itSquareSP1:
 dn 48,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,4,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itSquareSP2:
 dn 48,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,3,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itWaveSP2:
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$C08
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

itNoiseSP1:
 dn 36,0,$000
 dn 24,0,$000
 dn 48,0,$000
 dn 36,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,5,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,1,$000

