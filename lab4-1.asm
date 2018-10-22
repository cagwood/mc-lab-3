.global start
.text
	;; Port B: Communication (data and control)
	.set PINB,	0x03
	.set DDRB,	0x04
	.set PORTB,	0x05

	;; Port D: Input, status output, toggle send/recieve
	.set PIND,	0x09
	.set DDRD,	0x0A
	.set PORTD,	0x0B
.org 0x0000
reset_vector:
	jmp start

.org 0x0100
start:
	;; Init
	;; Set D(b0:b3) input, D(b4:b6) output
	ldi r16, 0b01110000
	out DDRD, r16

	;; B(b0:b2) variable. B(b3, b5) output. B(b4, b6) input.
	ldi r16, 0b00101000
	out DDRB, r16

loop1:
	;; Listen if requested to recieve
	in r16, PINB
	andi r16, 0b00010000
	cpi r16, 0b00010000
	breq listen

	;; Send if Port D bit 3 is high
	in r16, PIND
	andi r16, 0b00001000
	cpi r16, 0b00001000
	breq send
	
	rjmp loop1
	
listen:
	sbi PORTB, 5

	in r16, PINB
	andi r16, 0b00010000
	cpi r16, 0b00010000
	breq listen

	in r16, PINB
	andi r16, 0b00000111
	lsl r16
	lsl r16
	lsl r16
	lsl r16
	out PORTD, r16

	
send:
	sbi PORTB, 3

	in r16, PINB
	andi r16, 0b01000000
	cpi r16,  0b01000000
	brne send

	sbi DDRB, 0
	sbi DDRB, 1
	sbi DDRB, 2
	
	;; Write D inputs to B outputs
	sbic PIND, 0
	sbi PORTB, 0
	sbic PIND, 1
	sbi PORTB, 1
	sbic PIND, 2
	sbi PORTB, 2
	cbi PORTB, 3

	;; Wait for PBb6 to be zero
send2:	
	in r16, PINB
	andi r16, 0b01000000
	brne send2

	cbi DDRB, 0
	cbi DDRB, 1
	cbi DDRB, 2

	ldi r16, 255
	ldi r17, 199
	ldi r18, 200
delay:
	dec r16
	nop
	brne delay

	ldi r16, 255
	dec r17
	brne delay

	ldi r17, 199
	dec r18
	brne delay
	
	;; End wanting to send
	cbi PORTB, 3
	rjmp start
.end
