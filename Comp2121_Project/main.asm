
;
; Lab4Q3.asm
;
; Created: 10/05/2017 4:43:56 PM
; Author : Vince
;

.include "m2560def.inc"
.include "Macros.asm"


.dseg
	SecondCounter:
.byte 2 ; Two-byte counter for counting seconds.
	TempCounter:
.byte 2 
	SecondCounter_2:
.byte 2 ; Two-byte counter for counting seconds.
	TempCounter_2:
.byte 2 
	Item1Count: ;inventory count for all the items
.byte 1 
	Item2Count:
.byte 1 
	Item3Count:
.byte 1 
	Item4Count:
.byte 1 
	Item5Count:
.byte 1 
	Item6Count:
.byte 1 
	Item7Count:
.byte 1 
	Item8Count:
.byte 1 
	Item9Count:
.byte 1 
	Item1Price:;inventory prices for all the items
.byte 1 
	Item2Price:
.byte 1 
	Item3Price:
.byte 1 
	Item4Price:
.byte 1 
	Item5Price:
.byte 1 
	Item6Price:
.byte 1 
	Item7Price:
.byte 1 
	Item8Price:
.byte 1 
	Item9Price:
.byte 1
	SelectedItemNum: ;last selected item via keypad press
.byte 1
	PotFlag_Right: ; 1 when pot has been turned fully clockwise else 0
.byte 1
	PotFlag_Left:; 1 when pot has been turned fully anticlockwise
.byte 1
	CoinsRemaining: ;num coins remaining to be inserted. 
.byte 1

.cseg
.org 0
	jmp RESET
.org OVF2addr
	jmp Timer2OVF ;timer2 overflow handler
.org OVF0addr
	jmp Timer0OVF ;timer0 overflow handler
.org ADCCaddr
	jmp POT_HANDLER

.def row = r16              ; current row number
.def col = r17              ; current column number
.def rmask = r18            ; mask for current row during scan
.def cmask = r19            ; mask for current column during scan
.def temp1 = r20 
.def temp2 = r21
.def temp3 = r22
.def state = r23 ; 0-start,1-select,2-empty,3-coin, states of the machine
.def temp4 = r24
.equ START = 0
.equ SELECT = 1
.equ EMPTY = 2
.equ COIN = 3
.equ DELIVERY = 4
.equ toASCII = 48 ; to offset numbers into their ASCII counterpart
.equ PORTLDIR = 0xF0        ; PH7-4: output, PH3-0, input
.equ INITCOLMASK = 0xEF     ; scan from the rightmost column,
.equ INITROWMASK = 0x01     ; scan from the top row
.equ ROWMASK = 0x0F         ; for obtaining input from Port L
	

POT_HANDLER:;handling the potentiometer turns
	push temp1
	push temp2
	push temp3 
	push temp4
	push r16
	lds temp1, ADCL  
	lds temp2, ADCH

CompareMaxClockWise:
	ldi temp3, low(0x3ff) 
	ldi temp4, high(0x3ff) 
	;compare if max turn clockwise on pot
	cp temp1, temp3 
	cpc temp2, temp4
	breq MaxClockWise

CompareMaxAntiClockWise:	
	ldi temp3, low(0) 
	ldi temp4, high(0)
	;compare if max turn anti-clockwise on pot
	cp temp1, temp3 
	cpc temp2, temp4 
	breq MaxAntiClockWise
	jmp POT_HANDLE_FINAL
MaxClockWise:;setting pot right flag to 1 
	ldi r16, 1
	sts PotFlag_Right, r16
	jmp POT_HANDLE_FINAL

MaxAntiClockWise:

	lds r16,PotFlag_Right
	cpi r16,1
	breq HalfTurn ; check if pot right is 1 if it 1 then we check if pot left has been previously flagged 1
MaxAntiClockWise_Cont:
	ldi r16, 1
	sts PotFlag_Left, r16 ;set pot left flag to 1
	jmp POT_HANDLE_FINAL

HalfTurn:
	lds r16,PotFlag_Left
	cpi r16,1
	breq Coin_Inserted ;if pot left is also 1 then we know a coin has been inserted 
	jmp MaxAntiClockWise_Cont

Coin_Inserted:	
	Subtract_Coins_Remaining ;we subtract 1 from the coins remaining that is stored in dseg
	lds r16,CoinsRemaining
	Reset_PotFlags	; reset pot flags
	cpi r16,0 ; if coins remaining =0 
	breq Coin_Inserted_Cont
	jmp Coins_Remaining
Coin_Inserted_cont:	
	do_lcd_data 'P'
	ldi State,DELIVERY
	do_delivery_screen ; show delivery screen coins remaining is 0
	subtract_item_count ;subtract inventory amount
	Reset_Coins_Remaining ; reset the number of coins remaining
	jmp POT_HANDLE_FINAL
Coins_Remaining:
	do_coin_screen ;draw updated coin screen with new coins remaining

POT_HANDLE_FINAL: ; restore registers
	pop r16
	pop temp4
	pop temp3 
	pop temp2
	pop temp1
	ret

Timer2OVF:;every 1/3 second we check the turn values of the potentiometer
	in temp1, SREG
	push temp1 ; Prologue starts.
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.
	; Load the value of the temporary counter.
	lds r24, TempCounter_2
	lds r25, TempCounter_2+1
	adiw r25:r24, 1 ; Increase the temporary counter by one.
	cpi r24, low(2343) ; roughly once every 1/3 of a second
	ldi temp1, high(2343) ; 
	cpc r25, temp1
	brne NotSecond_2
	rcall POT_HANDLER ; we check the turn values of the potentiometer 
	clear TempCounter_2 ; Reset the temporary counter.
	; Load the value of the second counter.
	lds r24, SecondCounter_2
	lds r25, SecondCounter_2+1
	adiw r25:r24, 1 ; Increase the second counter by one.	sts SecondCounter_2, r24
	sts SecondCounter_2+1, r25
	rjmp EndIF_2

NotSecond_2:
	; Store the new value of the temporary counter.
	sts TempCounter_2, r24
	sts TempCounter_2+1, r25

EndIF_2:
	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	pop temp1
	out SREG, temp1
	reti ; Return from the interrupt.

Timer0OVF: ; after 3 seconds we draw the select screen
	in temp1, SREG
	push temp1 ; Prologue starts.
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.
	; Load the value of the temporary counter.
	lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1 ; Increase the temporary counter by one.
	cpi r24, low(23436) ; Check if (r25:r24) = 7812
	ldi temp1, high(23436) ; 3 second timer
	cpc r25, temp1
	breq IsSecond
	jmp NotSecond
IsSecond:
	do_select_screen ;3 seconds is up so we draw the select screen 
	;;	com leds
	;;	out PORTC, leds
	clear TempCounter ; Reset the temporary counter.
	; Load the value of the second counter.
	lds r24, SecondCounter
	lds r25, SecondCounter+1
	adiw r25:r24, 1 ; Increase the second counter by one.	sts SecondCounter, r24
	sts SecondCounter+1, r25
	rjmp EndIF

NotSecond:
	; Store the new value of the temporary counter.
	sts TempCounter, r24
	sts TempCounter+1, r25

EndIF:
	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	pop temp1
	out SREG, temp1
	reti ; Return from the interrupt.
RESET:
    ldi temp1, low(RAMEND)  ; initialize the stack
    out SPL, temp1
    ldi temp1, high(RAMEND)
    out SPH, temp1
    ldi temp1, PORTLDIR     ; PB7:4/PB3:0, out/in
    sts DDRL, temp1         ; PORTB is input
    ser temp1               ; PORTC is output
    out DDRC, temp1
    out PORTC, temp1
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
    do_lcd_command 0b00001100 ; Cursor on, bar, no blink
	do_startup_screen

	clear TempCounter ; Initialize the temporary counter to 0
	clear SecondCounter ; Initialize the second counter to 0
	ldi temp1, 0b00000000
	out TCCR0A, temp1
	ldi temp1, 0b00000010
	out TCCR0B, temp1 ; Prescaling value=8
	ldi temp1, 1<<TOIE0 ; = 128 microseconds
	sts TIMSK0, temp1 ; T/C0 interrupt enable
	setup_timer2
	sei ; Enable global interrupt
	ldi State,START
	initialise_items ;initialise inventory and prices
	setup_pot; setup potentiometer 

	rjmp main

;we check the state of the machine
main:
	clr temp1
	cpi State,START
	brne main2
	jmp polling 
main2: ; start and select both involve polling straight away
	cpi State,SELECT
	brne main3
	jmp polling
main3:
	cpi State,COIN 
	brne main4
	jmp coin_selection ; go to coin selection 
main4:
	cpi State,EMPTY
	brne main5
	jmp empty_screen ; go to empty stock
main5:
	cpi State,DELIVERY
	brne main6
	jmp delivery_screen; go to delivery
main6:
	jmp main
delivery_screen:
	do_delivery_screen; draw delivery screen
	rcall sleep_25ms
	rcall sleep_25ms
	jmp polling

coin_selection:
	do_coin_screen;draw coin screen
	rcall sleep_25ms
	rcall sleep_25ms
	jmp polling

empty_screen:
	do_empty_screen;draw empty screen
	rcall sleep_25ms
	rcall sleep_25ms
	jmp polling
	;;jmp halt

polling:;polling keypad press
    ldi cmask, INITCOLMASK  ; initial column mask why does 11101111 
    clr col                 ; initial column start at column 0

colloop:
    cpi col, 4				; have we reached the 4th column?
    breq polling              ; scanned all keys reset and start all over.
    sts PORTL, cmask        ; Otherwise, scan a column.
    ldi temp1, 0xFF         ; Slow down the scan operation. 

delay:
    dec temp1				
    brne delay              ; until temp1 is zero

    lds temp1, PINL          ; Read PORTL that is port connects to keypad
    andi temp1, ROWMASK     ; Get the keypad output value remember rowmask is 1111 in binary
    cpi temp1, 0xF          ; Check if any row is low, check if temp1 is the same as rowmask 
    breq nextcol            ; if not - switch to next column(

                            ; If yes, find which row is low
    ldi rmask, INITROWMASK  ; initialize for row check
    clr row

; and going into the row loop
rowloop:
    cpi row, 4              ; is row already 4?
    breq nextcol            ; the row scan is over - next column
    mov temp2, temp1		; clone temp1 please
    and temp2, rmask        ; check un-masked bit
    breq convert            ; if bit is clear, the key is pressed !!! so it sthe center 0 of the cross of 1's
    inc row                 ; else move to the next row
    lsl rmask
    jmp rowloop
    
nextcol:                    ; if row scan is over
     lsl cmask				; shift left i.e times by 2 so 1111 become 1110 cos overflow i think
     inc col                ; increase col value
     jmp colloop            ; go to the next column
     
convert:
    cpi col, 3              ; If the pressed key is in col 3
    brne convert2
	jmp letters

convert2:           ; we have letter                            ; If the key is not in col 3 and
    cpi row, 3              ; if the key is in row 3,
    brne convert3
	jmp symbols ;  we have a symbol or 0

convert3:            
    mov temp1, row          ; otherwise we have a number 1-9
    lsl temp1
    add temp1, row
    add temp1, col          ; temp1 = row*3 + col
	subi temp1, -1	;111
	cpi temp1, 1
	push temp1

	cpi State,START ;interrupting the intro screen via keypad press
	breq select_interrupt

    jmp convert_end ; deciding which item is being pressed

select_interrupt:;so start screen is interuppted via keypad press
	do_select_screen
	rcall sleep_25ms
	jmp main; new state is SELECT

    
letters:
	do_select_screen
    jmp main


symbols:
	do_select_screen
    jmp main
star:
	do_select_screen
	
    jmp main
zero:
	do_select_screen
	jmp convert_end

convert_end:
	cpi State,SELECT
	breq perform_selection ;we only can select items during SELECT state otherwise we just change state to SELECT
	jmp main ;otherwise we do nothing and loop to main 

perform_selection:
	sts SelectedItemNum, temp1 ;; store the item we have selected for future use in case
	clr ZL
	clr ZH
	ldi ZL, LOW(item1Count)
	ldi ZH, HIGH(item9Count)
	ldi temp3, 1

selection_loop:
	cp temp3,temp1;loop through until we find the right item in SRAM 
	breq selection; Z points to that item and we exit
	inc temp3
	inc ZL
	rjmp selection_loop

selection:
	ld temp1, Z ; getting quantity of the item in stock
	cpi temp1,0 
	breq empty_selection ;if nothing left we change the state to be empty
	ldi State,COIN ; otherwise the state is set to coin
	jmp main ;

empty_selection:
	ldi State,Empty ;state is set to empty 
	jmp main

halt:
	rjmp halt

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro
;LED commands for drawing characters and data from registers. 
lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

;delay commands for polling and to regulate the rendering of the lcd and keypad presses 
sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_25ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret