## # Sieb des Eratosthenes

## Analyse der Aufgabenstellung
Das Programm soll alle Primzahlen von 2 bis 1000 finden.
Dafür wird das Sieb des Eratosthenes verwendet.

## Aufbau des Programms
1. Ein boolean-Array wird erstellt.
2. Alle Zahlen ab 2 werden zuerst als true markiert.
3. Mit einer Schleife werden Vielfache gestrichen.
4. Am Ende werden alle Primzahlen ausgegeben.

## Verwendete Felder
boolean[] primzahl

Der Datentyp ist boolean.
true = Primzahl
false = keine Primzahl


## VorgehenWeise.
Ich verwende ein Byte-Array primzahl mit 1001 Elementen.
Der Index entspricht direkt der Zahl.
primzahl[i] = 1 bedeutet: i ist Primzahl.
primzahl[i] = 0 bedeutet: i ist keine Primzahl.

FOR1 initialisiert alle Werte von 2 bis 1000 mit true.

FOR2 prüft alle Zahlen i ab 2, solange i*i <= 1000 gilt.

IF1 prüft, ob primzahl[i] noch true ist.

FOR3 setzt alle Vielfachen von i ab i*i auf false.
Der Schritt ist j = j + i.

## Bedingungen
FOR1 setzt primzahl[2] bis primzahl[1000] auf true.
FOR2 läuft über alle möglichen Teiler i.
IF1 prüft, ob primzahl[i] true ist.
FOR3 streicht alle Vielfachen von i, beginnend bei i*i.

## Register 
R0 = Basisadresse des Arrays primzahl
R1 = Laufvariable i
R2 = i*i
R3 = true/false Wert
R4 = Laufvariable j

## Abspeichern

R1 läuft von 2 bis 1000.
R3 liest, ob diese Zahl prim ist.
R6 zählt nur die gefundenen Primzahlen.
R5 zeigt auf das neue Feld arrlists.
#############################
## Ablauf
i = 2
x = 0

Prüfe primzahl[2]
wenn 1: speichere 2 in arrlists[0]
x = 1

Prüfe primzahl[3]
wenn 1: speichere 3 in arrlists[1]
x = 2

Prüfe primzahl[4]
wenn 0: nichts speichern

Prüfe primzahl[5]
wenn 1: speichere 5 in arrlists[2]
x = 3

