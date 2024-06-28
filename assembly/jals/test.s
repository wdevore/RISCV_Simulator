# Basic test of arithmetics

.section .text
.align 2

# ra = x1

.global _start
_start:

    li x5, 0
loop:
                        # auipc x1, 0 = 0x404
    call cnt            # jalr	16(ra) = jalr x1, 16(x1)
    j loop              # jal x0, -8

    ebreak

cnt:
    addi x5, x5, 1
    ret	                # jalr x0, x1, 0  OR jalr x0, ra, 0

