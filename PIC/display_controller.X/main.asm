	LIST	P=PIC16F648A
	INCLUDE	<P16F648A.INC>
	__CONFIG 	_CP_OFF & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF & _HS_OSC & _LVP_OFF & _BOREN_OFF    

	INCLUDE "TABLE.INC"
	
; Constants
PADDLE0_HIGH	EQU		D'80'
PADDLE0_LOW	EQU		D'83'
PADDLE1_HIGH	EQU		D'86'
PADDLE1_LOW	EQU		D'89'
BALL		EQU		D'92'
		
TABLE_TOP	EQU		D'7'
TABLE_BOTTOM	EQU		D'41'
TABLE_LEFT	EQU		D'1'
TABLE_RIGHT	EQU		D'26'
	
MATCH_POINT	EQU		D'5'
	
SOUND_WALL	EQU		B'00000001'
SOUND_PONG	EQU		B'00000010'
SOUND_SHOOT	EQU		B'00000100'
	
; Pin definitions
;PORTB
MASTER_BUSY	EQU		H'05'
	
; bank 0
STATUS_TEMP	EQU		H'20'
PADDLE0_Y	EQU		H'21'
PADDLE1_Y	EQU		H'22'
BALL_Y		EQU		H'23'
BALL_X		EQU		H'24'
BALL_VEL_Y	EQU		H'25'
BALL_VEL_X	EQU		H'26'
BALL_COUNTER	EQU		H'27'
POINT0		EQU		H'28'
POINT1		EQU		H'29'
SHOOT_FLAG	EQU		H'2A'
BALL_SPEED	EQU		H'2B'
PADDLE0_DY	EQU		H'2C'
PADDLE1_DY	EQU		H'2D'
BUTTON_FLAGS	EQU		H'2E' ; XXXXXXSR, R: Reset, S: Shoot
	
; ALL BANK
ARG0		EQU		H'70'
ARG1		EQU		H'71'
TEMP0		EQU		H'72'
TEMP1		EQU		H'73'
SLAVE_FREE	EQU		H'74'
W_TEMP		EQU		H'75'
INT_TEMP0	EQU		H'76'
INT_TEMP1	EQU		H'77'	
FSR_BACK	EQU		H'78'

		ORG		H'0000'
		GOTO		INIT
		ORG		H'0004'
INTERRUPT
		MOVWF		W_TEMP
		SWAPF		STATUS, W
		BCF		STATUS, RP0
		MOVWF		STATUS_TEMP
		
		BTFSC		INTCON, INTF
		GOTO		INT_MATCH
		BTFSC		PIR1, RCIF
		GOTO		RC_MATCH
		GOTO		INTERRUPT_END
INT_MATCH	
		BSF		SLAVE_FREE, 0
		BCF		INTCON, INTF
		GOTO		INTERRUPT_END
RC_MATCH
		MOVFW		FSR
		MOVWF		FSR_BACK
		
		MOVLW		PADDLE0_DY
		MOVWF		FSR
		MOVFW		RCREG
		MOVWF		INT_TEMP0
		ANDLW		B'11000000'
		MOVWF		INT_TEMP1
		BCF		STATUS, C
		RLF		INT_TEMP1, F
		RLF		INT_TEMP1, F
		RLF		INT_TEMP1, W
		ADDWF		FSR
		MOVLW		B'00111111'
		ANDWF		INT_TEMP0, W
		MOVWF		INDF
		
		MOVFW		FSR_BACK
		MOVWF		FSR
		
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
		BSF		STATUS,RP0
		CLRF		TRISA
		MOVLW		B'00000111'
		MOVWF		TRISB
		MOVLW		H'3F'
		MOVWF		PR2
		
		MOVLW		B'11010111'
		MOVWF		OPTION_REG
		
		MOVLW		B'00100000'
		MOVWF		PIE1
		
		BCF		STATUS, RP0
		CLRF		PORTA
		MOVLW		B'00100000'
		MOVWF		PORTB
		
		CLRF		TMR0
		
		MOVLW		B'00001100'
		IORWF		CCP1CON
		
		BSF		T2CON, TMR2ON
		MOVLW		H'0F'
		MOVWF		CCPR1L
		
		MOVLW		B'11010000'
		MOVWF		INTCON
		
		BSF		RCSTA, SPEN
		BSF		STATUS, RP0
		BCF		TXSTA, SYNC
		BSF		TXSTA, BRGH
		CLRF		SPBRG
		BSF		TXSTA, TXEN
		BCF		STATUS, RP0
		BSF		RCSTA, CREN
		
		CLRF		SLAVE_FREE
		
		CALL		NOP10CYCLES
		
		GOTO		INIT_GAME

SEND_COMMAND	; ARG0: address, ARG1: command
		BTFSS		SLAVE_FREE, 0
		GOTO		$ - 1
		BCF		INTCON, INTE
		BCF		PORTB, MASTER_BUSY
		MOVFW		ARG0
		MOVWF		TXREG
		MOVFW		ARG1
		MOVWF		TXREG
		BSF		STATUS, RP0
		BTFSS		TXSTA, TRMT
		GOTO		$ - 1
		BCF		STATUS, RP0
		BSF		PORTB, MASTER_BUSY
		BCF		INTCON, INTF
		BSF		INTCON, INTE
		BCF		SLAVE_FREE, 0
		RETURN

SET_POS_Y	MACRO		SPRITE, Y
		MOVLW		SPRITE
		MOVWF		ARG0
		MOVFW		Y
		SUBLW		H'00'
		MOVWF		ARG1
		CALL		SEND_COMMAND
		ENDM
		
SET_POS_X	MACRO		SPRITE, X
		MOVLW		SPRITE + 1
		MOVWF		ARG0
		MOVFW		X
		MOVWF		ARG1
		CALL		SEND_COMMAND
		ENDM
		
SET_SPRITE	MACRO		SPRITE, TILE
		MOVLW		SPRITE + 2
		MOVWF		ARG0
		MOVLW		TILE
		MOVWF		ARG1
		CALL		SEND_COMMAND
		ENDM
		
SET_BACKGROUND	MACRO		Y, X, TILE
		MOVLW		Y * D'10' + X
		MOVWF		ARG0
		MOVLW		TILE
		MOVWF		ARG1
		CALL		SEND_COMMAND
		ENDM
		
SET_BACKGROUND_W    MACRO		Y, X
		MOVWF		ARG1
		MOVLW		Y * D'10' + X
		MOVWF		ARG0
		CALL		SEND_COMMAND
		ENDM

BACKGROUND
		SET_BACKGROUND	0, 0, TILE_ZERO
		SET_BACKGROUND	0, 1, TILE_TITLE_BACKGROUND
		SET_BACKGROUND	0, 2, TILE_TITLE_BACKGROUND_EDGE
		SET_BACKGROUND	0, 3, TILE_P
		SET_BACKGROUND	0, 4, TILE_O
		SET_BACKGROUND	0, 5, TILE_N
		SET_BACKGROUND	0, 6, TILE_G
		SET_BACKGROUND	0, 7, TILE_TITLE_BACKGROUND
		SET_BACKGROUND	0, 8, TILE_TITLE_BACKGROUND_EDGE
		SET_BACKGROUND	0, 9, TILE_ZERO
		
		SET_BACKGROUND	1, 0, TILE_TOP_LEFT_CORNER
		SET_BACKGROUND	1, 1, TILE_TOP
		SET_BACKGROUND	1, 2, TILE_TOP
		SET_BACKGROUND	1, 3, TILE_TOP
		SET_BACKGROUND	1, 4, TILE_TOP_CENTER
		SET_BACKGROUND	1, 5, TILE_TOP
		SET_BACKGROUND	1, 6, TILE_TOP
		SET_BACKGROUND	1, 7, TILE_TOP
		SET_BACKGROUND	1, 8, TILE_TOP
		SET_BACKGROUND	1, 9, TILE_TOP_RIGHT_CORNER
		
		SET_BACKGROUND	2, 0, TILE_LEFT
		SET_BACKGROUND	2, 1, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 2, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 3, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 4, TILE_CENTER
		SET_BACKGROUND	2, 5, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 6, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 7, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 8, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	2, 9, TILE_RIGHT
		
		SET_BACKGROUND	3, 0, TILE_LEFT
		SET_BACKGROUND	3, 1, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 2, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 3, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 4, TILE_CENTER
		SET_BACKGROUND	3, 5, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 6, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 7, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 8, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	3, 9, TILE_RIGHT
		
		SET_BACKGROUND	4, 0, TILE_LEFT
		SET_BACKGROUND	4, 1, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 2, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 3, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 4, TILE_CENTER
		SET_BACKGROUND	4, 5, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 6, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 7, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 8, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	4, 9, TILE_RIGHT
		
		SET_BACKGROUND	5, 0, TILE_LEFT
		SET_BACKGROUND	5, 1, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 2, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 3, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 4, TILE_CENTER
		SET_BACKGROUND	5, 5, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 6, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 7, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 8, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	5, 9, TILE_RIGHT
		
		SET_BACKGROUND	6, 0, TILE_LEFT
		SET_BACKGROUND	6, 1, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 2, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 3, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 4, TILE_CENTER
		SET_BACKGROUND	6, 5, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 6, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 7, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 8, TILE_TABLE_BACKGROUND
		SET_BACKGROUND	6, 9, TILE_RIGHT
		
		SET_BACKGROUND	7, 0, TILE_BOTTOM_LEFT_CORNER
		SET_BACKGROUND	7, 1, TILE_BOTTOM
		SET_BACKGROUND	7, 2, TILE_BOTTOM
		SET_BACKGROUND	7, 3, TILE_BOTTOM
		SET_BACKGROUND	7, 4, TILE_BOTTOM_CENTER
		SET_BACKGROUND	7, 5, TILE_BOTTOM
		SET_BACKGROUND	7, 6, TILE_BOTTOM
		SET_BACKGROUND	7, 7, TILE_BOTTOM
		SET_BACKGROUND	7, 8, TILE_BOTTOM
		SET_BACKGROUND	7, 9, TILE_BOTTOM_RIGHT_CORNER
		RETURN
		
SPEED_UP
		DECF		BALL_SPEED, F
		MOVF		BALL_SPEED, F
		MOVLW		H'01'
		BTFSC		STATUS, Z
		MOVWF		BALL_SPEED
		RETURN
		
PLAY_SOUND
		BCF		PORTA, 0
		BCF		PORTA, 1
		BCF		PORTA, 2
		ANDLW		H'0F'
		IORWF		PORTA, F
		RETURN

INIT_GAME
		SET_SPRITE	PADDLE0_HIGH, TILE_PADDLE0
		SET_SPRITE	PADDLE0_LOW, TILE_PADDLE0
		
		SET_SPRITE	PADDLE1_HIGH, TILE_PADDLE1
		SET_SPRITE	PADDLE1_LOW, TILE_PADDLE1
		
		SET_SPRITE	BALL, TILE_BALL
		
		CLRF		TEMP0
		SET_POS_X	PADDLE0_HIGH, TEMP0
		SET_POS_X	PADDLE0_LOW, TEMP0
		MOVLW		D'27'
		MOVWF		TEMP0
		SET_POS_X	PADDLE1_HIGH, TEMP0
		SET_POS_X	PADDLE1_LOW, TEMP0
START
		CLRF		PADDLE0_DY
		CLRF		PADDLE1_DY
		CLRF		BUTTON_FLAGS
		CLRF		SHOOT_FLAG
		
		CALL		BACKGROUND
		
		CLRF		POINT0
		CLRF		POINT1
		
		MOVLW		(TABLE_TOP + (TABLE_BOTTOM + D'6')) / D'2' - D'6'
		MOVWF		PADDLE0_Y
		MOVWF		PADDLE1_Y
		
GAME
		MOVLW		H'06'
		MOVWF		BALL_SPEED
		CLRF		BALL_COUNTER
LOOP
		BTFSS		INTCON, T0IF
		GOTO		$ - 1
		BCF		INTCON, T0IF
		
		BTFSC		BUTTON_FLAGS, 0
		GOTO		START
		BCF		BUTTON_FLAGS, 0
		
		MOVLW		-D'1'
		BTFSC		BUTTON_FLAGS, 1
		MOVWF		SHOOT_FLAG
		BCF		BUTTON_FLAGS, 1
		
PADDLE0_POS
		MOVFW		PADDLE0_DY
		MOVWF		TEMP0
		MOVLW		B'11000000'
		BTFSC		TEMP0, 5
		IORWF		TEMP0, F
		MOVFW		TEMP0
		ADDWF		PADDLE0_Y
		CLRF		PADDLE0_DY
		
		MOVLW		TABLE_TOP
		SUBWF		PADDLE0_Y, W
		MOVWF		TEMP0
		MOVLW		TABLE_TOP
		BTFSC		TEMP0, 7
		MOVWF		PADDLE0_Y
		MOVLW		TABLE_BOTTOM - D'6'
		SUBWF		PADDLE0_Y, W
		MOVLW		TABLE_BOTTOM - D'6'
		BTFSC		STATUS, C
		MOVWF		PADDLE0_Y
PADDLE1_POS
		MOVFW		PADDLE1_DY
		MOVWF		TEMP0
		MOVLW		B'11000000'
		BTFSC		TEMP0, 5
		IORWF		TEMP0, F
		MOVFW		TEMP0
		ADDWF		PADDLE1_Y
		CLRF		PADDLE1_DY
		
		MOVLW		TABLE_TOP
		SUBWF		PADDLE1_Y, W
		MOVWF		TEMP0
		MOVLW		TABLE_TOP
		BTFSC		TEMP0, 7
		MOVWF		PADDLE1_Y
		MOVLW		TABLE_BOTTOM - 6
		SUBWF		PADDLE1_Y, W
		MOVLW		TABLE_BOTTOM - 6
		BTFSC		STATUS, C
		MOVWF		PADDLE1_Y
		
		SET_POS_Y	PADDLE0_HIGH, PADDLE0_Y
		MOVLW		H'06'
		ADDWF		PADDLE0_Y, W
		MOVWF		TEMP0
		SET_POS_Y	PADDLE0_LOW, TEMP0
		
		MOVF		SHOOT_FLAG, F
		BTFSS		STATUS, Z
		GOTO		PADDLE1_SET_POS
		MOVFW		PADDLE0_Y
		ADDLW		D'3'
		MOVWF		BALL_Y
		MOVLW		D'2'
		MOVWF		BALL_X
		
		MOVLW		H'01'
		MOVWF		BALL_VEL_Y
		MOVWF		BALL_VEL_X
		
PADDLE1_SET_POS
		SET_POS_Y	PADDLE1_HIGH, PADDLE1_Y
		MOVLW		H'06'
		ADDWF		PADDLE1_Y, W
		MOVWF		TEMP0
		SET_POS_Y	PADDLE1_LOW, TEMP0
		
		MOVLW		H'01'
		SUBWF		SHOOT_FLAG, W
		BTFSS		STATUS, Z
		GOTO		POINT
		MOVFW		PADDLE1_Y
		ADDLW		D'3'
		MOVWF		BALL_Y
		MOVLW		D'25'
		MOVWF		BALL_X
		
		MOVLW		-H'01'
		MOVWF		BALL_VEL_Y
		MOVWF		BALL_VEL_X
		
POINT
		MOVFW		POINT0
		SET_BACKGROUND_W    0, 0
		MOVFW		POINT1
		SET_BACKGROUND_W    0, 9

WIN_CHECK0
		MOVLW		MATCH_POINT
		SUBWF		POINT0, W
		BTFSS		STATUS, Z
		GOTO		WIN_CHECK1
		SET_BACKGROUND	4, 1, TILE_W
		SET_BACKGROUND	4, 2, TILE_I
		SET_BACKGROUND	4, 3, TILE_WIN_N
		MOVLW		-D'6'
		MOVWF		TEMP0
		SET_POS_Y	BALL, TEMP0
		GOTO		GAME
WIN_CHECK1
		MOVLW		MATCH_POINT
		SUBWF		POINT1, W
		BTFSS		STATUS, Z
		GOTO		MOVE_BALL
		SET_BACKGROUND	4, 6, TILE_W
		SET_BACKGROUND	4, 7, TILE_I
		SET_BACKGROUND	4, 8, TILE_WIN_N
		MOVLW		-D'6'
		MOVWF		TEMP0
		SET_POS_Y	BALL, TEMP0
		GOTO		GAME
MOVE_BALL
		SET_POS_Y	BALL, BALL_Y
		SET_POS_X	BALL, BALL_X
		
		BTFSS		SHOOT_FLAG, 7
		GOTO		GAME
		
		INCF		BALL_COUNTER, F
		MOVFW	    	BALL_SPEED
		SUBWF		BALL_COUNTER, W
		BTFSS		STATUS, Z
		GOTO		LOOP
		CLRF		BALL_COUNTER
VERTICAL
		MOVFW		BALL_VEL_Y
		ADDWF		BALL_Y, F
TOP_CHECK
		MOVLW		TABLE_TOP - D'2'
		SUBWF		BALL_Y, W
		MOVWF		TEMP0
		BTFSS		TEMP0, 7
		GOTO		BOTTOM_CHECK
		MOVLW		TABLE_TOP - D'2'
		MOVWF		BALL_Y
		MOVFW		BALL_VEL_Y
		SUBLW		H'00'
		MOVWF		BALL_VEL_Y
		MOVLW		SOUND_WALL
		CALL		PLAY_SOUND
BOTTOM_CHECK
		MOVLW		TABLE_BOTTOM + D'2'
		SUBWF		BALL_Y, W
		BTFSS		STATUS, C
		GOTO		HORIZONTAL
		MOVLW		TABLE_BOTTOM + D'2'
		MOVWF		BALL_Y
		MOVFW		BALL_VEL_Y
		SUBLW		H'00'
		MOVWF		BALL_VEL_Y
		MOVLW		SOUND_WALL
		CALL		PLAY_SOUND
HORIZONTAL
		MOVFW		BALL_VEL_X
		ADDWF		BALL_X, F
LEFT_CHECK
		MOVLW		TABLE_LEFT + D'1'
		SUBWF		BALL_X, W
		MOVWF		TEMP0
		BTFSS		TEMP0, 7
		GOTO		RIGHT_CHECK
		MOVFW		PADDLE0_Y
		ADDLW		-H'02'
		SUBWF		BALL_Y, W
		MOVWF		TEMP0
		BTFSC		TEMP0, 7
		GOTO		RIGHT_CHECK
		MOVFW		PADDLE0_Y
		ADDLW		D'10'
		SUBWF		BALL_Y, W
		MOVWF		TEMP0
		BTFSS		TEMP0, 7
		GOTO		RIGHT_CHECK
		MOVLW		TABLE_LEFT + D'1'
		MOVWF		BALL_X
		MOVFW		BALL_VEL_X
		SUBLW		H'00'
		MOVWF		BALL_VEL_X
		CALL		SPEED_UP
		MOVLW		SOUND_PONG
		CALL		PLAY_SOUND
RIGHT_CHECK
		MOVLW		TABLE_RIGHT - D'1'
		SUBWF		BALL_X, W
		MOVWF		TEMP0
		BTFSC		TEMP0, 7
		GOTO		LEFT_FAIL_CHECK
		MOVFW		PADDLE1_Y
		ADDLW		-H'02'
		SUBWF		BALL_Y, W
		MOVWF		TEMP0
		BTFSC		TEMP0, 7
		GOTO		LEFT_FAIL_CHECK
		MOVFW		PADDLE1_Y
		ADDLW		D'10'
		SUBWF		BALL_Y, W
		MOVWF		TEMP0
		BTFSS		TEMP0, 7
		GOTO		LEFT_FAIL_CHECK
		MOVLW		TABLE_RIGHT - D'1'
		MOVWF		BALL_X
		MOVFW		BALL_VEL_X
		SUBLW		H'00'
		MOVWF		BALL_VEL_X
		CALL		SPEED_UP
		MOVLW		SOUND_PONG
		CALL		PLAY_SOUND
LEFT_FAIL_CHECK
		MOVLW		TABLE_LEFT
		SUBWF		BALL_X, W
		MOVWF		TEMP0
		BTFSS		TEMP0, 7
		GOTO		RIGHT_FAIL_CHECK
		INCF		POINT1, F
		CLRF		SHOOT_FLAG
		MOVLW		SOUND_SHOOT
		CALL		PLAY_SOUND
		GOTO		GAME
RIGHT_FAIL_CHECK
		MOVLW		TABLE_RIGHT
		SUBWF		BALL_X, W
		BTFSS		STATUS, C
		GOTO		CHECK_END
		INCF		POINT0, F
		MOVLW		H'01'
		MOVWF		SHOOT_FLAG
		MOVLW		SOUND_SHOOT
		CALL		PLAY_SOUND
		GOTO		GAME
CHECK_END	
		GOTO		LOOP

NOP10CYCLES	NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		RETURN
		
		END
