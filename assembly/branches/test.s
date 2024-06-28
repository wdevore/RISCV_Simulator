# Basic test of arithmetics

.section .text
.align 2

# ra = x1

.global _start
_start:

    li t0, 1    # x5
    li t1, 2    # x6
    beq t0, t1, bbeq    # if t0 == t1 then target
    bne t0, t1, bbne    # if t0 != t1 then target
    
bbeq:
    li t2, 0x0a # x7
    ebreak

bbne:
    li t2, 0x0b # x7
    ebreak

