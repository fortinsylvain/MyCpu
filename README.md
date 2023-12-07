# MyCpu
; -----------------------------------------------------------------
; Homebrew CPU micro code
; Author: Sylvain Fortin
; Date : 1 december 2023
; Documentation : Will be converted into 2 binary file to be 
;                 programmed into 2864 to control the 74LSxx based 
;                 cpu.
; External RAM required to support the microcode
; 0000H - 17FFH Total RAM space
; 0000H - 00FFH Stack
; 0100H - 17EF  Free for application
; 17F0H SP		Stack Pointer 8 bit
; 17F1H temp SP1
; 17F2H temp	SP2
; 17FAH bit<0>	Equal
; 17FBH bit<0>	Carry
; 17FCH A		Register
; 17FEH IPH		Instruction Pointer MSB
; 17FFH IPL		Instruction Pointer LSB
; -----------------------------------------------------------------
