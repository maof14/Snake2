;
; Snake2.asm
;
; Created: 2016-05-18 09:50:16
; Author : Mattias
;

; [En lista med registerdefinitioner]
.DEF rTemp				= r16
.DEF rTemp2				= r17
.DEF rPORTB				= r18
.DEF rPORTC				= r19
.DEF rPORTD				= r20
.DEF rSnake				= r21
;.DEF rMellan2			= r22
.DEF rDirectionX		= r23
.DEF rDirectionY		= r24

/* [En lista med konstanter] */
.EQU NUM_COLUMNS		= 8
.EQU MAX_LENGTH			= 25

; Definera namn får alla kolumner får att dessa ska bli enkelt att referera till
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
	// SÃ¤tt stackpekaren till högsta minnesadressen
	ldi rTemp, HIGH(RAMEND)
	out SPH, rTemp
	ldi rTemp, LOW(RAMEND)
	out SPL, rTemp

	; Initiering av portar får I/O
	ldi rTemp, 0b11111111	; ettor
	and rTemp2, rTemp		; nollor

	; SÃ¤tt alla I/O-portar till output, ettor i DDR representerar output. 
	ldi rTemp, 0b11111111
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

	; Två portar på DDRC är joystick X och Y
	cbi DDRC, PC4
	cbi DDRC, PC5

	; SlÃ¤ck alla lampor, sÃ¤tt nollpÃ¥ alla portar. 
	out PORTB, rTemp2
	out PORTC, rTemp2
	out PORTD, rTemp2
	
	; Initiering av timer
	; 1. Konfigurera pre-scaling genom att sätta bit 0-2 i TCCR0B
	ldi rTemp, 0x00
	lds rTemp, TCCR0B
	sbr rTemp,(1<<CS00)|(0<<CS01)|(1<<CS02)
	sts TCCR0B, rTemp

	; 2. Aktivera globala avbrott genom instruktionen sei
	sei

	; 3. Aktivera overflow-avbrott för timern genom att sätta bit 0 i TIMSK0 till 1.
	ldi rTemp, 0x00		; Nollställ rTemp
	lds rTemp, TIMSK0	; Ta nuvarnade TIMSK0
	sbr rTemp,(1<<TOIE0); Ändra en bitjävel
	sts TIMSK0, rTemp	; Sätt tillbaka den ändrade TIMSK0

	; Konfiguration av A/D-omvandlaren
	ldi rTemp, 0x00
	lds rTemp, ADMUX
	sbr rTemp,(1<<REFS0)|(0<<REFS1)|(1<<ADLAR) ; ADLAR ändrar till 8-bitarsläge för input. (mindre precision)
	sts ADMUX, rTemp

	; 
	ldi rTemp, 0x00
	lds rTemp, ADCSRA
	sbr rTemp,(1<<ADPS0)|(1<<ADPS1)|(1<<ADPS2)|(1<<ADEN)
	sts ADCSRA, rTemp
	// Konfiguration av A/D-omvandlaren slut. 

	;sbi COL0_PORT, COL0_PINOUT
	rcall clear

	ldi rSnake, 0b10000000

; Game loop
main: 

	; Välj x-axel
	ldi rTemp, 0x00
	lds rTemp, ADMUX
	sbr rTemp,(0<<MUX3)|(1<<MUX2)|(0<<MUX1)|(1<<MUX0) ; (0b0101 = 5)
	sts ADMUX, rTemp

	; Starta A/D-konvertering. 
	ldi rTemp, 0x00
	lds rTemp, ADCSRA		; Get ADCSRA
	sbr rTemp,(1<<ADSC)		; Starta konvertering ---> ADSC = 1 (bit 6)
	sts ADCSRA, rTemp		; Ladda in
	
iterate_x:
	ldi rTemp, 0x00
	lds rTemp, ADCSRA		; Ta nuvarande ADCSRA för att jämföra
	sbrc rTemp, 6			; Kolla om bit 6 (ADSC) är 0 i rSettings (reflekterar ADCSRA) (instruktion = Skip next instruction if bit in register is cleared) ; Alltså om ej cleared, iterera. 	
	jmp iterate_x			; Iterera
	nop

	lds rDirectionX, ADCH	; Läs av (kopiera) ADCH, som är de 8 bitarna. 
	; mov rTemp, rDirectionX	; Skicka den till rTemp, som skrivs ut. 

	; ADCH > 128 = vänster
	; ADCH < 128 = höger

	; X SLut

	; Välj y-axel
	ldi rTemp, 0x00
	lds rTemp, ADMUX
	sbr rTemp,(0<<MUX3)|(1<<MUX2)|(0<<MUX1)|(0<<MUX0) ; (0b0100 = 5)
	sts ADMUX, rTemp

	; Starta A/D-konvertering. 
	ldi rTemp, 0x00
	lds rTemp, ADCSRA		; Get ADCSRA
	sbr rTemp,(1<<ADSC)		; Starta konvertering ---> ADSC = 1 (bit 6)
	sts ADCSRA, rTemp		; Ladda in
	
iterate_y:
	ldi rTemp, 0x00
	lds rTemp, ADCSRA		; Ta nuvarande ADCSRA för att jämföra
	sbrc rTemp, 6			; Kolla om bit 6 (ADSC) är 0 i rSettings (reflekterar ADCSRA) (instruktion = Skip next instruction if bit in register is cleared) ; Alltså om ej cleared, iterera. 	
	jmp iterate_y			; Iterera
	nop

	lds rDirectionY, ADCH	; Läs av resultat
	; mov rTemp, rDirectionY

	; ADCH < 128 = neråt
	; ADCH > 128 = uppåt

	cpi rDirectionX, 0b10001000 ; compare x-value with 128 + 8
	brpl move_right				; if true, move right
	
	cpi rDirectionX, 0b10001000
	brmi move_left

	; if false?? 


	/*jmp end_if
	nop */

	end_if:

	; if slut
	mov rTemp, rSnake

;	===================
;		FIRST ROW
;	===================
	sbi ROW0_PORT, ROW0_PINOUT

	rcall Laddarad	
	rcall clear

	cbi ROW0_PORT, ROW0_PINOUT

;	===================
;		SECOND ROW
;	===================
/*	sbi ROW1_PORT, ROW1_PINOUT //Aktiverar raden

	rcall Laddarad
	rcall clear

	cbi ROW1_PORT, ROW1_PINOUT //Avaktiverar raden
	*/
;	===================
;		THIRD ROW
;	===================
/*
	
	sbi ROW2_PORT, ROW2_PINOUT

	ldi rTemp, 0b00110011

	rcall Laddarad
	
	rcall clear


	cbi ROW2_PORT, ROW2_PINOUT



;	===================
;		FOURTH ROW
;	===================
	
	
	sbi ROW3_PORT, ROW3_PINOUT

	ldi rTemp, 0b11001100

	rcall Laddarad
	
	rcall clear



	cbi ROW3_PORT, ROW3_PINOUT


;	===================
;		FIFTH ROW
;	===================

	sbi ROW4_PORT, ROW4_PINOUT

	ldi rTemp, 0b00110011

	rcall Laddarad
	
	rcall clear

;	===================
;		SIXTH ROW
;	===================

	
	sbi ROW5_PORT, ROW5_PINOUT

	ldi rTemp, 0b11001100

	rcall Laddarad
	
	rcall clear


	cbi ROW5_PORT, ROW5_PINOUT



;	===================
;		SEVENTH ROW
;	===================

	
	sbi ROW6_PORT, ROW6_PINOUT

	ldi rTemp, 0b00110011

	rcall Laddarad
	
	rcall clear


	cbi ROW6_PORT, ROW6_PINOUT


;	===================
;		EIGTH ROW
;	===================

	
	sbi ROW7_PORT, ROW7_PINOUT

	ldi rTemp, 0b11001100

	rcall Laddarad
	
	rcall clear


	cbi ROW7_PORT, ROW7_PINOUT
	*/
	jmp main

isr_timerOF:
	
	reti

Laddarad:

	bst rTemp, 7
	bld rPORTD, 6
	bst rTemp, 6
	bld rPORTD, 7
	bst rTemp, 5
	bld rPORTB, 0
	bst rTemp, 4
	bld rPORTB, 1
	bst rTemp, 3
	bld rPORTB, 2
	bst rTemp, 2
	bld rPORTB, 3
	bst rTemp, 1
	bld rPORTB, 4
	bst rTemp, 0
	bld rPORTB, 5

	out PORTD, rPORTD
	out PORTB, rPORTB

	ret


clear:
	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT
	
	ret

move_right:
	lsr rSnake
	ret

move_left:
	lsl rSnake
	ret