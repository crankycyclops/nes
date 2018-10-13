.include "defs.s"

.zeropage

; We reserve one byte for storing the data that is read from controller. We have
; to initialize this with instructions in the .code section, because otherwise
; we get the following linker warning: Segment `ZEROPAGE' with type `bss'
; contains initialized data
buttons:

.code

; Initialize zeropage variables
lda #$01
sta buttons

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Reset handler

.proc reset

	sei             ; Disable interrupts
	cld             ; Clear decimal mode
	ldx #$ff
	txs             ; Initialize SP = $FF
	inx
	stx PPU_CTRL    ; PPU_CTRL = 0 (see: https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL)
	stx PPU_MASK    ; PPU_MASK = 0
	stx APU_STATUS  ; APUSTATUS = 0

	; jsr zeroapu
	jsr init_apu
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

; include library procedures
.include "procedures.s"

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
;;; Empty CHR data, for now

.segment "CHR0a"
.segment "CHR0b"
