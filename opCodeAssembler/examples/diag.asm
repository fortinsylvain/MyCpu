; -----------------------------------------------------------------
; Homebrew MyCPU diagnostic program
; Author: Sylvain Fortin sylfortin71@hotmail.com
; Date : 29 december 2025
; Documentation : diag.asm is a test program that verifying every 
;                 assembler instructions of MyCPU.
; Memory map of the computer
; 0000H - 17FFH Total RAM space
; 00A0H - 00FFH Stack
; E000H - F000H EEPROM for application program
; -----------------------------------------------------------------

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

; RAM Reserved location
TEMP0    EQU 0x1FEC  ; TEMP0
TEMP1    EQU 0x1FED  ; TEMP1
TEMP2    EQU 0x1FEE  ; TEMP2
TEMP3    EQU 0x1FEF  ; TEMP3
SP       EQU 0x1FF0  ; SP      Stack Pointer 8 bit
JSH      EQU 0x1FF1  ; JSH     Temporary storage for JSR MSB address
JSL      EQU 0x1FF2  ; JSL          "       "     "   "  LSB    "
XH       EQU 0x1FF3  ; X MSB   X Register MSB
XL       EQU 0x1FF4  ; X LSB   X Register LSB
EQUAL    EQU 0x1FFA  ; E       bit<0> Equal Status bit
CARRY    EQU 0x1FFB  ; C       bit<0> Carry Status bit
REG_A    EQU 0x1FFC  ; A       A Register
IPH      EQU 0x1FFE  ; IPH	    Instruction Pointer MSB
IPL      EQU 0x1FFF  ; IPL          "         "    LSB

; Peripheral
LEDPORT  EQU 0xC000  ; PORT for the LED

; Program start
         ORG/0xE000  ; EEPROM Start        
START    LDA #0x00   ; Clear LED
         NOTA
         STA LEDPORT ; Output to LED port
         ; --------------------------------------------------------------------
         ; Test Carry Status bit integrity
         ; --------------------------------------------------------------------
TST01    LDA #0x01
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         STA CARRY   ; Write 0 to carry bit <0>
         LDA CARRY   ; Read Carry Status
         CMPA #0x00
         JNE FAIL
         LDA #0x01
         STA CARRY   ; Write 1 to carry bit <0>
         LDA CARRY   ; Read Carry Status
         CMPA #0x01
         JNE FAIL
         LDA #0x00
         STA CARRY   ; Write 0 to carry bit <0>
         LDA CARRY   ; Read Carry Status
         CMPA #0x00
         JNE FAIL
         ; --------------------------------------------------------------------
         ; Test Equal Status bit integrity
         ; --------------------------------------------------------------------
TST02    LDA #0x02
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         STA EQUAL   ; Write 0 to Equal Status bit <0>
         LDA EQUAL   ; Read Equal Status
         CMPA #0x00
         JNE FAIL
         LDA #0x01
         STA EQUAL   ; Write 1 to Equal Status bit <0>
         LDA EQUAL   ; Read Equal Status
         CMPA #0x01
         JNE FAIL
         LDA #0x00
         STA EQUAL   ; Write 0 to Equal Status bit <0>
         LDA EQUAL   ; Read Equal Status
         CMPA #0x00
         JNE FAIL

         ; --------------------------------------------------------------------
         ; OP.03 INCA  A = A + 1  INCREMENT REGISTRE A
         ; E UPDATE, C unchanged
         ; --------------------------------------------------------------------
TSTOP03  LDA #0x03
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         INCA
         CMPA #0x01
         JNE FAIL
         LDA #0x01
         INCA
         CMPA #0x02
         JNE FAIL
         LDA #0x7C
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         CMPA #0x86
         JNE FAIL
         LDA #0xFE
         INCA
         CMPA #0xFF
         JNE FAIL
         LDA #0xFF
         INCA
         CMPA #0x00
         JNE FAIL
         LDA #0xFF
         INCA
         INCA
         CMPA #0x01
         JNE FAIL
         INCA
         INCA
         INCA
         INCA
         CMPA #0x05
         JNE FAIL
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         CMPA #0x0D
         JNE FAIL
         LDA #0x00   ; Test Carry unchanged
         STA CARRY   ; Clear Carry 
         LDA #0xFF
         INCA
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x00  ; Expecting C=0 and <7:1> = 0
         JNE FAIL
         LDA #0x01   ; Set Carry 
         STA CARRY   
         LDA #0xEB
         INCA
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x01  ; Expecting C=1 and <7:1> = 0
         JNE FAIL
         LDA #0xFE   ; Test Equal (Set when result is 0)
         INCA
         LDA EQUAL   ; Read Equal status
         CMPA #0x00  ; Expecting E=0 and <7:1> = 0
         JNE FAIL
         LDA #0xFF
         INCA
         LDA EQUAL   ; Read Equal status
         CMPA #0x01  ; Expecting E=1 and <7:1> = 0
         JNE FAIL
         LDA #0x00
         INCA
         LDA EQUAL
         CMPA #0x00  ; Expecting E=0 and <7:1> = 0
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.04  LDX #0x****   Load X Register with 16 bits immediate value
         ; --------------------------------------------------------------------
TSTOP04  LDA #0x04
         NOTA
         STA LEDPORT ; Output to LED port
         LDX #0x1234
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x12
         JNE FAIL
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x34
         JNE FAIL
         LDX #0xABCD
         LDA XH      ; Read Reg X MSB into A
         CMPA #0xAB
         JNE FAIL
         LDA XL      ; Read Reg X LSB into A
         CMPA #0xCD
         JNE FAIL
         ; Test using symbolic
         LDX #?b0    ; ?b0      EQU 0x000F
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x00
         JNE FAIL
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x0F
         JNE FAIL
         LDX #SP     ; SP       EQU 0x1FF0
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x1F
         JNE FAIL
         LDA XL      ; Read Reg X LSB into A
         CMPA #0xF0
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.05  INCX   Increment Register X,  Carry Not Updated
         ; --------------------------------------------------------------------
TSTOP05  LDA #0x05
         NOTA
         STA LEDPORT ; Output to LED port
         LDX #0x0000 ; Clear X register
         INCX        ; Increment X
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x01
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x00
         JNE FAIL
         INCX
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x02
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x00
         JNE FAIL
         
         LDX #0x00FF ; Test a carry set
         INCX        ; Increment X
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x00
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x01
         JNE FAIL
         INCX        ; Increment X
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x01
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x01
         JNE FAIL
         
         LDX #0x1EFF
         INCX        ; Increment X
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x00
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x1F
         JNE FAIL
         
         LDX #0xFFFF
         INCX        ; Increment X
         LDA XL      ; Read Reg X LSB into A
         CMPA #0x00
         JNE FAIL
         LDA XH      ; Read Reg X MSB into A
         CMPA #0x00
         JNE FAIL

         ; --------------------------------------------------------------------
         ; OP.06 JSR    Jump to SubRoutine
         ; --------------------------------------------------------------------
TSTOP06  LDA #0x06
         NOTA
         STA LEDPORT ; Output to LED port
         JSR TJSR1   ; 1 layer
         JSR TJSR2   ; 2
         JSR TJSR3   ; 3
         JSR TJSR4   ; 4
         JSR TJSR5   ; 5
         JSR TJSR6   ; 6
         JSR TJSR7   ; 7
         JSR TJSR8   ; 8
         JSR TJSR9   ; 9
         JSR TJSR10  ; 10
         ; --------------------------------------------------------------------
         ; OP.07 RTS    ReTurn from Subroutine
         ; Tested in OP.06 JSR
         ; --------------------------------------------------------------------
         ;LDA #07H
         ;NOTA
         ;STA LEDPORT ; Output to LED port
         ; --------------------------------------------------------------------
         ; OP.08 STOP
         ; STOP EXECUTING
         ; Cannot test here it will stop execution...
         ; A diagnostic test failure is expected to call this instruction ending 
         ; program exectution.
         ; --------------------------------------------------------------------
         ;LDA #08H
         ;NOTA
         ;STA LEDPORT ; Output to LED port
         ;STOP
         ; --------------------------------------------------------------------
         ; OP.09 NOP   NO OPERATION
         ; --------------------------------------------------------------------
TSTOP09  LDA #0x09
         NOTA
         STA LEDPORT ; Output to LED port
         NOP
         NOP
         NOP
         ; --------------------------------------------------------------------
         ; OP.0A LDA (X) Load Reg A Indexed
         ; --------------------------------------------------------------------
TSTOP0A  LDA #0x0A
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x55   ; Store some value in RAM
         STA 0x0100
         LDA #0xAA
         STA 0x0101
         LDA #0xDE
         STA 0x01F0
         LDA #0xCA
         STA 0x01FF
         LDX #0x0100 ; Verify each locations
         LDA (X)
         CMPA #0x55
         JNE FAIL    ; Jump if result not good
         LDX #0x0101
         LDA (X)
         CMPA #0xAA
         JNE FAIL
         LDX #0x01F0
         LDA (X)
         CMPA #0xDE
         JNE FAIL
         LDX #0x01FF
         LDA (X)
         CMPA #0xCA
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.0B STA (X) Store Reg A Indexed
         ; --------------------------------------------------------------------
TSTOP0B  LDA #0x0B
         NOTA
         STA LEDPORT ; Output to LED port
         ; --------------------------------------------------------------------
         ; OP.0C JRA 0x** Unconditional relative jump
         ; --------------------------------------------------------------------
         ; Testing using hexadecimal value after the mnemonic
         LDA #0x0C
         NOTA
         STA LEDPORT ; Output to LED port
         JRA 0x00    ; Test jump foward, Execute next instruction
         JRA 0x01    ; Skip next instruction
         NOP         ; 1
         JRA 0x02    ; Skip next 2 instructions
         NOP         ; 1
         NOP         ; 2
         JRA 0x03    ; Skip next 3 instructions
         NOP         ; 1 
         NOP         ; 2
         NOP         ; 3
         JRA 0x05    ; Skip next 5 instructions
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
         NOP         ; 4
         NOP         ; 5
         JRA 0x10    ; Skip next 16 instructions
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
         NOP         ; 4
         NOP         ; 5
         NOP         ; 6
         NOP         ; 7
         NOP         ; 8
         NOP         ; 9
         NOP         ; 10
         NOP         ; 11
         NOP         ; 12
         NOP         ; 13
         NOP         ; 14
         NOP         ; 15
         NOP         ; 16
         JRA 0x22    ; Skip next 34 bytes
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
         JRA 0x1F   ; 4-5   Final jump to the end of thest
         NOP         ; 6
         NOP         ; 7
         NOP         ; 8
         NOP         ; 9
         NOP         ; 10
         NOP         ; 11
         NOP         ; 12
         NOP         ; 13
         NOP         ; 14
         NOP         ; 15
         NOP         ; 16
         NOP         ; 17
         NOP         ; 18
         NOP         ; 19
         NOP         ; 20
         NOP         ; 21
         NOP         ; 22
         NOP         ; 23
         NOP         ; 24
         NOP         ; 25
         JRA 0xE8    ; 26-27 Third Backward jump
         NOP         ; 28
         NOP         ; 29
         NOP         ; 30
         NOP         ; 31
         NOP         ; 32
         JRA 0xF7    ; 33-34 Second Backward jump
         JRA 0xFC    ; First Backward jump
         NOP         ; Arrival of the last jump to end the test
         ; Testing using symbolic address after the mnemonic
         JRA TST0B_0 ; Test jump foward, Execute next instruction
TST0B_0  JRA TST0B_1 ; Skip next instruction
         NOP         ; 1
TST0B_1  JRA TST0B_2 ; Skip next 2 instructions
         NOP         ; 1
         NOP         ; 2
TST0B_2  JRA TST0B_3 ; Skip next 3 instructions
         NOP         ; 1 
         NOP         ; 2
         NOP         ; 3
TST0B_3  JRA TST0B_4 ; Skip next 5 instructions
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
         NOP         ; 4
         NOP         ; 5
TST0B_4  JRA TST0B_5 ; Skip next 16 instructions
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
         NOP         ; 4
         NOP         ; 5
         NOP         ; 6
         NOP         ; 7
         NOP         ; 8
         NOP         ; 9
         NOP         ; 10
         NOP         ; 11
         NOP         ; 12
         NOP         ; 13
         NOP         ; 14
         NOP         ; 15
         NOP         ; 16
TST0B_5  JRA TST0B_9 ; Skip next 34 bytes
         NOP         ; 1
         NOP         ; 2
         NOP         ; 3
TST0B_6  JRA TST0B_10 ; 4-5   Final jump to the end of test
         NOP         ; 6
         NOP         ; 7
         NOP         ; 8
         NOP         ; 9
         NOP         ; 10
         NOP         ; 11
         NOP         ; 12
         NOP         ; 13
         NOP         ; 14
         NOP         ; 15
         NOP         ; 16
         NOP         ; 17
         NOP         ; 18
         NOP         ; 19
         NOP         ; 20
         NOP         ; 21
         NOP         ; 22
         NOP         ; 23
         NOP         ; 24
         NOP         ; 25
TST0B_7  JRA TST0B_6 ; 26-27 Third Backward jump
         NOP         ; 28
         NOP         ; 29
         NOP         ; 30
         NOP         ; 31
         NOP         ; 32
TST0B_8  JRA TST0B_7 ; 33-34 Second Backward jump
TST0B_9  JRA TST0B_8 ; First Backward jump
TST0B_10 NOP         ; Arrival of the last jump to end the test
;         ; Higher range testing using symbolic address after the mnemonic
         NOP         ; These NOP make relative jump to exercise carry on MSB address boundary
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         JRA TST0B_12
         NOP         ; 1     1     
         NOP
;         NOP
;         NOP
TST0B_11 JRA TST0B_13
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1     2   
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   3
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   4
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   5
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   5
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   6
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         ; 16
         NOP         ; 1   7
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP         
         NOP
         NOP
         NOP
         NOP
         NOP
;         NOP        ; 16
TST0B_12 NOP
         JRA TST0B_11
TST0B_13 NOP         ; final foward jump destination     
         ; --------------------------------------------------------------------
         ; OP.0D SRLA Shift Right Logical on Reg A
         ;            0 -> b7 b6 b5 b4 b3 b2 b1 b0 -> C
         ; --------------------------------------------------------------------
TSTOP0D  LDA #0x0D
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xA5
         SRLA
         CMPA #0x52
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         CMPA #0x29
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         CMPA #0x14
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x0A
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x05
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x02
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x01
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         SRLA
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         ; --------------------------------------------------------------------
         ; OP.0E SLLA Shift Left Logical on Reg A
         ;       SLAA Shift Left Arithmetic on Reg A (SLAA same as SLLA)
         ;            C <- b7 b6 b5 b4 b3 b2 b1 b0 <- 0
         ; --------------------------------------------------------------------
TSTOP0E  LDA #0x0E
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xA5
         SLLA
         CMPA #0x4A
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         CMPA #0x94
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         CMPA #0x28
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         CMPA #0x50
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         SLLA
         CMPA #0xA0
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         SLLA
         SLAA
         CMPA #0x40
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         SLLA
         SLAA
         SLAA
         CMPA #0x80
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         SLLA
         SLAA
         SLAA
         SLAA
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         SLLA
         SLLA
         SLLA
         SLLA
         SLLA
         SLAA
         SLAA
         SLAA
         SLAA
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         ; --------------------------------------------------------------------
         ; OP.0F 
         ; JRNC Jump Relatif if Not Carry
         ; --------------------------------------------------------------------
TSTOP0F  LDA #0x0F
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear carry
         STA CARRY
         JRNC TST0F_0
         JMP FAIL
TST0F_0  LDA #0x01   ; Set carry
         STA CARRY
         JRNC TST0F_1
         JMP TST0F_2
TST0F_1  JMP FAIL
TST0F_2  NOP
         ; --------------------------------------------------------------------
         ; OP.10  RRCA   Rotate Right Logical Reg A through Carry 
         ;               C -> b7 b6 b5 b4 b3 b2 b1 b0 -> C  
         ; --------------------------------------------------------------------
TSTOP10  LDA #0x10
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear Carry
         STA CARRY
         RRCA
         CMPA #0x00
         JNE FAIL
         LDA #0x00   ; Clear Carry
         STA CARRY
         RRCA
         LDA CARRY
         CMPA #0x00
         JNE FAIL
         LDA #0xAA   ; Test shifting
         RRCA
         CMPA #0x55
         JNE FAIL
         LDA #0x01   ; Test transfer of bit <0> to carry
         RRCA
         LDA CARRY
         CMPA #0x01
         JNE FAIL
         LDA #0x00   ; Test A become 0 after shifting when carry is 0
         STA CARRY   ; insure carry is clear
         LDA #0x01   ; set bit <0> to '1'
         RRCA
         CMPA #0x00
         JNE FAIL
         LDA #0x00   ; Test bit <0> goes to bit <7> after 2 RRCA
         STA CARRY   ; insure carry is clear
         LDA #0x01
         RRCA
         RRCA
         CMPA #0x80
         JNE FAIL
         RRCA        ; continue rotating this bit
         CMPA #0x40
         JNE FAIL
         RRCA
         CMPA #0x20
         JNE FAIL
         RRCA
         CMPA #0x10
         JNE FAIL
         RRCA
         CMPA #0x08
         JNE FAIL
         RRCA
         CMPA #0x04
         JNE FAIL
         RRCA
         CMPA #0x02
         JNE FAIL
         RRCA
         CMPA #0x01
         JNE FAIL
         RRCA
         CMPA #0x00
         JNE FAIL
         RRCA
         CMPA #0x80
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.11  RCF   Reset Carry Flag   C <- 0
         ; --------------------------------------------------------------------
TSTOP11  LDA #0x11
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x01   ; Set carry flag to 1
         STA CARRY
         RCF         ; Reset Carry Flag 
         LDA CARRY   ; Check carry is now cleared
         CMPA #0x00
         JNE FAIL
         RCF         ; Do again a Reset Carry Flag 
         LDA CARRY   ; Check carry is still cleared
         CMPA #0x00
         JNE FAIL
         LDA #0xA5   ; Check register A is not affected by a Reset Carry Flag
         RCF         ; Reset Carry Flag
         CMPA #0xA5  ; If A value not same then fail
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.12  SCF   Set Carry Flag   C <- 1
         ; --------------------------------------------------------------------
TSTOP12  LDA #0x12
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear carry flag
         STA CARRY
         SCF         ; Set Carry Flag 
         LDA CARRY   ; Check carry is set
         CMPA #0x01
         JNE FAIL
         SCF         ; Set Carry Flag again
         LDA CARRY   ; Check carry is still set
         CMPA #0x01
         JNE FAIL
         LDA #0xBE   ; Check register A is not affected by a Set Carry Flag
         SCF         ; Set Carry Flag
         CMPA #0xBE  ; If A value not same then fail
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.13  DECXL   Decrement XL   E updated
         ; --------------------------------------------------------------------
TSTOP13  LDA #0x13
         NOTA
         STA LEDPORT ; Output to LED port
         LDX #0xFFFF
         DECXL
         LDA XH
         CMPA #0xFF
         JNE FAIL
         LDA XL
         CMPA #0xFE
         JNE FAIL
         DECXL
         LDA XH
         CMPA #0xFF
         JNE FAIL
         LDA XL
         CMPA #0xFD
         JNE FAIL
         LDX #0xA502
         DECXL
         LDA XH
         CMPA #0xA5
         JNE FAIL
         LDA XL
         CMPA #0x01
         JNE FAIL
         DECXL
         LDA XH
         CMPA #0xA5
         JNE FAIL
         LDA XL
         CMPA #0x00
         JNE FAIL
         DECXL
         LDA XH
         CMPA #0xA5
         JNE FAIL
         LDA XL
         CMPA #0xFF
         JNE FAIL
         DECXL 
         LDA XH
         CMPA #0xA5
         JNE FAIL
         LDA XL
         CMPA #0xFE
         JNE FAIL
         LDX #0x0002 ; Check E status
         DECXL
         LDA EQUAL
         CMPA #0x00
         JNE FAIL
         LDX #0x0001
         DECXL
         LDA EQUAL
         CMPA #0x01
         JNE FAIL
         LDX #0xFFFF
         DECXL
         LDA EQUAL
         CMPA #0x00
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.14  RRC 0x****   Rotate Right Logical Address location through Carry 
         ;                     C -> b7 b6 b5 b4 b3 b2 b1 b0 -> C  
         ; --------------------------------------------------------------------
TSTOP14  LDA #0x14
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear Carry
         STA CARRY
         STA ?b0
         RRC ?b0
         LDA ?b0
         CMPA #0x00
         JNE FAIL
         LDA #0x00   ; Clear Carry
         STA CARRY
         STA ?b0
         RRC ?b0
         LDA CARRY
         CMPA #0x00
         JNE FAIL
         LDA #0xAA   ; Test shifting
         STA ?b0
         RRC ?b0
         LDA ?b0
         CMPA #0x55
         JNE FAIL
         LDA #0x01   ; Test transfer of bit <0> to carry
         STA ?b0
         RRC ?b0
         LDA CARRY
         CMPA #0x01
         JNE FAIL
         LDA #0x00   ; Test A become 0 after shifting when carry is 0
         STA CARRY   ; insure carry is clear
         LDA #0x01   ; set bit <0> to '1'
         STA ?b0
         RRC ?b0
         LDA ?b0
         CMPA #0x00
         JNE FAIL
         LDA #0x00   ; Test bit <0> goes to bit <7> after 2 RRCA
         STA CARRY   ; insure carry is clear
         LDA #0x01
         STA ?b0
         RRC ?b0
         RRC ?b0
         LDA ?b0
         CMPA #0x80
         JNE FAIL
         RRC ?b0     ; continue rotating this bit
         LDA ?b0
         CMPA #0x40
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x20
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x10
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x08
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x04
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x02
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x01
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x00
         JNE FAIL
         RRC ?b0
         LDA ?b0
         CMPA #0x80
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.15 SRL 0x****   Shift Right Logical on Address
         ;                    0 -> b7 b6 b5 b4 b3 b2 b1 b0 -> C
         ; --------------------------------------------------------------------
TSTOP15  LDA #0x15
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xA5
         STA ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x52
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x29
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x14
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x0A
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x05
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x02
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x01
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         LDA #0xA5
         STA ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         SRL ?b0
         LDA ?b0
         CMPA #0x00
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; The Carry Status bit is expected to be '0' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         ; --------------------------------------------------------------------
         ; OP.16 STX 0x****   STORE X REGISTER TO ADDRESS
         ; --------------------------------------------------------------------
TSTOP16  LDA #0x16
         NOTA
         STA LEDPORT ; Output to LED port
         LDX #0x1234 ; Test a STX using immediate Hex address value
         STX 0x0000  
         LDA 0x0000
         CMPA #0x12
         JNE FAIL
         LDA 0x0001
         CMPA #0x34
         JNE FAIL
         LDX #0xCAFE ; Test a STX at address boundary requiring a carry to MSB
         STX 0x10FF  
         LDA 0x10FF
         CMPA #0xCA
         JNE FAIL
         LDA 0x1100
         CMPA #0xFE
         JNE FAIL
         LDX #0xBEEF ; Test a STX on another boundary
         STX 0x12FF  
         LDA 0x12FF
         CMPA #0xBE
         JNE FAIL
         LDA 0x1300
         CMPA #0xEF
         JNE FAIL
         LDX #0x6789 ; Test a STX using symbolic address
         STX ?b1
         LDA ?b1
         CMPA #0x67
         JNE FAIL
         LDA ?b0
         CMPA #0x89
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.17 ORA #0x**   LOGICAL OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
TSTOP17  LDA #0x17
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xFF
         ORA #0xFF
         CMPA #0xFF
         JNE FAIL
         LDA #0x00
         ORA #0x00
         CMPA #0x00
         JNE FAIL
         LDA #0x25
         ORA #0xD3
         CMPA #0xF7
         JNE FAIL
         LDA #0x00
         ORA #0xFF
         CMPA #0xFF
         JNE FAIL
         LDA #0xFF
         ORA #0x00
         CMPA #0xFF
         JNE FAIL
         LDA #0x14
         ORA #0xC1
         CMPA #0xD5
         JNE FAIL
         LDA #0xAA
         ORA #0x55
         CMPA #0xFF
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.18 XORA #0x**  EXCLUSIVE OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
TSTOP18  LDA #0x18
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         XORA #0x00
         CMPA #0x00
         JNE FAIL
         LDA #0x00
         XORA #0xFF
         CMPA #0xFF
         JNE FAIL
         LDA #0xFF
         XORA #0xFF
         CMPA #0x00
         JNE FAIL
         LDA #0xFF
         XORA #0x55
         CMPA #0xAA
         JNE FAIL
         LDA #0xCE
         XORA #0x5A
         CMPA #0x94
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.19 NOTA  LOGIC NOT ON REG A
         ; --------------------------------------------------------------------
TSTOP19  LDA #0x19
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         NOTA
         CMPA #0xFF
         JNE FAIL
         NOTA
         CMPA #0x00
         JNE FAIL
         LDA #0x55
         NOTA
         CMPA #0xAA
         JNE FAIL
         NOTA
         CMPA #0x55
         JNE FAIL
         NOTA
         CMPA #0xAA
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.1A CMPX #0x****   COMPARE X to immediate value
         ; --------------------------------------------------------------------
TSTOP1A  LDA #0x1A
         NOTA
         STA LEDPORT ; Output to LED port
         LDX #0x0000 ; Load 0x0000 in X  (Testing with immediate hex value)
         CMPX #0x0000
         JNE FAIL
         CMPX #0x0001
         JEQ FAIL    ; good up tho here
         CMPX #0xFFFF
         JEQ FAIL
         LDX #0xFF00 ; Load 0xFF00 in X
         CMPX #0xFF00
         JNE FAIL
         CMPX #0x00FF
         JEQ FAIL
         CMPX #0xFFFF
         JEQ FAIL
         LDX #0x00FF ; Load 0x00FF in X
         CMPX #0x00FF
         JNE FAIL
         CMPX #0xFF00
         JEQ FAIL
         CMPX #0xFFFF
         JEQ FAIL
         LDX #0xFFFF ; Load 0xFFFF in X
         CMPX #0xFFFF
         JNE FAIL
         CMPX #0xFF00
         JEQ FAIL
         CMPX #0x00FF
         JEQ FAIL
         LDX #0xABCD
         CMPX #0xA5CD
         JEQ FAIL
         LDX #0x1234
         CMPX #0x12AA
         JEQ FAIL
         LDX #0xAEC3
         CMPX #0xAEC3
         JNE FAIL
         CMPX #0xAEDB
         JEQ FAIL
         CMPX #0x12C3
         JEQ FAIL
         CMPX #0xFFFF
         JEQ FAIL
         ; --------------------------------------------------------------------
         ; OP.1B LDX 0x**  
         ; LDX using a 8-bit direct address (8-bit offset into 0x00–0xFF page)
         ; --------------------------------------------------------------------
TSTOP1B  LDA #0x1B
         NOTA
         STA LEDPORT    ; Output to LED port
         LDA #0x00
         STA 0x0000
         LDA #0x00
         STA 0x0001
         LDX 0x00       ; Load index pointer from this 8 bit address
         LDA 0x1FF3     ; read X MSB
         CMPA #0x00
         JNE FAIL
         LDA 0x1FF4     ; read X LSB
         CMPA #0x00
         JNE FAIL       ;
         LDA #0xAB
         STA 0x0002
         LDA #0xCD
         STA 0x0003
         LDX 0x02       ; Load index pointer from this 8 bit address
         LDA 0x1FF3     ; read X MSB
         CMPA #0xAB
         JNE FAIL
         LDA 0x1FF4     ; read X LSB
         CMPA #0xCD
         JNE FAIL       ;      
         LDA #0xCA
         STA 0x0048
         LDA #0xFE
         STA 0x0049
         LDX 0x48       ; Load index pointer from this 8 bit address
         LDA 0x1FF3     ; read X MSB
         CMPA #0xCA
         JNE FAIL
         LDA 0x1FF4     ; read X LSB
         CMPA #0xFE
         JNE FAIL
         LDA #0x12      ; Test using symbolic adress
         STA 0x000E     ; ?b1
         LDA #0x34
         STA 0x000F     ; ?b0
         LDX ?b1        ; Load index pointer using symbolic LSB 8 bit address
         LDA 0x1FF3     ; read X MSB
         CMPA #0x12
         JNE FAIL
         LDA 0x1FF4     ; read X LSB
         CMPA #0x34
         JNE FAIL
         LDA #0x56      ; Test using symbolic adress
         STA 0x0009     ; ?b6
         LDA #0x78
         STA 0x000A     ; ?b7
         LDX ?b6        ; Load index pointer using symbolic LSB 8 bit address
         LDA 0x1FF3     ; read X MSB
         CMPA #0x56
         JNE FAIL
         LDA 0x1FF4     ; read X LSB
         CMPA #0x78
         JNE FAIL
         ; Test symbolic +- offset
         
         ; --------------------------------------------------------------------
         ; OP.1C LDA (****H,X)
         ; LDA indexed indirect addressing
         ; --------------------------------------------------------------------
TSTOP1C  LDA #0x1C
         NOTA
         STA LEDPORT    ; Output to LED port
         ;Store a few bytes in RAM to be read using indexed indirect addressing
         ;test with base address not requiring a carry to MSB
         ;by incrementing X from 0x0000 upwards
         LDA #0x55
         STA 0x0000
         LDA #0xAA
         STA 0x0001
         LDA #0xBE
         STA 0x0002
         LDX #0x0000
         LDA (0x0000,X)
         CMPA #0x55
         JNE FAIL
         INCX
         LDA (0x0000,X)
         CMPA #0xAA
         JNE FAIL
         INCX
         LDA (0x0000,X) 
         CMPA #0xBE
         JNE FAIL
         ; Now test with a base address requiring a carry to MSB
         ; by initializing X to 0x00FF and incrementing
         ; storing data at 0x10FE onwards
         LDA #0x12
         STA 0x10FE
         LDA #0x34
         STA 0x10FF
         LDA #0x56
         STA 0x1100
         LDA #0x78
         STA 0x1101
         LDX #0x0000 ; Point to LSB of base address   
         LDA (0x10FE,X)
         CMPA #0x12
         JNE FAIL
         INCX
         LDA (0x10FE,X)
         CMPA #0x34
         JNE FAIL
         INCX
         LDA (0x10FE,X)
         CMPA #0x56
         JNE FAIL
         INCX
         LDA (0x10FE,X)
         CMPA #0x78
         JNE FAIL 
         ; Finally test using a fixed indexed register with variable offset
         ; storing data at 0x1234 onwards
         LDA #0x12
         STA 0x1234
         LDA #0x34
         STA 0x1235
         LDA #0x56
         STA 0x1236
         LDA #0x78
         STA 0x1237
         LDX #0x1234 ; Point to base address
         LDA (0x0000,X)
         CMPA #0x12
         JNE FAIL
         LDA (0x0001,X)
         CMPA #0x34
         JNE FAIL
         LDA (0x0002,X)
         CMPA #0x56
         JNE FAIL
         LDA (0x0003,X)
         CMPA #0x78
         JNE FAIL
         ; Test using a fixed index register with carry to MSB
         LDA #0x9A
         STA 0x12FE
         LDA #0xBC   
         STA 0x12FF
         LDA #0xDE
         STA 0x1300
         LDA #0xF0
         STA 0x1301
         LDX #0x01FE ; Point to base address
         LDA (0x1100,X)
         CMPA #0x9A
         JNE FAIL
         LDA (0x1101,X)
         CMPA #0xBC
         JNE FAIL
         LDA (0x1102,X)
         CMPA #0xDE
         JNE FAIL
         LDA (0x1103,X)
         CMPA #0xF0
         JNE FAIL
         ; Test using symbolic with fixed index register to 0
         LDA #0xDE
         STA 0x0000
         LDA #0xAD
         STA 0x0001
         LDA #0xBE
         STA 0x0002
         LDA #0xEF
         STA 0x0003
         LDX #0x0000 ; Clear index
         LDA (?b15,X)
         CMPA #0xDE
         JNE FAIL
         LDA (?b14,X)
         CMPA #0xAD
         JNE FAIL
         LDA (?b13,X)
         CMPA #0xBE
         JNE FAIL
         LDA (?b12,X)
         CMPA #0xEF
         JNE FAIL
         ; Test using symbolic and incrementing index
         LDA #0xCA   ; ?b7      EQU 0x0008
         STA 0x0008
         LDA #0xFE
         STA 0x0009
         LDA #0x55
         STA 0x000A
         LDA #0xAA
         STA 0x000B
         LDX #0x0000 ; Clear index
         LDA (?b7,X)
         CMPA #0xCA
         JNE FAIL
         INCX
         LDA (?b7,X)
         CMPA #0xFE
         JNE FAIL
         INCX
         LDA (?b7,X)
         CMPA #0x55
         JNE FAIL
         INCX
         LDA (?b7,X)
         CMPA #0xAA
         JNE FAIL              
         ; Test using symbolic and incrementing index with a carry
         LDA #0x12   ; ?b0      EQU 0x000F
         STA 0x16FE
         LDA #0x34
         STA 0x16FF
         LDA #0x56
         STA 0x1700
         LDA #0x78
         STA 0x1701
         LDX #0x16EF ; Set base index
         LDA (?b0,X)
         CMPA #0x12
         JNE FAIL              
         INCX
         LDA (?b0,X)
         CMPA #0x34
         JNE FAIL              
         INCX        ; carry on MSB
         LDA (?b0,X)
         CMPA #0x56
         JNE FAIL              
         INCX
         LDA (?b0,X)
         CMPA #0x78
         JNE FAIL              
         ; --------------------------------------------------------------------
         ; OP.1D STA (****H,X)
         ; STA indexed indirect addressing
         ; --------------------------------------------------------------------
TSTOP1D  LDA #0x1D
         NOTA
         STA LEDPORT    ; Output to LED port
         ;Store a few bytes in RAM using indexed indirect addressing
         ;test with base address not requiring a carry to MSB
         ;by incrementing X from 0x0000 upwards
         LDA #0x55      ; store data at 0x0000 onwards
         LDX #0x0000
         STA (0x0000,X)
         LDA #0xAA
         INCX
         STA (0x0000,X)
         LDA #0xBE
         INCX
         STA (0x0000,X)
         LDX #0x0000    ; Now read back the stored data
         LDA (X)
         CMPA #0x55
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0xAA
         JNE FAIL 
         INCX
         LDA (X) 
         CMPA #0xBE
         JNE FAIL
         ; Now test with a base address requiring a carry to MSB
         ; by initializing X to 0x10FE and incrementing storing data
         LDA #0x12
         LDX #0x10FE
         STA (0x0000,X)
         LDA #0x34
         INCX
         STA (0x0000,X)
         LDA #0x56
         INCX
         STA (0x0000,X)
         LDA #0x78
         INCX
         STA (0x0000,X)
         LDX #0x10FE ; Initialize X to base address
         LDA (X)
         CMPA #0x12
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0x34
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0x56
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0x78
         JNE FAIL
         ; Test using a fixed indexed register with variable offset
         ; storing data at 0x1234 onwards
         LDA #0x12
         LDX #0x1234
         STA (0x0000,X)
         LDA #0x34
         STA (0x0001,X)
         LDA #0x56
         STA (0x0002,X)
         LDA #0x78
         STA (0x0003,X)
         LDX #0x1234 ; Point to base address
         LDA (X)
         CMPA #0x12
         JNE FAIL
         LDA (0x0001,X)
         CMPA #0x34
         JNE FAIL
         LDA (0x0002,X)
         CMPA #0x56
         JNE FAIL
         LDA (0x0003,X)
         CMPA #0x78
         JNE FAIL
         ; Test using a fixed index register with carry to MSB
         LDA #0x9A
         LDX #0x14FE
         STA (0x0000,X)
         LDA #0xBC
         STA (0x0001,X)
         LDA #0xDE
         STA (0x0002,X)
         LDA #0xF0
         STA (0x0003,X)
         LDX #0x14FE ; Point to base address
         LDA (X)
         CMPA #0x9A
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0xBC
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0xDE
         JNE FAIL
         INCX
         LDA (X)
         CMPA #0xF0
         JNE FAIL
         ; Test with carry to MSB on index and base address
         LDA #0x45
         LDX #0x02FE
         STA (0x1100,X)
         LDA #0x67
         STA (0x1101,X)
         LDA #0x89
         STA (0x1102,X)
         LDA #0xAB
         STA (0x1103,X)
         LDX #0x01FE ; Point to base address
         LDA (0x1200,X)
         CMPA #0x45
         JNE FAIL
         INCX
         LDA (0x1200,X)
         CMPA #0x67
         JNE FAIL
         INCX
         LDA (0x1200,X)
         CMPA #0x89
         JNE FAIL
         INCX
         LDA (0x1200,X)
         CMPA #0xAB
         JNE FAIL
         ; test using symbolic with fixed index register to 0
         LDX #0x0000 ; Clear index
         LDA #0xDE
         STA (?b10,X)
         LDA #0xAD
         STA (?b9,X)
         LDA #0xBE
         STA (?b8,X)   
         LDA #0xEF
         STA (?b7,X)
         LDA 0x0005
         CMPA #0xDE
         JNE FAIL
         LDA 0x0006
         CMPA #0xAD
         JNE FAIL
         LDA 0x0007
         CMPA #0xBE
         JNE FAIL
         LDA 0x0008
         CMPA #0xEF
         JNE FAIL
         ; test using symbolic and incrementing index
         LDX #0x0000 ; Clear index
         LDA #0xCA   
         STA (?b0,X) ; ?b0      EQU 0x000F
         INCX
         LDA #0xFE
         STA (?b0,X)
         INCX 
         LDA #0x55
         STA (?b0,X)
         INCX
         LDA #0xAA
         STA (?b0,X)
         LDA 0x000F
         CMPA #0xCA
         JNE FAIL
         LDA 0x0010
         CMPA #0xFE
         JNE FAIL
         LDA 0x0011
         CMPA #0x55
         JNE FAIL
         LDA 0x0012
         CMPA #0xAA
         JNE FAIL         
         ; Test using symbolic and incrementing index with a carry
         LDX #0x14EF ; Set base index
         LDA #0x12
         STA (?b0,X) ; 0x14FE
         INCX
         LDA #0x34
         STA (?b0,X) ; 0x14FF
         INCX
         LDA #0x56
         STA (?b0,X) ; 0x1500
         INCX
         LDA #0x78
         STA (?b0,X) ; 0x1501
         LDA 0x14FE
         CMPA #0x12
         JNE FAIL
         LDA 0x14FF
         CMPA #0x34
         JNE FAIL
         LDA 0x1500
         CMPA #0x56
         JNE FAIL
         LDA 0x1501
         CMPA #0x78
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.1E CLRX
         ; CLEAR X REGISTER
         ; --------------------------------------------------------------------
TSTOP1E  LDA #0x1E
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear E equal flag
         STA 0x1FFA
         LDX #0xFFFF ; Load X with non zero value
         CLRX
         LDA 0x1FF3  ; Read X MSB
         CMPA #0x00
         JNE FAIL
         LDA 0x1FF4  ; Read X LSB
         CMPA #0x00
         JNE FAIL
         LDA 0x1FFA  ; Read E flag and check it is set
         CMPA #0x01
         JNE FAIL
         LDA #0x01   ; Set E equal flag
         STA 0x1FFA
         LDX #0x1234 ; Load X with non zero value
         CLRX
         LDA 0x1FF3  ; Read X MSB
         CMPA #0x00
         JNE FAIL
         LDA 0x1FF4  ; Read X LSB
         CMPA #0x00
         JNE FAIL
         LDA 0x1FFA  ; Read E flag and check it is set
         CMPA #0x01  
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.29 ADDA 0x****  
         ; ADD A WITH BYTE AT ADDRESS, C UPDATE
         ; --------------------------------------------------------------------
TSTOP29  LDA #0x29
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x5F   ; Store a value in RAM
         STA 0x0123   
         LDA #0x63
         ADDA 0x0123 ; Add to A the byte at address location
         CMPA #0xC2  ; Check the sum
         JNE FAIL    ; Jump if result not good
         LDA CARRY   ; Read the Carry Status
         CMPA #0x00  ; No carry expected then C should be '0'
         JNE FAIL    ; Error if carry is set

         LDA #0xAC   ; Store another value in RAM
         STA 0x1056   
         LDA #0xD9
         ADDA 0x1056 ; Add to A the byte at address location
         CMPA #0x85  ; Check the sum LSB
         JNE FAIL    ; Jump if result not as expected
         LDA CARRY   ; Read the Carry Status
         CMPA #0x01  ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE FAIL    ; Error if different
         ; --------------------------------------------------------------------
         ; OP.2A LDA 0x****  
         ; LOAD A WITH BYTE AT ADDRESS (Direct Addressing)
         ; --------------------------------------------------------------------
TSTOP2A  LDA #0x2A
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xAA   ; Load immediate in register A
         CMPA #0xAA
         JNE FAIL
         LDA #0x01
         CMPA #0x01
         JNE FAIL
         LDA #0x02
         CMPA #0x02
         JNE FAIL
         LDA #0x04
         CMPA #0x04
         JNE FAIL
         LDA #0x08
         CMPA #0x08
         JNE FAIL
         LDA #0x10
         CMPA #0x10
         JNE FAIL
         LDA #0x20
         CMPA #0x20
         JNE FAIL
         LDA #0x40
         CMPA #0x40
         JNE FAIL
         LDA #0x80
         CMPA #0x80
         JNE FAIL
         LDA #0x55
         CMPA #0x55
         JNE FAIL
         LDA #0xFF
         CMPA #0xFF
         JNE FAIL
         ; Now test symbolic with positive offset
         LDA MSGTXT1
         CMPA #0x31     ; '1'
         JNE FAIL
         LDA MSGTXT1+1
         CMPA #0x32     ; '2'
         JNE FAIL
         LDA MSGTXT1+2
         CMPA #0x33     ; '3'
         JNE FAIL
         LDA MSGTXT1+3
         CMPA #0x41     ; 'A'
         JNE FAIL
         LDA MSGTXT1+4
         CMPA #0x42     ; 'B'
         JNE FAIL
         LDA MSGTXT1+5
         CMPA #0x43     ; 'C'
         JNE FAIL
         LDA MSGTXT1+6
         CMPA #0x00     ; null terminator
         JNE FAIL
         LDA MSGTXT1+10
         CMPA #0x6C
         JNE FAIL
         LDA MSGTXT1+11
         CMPA #0x6F
         JNE FAIL
         ; Now test symbolic with negative offset
         LDA MSGTXT3
         CMPA #0x54     ; 'T'
         JNE FAIL
         LDA MSGTXT3-1
         CMPA #0x00     ; null terminator
         JNE FAIL
         LDA MSGTXT3-2
         CMPA #0x64     ; 'd'
         JNE FAIL
         LDA MSGTXT3-3
         CMPA #0x72     ; 'l'
         JNE FAIL
         LDA MSGTXT3-10
         CMPA #0x65
         JNE FAIL
         LDA MSGTXT3-11
         CMPA #0x48
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.2B JNE 0x****  
         ; JUMP IF E=0
         ; Only a partial validation because i do not have symbolic address
         ; processing in the assembler program.
         ; --------------------------------------------------------------------
TSTOP2B  LDA #0x2B
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x6D   ; Load a value in A
         CMPA #0x6D  ; Compare with the same value
         JNE FAIL    ; Error if values are different
         LDA #0x10
         CMPA #0x10
         JNE FAIL
         LDA #0x01
         CMPA #0x01
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.2C JEQ 0x****
         ; JUMP IF E=1
         ; --------------------------------------------------------------------
TST2C    LDA #0x2C
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x7A   ; Load a value in A
         CMPA #0x28  ; Compare with a different value
         JEQ FAIL    ; If appear identical then it's and error
         LDA #0xFE   ; Again with adifference 
         CMPA #0xFF
         JEQ FAIL 
         LDA #0x01   ; Another with difference
         CMPA #0x10
         JEQ FAIL
         LDA #0xAB   ; Now compare when values are identical
         CMPA #0xAB
         JEQ TST2C_1 ; Testing if equal?
         JMP FAIL    ; Result say both are not equal then it's a failure
TST2C_1  LDA #0x00   ; Result say the values are identical so we are passing
         CMPA #0x00
         JEQ TST2C_2 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_2  LDA #0x01
         CMPA #0x01
         JEQ TST2C_3 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_3  LDA #0x02
         CMPA #0x02
         JEQ TST2C_4 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_4  LDA #0x04
         CMPA #0x04
         JEQ TST2C_5 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_5  LDA #0x08
         CMPA #0x08
         JEQ TST2C_6 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_6  LDA #0x10
         CMPA #0x10
         JEQ TST2C_7 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure
TST2C_7  LDA #0x20
         CMPA #0x20
         JEQ TST2C_8 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure         
TST2C_8  LDA #0x40
         CMPA #0x40
         JEQ TST2C_9 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure         
TST2C_9  LDA #0x80
         CMPA #0x80
         JEQ TST2C_10 ; Testing if equal?
         JMP FAIL    ; if different then it's a failure         
TST2C_10 NOP
         ; --------------------------------------------------------------------
         ; OP.2D CMPA #0x**
         ; COMPARE A WITH IMMEDIATE VALUE    EQUAL STATUS BIT (E) UPDATED
         ; --------------------------------------------------------------------
TSTOP2D  LDA #0x2D
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x12   ; Load a value in A
         CMPA #0x12  ; Compare with identical value
         LDA EQUAL   ; Inspect EQUAL STATUS 
         CMPA #0x01  ; Verify bit<0> E = '1' and all others bits <7:1> are '0'    
         JNE FAIL    ; If different then it's and error
         LDA #0xAA
         CMPA #0x55  ; Compare with a different value
         LDA EQUAL   ; Inspect EQUAL STATUS
         CMPA #0x00  ; Verify bit<0> E = '0' and all others bits <7:1> are '0'    
         JNE FAIL    ; If different then it's and error
         ; --------------------------------------------------------------------
         ; OP.2E ADCA #0x**
         ; REG A = REG A + IMMEDIATE BYTE + CARRY (C)   
         ; CARRY STATUS (C) IS UPDATED
         ; --------------------------------------------------------------------
TSTOP2E  LDA #0x2E
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00   ; Clear CARRY (C)
         STA CARRY      
         LDA #0x45
         ADCA #0x5B
         CMPA #0xA0  ; Verify summ
         JNE FAIL
         LDA CARRY   ; Check carry
         CMPA #0x00  ; Should be clear
         JNE FAIL
         
         LDA #0x01   ; Set CARRY (C)
         STA CARRY
         LDA #0x56
         ADCA #0x6D
         CMPA #0xC4   ; Verify summ
         JNE FAIL
         LDA CARRY   ; Check carry
         CMPA #0x00  ; Should be clear
         JNE FAIL
         
         LDA #0x00   ; Clear CARRY (C)
         STA CARRY
         LDA #0x7F
         ADCA #0xDE
         CMPA #0x5D  ; Verify summ
         JNE FAIL
         LDA CARRY   ; Check carry
         CMPA #0x01  ; Should be set
         JNE FAIL
         
         LDA #0x01   ; Set CARRY (C)
         STA CARRY
         LDA #0xFF
         ADCA #0xFF
         CMPA #0xFF  ; Verify summ
         JNE FAIL
         LDA CARRY   ; Check carry
         CMPA #0x01  ; Should be set
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.2F ADDA #0x**
         ; ACCA+M>ACCA     C UPDATED
         ; --------------------------------------------------------------------
TSTOP2F  LDA #0x2F
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x23
         ADDA #0x45
         CMPA #0x68
         JNE FAIL
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x00  ; Expecting C=0
         JNE FAIL
         LDA #0x8A
         ADDA #0xBD
         CMPA #0x47   
         JNE FAIL
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x01  ; Expecting C=1
         JNE FAIL
         LDA #0x01
         ADDA #0x02
         CMPA #0x03
         JNE FAIL
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x00  ; Expecting C=0
         JNE FAIL
         LDA #0xFF
         ADDA #0xFF
         CMPA #0xFE
         JNE FAIL
         LDA CARRY   ; Read Carry bit <0>
         CMPA #0x01   ; Expecting C=1
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.30 LDA #0x**  
         ; LOAD IMMEDIATE VALUE IN REGISTER A
         ; --------------------------------------------------------------------
TSTOP30  LDA #0x30
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x00
         CMPA #0x00
         JNE FAIL
         LDA #0x01
         CMPA #0x01
         JNE FAIL
         LDA #0x02
         CMPA #0x02
         JNE FAIL
         LDA #0x04
         CMPA #0x04
         JNE FAIL
         LDA #0x08
         CMPA #0x08
         JNE FAIL
         LDA #0x10
         CMPA #0x10
         JNE FAIL
         LDA #0x20
         CMPA #0x20
         JNE FAIL
         LDA #0x40
         CMPA #0x40
         JNE FAIL
         LDA #0x80
         CMPA #0x80
         JNE FAIL
         LDA #0x55
         CMPA #0x55
         JNE FAIL
         LDA #0xAA
         CMPA #0xAA
         JNE FAIL
         LDA #0xFF
         CMPA #0xFF
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.31 STA 0x**** 
         ; STORE REG.A TO ADDRESSE
         ; --------------------------------------------------------------------
TSTOP31  LDA #0x31
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x12   ; Write to RAM
         STA 0x0000
         LDA #0x23
         STA 0x0001
         LDA #0x34
         STA 0x0002
         LDA #0x45
         STA 0x0004
         LDA #0x56
         STA 0x0008
         LDA #0x67
         STA 0x0010
         LDA #0x78
         STA 0x0020
         LDA #0x89
         STA 0x0040
         LDA #0xAB
         STA 0x0080
         LDA #0xBC
         STA 0x0100
         LDA #0xCD
         STA 0x0200
         LDA #0xDE
         STA 0x0400
         LDA #0x22
         STA 0x0800
         LDA #0x33
         STA 0x1000
         LDA #0x44
         STA 0x1700
         LDA 0x0000  ; Read from RAM and compare
         CMPA #0x12
         JNE FAIL
         LDA 0x0001
         CMPA #0x23
         JNE FAIL
         LDA 0x0002
         CMPA #0x34
         JNE FAIL
         LDA 0x0004
         CMPA #0x45
         JNE FAIL
         LDA 0x0008
         CMPA #0x56
         JNE FAIL
         LDA 0x0010
         CMPA #0x67
         JNE FAIL
         LDA 0x0020
         CMPA #0x78
         JNE FAIL
         LDA 0x0040
         CMPA #0x89
         JNE FAIL
         LDA 0x0080
         CMPA #0xAB
         JNE FAIL
         LDA 0x0100
         CMPA #0xBC
         JNE FAIL
         LDA 0x0200
         CMPA #0xCD
         JNE FAIL
         LDA 0x0400
         CMPA #0xDE
         JNE FAIL
         LDA 0x0800
         CMPA #0x22
         JNE FAIL
         LDA 0x1000
         CMPA #0x33
         JNE FAIL
         LDA 0x1700
         CMPA #0x44
         JNE FAIL
         ; --------------------------------------------------------------------
         ; OP.32 JMP 0x**** 
         ; JUMP INCONDITIONAL TO ADDRESS
         ; --------------------------------------------------------------------
         ;LDA #0x32
         ;NOTA
         ;STA LEDPORT ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.33 ANDA #0x**  REGISTER A AND LOGICAL IMMEDIATE BYTE
         ; --------------------------------------------------------------------
TSTOP33  LDA #0x33
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xFF
         ANDA #0x52
         CMPA #0x52
         JNE FAIL
         LDA #0xE7
         ANDA #0x3C
         CMPA #0x24
         JNE FAIL
         LDA #0x00
         ANDA #0x00
         CMPA #0x00
         JNE FAIL
         LDA #0xFF
         ANDA #0xFF
         CMPA #0xFF
         JNE FAIL
         LDA #0xFF
         ANDA #0x55
         CMPA #0x55
         JNE FAIL
         LDA #0xFF
         ANDA #0x00
         CMPA #0x00
         JNE FAIL

         ; --------------------------------------------------------------------
         ; FIBONACCI TEST
         ; first method using direct addressing
         ; --------------------------------------------------------------------         
TSTFB1   LDA #0x40
         NOTA
         STA LEDPORT ; Output to LED port
                     ;
         LDA #0x00   ; Init first number with 00H
         STA 0x1000
         LDA #0x01   ; Init second number with 01H
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x01  ; HEX   Decimal  Real Value (in 8 bit storage only)
         JNE FAIL    ; x01   1        1
         
         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x02  ; HEX   Decimal  Real Value
         JNE FAIL    ; x02   2        2
         
         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002   ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x03  ; HEX   Decimal  Real Value
         JNE FAIL    ; x03   3        3
         
         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x05  ; HEX   Decimal  Real Value
         JNE FAIL    ; x05   5        5
         
         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x08  ; HEX   Decimal  Real Value
         JNE FAIL    ; x08   8        8

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x0D  ; HEX   Decimal  Real Value
         JNE FAIL    ; x0D   13       13

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x15  ; HEX   Decimal  Real Value
         JNE FAIL    ; x15   21       21

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x22  ; HEX   Decimal  Real Value
         JNE FAIL    ; x22   34       34

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x37  ; HEX   Decimal  Real Value
         JNE FAIL    ; x37   55       55

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x59  ; HEX   Decimal  Real Value
         JNE FAIL    ; x59   89       89

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x90  ; HEX   Decimal  Real Value
         JNE FAIL    ; x90   144      144

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0xE9  ; HEX   Decimal  Real Value
         JNE FAIL    ; xE9   233      233

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x79  ; HEX   Decimal  Real Value
         JNE FAIL    ; x79   121      377 - (256*1) = 121

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0x62  ; HEX   Decimal  Real Value
         JNE FAIL    ; x62   98       610 - (256*2) = 98

         LDA 0x1001  ; Move second number to the first number
         STA 0x1000
         LDA 0x1002  ; Move summ to the second number
         STA 0x1001
         LDA 0x1000  ; Load first number in A
         ADDA 0x1001 ; Add second number to A
         STA 0x1002  ; Store the summ
         CMPA #0xDB  ; HEX   Decimal  Real Value
         JNE FAIL    ; xDB   219      987 - (256*3) = 219         
         ; --------------------------------------------------------------------      
         ; END OF FIBONACCI TEST (method using direct addressing)
         ; --------------------------------------------------------------------          
         
         ; ---------
         ; Loop test
         ; ---------
LOOPTST  LDA #0x41
         NOTA
         STA LEDPORT    ; Output to LED port
         LDA #0x05      ; Init a counter of iterations
         STA ?b0
LOOPTST1 LDA ?b0        ; Read counter
         CMPA #0x00     ; Is it 0?
         JEQ LOOPTST2   ; Yes then it's the end fo the test
         ADDA #0xFF     ; Add -1 in complement 2 (equivalent to decrement)
         STA ?b0        ; Save decremented count
         JRA LOOPTST1
LOOPTST2 NOP            ; End of decrement loop         

         ; -----------------
         ; Math Library Test
         ; -----------------
         ; Test add16_w0_w0_w1  w0 <= w0 + w1
         LDA #0x42
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xBE   ; w0 = 0xBEEF
         STA ?b1
         LDA #0xEF
         STA ?b0
         LDA #0xDE   ; w1 = 0xDEAD
         STA ?b3
         LDA #0xAD
         STA ?b2
         JSR ?add16_w0_w0_w1  ; w0 <= w0 + w1
         LDA ?b1              ; Expected w0 = 9D9C + C set
         CMPA #0x9D
         JNE FAIL
         LDA ?b0
         CMPA #0x9C
         JNE FAIL
         LDA CARRY
         CMPA #0x01
         JNE FAIL

         ; Test add32_l0_l0_l1  l0 <= l0 + l1
         LDA #0x43
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x89   ; l0 = 0x89ABCDEF
         STA ?b3
         LDA #0xAB
         STA ?b2
         LDA #0xCD
         STA ?b1
         LDA #0xEF
         STA ?b0
         LDA #0xDE   ; l1 = DEADBEEF
         STA ?b7
         LDA #0xAD
         STA ?b6
         LDA #0xBE
         STA ?b5
         LDA #0xEF
         STA ?b4
         JSR ?add32_l0_l0_l1  ; l0 <= l0 + l1
         LDA ?b3              ; Expected l0 = 0x68598CDE + C set
         CMPA #0x68
         JNE FAIL
         LDA ?b2
         CMPA #0x59
         JNE FAIL
         LDA ?b1
         CMPA #0x8C
         JNE FAIL
         LDA ?b0
         CMPA #0xDE
         JNE FAIL
         LDA CARRY
         CMPA #0x01
         JNE FAIL

         ; Test ?inc32_l0_l0   l0 <= l0 + 1
         LDA #0x44
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0xFF   ; l0 = 0xFFFFFFFF
         STA ?b3
         LDA #0xFF
         STA ?b2
         LDA #0xFF
         STA ?b1
         LDA #0xFF
         STA ?b0
         JSR ?inc32_l0_l0  ; l0 <= l0 + 1
         ; Expected l0 = 0x00000000
         LDA ?b3     ; Expected l0 = 0x00000000
         CMPA #0x00
         JNE FAIL
         LDA ?b2
         CMPA #0x00
         JNE FAIL
         LDA ?b1
         CMPA #0x00
         JNE FAIL
         LDA ?b0
         CMPA #0x00
         JNE FAIL
         JSR ?inc32_l0_l0  ; l0 <= l0 + 1
         LDA ?b3
         CMPA #0x00
         JNE FAIL
         LDA ?b2
         CMPA #0x00
         JNE FAIL
         LDA ?b1
         CMPA #0x00
         JNE FAIL
         LDA ?b0
         CMPA #0x01
         JNE FAIL
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         JSR ?inc32_l0_l0
         LDA ?b3
         CMPA #0x00
         JNE FAIL
         LDA ?b2
         CMPA #0x00
         JNE FAIL
         LDA ?b1
         CMPA #0x00
         JNE FAIL
         LDA ?b0
         CMPA #0x12
         JNE FAIL

         ; Test  MUL 8-bit
         ; mul8_w1_b1_b0   w1 (b3,b2) <= b1 * b0
         LDA #0x45
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x02   ; 3 * 2 = 6
         STA ?b0
         LDA #0x03
         STA ?b1
         JSR ?mul8_w1_b1_b0
         LDA ?b3
         CMPA #0x00
         JNE FAIL
         LDA ?b2
         CMPA #0x06
         JNE FAIL

         LDA #0xFF   ; 255 * 255 = 65025 (0xFF * 0xFF = 0xFE01)
         STA ?b0
         STA ?b1
         JSR ?mul8_w1_b1_b0
         LDA ?b3
         CMPA #0xFE
         JNE FAIL
         LDA ?b2
         CMPA #0x01
         JNE FAIL

         LDA #0xAB   ; 171 * 205 = 35055 (0xAB * 0xCD = 0x88EF)
         STA ?b0
         LDA #0xCD
         STA ?b1
         JSR ?mul8_w1_b1_b0
         LDA ?b3
         CMPA #0x88
         JNE FAIL
         LDA ?b2
         CMPA #0xEF
         JNE FAIL

         LDA #0x00   ; 0 * 0 = 0 (0x00 * 0x00 = 0x0000)
         STA ?b0
         STA ?b1
         JSR ?mul8_w1_b1_b0
         LDA ?b3
         CMPA #0x00
         JNE FAIL
         LDA ?b2
         CMPA #0x00
         JNE FAIL

         ; Test  MUL 16-bit
         ; Total time for 3 multiplications 140ms @ 2 MHz
         ; 46ms per 16bit mult (21.7 multiplications per second)
         ; l1 <= w1 * w0      (b7,b6,b5,b4) = (b3,b2) * (b1,b0)
         LDA #0x46
         NOTA
         STA LEDPORT ; Output to LED port

         LDA #0x00   ; 0 * 0 = 0 (0x0000 * 0x0000 = 0x00000000)
         STA ?b0
         STA ?b1
         STA ?b2
         STA ?b3
         JSR ?mul16_l1_w1_w0
         LDA ?b7
         CMPA #0x00
         JNE FAIL
         LDA ?b6
         CMPA #0x00
         JNE FAIL
         LDA ?b5
         CMPA #0x00
         JNE FAIL
         LDA ?b4
         CMPA #0x00
         JNE FAIL

         LDA #0xFF   ; 65535 * 65535 = 4294836225  (0xFFFF * 0xFFFF = 0xFFFE0001)
         STA ?b0
         STA ?b1
         STA ?b2
         STA ?b3
         JSR ?mul16_l1_w1_w0
         LDA ?b7
         CMPA #0xFF
         JNE FAIL
         LDA ?b6
         CMPA #0xFE
         JNE FAIL
         LDA ?b5
         CMPA #0x00
         JNE FAIL
         LDA ?b4
         CMPA #0x01
         JNE FAIL

         LDA #0x31   ; 12345 * 54321 = 670592745  (0x3039 * 0xD431 = 0x27F86EE9)
         STA ?b0
         LDA #0xD4
         STA ?b1
         LDA #0x39
         STA ?b2
         LDA #0x30
         STA ?b3
         JSR ?mul16_l1_w1_w0   
         LDA ?b7
         CMPA #0x27
         JNE FAIL
         LDA ?b6
         CMPA #0xF8
         JNE FAIL
         LDA ?b5
         CMPA #0x6E
         JNE FAIL
         LDA ?b4
         CMPA #0xE9
         JNE FAIL  
         
         ; ---------------------
         ; END Math Library Test
         ; ---------------------

               ; TEST EXECUTION FROM RAM
               ; Copy a block of code from EEPROM to RAM
               ; then call to execute this block in RAM. Resume execution from EEPROM
               LDA #0x47
               NOTA
               STA LEDPORT ; Output to LED port
               JMP BLKCODEEND   ; We skip the nex block of code to be copied in RAM
               ; Simple 8 bit multiplication test code
BLKCODESTART   LDA #0x56   ; 86 * 171 = 14706   (0x56 * 0xAB = 0x3972)
               STA ?b0
               LDA #0xAB
               STA ?b1
               JSR ?mul8_w1_b1_b0
               LDA ?b3
               CMPA #0x39
               JNE FAIL
               LDA ?b2
               CMPA #0x72
               JNE FAIL
               RTS
               ; Copy the Block of code from EEPROM to RAM
BLKCODEEND     LDX #BLKCODESTART ; Load address of BLKCODESTART
               STX ?b1           ; Store this adddress in ?b1:?b0
RAMDESTSTART   EQU 0x1000
               LDX #RAMDESTSTART ; Load address of RAM destination
               STX ?b3           ; Store this adddress in ?b3:?b2
               ; copy a byte from source to destination
LOOPTST47      LDX ?b1           ; Load X with source address in ?b1:?b0
               CMPX #BLKCODEEND  ; Check if last byte copied
               JEQ ENDCOPYTST47  ; if yes then quit copy loop
               LDA (X)           ; Load byte pointed by X
               INCX
               STX ?b1
               LDX ?b3           ; Load X with destination address in ?b3:?b2
               STA (X)           ; Store byte to address pointed by X
               INCX
               STX ?b3
               JRA LOOPTST47
ENDCOPYTST47   JSR RAMDESTSTART ; Jump to ram for code execution

            ; ---------------------------------------
            ; 32-bit Fibonacci using library routines
            ; l2 = F(n), l1 = F(n-1), l0 = F(n-2)
            ; ---------------------------------------
            LDA #0x48
            NOTA
            STA LEDPORT
LOOPCNT     EQU 0x0100           ; Loop counter storage
FIBNUMB     EQU 0x1000           ; Output buffer for Fibonacci numbers
            ; Initialize Fibonacci state
            JSR ?clear32_l0      ; F(0) = 0
            JSR ?set32_l1_to_1   ; F(1) = 1
            JSR ?clear32_l2
            ; Output buffer
            LDX #FIBNUMB
            JSR ?store32_l0      ; F(0)
            JSR ?store32_l1      ; F(1)
            ; Loop counter
            ; F(47)=2,971,215,073  fit in 32 bits
            ; F(48)=4,807,526,976  exceed 32 bits
            LDA #0x2D   ; 47 - 2 = 45  iterations (0x2D)
            STA LOOPCNT
FIB32_LOOP  JSR ?add32_l2_l1_l0  ; l2 = l1 + l0
            JSR ?store32_l2      ; store F(n)
            ; rotate registers
            JSR ?mov32_l0_l1     ; l0 = l1
            JSR ?mov32_l1_l2     ; l1 = l2
            ;  DEC LOOPCNT ; I dont have a decrament register A instruction for now
            LDA LOOPCNT
            ADDA #0xFF
            STA LOOPCNT
            CMPA #0x00
            JNE FIB32_LOOP
            ; End of fibonacy number cocmputation 
            ;-----------------------------------------------
            ; Verify Fibonacci numbers stored in memory
            ; Memory layout:
            ;   FIBNUMB: F(0), F(1), F(2), ...
            ; Registers:
            ;   l0 = previous-previous (F(n-2))
            ;   l1 = previous          (F(n-1))
            ;   l2 = current from mem  (F(n))
            ;-----------------------------------------------
;FIB_VERIFY  LDX #FIBNUMB         ; pointer to first Fibonacci number
;            ; Load first two Fibonacci numbers from memory
;            JSR ?load32_l0       ; l0 = F(0)
;            JSR ?load32_l1       ; l1 = F(1)
;            ; Set loop counter = total_numbers - 2 (first two already loaded)
;            LDA #0x0E            ; e.g., total 16 numbers → 16-2=14 iterations
;            STA LOOPCNT
;VERIFY_LOOP JSR ?load32_l2       ; Load next Fibonacci number from memory into l2
;            JSR ?add32_l3_l1_l0  ; Compute sum l0 + l1 → l3
;            JSR ?cmp32_l3_l2     ; Compare computed sum with loaded number
;            JNE FAIL
;            JSR ?mov32_l0_l1     ; Rotate registers for next iteration
;            JSR ?mov32_l1_l2
;            LDA LOOPCNT          ; Decrement loop counter
;            ADDA #0xFF         ; decrement
;            STA LOOPCNT
;            CMPA #0x00
;            JNE VERIFY_LOOP


            JMP 0xE000  ; Loop from start of diag test
MSGTXT1        .ASCII "123ABC"
MSGTXT2        .ASCII "Hello Word"
MSGTXT3        .ASCII "This is a text message to test ascii text table in assembler"
         
         ; ---------------------
         ; Math library routines
         ; ---------------------
         ; virtual registers
;-----------------------------------------------------------------------------
; ?b15 ?b14 ?b13 ?b12 | ?b11 ?b10 ?b9 ?b8 | ?b7 ?b6 ?b5 ?b4 | ?b3 ?b2 ?b1 ?b0 |  8 bits
;    ?w7       ?w6    |    ?w5      ?w4   |   ?w3     ?w2   |   ?w1     ?w0   | 16 bits
;         ?l3         |         ?l2       |       ?l1       |       ?l0       | 32 bits
;-----------------------------------------------------------------------------
                  ; Clear 32bits
?clear32_l0       LDA #0x00
                  STA ?b0
                  STA ?b1
                  STA ?b2
                  STA ?b3
                  RTS
?clear32_l1       LDA #0x00
                  STA ?b4
                  STA ?b5
                  STA ?b6
                  STA ?b7
                  RTS   
?clear32_l2       LDA #0x00
                  STA ?b8
                  STA ?b9
                  STA ?b10
                  STA ?b11
                  RTS
?clear32_l3       LDA #0x00
                  STA ?b12
                  STA ?b13
                  STA ?b14
                  STA ?b15
                  RTS
                  ; Clear 16bits
?clear16_w0       LDA #0x00
                  STA ?b0
                  STA ?b1
                  RTS
?clear16_w1       LDA #0x00
                  STA ?b2
                  STA ?b3
                  RTS
?clear16_w2       LDA #0x00
                  STA ?b4
                  STA ?b5
                  RTS
?clear16_w3       LDA #0x00
                  STA ?b6
                  STA ?b7
                  RTS
?clear16_w4       LDA #0x00
                  STA ?b8
                  STA ?b9     
                  RTS
?clear16_w5       LDA #0x00
                  STA ?b10
                  STA ?b11
                  RTS
?clear16_w6       LDA #0x00
                  STA ?b12
                  STA ?b13
                  RTS
?clear16_w7       LDA #0x00
                  STA ?b14
                  STA ?b15
                  RTS
                  ; Set 32bits to 1
?set32_l0_to_1    LDA #0x01
                  STA ?b0
                  LDA #0x00
                  STA ?b1
                  STA ?b2
                  STA ?b3
                  RTS
?set32_l1_to_1    LDA #0x01
                  STA ?b4
                  ;CLR ?b5    ; I dont have a page 0 clear instruction yet
                  ;CLR ?b6
                  ;CLR ?b7
                  LDA #0x00
                  STA ?b5
                  STA ?b6
                  STA ?b7
                  RTS                  
                  ; Load 32bits l0 using X register as pointer
?load32_l0        LDA (X)
                  STA ?b3
                  INCX
                  LDA (X)
                  STA ?b2
                  INCX
                  LDA (X)
                  STA ?b1
                  INCX
                  LDA (X)
                  STA ?b0
                  RTS
                  ; Load 32bits l1 using X register as pointer
?load32_l1        LDA (X)
                  STA ?b7
                  INCX
                  LDA (X)
                  STA ?b6
                  INCX
                  LDA (X)
                  STA ?b5
                  INCX
                  LDA (X)
                  STA ?b4
                  RTS
                  ; Load 32bits l2 using X register as pointer
?load32_l2        LDA (X)
                  STA ?b11
                  INCX
                  LDA (X)
                  STA ?b10
                  INCX
                  LDA (X)
                  STA ?b9
                  INCX
                  LDA (X)
                  STA ?b8
                  RTS
                  ; Load 32bits l3 using X register as pointer
?load32_l3        LDA (X)
                  STA ?b15
                  INCX
                  LDA (X)
                  STA ?b14
                  INCX
                  LDA (X)
                  STA ?b13
                  INCX
                  LDA (X)
                  STA ?b12
                  RTS                   
                  ; Store 32bits l0 using X register as pointer
?store32_l0       LDA ?b3
                  STA (X)
                  INCX
                  LDA ?b2
                  STA (X)
                  INCX
                  LDA ?b1
                  STA (X)
                  INCX
                  LDA ?b0
                  STA (X)
                  INCX
                  RTS
                  ; Store 32bits l1 using X register as pointer
?store32_l1       LDA ?b7
                  STA (X)
                  INCX
                  LDA ?b6
                  STA (X)
                  INCX
                  LDA ?b5
                  STA (X)
                  INCX
                  LDA ?b4
                  STA (X)
                  INCX
                  RTS
                  ; Store 32bits l2 using X register as pointer
?store32_l2       LDA ?b11
                  STA (X)
                  INCX
                  LDA ?b10
                  STA (X)
                  INCX
                  LDA ?b9
                  STA (X)
                  INCX
                  LDA ?b8
                  STA (X)
                  INCX
                  RTS
                  ; Store 32bits l3 using X register as pointer
?store32_l3       LDA ?b15
                  STA (X)
                  INCX
                  LDA ?b14
                  STA (X)  
                  INCX
                  LDA ?b13
                  STA (X)
                  INCX
                  LDA ?b12
                  STA (X)
                  INCX
                  RTS
                  ; Move 32 bits from l0 to l1
?mov32_l1_l0      LDA ?b3
                  STA ?b7
                  LDA ?b2
                  STA ?b6
                  LDA ?b1
                  STA ?b5
                  LDA ?b0
                  STA ?b4
                  RTS
                  ; Move 32 bits from l0 to l2
?mov32_l2_l0      LDA ?b3
                  STA ?b11
                  LDA ?b2
                  STA ?b10
                  LDA ?b1
                  STA ?b9
                  LDA ?b0
                  STA ?b8
                  RTS
                  ; Move 32 bits from l0 to l3
?mov32_l3_l0      LDA ?b3
                  STA ?b15
                  LDA ?b2
                  STA ?b14
                  LDA ?b1
                  STA ?b13
                  LDA ?b0
                  STA ?b12
                  RTS
                  ; Move 32 bits from l1 to l0
?mov32_l0_l1      LDA ?b7
                  STA ?b3
                  LDA ?b6
                  STA ?b2
                  LDA ?b5
                  STA ?b1
                  LDA ?b4
                  STA ?b0
                  RTS
                  ; Move 32 bits from l1 to l2
?mov32_l2_l1      LDA ?b7
                  STA ?b11
                  LDA ?b6
                  STA ?b10
                  LDA ?b5
                  STA ?b9
                  LDA ?b4
                  STA ?b8
                  RTS
                  ; Move 32 bits from l1 to l3
?mov32_l3_l1      LDA ?b7
                  STA ?b15
                  LDA ?b6
                  STA ?b14
                  LDA ?b5
                  STA ?b13
                  LDA ?b4
                  STA ?b12
                  RTS
                  ; Move 32 bits from l2 to l0
?mov32_l0_l2      LDA ?b11
                  STA ?b3
                  LDA ?b10
                  STA ?b2
                  LDA ?b9
                  STA ?b1
                  LDA ?b8
                  STA ?b0
                  RTS
                  ; Move 32 bits from l2 to l1
?mov32_l1_l2      LDA ?b11
                  STA ?b7
                  LDA ?b10
                  STA ?b6
                  LDA ?b9
                  STA ?b5
                  LDA ?b8
                  STA ?b4
                  RTS
                  ; Move 32 bits from l2 to l3
?mov32_l3_l2      LDA ?b11
                  STA ?b15
                  LDA ?b10
                  STA ?b14
                  LDA ?b9
                  STA ?b13
                  LDA ?b8
                  STA ?b12
                  RTS
                  ; Addition on 16 bits  
                  ; w0 <= w0 + w1
?add16_w0_w0_w1   LDA ?b0  
                  ADDA ?b2
                  STA ?b0
                  LDA ?b1
                  ADCA ?b3
                  STA ?b1
                  RTS
                  ; Addition on 32 bits
                  ; l0 <= l0 + l1
?add32_l0_l0_l1   LDA ?b0  
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
                  ; l2 <= l1 + l0
?add32_l2_l1_l0   LDA ?b0  
                  ADDA ?b4
                  STA ?b8
                  LDA ?b1
                  ADCA ?b5
                  STA ?b9
                  LDA ?b2
                  ADCA ?b6
                  STA ?b10
                  LDA ?b3
                  ADCA ?b7
                  STA ?b11
                  RTS
                  ; l3 <= l1 + l0
?add32_l3_l1_l0   LDA ?b0
                  ADDA ?b4
                  STA ?b12
                  LDA ?b1
                  ADCA ?b5
                  STA ?b13
                  LDA ?b2
                  ADCA ?b6
                  STA ?b14
                  LDA ?b3
                  ADCA ?b7
                  STA ?b15
                  RTS                  
                  ; INC 32 bit
                  ; l0 <= l0 + 1
?inc32_l0_l0      LDA ?b0
                  INCA
                  STA ?b0
                  JNE ?inc32_0x_0x_JP
                  LDA ?b1
                  INCA
                  STA ?b1
                  JNE ?inc32_0x_0x_JP
                  LDA ?b2
                  INCA
                  STA ?b2
                  JNE ?inc32_0x_0x_JP
                  LDA ?b3
                  INCA
                  STA ?b3
?inc32_0x_0x_JP   RTS

                  ; Compare 32-bit registers
                  ; Result: sets E flag if equal, clears if different
;?cmp32_l3_l2      LDA ?b8
;                  CMPA ?b12      ; This instruction not available yet
;                  JNE ?cmp32_not_equal
;                  LDA ?b9
;                  CMPA ?b13
;                  JNE ?cmp32_not_equal
;                  LDA ?b10
;                  CMPA ?b14
;                  JNE ?cmp32_not_equal
;                  LDA ?b11
;                  CMPA ?b15
;                  JNE ?cmp32_not_equal
;                  ; All bytes equal, E flag already set from last comparison
;                  RTS
;?cmp32_not_equal  LDA #0x00   ; Clear E flag    I dont have a direct way to clear E flag
;                  STA ?b0
;                  RTS

                  ; MUL 8-bit
                  ; w1 (b3,b2) <= b1 * b0
?mul8_w1_b1_b0    LDA #0x00   ; Only clear ?b3
                  STA ?b3
                  LDX #0x0008 ; Loop counter (8 bits)
?mul8_w1_b1_loop  SRL ?b0     ; Shift right ?b0 (check LSB)
                  JRNC ?mul8_skip_add  ; Conditional relative jump if not Carry ( If LSB was 0, skip addition)
                  LDA ?b3
                  ADDA ?b1    ; Add multiplicand
                  STA ?b3     ; Store back
?mul8_skip_add    RRC ?b3     ; Shift right ?b3 ?b2   C -> 7 6 5 4 3 2 1 0 -> C
                  RRC ?b2     ;                       C -> 7 6 5 4 3 2 1 0 -> C
                  DECXL       ; Decrement loop counter
                  JNE ?mul8_w1_b1_loop
                  RTS

                  ; MUL 16-bit
                  ; l1 <= w1 * w0      (b7,b6,b5,b4) = (b3,b2) * (b1,b0)
?mul16_l1_w1_w0   LDA #0x00   ; Only clear ?b7 and ?b6
                  STA ?b7
                  STA ?b6
                  LDX #0x0010 ; Loop counter (16 bits)
?mul16_l1_w1_loop SRL ?b1     ; Shift right ?w0 (check LSB)  '0' -> 7 6 5 4 3 2 1 0 -> C
                  RRC ?b0     ; C  -> 7 6 5 4 3 2 1 0 -> C
                  JRNC ?mul16_skip_add  ; Conditional relative jump if not Carry ( If LSB was 0, skip addition)
                  LDA ?b6
                  ADDA ?b2    ; Add multiplicand
                  STA ?b6     ; Store back
                  LDA ?b7
                  ADCA ?b3
                  STA ?b7
?mul16_skip_add   RRC ?b7     ; Shift right ?b7 ?b6 ?b5 ?b4   C -> 7 6 5 4 3 2 1 0 -> C 
                  RRC ?b6     ;                               C -> 7 6 5 4 3 2 1 0 -> C
                  RRC ?b5
                  RRC ?b4
                  DECXL       ; Decrement loop counter
                  JNE ?mul16_l1_w1_loop
                  RTS

         ; --------------------------------------------------------------------
         ; Error routine
         ; --------------------------------------------------------------------
         ORG/0xF800  ; Diagnostic Error routine   
         ;STOP        ; Stop execution
FAIL     JMP FAIL    ; Infinite Loop on error
         
         ; --------------------------------------------------------------------
         ; JSR and RTS Test subroutine
         ; --------------------------------------------------------------------
         ORG/0xFFC0
TJSR1    LDA #0x11
         RTS
         ORG/0xFFC3
TJSR2    LDA #0x22
         JSR TJSR1
         RTS
         ORG/0xFFC9
TJSR3    LDA #0x33
         JSR TJSR2
         RTS
         ORG/0xFFCF
TJSR4    LDA #0x44
         JSR TJSR3
         RTS
         ORG/0xFFD5
TJSR5    LDA #0x44
         JSR TJSR4
         RTS
         ORG/0xFFDB
TJSR6    LDA #0x55
         JSR TJSR5
         RTS
         ORG/0xFFE1
TJSR7    LDA #0x66
         JSR TJSR6
         RTS
         ORG/0xFFE7
TJSR8    LDA #0x77
         JSR TJSR7
         RTS
         ORG/0xFFED
TJSR9    LDA #0x88
         JSR TJSR8
         RTS
         ORG/0xFFF3
TJSR10   LDA #0x99
         JSR TJSR9
         RTS
         ; --------------------------------------------------------------------
         ; Reset Vector
         ; --------------------------------------------------------------------
         ORG/0xFFFE  ; Set the Reset vector
         DB 0xE0     ; MSB Reset Vector
         DB 0x00     ; LSB Reset Vector

         
