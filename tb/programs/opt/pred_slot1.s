// EF Program 2 - Branch predicted taken in slot 1
// Slot 0 is older than the beq and is kept; the next PC is the target of slot 1.
// Expected: x1=11 x10=33 x5=7 ; MEM[0]=33 [4]=7
        addi x1, x0, 0
        addi x2, x0, 10
        addi x3, x0, 1
        addi x10, x0, 0
loop:   slt  x4, x1, x2         ; pair (16, 20): x4 = (old i < n), no RAW
        addi x1, x1, 1
        addi x10, x10, 3        ; pair (24, 28): slot 0, older -> kept
        beq  x4, x3, loop       ; slot 1, predicted taken
        addi x5, x0, 7
        sw   x10, 0(x0)
        sw   x5, 4(x0)
        jal  x0, 0
