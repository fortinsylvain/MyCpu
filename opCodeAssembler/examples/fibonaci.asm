; -----------------------------------------------------------------
; Homebrew CPU micro code
; Author: Sylvain Fortin
; Date : 14 december 2023
; Documentation : fibonaci.asm compute the fibonacciy serie on MyCPU.
;                 Output results are displayed sequentially on LED 
;                 as they are computed.
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
                     ; RAM variables
                     ; 1000H First number  (8-bits)
                     ; 1001H Second number (8-bits)
                     ; 1002H Summ storage           (8-bits)
                     ; 
         ORG/E000H   ; EEPROM Start
         LDA #00H    ; Init first number to 0
         STA 1000H   ; 
         LDA #01H    ; Init second number to 1
         STA 1001H   ; 
; Loop         
         LDA 1000H   ; Load first number in A
         ADDA 1001H  ; Add second number to A
         STA 1002H   ; Store the summ
         NOTA        ; Invert all bits, 0:LED ON
         STA C000H   ; Output to LED port
         LDA 1001H   ; Move second number to the first number
         STA 1000H
         LDA 1002H   ; Move summ to the second number
         STA 1001H
         JMP E00AH   ; Loop
            
         ORG/FFFEH   ; Set the Reset vector
         DB E0H      ; MSB Reset Vector
         DB 00H      ; LSB Reset Vector

; LED output   HEX   Decimal  Real Value
; ----------   ---   -------  ----------
; 0000 0001    01H   1        1
; 0000 0010    02H   2        2
; 0000 0011    03H   3        3
; 0000 0101    05H   5        5
; 0000 1000    08H   8        8
; 0000 1101    0DH   13       13
; 0001 0101    15H   21       21
; 0010 0010    22H   34       34
; 0011 0111    37H   55       55
; 0101 1001    59H   89       89
; 1001 0000    90H   144      144
; 1110 1001    E9H   233      233
; 0111 1001    79H   121      377 - (256*1) = 121
; 0110 0010    62H   98       610 - (256*2) = 98
; 1101 1011    DBH   219      987 - (256*3) = 219
; 0011 1101    3DH   61       ...
; 0001 1000
; 0101 0101
; 


