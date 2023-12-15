; -----------------------------------------------------------------
; Homebrew CPU micro code
; Author: Sylvain Fortin
; Date : 1 december 2023
; Documentation : blink.asm show two alternating values 0x55 
;                 and 0xAA on the led port of MyCPU
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
         ORG/E000H   ; EEPROM Start
         LDA #AAH    ; Load immediate in register A
         STA C000H   ; Output to LED port
         NOTA        ; Not logical on Reg A
         STA C000H   ; Output to LED port
         JMP E000H   ; Jump inconditional to address
         ORG/FFFEH   ; Set the Reset vector
         DB E0H      ; MSB Reset Vector
         DB 00H      ; LSB Reset Vector


