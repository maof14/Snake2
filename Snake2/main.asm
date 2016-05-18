;
; Snake2.asm
;
; Created: 2016-05-18 09:50:16
; Author : Mattias
;

; [En lista med registerdefinitioner]
.DEF rTemp				= r16
.DEF rTemp2				= r17
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

<<<<<<< HEAD
	; Initiering av portar för I/O
	ldi rTemp, 0b11111111	; ettor
	and rTemp2, rTemp		; nollor

	; Sätt alla DDR till output, ettor på allt. 
=======
; Sätt alla I/O-portar till output, ettor i DDR representerar output. 
	ldi rTemp, 0b11111111
>>>>>>> refs/remotes/origin/master
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

<<<<<<< HEAD
	; Två portar på DDRC är joystick X och Y
	cbi DDRC, PC4
	cbi DDRC, PC5

	; Släck alla lampor, sätt nollpå alla portar. 
	out PORTB, rTemp2
	out PORTC, rTemp2
	out PORTD, rTemp2

	; Initieringar av timer och sånt... 

; Game loop
main: 
	
=======
	; Sätter joystickar till input, nolla i DDR representerar input. 
	cbi DDRC, PC4 ; 
	cbi DDRC, PC5 ; DDR klar

	; Avaktiverar alla lampor
	ldi rTemp, 0b00000000 
	out PORTB, rTemp
	out PORTC, rTemp
	out PORTD, rTemp



; Game loop
main: 

;	===================
;		FIRST ROW
;	===================
	sbi ROW0_PORT, ROW0_PINOUT


	cbi ROW0_PORT, ROW0_PINOUT
;	===================
;		SECOND ROW
;	===================

	sbi ROW1_PORT, ROW1_PINOUT


	cbi ROW1_PORT, ROW1_PINOUT

;	===================
;		THIRD ROW
;	===================

	
	sbi ROW2_PORT, ROW2_PINOUT


	cbi ROW2_PORT, ROW2_PINOUT



;	===================
;		FOURTH ROW
;	===================
	
	
	sbi ROW3_PORT, ROW3_PINOUT


	cbi ROW3_PORT, ROW3_PINOUT


;	===================
;		FIFTH ROW
;	===================

	
	sbi ROW4_PORT, ROW4_PINOUT


	cbi ROW4_PORT, ROW4_PINOUT


;	===================
;		SIXTH ROW
;	===================

	
	sbi ROW5_PORT, ROW5_PINOUT


	cbi ROW5_PORT, ROW5_PINOUT



;	===================
;		SEVENTH ROW
;	===================

	
	sbi ROW6_PORT, ROW6_PINOUT


	cbi ROW6_PORT, ROW6_PINOUT


;	===================
;		EIGTH ROW
;	===================

	
	sbi ROW7_PORT, ROW7_PINOUT


	cbi ROW7_PORT, ROW7_PINOUT





>>>>>>> refs/remotes/origin/master
	jmp main
; tick
isr_timerOF:

	reti