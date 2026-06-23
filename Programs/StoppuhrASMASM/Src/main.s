;******************** (C) COPYRIGHT HAW-Hamburg ********************************
;* File Name          : main.s
;* Author             : Franz Korf	
;* Version            : V1.0
;* Date               : 11.05.2022
;* Description        : Rahmen zur Loesung von GTP Woche 7-9 (Stoppuhr).
;
;*******************************************************************************

; Define address of selected GPIO and Timer registers
PERIPH_BASE     	equ	0x40000000                 ;Peripheral base address
AHB1PERIPH_BASE 	equ	(PERIPH_BASE + 0x00020000)
APB1PERIPH_BASE         equ     PERIPH_BASE

GPIOD_BASE		equ	(AHB1PERIPH_BASE + 0x0C00)
GPIOF_BASE		equ	(AHB1PERIPH_BASE + 0x1400)
TIM2_BASE               equ     (APB1PERIPH_BASE + 0x0000)
	
GPIO_F_PIN        	equ	(GPIOF_BASE + 0x10)

GPIO_D_PIN		equ	(GPIOD_BASE + 0x10)
GPIO_D_SET		equ     (GPIOD_BASE + 0x18)
GPIO_D_CLR	        equ	(GPIOD_BASE + 0x1A)
	
TIMER			equ     (TIM2_BASE + 0x24)   ; CNT : current time stamp (32 bit),  resolution
TIM2_PSC		equ     (TIM2_BASE + 0x28)   ; Prescaler  resolution
TIM2_ERG		equ     (TIM2_BASE + 0x14)   ; 16 Bit register, Bit 0 : 1 Restart Timer


        EXTERN initITSboard
        EXTERN GUI_init
        EXTERN TP_Init
        EXTERN initTimer
        EXTERN lcdSetFont
        EXTERN lcdGotoXY      		; TFT goto x y function
        EXTERN lcdPrintS		; TFT output function	
        EXTERN lcdPrintC                ; TFT output one character		
        EXTERN Delay			; Delay (ms) function


;********************************************
; Data section, aligned on 4-byte boundary
;********************************************
        AREA MyData, DATA, align = 2

DEFAULT_BRIGHTNESS     	DCW     800
MY_TEXT 		DCB 	"STOPPUHR", 0
ZEIT_NULL 		DCB	"00:00.00", 0

;=============================  ZUSTAND ANZEIGE =================================
STATE_INIT_TEXT         DCB     "Zustand: INIT    ", 0
STATE_RUNNING_TEXT      DCB     "Zustand: RUNNING ", 0
STATE_HOLD_TEXT         DCB     "Zustand: HOLD    ", 0

;============================= ZEIT VARIABLE =========================================
GESAMT_HUNDERTSTEL      DCD     0
SEKUNDEN                DCD     0
HUNDERTSTEL_REST        DCD     0
MINUTEN                 DCD     0
SEKUNDEN_REST           DCD     0


;================== letzter Zeitstempel =================================================
LETZTER_TIMER           DCD     0

; =================== Zeit seit letztem Schleifendurchlau ================================
DELTA_ZEIT              DCD     0

;===================== gesamte Stoppuhrzeit ==============================================
STOPPUHR_ZEIT            DCD     0

; ============== Zustandswert ============================================================
ZUSTAND_INIT             EQU     0 		;Zustand Konstante fuer INIT
ZUSTAND_RUNNING          EQU     1		;Zustand Konstante fuer RUNNING
ZUSTAND_HOLD             EQU     2		;Zustand Konstante fuer HOLD

; ============== Variable fuer aktuellen Zustand ============================
ZUSTAND                 DCB     ZUSTAND_INIT

        

; ============== Variable fuer aktuell eingelesene Taster =====================================
TASTER                 DCW     0

		ALIGN

;********************************************
; Code section, aligned on 8-byte boundery
;********************************************
	AREA |.text|, CODE, READONLY, ALIGN = 3


;--------------------------------------------
; main subroutine
;--------------------------------------------
	EXPORT main [CODE]
	
main	PROC

	; Initialisierung der HW
	BL	initITSboard
	ldr   	r1, =DEFAULT_BRIGHTNESS
	ldrh 	r0, [r1]
	bl   	GUI_init
	bl  	initTimer
	ldr 	R1,=TIM2_PSC   		; Set pre scaler such that 1 timer tick represents 10 us
	mov 	R0,#(90*10-1) 
	strh	R0,[R1]
	ldr 	R1,=TIM2_ERG   		; Restart timer	
	mov	R0,#0x01
	strh	R0,[R1]		        ; Set UG Bit
	MOV 	R0, #24
	bl  	lcdSetFont

		

;================================= Initialisierung LETZTER_TIMER ==============================
        LDR 	R0, =TIMER          ; Adresse von TIMER laden
	LDR 	R1, [R0]            ; aktuellen Timerwert lesen

	LDR 	R0, =LETZTER_TIMER  ; Adresse von LETZTER_TIMER laden
	STR 	R1, [R0]            ; aktuellen Timerwert dort speichern

		



;****************************************************************************************
; Ihre Initialisierung ============================== Hier fangt es an
;****************************************************************************************
	LDR     R1, =ZUSTAND			; Zustand Adresse wird in R1 geladen
	MOV     R0, #ZUSTAND_INIT		; Kopiere den Wert der Konstante in R0
	STRB    R0, [R1]			; Speichere den wert von R0 in R1
	BL 	MY_TEXT_AUSGEBEN
	BL 	DISPLAY_NULL




superloop

	 BL      UPDATECLK           ; vergangene Zeit seit letztem Schleifendurchlauf berechnen

    ;=============================== Taster einlesen ==========================
        LDR     R0, =GPIO_F_PIN
        LDRH    R0, [R0]

        LDR     R1, =TASTER
        STRH    R0, [R1]

    ;=============================== Zustand pruefen ==========================
        LDR     R1, =ZUSTAND
        LDRB    R0, [R1]
		

        CMP     R0, #ZUSTAND_INIT
        BLEQ     INIT

        CMP     R0, #ZUSTAND_RUNNING
        BLEQ     RUNNING

        CMP     R0, #ZUSTAND_HOLD
        BLEQ     HOLD

        B       superloop






;================= INIT PROGRAM =========================================
;------------------------------------------------------------------------
; INIT_PROGRAM
; Zustand INIT
;------------------------------------------------------------------------
INIT PROC
	push{LR}

	;========== Alle LEDS ausschalten ==================================
	LDR 	R0,=GPIO_D_CLR
	MOV 	R1, #3
	STRH 	R1, [R0]

	;================== INIT AUF NULL SETZEN =======================	
	LDR     R0, =STOPPUHR_ZEIT
	MOV     R1, #0
	STR     R1, [R0]

	

	;================Tasterwert laden ================================
	;TASTER wurde vorher in der superloop gespeichert
	LDR 	R0,=TASTER
	LDRH    R1, [R0]


    ;========== Pruefen, ob S7 gedrueckt ist ==========================

        ; S7 liegt auf Bit 7 = 0x80
        ; Taster sind active-low:
        ; 0 = gedrueckt
        ; 1 = nicht gedrueckt
IF_INIT
        AND     R1, R1, #0x80
        CMP     R1, #0

        ; Wenn S7 nicht gedrueckt ist, INIT verlassen
        BNE     END_IF_INIT
THEN_INIT
		;========== Wenn S7 gedrueckt wurde ==============================
        ; Zustand auf RUNNING setzen
        LDR     R0, =ZUSTAND
        MOV     R1, #ZUSTAND_RUNNING
        STRB    R1, [R0]
		BL      ZUSTAND_AUSGABEN
END_IF_INIT

	POP{PC}
	ENDP

;============================== RUNNING PROGRAM ==============================
;-----------------------------------------------------------------------------
; RUNNING
; Zustand RUNNING
;------------------------------------------------------------------------------
RUNNING PROC

        PUSH    {LR}

;==================================== D8 an ================================
        LDR     R0, =GPIO_D_SET
        MOV     R1, #1
        STRH    R1, [R0]

;=================================== D9 aus =================================
        LDR     R0, =GPIO_D_CLR
        MOV     R1, #2
        STRH    R1, [R0]

;==================================== Tasterwert laden ========================
        LDR     R0, =TASTER
        LDRH    R1, [R0]

;==================================== S6 pruefen: Wechsel zu HOLD ==============
IF_HOLD_01
        AND     R2, R1, #0x40
        CMP     R2, #0
		BNE 	END_IF_HOLD_01

THEN_HOLD_01

        LDR     R0, =ZUSTAND
        MOV     R1, #ZUSTAND_HOLD
        STRB    R1, [R0]
		BL      ZUSTAND_AUSGABEN
        B       running_ende
END_IF_HOLD_01

;=====================================  S5 pruefen: Reset zu INIT ================
IF_INIT_01
        AND     R2, R1, #0x20
        CMP     R2, #0
	BNE		END_IF_INIT_01

THEN_INIT_01
        LDR     R0, =ZUSTAND
        MOV     R1, #ZUSTAND_INIT
        STRB    R1, [R0]

	BL 		DISPLAY_NULL
	BL      ZUSTAND_AUSGABEN
	B		running_ende

END_IF_INIT_01
        

;===================================== Zeit hochzaehlen =========================
        LDR     R0, =STOPPUHR_ZEIT
        LDR     R1, [R0]

        LDR     R2, =DELTA_ZEIT
        LDR     R2, [R2]

        ADD     R1, R1, R2
        STR     R1, [R0]

	BL      ZEIT_BERECHNUNG
	BL 	DISPLAY_ZEIT


        B       running_ende




running_ende
	POP     {PC}
	ENDP



;============================== HOLD PROGRAM ==============================
;--------------------------------------------------------------------------
; HOLD
; Zustand HOLD
;--------------------------------------------------------------------------
HOLD    PROC

        PUSH    {LR}

;==================================== D8 an ===================================
        LDR     R0, =GPIO_D_SET
        MOV     R1, #1
        STRH    R1, [R0]

;==================================== D9 an ====================================
        LDR     R0, =GPIO_D_SET
        MOV     R1, #2
        STRH    R1, [R0]

;==================================== Tasterwert laden =========================
        LDR     R0, =TASTER
        LDRH    R1, [R0]

;===================================== S7 pruefen: zurueck zu RUNNING ================
IF_RUNNING_02
        AND     R2, R1, #0x80
        CMP     R2, #0
	BNE	END_IF_RUNNING_02

THEN_RUNNING_02
	LDR     R0, =ZUSTAND
        MOV     R1, #ZUSTAND_RUNNING
        STRB    R1, [R0]
	BL      ZUSTAND_AUSGABEN
        B       hold_ende

END_IF_RUNNING_02

;==================================== S5 pruefen: RESET zu INIT ========================
IF_INIT_02
        AND     R2, R1, #0x20
        CMP     R2, #0
	BNE 	END_IF_INIT_02

THEN_INIT_02
	LDR     R0, =ZUSTAND
        MOV     R1, #ZUSTAND_INIT
        STRB    R1, [R0]

	BL 	DISPLAY_NULL
	BL      ZUSTAND_AUSGABEN
END_IF_INIT_02
;==================== Zeit im Hintergrund weiterzaehlen ================================   
        LDR     R0, =STOPPUHR_ZEIT
        LDR     R1, [R0]

        LDR     R2, =DELTA_ZEIT
        LDR     R2, [R2] 	;Lese die vergangene Zeit seit dem letzten Schleifendurchlauf.

        ADD     R1, R1, R2
        STR     R1, [R0]

        B       hold_ende


hold_ende
        POP     {PC}
	ENDP


MY_TEXT_AUSGEBEN PROC
        PUSH    {LR}

;============== Cursor auf Position x=0, y=0 =====================
        MOV     R0, #0
        MOV     R1, #0
        BL      lcdGotoXY

;================ STOPPUHR TEXT ausgeben ==============================
        LDR     R0, =MY_TEXT
        BL      lcdPrintS

        POP     {PC}

        ENDP

;================= ZUSTAND AUSGEBEN UNTERPROGRAM X = R0, Y = R1 =============================
ZUSTAND_AUSGABEN PROC

        PUSH    {LR}

        MOV     R0, #6
	MOV     R1, #5
        BL      lcdGotoXY

        LDR     R1, =ZUSTAND
        LDRB    R1, [R1]
IF_03
        CMP     R1, #ZUSTAND_INIT
        BNE	ELSE_031
	BEQ 	THEN_031
THEN_031   
	LDR     R0, =STATE_INIT_TEXT
        BL      lcdPrintS

ELSE_031
        CMP     R1, #ZUSTAND_RUNNING
        BNE	ELSE_032
	BEQ 	THEN_032

THEN_032
	LDR     R0, =STATE_RUNNING_TEXT
        BL      lcdPrintS
        

ELSE_032
        CMP     R1, #ZUSTAND_HOLD
        BNE	ENDIF_03
	BEQ 	THEN_033

THEN_033
	LDR     R0, =STATE_HOLD_TEXT
        BL      lcdPrintS

ENDIF_03
        B       zustand_ende
        

zustand_ende
        POP     {PC}

        ENDP



;================= DISPLAY UNTERPROGRAM =============================
DISPLAY_NULL PROC
;=====================================================================

	PUSH	{LR}

;============== Cursor auf Position X = R0, Y = R1 =====================
	MOV 	R0, #8
	MOV 	R1, #6
	BL 	lcdGotoXY



;=============== text "00:00,0" ausgeben ========================
	LDR     R0, =ZEIT_NULL
        BL      lcdPrintS

	POP     {PC}

	ENDP
;============================== UPDATECLOCK PROGRAM ==============================
;----------------------------------------------------------------------------------
; UPDATECLK
;----------------------------------------------------------------------------------
UPDATECLK PROC

    	PUSH 	{LR}

;=============================== aktuellen TIMER lesen==================================
    	LDR 	R0, =TIMER
    	LDR 	R1, [R0]

;================================ alten TIMER laden ====================================
    	LDR 	R0, =LETZTER_TIMER
    	LDR 	R2, [R0]

;================================ Delta berechnen ======================================
    	SUB 	R3, R1, R2

;================================ Delta speichern =======================================
    	LDR 	R0, =DELTA_ZEIT
    	STR 	R3, [R0]

;================================= aktuellen Timer merken ===============================
    	LDR 	R0, =LETZTER_TIMER
    	STR 	R1, [R0]

        POP     {PC}

        ENDP
;============================ DISPLAY_ZEIT PROGRAM X = R0, Y = R1================================
DISPLAY_ZEIT PROC
        PUSH    {LR}

        MOV     R0, #8
        MOV     R1, #6
        BL      lcdGotoXY

        ; Minuten anzeigen
        LDR     R0, =MINUTEN
        LDR     R1, [R0]
        BL      PRINT2

        ; Doppelpunkt
        MOV     R0, #':'
        BL      lcdPrintC

        ; Sekunden-Rest anzeigen
        LDR     R0, =SEKUNDEN_REST
        LDR     R1, [R0]
        BL      PRINT2

        ; Punkt
        MOV     R0, #'.'
        BL      lcdPrintC

        ; Hundertstel anzeigen
        LDR     R0, =HUNDERTSTEL_REST
        LDR     R1, [R0]
        BL      PRINT2

        POP     {PC}
        ENDP

;============================================================================================
PRINT2 PROC
;============================================================================================
        PUSH    {LR}            ; Rücksprungadresse sichern

        MOV     R2, #0          ; Zehnerstelle auf 0 setzen

p2_loop
        CMP     R1, #10         ; Prüfen ob Zahl >= 10
        BLT     p2_ende         ; Falls kleiner 10, Schleife beenden

        SUB     R1, R1, #10     ; 10 abziehen
        ADD     R2, R2, #1      ; Zehnerstelle erhöhen
        B       p2_loop         ; Wiederholen

p2_ende
        PUSH    {R1}            ; Einerstelle zwischenspeichern

        MOV     R0, R2          ; Zehnerstelle nach R0
        ADD     R0, R0, #'0'    ; Zahl in ASCII-Zeichen umwandeln
        BL      lcdPrintC       ; Zehnerstelle ausgeben

        POP     {R1}            ; Einerstelle zurückholen

        MOV     R0, R1          ; Einerstelle nach R0
        ADD     R0, R0, #'0'    ; Zahl in ASCII-Zeichen umwandeln
        BL      lcdPrintC       ; Einerstelle ausgeben

        POP     {PC}            ; Rückkehr aus Unterprogramm
        ENDP

;============================ ZEIT_BERECHNUNG PROGRAM ==================================
ZEIT_BERECHNUNG PROC
        PUSH    {LR}                ; Rücksprungadresse sichern

        LDR     R0, =STOPPUHR_ZEIT  ; Adresse von STOPPUHR_ZEIT laden
        LDR     R1, [R0]            ; Wert von STOPPUHR_ZEIT in R1 laden

        MOV     R3, #0              ; R3 zählt die Gesamt-Hundertstel

division_loop
        CMP     R1,#1000           ; Prüfen: Ist STOPPUHR_ZEIT kleiner als 1000?
        BLT     division_ende       ; Wenn kleiner, Schleife beenden

        SUB     R1, R1,#1000       ; 1000 Timer-Ticks abziehen
        ADD     R3, R3, #1          ; 1 Hundertstel dazuzählen

        B       division_loop       ; Schleife wiederholen

division_ende
        LDR     R0, =GESAMT_HUNDERTSTEL
        STR     R3, [R0]            ; Gesamt-Hundertstel speichern

        MOV     R1, R3              ; Gesamt-Hundertstel nach R1 kopieren
        MOV     R4, #0              ; R4 zählt die Sekunden

sekunden_loop
        CMP     R1,#100            ; Prüfen: Sind mindestens 100 Hundertstel vorhanden?
        BLT     sekunden_ende       ; Wenn weniger als 100, Schleife beenden

        SUB     R1, R1,#100        ; 100 Hundertstel abziehen
        ADD     R4, R4, #1          ; 1 Sekunde dazuzählen

        B       sekunden_loop       ; Schleife wiederholen

sekunden_ende
        MOV     R6, R1              ; Rest-Hundertstel sichern

        LDR     R0, =SEKUNDEN
        STR     R4, [R0]            ; Gesamt-Sekunden speichern

        LDR     R0, =HUNDERTSTEL_REST
        STR     R6, [R0]            ; Hundertstel-Rest speichern

        MOV     R1, R4              ; Gesamt-Sekunden nach R1 kopieren
        MOV     R5, #0              ; R5 zählt die Minuten

minuten_loop
        CMP     R1, #60             ; Prüfen: Sind mindestens 60 Sekunden vorhanden?
        BLT     minuten_ende        ; Wenn weniger als 60, Schleife beenden

        SUB     R1, R1, #60         ; 60 Sekunden abziehen
        ADD     R5, R5, #1          ; 1 Minute dazuzählen

        B       minuten_loop        ; Schleife wiederholen

minuten_ende
        LDR     R0, =MINUTEN
        STR     R5, [R0]            ; Minuten speichern

        LDR     R0, =SEKUNDEN_REST
        STR     R1, [R0]            ; Sekunden-Rest speichern

        POP     {PC}                ; Zurück zum Hauptprogramm

        ENDP 	;Zeit Berechnung

        ALIGN
        END
