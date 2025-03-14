; -----------------------------------------------------------------
; Homebrew MyCPU diagnostic program
; Author: Sylvain Fortin
; Date : 13 march 2025
; Documentation : diag.asm is used to test the assembler
;                 instructions of MyCPU.
; Memory map of the computer
; 0000H - 17FFH Total RAM space
; 0000H - 00FFH Stack
; 0100H - 17EF  Free for application
; E000H - F000H EEPROM for application program
; -----------------------------------------------------------------

; RAM test variable
R8_0     EQU 0x1000
R8_1     EQU 0x1001
R8_2     EQU 0x1002
R8_3     EQU 0x1003

; RAM Reserved location
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
         ; LOAD A WITH BYTE AT ADDRESS Test LDA #0x** instruction 
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
         ; Partial validation
         ; --------------------------------------------------------------------
TSTOP2C  LDA #0x2C
         NOTA
         STA LEDPORT ; Output to LED port
         LDA #0x7A   ; Load a value in A
         CMPA #0x28  ; Compare with a different value
         JEQ FAIL    ; If appear identical then it's and error
         LDA #0xFE
         CMPA #0xFF
         JEQ FAIL 
         LDA #0x01
         CMPA #0x10
         JEQ FAIL 
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
         
         LDA #0x01H  ; Set CARRY (C)
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
         ; OP.34 ORA #0x**   LOGICAL OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
TSTOP34  LDA #0x34
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
         ; OP.35 XORA #0x**  EXCLUSIVE OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
TSTOP35  LDA #0x35
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
         ; OP.36 NOTA  LOGIC NOT ON REG A
         ; --------------------------------------------------------------------
TSTOP36  LDA #0x36
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
         ; OP.37 INCA  A = A + 1  INCREMENT REGISTRE A
         ; NO UPDATE ON C (CARRY)
         ; --------------------------------------------------------------------
TSTOP37  LDA #0x37
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
         LDA #0x00   ; Test Carry is not updated
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
         ; --------------------------------------------------------------------
         ; OP.38  LDX #0x****   Load X Register with 16 bits immediate value
         ; --------------------------------------------------------------------
TSTOP38  LDA #0x38
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
         ; --------------------------------------------------------------------
         ; OP.39  INCX   Increment Register X,  Carry Not Updated
         ; --------------------------------------------------------------------
TSTOP39  LDA #0x39
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
         ; FIBONACCI TEST
         ; --------------------------------------------------------------------         
TSTFIBON LDA #0xFE
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
         ; END OF FIBONACCI TEST
         ; --------------------------------------------------------------------      
         
         ; ---------
         ; Loop test
         ; ---------
LOOPTST  LDA #0xFF
         NOTA
         STA LEDPORT    ; Output to LED port
         LDA #0x05      ; Init a counter of iterations
         STA R8_0
LOOPTST1 LDA R8_0       ; Read counter
         CMPA #0x00     ; Is it 0?
         JEQ LOOPTST2   ; Yes then it's the end fo the test
         ADDA #0xFF     ; Add -1 in complement 2 (equivalent to decrement)
         STA R8_0       ; Save decremented count
         JRA LOOPTST1
LOOPTST2 NOP            ; End of decrement loop         


         JMP 0xE000  ; Loop from start of diag test
         
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

         
