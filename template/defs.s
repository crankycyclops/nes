;;;;;;;;;;;;;;;;;;;;;;
;;; PPU registers. ;;;
;;;;;;;;;;;;;;;;;;;;;;

PPUCTRL		= $2000
PPUMASK		= $2001
PPUSTATUS	= $2002
OAMADDR		= $2003
OAMDATA		= $2004
PPUSCROLL	= $2005
PPUADDR		= $2006
PPUDATA		= $2007

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Other IO registers. ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

OAMDMA		= $4014
APUSTATUS	= $4015
JOYPAD1		= $4016
JOYPAD2		= $4017

;;;;;;;;;;;;;;;;;;;;;
;;; Useful macros ;;;
;;;;;;;;;;;;;;;;;;;;;

;; PPU warmup: wait three frames.
;; See: http://forums.nesdev.com/viewtopic.php?f=2&t=3958
.macro ppuwarmup

:
	bit PPUSTATUS
	bpl :-
:
	bit PPUSTATUS
	bpl :-
:
	bit PPUSTATUS
	bpl :-

.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Zero out RAM
.macro zeroram

	ldx #$00
	txa

:	sta $000, x
	sta $100, x
	sta $300, x
	sta $400, x
	sta $500, x
	sta $600, x
	sta $700, x

	; The $200s are shadow sprite OAM and should be set to $ff
	lda #$ff
	sta $200, x

	inx

	; This works because the inx instruction will always result in a Z (zero)
	; flag value of 0 until we wrap back around to 0 again, at which point the
	; Z flag will get set to 1. The Z flag equaling 1 is how the bne instruction
	; determines that a comparison was equal, and therefore, once we wrap
	; back around to X = 0, we no longer branch and the loop is over.
	bne :-

.endmacro

