.include "defs.s"

.code

;;; ----------------------------------------------------------------------------
;;; Reset handler

.proc reset

	sei             ; Disable interrupts
	cld             ; Clear decimal mode
	ldx #$ff
	txs             ; Initialize SP = $FF
	inx
	stx PPUCTRL     ; PPUCTRL = 0 (see: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL)
	stx PPUMASK     ; PPUMASK = 0
	stx APUSTATUS   ; APUSTATUS = 0

	ppuwarmup

	;; Zero ram.
	txa
:	sta $000, x
	sta $100, x
	sta $200, x
	sta $300, x
	sta $400, x
	sta $500, x
	sta $600, x
	sta $700, x
	inx
	bne :-

	;; Play audio forever.
	lda #$01		; enable pulse 1
	sta APUSTATUS
	lda #$08		; period
	sta $4002
	lda #$02
	sta $4003
	lda #$bf		; volume
	sta $4000
forever:
	jmp forever
.endproc

;;; ----------------------------------------------------------------------------
;;; NMI (vertical blank) handler

.proc nmi
	rti
.endproc

;;; ----------------------------------------------------------------------------
;;; IRQ handler

.proc irq
	rti
.endproc

;;; ----------------------------------------------------------------------------
;;; Vector table

.segment "VECTOR"
.addr nmi
.addr reset
.addr irq

;;; ----------------------------------------------------------------------------
;;; Empty CHR data, for now

.segment "CHR0a"
.segment "CHR0b"
