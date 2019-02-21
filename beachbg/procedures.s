;; Zero APU registers
;; Copied from: https://safiire.github.io/blog/2015/03/29/creating-sound-on-the-nes/
;; I'm not sure which function I should call, this, or init_apu (below) from
;; nesdev.com. I need to study sound on the NES more before I can better understand
;; these functions.
.proc zeroapu

	lda #$00
	ldx #$00

:	sta $4000, x
	inx
	cpx $18
	bne :-

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Initialize the APU to a known state
;; Adapted (mostly copied) from: https://wiki.nesdev.com/w/index.php/APU_basics#Register_initialization
.proc init_apu

	; Init $4000-4013
	ldy #$13

:	lda regs, y
	sta $4000, y
	dey
	bpl :-

	; We have to skip over $4014 (OAMDMA)
	lda #$0f
	sta $4015
	lda #$40
	sta $4017

	rts

regs:

	.byte $30, $08, $00, $00
	.byte $30, $08, $00, $00
	.byte $80, $00, $00, $00
	.byte $30, $00, $00, $00
	.byte $00, $00, $00, $00

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Loads a nametable into the PPU. Takes as input the nametable number (0-3) in
;; A and the nametable data's 16-bit memory address (LSB in X and MSB in Y.)
;; Note that for a serious project where saving space is important, you might
;; want to replace this procedure with one that can load compressed data.
.proc load_nametable

	; ZP address containing an array (lookup table) of PPU nametable base
	; addresses (for nametables 0-3)
	NAMETABLE_BASE_PPU_ADDRESSES = $00

	; ZP address containing 16-bit pointer to nametable data (little-endian)
	NAMETABLE_DATA_ADDR = $04

	; ZP address containing the selected nametable we want to load data into (0-3)
	NAMETABLE_SELECTED = $06

	sta NAMETABLE_SELECTED

	pha
	txa
	pha
	tya
	pha

	; Nametable data 16-bit address (little-endian)
	stx NAMETABLE_DATA_ADDR
	sty NAMETABLE_DATA_ADDR + 1

	; Lookup table that we'll use to select the MSB of the starting PPU address
	; for the selected nametable
	ldx #NAMETABLE_0_ADDR_MSB
	stx NAMETABLE_BASE_PPU_ADDRESSES
	ldx #NAMETABLE_1_ADDR_MSB
	stx NAMETABLE_BASE_PPU_ADDRESSES + 1
	ldx #NAMETABLE_2_ADDR_MSB
	stx NAMETABLE_BASE_PPU_ADDRESSES + 2
	ldx #NAMETABLE_3_ADDR_MSB
	stx NAMETABLE_BASE_PPU_ADDRESSES + 3

	; Prime the PPU to start receiving data for the chosen nametable
	ldy NAMETABLE_SELECTED
	ldx NAMETABLE_BASE_PPU_ADDRESSES, Y
	stx PPU_ADDR
	ldx #NAMETABLE_ADDR_LSB
	stx PPU_ADDR

	; The nametable's data is 4 * 240($f0) = 960 bytes. This number is too large for
	; a single 8-bit integer, so I'm doing a nested loop instead.

	ldx #$4

outerNametableLoadLoop:

	cpx #0
	beq endOuterNametableLoadLoop

	ldy #$f0

innerNametableLoadLoop:

	cpy #0
	beq endInnerNametableLoadLoop

	; Send the next byte to the PPU
	tya
	pha
	ldy #0
	lda (NAMETABLE_DATA_ADDR), Y
	sta PPU_DATA

	inc NAMETABLE_DATA_ADDR

	; If incrementing the LSB of the data pointer's 16-bit address results in an
	; overflow, increment the MSB as well.
	bne skipIncNametableDataAddr
	inc NAMETABLE_DATA_ADDR + 1

skipIncNametableDataAddr:

	pla
	tay
	dey
	jmp innerNametableLoadLoop

endInnerNametableLoadLoop:

	dex
	jmp outerNametableLoadLoop

endOuterNametableLoadLoop:

	pla
	tay
	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Loads the attribute table for the specified nametable. Takes as input the
;; attribute table's 16-bit address (LSB in X and MSB in Y), along with the
;; associated nametable (0-3), stored in A.
.proc load_attribute_table

	; ZP address containing an array (lookup table) of PPU attribute table base
	; addresses (for nametables 0-3)
	ATTR_TABLE_BASE_PPU_ADDRESSES = $00

	; ZP address containing 16-bit pointer to attribute table data (little-endian)
	ATTR_DATA_ADDR = $04

	; ZP address containing the selected nametable we want to load the 
	; attribute table data for (0-3)
	NAMETABLE_SELECTED = $06

	sta NAMETABLE_SELECTED

	pha
	txa
	pha
	tya
	pha

	; Lookup table that we'll use to select the MSB of the starting PPU address
	; for the selected nametable
	ldx #ATTRIBUTE_TABLE_0_ADDR_MSB
	stx ATTR_TABLE_BASE_PPU_ADDRESSES
	ldx #ATTRIBUTE_TABLE_1_ADDR_MSB
	stx ATTR_TABLE_BASE_PPU_ADDRESSES + 1
	ldx #ATTRIBUTE_TABLE_2_ADDR_MSB
	stx ATTR_TABLE_BASE_PPU_ADDRESSES + 2
	ldx #ATTRIBUTE_TABLE_3_ADDR_MSB
	stx ATTR_TABLE_BASE_PPU_ADDRESSES + 3

	; Prime the PPU to start receiving data for the chosen attribute table
	ldy NAMETABLE_SELECTED
	ldx ATTR_TABLE_BASE_PPU_ADDRESSES, Y
	stx PPU_ADDR
	ldx #ATTRIBUTE_TABLE_ADDR_LSB
	stx PPU_ADDR

	ldy #0

attributeTableLoop:

	lda (ATTR_DATA_ADDR), Y
	sta PPU_DATA

	; The attribute table is 64 ($ff) bytes long. Starting from a zero offset,
	; then, we loop until $ff overflows back to 0. At that point, we'll have
	; copied 64 bytes from system memory to the PPU.
	iny
	bne attributeTableLoop

	pla
	tay
	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Sets up the color palettes stored at the specified 16-bit memory address.
;; Takes as input the palette location's address (LSB in X and MSB in Y.)
;; Palettes at this memory location should be a sequence of 16 bytes (each
;; group of 4 corresponds to palettes 0-3.)
.proc load_palettes

	pha
	txa
	pha
	tya
	pha

	stx $00 ; addresses are little-endian and have the LSB at the front
	sty $01

	; used to index into the palettes pointer at ZP address $00, for the offset
	; of PPU palette addresses, and as the loop's terminating condition (when it
	; reaches $1f, we're done.)
	ldy #0

	; Set the universal background color once before looping over palettes
	ldx #PALETTE_ADDR_MSB
	stx PPU_ADDR
	ldx #PALETTE_UNIVERSAL_BG_ADDR_LSB
	stx PPU_ADDR

	lda ($00), Y
	sta PPU_DATA

; You'll note that I cut and pasted the same instructions three times to set
; each palette color. Ordinarily, this would be a massive code smell, and I
; thought about putting these instructions in a loop. But because I'm already
; using all three registers, I'd have to make constant use of the stack, which
; would result in extra instructions anyway and worse performance. So even
; though it's not the "correct" computer sciencey solution, I believe it's the
; right approach here. Assembly language can get ugly, especially with such a
; limited architecture.
paletteloop:

	; skip past universal background color, which was already set
	iny

	; Color #1 address
	ldx #PALETTE_ADDR_MSB
	stx PPU_ADDR
	sty PPU_ADDR

	; Color #1 set
	lda ($00), Y
	sta PPU_DATA

	iny

	; Color #2 address
	ldx #PALETTE_ADDR_MSB
	stx PPU_ADDR
	sty PPU_ADDR

	; Color #1 set
	lda ($00), Y
	sta PPU_DATA

	iny

	; Color #3 address
	ldx #PALETTE_ADDR_MSB
	stx PPU_ADDR
	sty PPU_ADDR

	; Color #3 set
	lda ($00), Y
	sta PPU_DATA

	iny

	cpy #$20
	beq endpaletteloop
	jmp paletteloop

endpaletteloop:

	pla
	tay
	pla
	tax
	pla

	rts

.endproc

