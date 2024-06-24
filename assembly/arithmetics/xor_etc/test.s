# Basic test of arithmetics

.section .text
.align 2

.global _start
_start:
    li x6, 0x1
    li x7, 0x3
    slli x11, x6, 3
    
    ebreak

