# Basic test of 'li'

.section .text
.align 2

.global _start
_start:
    li x6, 0xa
    slti x11, x6 , 4
    
    ebreak

