; -----------------------------------------------------------------
; Homebrew MyCPU diagnostic program
; Author: Sylvain Fortin
; Date : 8 march 2024
; Documentation : diag.asm is used to test the assembler
;                 instructions of MyCPU.
; Memory map of the computer
; 0000H - 17FFH Total RAM space
; 0000H - 00FFH Stack
; 0100H - 17EF  Free for application
; 1FF0H SP      Stack Pointer 8 bit
; 1FF1H JSH     Temporary storage for JSR MSB address
; 1FF2H JSL          "       "     "   "  LSB    "
; 1FF3H X MSB   X Register MSB
; 1FF4H X LSB   X Register LSB
; 1FFAH E       bit<0> Equal Status bit
; 1FFBH C       bit<0> Carry Status bit
; 1FFCH A       A Register
; 1FFEH IPH	    Instruction Pointer MSB
; 1FFFH IPL          "         "    LSB
; C000H         LED port
; E000H - F000H EEPROM for application program
; -----------------------------------------------------------------
                     ; 
         ORG/E000H   ; EEPROM Start
         LDA #00H    ; Clear LED
         NOTA
         STA C000H   ; Output to LED port
         ; --------------------------------------------------------------------
         ; Test Carry Status bit integrity
         ; --------------------------------------------------------------------
         LDA #01H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         STA 1FFBH   ; Write 0 to carry bit <0>
         LDA 1FFBH   ; Read Carry Status
         CMPA #00H
         JNE F800H
         LDA #01H
         STA 1FFBH   ; Write 1 to carry bit <0>
         LDA 1FFBH   ; Read Carry Status
         CMPA #01H
         JNE F800H
         LDA #00H
         STA 1FFBH   ; Write 0 to carry bit <0>
         LDA 1FFBH   ; Read Carry Status
         CMPA #00H
         JNE F800H
         ; --------------------------------------------------------------------
         ; Test Equal Status bit integrity
         ; --------------------------------------------------------------------
         LDA #02H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         STA 1FFAH   ; Write 0 to Equal Status bit <0>
         LDA 1FFAH   ; Read Equal Status
         CMPA #00H
         JNE F800H
         LDA #01H
         STA 1FFAH   ; Write 1 to Equal Status bit <0>
         LDA 1FFAH   ; Read Equal Status
         CMPA #01H
         JNE F800H
         LDA #00H
         STA 1FFAH   ; Write 0 to Equal Status bit <0>
         LDA 1FFAH   ; Read Equal Status
         CMPA #00H
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.06 JSR    Jump to SubRoutine
         ; --------------------------------------------------------------------
         LDA #06H
         NOTA
         STA C000H   ; Output to LED port
         JSR FFC0H   ; 1 layer
         JSR FFC3H   ; 2
         JSR FFC9H   ; 3
         JSR FFCFH   ; 4
         JSR FFD5H   ; 5
         JSR FFDBH   ; 6
         JSR FFE1H   ; 7
         JSR FFE7H   ; 8
         JSR FFEDH   ; 9
         JSR FFF3H   ; 10
         ; --------------------------------------------------------------------
         ; OP.07 RTS    ReTurn from Subroutine
         ; Tested in OP.06 JSR
         ; --------------------------------------------------------------------
         ;LDA #07H
         ;NOTA
         ;STA C000H   ; Output to LED port
         ; --------------------------------------------------------------------
         ; OP.08 STOP
         ; STOP EXECUTING
         ; Cannot test here it will stop execution...
         ; A diagnostic test failure is expected to call this instruction ending 
         ; program exectution.
         ; --------------------------------------------------------------------
         ;LDA #08H
         ;NOTA
         ;STA C000H   ; Output to LED port
         ;STOP
         ; --------------------------------------------------------------------
         ; OP.09 NOP   NO OPERATION
         ; --------------------------------------------------------------------
         LDA #09H
         NOTA
         STA C000H   ; Output to LED port
         NOP
         NOP
         NOP
         ; --------------------------------------------------------------------
         ; OP.0A LDA (X) Load Reg A Indexed
         ; --------------------------------------------------------------------
         LDA #0AH
         NOTA
         STA C000H   ; Output to LED port
         LDA #55H    ; Store some value in RAM
         STA 0100H
         LDA #AAH
         STA 0101H
         LDA #DEH
         STA 01F0H
         LDA #CAH
         STA 01FFH
         LDX #0100H  ; Verify each locations
         LDA (X)
         CMPA #55H
         JNE F800H   ; Jump if result not good
         LDX #0101H
         LDA (X)
         CMPA #AAH
         JNE F800H
         LDX #01F0H
         LDA (X)
         CMPA #DEH
         JNE F800H
         LDX #01FFH
         LDA (X)
         CMPA #CAH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.0B STA (X) Store Reg A Indexed
         ; --------------------------------------------------------------------
         LDA #0BH
         NOTA
         STA C000H   ; Output to LED port
         ; --------------------------------------------------------------------
         ; OP.0C JRA **H Unconditional relative jump
         ; --------------------------------------------------------------------
         LDA #0CH
         NOTA
         STA C000H   ; Output to LED port
         JRA 00H     ; Test jump foward, Execute next instruction
         JRA 01H     ; Skip next instruction
         NOP
         JRA 02H     ; Skip next two instructions
         NOP
         NOP
         JRA 03H     ; Skip next two instructions
         NOP
         NOP
         NOP
         JRA 05H     ; Skip next two instructions
         NOP
         NOP
         NOP
         NOP 
         NOP 
         JRA 10H     ; Skip next 16 instructions
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
         NOP
         JRA 20H     ; Skip next 32 instructions
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
         NOP 
         NOP 
         ; --------------------------------------------------------------------
         ; OP.29 ADDA ****H  
         ; ADD A WITH BYTE AT ADDRESS, C UPDATE
         ; --------------------------------------------------------------------
         LDA #29H
         NOTA
         STA C000H   ; Output to LED port
         LDA #5FH    ; Store a value in RAM
         STA 0123H   
         LDA #63H
         ADDA 0123H  ; Add to A the byte at address location
         CMPA #C2H   ; Check the sum
         JNE F800H   ; Jump if result not good
         LDA 1FFBH   ; Read the Carry Status
         CMPA #00H   ; No carry expected then C should be '0'
         JNE F800H   ; Error if carry is set

         LDA #ACH    ; Store another value in RAM
         STA 1056H   
         LDA #D9H
         ADDA 1056H  ; Add to A the byte at address location
         CMPA #85H   ; Check the sum LSB
         JNE F800H   ; Jump if result not as expected
         LDA 1FFBH   ; Read the Carry Status
         CMPA #01H   ; The Carry Status bit is expected to be '1' with <7:1> set to '0'
         JNE F800H   ; Error if different
         ; --------------------------------------------------------------------
         ; OP.2A LDA ****H  
         ; LOAD A WITH BYTE AT ADDRESS Test LDA #**H instruction 
         ; --------------------------------------------------------------------
         LDA #2AH
         NOTA
         STA C000H   ; Output to LED port
         LDA #AAH    ; Load immediate in register A
         CMPA #AAH
         JNE F800H
         LDA #01H
         CMPA #01H
         JNE F800H
         LDA #02H
         CMPA #02H
         JNE F800H
         LDA #04H
         CMPA #04H
         JNE F800H
         LDA #08H
         CMPA #08H
         JNE F800H
         LDA #10H
         CMPA #10H
         JNE F800H
         LDA #20H
         CMPA #20H
         JNE F800H
         LDA #40H
         CMPA #40H
         JNE F800H
         LDA #80H
         CMPA #80H
         JNE F800H
         LDA #55H
         CMPA #55H
         JNE F800H
         LDA #FFH
         CMPA #FFH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.2B JNE ****H  
         ; JUMP IF E=0
         ; Only a partial validation because i do not have symbolic address
         ; processing in the assembler program.
         ; --------------------------------------------------------------------
         LDA #2BH
         NOTA
         STA C000H   ; Output to LED port
         LDA #6DH    ; Load a value in A
         CMPA #6DH   ; Compare with the same value
         JNE F800H   ; Error if values are different
         LDA #10H
         CMPA #10H
         JNE F800H
         LDA #01H
         CMPA #01H
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.2C JEQ ****H
         ; JUMP IF E=1
         ; Partial validation
         ; --------------------------------------------------------------------
         LDA #2CH
         NOTA
         STA C000H   ; Output to LED port
         LDA #7AH    ; Load a value in A
         CMPA #28H   ; Compare with a different value
         JEQ F800H   ; If appear identical then it's and error
         LDA #FEH
         CMPA #FFH
         JEQ F800H
         LDA #01H
         CMPA #10H
         JEQ F800H
         ; --------------------------------------------------------------------
         ; OP.2D CMPA #**H
         ; COMPARE A WITH IMMEDIATE VALUE    EQUAL STATUS BIT (E) UPDATED
         ; --------------------------------------------------------------------
         LDA #2DH
         NOTA
         STA C000H   ; Output to LED port
         LDA #12H    ; Load a value in A
         CMPA #12H   ; Compare with identical value
         LDA 1FFAH   ; Inspect EQUAL STATUS 
         CMPA #01H   ; Verify bit<0> E = '1' and all others bits <7:1> are '0'    
         JNE F800H   ; If different then it's and error
         LDA #AAH
         CMPA #55H   ; Compare with a different value
         LDA 1FFAH   ; Inspect EQUAL STATUS
         CMPA #00H   ; Verify bit<0> E = '0' and all others bits <7:1> are '0'    
         JNE F800H   ; If different then it's and error
         ; --------------------------------------------------------------------
         ; OP.2E ADCA #**H
         ; REG A = REG A + IMMEDIATE BYTE + CARRY (C)   
         ; CARRY STATUS (C) IS UPDATED
         ; --------------------------------------------------------------------
         LDA #2EH
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H    ; Clear CARRY (C)
         STA 1FFBH      
         LDA #45H
         ADCA #5BH
         CMPA #A0H   ; Verify summ
         JNE F800H
         LDA 1FFBH   ; Check carry
         CMPA #00H   ; Should be clear
         JNE F800H
         
         LDA #01H    ; Set CARRY (C)
         STA 1FFBH
         LDA #56H
         ADCA #6DH
         CMPA #C4H   ; Verify summ
         JNE F800H
         LDA 1FFBH   ; Check carry
         CMPA #00H   ; Should be clear
         JNE F800H
         
         LDA #00H    ; Clear CARRY (C)
         STA 1FFBH
         LDA #7FH
         ADCA #DEH
         CMPA #5DH   ; Verify summ
         JNE F800H
         LDA 1FFBH   ; Check carry
         CMPA #01H   ; Should be set
         JNE F800H
         
         LDA #01H    ; Set CARRY (C)
         STA 1FFBH
         LDA #FFH
         ADCA #FFH
         CMPA #FFH   ; Verify summ
         JNE F800H
         LDA 1FFBH   ; Check carry
         CMPA #01H   ; Should be set
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.2F ADDA #**H
         ; ACCA+M>ACCA     C UPDATED
         ; --------------------------------------------------------------------
         LDA #2FH
         NOTA
         STA C000H   ; Output to LED port
         LDA #23H
         ADDA #45H
         CMPA #68H
         JNE F800H
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #00H   ; Expecting C=0
         JNE F800H
         LDA #8AH
         ADDA #BDH
         CMPA #47H   
         JNE F800H
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #01H   ; Expecting C=1
         JNE F800H
         LDA #01H
         ADDA #02H
         CMPA #03H
         JNE F800H
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #00H   ; Expecting C=0
         JNE F800H
         LDA #FFH
         ADDA #FFH
         CMPA #FEH
         JNE F800H
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #01H   ; Expecting C=1
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.30 LDA #**H  
         ; LOAD IMMEDIATE VALUE IN REGISTER A
         ; --------------------------------------------------------------------
         LDA #30H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         CMPA #00H
         JNE F800H
         LDA #01H
         CMPA #01H
         JNE F800H
         LDA #02H
         CMPA #02H
         JNE F800H
         LDA #04H
         CMPA #04H
         JNE F800H
         LDA #08H
         CMPA #08H
         JNE F800H
         LDA #10H
         CMPA #10H
         JNE F800H
         LDA #20H
         CMPA #20H
         JNE F800H
         LDA #40H
         CMPA #40H
         JNE F800H
         LDA #80H
         CMPA #80H
         JNE F800H
         LDA #55H
         CMPA #55H
         JNE F800H
         LDA #AAH
         CMPA #AAH
         JNE F800H
         LDA #FFH
         CMPA #FFH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.31 STA ****H 
         ; STORE REG.A TO ADDRESSE
         ; --------------------------------------------------------------------
         LDA #31H
         NOTA
         STA C000H   ; Output to LED port
         LDA #12H    ; Write to RAM
         STA 0000H
         LDA #23H
         STA 0001H
         LDA #34H
         STA 0002H
         LDA #45H
         STA 0004H
         LDA #56H
         STA 0008H
         LDA #67H
         STA 0010H
         LDA #78H
         STA 0020H
         LDA #89H
         STA 0040H
         LDA #ABH
         STA 0080H
         LDA #BCH
         STA 0100H
         LDA #CDH
         STA 0200H
         LDA #DEH
         STA 0400H
         LDA #22H
         STA 0800H
         LDA #33H
         STA 1000H
         LDA #44H
         STA 1700H
         LDA 0000H   ; Read from RAM and compare
         CMPA #12H
         JNE F800H
         LDA 0001H
         CMPA #23H
         JNE F800H
         LDA 0002H
         CMPA #34H
         JNE F800H
         LDA 0004H
         CMPA #45H
         JNE F800H
         LDA 0008H
         CMPA #56H
         JNE F800H
         LDA 0010H
         CMPA #67H
         JNE F800H
         LDA 0020H
         CMPA #78H
         JNE F800H
         LDA 0040H
         CMPA #89H
         JNE F800H
         LDA 0080H
         CMPA #ABH
         JNE F800H
         LDA 0100H
         CMPA #BCH
         JNE F800H
         LDA 0200H
         CMPA #CDH
         JNE F800H
         LDA 0400H
         CMPA #DEH
         JNE F800H
         LDA 0800H
         CMPA #22H
         JNE F800H
         LDA 1000H
         CMPA #33H
         JNE F800H
         LDA 1700H
         CMPA #44H
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.32 JMP ****H 
         ; JUMP INCONDITIONAL TO ADDRESS
         ; --------------------------------------------------------------------
         ;LDA #32H
         ;NOTA
         ;STA C000H   ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.33 ANDA #**H  REGISTER A AND LOGICAL IMMEDIATE BYTE
         ; --------------------------------------------------------------------
         LDA #33H
         NOTA
         STA C000H   ; Output to LED port
         LDA #FFH
         ANDA #52H
         CMPA #52H
         JNE F800H
         LDA #E7H
         ANDA #3CH
         CMPA #24H
         JNE F800H
         LDA #00H
         ANDA #00H
         CMPA #00H
         JNE F800H
         LDA #FFH
         ANDA #FFH
         CMPA #FFH
         JNE F800H
         LDA #FFH
         ANDA #55H
         CMPA #55H
         JNE F800H
         LDA #FFH
         ANDA #00H
         CMPA #00H
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.34 ORA #**H   LOGICAL OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
         LDA #34H
         NOTA
         STA C000H   ; Output to LED port
         LDA #FFH
         ORA #FFH
         CMPA #FFH
         JNE F800H
         LDA #00H
         ORA #00H
         CMPA #00H
         JNE F800H
         LDA #25H
         ORA #D3H
         CMPA #F7H
         JNE F800H
         LDA #00H
         ORA #FFH
         CMPA #FFH
         JNE F800H
         LDA #FFH
         ORA #00H
         CMPA #FFH
         JNE F800H
         LDA #14H
         ORA #C1H
         CMPA #D5H
         JNE F800H
         LDA #AAH
         ORA #55H
         CMPA #FFH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.35 XORA #**H  EXCLUSIVE OR BETWEEN REG A AND IMMEDIATE BYTE
         ; --------------------------------------------------------------------
         LDA #35H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         XORA #00H
         CMPA #00H
         JNE F800H
         LDA #00H
         XORA #FFH
         CMPA #FFH
         JNE F800H
         LDA #FFH
         XORA #FFH
         CMPA #00H
         JNE F800H
         LDA #FFH
         XORA #55H
         CMPA #AAH
         JNE F800H
         LDA #CEH
         XORA #5AH
         CMPA #94H
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.36 NOTA  LOGIC NOT ON REG A
         ; --------------------------------------------------------------------
         LDA #36H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         NOTA
         CMPA #FFH
         JNE F800H
         NOTA
         CMPA #00H
         JNE F800H
         LDA #55H
         NOTA
         CMPA #AAH
         JNE F800H
         NOTA
         CMPA #55H
         JNE F800H
         NOTA
         CMPA #AAH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.37 INCA  A = A + 1  INCREMENT REGISTRE A
         ; NO UPDATE ON C (CARRY)
         ; --------------------------------------------------------------------
         LDA #37H
         NOTA
         STA C000H   ; Output to LED port
         LDA #00H
         INCA
         CMPA #01H
         JNE F800H
         LDA #01H
         INCA
         CMPA #02H
         JNE F800H
         LDA #7CH
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
         CMPA #86H
         JNE F800H
         LDA #FEH
         INCA
         CMPA #FFH
         JNE F800H
         LDA #FFH
         INCA
         CMPA #00H
         JNE F800H
         LDA #FFH
         INCA
         INCA
         CMPA #01H
         JNE F800H
         INCA
         INCA
         INCA
         INCA
         CMPA #05H
         JNE F800H
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         INCA
         CMPA #0DH
         JNE F800H
         LDA #00H    ; Test Carry is not updated
         STA 1FFBH   ; Clear Carry 
         LDA #FFH
         INCA
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #00H   ; Expecting C=0 and <7:1> = 0
         JNE F800H
         LDA #01H    ; Set Carry 
         STA 1FFBH   
         LDA #EBH
         INCA
         LDA 1FFBH   ; Read Carry bit <0>
         CMPA #01H   ; Expecting C=1 and <7:1> = 0
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.38  LDX #****H   Load X Register with 16 bits immediate value
         ; --------------------------------------------------------------------
         LDA #38H
         NOTA
         STA C000H   ; Output to LED port
         LDX #1234H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #12H
         JNE F800H
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #34H
         JNE F800H
         LDX #ABCDH
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #ABH
         JNE F800H
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #CDH
         JNE F800H
         ; --------------------------------------------------------------------
         ; OP.39  INCX   Increment Register X,  Carry Not Updated
         ; --------------------------------------------------------------------
         LDA #39H
         NOTA
         STA C000H   ; Output to LED port
         LDX #0000H  ; Clear X register
         INCX        ; Increment X
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #01H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #00H
         JNE F800H
         INCX
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #02H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #00H
         JNE F800H
         
         LDX #00FFH  ; Test a carry set
         INCX        ; Increment X
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #00H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #01H
         JNE F800H
         INCX        ; Increment X
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #01H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #01H
         JNE F800H
         
         LDX #1EFFH
         INCX        ; Increment X
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #00H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #1FH
         JNE F800H
         
         LDX #FFFFH
         INCX        ; Increment X
         LDA 1FF4H   ; Read Reg X LSB into A
         CMPA #00H
         JNE F800H
         LDA 1FF3H   ; Read Reg X MSB into A
         CMPA #00H
         JNE F800H
         
         ; --------------------------------------------------------------------
         ; FIBONACCI TEST
         ; --------------------------------------------------------------------         
         LDA #FFH
         NOTA
         STA C000H   ; Output to LED port
                     ;
         LDA #00H    ; Init first number with 00H
         STA 1000H
         LDA #01H    ; Init second number with 01H
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #01H   ; HEX   Decimal  Real Value (in 8 bit storage only)
         JNE F800H   ; 01H   1        1
         
         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #02H   ; HEX   Decimal  Real Value
         JNE F800H   ; 02H   2        2
         
         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #03H   ; HEX   Decimal  Real Value
         JNE F800H   ; 03H   3        3
         
         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #05H   ; HEX   Decimal  Real Value
         JNE F800H   ; 05H   5        5
         
         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #08H   ; HEX   Decimal  Real Value
         JNE F800H   ; 08H   8        8

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #0DH   ; HEX   Decimal  Real Value
         JNE F800H   ; 0DH   13       13

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #15H   ; HEX   Decimal  Real Value
         JNE F800H   ; 15H   21       21

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #22H   ; HEX   Decimal  Real Value
         JNE F800H   ; 22H   34       34

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #37H   ; HEX   Decimal  Real Value
         JNE F800H   ; 37H   55       55

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #59H   ; HEX   Decimal  Real Value
         JNE F800H   ; 59H   89       89

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #90H   ; HEX   Decimal  Real Value
         JNE F800H   ; 90H   144      144

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #E9H   ; HEX   Decimal  Real Value
         JNE F800H   ; E9H   233      233

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #79H   ; HEX   Decimal  Real Value
         JNE F800H   ; 79H   121      377 - (256*1) = 121

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #62H   ; HEX   Decimal  Real Value
         JNE F800H   ; 62H   98       610 - (256*2) = 98

         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         CMPA #DBH   ; HEX   Decimal  Real Value
         JNE F800H   ; DBH   219      987 - (256*3) = 219         

         ; --------------------------------------------------------------------      
         ; END OF FIBONACCI TEST
         ; --------------------------------------------------------------------      
         
         JMP E000H   ; Loop from start of diag test
         
         ; --------------------------------------------------------------------
         ; Error routine
         ; --------------------------------------------------------------------
         ORG/F800H   ; Diagnostic Error routine   
         STOP        ; Stop execution
         ;JMP F800H   ; Infinite Loop on error
         
         ; --------------------------------------------------------------------
         ; JSR and RTS Test subroutine
         ; --------------------------------------------------------------------
         ORG/FFC0H
         LDA #11H
         RTS
         ORG/FFC3H
         LDA #22H
         JSR FFC0H
         RTS
         ORG/FFC9H
         LDA #33H
         JSR FFC3H
         RTS
         ORG/FFCFH
         LDA #44H
         JSR FFC9H
         RTS
         ORG/FFD5H
         LDA #44H
         JSR FFCFH
         RTS
         ORG/FFDBH
         LDA #55H
         JSR FFD5H
         RTS
         ORG/FFE1H
         LDA #66H
         JSR FFDBH
         RTS
         ORG/FFE7H
         LDA #77H
         JSR FFE1H
         RTS
         ORG/FFEDH
         LDA #88H
         JSR FFE7H
         RTS
         ORG/FFF3H
         LDA #99H
         JSR FFEDH
         RTS
         ; --------------------------------------------------------------------
         ; Reset Vector
         ; --------------------------------------------------------------------
         ORG/FFFEH   ; Set the Reset vector
         DB E0H      ; MSB Reset Vector
         DB 00H      ; LSB Reset Vector

         
