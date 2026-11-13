// EF Program 5 - Pattern taken, taken, not taken
// The 2-bit counter stays in the taken states (one misprediction per period); each
// mispredicted not taken resumes at PC+4 and runs the not-taken path.
// Expected: x1=9 x10=9 x11=3 ; MEM[0]=9 [4]=3
        addi x1, x0, 0          ; i
        addi x2, x0, 9          ; n
        addi x3, x0, 1
        addi x6, x0, 0          ; k = i mod 3
        addi x10, x0, 0         ; iterations
        addi x11, x0, 0         ; not-taken count
loop:   slti x9, x6, 2          ; 1 when k < 2
        addi x1, x1, 1
        beq  x9, x3, small      ; T, T, N, T, T, N, ...
        addi x11, x11, 1        ; not-taken path
        addi x6, x0, -1
small:  addi x6, x6, 1
        addi x10, x10, 1
        slt  x4, x1, x2
        addi x0, x0, 0
        beq  x4, x3, loop
        sw   x10, 0(x0)
        sw   x11, 4(x0)
        jal  x0, 0
