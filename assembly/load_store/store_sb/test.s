# Basic test of 'li'

.section .text
.align 2

# for 'sb; the offset counts by 1 byte, for example, 0,1,2,3
# for 'sh' the offset counts by 2 bytes, for example, 0, 3
# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    li x6, 0x0908
    li x11, 0xaabbccdd
    sw x11, 0x0(x6)

    ebreak

