"""Highlighted cycles and notes of each E2 waveform (written after reading the traces).
NOTES[name] = (highlights, notes); highlight = (first cycle, last cycle, colour, label)."""
from waves import BLUE, GREEN, ORANGE, RED, PURPLE

NOTES = {
    "alu-pair": (
        [(4, 8, BLUE, "ALU + ALU en EX"), (9, 10, GREEN, "MEM + ALU")],
        [(BLUE, "Ciclos 4–8: cada par entra completo a EX (IssueOneD=0); las dos ALU calculan a la vez: 3/7, 10/4, 10/6, 7/2 y 12/1."),
         (GREEN, "Ciclos 9–10: sw + addi: el sw usa el puerto de memoria (vía 0) y el addi la ALU de la vía 1 en el mismo ciclo."),
         (BLUE, "Ciclos 6–10: RegWriteW_0 y RegWriteW_1 valen 1 a la vez: dos escrituras por ciclo en el Register File."),
         (GREEN, "16 instrucciones en 12 ciclos (IPC = 1.33), frente a 20 ciclos en el pipeline Single-Issue.")]),
    "raw-forward": (
        [(3, 3, ORANGE, "RAW"), (5, 5, BLUE, "MEM0"), (6, 7, GREEN, "forwarding entre vías"), (8, 11, PURPLE, "un sw por ciclo")],
        [(ORANGE, "Ciclo 3: addi x2,x1,1 necesita x1 del slot 0 → IssueOneD=RegroupD=1; en el ciclo 4 solo addi x1 entra a EX."),
         (BLUE, "Ciclo 5: addi x2 toma x1 desde MEM0 (5+1=6); addi x3 se emitió junto con él en la vía 1."),
         (GREEN, "Ciclo 6: add x4 ← x2 de MEM0 y x3 de MEM1 (6+2=8); sub x5 ← x1 de WB0 y x3 de MEM1 (5−2=3)."),
         (GREEN, "Ciclo 7: or x6 ← x4 de MEM0 y x2 de WB0 (8|6=14); add x7 ← x5 de MEM1 y x4 de MEM0 (3+8=11)."),
         (PURPLE, "Ciclos 8–11: los cuatro sw comparten el único puerto de memoria y se emiten de uno en uno.")]),
    "memory": (
        [(4, 5, ORANGE, "conflicto mem"), (7, 7, GREEN, "lw ‖ ALU"), (8, 9, RED, "ALU ‖ lw + load-use"),
         (11, 13, PURPLE, "RAW + load-use")],
        [(ORANGE, "Ciclos 4–5: sw+sw y sw+lw en Decode → IssueOneD=1: un solo puerto de memoria; FlushE_1 deja burbuja en la vía 1."),
         (GREEN, "Ciclos 7–8: lw+addi y addi+lw se emiten juntos; en el ciclo 9 MemLaneM=1: el lw de la vía 1 usa el puerto (ReadDataM=22)."),
         (RED, "Ciclo 8: add x5 necesita x4 del lw en EX (vía 1) → LoadUseD_0=1, StallF=StallD=1, burbuja en ambas vías; ciclo 10: x4 por WB1 → 33."),
         (PURPLE, "Ciclo 11: lw x10 y addi x8,x10 en el mismo par → RAW; ciclo 12: load-use → stall; ciclo 14: x10 por WB0 → 34.")]),
    "branch": (
        [(6, 6, RED, "beq slot 0"), (9, 9, BLUE, "beq slot 1"), (12, 13, GREEN, "no tomados"), (14, 14, PURPLE, "jal slot 0")],
        [(RED, "Ciclo 6: beq en la vía 0 tomado (TakenE_0=1): FlushD y FlushE limpian Decode y FlushM_1 anula el addi x3,99 de su mismo par."),
         (BLUE, "Ciclo 9: beq en la vía 1 tomado (BrLaneE=1, TakenE_0=0): addi x5, más antiguo, sigue a MEM (InstrM_0 en el ciclo 10)."),
         (GREEN, "Ciclos 12–13: beq no tomados en el slot 0 y en el slot 1: PCSrcE=0 y la otra instrucción del par continúa."),
         (PURPLE, "Ciclo 14: jal x8 en la vía 0 anula el addi x3,99 de la vía 1. x3 se mantiene en 7 y MEM[0]=7.")]),
    "branch-conflict": (
        [(5, 7, ORANGE, "beq + beq"), (10, 10, BLUE, "jal slot 1"), (12, 13, GREEN, "beq + jal"), (15, 17, PURPLE, "RAW → beq")],
        [(ORANGE, "Ciclo 5: dos beq en el par → una sola Branch Unit: IssueOneD=1. El segundo beq se reagrupa y se resuelve tomado en el ciclo 7."),
         (BLUE, "Ciclo 10: jal x5 en la vía 1 tomado (BrLaneE=1): addi x4 (vía 0) se conserva; x5=40 se escribe por WB1 en el ciclo 12."),
         (GREEN, "Ciclos 12–13: beq + jal x3: solo entra el beq; al tomarse, FlushD descarta el jal x3 que esperaba en Decode (x3 sigue en 3)."),
         (PURPLE, "Ciclos 15–17: beq x7 depende de addi x7 en el mismo par → espera un ciclo y toma x7 por forwarding (no tomado).")]),
    "two-writes": (
        [(6, 6, BLUE, "2 escrituras · MEM1"), (7, 7, RED, "WAW x3 · WB1")],
        [(BLUE, "Ciclo 6: addi x1 y addi x2 llegan juntas a WB: RegWriteW_0=RegWriteW_1=1, se escriben x1=1 y x2=2 en el mismo flanco."),
         (BLUE, "Ciclo 6: add x4 necesita x3 y las dos vías en MEM lo escriben (10 y 30): el forwarding elige MEM1, la más joven → 30."),
         (RED, "Ciclo 7: ambas escrituras a x3 llegan a WB; el puerto de la vía 1 se aplica último y x3 (RF) queda en 30. addi x5 toma WB1 → 31."),
         (RED, "Stores: MEM[0]=30, MEM[4]=31, MEM[8]=3, iguales a los del pipeline Single-Issue.")]),
    "regroup": (
        [(3, 3, ORANGE, "regroup"), (6, 6, ORANGE, "regroup"), (9, 9, ORANGE, "regroup"), (11, 11, ORANGE, "regroup")],
        [(ORANGE, "Ciclo 3: (addi x1 | sw x1) tiene RAW → RegroupD=1. En el ciclo 4 sw x1,0 (0x4) pasa a slot 0 y addi x1 (0x8) a slot 1; el PC avanza 4."),
         (ORANGE, "Ciclos 6, 9 y 11: el mismo reagrupamiento; PCD_0 y PCD_1 siempre son consecutivos y crecientes: nada se pierde ni se repite."),
         (GREEN, "Ciclo 6: sw x1,4 se emite en la vía 1 (pareado con addi x2); en el ciclo 7 MemLaneM=1 le da el puerto de memoria."),
         (GREEN, "Los sw escriben 1, 2, 3, 4, 5 y 6 en MEM[0..20]: la secuencia queda intacta, igual que en el pipeline.")]),
}
