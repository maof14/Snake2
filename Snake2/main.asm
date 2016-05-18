;
; Snake2.asm
;
; Created: 2016-05-18 09:50:16
; Author : Mattias
;


; [En lista med registerdefinitioner]
/* t ex */
.DEF rTemp				= r16
.DEF rDirection			= r23
/*…*/

/* [En lista med konstanter] */
/* t ex */
.EQU NUM_COLUMNS		= 8
.EQU MAX_LENGTH			= 25
/* … */
; [Datasegmentet]
/* t ex */
.DSEG
matrix:		.BYTE 8
snake:		.BYTE MAX_LENGTH+1
/* … */
; [Kodsegmentet]
/* t ex */
.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
//... fler interrupts
.ORG INT_VECTORS_SIZE
init:
	// Sätt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp