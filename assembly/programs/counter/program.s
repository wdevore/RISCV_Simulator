# Basic test of arithmetics

.section .text
.align 2

# Counts to 10

.global _start

.section .rodata
.balign 4

_start:
    li t0, 0    # x5; reset counter
    li t1, 4096*128   # Terminal count
loop:
    addi t0, t0, 1
    beq t0, t1, done
    j loop

done:
    ebreak
    