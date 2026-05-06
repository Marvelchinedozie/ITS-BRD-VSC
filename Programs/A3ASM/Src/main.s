;************************************************
;* Beginn der globalen Daten *
;************************************************
                   AREA MyData, DATA, align = 2
Base
VariableA          DCW 0x1234
VariableB          DCW 0x4711

VariableC          DCD  0

MeinHalbwortFeld   DCW 0x22 , 0x3e , -52, 78 , 0x27 , 0x45

MeinWortFeld       DCD 0x12345678 , 0x9dca5986
                   DCD -872415232 , 1308622848
                   DCD 0x27000000
                   DCD 0x45000000

MeinTextFeld       DCB "ABab0123",0

                   EXPORT VariableA
                   EXPORT VariableB
                   EXPORT VariableC
                   EXPORT MeinHalbwortFeld
                   EXPORT MeinWortFeld
                   EXPORT MeinTextFeld

;***********************************************
;* Beginn des Programms *
;************************************************
    AREA |.text|, CODE, READONLY, ALIGN = 3
; ----- S t a r t des Hauptprogramms -----
                EXPORT main
                EXTERN initITSboard
main            PROC
                bl    initITSboard                 ; HW Initialisieren

; Laden von Konstanten in Register
                mov   r0,#0x12                      ; lädt die Konstante 0x12 in Register R0.
                mov   r1,#-128                      ; lädt die Konstante 0x-128 in register R1.
                ldr   r2,=0x12345678                ; lädt die Konstante 0x12345678 in Register R2.

; Zugriff auf Variable
                ldr   r0,=VariableA                 ; lädt die Adresse von VariableA in Register R0.
                ldrh  r1,[r0]                       ; lädt ein 16 Bit Halbwort aus dem Speicher an der Adresse in R0 in R1.                
				ldr   r2,[r0]                       ; R2 bekommt der Wert aus dem Speicher an der Adresse R0.
                str   r2,[r0,#VariableC-VariableA]  ; Speichert den Inhalt von R2 an der Adresse r0 + offset.

; Zugriff auf Felder (Speicherzellen)
                ldr   r0,=MeinHalbwortFeld          ; lädt die Startadresse des Feldes in R0. 0x1008
                ldrh  r1,[r0]                       ; lädt das erste Element (Index 0) aus dem Feld in R1
                ldrh  r2,[r0,#2]                    ; lädt das zweite Element (index 1), weil +2 Byte = 1 Element weiter
                mov   r3,#10                        ; Speichert den Wert 10 in R3 (offset)
                ldrh  r4,[r0,r3]                    ; lädt das Element bei offset 10 Byte in Index 5(10/2)

                ldrh  r5,[r0,#2]!                   ; lädt wieder das 2. Element (index 1), R0 bleibt unverändert
                ldrh  r6,[r0,#2]!                   ; lädt wieder das gleiche Element (Index 1), R0 bleibt unverändert
                strh  r6,[r0,#2]!                   ; speichert den wert aus R6 zurück an position Index 1 im Feld

; Addition und Subtraktion von unsigned / signed Integer-Werten
                ldr  r0,=MeinWortFeld               ; lädt die Startadresse des 32-Bit-Feldes in R0
                ldr  r1,[r0]                        ; lädt das 1. Element (Index 0) aus dem Feld in R1
                ldr  r2,[r0,#4]                     ; lädt das 2. Element (Index 1), da jedes Element 4 Byte groß ist
                adds r3,r1,r2                       ; addiert R1 + R2 und speichert das Ergebnis in R3. setzt zusätzlich die Status-Flags (N, Z, C, V)

                ldr  r4,[r0,#8]                     ; lädt das 3. Element (Index 2)
                ldr  r5,[r0,#12]                    ; lädt das 4. Element (Index 3)
                subs r6,r4,r5                       ; berechnet R4 - R5 und speichert das Ergebnis in R6, setzt ebenfalls die Status-Flags

                ldr  r7,[r0,#16]                    ; lädt das 5. Element (Index 4)
                ldr  r8,[r0,#20]                    ; lädt das 6. Element (Index 5)
                subs r9,r7,r8                       ; berechnet R7 - R8 und speichert das Ergebnis in R9, setzt wieder die Status-Flags

forever         b   forever                         ; Endlosschleife → Programm bleibt hier stehen
                ENDP
                END