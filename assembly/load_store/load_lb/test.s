# Basic test of 'li'

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    li x6, 0x0900
    lb x11, 0x0a(x6)

    ebreak

