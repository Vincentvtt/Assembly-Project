/*
 * Macros.asm
 *
 *  Created: 18/05/2017 12:31:13 PM
 *   Author: Vince
 */ 
 .include "m2560def.inc"

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro initialise_items ;intialises items with default value 
	ldi r16, 1
	sts Item1Count, r16
	clr r16
	ldi r16, 2
	sts Item2Count, r16
	clr r16
	ldi r16, 3
	sts Item3Count, r16
	clr r16
	ldi r16, 4
	sts Item4Count, r16
	clr r16
	ldi r16, 5
	sts Item5Count, r16
	clr r16
	ldi r16, 6
	sts Item6Count, r16
	clr r16
	ldi r16, 7
	sts Item7Count, r16
	clr r16
	ldi r16, 8
	sts Item8Count, r16
	clr r16
	ldi r16, 9
	sts Item9Count, r16
	clr r16
	ldi r16, 1
	sts Item1Price, r16
	clr r16
	ldi r16, 2
	sts Item2Price, r16
	clr r16
	ldi r16, 1
	sts Item3Price, r16
	clr r16
	ldi r16, 2
	sts Item4Price, r16
	clr r16
	ldi r16, 1
	sts Item5Price, r16
	clr r16
	ldi r16, 2
	sts Item6Price, r16
	clr r16
	ldi r16, 1
	sts Item7Price, r16
	clr r16
	ldi r16, 2
	sts Item8Price, r16
	clr r16
	ldi r16, 1
	sts Item9Price, r16
	clr r16
	ldi r16, 5 
	sts CoinsRemaining, r16;outside of the max price of 3 so theres no conflicts and can be properly intialised via user input
	clr r16
.endmacro

.macro subtract_item_count; we subtract a selected items inventory count by 1
	push temp1
	push temp2
	push temp3
	clr YL
	clr YH
	ldi YL, LOW(item1Count) ;initialising y pointer to point at the inventory in SRAM
	ldi YH, HIGH(item1Count)
	ldi temp3, 1
	lds temp2,SelectedItemNum ; the item we are subtracting from 
sub_loop: ;finding the item which we are decrementing
	cp temp3,temp2
	breq decrement
	inc temp3
	inc YL
	rjmp sub_loop
decrement:
	ld temp1, Y
	dec temp1 ;subtract 1 from the number of items
	st Y,temp1; store the number of items
	pop temp3 ;restore registers 
	pop temp2 
	pop temp1
.endmacro

.macro do_lcd_data ; prints an lcd command or a character 
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_data_register;prints the value of a register to the lcd 
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_select_screen ; we draw the select screen
	stop_timer ;stopping timers as there are no timer interrupts occuring while on this screen
	stop_timer2
	Reset_Coins_Remaining; number of coins remaining is rese
	do_lcd_command 0b00000001
	do_lcd_data 'S'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 'c'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'
	ldi State,SELECT ;state is changed to SELECT
.endmacro

.macro do_delivery_screen ;do delivery screen
	stop_timer2 ;potentiometer timer is stopped
	start_timer; select screen timer is started - we return to select screen after 3 seconds. 

	Reset_Coins_Remaining ;reset coins remaining 
	do_lcd_command 0b00000001
	do_lcd_data 'D'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'i'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'
	ldi State,Delivery ;change state to delivery 
.endmacro
.macro do_startup_screen ;start up screen occurs when power on or reset is pressed 
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '7'
	do_lcd_data 's'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'K'
	do_lcd_data '6'
	do_lcd_command 0b11000000
	do_lcd_data 'V'
	do_lcd_data 'e'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'M'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'h'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'e'
.endmacro

.macro Subtract_Coins_Remaining ; we subtract the coins remaining(value stored in SRAM) by 1 
	push temp3 
	lds temp3,CoinsRemaining
	dec temp3
	sts CoinsRemaining,temp3
	pop temp3
.endmacro

.macro do_coin_screen;we draw the coin screen
	stop_timer; cancel the interrupt for the select screen 
	cli ; no interrupts occuring while this screen is being drawn 
	push temp1
	push temp2
	push temp3 
	ldi temp2,1
	ld temp1, Z
	clr YL
	clr YH
	ldi YL, LOW(item1Price)
	ldi YH, HIGH(item9Price)
	lds temp3,coinsRemaining
price_loop:
	cp temp2, temp1
	breq lcd_out
	inc YL
	inc temp2
	rjmp price_loop
lcd_out:
	ld temp1, Y
	cpi temp3,5;We compare if coins remaining is uninitialised - that is value is 5
	brne lcd_out_continue
	mov temp3, temp1 

	sts CoinsRemaining,temp3;set it to default price stored in ram e.g item1Price
lcd_out_continue:
	ldi temp2, toASCII ;ASCII offsett
	add temp3,temp2	
	do_lcd_command 0b00000001
	do_lcd_data 'I'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'c'
	do_lcd_data 'o'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_command 0b11000000
	do_lcd_data_register temp3
	pop temp3
	pop temp2
	pop temp1
	clr YL
	clr YH
	start_timer2 ; start the potentiometer interrupt timer
	sei; enable interrupts again 
.endmacro

.macro do_empty_screen ;draws empty screen 
	start_timer ;can be interrupted by select timer
	stop_timer2; but not by pentiometer timer 
	push temp3
	push temp2
	lds temp3, SelectedItemNum ;load last selected item into temp3 which is empty 
	ldi temp2, toASCII
	add temp3, temp2
	do_lcd_command 0b00000001
	do_lcd_data 'O'
	do_lcd_data 'u'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' '
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'c'
	do_lcd_data 'k'
	do_lcd_command 0b11000000
	do_lcd_data_register temp3 ;temp3 represents item that is empty 
	pop temp2
	pop temp3
.endmacro

.macro clear 
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp1
	st Y+, temp1 ; clear the two bytes at @0 in SRAM
	st Y, temp1
.endmacro

.macro stop_timer ;stop select timer 
	push temp1
	ldi temp1, 0b00000000
	out TCCR0B, temp1 
	pop temp1
.endmacro

.macro start_timer;start select timer 
	push temp1
	ldi temp1, 0b00000000
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1 ; Prescaling value=8
	ldi temp1, 1<<TOIE0 ; = 128 microseconds
	sts TIMSK0, temp1 ; T/C0 interrupt enable
	pop temp1
.endmacro

.macro setup_pot ;intialises potentiometer -interrupts off
	ldi temp1, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0);
	sts ADMUX, temp1
	ldi temp1, (1 << MUX5);
	sts ADCSRB, temp1
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (0 << ADIE) | (5 << ADPS0)|(1 << ADATE);
	sts ADCSRA, temp1
.endmacro

.macro enable_pot_int;potentiometer interrupts are on
	push temp1 
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)|(1 << ADATE);
	sts ADCSRA, temp1
	pop temp1
.endmacro

.macro disable_pot_int;potentiometer interrupts are off
	push temp1 
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (0 << ADIE) | (5 << ADPS0)|(1 << ADATE);
	sts ADCSRA, temp1
	pop temp1
.endmacro

.macro setup_timer2; setsup timer 2 with its interrupt off
	ldi temp1, 0b00000000
	sts TCCR2A, temp1
	ldi temp1, 0b00000000 ;default disable timer1
	sts TCCR2B, temp1 ; Prescaling value=8
	ldi temp1, 1<<TOIE0 ; = 128 microseconds
	sts TIMSK2, temp1 ; T/C0 interrupt enable
.endmacro

.macro stop_timer2 ;turn off interrupts for timer 2 
	push temp1
	ldi temp1, 0b00000000
	sts TCCR2B, temp1 
	pop temp1
.endmacro

.macro start_timer2; start interrupts for timer 2 
	push temp1
	ldi temp1, 0b00000010
	sts TCCR2B, temp1 
	pop temp1
.endmacro

.macro Reset_PotFlags ; reset pot left and right flags, when coin has been inserted
	push r16
	ldi r16,0
	sts PotFlag_Left,r16
	sts PotFlag_Right,r16
	pop r16
.endmacro

.macro Reset_Coins_Remaining ;resets number of cons needed to be inserted . 
	push r16
	ldi r16, 5
	sts CoinsRemaining,r16
	pop r16
.endmacro