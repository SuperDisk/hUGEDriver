; aPACK/aPLib decompressor
; Intel 8080 version by Ivan Gorodetsky, 2018-2020
; GBZ80 adaptation by Tony Pavlov, 2020
; No self-modifying code
; Based on z80 version by dwedit/utopian/Metalbrain

; de = source
; bc = dest
; call UNAPACK

SECTION "Unapack Decompressor", ROM0

; _UNAPACK::
;         PUSH    BC
;         LDA     HL,4(SP)
;         LD      A,(HL+)
;         LD      E,A
;         LD      A,(HL+)
;         LD      D,A
;         LD      A,(HL+)
;         LD      C,A
;         LD      A,(HL)
;         LD      B,A
;         CALL    UNAPACK
;         POP     BC
;         RET

UNAPACK::
        LD      A,$80
        LD      [BITS],A

APBRANCH1:
        LD      A,[DE]
        INC     DE
APLOOP0:
        LD      [BC],A
        INC     BC
        LD      A,-1
APLOOP:
        LD      [DECR],A
        CALL    AP_GETBIT
        JR      NC,APBRANCH1
        ADD     A,A
        CALL    Z,AP_GETBIT3
        JR      NC,APBRANCH2
        ADD     A,A
        CALL    Z,AP_GETBIT3
        JR      NC,APBRANCH3
        LD      L,A
        LD      H,$10
APGET4BITS:
        ADD     A,A
        JR      NZ,APGET4BITS1
        LD      A,[DE]
        INC     DE
        LD      L,A
        ADC     A,A
APGET4BITS1:
        ADD     HL,HL
        JR      NC,APGET4BITS
        LD      [BITS],A
        XOR     A
        OR      H
        JR      Z,APLOOP0
        LD      A,C
        SUB     H
        LD      L,A
        LD      A,B
        SBC     A,0
        LD      H,A
        LD      A,[HL]
        JR      APLOOP0
APBRANCH3:
        LD      [BITS],A
        LD      H,0
        LD      A,[DE]
        RRA
        LD      L,A
        RRA
        ADC     A,A
        RET     Z
        INC     DE
        LD      A,2
        ADC     A,H
        PUSH    DE

        LD      E, A

        LD      A,L
        LD      [OFFSET], A
        LD      A,H
        LD      [OFFSET+1], A

        LD      D,H
        JR      AP_FINISHUP
APBRANCH2:
        CALL    AP_GETGAMMA
        DEC     E
        LD      A,[DECR]
        ADD     A,E
        JR      Z,AP_R0_GAMMA
        DEC     A
        LD      D,A
        LD      E,[HL]

        PUSH    HL
        LD      H,D
        LD      L,E
        POP     DE

        INC     DE

        LD      A,L
        LD      [OFFSET], A
        LD      A,H
        LD      [OFFSET+1], A

        PUSH    HL
        CALL    AP_GETGAMMA_

        PUSH    DE
        LD      A,L
        LD      D,H
        ld hl, sp+2
        ; LDA     HL,2(SP)
        LD      E,[HL]
        LD      [HL+],A
        LD      A,[HL]
        LD      [HL],D
        LD      H,A
        LD      L,E
        POP     DE

        LD      A,H
        CP      32000/256
        JR      NC,APSKIP1
        CP      5
        JR      C,APSKIP2
        INC     DE
APSKIP2:
        LD      A,$7F
        SUB     L
        LD      A,0
        SBC     A,H
        JR      C,APSKIP3
APSKIP1:
        INC     DE
        INC     DE
APSKIP3:
AP_FINISHUP:
        LD      A,C
        SUB     L
        LD      L,A
        LD      A,B
        SBC     A,H
        LD      H,A
AP_FINISHUP2::
        INC     D
LDIR:
        LD      A,[HL+]
        LD      [BC],A
        INC     BC
        DEC     E
        JR      NZ, LDIR
        DEC     D
        JR      NZ, LDIR
        XOR     A
        POP     DE
        JP      APLOOP

AP_R0_GAMMA:
        PUSH    HL
        LD      H,D
        LD      L,E
        POP     DE

        CALL    AP_GETGAMMA_
        PUSH    HL

        LD      HL,OFFSET
        LD      A,[HL+]
        LD      H,[HL]
        LD      L,A

        JR      AP_FINISHUP
AP_GETBIT:
        LD      A,[BITS]
AP_GETBIT2:
        ADD     A,A
        LD      [BITS],A
        RET     NZ
AP_GETBIT3:
        LD      A,[DE]
        INC     DE
        ADC     A,A
AP_GETBIT4:
        LD      [BITS],A
        RET

AP_GETGAMMA_:
        LD      A,[BITS]
AP_GETGAMMA:
        LD      HL,1
AP_GETGAMMALOOP:
        ADD     HL,HL
        ADD     A,A
        CALL    Z,AP_GETBIT3
        JR      NC,AP_GETGAMMALOOP1
        INC     L
AP_GETGAMMALOOP1:
        ADD     A,A
        CALL    Z,AP_GETBIT3
        JR      C,AP_GETGAMMALOOP

        PUSH    HL
        LD      H,D
        LD      L,E
        POP     DE

        JR      AP_GETBIT4


SECTION "Unapack vars", WRAM0
OFFSET:
        DS 2
BITS:
        DS 1
DECR:
        DS 1
