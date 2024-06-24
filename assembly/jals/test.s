# Basic test of arithmetics

.section .text
.align 2

.global _start
_start:

loop:
    addi x5, x5, 1
    jal x1, loop
    
    ebreak

