; A simple NES ROM that displays a beach background to the screen.

.include "defs.s"

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Reset handler

.proc reset

	init_cpu

	stx PPU_CTRL    ; PPU_CTRL = 0 (see: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL)
	stx PPU_MASK    ; PPU_MASK = 0
	stx APU_STATUS  ; APUSTATUS = 0

	jsr init_apu
	ppuwarmup
	zeroram

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Setup Palette Colors ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #<palettes ; LSB
	ldy #>palettes ; MSB
	jsr load_palettes

	;;;;;;;;;;;;;;;;;;;;;;;
	;;; Setup Nametable ;;;
	;;;;;;;;;;;;;;;;;;;;;;;

	ldx #<nametable ; LSB
	ldy #>nametable ; MSB
	lda #0 ; we're loading nametable 0
	jsr load_nametable

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Setup Attribute Table ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldx #<attributes ; LSB
	ldy #>attributes ; MSB
	lda #0 ; we're loading the attributes for nametable 0
	jsr load_attribute_table

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Tell the PPU to display a picture ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; We're not actually going to do any scrolling, but we need to initialize
	; this to (0, 0) to indicate that we're starting our display from the
	; beginning of the nametable.
	lda #0
	sta PPU_SCROLL
	sta PPU_SCROLL

	; Tell the PPU to use Pattern Table 0 and Nametable 0
	lda #%00011110
	sta PPU_MASK

	; Tell the PPU to start rendering
	lda #%10000000
	sta PPU_CTRL

forever:
	jmp forever

.endproc

; include library procedures
.include "procedures.s"

; Beach scene nametable
nametable:
	.incbin "data/beach.nam"

; Beach scene attributes
attributes:
	.incbin "data/beach.atr"

; Beach scene palettes
palettes:
	.incbin "data/beach.pal"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; NMI (vertical blank) handler

.proc nmi
	rti
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; IRQ handler

.proc irq
	rti
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Vector table

.segment "VECTOR"
.addr nmi
.addr reset
.addr irq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CHR0a"

	; Background tiles
	.incbin "data/tiles.chr"

.segment "CHR0b"

