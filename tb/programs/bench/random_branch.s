// EF Benchmark - Data-dependent branch without a regular pattern
// 32 iterations of x = (5x + 3) mod 64, x0 = 7; the inner beq depends on bit 4 of x:
// the case where the predictor helps least.
// Expected: MEM[0]=16 [4]=16 [8]=39
        addi x3, x0, 1
        addi x2, x0, 32         ; iterations
        addi x1, x0, 0
        addi x5, x0, 7          ; seed
        addi x10, x0, 0         ; bit 4 = 0
        addi x11, x0, 0         ; bit 4 = 1
loop:   add  x7, x5, x5
        add  x7, x7, x7
        add  x5, x7, x5
        addi x5, x5, 3
        andi x5, x5, 63
        andi x8, x5, 16
        addi x1, x1, 1
        beq  x8, x0, zero       ; data dependent
        addi x11, x11, 1
        jal  x0, next
zero:   addi x10, x10, 1
next:   slt  x4, x1, x2
        beq  x4, x3, loop       ; loop branch
        sw   x10, 0(x0)
        sw   x11, 4(x0)
        sw   x5, 8(x0)
        jal  x0, 0
