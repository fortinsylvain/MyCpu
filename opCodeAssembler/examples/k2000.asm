; -----------------------------------------------------------------
; Homebrew CPU micro code
; Author: Sylvain Fortin
; Date : 1 december 2023
; Documentation : k2000.asm toggle each LED back and fourth like the 
;                 car called KIT in the famous TV show. It store the  
;                 LED patterns in ram and then send them sequentially 
;                 to the led port of MyCPU.
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
; C000H           LED port    0:LED ON, 1:LED OFF
; E000H - F000H   EEPROM 2864 for program storage
; -----------------------------------------------------------------
         ORG/E000H   ; EEPROM Start
         LDA #7FH    ; LED<7> ON
         STA 0107H
         LDA #BFH    ; LED<6> ON
         STA 0106H
         LDA #DFH    ; LED<5> ON
         STA 0105H
         LDA #EFH    ; LED<4> ON
         STA 0104H
         LDA #F7H    ; LED<3> ON
         STA 0103H
         LDA #FBH    ; LED<2> ON
         STA 0102H
         LDA #FDH    ; LED<1> ON
         STA 0101H
         LDA #FEH    ; LED<0> ON
         STA 0100H
; Loop   
         LDA 0100H   ; Load each pattern from RAM
         STA C000H   ; and send to LED
         LDA 0101H
         STA C000H
         LDA 0102H
         STA C000H
         LDA 0103H
         STA C000H
         LDA 0104H
         STA C000H
         LDA 0105H
         STA C000H
         LDA 0106H
         STA C000H
         LDA 0107H
         STA C000H
         LDA 0106H
         STA C000H
         LDA 0105H
         STA C000H
         LDA 0104H
         STA C000H
         LDA 0103H
         STA C000H
         LDA 0102H
         STA C000H
         LDA 0101H
         STA C000H
         LDA 0100H
         STA C000H
         JMP E028H   ; Jump inconditional to Loop
         
         ORG/FFFEH   ; Set the Reset vector
         DB E0H      ; MSB Reset Vector
         DB 00H      ; LSB Reset Vector


