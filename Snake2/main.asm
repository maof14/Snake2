;
; Snake2.asm
;
; Created: 2016-05-18 09:50:16
; Author : Mattias
;

; [En lista med registerdefinitioner]
.DEF rTemp				= r16
.DEF rDirection			= r23

/* [En lista med konstanter] */
.EQU NUM_COLUMNS		= 8
.EQU MAX_LENGTH			= 25

; Definera namn för alla kolumner för att dessa ska bli enkelt att referera till
.EQU COL0_DDR			= DDRD
.EQU COL0_PORT			= PORTD
.EQU COL0_PINOUT		= PD6

.EQU COL1_DDR			= DDRD
.EQU COL1_PORT			= PORTD
.EQU COL1_PINOUT		= PD7

.EQU COL2_DDR			= DDRB
.EQU COL2_PORT			= PORTB
.EQU COL2_PINOUT		= PB0

.EQU COL3_DDR			= DDRB
.EQU COL3_PORT			= PORTB
.EQU COL3_PINOUT		= PB1

.EQU COL4_DDR			= DDRB
.EQU COL4_PORT			= PORTB
.EQU COL4_PINOUT		= PB2

.EQU COL5_DDR			= DDRB
.EQU COL5_PORT			= PORTB
.EQU COL5_PINOUT		= PB3

.EQU COL6_DDR			= DDRB
.EQU COL6_PORT			= PORTB
.EQU COL6_PINOUT		= PB4

.EQU COL7_DDR			= DDRB
.EQU COL7_PORT			= PORTB
.EQU COL7_PINOUT		= PB5

; Definera namn för alla rader. 
.EQU ROW0_DDR			= DDRC
.EQU ROW0_PORT			= PORTC
.EQU ROW0_PINOUT		= PC0

.EQU ROW1_DDR			= DDRC
.EQU ROW1_PORT			= PORTC
.EQU ROW1_PINOUT		= PC1

.EQU ROW2_DDR			= DDRC
.EQU ROW2_PORT			= PORTC
.EQU ROW2_PINOUT		= PC2

.EQU ROW3_DDR			= DDRC
.EQU ROW3_PORT			= PORTC
.EQU ROW3_PINOUT		= PC3

.EQU ROW4_DDR			= DDRD
.EQU ROW4_PORT			= PORTD
.EQU ROW4_PINOUT		= PD2

.EQU ROW5_DDR			= DDRD
.EQU ROW5_PORT			= PORTD
.EQU ROW5_PINOUT		= PD3

.EQU ROW6_DDR			= DDRD
.EQU ROW6_PORT			= PORTD
.EQU ROW6_PINOUT		= PD4

.EQU ROW7_DDR			= DDRD
.EQU ROW7_PORT			= PORTD
.EQU ROW7_PINOUT		= PD5

; [Datasegmentet]
.DSEG
matrix:		.BYTE 8
snake:		.BYTE MAX_LENGTH+1

; [Kodsegmentet]
/* t ex */
.CSEG
// Interrupt vector table
.ORG 0x0000
	jmp init // Reset vector
.ORG 0x0020
	jmp isr_timerOF
.ORG INT_VECTORS_SIZE
init:
	// Sätt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp

; Game loop
main: 

	jmp main

; tick
isr_timerOF:

	reti