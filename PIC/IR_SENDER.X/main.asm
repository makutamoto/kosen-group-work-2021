	LIST	P=PIC16F648A
	INCLUDE	<P16F648A.INC>
	__CONFIG 	_CP_OFF & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF & _HS_OSC & _LVP_OFF & _BOREN_OFF    

; Constants
CAMERA_ADDRESS	EQU		H'58'
	
; Pin definitions
I2C_SCL		EQU		H'03'
I2C_SDA		EQU		H'04'
	
; ALL BANK
ARG0		EQU		H'70'
ARG1		EQU		H'71'
ARG2		EQU		H'72'
TEMP0		EQU		H'73'
TEMP1		EQU		H'74'

		ORG		H'0000'
INIT		
		MOVLW		H'07'
		MOVWF		CMCON
		BSF		STATUS,RP0	;Set Bank 1
		CLRF		TRISA		;Set RA7-5 to Output and RA4-0 to Input 
		MOVLW		B'11110110'
		MOVWF		TRISB		;Set Port-B to all Output
		MOVLW		D'131'
		MOVWF		PR2
		
		MOVLW		B'01010010'
		MOVWF		OPTION_REG
		
		BCF		STATUS,RP0	;Set Bank 0
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

IR_COOLDOWN
		CLRF		TMR1H
		CLRF		TMR1L
		BCF		PIR1, TMR1IF
		BTFSS		PIR1, TMR1IF
		GOTO		$ - 1
		RETURN

START
		MOVFW		PORTB
		ANDLW		H'F0'
		MOVWF		TEMP0
		RRF		TEMP0, F
		RRF		TEMP0, F
		RRF		TEMP0, F
		RRF		TEMP0, F
		MOVWF		TXREG
		BSF		STATUS, RP0
		BTFSS		TXSTA, TRMT
		GOTO		$ - 1
		BCF		STATUS, RP0
		CALL		IR_COOLDOWN
		GOTO		START
		
		END
