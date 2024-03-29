	LIST	P=PIC16F648A
	INCLUDE	<P16F648A.INC>
	__CONFIG 	_CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _HS_OSC & _LVP_OFF & _BOREN_OFF    
	
; Pin definitions
; PortA
SHOOT_BUTTON	EQU		H'02'
RESET_BUTTON	EQU		H'04'

; bank 0
STATUS_TEMP	EQU		H'20'
; ALL BANK
BUTTON_FLAGS	EQU		H'70'
ROTARY0		EQU		H'71'
ROTARY1		EQU		H'72'
RB_OLD		EQU		H'73'
W_TEMP		EQU		H'74'
INT_TEMP0	EQU		H'75'
INT_TEMP1	EQU		H'76'

		ORG		H'0000'
		GOTO		INIT
		ORG		H'0004'
INTERRUPT
		MOVWF		W_TEMP
		SWAPF		STATUS, W
		BCF		STATUS, RP0
		MOVWF		STATUS_TEMP
		
		BTFSC		INTCON, RBIF
		GOTO		RB_MATCH
		GOTO		INTERRUPT_END
RB_MATCH
		MOVLW		H'F0'
		ANDWF		PORTB, W
		MOVWF		INT_TEMP0
		MOVLW		H'F0'
		ANDWF		RB_OLD, W
		SUBWF		INT_TEMP0, W
		BTFSC		STATUS, Z
		GOTO		RB_END
		
		MOVLW		B'01010000'
		XORWF		INT_TEMP0, W
		ANDWF		RB_OLD, W
		MOVWF		INT_TEMP1
		
		MOVFW		INT_TEMP0
		MOVWF		RB_OLD
RB_ROTARY0	
		BTFSS		INT_TEMP1, 4
		GOTO		RB_ROTARY1
		
		MOVLW		H'01'
		BTFSS		INT_TEMP0, 5
		MOVLW		-H'01'
		ADDWF		ROTARY0, F
RB_ROTARY1
		BTFSS		INT_TEMP1, 6
		GOTO		RB_END
		
		MOVLW		H'01'
		BTFSS		INT_TEMP0, 7
		MOVLW		-H'01'
		ADDWF		ROTARY1, F
RB_END
		BCF		INTCON, RBIF
		GOTO		INTERRUPT_END
INTERRUPT_END
		SWAPF		STATUS_TEMP, W
		MOVWF		STATUS
		SWAPF		W_TEMP, F
		SWAPF		W_TEMP, W
		
		RETFIE
INIT		
		MOVLW		H'07'
		MOVWF		CMCON
		BSF		STATUS, RP0
		MOVLW		B'00010100'
		MOVWF		TRISA
		MOVLW		B'11110110'
		MOVWF		TRISB
		MOVLW		D'131'
		MOVWF		PR2

		MOVLW		B'01111111'
		MOVWF		OPTION_REG
		
		BCF		STATUS, RP0
		CLRF		PORTA
		CLRF		PORTB
		
		MOVLW		B'10001000'
		MOVWF		INTCON
		
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
		
		MOVLW		H'FF'
		MOVWF		RB_OLD
		
		CLRF		ROTARY0
		CLRF		ROTARY1
		CLRF		BUTTON_FLAGS
		
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
		CLRF		BUTTON_FLAGS
		BTFSC		PORTA, RESET_BUTTON
		BSF		BUTTON_FLAGS, 0
		BTFSC		PORTA, SHOOT_BUTTON
		BSF		BUTTON_FLAGS, 1
		
		MOVFW		ROTARY0
		CLRF		ROTARY0
		ANDLW		B'00111111'
		CALL		IR_SEND
		MOVFW		ROTARY1
		CLRF		ROTARY1
		ANDLW		B'00111111'
		IORLW		B'01000000'
		CALL		IR_SEND
		MOVFW		BUTTON_FLAGS
		ANDLW		B'00111111'
		IORLW		B'10000000'
		CALL		IR_SEND
		CALL		IR_COOLDOWN
		
		GOTO		START
		
		END
