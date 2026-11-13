// EF Program 7 - Load-use stall behind a correctly predicted branch
// The pair (lw, beq) issues together; the beq is predicted taken, so Decode already holds
// the target pair, whose add uses the lw: the stall must still happen.
// Expected: x10=10 ; MEM[0]=10 [4]=1 [8]=2 [12]=3 [16]=4
        addi x3, x0, 1
        addi x6, x0, 1
        sw   x6, 4(x0)
        addi x6, x0, 2
        sw   x6, 8(x0)
        addi x6, x0, 3
        sw   x6, 12(x0)
        addi x6, x0, 4
        sw   x6, 16(x0)
        addi x1, x0, 0
        addi x2, x0, 16
        addi x10, x0, 0
        addi x5, x0, 0
        addi x0, x0, 0
loop:   add  x10, x10, x5       ; LOAD-USE with the lw of the previous iteration
        addi x1, x1, 4
        slt  x4, x1, x2
        addi x0, x0, 0
        lw   x5, 0(x1)          ; pair: memory + branch
        beq  x4, x3, loop
        add  x10, x10, x5
        sw   x10, 0(x0)
        jal  x0, 0
