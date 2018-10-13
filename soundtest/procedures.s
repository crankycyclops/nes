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

; Shamelessly stolen from: https://wiki.nesdev.com/w/index.php/Controller_Reading
; Note: this only reads the first controller.
.proc read_controller

	lda #$01

	; While the strobe bit is set, buttons will be continuously reloaded.
	; This means that reading from JOYPAD1 will only return the state of the
	; first button: button A.
	sta CONTROLLER_1
	sta buttons
	lsr a        ; now A is 0

	; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
	; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
	sta CONTROLLER_1

loop:
	lda CONTROLLER_1
	lsr a	       ; bit0  -> Carry
	rol buttons    ; Carry -> bit0; bit 7 -> Carry
	bcc loop
	rts

.endproc

