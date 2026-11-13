// EF Program 3 - Predicted branch and regroup
// RAW slt -> beq: only slt issues and the beq is regrouped with the first instruction of its
// target (addi x10). The beq is correctly predicted, so that instruction must not be annulled.
// Expected: x1=6 x10=30 x5=9 ; MEM[0]=30 [4]=9
        addi x1, x0, 0
        addi x2, x0, 6
        addi x3, x0, 1
        addi x10, x0, 0
loop:   addi x10, x10, 5        ; joins the beq after the regroup
        addi x1, x1, 1
        slt  x4, x1, x2
        beq  x4, x3, loop       ; RAW on x4 -> regroup
        addi x5, x0, 9
        sw   x10, 0(x0)
        sw   x5, 4(x0)
        jal  x0, 0
