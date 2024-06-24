OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The addresses specified are in byte-address form */
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =128
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM
}