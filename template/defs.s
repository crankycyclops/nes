;;;;;;;;;;;;;;;;;;;;;
;;; PPU registers ;;;
;;;;;;;;;;;;;;;;;;;;;

PPUCTRL     = $2000
PPUMASK     = $2001
PPUSTATUS   = $2002
OAMADDR     = $2003
OAMDATA     = $2004
PPUSCROLL   = $2005
PPUADDR     = $2006
PPUDATA     = $2007

;;;;;;;;;;;;;;;;;;;;;
;;; APU registers ;;;
;;;;;;;;;;;;;;;;;;;;;

; See: https://safiire.github.io/blog/2015/03/29/creating-sound-on-the-nes/

APU_STATUS               = $4015

APU_PULSE1_CONTROL       = $4000

; Value: DDLC VVVV
; D: Duty cycle of the pulse wave 00 = 12.5% 01 = 25% 10 = 50% 11 = 75%
; L: Length Counter Halt
; C: Constant Volume
; V: 4-bit volume

APU_PULSE1_RAMP_CONTROL  = $4001

; Value: EPPP NSSS
; E: Enabled flag
; P: Sweep Divider Period
; N: Negate flag, inverts the sweep envelope
; S: Shift count

APU_PULSE1_FT            = $4002

; Value: TTTT TTTT
; T: Low 8 bits of the timer that controls the frequency

APU_PULSE1_CT            = $4003

; Value: LLLL LTTT
; L: Length counter, if Length Counter Halt is 0, timer for note length
; T: High 3 bits of timer that controls frequency

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Other IO registers ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

OAMDMA      = $4014
JOYPAD1     = $4016
JOYPAD2     = $4017

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

;; Zero APU registers
.macro zeroapu

	lda #$00
	ldx #$00

:	sta $4000, x
	inx
	cpx $18
	bne :-

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

	; The $200s are shadow sprite OAM and should be set to $fe
	; See: https://safiire.github.io/blog/2015/03/29/creating-sound-on-the-nes/
	lda #$fe
	sta $200, x

	inx

	; This works because the inx instruction will always result in a Z (zero)
	; flag value of 0 until we wrap back around to 0 again, at which point the
	; Z flag will get set to 1. The Z flag equaling 1 is how the bne instruction
	; determines that a comparison was equal, and therefore, once we wrap
	; back around to X = 0, we no longer branch and the loop is over.
	bne :-

.endmacro

