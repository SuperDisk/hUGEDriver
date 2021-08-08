dn: MACRO ;; (note, instr, effect)
    db \1
    db ((\2 << 4) | (\3 >> 8))
    db LOW(\3)
ENDM

rsreset
def C_3 rb
def C#3 rb
def D_3 rb
def D#3 rb
def E_3 rb
def F_3 rb
def F#3 rb
def G_3 rb
def G#3 rb
def A_3 rb
def A#3 rb
def B_3 rb
def C_4 rb
def C#4 rb
def D_4 rb
def D#4 rb
def E_4 rb
def F_4 rb
def F#4 rb
def G_4 rb
def G#4 rb
def A_4 rb
def A#4 rb
def B_4 rb
def C_5 rb
def C#5 rb
def D_5 rb
def D#5 rb
def E_5 rb
def F_5 rb
def F#5 rb
def G_5 rb
def G#5 rb
def A_5 rb
def A#5 rb
def B_5 rb
def C_6 rb
def C#6 rb
def D_6 rb
def D#6 rb
def E_6 rb
def F_6 rb
def F#6 rb
def G_6 rb
def G#6 rb
def A_6 rb
def A#6 rb
def B_6 rb
def C_7 rb
def C#7 rb
def D_7 rb
def D#7 rb
def E_7 rb
def F_7 rb
def F#7 rb
def G_7 rb
def G#7 rb
def A_7 rb
def A#7 rb
def B_7 rb
def C_8 rb
def C#8 rb
def D_8 rb
def D#8 rb
def E_8 rb
def F_8 rb
def F#8 rb
def G_8 rb
def G#8 rb
def A_8 rb
def A#8 rb
def B_8 rb
def LAST_NOTE rb
___ EQU 90 ; the default "no note" value
