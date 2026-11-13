// EF Benchmark - Bubble sort of 16 pseudo-random words, x = (5x + 3) mod 64, x0 = 7,
// then a checksum unrolled by 2 and a count of inversions (must be 0).
// Expected: MEM[0..60]=1,2,4,5,8,9,13,14,15,23,26,28,38,43,48,51 ; MEM[256]=328 (sum)
//           [260]=0 (inversions) [264]=62 (swaps)
        addi x3, x0, 1          ; flag compared by the backward beqs
        addi x6, x0, 64         ; end of the array
        addi x5, x0, 7          ; seed
        addi x1, x0, 0          ; address
init:   add  x7, x5, x5         ; 2x
        add  x7, x7, x7         ; 4x
        add  x5, x7, x5         ; 5x
        addi x5, x5, 3
        andi x5, x5, 63         ; mod 64
        sw   x5, 0(x1)
        addi x1, x1, 4
        slt  x9, x1, x6
        beq  x9, x3, init
        addi x11, x0, 60        ; end of the unsorted part (bytes)
        addi x18, x0, 0         ; swaps
outer:  addi x12, x0, 0         ; j (bytes)
inner:  lw   x13, 0(x12)        ; a[j]
        lw   x14, 4(x12)        ; a[j+1]
        addi x12, x12, 4
        slt  x16, x12, x11      ; j < end
        slt  x15, x14, x13      ; a[j+1] < a[j]
        beq  x15, x0, noswap    ; data dependent
        sw   x14, -4(x12)
        sw   x13, 0(x12)
        addi x18, x18, 1
noswap: beq  x16, x3, inner
        addi x11, x11, -4
        slt  x17, x0, x11       ; end > 0
        beq  x17, x3, outer
        addi x1, x0, 0          ; checksum with two accumulators
        addi x20, x0, 0
        addi x21, x0, 0
        addi x22, x0, 0         ; inversions
        lw   x13, 0(x0)
check:  lw   x14, 4(x1)
        lw   x15, 8(x1)
        add  x20, x20, x13
        add  x21, x21, x14
        slt  x16, x14, x13
        slt  x17, x15, x14
        add  x22, x22, x16
        add  x22, x22, x17
        addi x13, x15, 0
        addi x1, x1, 8
        slti x9, x1, 56
        beq  x9, x3, check
        lw   x14, 60(x0)        ; last pair
        add  x20, x20, x13
        add  x21, x21, x14
        slt  x16, x14, x13
        add  x22, x22, x16
        add  x23, x20, x21
        sw   x23, 256(x0)
        sw   x22, 260(x0)
        sw   x18, 264(x0)
        jal  x0, 0
