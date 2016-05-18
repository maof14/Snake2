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

; Definera namn f�r alla kolumner f�r att dessa ska bli enkelt att referera till
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

	; Initiering av portar för I/O
	ldi rTemp, 0b11111111	; ettor
	and rTemp2, rTemp		; nollor

	; Sätt alla I/O-portar till output, ettor i DDR representerar output. 
	ldi rTemp, 0b11111111
	out DDRB, rTemp
	out DDRC, rTemp
	out DDRD, rTemp

	; Två portar på DDRC är joystick X och Y
	cbi DDRC, PC4
	cbi DDRC, PC5

	; Släck alla lampor, sätt nollpå alla portar. 
	out PORTB, rTemp2
	out PORTC, rTemp2
	out PORTD, rTemp2
	
	; Initiering av timer
	; 1. Konfigurera pre-scaling genom att s�tta bit 0-2 i TCCR0B
	ldi rTemp, 0x00
	ldi rTemp2, 0x00
	ldi rTemp, (1<<CS00)|(1<<CS02)
	lds rTemp2, TCCR0B
	or rTemp, rTemp2
	sts TCCR0B, rTemp

	; Timer-konfiguration start
	; 1. Konfigurera pre-scaling genom att sätta bit 0-2 i TCCR0B
	lds r16, TCCR0B					; ta nuvarande värde på TCCR0B
	sbr r16,(1<<CS00)|(1<<CS02)		; Manipulera de enskilda bitarna i temporär TCCRB0. (prescales to 1024. rSettings = 0b00000101)
	sts TCCR0B, r16

	; 2. Aktivera globala avbrott genom instruktionen sei
	sei

	ldi rTemp, 0x00
	ldi rTemp2, 0x00
	; 3. Aktivera overflow-avbrottet f�r Timer0 genom att s�tta bit 0 i TIMSK0 till 1.
	ldi rTemp, (1<<TOIE0)
	lds rTemp2, TIMSK0
	or rTemp, rTemp2
	sts TIMSK0, rTemp

	; 3. Aktivera overflow-avbrottet för Timer0 genom att sätta bit 0 i TIMSK0 till 1.
	lds r16, TIMSK0					; Ta nuvarande värde på TIMSK0
	sbr r16,(1<<TOIE0)					; Vad gör denna? rSettings = 0b00000001
	sts TIMSK0, r16					; sts = out-instruktion fast för icke extendat I/O-space
	; Timer-konfiguration slut. 

	; Konfiguration av A/D-omvandlaren
	lds r16, ADMUX
	sbr r16,(1<<REFS0)|(0<<REFS1)|(1<<ADLAR) ; ADLAR ändrar till 8-bitarsläge för input. (mindre precision)
	sts ADMUX, r16

	lds r16, ADCSRA
	sbr r16,(1<<ADPS0)|(1<<ADPS1)|(1<<ADPS2)|(1<<ADEN)
	sts ADCSRA, r16
	// Konfiguration av A/D-omvandlaren slut. 

; Game loop
main: 

;	===================
;		FIRST ROW
;	===================
	sbi ROW0_PORT, ROW0_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT

	cbi ROW0_PORT, ROW0_PINOUT
;	===================
;		SECOND ROW
;	===================

	sbi ROW1_PORT, ROW1_PINOUT //Aktiverar raden

	sbi COL0_PORT, COL0_PINOUT //Aktiverar alla COL
	sbi COL1_PORT, COL1_PINOUT 
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT //Avaktiverar alla COL
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT



	cbi ROW1_PORT, ROW1_PINOUT //Avaktiverar raden

;	===================
;		THIRD ROW
;	===================

	
	sbi ROW2_PORT, ROW2_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT


	cbi ROW2_PORT, ROW2_PINOUT



;	===================
;		FOURTH ROW
;	===================
	
	
	sbi ROW3_PORT, ROW3_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT



	cbi ROW3_PORT, ROW3_PINOUT


;	===================
;		FIFTH ROW
;	===================

	sbi ROW4_PORT, ROW4_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT
	cbi ROW4_PORT, ROW4_PINOUT

;	===================
;		SIXTH ROW
;	===================

	
	sbi ROW5_PORT, ROW5_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT


	cbi ROW5_PORT, ROW5_PINOUT



;	===================
;		SEVENTH ROW
;	===================

	
	sbi ROW6_PORT, ROW6_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT


	cbi ROW6_PORT, ROW6_PINOUT


;	===================
;		EIGTH ROW
;	===================

	
	sbi ROW7_PORT, ROW7_PINOUT

	sbi COL0_PORT, COL0_PINOUT
	sbi COL1_PORT, COL1_PINOUT
	sbi COL2_PORT, COL2_PINOUT
	sbi COL3_PORT, COL3_PINOUT
	sbi COL4_PORT, COL4_PINOUT
	sbi COL5_PORT, COL5_PINOUT
	sbi COL6_PORT, COL6_PINOUT
	sbi COL7_PORT, COL7_PINOUT

	
	
	

	
	cbi COL0_PORT, COL0_PINOUT
	cbi COL1_PORT, COL1_PINOUT
	cbi COL2_PORT, COL2_PINOUT
	cbi COL3_PORT, COL3_PINOUT
	cbi COL4_PORT, COL4_PINOUT
	cbi COL5_PORT, COL5_PINOUT
	cbi COL6_PORT, COL6_PINOUT
	cbi COL7_PORT, COL7_PINOUT


	cbi ROW7_PORT, ROW7_PINOUT

	jmp main

; tick
isr_timerOF:

	reti
