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

              LDX SP ; initialize frame base from SP (callers may set X before calls)
main_loop:    LDA #0x03
              STA ?b0 ; x (b0)
              LDA #0x02
              STA ?b1 ; x (b1)
              LDA #0x01
              STA ?b2 ; x (b2)
              LDA #0x00
              STA ?b3 ; x (b3)
              LDA #0x01
              STA ?b4 ; y (b0)
              LDA #0x00
              STA ?b5 ; y (b1)
              LDA #0x00
              STA ?b6 ; y (b2)
              LDA #0x00
              STA ?b7 ; y (b3)
              JSR ?add32_l2_l0_l1 ; l2 <- l0 + l1
              JSR ?mov32_l3_l2 ; mov32 result <- z
              LDA ?b8 ; z
              JMP main_loop

?mov32_l3_l2: LDA ?b8
              STA ?b12
              LDA ?b9
              STA ?b13
              LDA ?b10
              STA ?b14
              LDA ?b11
              STA ?b15
              RTS
