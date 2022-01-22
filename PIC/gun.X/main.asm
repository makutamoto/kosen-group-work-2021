	LIST	P=PIC16F648A
	INCLUDE	<P16F648A.INC>
	__CONFIG 	_CP_OFF & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF & _HS_OSC & _LVP_OFF & _BOREN_OFF    

; Pin definitions
; PortA
MENU_BUTTON	EQU		H'04'
	
; ALL BANK
BUTTONS		EQU		H'70'

		ORG		H'0000'
INIT		
		MOVLW		H'07'
		MOVWF		CMCON
		BSF		STATUS,RP0	;Set Bank 1
		MOVLW		B'00010000'
		MOVWF		TRISA
		MOVLW		B'11110111'
		MOVWF		TRISB		;Set Port-B to all Output
		MOVLW		D'131'
		MOVWF		PR2

		MOVLW		B'01111111'
		MOVWF		OPTION_REG
		
		BCF		STATUS, RP0
		MOVLW		B'00000001'
		MOVWF		PORTA
		CLRF		PORTB
		
		MOVLW		B'00010001'
		MOVWF		T1CON
		
		MOVLW		B'00111100'
		IORWF		CCP1CON
		MOVLW		B'00111111'
		MOVWF		CCPR1L
		BSF		T2CON, TMR2ON
		
		BSF		RCSTA, SPEN
		BSF		STATUS, RP0
		BCF		TXSTA, SYNC
		MOVLW		D'129'
		MOVWF		SPBRG
		BSF		TXSTA, TXEN
		BCF		STATUS, RP0
		
		GOTO		START

IR_SEND
		MOVWF		TXREG
		BSF		STATUS, RP0
		BTFSS		TXSTA, TRMT
		GOTO		$ - 1
		BCF		STATUS, RP0
		RETURN

IR_COOLDOWN
		CLRF		TMR1H
		CLRF		TMR1L
		BCF		PIR1, TMR1IF
		BTFSS		PIR1, TMR1IF
		GOTO		$ - 1
		RETURN

START
		MOVLW		B'11110001'
		ANDWF		PORTB, W
		MOVWF		BUTTONS
		BTFSC		PORTA, MENU_BUTTON
		BSF		BUTTONS, 1
		MOVLW		B'11110011'
		XORWF		BUTTONS, W
		CALL		IR_SEND
		CALL		IR_COOLDOWN
		GOTO		START
		
		END
