; ============================================================================
; MyCpu Tetris V12 - pseudo-random pieces, decimal statistics, 19200 UART
; Based on: MyCpu_Tetris_V6_FastLineAI.asm
; Improved AI search and faster row scoring; hardware timing not yet tested.
; Hardware: UART 0x7400; LEDs 0x7800; LCD commands 0x7C00, data 0x7C01.
; Board: 10 columns x 12 rows, stored at 0x0200 with 16-byte row stride.
; AI: 2 rotations x 10 columns, score row completion and row density.
; V11 changes board addressing and decimal display; test on physical MyCpu.
; Immediate numeric values (e.g. #0x04) remain where assembler lacks
; symbolic 8-bit immediate support. Such values are documented in comments.
; ============================================================================

; MYCPU TETRIS V12 - OPTIMIZED BOARD ADDRESSING / DECIMAL STATS / RANDOM PIECES
; 10x12 board, 16-byte stride, ANSI Tera Term, 19200 8N1
; Evaluate 2 rotations x 10 columns. Prefer complete / nearly complete rows.
; No full-board hole evaluation; temporary placement is undone after scoring.
; -----------------------------------------------------------------------------
; RAM VARIABLES - ascending address order
; -----------------------------------------------------------------------------
POSX             EQU 0x0100  ; Falling/candidate piece X position
POSY             EQU 0x0101  ; Falling/candidate piece Y position
COL              EQU 0x0102  ; Board column index
ROW              EQU 0x0103  ; Board row index
TMP              EQU 0x0104  ; General scratch byte
IDX              EQU 0x0105  ; General loop/index byte
VAL              EQU 0x0106  ; General scratch value
LINES            EQU 0x0107  ; Total cleared rows
TYPE             EQU 0x0108  ; Piece type 0..6
ROT              EQU 0x0109  ; Rotation index
CANDX            EQU 0x010A  ; Candidate X under evaluation
CANDROT          EQU 0x010B  ; Candidate rotation under evaluation
BESTX            EQU 0x010C  ; Chosen candidate X
BESTROT          EQU 0x010D  ; Chosen rotation
BESTY            EQU 0x010E  ; Chosen landing Y
FOUND            EQU 0x010F  ; 1 when a legal candidate was found
SHAPEPTR         EQU 0x0110  ; Pointer to ROM shape data
BLOCKS           EQU 0x0112  ; Remaining shape blocks to process
DX               EQU 0x0113  ; Block horizontal offset
DY               EQU 0x0114  ; Block vertical offset
CELLX            EQU 0x0115  ; Cell X scratch
CELLY            EQU 0x0116  ; Cell Y scratch
SAVEA            EQU 0x0117  ; Save accumulator
DIGIT            EQU 0x0118  ; Decimal digit scratch
TENS             EQU 0x0119  ; Decimal tens scratch
CURCOLOR         EQU 0x011A  ; Current ANSI foreground color
LCDTMP           EQU 0x011B  ; LCD temporary byte
LEDPAT           EQU 0x011C  ; LED activity pattern
SCORE            EQU 0x011D  ; Current candidate score
BESTSCORE        EQU 0x011E  ; Best score so far
SAVEROW          EQU 0x011F  ; Row scan scratch (reserved)
ROWCOUNT         EQU 0x0120  ; Number of occupied cells in evaluated row
TOTAL_LO         EQU 0x0121  ; Cumulative lines, low byte (base 256)
TOTAL_HI         EQU 0x0122  ; Cumulative lines, high byte
GAMES_LO         EQU 0x0123  ; Completed games, low byte
GAMES_HI         EQU 0x0124  ; Completed games, high byte
BEST_LINES       EQU 0x0125  ; Maximum lines completed in one game
ADDR_HI          EQU 0x0126  ; Fast board pointer: high byte (BOARD page)
ADDR_LO          EQU 0x0127  ; Fast board pointer: low byte = ROW*16+COL
DEC_HI           EQU 0x0128  ; Decimal conversion: remaining high byte
DEC_LO           EQU 0x0129  ; Decimal conversion: remaining low byte
DEC_DIGIT        EQU 0x012A  ; Decimal digit being calculated
RNG_STATE        EQU 0x012B  ; Nonzero 8-bit LFSR state
DLYOUT           EQU 0x01D0  ; Outer delay counter
DLYIN            EQU 0x01D1  ; Inner delay counter

; -----------------------------------------------------------------------------
; GAME BOARD - RAM
; -----------------------------------------------------------------------------
BOARD            EQU 0x0200  ; First byte of the Tetris board in RAM

; -----------------------------------------------------------------------------
; MEMORY-MAPPED HARDWARE
; -----------------------------------------------------------------------------
UARTPORT         EQU 0x7400  ; UART transmit port
LEDPORT          EQU 0x7800  ; 8-bit LED latch
LCD_CMD          EQU 0x7C00  ; LCD instruction register
LCD_DATA         EQU 0x7C01  ; LCD character register

; -----------------------------------------------------------------------------
; ROM TEXT AND SHAPE TABLES
; -----------------------------------------------------------------------------
TITLE_TEXT       EQU 0x9000  ; ROM string: program title
HELP_TEXT        EQU 0x9040  ; ROM string: instructions
GAMEOVER_TEXT    EQU 0x9080  ; ROM string: game-over message
STATUS_TEXT      EQU 0x90C0  ; ROM string: terminal status label
LINES_TEXT       EQU 0x9100  ; ROM label for current game line count
STATS_TOTAL_TEXT EQU 0x9140  ; ROM label for cumulative lines
STATS_GAMES_TEXT EQU 0x9180  ; ROM label for completed games
STATS_BEST_TEXT  EQU 0x91C0  ; ROM label for best game
SHAPES           EQU 0x9200  ; ROM table: tetromino shape coordinates
LCD_PIECE_TEXT   EQU 0x9600  ; LCD first-row piece label
LCD_LINES_TEXT   EQU 0x9640  ; LCD second-row line label
LCD_SUFFIX_TEXT  EQU 0x9680  ; LCD second-row suffix
LCD_SEARCH_TEXT  EQU 0x96C0  ; LCD searching label
LCD_OVER_TEXT    EQU 0x9700  ; LCD game-over label

          ORG/0x8000

; -----------------------------------------------------------------------------
; START: Initialize UART, game counters, board, LCD and terminal.
; -----------------------------------------------------------------------------
START
          LDA #0x01
          STA UARTPORT
          CLRA
          STA TOTAL_LO       ; CPU reset: clear persistent counters once
          STA TOTAL_HI
          STA GAMES_LO
          STA GAMES_HI
          STA BEST_LINES
          LDA #0xA5         ; Fixed nonzero seed: no timer/input entropy is exposed
          STA RNG_STATE
          LDX #BOARD
          STX ADDR_HI      ; Initialize the 16-bit pointer in RAM once
          JMP RESET_GAME

; RESET_GAME clears only the current game; persistent counters survive.
RESET_GAME
          CLRA
          STA LINES
          STA TYPE
          JSR CLEAR_BOARD
          JSR LCD_INIT
          JSR LCD_STATUS
          JSR ANSI_CLEAR
          JSR ANSI_HOME
          LDX #TITLE_TEXT
          JSR UART_PRINT
          JSR UART_NEWLINE
          LDX #HELP_TEXT
          JSR UART_PRINT
          JSR UART_NEWLINE

; -----------------------------------------------------------------------------
; NEW_PIECE: Ask AI for a landing position, then animate the selected piece.
; -----------------------------------------------------------------------------
NEW_PIECE
          JSR LCD_SEARCH
          JSR NEXT_PIECE_TYPE
          JSR FIND_BEST
          JSR LCD_STATUS
          LDA FOUND
          TEQA #0x00
          JEQ GAME_END
          LDA BESTX
          STA POSX
          LDA BESTROT
          STA ROT
          CLRA
          STA POSY

; -----------------------------------------------------------------------------
; FALL_LOOP: Display the board, wait, and advance the piece by one row.
; -----------------------------------------------------------------------------
FALL_LOOP
          LDA POSY
          NOTA              ; LED port is active-low: invert the displayed row
          STA LEDPORT
          JSR DRAW_BOARD
          JSR GAME_DELAY
          LDA POSY
          INCA
          STA POSY
          JSR CHECK_PIECE
          TEQA #0x00
          JEQ LOCK_PIECE
          JMP FALL_LOOP

; -----------------------------------------------------------------------------
; LOCK_PIECE: Commit landed piece to RAM board and remove completed rows.
; -----------------------------------------------------------------------------
LOCK_PIECE
          LDA #0xFF     ; All eight LEDs on when a piece locks
          NOTA          ; Active-low LEDs: output 0x00 to turn all on
          STA LEDPORT
          LDA POSY
          DECA
          STA POSY
          JSR PUT_PIECE
          JSR CLEAR_LINES
          JSR LCD_STATUS
          JMP NEW_PIECE

; -----------------------------------------------------------------------------
; NEXT_PIECE_TYPE: Advance an 8-bit maximal-length LFSR and choose TYPE 0..6.
; MyCpu exposes no free-running timer or player input to provide an entropy
; seed, so the fixed 0xA5 seed makes the pseudo-random sequence repeatable.
; The left-shift polynomial is x^8+x^6+x^5+x^4+1 (XOR 0x1D on old bit 7).
; The LFSR visits every nonzero byte. Reject 0xFD..0xFF, leaving 1..252
; (252 states, exactly 36 per piece); subtract one, then reduce modulo seven.
; This rejection step avoids modulo bias for the nonzero LFSR state space.
; Clobbers A and carry; preserves X and all game/statistics variables.
; -----------------------------------------------------------------------------
NEXT_PIECE_TYPE
LFSR_STEP
          LDA RNG_STATE
          SLLA
          JRNC LFSR_NO_TAP
          XORA #0x1D
LFSR_NO_TAP
          STA RNG_STATE
          CMPA #0xFD
          JRUGE LFSR_STEP
          DECA              ; Map accepted states 1..252 to values 0..251
LFSR_MOD7
          CMPA #0x07
          JRNC LFSR_DONE
          ADDA #0xF9        ; Add -7 modulo 256
          JMP LFSR_MOD7
LFSR_DONE
          STA TYPE
          RTS

; -----------------------------------------------------------------------------
; GAME_END: Display game over, pause, then restart the program.
; -----------------------------------------------------------------------------
GAME_END
          JSR RECORD_GAME     ; Update best score and completed-game count
          JSR LCD_GAMEOVER
          JSR DRAW_BOARD
          LDX #GAMEOVER_TEXT
          JSR UART_PRINT
          JSR GAME_DELAY
          JSR GAME_DELAY
          JMP RESET_GAME     ; Do not reset cumulative statistics

; RECORD_GAME: called exactly once for each finished game.
; BEST_LINES is an unsigned 8-bit value, matching LINES.
; GAMES_HI:GAMES_LO is a 16-bit count of completed games.
RECORD_GAME
          LDA LINES
          CMPA BEST_LINES
          JRUGE RECORD_BEST
          JMP RECORD_COUNT
RECORD_BEST
          STA BEST_LINES
RECORD_COUNT
          LDA GAMES_LO
          INCA
          STA GAMES_LO
          TEQA #0x00         ; Increment high byte on low-byte overflow
          JNE RECORD_DONE
          LDA GAMES_HI
          INCA
          STA GAMES_HI
RECORD_DONE
          RTS

; FAST SEARCH: two rotations and all ten columns (0..9).
; For each candidate, drop virtually until collision, keeping deepest landing.

; -----------------------------------------------------------------------------
; FIND_BEST: Evaluate twenty candidate landings (2 rotations x 10 columns).
; -----------------------------------------------------------------------------
FIND_BEST
          CLRA
          STA FOUND
          STA CANDROT

; -----------------------------------------------------------------------------
; SEARCH_ROT: Begin evaluating a rotation.
; -----------------------------------------------------------------------------
SEARCH_ROT
          CLRA
          STA CANDX

; -----------------------------------------------------------------------------
; SEARCH_X: Select the candidate X and rotation, then check spawn legality.
; -----------------------------------------------------------------------------
SEARCH_X
          LDA CANDX
          ORA #0x80    ; Set LED high bit as search activity indicator
          NOTA          ; Active-low port: invert logical indicator/column bits
          STA LEDPORT
          LDA CANDX
          STA POSX
          LDA CANDROT
          STA ROT
          CLRA
          STA POSY
          JSR CHECK_PIECE
          TEQA #0x00
          JEQ NEXT_X

; -----------------------------------------------------------------------------
; TRY_DOWN: Simulate gravity until the next step would collide.
; -----------------------------------------------------------------------------
TRY_DOWN
          LDA POSY
          INCA
          STA POSY
          JSR CHECK_PIECE
          TEQA #0x00
          JEQ CAND_LANDED
          JMP TRY_DOWN

; -----------------------------------------------------------------------------
; CAND_LANDED: Score the last legal position of this candidate.
; -----------------------------------------------------------------------------
CAND_LANDED
          LDA POSY
          DECA
          STA POSY
; Temporarily place four blocks, test only their rows, then undo.
          JSR SCORE_CANDIDATE
          LDA FOUND
          TEQA #0x00
          JEQ NEW_BEST
          LDA SCORE
          CMPA BESTSCORE
          JRUGE SCORE_GE
          JMP NEXT_X
SCORE_GE
          TEQA BESTSCORE
          JNE NEW_BEST
          LDA POSY
          CMPA BESTY
          JRUGE NEW_BEST
          JMP NEXT_X

; -----------------------------------------------------------------------------
; NEW_BEST: Remember the highest scoring candidate and its landing position.
; -----------------------------------------------------------------------------
NEW_BEST
          LDA #0x01
          STA FOUND
          LDA SCORE
          STA BESTSCORE
          LDA POSY
          STA BESTY
          LDA CANDX
          STA BESTX
          LDA CANDROT
          STA BESTROT

; -----------------------------------------------------------------------------
; NEXT_X: Move to the next column; then the next rotation.
; -----------------------------------------------------------------------------
NEXT_X
          LDA CANDX
          INCA
          STA CANDX
          TEQA #0x0A
          JNE SEARCH_X
          LDA CANDROT
          INCA
          STA CANDROT
          TEQA #0x02
          JEQ SEARCH_DONE
          JMP SEARCH_ROT
SEARCH_DONE
          RTS
 ; SCORE_CANDIDATE
;   Temporarily place candidate blocks on board, then examine each of the
;   four block rows. Scan a row by computing its base address ONCE and
;   advancing X sequentially: much cheaper than CELL_ADDRESS per cell.
;   Each full row contributes 32 points per touched block, while a row
;   with 8 or 9 occupied cells contributes 4 points per touched block.
;   The score also includes landing depth (POSY).
;   The board is restored before returning.  Max score = 139.
;   Note: repeated rows are intentionally counted multiple times.
; -----------------------------------------------------------------------------
SCORE_CANDIDATE
          LDA POSY
          STA SCORE
          JSR PUT_PIECE
          JSR SHAPE_START
          LDA #0x04      ; Four blocks per tetromino
          STA BLOCKS

SCORE_BLOCK
          LDX SHAPEPTR
          INCX           ; Skip the block X coordinate
          LDA (X)        ; Read block Y coordinate
          STA DY
          INCX
          STX SHAPEPTR
          LDA POSY
          ADDA DY
          STA ROW
          CLRA
          STA COL
          STA ROWCOUNT
          JSR CELL_ADDRESS  ; X = start of candidate's row

SCORE_COL
          LDA (X)
          TEQA #0x00
          JEQ SCORE_EMPTY
          LDA ROWCOUNT
          INCA
          STA ROWCOUNT
SCORE_EMPTY
          INCX           ; Scan next cell without recomputing row address
          LDA COL
          INCA
          STA COL
          TEQA #0x0A    ; Ten playable cells per row
          JNE SCORE_COL

          LDA ROWCOUNT
          TEQA #0x0A    ; All ten cells occupied: completed row
          JEQ SCORE_FULL
          CMPA #0x08    ; 8 or 9 cells: useful nearly full row
          JRUGE SCORE_NEAR
          JMP SCORE_NEXT_BLOCK
SCORE_FULL
          LDA SCORE
          ADDA #0x20   ; Strong line-clear reward (+32)
          STA SCORE
          JMP SCORE_NEXT_BLOCK
SCORE_NEAR
          LDA SCORE
          ADDA #0x04   ; Small reward for 8/9 occupied cells
          STA SCORE
SCORE_NEXT_BLOCK
          LDA BLOCKS
          DECA
          STA BLOCKS
          JNE SCORE_BLOCK
          JSR ERASE_PIECE
          RTS
; Undo temporary piece. Safe because only legal empty cells were written.

; -----------------------------------------------------------------------------
; ERASE_PIECE: Undo the candidate placement so the board is unchanged.
; -----------------------------------------------------------------------------
ERASE_PIECE
          JSR SHAPE_START
          LDA #0x04
          STA BLOCKS
ERASE_BLOCK
          LDX SHAPEPTR
          LDA (X)
          STA DX
          INCX
          LDA (X)
          STA DY
          INCX
          STX SHAPEPTR
          LDA POSX
          ADDA DX
          STA COL
          LDA POSY
          ADDA DY
          STA ROW
          JSR CELL_ADDRESS
          CLRA
          STA (X)
          LDA BLOCKS
          DECA
          STA BLOCKS
          JNE ERASE_BLOCK
          RTS
; Each shape consists of 4 blocks, each with X,Y offsets.
; Each rotation occupies 8 bytes, each piece occupies 32 bytes.
; SHAPES is at a fixed ROM address; compute index TYPE*32+ROT*8.

; -----------------------------------------------------------------------------
; SHAPE_START: Locate TYPE and ROT data in ROM shape table.
; -----------------------------------------------------------------------------
SHAPE_START
          LDX #SHAPES
          LDA TYPE
          STA TMP
SHAPE_TYPE_LOOP
          LDA TMP
          TEQA #0x00
          JEQ SHAPE_ROT_START
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          LDA TMP
          DECA
          STA TMP
          JMP SHAPE_TYPE_LOOP
SHAPE_ROT_START
          LDA ROT
          STA TMP
SHAPE_ROT_LOOP
          LDA TMP
          TEQA #0x00
          JEQ SHAPE_READY
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          INCX
          LDA TMP
          DECA
          STA TMP
          JMP SHAPE_ROT_LOOP
SHAPE_READY
          STX SHAPEPTR
          RTS
; Check current shape at POSX,POSY. Return A=1 valid, 0 blocked.

; -----------------------------------------------------------------------------
; CHECK_PIECE: Test four blocks for collisions; return A=1 or A=0.
; -----------------------------------------------------------------------------
CHECK_PIECE
          JSR SHAPE_START
          LDA #0x04
          STA BLOCKS
CHECK_BLOCK
          LDX SHAPEPTR
          LDA (X)
          STA DX
          INCX
          LDA (X)
          STA DY
          INCX
          STX SHAPEPTR
          LDA POSX
          ADDA DX
          STA COL
          LDA POSY
          ADDA DY
          STA ROW
          JSR GET_CELL
          TEQA #0x00
          JEQ PIECE_BLOCKED
          LDA BLOCKS
          DECA
          STA BLOCKS
          JNE CHECK_BLOCK
          LDA #0x01
          RTS
PIECE_BLOCKED
          CLRA
          RTS

; -----------------------------------------------------------------------------
; PUT_PIECE: Write all four blocks of the current piece to board RAM.
; -----------------------------------------------------------------------------
PUT_PIECE
          JSR SHAPE_START
          LDA #0x04
          STA BLOCKS
PUT_BLOCK
          LDX SHAPEPTR
          LDA (X)
          STA DX
          INCX
          LDA (X)
          STA DY
          INCX
          STX SHAPEPTR
          LDA POSX
          ADDA DX
          STA COL
          LDA POSY
          ADDA DY
          STA ROW
          JSR CELL_ADDRESS
          LDA TYPE
          INCA
          STA (X)
          LDA BLOCKS
          DECA
          STA BLOCKS
          JNE PUT_BLOCK
          RTS

; -----------------------------------------------------------------------------
; GET_CELL: Read a board cell, accounting for board bounds.
; -----------------------------------------------------------------------------
GET_CELL
          LDA ROW
          CMPA #0x0C
          JRUGE CELL_BLOCKED
          LDA COL
          CMPA #0x0A
          JRUGE CELL_BLOCKED
          JSR CELL_ADDRESS
          LDA (X)
          TEQA #0x00
          JNE CELL_BLOCKED
          LDA #0x01
          RTS
CELL_BLOCKED
          CLRA
          RTS

 ; -----------------------------------------------------------------------------
; CELL_ADDRESS: Fast board address calculation.
;
; Input: ROW (0..11), COL (0..9).
; Output: X = BOARD + ROW*16 + COL.
; Board is 0x0200..0x02BF, so the high address byte stays 0x02.
; ADDR_HI:ADDR_LO was initialized by STX #BOARD in START.
; No loop and no repeated INCX instructions: four shifts + one add.
; X is loaded from the two consecutive RAM bytes of the pointer.
; The caller must ensure ROW and COL are within the board.
; -----------------------------------------------------------------------------
CELL_ADDRESS
          LDA ROW
          SLLA              ; Multiply row by 2
          SLLA              ; Multiply row by 4
          SLLA              ; Multiply row by 8
          SLLA              ; Multiply row by 16 (ROW_STRIDE)
          ADDA COL          ; Add column offset; max result = 185
          STA ADDR_LO       ; Update low byte of board pointer
          LDX ADDR_HI       ; Load complete 16-bit pointer into X
          RTS

; -----------------------------------------------------------------------------
; CLEAR_BOARD: Reset the 10x12 playfield in RAM.
; -----------------------------------------------------------------------------
CLEAR_BOARD
          LDX #BOARD      ; Board base address, defined once in EQU section
          LDA #0xC0
          STA IDX
CLEAR_BOARD_LOOP
          CLRA
          STA (X)
          INCX
          LDA IDX
          DECA
          STA IDX
          JNE CLEAR_BOARD_LOOP
          RTS

; -----------------------------------------------------------------------------
; CLEAR_LINES: Detect full rows, shift rows down, increment LINES.
; -----------------------------------------------------------------------------
CLEAR_LINES
          LDA #0x0B
          STA ROW
SCAN_ROW
          CLRA
          STA COL
          STA VAL
SCAN_COL
          JSR CELL_ADDRESS
          LDA (X)
          TEQA #0x00
          JEQ SCAN_NEXT
          LDA VAL
          INCA
          STA VAL
SCAN_NEXT
          LDA COL
          INCA
          STA COL
          TEQA #0x0A
          JNE SCAN_COL
          LDA VAL
          TEQA #0x0A
          JEQ ROW_FULL
          LDA ROW
          TEQA #0x00
          JEQ CLEAR_DONE
          DECA
          STA ROW
          JMP SCAN_ROW
ROW_FULL
          LDA LINES
          INCA
          STA LINES
          LDA TOTAL_LO      ; Count every completed row across all games
          INCA
          STA TOTAL_LO
          TEQA #0x00        ; Carry into the high byte on wraparound
          JNE SHIFT_ROW
          LDA TOTAL_HI
          INCA
          STA TOTAL_HI
SHIFT_ROW
          LDA ROW
          TEQA #0x00
          JEQ ZERO_TOP
          CLRA
          STA COL
SHIFT_COL
          LDA ROW
          DECA
          STA ROW
          JSR CELL_ADDRESS
          LDA (X)
          STA VAL
          LDA ROW
          INCA
          STA ROW
          JSR CELL_ADDRESS
          LDA VAL
          STA (X)
          LDA COL
          INCA
          STA COL
          TEQA #0x0A
          JNE SHIFT_COL
          LDA ROW
          DECA
          STA ROW
          JMP SHIFT_ROW
ZERO_TOP
          CLRA
          STA COL
ZERO_COL
          JSR CELL_ADDRESS
          CLRA
          STA (X)
          LDA COL
          INCA
          STA COL
          TEQA #0x0A
          JNE ZERO_COL
          LDA #0x0B
          STA ROW
          JMP SCAN_ROW
CLEAR_DONE
          RTS

; -----------------------------------------------------------------------------
; DRAW_BOARD: Render playfield and current piece to Tera Term.
; -----------------------------------------------------------------------------
DRAW_BOARD
          JSR ANSI_BOARD_POS
          LDA #0xFF
          STA CURCOLOR
          CLRA
          JSR SET_COLOR_A
          CLRA
          STA ROW
DRAW_ROW
          CLRA
          JSR SET_COLOR_A
          LDA #0x7C
          JSR UART_TX
          CLRA
          STA COL
DRAW_COL
          JSR CELL_ADDRESS
          LDA (X)
          TEQA #0x00
          JNE DRAW_LOCKED
; Empty board cell: check whether the falling piece occupies it.
          JSR SHAPE_START
          LDA #0x04
          STA BLOCKS
DRAW_CHECK_BLOCK
          LDX SHAPEPTR
          LDA (X)
          STA DX
          INCX
          LDA (X)
          STA DY
          INCX
          STX SHAPEPTR
          LDA POSX
          ADDA DX
          TEQA COL
          JNE DRAW_NEXT_BLOCK
          LDA POSY
          ADDA DY
          TEQA ROW
          JEQ DRAW_FALLING
DRAW_NEXT_BLOCK
          LDA BLOCKS
          DECA
          STA BLOCKS
          JNE DRAW_CHECK_BLOCK
          CLRA
          JSR SET_COLOR_A
          LDA #0x20
          JSR UART_TX
          JMP DRAW_NEXT
DRAW_FALLING
          LDA TYPE
          INCA
          JMP DRAW_COLORED
DRAW_LOCKED
; Board cells store the original piece identity (1..7).
          JSR CELL_ADDRESS
          LDA (X)
DRAW_COLORED
          JSR SET_COLOR_A
          LDA #0x23
          JSR UART_TX
DRAW_NEXT
          LDA COL
          INCA
          STA COL
          TEQA #0x0A
          JNE DRAW_COL
          CLRA
          JSR SET_COLOR_A
          LDA #0x7C
          JSR UART_TX
          JSR UART_NEWLINE
          LDA ROW
          INCA
          STA ROW
          TEQA #0x0C
          JNE DRAW_ROW
          LDX #STATUS_TEXT
          JSR UART_PRINT
          JSR UART_NEWLINE
          LDX #LINES_TEXT
          JSR UART_PRINT
          LDA LINES
          STA DIGIT
          CLRA
          STA TENS
LINE_TENS_LOOP
          LDA DIGIT
          CMPA #0x0A
          JRUGE LINE_SUB_TEN
          JMP LINE_DIGITS
LINE_SUB_TEN
          ADDA #0xF6
          STA DIGIT
          LDA TENS
          INCA
          STA TENS
          JMP LINE_TENS_LOOP
LINE_DIGITS
          LDA TENS
          ADDA #0x30
          JSR UART_TX
          LDA DIGIT
          ADDA #0x30
          JSR UART_TX
          CLRA
          JSR SET_COLOR_A
          JSR UART_NEWLINE
          JSR DRAW_STATS     ; Print cumulative values below the board
          RTS
; A=0 for default text, 1..7 for piece colors (ANSI 31..37).
; Emit escape sequence only when color changes.

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; DRAW_STATS: Print persistent counters in decimal (not hexadecimal).
; Counters are unchanged; only the UART presentation is different.
; Output is fixed-width decimal: TOTAL=00010 GAMES=00005 BEST=00002.
; UART_DEC16 supports the complete unsigned 16-bit range (0..65535).
; -----------------------------------------------------------------------------
DRAW_STATS
          LDX #STATS_TOTAL_TEXT
          JSR UART_PRINT
          LDA TOTAL_HI
          STA DEC_HI
          LDA TOTAL_LO
          STA DEC_LO
          JSR UART_DEC16
          LDX #STATS_GAMES_TEXT
          JSR UART_PRINT
          LDA GAMES_HI
          STA DEC_HI
          LDA GAMES_LO
          STA DEC_LO
          JSR UART_DEC16
          LDX #STATS_BEST_TEXT
          JSR UART_PRINT
          CLRA
          STA DEC_HI
          LDA BEST_LINES
          STA DEC_LO
          JSR UART_DEC16
          JSR UART_NEWLINE
          RTS

; UART_DEC16: Print unsigned 16-bit DEC_HI:DEC_LO in base 10.
; Repeatedly subtract each decimal place (10000,1000,100,10,1),
; counting at most nine subtractions per place. No division needed.
UART_DEC16
          JSR DEC_PLACE_10000
          JSR DEC_PLACE_1000
          JSR DEC_PLACE_100
          JSR DEC_PLACE_10
          JSR DEC_PLACE_1
          RTS

; Decimal place 10000: compare remaining value, subtract while >= 10000.
DEC_PLACE_10000
          CLRA
          STA DEC_DIGIT
DEC_10000_LOOP
          LDA DEC_HI
          CMPA #0x27       ; High byte of 10000
          JRUGE DEC_10000_HI_OK
          JMP DEC_10000_PRINT
DEC_10000_HI_OK
          TEQA #0x27
          JNE DEC_10000_SUB
          LDA DEC_LO
          CMPA #0x10       ; Low byte of 10000
          JRUGE DEC_10000_SUB
          JMP DEC_10000_PRINT
DEC_10000_SUB
          LDA DEC_LO
          CMPA #0x10       ; Detect low-byte borrow
          JRUGE DEC_10000_NO_BORROW
          LDA DEC_HI
          DECA
          STA DEC_HI
DEC_10000_NO_BORROW
          LDA DEC_LO
          ADDA #0xF0       ; Subtract low byte, modulo 256
          STA DEC_LO
          LDA DEC_HI
          ADDA #0xD9       ; Subtract high byte
          STA DEC_HI
          LDA DEC_DIGIT
          INCA
          STA DEC_DIGIT
          JMP DEC_10000_LOOP
DEC_10000_PRINT
          LDA DEC_DIGIT
          ADDA #0x30       ; ASCII '0'
          JSR UART_TX
          RTS

; Decimal place 1000: compare remaining value, subtract while >= 1000.
DEC_PLACE_1000
          CLRA
          STA DEC_DIGIT
DEC_1000_LOOP
          LDA DEC_HI
          CMPA #0x03       ; High byte of 1000
          JRUGE DEC_1000_HI_OK
          JMP DEC_1000_PRINT
DEC_1000_HI_OK
          TEQA #0x03
          JNE DEC_1000_SUB
          LDA DEC_LO
          CMPA #0xE8       ; Low byte of 1000
          JRUGE DEC_1000_SUB
          JMP DEC_1000_PRINT
DEC_1000_SUB
          LDA DEC_LO
          CMPA #0xE8       ; Detect low-byte borrow
          JRUGE DEC_1000_NO_BORROW
          LDA DEC_HI
          DECA
          STA DEC_HI
DEC_1000_NO_BORROW
          LDA DEC_LO
          ADDA #0x18       ; Subtract low byte, modulo 256
          STA DEC_LO
          LDA DEC_HI
          ADDA #0xFD       ; Subtract high byte
          STA DEC_HI
          LDA DEC_DIGIT
          INCA
          STA DEC_DIGIT
          JMP DEC_1000_LOOP
DEC_1000_PRINT
          LDA DEC_DIGIT
          ADDA #0x30       ; ASCII '0'
          JSR UART_TX
          RTS

; Decimal place 100: compare remaining value, subtract while >= 100.
DEC_PLACE_100
          CLRA
          STA DEC_DIGIT
DEC_100_LOOP
          LDA DEC_HI
          CMPA #0x00       ; High byte of 100
          JRUGE DEC_100_HI_OK
          JMP DEC_100_PRINT
DEC_100_HI_OK
          TEQA #0x00
          JNE DEC_100_SUB
          LDA DEC_LO
          CMPA #0x64       ; Low byte of 100
          JRUGE DEC_100_SUB
          JMP DEC_100_PRINT
DEC_100_SUB
          LDA DEC_LO
          CMPA #0x64       ; Detect low-byte borrow
          JRUGE DEC_100_NO_BORROW
          LDA DEC_HI
          DECA
          STA DEC_HI
DEC_100_NO_BORROW
          LDA DEC_LO
          ADDA #0x9C       ; Subtract low byte, modulo 256
          STA DEC_LO
          LDA DEC_HI
          ADDA #0x00       ; Subtract high byte
          STA DEC_HI
          LDA DEC_DIGIT
          INCA
          STA DEC_DIGIT
          JMP DEC_100_LOOP
DEC_100_PRINT
          LDA DEC_DIGIT
          ADDA #0x30       ; ASCII '0'
          JSR UART_TX
          RTS

; Decimal place 10: compare remaining value, subtract while >= 10.
DEC_PLACE_10
          CLRA
          STA DEC_DIGIT
DEC_10_LOOP
          LDA DEC_HI
          CMPA #0x00       ; High byte of 10
          JRUGE DEC_10_HI_OK
          JMP DEC_10_PRINT
DEC_10_HI_OK
          TEQA #0x00
          JNE DEC_10_SUB
          LDA DEC_LO
          CMPA #0x0A       ; Low byte of 10
          JRUGE DEC_10_SUB
          JMP DEC_10_PRINT
DEC_10_SUB
          LDA DEC_LO
          CMPA #0x0A       ; Detect low-byte borrow
          JRUGE DEC_10_NO_BORROW
          LDA DEC_HI
          DECA
          STA DEC_HI
DEC_10_NO_BORROW
          LDA DEC_LO
          ADDA #0xF6       ; Subtract low byte, modulo 256
          STA DEC_LO
          LDA DEC_HI
          ADDA #0x00       ; Subtract high byte
          STA DEC_HI
          LDA DEC_DIGIT
          INCA
          STA DEC_DIGIT
          JMP DEC_10_LOOP
DEC_10_PRINT
          LDA DEC_DIGIT
          ADDA #0x30       ; ASCII '0'
          JSR UART_TX
          RTS

; Decimal place 1: compare remaining value, subtract while >= 1.
DEC_PLACE_1
          CLRA
          STA DEC_DIGIT
DEC_1_LOOP
          LDA DEC_HI
          CMPA #0x00       ; High byte of 1
          JRUGE DEC_1_HI_OK
          JMP DEC_1_PRINT
DEC_1_HI_OK
          TEQA #0x00
          JNE DEC_1_SUB
          LDA DEC_LO
          CMPA #0x01       ; Low byte of 1
          JRUGE DEC_1_SUB
          JMP DEC_1_PRINT
DEC_1_SUB
          LDA DEC_LO
          CMPA #0x01       ; Detect low-byte borrow
          JRUGE DEC_1_NO_BORROW
          LDA DEC_HI
          DECA
          STA DEC_HI
DEC_1_NO_BORROW
          LDA DEC_LO
          ADDA #0xFF       ; Subtract low byte, modulo 256
          STA DEC_LO
          LDA DEC_HI
          ADDA #0x00       ; Subtract high byte
          STA DEC_HI
          LDA DEC_DIGIT
          INCA
          STA DEC_DIGIT
          JMP DEC_1_LOOP
DEC_1_PRINT
          LDA DEC_DIGIT
          ADDA #0x30       ; ASCII '0'
          JSR UART_TX
          RTS

; UART_HEX_BYTE: print A as two hexadecimal digits.
; LCDTMP holds the original byte while the high nibble is printed.
UART_HEX_BYTE
          STA LCDTMP
          SRLA
          SRLA
          SRLA
          SRLA
          JSR UART_HEX_DIGIT
          LDA LCDTMP
          JSR UART_HEX_DIGIT
          RTS

; UART_HEX_DIGIT: print low nibble of A as 0..9 or A..F.
UART_HEX_DIGIT
          ANDA #0x0F
          CMPA #0x0A
          JRUGE UART_HEX_LETTER
          ADDA #0x30       ; ASCII digit '0' offset
          JSR UART_TX
          RTS
UART_HEX_LETTER
          ADDA #0x37       ; ASCII letter 'A' offset
          JSR UART_TX
          RTS

; SET_COLOR_A: Set ANSI color only when different from current color.
; -----------------------------------------------------------------------------
SET_COLOR_A
          STA SAVEA
          TEQA CURCOLOR
          JEQ COLOR_DONE
          LDA SAVEA
          STA CURCOLOR
          LDA #0x1B
          JSR UART_TX
          LDA #0x5B
          JSR UART_TX
          LDA SAVEA
          TEQA #0x00
          JEQ COLOR_DEFAULT
          LDA #0x33
          JSR UART_TX
          LDA SAVEA
          ADDA #0x30
          JSR UART_TX
          JMP COLOR_END
COLOR_DEFAULT
          LDA #0x30
          JSR UART_TX
COLOR_END
          LDA #0x6D
          JSR UART_TX
COLOR_DONE
          RTS
ANSI_CLEAR
          LDA #0x1B
          JSR UART_TX
          LDA #0x5B
          JSR UART_TX
          LDA #0x32
          JSR UART_TX
          LDA #0x4A
          JSR UART_TX
          RTS
ANSI_HOME
          LDA #0x1B
          JSR UART_TX
          LDA #0x5B
          JSR UART_TX
          LDA #0x48
          JSR UART_TX
          RTS
ANSI_BOARD_POS
          LDA #0x1B
          JSR UART_TX
          LDA #0x5B
          JSR UART_TX
          LDA #0x33
          JSR UART_TX
          LDA #0x3B
          JSR UART_TX
          LDA #0x31
          JSR UART_TX
          LDA #0x48
          JSR UART_TX
          RTS

; -----------------------------------------------------------------------------
; UART_PRINT: Send a zero-terminated ROM string over UART.
; -----------------------------------------------------------------------------
UART_PRINT
UART_PRINT_NEXT
          LDA (X)
          TEQA #0x00
          JEQ UART_PRINT_DONE
          JSR UART_TX
          INCX
          JMP UART_PRINT_NEXT
UART_PRINT_DONE
          RTS

; -----------------------------------------------------------------------------
; UART_NEWLINE: Send carriage return and line feed.
; -----------------------------------------------------------------------------
UART_NEWLINE
          LDA #0x0D
          JSR UART_TX
          LDA #0x0A
          JSR UART_TX
          RTS
; LCD dashboard. LCD command/data are memory-mapped.
; The short delay loops follow the proven diagnostic program.

; -----------------------------------------------------------------------------
; LCD_INIT: Initialize LCD controller and clear its display.
; -----------------------------------------------------------------------------
LCD_INIT
          LDA #0xFF
LCD_POWER_WAIT
          DECA
          JNE LCD_POWER_WAIT
          LDA #0x38
          STA LCD_CMD
          LDA #0xF0
LCD_INIT_WAIT
          DECA
          JNE LCD_INIT_WAIT
          LDA #0x0C
          STA LCD_CMD
          LDA #0x06
          STA LCD_CMD
          LDA #0x01
          STA LCD_CMD
          JSR LCD_CLEAR_WAIT
          RTS
LCD_CLEAR_WAIT
          LDA #0xFF
LCD_CLEAR_LOOP
          DECA
          JNE LCD_CLEAR_LOOP
          RTS
LCD_ROW1
          LDA #0x80
          STA LCD_CMD
          RTS
LCD_ROW2
          LDA #0xC0
          STA LCD_CMD
          RTS
; Print a zero-terminated ROM string using X.
LCD_PRINT
          LDA (X)
          TEQA #0x00
          JEQ LCD_PRINT_DONE
          STA LCD_DATA
          INCX
          JMP LCD_PRINT
LCD_PRINT_DONE
          RTS
; Print one hex digit from A, preserving neither A nor X.
LCD_HEX_DIGIT
          ANDA #0x0F
          CMPA #0x0A
          JRUGE LCD_HEX_LETTER
          ADDA #0x30
          STA LCD_DATA
          RTS
LCD_HEX_LETTER
          ADDA #0x37
          STA LCD_DATA
          RTS
LCD_HEX_BYTE
          STA LCDTMP
          SRLA
          SRLA
          SRLA
          SRLA
          JSR LCD_HEX_DIGIT
          LDA LCDTMP
          JSR LCD_HEX_DIGIT
          RTS
; Show current piece number 0..6 and total lines as two hex digits.

; -----------------------------------------------------------------------------
; LCD_STATUS: Show piece identity and cleared line count on LCD.
; -----------------------------------------------------------------------------
LCD_STATUS
          JSR LCD_ROW1
          LDX #LCD_PIECE_TEXT
          JSR LCD_PRINT
          LDA TYPE
          ADDA #0x31
          STA LCD_DATA
          JSR LCD_ROW2
          LDX #LCD_LINES_TEXT
          JSR LCD_PRINT
          LDA LINES
          JSR LCD_HEX_BYTE
          LDX #LCD_SUFFIX_TEXT
          JSR LCD_PRINT
          RTS

; -----------------------------------------------------------------------------
; LCD_SEARCH: Show search activity while AI computes.
; -----------------------------------------------------------------------------
LCD_SEARCH
          JSR LCD_ROW1
          LDX #LCD_SEARCH_TEXT
          JSR LCD_PRINT
          RTS

; -----------------------------------------------------------------------------
; LCD_GAMEOVER: Show game-over message on LCD.
; -----------------------------------------------------------------------------
LCD_GAMEOVER
          JSR LCD_ROW1
          LDX #LCD_OVER_TEXT
          JSR LCD_PRINT
          RTS

; -----------------------------------------------------------------------------
; GAME_DELAY: Visible animation delay (separate from UART bit timing).
; -----------------------------------------------------------------------------
GAME_DELAY
          LDA #0x02
          STA DLYOUT
DELAY_OUTER
          LDA #0x20
          STA DLYIN
DELAY_INNER
          LDA DLYIN
          DECA
          STA DLYIN
          JNE DELAY_INNER
          LDA DLYOUT
          DECA
          STA DLYOUT
          JNE DELAY_OUTER
          RTS
; ----------------------------------------------------------------------------
; UART_TX: 19200 baud (5 MHz MyCpu), measured on oscilloscope.
; UARTPORT uses bit 0. STA preserves Carry, allowing SLLA/RRCA to
; generate the start bit and restore the original byte without the stack.
; Target bit period: 52.083 us.
; Measured start bit: 52.8 us; data bits 0..6: 52.6 us;
; measured data bit 7: 58.8 us (after removing final SRLA).
; Stop-bit duration has not yet been measured.
; On return A is changed; X is not modified by this routine.
; ----------------------------------------------------------------------------
UART_TX
          SLLA            ; A0=0, original A7 -> Carry
          STA UARTPORT    ; Start bit LOW
          RRCA            ; Restore original byte from Carry
          STA UARTPORT    ; Data bit 0
          SRLA
          STA UARTPORT    ; Data bit 1
          SRLA
          STA UARTPORT    ; Data bit 2
          SRLA
          STA UARTPORT    ; Data bit 3
          SRLA
          STA UARTPORT    ; Data bit 4
          SRLA
          STA UARTPORT    ; Data bit 5
          SRLA
          STA UARTPORT    ; Data bit 6
          SRLA
          STA UARTPORT    ; Data bit 7
          LDA #0x01       ; Stop/idle level HIGH
          STA UARTPORT    ; Stop bit
          RTS
          ORG/0x9000
          .ASCII "MYCPU TETRIS V12 FAST AI"
          ORG/0x9040
          .ASCII "7 PIECES / 10x12 / FAST AI"
          ORG/0x9080
          .ASCII " GAME OVER - RESTARTING "
          ORG/0x90C0  ; STATUS_TEXT ROM location
          .ASCII "+----------+"
          ORG/0x9100
          .ASCII "LINES: "
          ORG/0x9140
          .ASCII " TOTAL="
          ORG/0x9180
          .ASCII " GAMES="
          ORG/0x91C0
          .ASCII " BEST="
          ORG/0x9200
; I rotation 0
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x03
          DB 0x00
; I rotation 1
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x03
; I rotation 2
          DB 0x03
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; I rotation 3
          DB 0x00
          DB 0x03
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
; O rotation 0
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
; O rotation 1
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
; O rotation 2
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; O rotation 3
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
; T rotation 0
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x01
; T rotation 1
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
; T rotation 2
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; T rotation 3
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
; L rotation 0
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x01
          DB 0x02
; L rotation 1
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
; L rotation 2
          DB 0x01
          DB 0x02
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; L rotation 3
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x01
          DB 0x02
          DB 0x00
; J rotation 0
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x01
          DB 0x02
; J rotation 1
          DB 0x02
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
; J rotation 2
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; J rotation 3
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x01
          DB 0x02
          DB 0x00
; S rotation 0
          DB 0x01
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
; S rotation 1
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x00
          DB 0x00
          DB 0x00
          DB 0x01
; S rotation 2
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x00
; S rotation 3
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x02
          DB 0x01
          DB 0x01
; Z rotation 0
          DB 0x00
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x02
          DB 0x01
; Z rotation 1
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x01
          DB 0x00
          DB 0x02
; Z rotation 2
          DB 0x02
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
          DB 0x00
          DB 0x00
; Z rotation 3
          DB 0x00
          DB 0x02
          DB 0x00
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x01
          DB 0x00
          ORG/0x9600
          .ASCII "PIECE: "
          ORG/0x9640
          .ASCII "LINES: "
          ORG/0x9680
          .ASCII " HEX  "
          ORG/0x96C0
          .ASCII "AI SEARCH...    "
          ORG/0x9700
          .ASCII "GAME OVER       "
          ORG/0xFFFE
          DB 0x80
          DB 0x00
