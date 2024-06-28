# Basic test of arithmetics

.section .text
.align 2

.global _start
_start:

loop:
    li x5, 0
    addi x5, x5, 1
    j loop

    ebreak

