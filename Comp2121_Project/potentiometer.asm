; potentiometer.asm
; Handles the speaker stuff.

;.ifndef POTENTIOMETER_ASM
;.equ POTENTIOMETER_ASM = 1

; TODO: Figure out the ports.
.equ POTENT_OUT = PORTK
.equ POTENT_DDR = DDRK
.equ POTENT_IN = PINK

SetupPotent:
	push temp1

	; REFS0 Internal 2.56V reference with external capacitor at external AFREF pin
	; 0 << ADLAR sets to right adjusted input
	; 0 << MUX0 && 1 << MUX5 -> selects ADC8 as analog input channel
	; 1 << ADEN -> enables the ADC
	; 1 << ADSC -> starts the first conversion
	; 1 << ADIE -> ADC conversion complete interrupt is activated
	; 5 << ADPS0 -> Division factor between xtal freq and input clock to adc?
	;				division factor = 32
	ldi temp1, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0) 
	sts ADMUX, temp1
	ldi temp1, (1 << MUX5)
	sts ADCSRB, temp1
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
	sts ADCSRA, temp1
	pop temp1

	ldi temp1, FLAG_UNSET
	sts potFlag, temp1
	ret

EnablePotInterrupt:
	push temp1
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
	sts ADCSRA, temp1

	pop temp1
	ret


DisablePotInterrupt:
	push temp1

	clr temp1
	sts ADCSRA, temp1

	pop temp1
	ret

ADCCint:
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push r16
	
	lds temp1, currentMode
	; RESET POT MODE
	cpi temp1, MODE_RESETPOTENT
	breq HandleResetPotMode
	; FIND POT MODE
	cpi temp1, MODE_FINDPOTENT
	breq HandleFindPotMode
	; else do nothing
	rjmp return_ADCCint
	
	setPotResetFlag:
		sts potFlag, r16

	return_ADCCint:
		pop r16
		pop temp2
		pop temp1
		out SREG, temp1
		pop temp1
		reti

HandleResetPotMode:
	lds temp1, ADCL
	lds temp2, ADCH
	cpi temp1, 0 
	brne potIsNotZero
	cpi temp2, 0 
	brne potIsNotZero
	rjmp potIsZero
	
potIsZero: 
	lds r16, potFlag
	cpi r16, FLAG_SET
	breq setPotResetFlag
	clr r16
	sts potTimer, r16
	sts potTimer+1, r16
	ldi r16, FLAG_SET
	rjmp setPotResetFlag

potIsNotZero:
	ldi r16, FLAG_UNSET
	rjmp setPotResetFlag

.def temp3 = r20
.def temp4 = r21
HandleFindPotMode:
	lds temp1, ADCL
	lds temp2, ADCH
	lds temp3, currentDesiredPot
	lds temp4, currentDesiredPot+1

	sub temp3, temp1
	sbc temp4, temp2
	
	ldi r16, 0
	cpi temp3, 0
	cpc temp4, r16
	brlt PotGreaterThanDesired
	rjmp PotWithinDesiredRange

PotWithinDesiredRange: 
	ldi r16, high(16)
	cpi temp3, 16
	cpc temp4, r16
	brlt PotCorrect
	ldi r16, high(32)
	cpi temp3, 32
	cpc temp4, r16
	brlt PotAlmostCorrect
	ldi r16, high(48)
	cpi temp3, 48
	cpc temp4, r16
	brlt PotAlmostAlmostCorrect
	
	ldi r16, FLAG_UNSET
	; TODO: do nothing
	rjmp setPotResetFlag

PotCorrect:
	; if flag already set, do nothing
	lds r16, potFlag
	cpi r16, FLAG_SET
	breq setPotResetFlag
	; else:
	;  set leds
	ldi r16, 0b11111111
	out portc, r16
	ldi r16, 0b00000011
	out portg, r16
	; reset timer
	clr r16
	sts potTimer, r16
	sts potTimer+1, r16
	; set flag
	ldi r16, FLAG_SET
	rjmp setPotResetFlag

PotAlmostCorrect:
	ldi r16, 0b11111111
	out portc, r16
	ldi r16, 0b00000001
	out portg, r16
	ldi r16, FLAG_UNSET ; unset flag
	rjmp setPotResetFlag

PotAlmostAlmostCorrect:
	ldi r16, 0b11111111
	out portc, r16
	ldi r16, 0b00000000
	out portg, r16
	ldi r16, FLAG_UNSET ; unset flag
	rjmp setPotResetFlag

PotGreaterThanDesired:
	; go back to reset pot screen
	clr r16
	out portc, r16
	out portg, r16
	rcall StartResetPotent
	ldi r16, FLAG_UNSET ; unset flag
	rjmp setPotResetFlag

.undef temp3
.undef temp4

.undef temp1
.undef temp2

