; -----------------------------------------------------------------
; MyCPU Snake Demo
; Automatic-play Snake animation for Sylvain Fortin's MyCPU
;
; Based on the instruction syntax and LCD routines in diag.asm.
; No player input is used. The snake moves back and forth across
; a 16x2 character LCD. The food is shown on the opposite row.
; The LED port displays the snake's current head column.
;
; Hardware assumptions:
;   - LCD_CMD = 0x7C00 and LCD_DATA = 0x7C01.
;   - LCD is compatible with the HD44780-style commands used in diag.asm:
;     8-bit interface, 2 lines, 5x8 font, standard 16x2 DDRAM mapping.
;   - LED port is writable at 0x7800.
;   - LCD and LED I/O are memory-mapped as described in diag.asm.
;   - RAM 0x0200-0x0207 is available.
;   - The CPU reset/startup mechanism initializes the stack sufficiently
;     for JSR/RTS, as assumed by diag.asm.
;
; Note: this is an automatic visual demo, not a playable Snake game.
; It animates a 4-character snake and a food marker; no growth or collision
; logic is implemented because there is no input hardware yet.
; -----------------------------------------------------------------

LCD_CMD       EQU 0x7C00
LCD_DATA      EQU 0x7C01
LEDPORT       EQU 0x7800

; RAM variables (keep clear of the stack and MyCPU reserved registers)
HEADCOL       EQU 0x0200   ; Head column, constrained to 3..12
ROW           EQU 0x0201   ; Snake row: 0 or 1
DIR           EQU 0x0202   ; 1 = moving right, 0 = moving left
CURROW        EQU 0x0203   ; Temporary LCD cursor row
CURCOL        EQU 0x0204   ; Temporary LCD cursor column
FOODROW       EQU 0x0205   ; Food is displayed on the opposite row
DLYOUT        EQU 0x0206   ; Outer frame-delay counter
DLYIN         EQU 0x0207   ; Inner frame-delay counter

         ORG/0x8000

START    JSR LCD_Init
         JSR LCD_Clear

         ; Initial snake state: head at column 3, row 0, moving right
         LDA #0x03
         STA HEADCOL
         CLRA
         STA ROW
         LDA #0x01
         STA DIR

MAIN     JSR LCD_Clear
         ; LED output follows the head column (0x03..0x0C)
         LDA HEADCOL
         STA LEDPORT

         ; Draw the four-character snake on its current row.
         ; Right: draw "ooo@" from headcol-3.
         ; Left:  draw "@ooo" from headcol.
         LDA DIR
         TEQA #0x01
         JNE DRAW_LEFT

DRAW_RIGHT
         LDA HEADCOL
         DECA
         DECA
         DECA
         STA CURCOL
         LDA ROW
         STA CURROW
         JSR LCD_SetDynamicCursor
         LDX #SnakeRight
         JSR LCD_PrintString
         JMP DRAW_FOOD

DRAW_LEFT
         LDA HEADCOL
         STA CURCOL
         LDA ROW
         STA CURROW
         JSR LCD_SetDynamicCursor
         LDX #SnakeLeft
         JSR LCD_PrintString

DRAW_FOOD
         ; Place food at column 8 on the row opposite the snake.
         LDA ROW
         TEQA #0x00
         JNE FOOD_ON_ROW0
         LDA #0x01
         STA FOODROW
         JMP FOOD_POSITION
FOOD_ON_ROW0
         CLRA
         STA FOODROW

FOOD_POSITION
         LDA #0x08
         STA CURCOL
         LDA FOODROW
         STA CURROW
         JSR LCD_SetDynamicCursor
         LDA #0x2A          ; ASCII '*'
         JSR LCD_PrintChar

         JSR FrameDelay
         JSR MoveSnake
         JMP MAIN

; -----------------------------------------------------------------
; Move one step. At each end, reverse direction and switch rows.
; Restricting the head to columns 3..12 keeps the whole 4-char body
; visible on a 16-column display.
; -----------------------------------------------------------------
MoveSnake
         LDA DIR
         TEQA #0x01
         JNE MOVE_LEFT

MOVE_RIGHT
         LDA HEADCOL
         TEQA #0x0C
         JEQ RIGHT_TURN
         INCA
         STA HEADCOL
         RTS

RIGHT_TURN
         CLRA
         STA DIR             ; now moving left
         LDA ROW
         TEQA #0x00
         JNE RIGHT_TO_ROW0
         LDA #0x01
         STA ROW
         RTS
RIGHT_TO_ROW0
         CLRA
         STA ROW
         RTS

MOVE_LEFT
         LDA HEADCOL
         TEQA #0x03
         JEQ LEFT_TURN
         DECA
         STA HEADCOL
         RTS

LEFT_TURN
         LDA #0x01
         STA DIR             ; now moving right
         LDA ROW
         TEQA #0x00
         JNE LEFT_TO_ROW0
         LDA #0x01
         STA ROW
         RTS
LEFT_TO_ROW0
         CLRA
         STA ROW
         RTS

; -----------------------------------------------------------------
; Dynamic cursor positioning.
; CURROW = 0 or 1; CURCOL = 0..15.
; HD44780-style command is 0x80+column for row 0 and 0xC0+column
; for row 1. This avoids relying on writing directly to XH/XL.
; -----------------------------------------------------------------
LCD_SetDynamicCursor
         LDA CURROW
         TEQA #0x00
         JNE LCD_CursorRow1
         LDA CURCOL
         ORA #0x80
         STA LCD_CMD
         RTS

LCD_CursorRow1
         LDA CURCOL
         ADDA #0x40
         ORA #0x80
         STA LCD_CMD
         RTS

; -----------------------------------------------------------------
; LCD routines adapted from diag.asm
; -----------------------------------------------------------------
LCD_Init
         ; Approximate power-up wait, following diag.asm
         LDA #0xFF
LCD_Delay40ms
         DECA
         JNE LCD_Delay40ms

         LDA #0x38          ; 8-bit, 2-line, 5x8 font
         STA LCD_CMD

         LDA #0xF0
LCD_Delay4ms
         DECA
         JNE LCD_Delay4ms

         LDA #0x0C          ; Display on, cursor off, blink off
         STA LCD_CMD
         LDA #0x06          ; Increment cursor, no display shift
         STA LCD_CMD
         RTS

LCD_Clear
         LDA #0x01
         STA LCD_CMD
         LDA #0xFF
LCD_DelayClear
         DECA
         JNE LCD_DelayClear
         RTS

; Input: A = ASCII character
LCD_PrintChar
         STA LCD_DATA
         RTS

; Input: X points to a zero-terminated string
LCD_PrintString
         LDA (X)
         TEQA #0x00
         JEQ LCD_StringDone
         JSR LCD_PrintChar
         INCX
         JMP LCD_PrintString
LCD_StringDone
         RTS

; A pair of strings used to orient the head in the direction of travel.
SnakeRight  .ASCII "ooo@"
            DB 0x00
SnakeLeft   .ASCII "@ooo"
            DB 0x00

; -----------------------------------------------------------------
; Frame delay. Nested counters create a visible pause without a timer.
; Timing depends on MyCPU instruction timing and clock frequency.
; -----------------------------------------------------------------
FrameDelay
         LDA #0x10
         STA DLYOUT
DelayOuter
         LDA #0xFF
         STA DLYIN
DelayInner
         LDA DLYIN
         DECA
         STA DLYIN
         LDA DLYIN
         TEQA #0x00
         JNE DelayInner

         LDA DLYOUT
         DECA
         STA DLYOUT
         LDA DLYOUT
         TEQA #0x00
         JNE DelayOuter
         RTS

; -----------------------------------------------------------------
; Reset vector: reset address 0x8000, matching diag.asm.
; -----------------------------------------------------------------
         ORG/0xFFFE
         DB 0x80
         DB 0x00
