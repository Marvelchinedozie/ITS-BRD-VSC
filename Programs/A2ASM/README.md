Speicher (Memory) ab der Addresse "VariableA":
VariableA: 
    speichert ein Wort im Speicher: 2 Byte(16Bit) mit dem Wert 0xbeef.
    0xbeef wird in little Endian gespeichert (Least Significant Wert kommt zuerst).
    zum Beispiel:
    0x00    ef
    0x01    be

VariableB:
    speichert ein Wort im Speicher: 2 Byte(16 Bits) mit dem Wert 0x1234 in little Endian wie "VaiableA".

Register:
ldr R0, =VariableA:
     R0 wird mit 4 Byte aus dem Speicher geladen und die Adresse von " VariableA" wird drin gespeichert.
ldrb R2,[R0]:
    R2 wird mit 1 Byte aus dem Speicher an der Adresse R0 geladen. mit dem Wert "ef".
ldrb R3,[Ro,#1];
    R3 wird mit 1 Byte aus dem speicher der Adresse R0 + 1 geladen. mit dem Wert "be".
lsl R2,#8:
    die Werte in R2 wird um 8 bits nach links geschoben. 0xef00
orr R2, R3:
    R2 = R2 or R3, R2 veraendert sich und R3 bleibt unveraendert.
strh R2,[R0]:
    Der Wert von R2 wird in den Speicher an der Adresse gespeichert, die in R0 steht