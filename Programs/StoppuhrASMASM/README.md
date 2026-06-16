# STOPPUHR – Grundlage der Informatik

## Überblick

Im Rahmen des Praktikums wird eine digitale Stoppuhr auf dem ITS-Board mit ARM-Assembler implementiert.

Die Entwicklung erfolgt schrittweise über mehrere Wochen. In den ersten beiden Wochen werden die Hardwarefunktionen, die Zustandsmaschine (FSM) sowie die grundlegende Zeitberechnung umgesetzt.

---

# Woche 1 – Hardwaretest und Zustandsanzeige

## Ziel

In Woche 1 wird die Hardware des ITS-Boards getestet und angesteuert.

Folgende Komponenten werden verwendet:

* TFT-Display
* Taster S5
* Taster S6
* Taster S7
* LED D8
* LED D9

Die eigentliche Zeitmessung steht noch nicht im Vordergrund. Ziel ist die sichere Ansteuerung aller Ein- und Ausgänge.

---

## Programmablauf

Nach dem Programmstart wird zunächst die Hardware initialisiert.

Anschließend werden folgende Informationen auf dem TFT dargestellt:

```text
STOPPUHR
00:00.00
Zustand: INIT
```

Danach läuft das Programm dauerhaft in einer Endlosschleife (Superloop).

---

## Tastereinlesung

Die Taster werden über das Register

```asm
GPIO_F_PIN
```

eingelesen.

Die Taster arbeiten als Active-Low-Eingänge:

```text
0 = gedrückt
1 = nicht gedrückt
```

Zur Auswertung wird das entsprechende Bit mit AND maskiert.

Beispiel für S7:

```asm
AND R1, R1, #0x80
CMP R1, #0
```

Ist das Ergebnis 0, wurde der Taster S7 gedrückt.

---

## Zustände der FSM

Die Stoppuhr besitzt drei Zustände:

### INIT

Start- und Reset-Zustand.

Anzeige:

```text
Zustand: INIT
```

LED-Zustand:

```text
D8 = AUS
D9 = AUS
```

---

### RUNNING

Die Stoppuhr läuft.

Anzeige:

```text
Zustand: RUNNING
```

LED-Zustand:

```text
D8 = EIN
D9 = AUS
```

---

### HOLD

Die Stoppuhr ist angehalten.

Anzeige:

```text
Zustand: HOLD
```

LED-Zustand:

```text
D8 = EIN
D9 = EIN
```

---

## Tasterfunktionen

| Taster | Funktion | Neuer Zustand |
| ------ | -------- | ------------- |
| S7     | Start    | RUNNING       |
| S6     | Pause    | HOLD          |
| S5     | Reset    | INIT          |

---

## Ergebnis Woche 1

Am Ende von Woche 1 können:

* LEDs geschaltet werden
* Taster eingelesen werden
* Zustände angezeigt werden
* Zustandswechsel durchgeführt werden
* Displaytexte ausgegeben werden

---

# Woche 2 – FSM und Zeitberechnung

## Ziel

In Woche 2 wird die Zustandsmaschine erweitert und die Zeitberechnung implementiert.

Die Stoppuhr soll nun die vergangene Zeit messen und auf dem Display darstellen.

---

## Zeitmessung

Der Hardwaretimer TIM2 wird verwendet.

Die Auflösung beträgt:

```text
1 Tick = 10 µs
```

Daraus ergeben sich:

| Zeit   | Ticks     |
| ------ | --------- |
| 10 µs  | 1         |
| 1 ms   | 100       |
| 10 ms  | 1.000     |
| 100 ms | 10.000    |
| 1 s    | 100.000   |
| 10 s   | 1.000.000 |
| 1 min  | 6.000.000 |

---

## UPDATECLK

Das Unterprogramm UPDATECLK berechnet die Zeitdifferenz zwischen zwei Schleifendurchläufen.

Berechnung:

```text
DELTA_ZEIT =
Aktueller Timerwert
-
Letzter Timerwert
```

Die berechnete Differenz wird in

```asm
DELTA_ZEIT
```

gespeichert.

---

## Laufende Stoppuhrzeit

Im Zustand RUNNING wird die vergangene Zeit aufaddiert:

```text
STOPPUHR_ZEIT =
STOPPUHR_ZEIT
+
DELTA_ZEIT
```

Dadurch entsteht die gesamte gemessene Zeit seit dem Start.

---

## Umrechnung der Zeit

Die gespeicherte Zeit liegt zunächst nur als Anzahl von Timer-Ticks vor.

Diese wird schrittweise umgerechnet:

### Schritt 1

Timer-Ticks → Hundertstel

```text
GESAMT_HUNDERTSTEL =
STOPPUHR_ZEIT / 1000
```

Da

```text
1000 Ticks = 10 ms
```

entspricht ein Hundertstel einer Zeiteinheit von 10 ms.

---

### Schritt 2

Hundertstel → Sekunden

```text
SEKUNDEN =
GESAMT_HUNDERTSTEL / 100
```

Rest:

```text
HUNDERTSTEL_REST
```

---

### Schritt 3

Sekunden → Minuten

```text
MINUTEN =
SEKUNDEN / 60
```

Rest:

```text
SEKUNDEN_REST
```

---

## Anzeigeformat

Die Zeit wird auf dem TFT im Format

```text
MM:SS.HH
```

angezeigt.

Beispiele:

```text
00:00.00
00:15.34
01:22.87
09:59.99
```

---

## Unterprogramme

### INIT

Setzt die Stoppuhr zurück.

Aufgaben:

* LEDs ausschalten
* Zeit auf 0 setzen
* Zustand INIT aktivieren

---

### RUNNING

Aktive Zeitmessung.

Aufgaben:

* D8 einschalten
* Zeit hochzählen
* Anzeige aktualisieren

---

### HOLD

Pausenzustand.

Aufgaben:

* D8 und D9 einschalten
* Zeitstand halten
* Rückkehr zu RUNNING ermöglichen

---

### UPDATECLK

Berechnet die vergangene Zeit seit dem letzten Schleifendurchlauf.

---

### ZEIT_BERECHNUNG

Rechnet Timer-Ticks in

* Minuten
* Sekunden
* Hundertstel

um.

---

### DISPLAY_ZEIT

Gibt die Zeit als

```text
MM:SS.HH
```

auf dem Display aus.

---

## Ergebnis Woche 2

Am Ende von Woche 2 verfügt die Stoppuhr über:

* vollständige FSM
* Start-, Hold- und Reset-Funktion
* Zeitmessung mit Hardwaretimer
* Umrechnung der Timer-Ticks
* Anzeige im Format MM:SS.HH
* Zustandsanzeige auf dem TFT

Die Grundlage für die vollständige Stoppuhr ist damit umgesetzt.
