// EF Benchmark - Sieve of Eratosthenes, primes below 200
// a[i] (MEM[4i]) = 1 marks a composite; multiples of p are reached by adding p (no multiply).
// The inner loop runs a different number of times for every prime p.
// Expected: MEM[1000]=46 (primes) [1004]=4227 (sum) [1008]=199 (largest)
        addi x3, x0, 1
        addi x6, x0, 800        ; end of the array (200 words)
        addi x1, x0, 0
init:   sw   x0, 0(x1)          ; a[i] = 0
        addi x1, x1, 4
        slt  x9, x1, x6
        beq  x9, x3, init
        addi x10, x0, 2         ; p
        addi x11, x0, 8         ; 4p (bytes)
        addi x7, x0, 15         ; p < 15 (15 * 15 > 200)
outer:  lw   x13, 0(x11)        ; a[p]
        beq  x13, x3, next      ; composite: skip
        add  x12, x11, x11      ; j = 2p
inner:  sw   x3, 0(x12)         ; a[j] = 1
        add  x12, x12, x11      ; j += p
        slt  x9, x12, x6
        beq  x9, x3, inner
next:   addi x10, x10, 1
        addi x11, x11, 4
        slt  x9, x10, x7
        beq  x9, x3, outer
        addi x1, x0, 8          ; count from i = 2
        addi x14, x0, 2         ; i
        addi x20, x0, 0         ; primes
        addi x21, x0, 0         ; sum
        addi x22, x0, 0         ; largest
count:  lw   x13, 0(x1)
        beq  x13, x3, skip      ; composite
        addi x20, x20, 1
        add  x21, x21, x14
        addi x22, x14, 0
skip:   addi x1, x1, 4
        addi x14, x14, 1
        slt  x9, x1, x6
        beq  x9, x3, count
        sw   x20, 1000(x0)
        sw   x21, 1004(x0)
        sw   x22, 1008(x0)
        jal  x0, 0
