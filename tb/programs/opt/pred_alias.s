// EF Program 6 - Two branches with the same BTB index
// The inner beqs (PCs 36 and 100) evict each other's entry in every outer iteration:
// only misses (predicted not taken), never a wrong result.
// Expected: x10=9 x11=9 ; MEM[0]=9 [4]=9
        addi x3, x0, 1
        addi x20, x0, 0         ; outer counter
        addi x21, x0, 3
        addi x10, x0, 0
        addi x11, x0, 0
outer:  addi x1, x0, 0
in1:    addi x1, x1, 1
        addi x10, x10, 1
        slt  x4, x1, x21
        beq  x4, x3, in1        ; BTB index 9
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x0, x0, 0
        addi x1, x0, 0
in2:    addi x1, x1, 1
        addi x11, x11, 1
        slt  x4, x1, x21
        beq  x4, x3, in2        ; 36 + 64: same index, other tag
        addi x20, x20, 1
        slt  x5, x20, x21
        beq  x5, x3, outer
        sw   x10, 0(x0)
        sw   x11, 4(x0)
        jal  x0, 0
