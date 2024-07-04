OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The addresses specified are in byte-address form */
    ROM      :ORIGIN =0x00000400,LENGTH =1024  /* -> 0x07ff */
    BRAM(wx) :ORIGIN =0x00000900,LENGTH =1024  /* -> 0x0cff */
    DATA     :ORIGIN =0x00001000,LENGTH =64    /* -> 0x103f */
    UART(w)  :ORIGIN =0x00001d00,LENGTH =4
}

SECTIONS
{
    .rodata : {
        rom_data = .;
        *(.rodata)
    }> ROM

    .text : {
        *(.text)
    }> BRAM

    .data : {
        *(.data)
    }> DATA
}