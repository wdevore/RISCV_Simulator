# Basic test of arithmetics

.section .text
.align 2

# ra = x1


.global _start

_start:
    j go

test1:
    li t2, 0x0a # x7
    ebreak

test2:
    li t2, 0x0b # x7
    ebreak

go:
    li t0, -4    # x5
    li t1, 6    # x6
    bltu t0, t1, test1
    bgeu t0, t1, test2
    # blt t0, t1, test1
    # bge t0, t1, test2
    # beq t0, t1, test1
    # bne t0, t1, test2

    li t2, 0x0c # x7
    ebreak


