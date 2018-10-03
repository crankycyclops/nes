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

