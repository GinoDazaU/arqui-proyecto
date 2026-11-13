// EF Program 4 - jal in the BTB
// While loop with a forward exit beq and a backward jal, plus a jal x8 that skips a
// poisoned addi (it would write 99) and writes its return address.
// Expected: x10=20 x8=32 x9=0 ; MEM[0]=20 [4]=32 [8]=0
        addi x1, x0, 0
        addi x2, x0, 5
        addi x10, x0, 0
        addi x9, x0, 0
while:  beq  x1, x2, done       ; forward exit, taken once
        addi x1, x1, 1
        addi x10, x10, 2
        jal  x8, skip           ; x8 = 32
        addi x9, x0, 99         ; skipped
skip:   addi x10, x10, 2
        jal  x0, while          ; backward jump
done:   sw   x10, 0(x0)
        sw   x8, 4(x0)
        sw   x9, 8(x0)
        jal  x0, 0
