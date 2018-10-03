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
	stx APU_STATUS  ; APUSTATUS = 0

	zeroapu
	ppuwarmup
	zeroram

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Game code begins here ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Play audio forever.
	lda #$01		; enable pulse 1
	sta APU_STATUS
	lda #$08		; period
	sta APU_PULSE1_FT
	lda #$02
	sta APU_PULSE1_CT
	lda #$bf		; volume
	sta APU_PULSE1_CONTROL

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
