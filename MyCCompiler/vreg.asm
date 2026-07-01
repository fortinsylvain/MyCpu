; virtual registers
;-----------------------------------------------------------------------------
; ?b15 ?b14 ?b13 ?b12 | ?b11 ?b10 ?b9 ?b8 | ?b7 ?b6 ?b5 ?b4 | ?b3 ?b2 ?b1 ?b0 |  8 bits
;    ?w7       ?w6    |    ?w5      ?w4   |   ?w3     ?w2   |   ?w1     ?w0   | 16 bits
;         ?l3         |         ?l2       |       ?l1       |       ?l0       | 32 bits
;-----------------------------------------------------------------------------

?b15     EQU 0x0000
?b14     EQU 0x0001
?b13     EQU 0x0002
?b12     EQU 0x0003
?b11     EQU 0x0004
?b10     EQU 0x0005
?b9      EQU 0x0006
?b8      EQU 0x0007
?b7      EQU 0x0008
?b6      EQU 0x0009
?b5      EQU 0x000A
?b4      EQU 0x000B
?b3      EQU 0x000C
?b2      EQU 0x000D
?b1      EQU 0x000E
?b0      EQU 0x000F

?w7      EQU 0x0000  ; ?b15:?b14
?w6      EQU 0x0002  ; ?b13:?b12
?w5      EQU 0x0004  ; ?b11:?b10
?w4      EQU 0x0006  ; ?b9:?b8
?w3      EQU 0x0008  ; ?b7:?b6
?w2      EQU 0x000A  ; ?b5:?b4
?w1      EQU 0x000C  ; ?b3:?b2
?w0      EQU 0x000E  ; ?b1:?b0

?l3      EQU 0x0000  ; ?b15,?b14,?b13,?b12
?l2      EQU 0x0004  ; ?b11,?b10,?b9,?b8
?l1      EQU 0x0008  ; ?b7,?b6,?b5,?b4
?l0      EQU 0x000C  ; ?b3,?b2,?b1,?b0

; ------------------ mov32 implementations ------------------
?mov32_l0_l0:
    LDA ?b0
    STA ?b0
    LDA ?b1
    STA ?b1
    LDA ?b2
    STA ?b2
    LDA ?b3
    STA ?b3
    RTS

?mov32_l0_l1:
    LDA ?b4
    STA ?b0
    LDA ?b5
    STA ?b1
    LDA ?b6
    STA ?b2
    LDA ?b7
    STA ?b3
    RTS

?mov32_l0_l2:
    LDA ?b8
    STA ?b0
    LDA ?b9
    STA ?b1
    LDA ?b10
    STA ?b2
    LDA ?b11
    STA ?b3
    RTS

?mov32_l0_l3:
    LDA ?b12
    STA ?b0
    LDA ?b13
    STA ?b1
    LDA ?b14
    STA ?b2
    LDA ?b15
    STA ?b3
    RTS

?mov32_l1_l0:
    LDA ?b0
    STA ?b4
    LDA ?b1
    STA ?b5
    LDA ?b2
    STA ?b6
    LDA ?b3
    STA ?b7
    RTS

?mov32_l1_l1:
    LDA ?b4
    STA ?b4
    LDA ?b5
    STA ?b5
    LDA ?b6
    STA ?b6
    LDA ?b7
    STA ?b7
    RTS

?mov32_l1_l2:
    LDA ?b8
    STA ?b4
    LDA ?b9
    STA ?b5
    LDA ?b10
    STA ?b6
    LDA ?b11
    STA ?b7
    RTS

?mov32_l1_l3:
    LDA ?b12
    STA ?b4
    LDA ?b13
    STA ?b5
    LDA ?b14
    STA ?b6
    LDA ?b15
    STA ?b7
    RTS

?mov32_l2_l0:
    LDA ?b0
    STA ?b8
    LDA ?b1
    STA ?b9
    LDA ?b2
    STA ?b10
    LDA ?b3
    STA ?b11
    RTS

?mov32_l2_l1:
    LDA ?b4
    STA ?b8
    LDA ?b5
    STA ?b9
    LDA ?b6
    STA ?b10
    LDA ?b7
    STA ?b11
    RTS

?mov32_l2_l2:
    LDA ?b8
    STA ?b8
    LDA ?b9
    STA ?b9
    LDA ?b10
    STA ?b10
    LDA ?b11
    STA ?b11
    RTS

?mov32_l2_l3:
    LDA ?b12
    STA ?b8
    LDA ?b13
    STA ?b9
    LDA ?b14
    STA ?b10
    LDA ?b15
    STA ?b11
    RTS

?mov32_l3_l0:
    LDA ?b0
    STA ?b12
    LDA ?b1
    STA ?b13
    LDA ?b2
    STA ?b14
    LDA ?b3
    STA ?b15
    RTS

?mov32_l3_l1:
    LDA ?b4
    STA ?b12
    LDA ?b5
    STA ?b13
    LDA ?b6
    STA ?b14
    LDA ?b7
    STA ?b15
    RTS

?mov32_l3_l2:
    LDA ?b8
    STA ?b12
    LDA ?b9
    STA ?b13
    LDA ?b10
    STA ?b14
    LDA ?b11
    STA ?b15
    RTS

?mov32_l3_l3:
    LDA ?b12
    STA ?b12
    LDA ?b13
    STA ?b13
    LDA ?b14
    STA ?b14
    LDA ?b15
    STA ?b15
    RTS

; ------------------ add32 implementations ------------------
; lD = lD + lR  (handles carry across bytes)
?add32_l0_l0_l0:
    LDA ?b0
    ADDA ?b0
    STA ?b0
    LDA ?b1
    ADCA ?b1
    STA ?b1
    LDA ?b2
    ADCA ?b2
    STA ?b2
    LDA ?b3
    ADCA ?b3
    STA ?b3
    RTS

?add32_l0_l0_l1:
    LDA ?b0
    ADDA ?b4
    STA ?b0
    LDA ?b1
    ADCA ?b5
    STA ?b1
    LDA ?b2
    ADCA ?b6
    STA ?b2
    LDA ?b3
    ADCA ?b7
    STA ?b3
    RTS

?add32_l0_l0_l2:
    LDA ?b0
    ADDA ?b8
    STA ?b0
    LDA ?b1
    ADCA ?b9
    STA ?b1
    LDA ?b2
    ADCA ?b10
    STA ?b2
    LDA ?b3
    ADCA ?b11
    STA ?b3
    RTS

?add32_l0_l0_l3:
    LDA ?b0
    ADDA ?b12
    STA ?b0
    LDA ?b1
    ADCA ?b13
    STA ?b1
    LDA ?b2
    ADCA ?b14
    STA ?b2
    LDA ?b3
    ADCA ?b15
    STA ?b3
    RTS

; (and similarly for add where dest is l1,l2,l3)
?add32_l1_l1_l0:
    LDA ?b4
    ADDA ?b0
    STA ?b4
    LDA ?b5
    ADCA ?b1
    STA ?b5
    LDA ?b6
    ADCA ?b2
    STA ?b6
    LDA ?b7
    ADCA ?b3
    STA ?b7
    RTS

?add32_l1_l1_l1:
    LDA ?b4
    ADDA ?b4
    STA ?b4
    LDA ?b5
    ADCA ?b5
    STA ?b5
    LDA ?b6
    ADCA ?b6
    STA ?b6
    LDA ?b7
    ADCA ?b7
    STA ?b7
    RTS

?add32_l1_l1_l2:
    LDA ?b4
    ADDA ?b8
    STA ?b4
    LDA ?b5
    ADCA ?b9
    STA ?b5
    LDA ?b6
    ADCA ?b10
    STA ?b6
    LDA ?b7
    ADCA ?b11
    STA ?b7
    RTS

?add32_l1_l1_l3:
    LDA ?b4
    ADDA ?b12
    STA ?b4
    LDA ?b5
    ADCA ?b13
    STA ?b5
    LDA ?b6
    ADCA ?b14
    STA ?b6
    LDA ?b7
    ADCA ?b15
    STA ?b7
    RTS

?add32_l2_l2_l0:
    LDA ?b8
    ADDA ?b0
    STA ?b8
    LDA ?b9
    ADCA ?b1
    STA ?b9
    LDA ?b10
    ADCA ?b2
    STA ?b10
    LDA ?b11
    ADCA ?b3
    STA ?b11
    RTS

?add32_l2_l2_l1:
    LDA ?b8
    ADDA ?b4
    STA ?b8
    LDA ?b9
    ADCA ?b5
    STA ?b9
    LDA ?b10
    ADCA ?b6
    STA ?b10
    LDA ?b11
    ADCA ?b7
    STA ?b11
    RTS

?add32_l2_l2_l2:
    LDA ?b8
    ADDA ?b8
    STA ?b8
    LDA ?b9
    ADCA ?b9
    STA ?b9
    LDA ?b10
    ADCA ?b10
    STA ?b10
    LDA ?b11
    ADCA ?b11
    STA ?b11
    RTS

?add32_l2_l2_l3:
    LDA ?b8
    ADDA ?b12
    STA ?b8
    LDA ?b9
    ADCA ?b13
    STA ?b9
    LDA ?b10
    ADCA ?b14
    STA ?b10
    LDA ?b11
    ADCA ?b15
    STA ?b11
    RTS

?add32_l3_l3_l0:
    LDA ?b12
    ADDA ?b0
    STA ?b12
    LDA ?b13
    ADCA ?b1
    STA ?b13
    LDA ?b14
    ADCA ?b2
    STA ?b14
    LDA ?b15
    ADCA ?b3
    STA ?b15
    RTS

?add32_l3_l3_l1:
    LDA ?b12
    ADDA ?b4
    STA ?b12
    LDA ?b13
    ADCA ?b5
    STA ?b13
    LDA ?b14
    ADCA ?b6
    STA ?b14
    LDA ?b15
    ADCA ?b7
    STA ?b15
    RTS

?add32_l3_l3_l2:
    LDA ?b12
    ADDA ?b8
    STA ?b12
    LDA ?b13
    ADCA ?b9
    STA ?b13
    LDA ?b14
    ADCA ?b10
    STA ?b14
    LDA ?b15
    ADCA ?b11
    STA ?b15
    RTS

?add32_l3_l3_l3:
    LDA ?b12
    ADDA ?b12
    STA ?b12
    LDA ?b13
    ADCA ?b13
    STA ?b13
    LDA ?b14
    ADCA ?b14
    STA ?b14
    LDA ?b15
    ADCA ?b15
    STA ?b15
    RTS

; ------------------ load32 implementations (load from memory at X) ------------------
?load32_l0:
    LDA (0x0000,X)
    STA ?b0
    LDA (0x0001,X)
    STA ?b1
    LDA (0x0002,X)
    STA ?b2
    LDA (0x0003,X)
    STA ?b3
    RTS

?load32_l1:
    LDA (0x0000,X)
    STA ?b4
    LDA (0x0001,X)
    STA ?b5
    LDA (0x0002,X)
    STA ?b6
    LDA (0x0003,X)
    STA ?b7
    RTS

?load32_l2:
    LDA (0x0000,X)
    STA ?b8
    LDA (0x0001,X)
    STA ?b9
    LDA (0x0002,X)
    STA ?b10
    LDA (0x0003,X)
    STA ?b11
    RTS

?load32_l3:
    LDA (0x0000,X)
    STA ?b12
    LDA (0x0001,X)
    STA ?b13
    LDA (0x0002,X)
    STA ?b14
    LDA (0x0003,X)
    STA ?b15
    RTS

; ------------------ store32 implementations (store lS to memory at X) ------------------
?store32_l0:
    LDA ?b0
    STA (0x0000,X)
    LDA ?b1
    STA (0x0001,X)
    LDA ?b2
    STA (0x0002,X)
    LDA ?b3
    STA (0x0003,X)
    RTS

?store32_l1:
    LDA ?b4
    STA (0x0000,X)
    LDA ?b5
    STA (0x0001,X)
    LDA ?b6
    STA (0x0002,X)
    LDA ?b7
    STA (0x0003,X)
    RTS

?store32_l2:
    LDA ?b8
    STA (0x0000,X)
    LDA ?b9
    STA (0x0001,X)
    LDA ?b10
    STA (0x0002,X)
    LDA ?b11
    STA (0x0003,X)
    RTS

?store32_l3:
    LDA ?b12
    STA (0x0000,X)
    LDA ?b13
    STA (0x0001,X)
    LDA ?b14
    STA (0x0002,X)
    LDA ?b15
    STA (0x0003,X)
    RTS

; end of vreg.asm
