;
; Snake2.asm
;
; Created: 2016-05-18 09:50:16
; Author : Mattias
;

; [En lista med registerdefinitioner]
.DEF rTemp				= r16
.DEF rDirection			= r17
.DEF rPORTB				= r18
.DEF rCounter			= r19
.DEF rPORTD				= r20
.DEF rSnake				= r21
.DEF rUpdateFlag		= r22
.DEF rUpdateDelay		= r25
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

	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)



	; SÃ¤tt alla I/O-portar till output, ettor i DDR representerar output. 
	ldi rTemp, 0b11111111
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

	; Två portar på DDRC är joystick X och Y
	cbi DDRC, PC4
	cbi DDRC, PC5

	; SlÃ¤ck alla lampor, sÃ¤tt nollpÃ¥ alla portar. 
	ldi rTemp, 0b00000000
	out PORTB, rTemp
	out PORTC, rTemp
	out PORTD, rTemp
	
	; Initiering av timer
	; 1. Konfigurera pre-scaling genom att sätta bit 0-2 i TCCR0B
	ldi rTemp, 0x00
	in rTemp, TCCR0B
	sbr rTemp,(1<<CS00)|(0<<CS01)|(1<<CS02)
	out TCCR0B, rTemp

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

	ldi YH, 0
	ldi YL, 0

	ldi rTemp, 0b00000001
	std Y+0, rTemp
	ldi rTemp, 0b00000010
	std Y+1, rTemp
	ldi rTemp, 0b00000100
	std Y+2, rTemp
	ldi rTemp, 0b00001000
	std Y+3, rTemp
	ldi rTemp, 0b00000001
	std Y+4, rTemp
	ldi rTemp, 0b00000010
	std Y+5, rTemp
	ldi rTemp, 0b00000100
	std Y+6, rTemp
	ldi rTemp, 0b00001000
	std Y+7, rTemp
	ldi rUpdateFlag, 0
	ldi rUpdateDelay, 0
	ldi rDirection, 0

; Game loop
main:
/*

	; rDirectionX > 128 = vänster
	; rDirectionX < 128 = höger


	; mov rTemp, rDirectionY

	; rDirectionY < 128 = neråt
	; rDirectionY > 128 = uppåt

	cpi rDirectionX, 0b10001000 ; compare x-value with 128 + 8
	brlo move_right				; if true, move right
	*/
	/* jmp end_if
	nop */
 

	ldi YH, 0
	ldi YL, 0


;	===================
;		FIRST ROWs
;	===================

	sbi ROW0_PORT, ROW0_PINOUT

	ld rSnake, Y+

	rcall Laddarad	
	rcall clear

	cbi ROW0_PORT, ROW0_PINOUT
	
;	===================
;		SECOND ROW
;	===================
	
	sbi ROW1_PORT, ROW1_PINOUT //Aktiverar raden

	ld rSnake, Y+

	rcall Laddarad
	rcall clear

	cbi ROW1_PORT, ROW1_PINOUT //Avaktiverar raden
	
	
;	===================
;		THIRD ROW
;	===================

	sbi ROW2_PORT, ROW2_PINOUT

	ld rSnake, Y+
	
	rcall Laddarad
	rcall clear

	cbi ROW2_PORT, ROW2_PINOUT

;	===================
;		FOURTH ROW
;	===================
	
	
	sbi ROW3_PORT, ROW3_PINOUT

	ld rSnake, Y+
	rcall Laddarad
	
	rcall clear



	cbi ROW3_PORT, ROW3_PINOUT


;	===================
;		FIFTH ROW
;	===================

	sbi ROW4_PORT, ROW4_PINOUT

	ld rSnake, Y+

	rcall Laddarad
	
	rcall clear

	cbi ROW4_PORT, ROW4_PINOUT

;	===================
;		SIXTH ROW
;	===================

	
	sbi ROW5_PORT, ROW5_PINOUT

	ld rSnake, Y+
	rcall Laddarad
	
	rcall clear


	cbi ROW5_PORT, ROW5_PINOUT



;	===================
;		SEVENTH ROW
;	===================

	
	sbi ROW6_PORT, ROW6_PINOUT

	ld rSnake, Y+

	rcall Laddarad
	
	rcall clear


	cbi ROW6_PORT, ROW6_PINOUT


;	===================
;		EIGTH ROW
;	===================

	
	sbi ROW7_PORT, ROW7_PINOUT

	ld rSnake, Y+

	rcall Laddarad
	
	rcall clear


	cbi ROW7_PORT, ROW7_PINOUT



	cpi rUpdateFlag, 1
	breq updateLoop

	jmp main

; Bestämmer hur lång tid man ska vänta mellan varje interrupt. 
updateLoop:
	inc rUpdateDelay			; rUpdateDelay++
	cpi rUpdateDelay, 15		; Kolla om 10 interrupts har gått
	brne skip					; Om inte 10 updates har gått, skippa continueUpdate
	rcall continueUpdate		; 
	skip:						; 
	ldi rUpdateFlag, 0b00000000	; Nollställ inför nästa interrupt
	jmp main					; 

; Increase rSnake 
continueUpdate:	
	ldi rUpdateDelay, 0b00000000

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

	; Läs av y-axel

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

	lds rDirectionY, ADCH		; Läs av resultat

	; Läs av y-axel slut!! 

	; Deadzone X
	cpi rDirectionX, 165	; Deadzone
	brsh go_left

	cpi rDirectionX, 91		; Deadzone
	brlo go_right

	cpi rDirectionY, 165
	;brsh

	cpi rDirectionY, 91
	;brlo 

	; Välj om gå i X eller Y

	jmp checkdir
	
	; Stå still = 0
	; Vänster = 1
	; Höger = 2
	; Upp = 4 (inte fixat än)
	; Ner = 8 (inte fixat än)
	go_left:
		ldi rDirection, 0b0000001
	jmp checkdir
	
	go_right:
		ldi rDirection, 0b0000010
	
checkdir:

	ldi YH, 0
	ldi YL, 0
	ldi rCounter, 0

checkdircont:
	

	;ld rTemp, Y
	;add rTemp, rCounter
	;st Y, rTemp

	cpi rDirection, 0
	breq outsidecheckdone

	cpi rDirection, 1
	breq left

	cpi rDirection, 2
	breq right
	
	

	jmp outsidecheck
	left:
		;rcall move_left
		ld rTemp, Y
		lsl rTemp
		st Y, rTemp
		jmp outsidecheck
	right:
		;rcall move_right
		ld rTemp, Y
		lsr rTemp
		st Y, rTemp
outsidecheck:

	brcc outsidecheckdone	; Kontrollera om Carry är cleared

	cpi rDirection, 1		; 
	breq outsideleft

	cpi rDirection, 2
	breq outsideRight

	outsideleft:
	ldi rTemp, 1
	st Y, rTemp
	clc
	jmp outsidecheckdone

	outsideright:
	ldi rTemp, 128
	st Y, rTemp
	clc

	outsidecheckdone:
	cpi rCounter, 8
	breq done
	
cont:
	inc rCounter

	ld rTemp, Y+
	;inc rTemp
	;st Y, rTemp
	jmp checkdircont
done:
	ret

isr_timerOF:
	ldi rUpdateFlag, 0b00000001
	reti

Laddarad:

	in rPORTD, PORTD

	bst rSnake, 7
	bld rPORTD, 6
	bst rSnake, 6
	bld rPORTD, 7
	bst rSnake, 5
	bld rPORTB, 0
	bst rSnake, 4
	bld rPORTB, 1
	bst rSnake, 3
	bld rPORTB, 2
	bst rSnake, 2
	bld rPORTB, 3
	bst rSnake, 1
	bld rPORTB, 4
	bst rSnake, 0
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
/*
move_right:
	ld rTemp, Y
	lsr rTemp
	st Y, rTemp
	ret

move_left:
	ld rTemp, Y
	lsl rTemp
	st Y, rTemp
	ret
	*/