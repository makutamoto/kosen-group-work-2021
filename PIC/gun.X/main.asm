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
TEMP0		EQU		H'72'
TEMP1		EQU		H'73'

		ORG		H'0000'
INIT		
		MOVLW		H'07'
		MOVWF		CMCON
		BSF		STATUS,RP0	;Set Bank 1
		CLRF		TRISA		;Set RA7-5 to Output and RA4-0 to Input 
		MOVLW		B'00000110'
		MOVWF		TRISB		;Set Port-B to all Output
		MOVLW		H'3F'
		MOVWF		PR2
		
		BCF		STATUS,RP0	;Set Bank 0
		MOVLW		B'00000001'
		MOVWF		PORTA
		CLRF		PORTB
		
		MOVLW		B'00001100'
		IORWF		CCP1CON
		
		BSF		T2CON, TMR2ON
		;MOVLW		H'0F'
		MOVLW		H'00'
		MOVWF		CCPR1L
		;GOTO		$
		
		MOVLW		B'11000000'
		IORWF		INTCON, F
		
		BSF		RCSTA, SPEN
		BSF		STATUS, RP0
		BCF		TXSTA, SYNC
		BSF		TXSTA, BRGH
		MOVLW		D'10'
		MOVWF		SPBRG
		BSF		TXSTA, TXEN
		BCF		STATUS, RP0
		
		CALL		INIT_CAMERA
		
		GOTO		START

UART
		MOVWF		TXREG
		BSF		STATUS, RP0
		BTFSS		TXSTA, TRMT
		GOTO		$ - 1
		BCF		STATUS, RP0
		RETURN
		
I2C_SCL_LOW
		BCF		PORTA, I2C_SCL
		CALL		NOP10CYCLES
		RETURN

I2C_SCL_HIGH
		BSF		PORTA, I2C_SCL
		CALL		NOP10CYCLES
		RETURN
		
I2C_SCL_INPUT
		BSF		STATUS, RP0
		BSF		TRISA, I2C_SCL
		BCF		STATUS, RP0
		RETURN
		
I2C_SCL_OUTPUT
		BSF		STATUS, RP0
		BCF		TRISA, I2C_SCL
		BCF		STATUS, RP0
		RETURN
		
I2C_SDA_LOW
		BCF		PORTA, I2C_SDA
		CALL		NOP10CYCLES
		RETURN

I2C_SDA_HIGH
		BSF		PORTA, I2C_SDA
		CALL		NOP10CYCLES
		RETURN
		
I2C_SDA_INPUT
		BSF		STATUS, RP0
		BSF		TRISA, I2C_SDA
		BCF		STATUS, RP0
		RETURN
		
I2C_SDA_OUTPUT
		BSF		STATUS, RP0
		BCF		TRISA, I2C_SDA
		BCF		STATUS, RP0
		RETURN
		
I2C_START_CONDITION
		CALL		I2C_SDA_LOW
		CALL		I2C_SCL_LOW
		RETURN
		
I2C_STOP_CONDITION
		CALL		I2C_SCL_HIGH
		CALL		I2C_SDA_HIGH
		RETURN
		
I2C_SEND_DATA
		MOVWF		TEMP0
		MOVLW		H'08'
		MOVWF		TEMP1
I2C_SEND_DATA_LOOP
		BTFSC		TEMP0, 7
		GOTO		I2C_SEND_DATA_LOOP_SDA_1
		CALL		I2C_SDA_LOW
		GOTO		I2C_SEND_DATA_LOOP_SDA_END
I2C_SEND_DATA_LOOP_SDA_1
		CALL		I2C_SDA_HIGH
I2C_SEND_DATA_LOOP_SDA_END
		RLF		TEMP0, F
		CALL		I2C_SCL_HIGH
		CALL		I2C_SCL_LOW
		DECFSZ		TEMP1, F
		GOTO		I2C_SEND_DATA_LOOP
		CALL		I2C_SDA_HIGH
		CALL		I2C_SDA_INPUT
		CALL		I2C_SCL_HIGH
		BTFSC		PORTA, I2C_SDA
		GOTO		I2C_SEND_DATA_SUCCESS
		CALL		I2C_SCL_LOW
		CALL		I2C_SDA_OUTPUT
		CALL		I2C_SDA_LOW
		RETLW		H'01'
I2C_SEND_DATA_SUCCESS
		CALL		I2C_SCL_LOW
		CALL		I2C_SDA_OUTPUT
		CALL		I2C_SDA_LOW
		CALL		I2C_SCL_INPUT
		BTFSS		PORTA, I2C_SCL
		GOTO		$ - 1
		CALL		I2C_SCL_OUTPUT
		CALL		I2C_SCL_LOW
		RETLW		H'00'
		
I2C_READ_DATA
		CLRF		TEMP0
		CALL		I2C_SDA_INPUT
		MOVLW		H'08'
		MOVWF		TEMP1
I2C_READ_DATA_LOOP
		RLF		TEMP0, F
		CALL		I2C_SCL_HIGH
		BTFSC		PORTA, I2C_SDA
		BSF		TEMP0, 0
		CALL		I2C_SCL_LOW
		DECFSZ		TEMP1, F
		GOTO		I2C_READ_DATA_LOOP
		CALL		I2C_SDA_OUTPUT
		CALL		I2C_SDA_LOW
		CALL		I2C_SCL_HIGH
		CALL		I2C_SCL_LOW
		MOVFW		TEMP0
		CALL		UART
		RETURN
	
WRITE_CAMERA	; ARG0: Address, ARG1: data
		CALL		I2C_START_CONDITION
		MOVLW		CAMERA_ADDRESS << 1
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		WRITE_CAMERA_FAIL
		MOVFW		ARG0
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		WRITE_CAMERA_FAIL
		MOVFW		ARG1
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		WRITE_CAMERA_FAIL
		CALL		I2C_STOP_CONDITION		
		RETURN
WRITE_CAMERA_FAIL
		CALL		I2C_STOP_CONDITION
		GOTO		WRITE_CAMERA		

READ_CAMERA
		CALL		I2C_START_CONDITION
		MOVLW		CAMERA_ADDRESS << 1
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		READ_CAMERA_FAIL
		MOVLW		H'36'
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		READ_CAMERA_FAIL
		CALL		I2C_STOP_CONDITION
		
		CALL		I2C_START_CONDITION
		MOVLW		CAMERA_ADDRESS << 1 | 1
		CALL		I2C_SEND_DATA
		ADDLW		H'00'
		BTFSC		STATUS, Z
		GOTO		READ_CAMERA_FAIL
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_READ_DATA
		CALL		I2C_STOP_CONDITION		
		RETURN
READ_CAMERA_FAIL
		CALL		I2C_STOP_CONDITION
		GOTO		READ_CAMERA		
		
INIT_CAMERA
		MOVLW		H'30'
		MOVWF		ARG0
		MOVLW		H'01'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		MOVLW		H'30'
		MOVWF		ARG0
		MOVLW		H'08'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		MOVLW		H'06'
		MOVWF		ARG0
		MOVLW		H'90'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		MOVLW		H'08'
		MOVWF		ARG0
		MOVLW		H'C0'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		MOVLW		H'1A'
		MOVWF		ARG0
		MOVLW		H'40'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		MOVLW		H'33'
		MOVWF		ARG0
		MOVLW		H'33'
		MOVWF		ARG1
		CALL		WRITE_CAMERA
		
		RETURN
START	
		CALL		READ_CAMERA
		GOTO		START
		
;Subroutine for waiting 10-micro-second		;0.25-micro*4-Clock*(2+8)-Cycle=10-micro
NOP10CYCLES	NOP				;1-Cycle
		NOP				;1-Cycle
		NOP				;1-Cycle
		NOP				;1-Cycle
		NOP				;1-Cycle
		NOP				;1-Cycle
		RETURN				;2-Cycle  Total 8-Cycle
		
		END
