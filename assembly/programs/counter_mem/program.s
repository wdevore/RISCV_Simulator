# Basic test of arithmetics

.section .text
.align 2

# Test memory counting


.global _start

.section .rodata
.balign 4

_start:
    lw t0, number

done:
    ebreak


.section .data
number: .word 0x12345678
.word 0xdeadbeaf
# Memory is Little-Endian form
.word 0x64656164   #  'daed' = 'dead'
#       |      \ low byte
#       \ high byte
