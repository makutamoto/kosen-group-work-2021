	LIST	P=PIC16F648A
	INCLUDE	<P16F648A.INC>
	__CONFIG 	_CP_OFF & _MCLRE_OFF & _PWRTE_OFF & _WDT_OFF & _HS_OSC & _LVP_OFF & _BOREN_OFF    

; PIN definition
; PORTA
VSYNC_PIN	EQU		H'00'
HSYNC_PIN	EQU		H'02'
; PORTB
MASTER_BUSY	EQU		H'00' ; active low
	
; Bank 0
SCREEN_BUFFER0	EQU		H'20'	; 0x20-3D
SCREEN_BUFFER1	EQU		H'3E'	; 0x3E-5B
; Sprite area, each sprite occuoy 3 bytes: Y X TILE
SPRITE0		EQU		H'5C'
SPRITE1		EQU		H'5F'
SPRITE2		EQU		H'62'
SPRITE3		EQU		H'65'
SPRITE4		EQU		H'68'
SPRITE5		EQU		H'6B'
SPRITE6		EQU		H'6E'

; Bank 1
TILE_MAP	EQU		H'A0'	; 0xA0-EF
	
; ALL BANK
TEMP0		EQU		H'71'
TEMP1		EQU		H'72'
TILE_ROW	EQU		H'73'
MAP_INDEX	EQU		H'74'
MAP_INDEX_TEMP	EQU		H'75'
FSR_BACK	EQU		H'76'
FILL_COLOR	EQU		H'77' ; B'BBBB000A' A: Flag, B: Color
CURRENT_BUFFER	EQU		H'78'
DRAWED_PAST	EQU		H'79'
TILE_ROW_BACK	EQU		H'7A'
CURRENT_BUFFER_ADDR	EQU	H'7B'
TEMP2		EQU		H'7C'
TEMP3		EQU		H'7D'

COLORBAR	MACRO
	VARIABLE I
I = 0
	WHILE	I < D'45'
		MOVLW	((I & H'0F') << 4) | ((I + 1) & H'0F')
		MOVWF	SCREEN_BUFFER + I / 2
I += 2
	ENDW
		ENDM
		
CLEAR_TILEMAP	MACRO
		LOCAL		LOOP
		MOVLW		TILE_MAP
		MOVWF		FSR
		CLRF		TEMP1
		MOVLW		D'80'
		MOVWF		TEMP0
LOOP:
		MOVFW		TEMP1
		MOVWF		INDF
		INCF		TEMP1, F
		ADDLW		-D'15'
		BTFSC		STATUS, Z
		CLRF		TEMP1
		INCF		FSR, F
		DECFSZ		TEMP0, F
		GOTO		LOOP
		ENDM
	
		ORG		H'0000'		;Reset Start
INIT		MOVLW		H'07'
		MOVWF		CMCON
		
		BSF		STATUS, RP0
		CLRF		TRISA 
		MOVLW		B'00001111'
		MOVWF		TRISB
		BCF		STATUS, RP0
		
		BSF		RCSTA, SPEN
		BSF		STATUS, RP0
		BCF		TXSTA, SYNC
		BSF		TXSTA, BRGH
		CLRF		SPBRG
		BSF		TXSTA, TXEN
		BCF		STATUS, RP0
		BSF		RCSTA, CREN
		
		BSF		PORTA, VSYNC_PIN
		CLRF		PORTB
		
		CLRF		CURRENT_BUFFER
		
		CLEAR_TILEMAP
		
		CLRF		DRAWED_PAST
		MOVLW		H'01'
		MOVWF		FILL_COLOR
		
		CLRF		SPRITE0
		CLRF		SPRITE0 + 1
		CLRF		SPRITE0 + 2
		
		CLRF		SPRITE1
		MOVLW		H'03'
		MOVWF		SPRITE1 + 1
		CLRF		SPRITE1 + 2
		
		CLRF		SPRITE2
		MOVLW		H'06'
		MOVWF		SPRITE2 + 1
		CLRF		SPRITE2 + 2
		
		CLRF		SPRITE3
		MOVLW		H'09'
		MOVWF		SPRITE3 + 1
		CLRF		SPRITE3 + 2
		
		CLRF		SPRITE4
		MOVLW		H'0C'
		MOVWF		SPRITE4 + 1
		CLRF		SPRITE4 + 2
		
		CLRF		SPRITE5
		MOVLW		H'0F'
		MOVWF		SPRITE5 + 1
		CLRF		SPRITE5 + 2
		
		CLRF		SPRITE6
		MOVLW		H'12'
		MOVWF		SPRITE6 + 1
		CLRF		SPRITE6 + 2
		
		GOTO		DRAW_DISPLAY

CALC_PIXELS	MACRO
		MOVLW		high TILE_TABLE
		MOVWF		PCLATH
		MOVFW		FSR
		MOVWF		FSR_BACK
		MOVFW		MAP_INDEX_TEMP
		MOVWF		FSR
		MOVFW		INDF
		MOVWF		TEMP1
		INCF		MAP_INDEX_TEMP, F
		MOVFW		FSR_BACK
		MOVWF		FSR
		MOVFW		TEMP1
		CALL		TILE_TABLE
		ENDM

CALC_SPRITE	MACRO		SPRITE
		LOCAL		SPRITE_UPPER, SPRITE_LOWER
		MOVFW		SPRITE
		MOVWF		TILE_ROW
		BTFSC		SPRITE, 7
		GOTO		SPRITE_UPPER
		SUBLW		H'05'
		BTFSS		STATUS, C
		GOTO		SPRITE_LOWER
		BCF		STATUS, C
		RLF		TILE_ROW, F
		RLF		TILE_ROW, F
		RLF		TILE_ROW, F
		RLF		SPRITE, W
		ADDWF		TILE_ROW, F
		MOVLW		high TILE_TABLE
		MOVWF		PCLATH
		MOVFW		SPRITE + 1
		ADDWF		CURRENT_BUFFER_ADDR, W
		MOVWF		FSR
		MOVFW		SPRITE + 2
		CALL		TILE_TABLE
		CLRF		PCLATH
		GOTO		$ + 8
SPRITE_UPPER:
		NOP
		NOP
		NOP
SPRITE_LOWER:
		CALL	    NOP10CYCLES
		CALL	    NOP10CYCLES
		CALL	    NOP8CYCLES
		CALL	    NOP8CYCLES
		ENDM

RECEIVE_DATA	; 69 cycles
		BTFSS		PORTB, MASTER_BUSY
		GOTO		RECEIVE_DATA_BUSY
		BTFSS		PIR1, RCIF
		GOTO		RECEIVE_DATA_NO_DATA
		MOVFW		RCREG
		MOVWF		TEMP1
		MOVFW		RCREG
		MOVWF		TEMP2
		MOVLW		H'00'
		MOVWF		TXREG
		MOVLW		H'50'
		SUBWF		TEMP1, F
		MOVLW		TILE_MAP + H'50'
		BTFSC		STATUS, C
		MOVLW		SPRITE0
		ADDWF		TEMP1, W
		MOVWF		FSR
		MOVFW		TEMP2
		MOVWF		INDF
		GOTO		RECEIVE_DATA_END
RECEIVE_DATA_BUSY
		CALL		NOP10CYCLES
		CALL		NOP6CYCLES
		GOTO		RECEIVE_DATA_END
RECEIVE_DATA_NO_DATA
		MOVLW		H'00'
		MOVWF		TXREG
		CALL		NOP10CYCLES
		CALL		NOP4CYCLES
RECEIVE_DATA_END
		CALL		NOP10CYCLES
		CALL		NOP10CYCLES
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		CALL		NOP6CYCLES
		RETURN
		
DRAW_BUFFER	MACRO	BUFFER
	VARIABLE I
		NOP
		NOP
I = 0
	WHILE	I < D'30'
		MOVFW		BUFFER + I
		MOVWF		PORTB
		SWAPF		BUFFER + I, W
		MOVWF		PORTB
I += 1
	ENDW
		NOP
		CLRF		PORTB
		ENDM
		
HSYNC_TYPE_VSYNCSTART	EQU	H'00'
HSYNC_TYPE_VSYNCEND	EQU	H'01'
HSYNC_TYPE_CALIB	EQU	H'02'
HSYNC_TYPE_PRE_DRAW	EQU	H'03' ; ARG1: PREDRAW_NUM
HSYNC_TYPE_DRAW		EQU	H'04'
HSYNC_TYPE_END		EQU	H'05'
HSYNC_TYPE_SPRITE0	EQU	H'06'
HSYNC_TYPE_SPRITE1	EQU	H'07'
HSYNC		MACRO		TYPE, ARG0	; Wait 18 instructions after SYNC.
	;   Start of rising edge
	LOCAL		FILL_DRAW, DRAW_BUFFER1, END_DRAW, NOT_ONE_LINE, ONE_LINE
	variable	I
	IF	TYPE == HSYNC_TYPE_VSYNCSTART
		MOVLW		B'0000101'
		XORWF		PORTA, F
	ELSE
		NOP
		BSF		PORTA, HSYNC_PIN
	ENDIF
	;   End of falling edge
	
	;	free space 139 cycles
	IF	TYPE == HSYNC_TYPE_PRE_DRAW
		BSF		STATUS, RP0
		CALC_PIXELS
		CALC_PIXELS	
	IF	ARG0 < 2
		CALC_PIXELS
		CALC_PIXELS
		CLRF		PCLATH
		BCF		STATUS, RP0
	ELSE
		BCF		STATUS, RP0
		CLRF		PCLATH
		MOVLW		H'0A'
		ADDWF		TILE_ROW
		MOVLW		D'60'
		SUBWF		TILE_ROW, W
		BTFSS		STATUS, Z
		GOTO		NOT_ONE_LINE
		CLRF		TILE_ROW
		MOVLW		H'0A'
		ADDWF		MAP_INDEX, F
		MOVLW		H'F0'
		SUBWF		MAP_INDEX, W
		MOVLW		TILE_MAP
		BTFSC		STATUS, Z
		MOVWF		MAP_INDEX
		GOTO		ONE_LINE
NOT_ONE_LINE:
		CALL		NOP8CYCLES
		NOP
ONE_LINE:	
		MOVFW		TILE_ROW
		MOVWF		TILE_ROW_BACK
		CALC_SPRITE	SPRITE0
		CALL		NOP6CYCLES
	ENDIF
	ELSE
	IF	TYPE == HSYNC_TYPE_DRAW
		NOP
		CALL		NOP4CYCLES
		BTFSC		FILL_COLOR, 0
		GOTO		FILL_DRAW
		BTFSC		CURRENT_BUFFER, 0
		GOTO		DRAW_BUFFER1
		NOP
		DRAW_BUFFER	SCREEN_BUFFER0
		NOP
		NOP
		GOTO		END_DRAW
DRAW_BUFFER1:
		DRAW_BUFFER	SCREEN_BUFFER1
		NOP
		NOP
		GOTO		END_DRAW
FILL_DRAW:
		CALL		NOP4CYCLES
		MOVFW		FILL_COLOR
		MOVWF		PORTB
I = 0
	WHILE	I < D'11'
		CALL		NOP10CYCLES
I += 1
	ENDW
		CALL		NOP8CYCLES
		NOP
		CLRF		PORTB
		CALL		NOP4CYCLES
		
END_DRAW:	
		NOP
	ELSE
	IF  TYPE == HSYNC_TYPE_SPRITE0
		CALC_SPRITE	SPRITE1
		CALC_SPRITE	SPRITE2
		CALC_SPRITE	SPRITE3
		CALL		NOP6CYCLES
		NOP
	ELSE
	IF  TYPE == HSYNC_TYPE_SPRITE1
		CALC_SPRITE	SPRITE4
		CALC_SPRITE	SPRITE5
		CALC_SPRITE	SPRITE6
		CALL		NOP6CYCLES
		NOP
	ELSE
		CALL		RECEIVE_DATA
		CALL		RECEIVE_DATA
		NOP
	ENDIF
	ENDIF
	ENDIF
	ENDIF
	
	;   Start of falling edge
	IF	TYPE == HSYNC_TYPE_VSYNCEND
		MOVLW		B'00000101'
		XORWF		PORTA, F
	ELSE
		NOP
		BCF		PORTA, HSYNC_PIN
	ENDIF
	;   End of falling edge
		ENDM

CALIBRATION	MACRO		COUNT ; before: 4 cycles, after: 5 cycles
		LOCAL		LOOP, NOT_ZERO, ZERO
		MOVLW		COUNT
		MOVWF		TEMP0
LOOP:		HSYNC		HSYNC_TYPE_CALIB, 0
		DECFSZ		TEMP0, F
		GOTO		NOT_ZERO
		GOTO		ZERO
NOT_ZERO:	CALL		NOP10CYCLES
		NOP
		NOP
		NOP
		GOTO		LOOP
ZERO:		NOP
		ENDM
		
SEND_DATA	MACRO		; before: 15 cycles, after: 6 cycles
		LOCAL		LOOP, NOT_ONE_LINE, ONE_LINE, NOT_LAST, LAST_END, NOT_ZERO, ZERO
		MOVLW		H'0A'
		MOVWF		TILE_ROW
		MOVLW		TILE_MAP
		MOVWF		MAP_INDEX
		MOVLW		D'48'
		MOVWF		TEMP0
LOOP:		MOVLW		SCREEN_BUFFER0
		BTFSS		CURRENT_BUFFER, 0
		MOVLW		SCREEN_BUFFER1
		MOVWF		FSR
		MOVWF		CURRENT_BUFFER_ADDR
		MOVFW		MAP_INDEX
		MOVWF		MAP_INDEX_TEMP
		HSYNC		HSYNC_TYPE_PRE_DRAW, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_DRAW, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_PRE_DRAW, 1
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_DRAW, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_PRE_DRAW, 2
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_DRAW, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_SPRITE0, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_DRAW, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_SPRITE1, 0
		MOVFW		TILE_ROW_BACK
		MOVWF		TILE_ROW
		DECF		TEMP0, W
		BTFSS		STATUS, Z
		GOTO		NOT_LAST
		MOVLW		D'47'
		SUBWF		SPRITE0
		SUBWF		SPRITE1
		SUBWF		SPRITE2
		SUBWF		SPRITE3
		SUBWF		SPRITE4
		SUBWF		SPRITE5
		SUBWF		SPRITE6
		GOTO		LAST_END
NOT_LAST:
		INCF		SPRITE0, F
		INCF		SPRITE1, F
		INCF		SPRITE2, F
		INCF		SPRITE3, F
		INCF		SPRITE4, F
		INCF		SPRITE5, F
		INCF		SPRITE6, F
		NOP
		NOP
LAST_END:
		NOP
		NOP
		NOP
		HSYNC		HSYNC_TYPE_DRAW, 0
		DECFSZ		TEMP0, F
		GOTO		NOT_ZERO
		GOTO		ZERO
NOT_ZERO:	MOVLW		H'01'
		XORWF		CURRENT_BUFFER
		CALL		NOP4CYCLES
		GOTO		LOOP
ZERO:		MOVLW		H'01'
		XORWF		CURRENT_BUFFER
		ENDM

DRAW_DISPLAY
		HSYNC		HSYNC_TYPE_VSYNCSTART, 0
		CALL		NOP10CYCLES
		CALL		NOP8CYCLES
		HSYNC		HSYNC_TYPE_VSYNCEND, 0
		CALL		NOP10CYCLES
		CALL		NOP6CYCLES
		CALIBRATION	D'33'
		SEND_DATA
		BTFSS		DRAWED_PAST, 0
		CLRF		FILL_COLOR
		BSF		DRAWED_PAST, 0
		NOP
		CALL		NOP6CYCLES
		CALIBRATION	H'0A'
		CALL		NOP10CYCLES
		NOP
		GOTO		DRAW_DISPLAY

NOP4CYCLES	RETURN
		
NOP6CYCLES	NOP
		NOP
		RETURN
		
NOP8CYCLES	NOP
		NOP
		NOP
		NOP
		RETURN
		
NOP10CYCLES	NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		RETURN
		
BLACK		EQU	H'00'
DARKBLUE	EQU	H'01'
DARKGREEN	EQU	H'02'
DARKCYAN	EQU	H'03'
DARKRED		EQU	H'04'
DARKPURPLE	EQU	H'05'
DARKYELLOW	EQU	H'06'
DARKGRAY	EQU	H'07'
GRAY		EQU	H'08'
BLUE		EQU	H'09'
GREEN		EQU	H'0A'
CYAN		EQU	H'0B'
RED		EQU	H'0C'
PURPLE		EQU	H'0D'
YELLOW		EQU	H'0E'
WHITE		EQU	H'0F'
NULL_COLOR	EQU	H'10'
	
IMAGE_LOADER	MACRO	    TILE
		MOVLW	    high TILE
		MOVWF	    PCLATH
		MOVFW	    TILE_ROW
		ADDWF	    PCL, F
		ENDM

IMAGE		MACRO	    TRANSPARENT, C0, C1, C2, C3, C4, C5 ; 17 instructions
		IF	    C0 == TRANSPARENT && C1 == TRANSPARENT
		NOP
		NOP
		INCF	    FSR, F
		ELSE
		MOVLW	    (C0 << 4) | C1
		MOVWF	    INDF
		INCF	    FSR, F
		ENDIF
		IF	    C2 == TRANSPARENT && C3 == TRANSPARENT
		NOP
		NOP
		INCF	    FSR, F
		ELSE
		MOVLW	    (C2 << 4) | C3
		MOVWF	    INDF
		INCF	    FSR, F
		ENDIF
		IF	    C4 == TRANSPARENT && C5 == TRANSPARENT
		NOP
		NOP
		INCF	    FSR, F
		ELSE
		MOVLW	    (C4 << 4) | C5
		MOVWF	    INDF
		INCF	    FSR, F
		ENDIF
		RETURN
		ENDM

		INCLUDE	    "TILES.INC"
		
		END