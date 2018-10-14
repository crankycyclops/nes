;; Plays a short pulse in the key of A (NTSC timing) with each of the four
;; possible duty cycles.
.proc play_pulse_A_duty_ntsc

	pha

	lda #%00011111
	sta APU_PULSE1_CONTROL

	lda #%11111011
	sta APU_PULSE1_FT

	lda #%11111001
	sta APU_PULSE1_CT


	jsr delay_half_second_ntsc


	lda #%01011111
	sta APU_PULSE1_CONTROL

	lda #%11111011
	sta APU_PULSE1_FT

	lda #%11111001
	sta APU_PULSE1_CT


	jsr delay_half_second_ntsc


	lda #%10011111
	sta APU_PULSE1_CONTROL

	lda #%11111011
	sta APU_PULSE1_FT

	lda #%11111001
	sta APU_PULSE1_CT


	jsr delay_half_second_ntsc


	lda #%11011111
	sta APU_PULSE1_CONTROL

	lda #%11111011
	sta APU_PULSE1_FT

	lda #%11111001
	sta APU_PULSE1_CT

	pla
	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Plays a short pulse in the key of A (NTSC timing) with all possible volume
;; values (0-15)
.proc play_pulse_A_volume_ntsc

	; Duty (D), envelope loop / length counter halt (L), constant volume (C)
	DDLC = %00010000

	pha
	txa
	pha

	lda #0

	; add in the non-volume bits long enough to update the pulse register, then
	; remove them again so we can continue the loop
:	ora #DDLC
	sta APU_PULSE1_CONTROL
	and #$0f

	pha

	lda #%11111011
	sta APU_PULSE1_FT

	lda #%11111001
	sta APU_PULSE1_CT

	pla

	jsr delay_half_second_ntsc

	; Too bad there's no ina instruction, amiright? Other tutorials I've seen
	; suggest you do tax, inx, then txa, but this amounts to 6 clock cycles,
	; while the adc instruction only ammounts to 2.
	adc #$01

	cmp #%00010000
	bne :-

	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Plays the piano scales through Pulse 1 (NTSC timing)
;; TODO: hardcoding these values was just for the sake of making it work quickly.
;; I need to refactor this so that I loop through the offsets in
;; periodTableOffsetsAToG (defined in main.s) to produce notes A-G.
.proc play_pulse_scales_ntsc

	pha
	txa
	pha

	; Duty (D), envelope loop / length counter halt (L), constant volume (C), volume (v)
	DDLCVVVV = %00011111
	LLLLL = %11111000

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$00
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$02
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$04
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$05
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$07
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$09
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$0b
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	jsr delay_half_second_ntsc

	lda #DDLCVVVV
	sta APU_PULSE1_CONTROL

	ldx #$0c
	lda periodTableLo, X
	sta APU_PULSE1_FT

	lda periodTableHi, X
	ora #LLLLL
	sta APU_PULSE1_CT

	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Execute 256 x 256 (65536) NOP instructions at 2 clock cycles each, for a total
;; delay of 131072 clock cycles.
.proc delay_65knops

	; save previous values of A, X and Y so we can restore them later
	pha
	txa
	pha
	tya
	pha

	ldx #$ff

loop_x:

	ldy #$ff

loop_y:

	nop
	dey
	bne loop_y

	dex
	bne loop_x

	pla
	tay
	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc delay_half_second_ntsc

	pha
	txa
	pha

	ldx #$02

:	jsr delay_65knops
	dex
	bne :-

	pla
	tax
	pla

	rts

.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TODO: The multiplier of 4 (line 51) should give me something closer to a
;; half second, and the numbers I quote below are obviously wrong. I need to go
;; to the forums and figure out why my math is off.
;;
;; On an NTSC CPU (1.79MHz), this equals a delay of about 0.0732 seconds, while
;; on a PAL CPU (1.66MHz), this equals a delay of about 0.0790 seconds. There's
;; likely a more intelligent way to handle delays, but this simple function will
;; serve my sound test purposes.
.proc delay_one_second_ntsc

	pha
	txa
	pha

	ldx #$04

:	jsr delay_65knops
	dex
	bne :-

	pla
	tax
	pla

	rts

.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

