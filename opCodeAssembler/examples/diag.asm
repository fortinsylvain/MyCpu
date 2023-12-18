; -----------------------------------------------------------------
; Homebrew MyCPU diagnostic program
; Author: Sylvain Fortin
; Date : 17 december 2023
; Documentation : diag.asm is used to test the assembler
;                 instructions of MyCPU.
; Memory map of the computer
; 0000H - 17FFH Total RAM space
; 0000H - 00FFH Stack
; 0100H - 17EF  Free for application
; 17F0H         SP Stack Pointer 8 bit
; 17F1H temp SP1
; 17F2H temp SP2
; 17FAH bit<0>	Equal
; 17FBH bit<0>	Carry
; 17FCH A Register
; 17FEH IPH	Instruction Pointer MSB
; 17FFH IPL Instruction Pointer LSB
; C000H           LED port
; E000H - F000H   EEPROM 2864 for program storage
; -----------------------------------------------------------------
                     ; 
         ORG/E000H   ; EEPROM Start
         
         LDA #00H    ; Clear LED
         NOTA
         STA C000H   ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.08 STOP
         ; STOP EXECUTING
         ; Cannot test here it will stop execution...
         ; --------------------------------------------------------------------
         ;LDA #08H
         ;NOTA
         ;STA C000H   ; Output to LED port
         ;STOP
         
         ; --------------------------------------------------------------------
         ; OP.29 ADDA ****H  
         ; ADD A WITH BYTE AT ADDRESS, C UPDATE
         ; --------------------------------------------------------------------
         ;LDA #29H
         ;NOTA
         ;STA C000H   ; Output to LED port
         
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
         ; OP.2B JNEQ ****H  
         ; JUMP IF E=0
         ; --------------------------------------------------------------------
         ;LDA #2BH
         ;NOTA
         ;STA C000H   ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.2C JEQ ****H
         ; JUMP IF E=1
         ; --------------------------------------------------------------------
         ;LDA #2CH
         ;NOTA
         ;STA C000H   ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.2D CMPA #**H
         ; COMPARE A WITH IMMEDIATE VALUE 
         ; --------------------------------------------------------------------
         ;LDA #2DH
         ;NOTA
         ;STA C000H   ; Output to LED port
         
         ; --------------------------------------------------------------------
         ; OP.2E ADCA #**H
         ; ACCA+M+C>ACCA     C UPDATED
         ; --------------------------------------------------------------------
         ;LDA #2EH
         ;NOTA
         ;STA C000H   ; Output to LED port
         
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
         LDA 17FBH   ; Read Carry bit <0>
         CMPA #00H   ; Expecting C=0
         JNE F800H
         LDA #8AH
         ADDA #BDH
         CMPA #47H   
         JNE F800H
         ;LDA 17FBH   ; Read Carry bit <0>   BUG: Appear to miss the Carry !!!!
         ;CMPA #01H   ; Expecting C=1
         ;JNE F800H
         ;LDA #01H
         ;ADDA #02H
         ;CMPA #03H
         ;JNE F800H
         ;LDA 17FBH   ; Read Carry bit <0>
         ;CMPA #00H   ; Expecting C=0
         ;JNE F800H
         ;LDA #FFH
         ;ADDA #FFH
         ;CMPA #FEH
         ;JNE F800H
         ;LDA 17FBH   ; Read Carry bit <0>
         ;CMPA #01H   ; Expecting C=1
         ;JNE F800H
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
         ; OP.33 ANDA #**H  REGISTER A AND LOGICAL IMMEDIATE 
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
         ; Reset Vector
         ; --------------------------------------------------------------------
         ORG/FFFEH   ; Set the Reset vector
         DB E0H      ; MSB Reset Vector
         DB 00H      ; LSB Reset Vector

         
