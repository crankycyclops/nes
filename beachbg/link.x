MEMORY {

	# CPU Memory Addresses
    ZP:     start = $0000, size = $0100, type = rw;
    RAM:    start = $0300, size = $0500, type = rw;
    HEADER: start = $0000, size = $0010, type = rw,
            file = %O, fill = yes;
    PRG0:   start = $8000, size = $8000, type = ro,
            file = %O, fill = yes;

	# PPU Memory Addresses
    CHR0a:  start = $0000, size = $1000, type = ro,
            file = %O, fill = yes;
    CHR0b:  start = $1000, size = $1000, type = ro,
            file = %O, fill = yes;
}

SEGMENTS {
    ZEROPAGE: load = ZP, type = zp;
    BSS:    load = RAM, type = bss;
    INES:   load = HEADER, type = ro, align = $10;
    CODE:   load = PRG0, type = ro;
    VECTOR: load = PRG0, type = ro, start = $FFFA;
    CHR0a:  load = CHR0a, type = ro;
    CHR0b:  load = CHR0b, type = ro;
}