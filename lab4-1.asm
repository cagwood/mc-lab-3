;;; Pin configurations:
;;; D:     7      |6 5 4|   3    |2 1 0 |
;;;   Recv Confirm| LED |Send bit|Number|
;;; B      5      |    4    |   3   |2 1 0 |
;;;   Send Confirm|RQ Listen|Sending|Number|
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
	sbic PINB, 4
	rjmp listen

	;; Send if D send bit is high
	sbic PIND, 3
	rjmp send
	
	rjmp loop1

;;; Listen State
listen:
	sbi PORTB, 5
w_lstn_c:	
	sbic PINB, 4
	rjmp w_lstn_c

	in r16, PINB
	andi r16, 0b00000111
	lsl r16
	lsl r16
	lsl r16
	lsl r16
	out PORTD, r16

	;; stop confirming request
	cbi PORTB, 5

w2_lstn_s:
	sbis PINB, 4
	rjmp w2_lstn_s
w2_lstn_c:
	sbic PINB, 4
	rjmp w2_lstn_c

	;; Delay to ensure the sender gets a chance to enter send mode
	;; again. Listener will continue to listen even with send set
	;; until the first sender stops.
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	rjmp start

;;; Send State
send:
	sbi PORTB, 3

w_cnfm_s:	
	sbis PIND, 7
	rjmp w_cnfm_s

	sbi DDRB, 0
	sbi DDRB, 1
	sbi DDRB, 2
	
	;; Write D inputs to B outputs
	sbic PIND, 0
	sbi PORTB, 0
	sbis PIND, 0
	cbi PORTB, 0
	
	sbic PIND, 1
	sbi PORTB, 1
	sbis PIND, 1
	cbi PORTB, 1
	
	sbic PIND, 2
	sbi PORTB, 2
	sbis PIND, 2
	cbi PORTB, 2

	;; Done sending: values are on outputs
	cbi PORTB, 3

	;; Wait for other machine to stop confirm: nums recorded
w2_cnfm_c:	
	sbic PIND, 7
	rjmp w2_cnfm_c

	;; Set B number bits back to inputs.
	cbi DDRB, 0
	cbi DDRB, 1
	cbi DDRB, 2

	;; Indicate sending to sync with other machine.
	sbi PORTB, 3

	;; Short delay to ensure other machine can read set.
	nop
	nop
	nop
	nop
	nop
	nop
	
	;; End indicating sending.
	cbi PORTB, 3
	rjmp start
.end
