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

;; Sets up the color palettes stored at the specified 16-bit memory address.
;; Takes as input the palette location's address (LSB in X and MSB in Y.)
;; Palettes at this memory location should be a sequence of 16 bytes (each
;; group of 4 corresponds to palettes 0-3.)
.proc setup_palettes

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

