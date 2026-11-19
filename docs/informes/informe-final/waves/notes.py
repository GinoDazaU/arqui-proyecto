"""Highlighted cycles and notes of each waveform of the final report (written after reading the
traces with `waves.py table`). NOTES[name] = (highlights, notes);
highlight = (first cycle, last cycle, colour, label), with the cycle numbers of the trace."""
from waves import BLUE, GREEN, ORANGE, RED, PURPLE, BROWN

NOTES = {
    # ---------------- optimization ----------------
    "opt-slot0": (
        [(7, 7, RED, "fallo BTB"), (10, 10, BROWN, "PredF_0"), (12, 12, GREEN, "verifica"), (13, 13, BROWN, "PredF_0"),
         (15, 15, GREEN, "Ctr 11")],
        [(RED, "Ciclo 7: primera ejecución del beq (PC 32): no está en el BTB (BtbHitE=0), se predijo no tomado y se toma → "
               "MispredictE=1, PCCorrectE=16; se crea la entrada con Ctr=10."),
         (BROWN, "Ciclo 10: Fetch busca el par (32, 36); el BTB acierta (PredF_0=1): PCNextF=TargetF_0=16 y AnnulF_1=1 anula "
                 "addi x5 (InstrD_1 = bubble en el ciclo 11)."),
         (GREEN, "Ciclo 12: el beq llega a EX con PredTakenE=1, PCSrcE=1 → MispredictE=0: no hay flush; el contador sube de 10 a 11."),
         (GREEN, "Desde el ciclo 10 cada iteración dura 3 ciclos (10, 13, 16, ...), frente a 5 en el Dual-Issue sin predicción.")]),
    "opt-slot0-exit": (
        [(34, 34, BROWN, "pred. tomado"), (36, 36, RED, "MispredictE"), (38, 41, GREEN, "camino correcto")],
        [(BROWN, "Ciclo 34: última búsqueda del par (32, 36): el contador está en 11 y el beq se predice tomado otra vez."),
         (RED, "Ciclo 36: x1 = 10, el beq no se toma: PCSrcE=0 ≠ PredTakenE=1 → MispredictE=1, PCCorrectE = PC+4 = 36; "
               "FlushD y FlushE descartan la iteración predicha y el contador baja a 10."),
         (GREEN, "Ciclos 38–41: addi x5,x0,7 (la instrucción anulada en cada iteración) entra a EX en el ciclo 39 con sw x10; los sw escriben 30 y 7."),
         (RED, "El error de la salida cuesta los mismos 2 ciclos que un salto tomado en B; se paga una vez por bucle.")]),
    "opt-slot0-B": (
        [(7, 7, RED, "tomado"), (12, 12, RED, "tomado"), (17, 17, RED, "tomado")],
        [(RED, "Ciclos 7, 12, 17: sin predicción, cada beq tomado activa PCSrcE en EX: FlushD, FlushE y FlushM_1 descartan "
               "el addi x5 del par y los dos pares buscados detrás."),
         (RED, "Ciclos 8–9, 13–14, 18–19: dos ciclos sin instrucciones en EX por iteración; cada iteración dura 5 ciclos.")]),
    "opt-slot1": (
        [(6, 6, RED, "fallo BTB"), (8, 8, BROWN, "PredF_1"), (10, 10, GREEN, "verifica"), (12, 18, GREEN, "2 instr/ciclo")],
        [(RED, "Ciclo 6: el beq del slot 1 (PC 28) se toma sin estar en el BTB: MispredictE=1; FlushLane1E=0 porque está en "
               "la vía 1 y el addi x10 de la vía 0, más antiguo, continúa."),
         (BROWN, "Ciclo 8: el par (24, 28) se busca con PredF_1=1: PCNextF=TargetF_1=16. No se anula nada (AnnulF_1=0): "
                 "el slot 0 es más antiguo que el salto."),
         (GREEN, "Ciclos 10–18: el beq se confirma en cada iteración (MispredictE=0); el bucle de 4 instrucciones dura 2 ciclos: "
                 "IPC = 2 en régimen."),
         (RED, "La salida (ciclo 28, fuera de la ventana) es el único otro error: 2 errores en 11 ejecuciones del beq.")]),
    "opt-regroup": (
        [(9, 9, BROWN, "PredF_1"), (10, 10, ORANGE, "regroup"), (12, 12, GREEN, "PredF_0 + regroup"), (13, 13, ORANGE, "regroup")],
        [(BROWN, "Ciclo 9: el par (24, 28) se busca y el beq del slot 1 se predice tomado (PredF_1=1): Fetch salta a 16."),
         (ORANGE, "Ciclo 10: slt x4 | beq x4 tiene RAW → RegroupD=1. El beq pasa al slot 0 con su predicción (PredD_0=1 en el "
                  "ciclo 11) y el nuevo slot 1 es addi x10,x10,5 (PC 16), la primera instrucción del destino."),
         (GREEN, "Ciclo 12: el beq se confirma (MispredictE=0) y addi x10, que viaja en la vía 1, no se anula. A la vez Fetch busca "
                 "el beq (PredF_0=1) durante un reagrupamiento: PCNextF = TargetF_0 tiene prioridad sobre PC+4."),
         (ORANGE, "En régimen cada iteración dura 3 ciclos (10, 13, 16, ...) en lugar de 5: el reagrupamiento y la predicción conviven.")]),
    "opt-jal": (
        [(6, 6, RED, "jal x8: fallo"), (9, 9, RED, "jal x0: fallo"), (11, 12, BROWN, "PredF_1"), (13, 14, GREEN, "Ctr = 11"),
         (24, 24, RED, "salida")],
        [(RED, "Ciclos 6 y 9: la primera vez, jal x8 (PC 28) y jal x0 (PC 40) no están en el BTB: MispredictE=1. "
               "Como son jal, su entrada se crea directamente con Ctr=11."),
         (BROWN, "Ciclos 11–12: los dos jal se predicen tomados desde Fetch (PredF_1, ambos en el slot 1): el par (24, 28) va a 36 y "
                 "el par (36, 40) va a 16."),
         (GREEN, "Ciclos 13–23: ningún flush; el while (6 instrucciones) dura 3 ciclos. jal x8 escribe x8 = 32 por WB1 en cada vuelta."),
         (RED, "Ciclo 24: el beq de salida (PC 16) nunca se había tomado, no tiene entrada y falla: FlushM_1 anula el addi x1 de su par.")]),
    "opt-loaduse": (
        [(15, 15, BROWN, "PredF_1"), (17, 17, ORANGE, "load-use"), (18, 18, ORANGE, "burbuja"), (19, 19, GREEN, "WB0"),
         (25, 25, RED, "salida")],
        [(BROWN, "Ciclo 15: el par (lw x5 | beq) se busca con el beq predicho tomado (PredF_1=1): Fetch ya va a loop (PC 56)."),
         (ORANGE, "Ciclo 17: lw y beq están en EX (el beq se confirma) y Decode ya tiene add x10,x10,x5 del destino, que usa x5: "
                  "LoadUseD_0=1, StallF=StallD=1 y FlushE_0/1 insertan una burbuja (ciclo 18)."),
         (GREEN, "Ciclo 19: add x10 entra a EX y toma x5 desde WB0 (ReadDataM=2 en el ciclo 18): el stall se mantiene aunque el "
                 "salto se predijo bien."),
         (RED, "Ciclo 25: salida del bucle, predicho tomado y no tomado: MispredictE=1 y el stall se cancela (prioridad del error).")]),
    # ---------------- professor's program ----------------
    "prog-A": (
        [(5, 7, BLUE, "doble emisión + forwarding"), (8, 9, PURPLE, "un puerto"), (12, 12, GREEN, "chk A")],
        [(BLUE, "Ciclos 5–7: pares completos en EX. add x5 / sub x6 toman x3 de MEM0 y x4 de MEM1; add x9,x7,x8 y addi x9,x0,7 "
                "van juntos (WAW): x9 = 7 porque la vía 1 escribe después."),
         (BLUE, "Ciclo 8: add x10,x9,x6 toma x9 de MEM1 (7, no 18) → 12; en la vía 1 sw x5 calcula su dirección 1536."),
         (PURPLE, "Ciclos 8–9: sw x6 | sw x10 y sw x10 | lw x11 no pueden ir juntos (un solo puerto): IssueOneD=1."),
         (GREEN, "Ciclo 12: sw x10,8(x1), la última de A, llega a WB: chk = A y ok = 1. x5=11, x6=5, x7=16, x9=7, x10=12; "
                 "M[x1+0..8] = 11, 5, 12.")]),
    "prog-B": (
        [(11, 11, ORANGE, "load-use"), (14, 14, ORANGE, "load-use"), (16, 19, PURPLE, "memoria en serie"),
         (20, 20, ORANGE, "load-use"), (25, 25, GREEN, "chk B")],
        [(ORANGE, "Ciclos 11, 14 y 20: add x12 ← lw x11, sub x15 ← lw x14 y add x18 ← lw x17: el slot 0 usa el lw que está en EX → "
                  "LoadUseD_0=1 y un ciclo de stall; luego el dato llega por WB0."),
         (PURPLE, "Ciclos 16–19: sw x15 | lw x16, lw x16 | sw x12 y sw x12 | lw x17: cada par tiene dos accesos a memoria y sale "
                  "de a una instrucción (IssueOneD=1). En el ciclo 14 MemLaneM=1: lw x13 (vía 1) usa el puerto."),
         (GREEN, "Ciclo 25: sw x18,20(x1) llega a WB: chk = B, ok = 1. x12=16, x15=7, x16=7, x17=16, x18=23 y "
                 "M[x1+12..20] = 7, 16, 23. La etapa B es casi secuencial: dependencias load-use y un solo puerto.")]),
    "prog-C1": (
        [(27, 27, RED, "fallo BTB"), (29, 29, BROWN, "PredF_1"), (32, 32, GREEN, "Ctr 10"), (34, 34, GREEN, "Ctr 11")],
        [(RED, "Ciclo 27: primera ejecución de beq x25,x2,C1 (PC 124): sin entrada, se toma → MispredictE=1; se crea la entrada."),
         (BROWN, "Ciclo 29: Fetch busca (120, 124) y predice el beq tomado (PredF_1): PCNextF = 112, la siguiente iteración."),
         (GREEN, "Ciclos 32, 34, 37, ...: el beq se confirma en EX (MispredictE=0) y el contador pasa a 11. slt x25 | beq tiene RAW: "
                 "el beq se reagrupa con la primera instrucción de C1 y se anula el slot 1 cuando el beq queda en el slot 0."),
         (GREEN, "La iteración (4 instrucciones) dura 5 ciclos en B y ~2.5 en C: los 11 saltos tomados de C1 cuestan 2 errores.")]),
    "prog-C2": (
        [(63, 63, RED, "fallo"), (68, 68, ORANGE, "beq C2: fallo"), (72, 72, RED, "T→N"), (75, 75, RED, "jal: fallo"), (81, 81, RED, "N→T"), (87, 87, RED, "T→N")],
        [(RED, "beq x23,x2,C2a (PC 148) alterna tomado / no tomado porque x23 cambia entre 1 y 0 en cada iteración."),
         (RED, "Ciclo 72: Ctr = 10 predice tomado, no se toma → error y Ctr = 01. Ciclo 81: Ctr = 01 predice no tomado, se toma → error "
               "y Ctr = 10. Ciclo 87: otra vez 10 y otra vez error."),
         (RED, "El contador oscila entre 10 y 01 y se equivoca las 12 veces; en B solo fallan las 6 tomadas. Es el caso que el predictor "
               "de 2 bits no puede aprender."),
         (GREEN, "En cambio jal x0,C2b (PC 156) solo falla la primera vez (ciclo 75) y beq x25,x2,C2 (PC 172), que cierra el bucle, falla solo en su primera ejecución (ciclo 68) y luego se predice bien (ciclos 80, 86).")]),
    "prog-C": (
        [(215, 215, RED, "salida C3"), (220, 220, GREEN, "chk C")],
        [(RED, "Ciclo 215: beq x25,x2,C3 de salida (x19 = 12) predicho tomado y no tomado: MispredictE=1, PCCorrectE = 224."),
         (GREEN, "Ciclo 220: sw x24,32(x1) llega a WB en la vía 0: chk = C, ok = 1. x19=12, x20=12, x21=24, x22=18, x24=24, x25=0; "
                 "M[x1+24..32] = 24, 18, 24."),
         (ORANGE, "En el mismo ciclo addi x19,x0,0 (etapa D, vía 1) escribe x19 = 0, por eso la fila x19 ya muestra 0: el testbench "
                  "compara con el valor anterior a esa escritura (12), que es el estado de la etapa C en orden de programa.")]),
    "prog-D": (
        [(278, 278, RED, "beq x2,x2 (D4)"), (282, 282, RED, "beq x2,x2 (D5)"), (285, 286, ORANGE, "load-use"),
         (287, 287, RED, "beq (D6)"), (292, 292, GREEN, "chk D")],
        [(RED, "Ciclos 278, 282 y 287: saltos hacia adelante que se ejecutan una sola vez (D4, D5, D6): no están en el BTB y se "
               "predicen no tomados; al tomarse pagan 2 ciclos, igual que en B."),
         (ORANGE, "Ciclos 285–286: lw x25,40(x1) | addi x26 y luego beq x25,x26: el beq usa el lw (load-use) y espera un ciclo."),
         (BLUE, "Ningún sw x31,44 llega a memoria: M[x1+44] mantiene el 0 escrito al inicio de D y x31 termina en 1."),
         (GREEN, "Ciclo 292: sw x31,52(x1) llega a WB junto con el halt: chk = D, ok = 1. x25=4, x26=4, x27=1560, x28=74, x29=4, "
                 "x31=1 y M[x1+36..52] = 74, 4, 0, 1, 1.")]),
}
