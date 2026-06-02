;******************** (C) COPYRIGHT HAW-Hamburg ********************************
;* File Name          : main.s
;* Author             : Silke Behn	
;* Version            : V1.0
;* Date               : 01.06.2021
;* Description        : This is a simple main.
;					  :
;					  : Replace this main with yours.
;
;*******************************************************************************
    EXTERN initITSboard
    EXTERN lcdPrintS            ;Display ausgabe
    EXTERN GUI_init
;	EXTERN TP_Init

;********************************************
; Data section, aligned on 4-byte boundery
;********************************************
	
	AREA MyData, DATA, align = 2

    GLOBAL text
DEFAULT_BRIGHTNESS DCW 800

text    DCB "Hallo liebes TI-Labor (asm-project)",0

primzahl                
        FILL 1001, 1
;hier hab ich ich mein PrimzahlFeld mit 1001 platz erstellt und 
;in jede Zelle mit 1 als Wahr(primzahl) gepackt.


arrlists
        SPACE 2002
;Reserviere für jedes Element 2 Byte, 
;weil ein Byte(255 Zustände) reicht hier nicht.

	AREA |.text|, CODE, READONLY, ALIGN = 3

;--------------------------------------------
; main subroutine
;--------------------------------------------
				EXPORT main [CODE]
				EXTERN initITSboard
main            PROC
                bl    initITSboard                 ; HW Initialisieren

; Sieb des Eratosthenes

; Speicher für Zahlen von 0 bis 1000 reservieren
; boolean[] primzahl = new boolean[1001]
; int[] arrlists = new int[1001];

; Alle Zahlen ab 2 zunächst als Primzahl markieren
; for (int i = 2; i <= 1000; i++)
;     primzahl[i] = true;

; Beginne mit Zahl 2
; Prüfe ob Zahl noch als Primzahl markiert ist
; for (int i = 2; i * i <= 1000; i++)
;     if (primzahl[i])

; Alle Vielfachen der Zahl als nicht prim markieren
; for (int b = i * i; b <= 1000; b += i)
;     primzahl[b] = false;

; Am Ende alle Primzahlen ausgeben
; for (int i = 2; i <= 1000; i++)
;     if (primzahl[i]) {
;		arrlists[x+1] = i
;	}
; 
;==========================================================
;               LOESUNGEN ZUR AUFGABE 5
; ==========================================================
; Sieb des Eratosthenes in Kontrollstruktur-/Assembler-Form
; ==========================================================
;
; Bedeutung der Register:
;
; R0 = Basisadresse vom Array primzahl
;      Also: Anfangsadresse von primzahl[]
;
; R1 = i
;      Laufvariable für die äußeren Schleifen
;
; R2 = i * i
;      Hilfsregister für das Quadrat von i
;
; R3 = Wert für true/false
;      1 = true
;      0 = false
;
; R4 = j
;      Laufvariable für die Vielfachen von i
;
; ----------------------------------------------------------



; ==========================================================
; 
; Addresse geladet und erste und zweite bYTE auf NULL ersetzt, weill 
; sie keine Primzahl sind.
; ==========================================================
        LDR R0, =primzahl
        ; R0 = Basisadresse von primzahl[]

        MOV R3, #0
        ; R3 = 0, also false / keine Primzahl

        STRB R3, [R0, #0]
        ; primzahl[0] = false

        STRB R3, [R0, #1]
        ; primzahl[1] = false



; ==========================================================
; iCH hab 3 For Loop verwendet.
; FOR1:
; Äußere Sieb-Schleife
; Prüft alle möglichen Primzahlen i
; ==========================================================

FOR1
    MOV R1, #2
    ; i = 2
    ; Wir beginnen wieder bei der kleinsten Primzahl.


UNTIL1
    MUL R2, R1, R1
    ; R2 = i * i
    ; Wir brauchen i*i, weil die Schleife nur laufen muss,
    ; solange i*i <= 1000 gilt.

    CMP R2,#1000
    ; Vergleiche i*i mit 1000.

    BGT ENDDO1
    ; Wenn i*i > 1000 ist, kann die Schleife enden.
    ; Dann wurden alle nötigen Vielfachen gestrichen.


DO1
    LDRB R3, [R0, R1]
    ; Lade den Wert von primzahl[i] in R3.
    ; R3 = primzahl[i];

IF1
    CMP R3, #1
    ; Prüfe, ob primzahl[i] == true ist.

    BNE ENDIF1
    ; Wenn primzahl[i] NICHT true ist, springe zum Ende des if.
    ;
    ; BNE = Branch Not Equal
    ;
    ; wIE HIER IN java.
    ; if (primzahl[i] == true)
    ; {
    ;     ...
    ; }


THEN1
    
    ; j = i * i
    ;
    ; Warum nicht j = 2 * i?
    ; Weil kleinere Vielfache schon vorher gestrichen wurden.
    ;
    ; Beispiel:
    ; Bei i = 5:
    ; 10, 15, 20 wurden schon bei 2 oder 3 gestrichen.
    ; Deshalb startet man bei 25.


; ==========================================================
; FOR2:
; Innere Schleife
; Streicht alle Vielfachen von i
; ==========================================================

FOR2
    MOV R4, R2
    ; Start der inneren Schleife.
    ; j wurde vorher schon auf i*i gesetzt.


UNTIL2
    CMP R4,#1000
    ; Vergleiche j mit 1000.

    BGT ENDDO2
    ; Wenn j > 1000 ist, ist die innere Schleife fertig.


DO2
    MOV R3, #0
    ; R3 = 0
    ; 0 bedeutet false.

    STRB R3, [R0, R4]
    ; Speichere false in primzahl[j].
    ;
    ; Wie in java
    ; primzahl[j] = false;
    ;
    ; Damit wird j als "keine Primzahl" markiert.


STEP2
    ADD R4, R4, R1
    ; j = j + i
    ;
    ; Dadurch gehen wir zum nächsten Vielfachen von i.
    ;
    ; Beispiel bei i = 3:
    ; j = 9
    ; dann 12
    ; dann 15
    ; dann 18
    ; usw.

    B UNTIL2
    ; Springe zurück zur Bedingung der inneren Schleife.


ENDDO2
    ; Ende der inneren Schleife.
    ; Alle Vielfachen von i wurden auf false gesetzt.


ENDIF1
    ; Ende der if Unterscheidung.
    ; Hier landet man auch, wenn primzahl[i] nicht true war.


STEP1
    ADD R1, R1, #1
    ; i = i + 1
    ; Gehe zur nächsten Zahl.

    B UNTIL1
    ; Springe zurück zur Bedingung der äußeren Sieb-Schleife.


ENDDO1
        ; Das Sieb ist fertig.
        ; Alle Stellen mit true sind Primzahlen.

        LDR R5, =arrlists
        ; R5 = Basisadresse vom neuen Array arrlists

        MOV R1, #2
        ; i = 2
        ; Wir starten bei 2, weil 0 und 1 keine Primzahlen sind.

        MOV R6, #0
        ; x = 0
        ; x ist die Position im neuen Array arrlists.


; ==========================================================
; FOR3:
; Alle Primzahlen aus primzahl[] suchen und in arrlists[] speichern
; ==========================================================

        CMP R1,#1000
        ; Vergleiche i mit 1000.

        BGT ENDDO3
        ; Wenn i > 1000 ist, ist die Schleife fertig.


DO3
        LDRB R3, [R0, R1]
        ; Lade primzahl[i] in R3.
        ; Wenn R3 = 1, dann ist i eine Primzahl.
        ; Wenn R3 = 0, dann ist i keine Primzahl.

IF2
        CMP R3, #1
        ; Prüfe: primzahl[i] == true?

        BNE STEP3
        ; Wenn primzahl[i] nicht 1 ist, dann überspringe das Speichern.


THEN2
        STRH R1, [R5, R6, LSL #1]
        ; Speichere i in arrlists[x].
        ;
        ; R5 = Basisadresse von arrlists
        ; R6 = x
        ; LSL #1 bedeutet: x * 2
        ;
        ; Warum x * 2?
        ; Weil STRH 2 Bytes speichert.
        ;
        ; Java-Entsprechung:
        ; arrlists[x] = i;

        ADD R6, R6, #1
        ; x = x + 1
        ; Nächste freie Position im Array.

ENDIF2 
STEP3
        ADD R1, R1, #1
        ; i = i + 1

        B FOR3
        ; Zurück zum Anfang der Schleife.


ENDDO3
        B ENDDO3
        ; Programm hier halten.
        ENDP
        END