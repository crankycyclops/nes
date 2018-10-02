;;; PPU registers.

PPUCTRL		= $2000
PPUMASK		= $2001
PPUSTATUS	= $2002
OAMADDR		= $2003
OAMDATA		= $2004
PPUSCROLL	= $2005
PPUADDR		= $2006
PPUDATA		= $2007

;;; Other IO registers.

OAMDMA		= $4014
APUSTATUS	= $4015
JOYPAD1		= $4016
JOYPAD2		= $4017

;;; Useful macros

;; PPU warmup: wait three frames.
;; See: http://forums.nesdev.com/viewtopic.php?f=2&t=3958
.macro ppuwarmup

	:  bit PPUSTATUS
	   bpl :-
	:  bit PPUSTATUS
	   bpl :-
	:  bit PPUSTATUS
	   bpl :-

.endmacro

