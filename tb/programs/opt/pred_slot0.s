// EF Program 1 - Branch predicted taken in slot 0
// The younger slot 1 (addi x5) is annulled in Fetch while the beq is predicted taken,
// and executes after the loop exit (predicted taken, not taken -> PC+4 of the beq).
// Expected: x1=10 x10=30 x5=7 ; MEM[0]=30 [4]=7
        addi x1, x0, 0
        addi x2, x0, 10
        addi x3, x0, 1
        addi x10, x0, 0
loop:   addi x1, x1, 1          ; pair (16, 20)
        addi x10, x10, 3
        slt  x4, x1, x2         ; pair (24, 28): x4 = (i < n)
        addi x0, x0, 0
        beq  x4, x3, loop       ; pair (32, 36): slot 0, predicted taken
        addi x5, x0, 7          ; slot 1: annulled while the beq is predicted taken
        sw   x10, 0(x0)
        sw   x5, 4(x0)
        jal  x0, 0
