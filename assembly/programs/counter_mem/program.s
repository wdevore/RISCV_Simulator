# Basic test of arithmetics

.section .text
.align 2

# Test memory counting


.global _start

.section .rodata
.balign 4

_start:

    li t0, 0
    li t1, 10
    la t2, .data

loop:
    addi t0, t0, 1
    sb t0, 0xc(t2)
    
    beq t0, t1, done
    j loop

done:
    ebreak


.section .data
.word 0x12345678
.word 0xdeadbeaf
# Memory is Little-Endian form
.word 0x64656164   #  'daed' = 'dead'
#       |      \ low byte
#       \ high byte
.word 0x00000000
