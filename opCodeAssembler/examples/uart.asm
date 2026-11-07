; -----------------------------------------------------------------
; Homebrew MyCPU diagnostic program
; Author: Sylvain Fortin sylfortin71@hotmail.com
; Date : 6 nov 2026
; Documentation : uart.asm is a UART test program
;                 for MyCPU.
; Memory map of the computer
; 0x0000 - 0x1FFF   RAM
; 0x0000 - 0x7FFF   Total RAM space
; 0x00A0 - 0x00FF   Stack
; 0x7400 - 0x77FF   UART        DEC0_CS_N
; 0x7800 - 0x7BFF   LED_PORT 
; 0x7C00 - 0x7FFF   LCD         DEC1_CS_N
; 0x8000 - 0xFFFF   EEPROM
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

; Diagnostic program variable
DIAGLOOPCOUNTER_MSB EQU 0x01E0  ; MSB of loop counter for diagnostics
DIAGLOOPCOUNTER_LSB EQU 0x01E1  ; LSB
DIAGTST_MSB         EQU 0x01E2  ; MSB of test variable
DIAGTST_LSB         EQU 0x01E3  ; LSB 
DIAGTST2_MSB        EQU 0x1EFF  ; MSB of test variable2
DIAGTST2_LSB        EQU 0x1F00  ; LSB 

;--------------------------------------------
; UART PORT
; 0x7400 - 0x77FF   UART        DEC0_CS_N
;--------------------------------------------
UARTPORT EQU 0x7400  ; UART TX bit

;--------------------------------------------
; LED PORT
; 0x7800 - 0x7BFF   LED_PORT 
;--------------------------------------------
LEDPORT  EQU 0x7800  ; PORT for the LED

;--------------------------------------------
; LCD Memory-Mapped I/O Addresses
;--------------------------------------------
LCD_CMD  EQU 0x7C00
LCD_DATA EQU 0x7C01


; MyCPU - Software UART transmitter
; CPU clock: 5 MHz
; Target baud: 9600
; Format: 8N1

         ORG/0x8000
START
         ; Initialize TX to idle HIGH
         LDA #0x01
         STA UARTPORT

TX_LOOP
         ; Send test character 0x55
         LDA #0x55
         JSR UART_TX
         
         LDA #0x55
         JSR UART_TX
         
         LDA #0x55
         JSR UART_TX
         
         JRA TX_LOOP

; --------------------------------
; UART_TX
; Input: A = character to transmit
; A UART 8N1 frame contains 10 bits:
; - 1 start bit
; - 8 data bits
; - 1 stop bit
; D0 first (LSB first)
; --------------------------------

; ============================================================
; MyCPU SOFTWARE UART TRANSMITTER - TIMING CALIBRATION
; ============================================================
; CPU clock              : 5 MHz
; UART format             : 9600 baud, 8-N-1
; TX idle state           : HIGH
;
; TARGET
; ------------------------------------------------------------
; Target bit period       : 104.167 us
;
; MEASURED
; ------------------------------------------------------------
; Start bit               : 103.6 us (3 NOP + POPA)
; Data bits 0-6           : approximately 103-104 us
; Start + 8 data bits     : 940 us
; Average bit period      : 104.44 us
; Calculated baud rate    : 9575 baud
; Baud error              : -0.26%
;
; Last data bit interval  : 108.8 us (3 NOP + LDA)
; Stop bit HIGH           : 264 us
;
; Complete frame          : 1204 us
; Maximum throughput      : approximately 830 characters/sec
;
; ============================================================
; DELAY CALIBRATION
; ============================================================
; Start bit transition:
;    3 NOP + POPA          = 103.6 us
;
; Normal data bit:
;    4 NOP                 = approximately 103-104 us
;
; Last data bit to stop:
;    3 NOP + LDA #0x01     = 108.8 us
;
; Stop bit:
;    HIGH for 264 us
;
; ============================================================

UART_TX
        PSHA
        ; Start bit = LOW
        LDA #0x00    
        STA UARTPORT ; start bit    
        NOP
        NOP
        NOP                         ; 103.6 us 3 NOP + POPA
        ;NOP                        ; 112 us 4 NOP + POPA
        POPA
        STA UARTPORT ; bit 0        
        SRLA                        ; 52.4 us per bit 0 NOP
        NOP                         ; 61.6 us per bit 1 NOP
        NOP
        NOP                         ; 86.8 us per bit 3 NOP
        NOP                         ; 104  us per bit 4 NOP
;        NOP
;        NOP                         ; 128.8 us per bit 6 NOP
        STA UARTPORT ; bit 1
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 2
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 3
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 4
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 5
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 6
        SRLA
        NOP
        NOP
        NOP
        NOP
;        NOP
;        NOP
        STA UARTPORT ; bit 7
        SRLA
        NOP
        NOP                         ; 99.6 us 2 NOP + LDA
        NOP                       ; 108.8 us 3 NOP + LDA
;        NOP                      ; 130 us 4 NOP + LDA
;        NOP
;        NOP
        LDA #0x01
        STA UARTPORT ; Stop bit = HIGH
        RTS

; 54 us between two writes
;START    LDA #0x00
;         STA UARTPORT
;         LDA #0x01
;         STA UARTPORT
;         JRA START
; --------------------------------------------------------------------
; Reset Vector
; --------------------------------------------------------------------
         ORG/0xFFFE  ; Set the Reset vector
         DB 0x80     ; MSB Reset Vector
         DB 0x00     ; LSB Reset Vector         
         
         

       