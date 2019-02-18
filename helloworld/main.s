; A simple NES game that prints "Hello, World!" to the screen. I mostly followed
; along with this link:
; https://timcheeseman.com/nesdev/2016/01/18/hello-world-part-one.html
;
; Also, here's another really good article about Nintendo graphics, which was
; helpful for this and which I'll also definitely make more use of for other
; projects:
; http://www.dustmop.io/blog/2015/04/28/nes-graphics-part-1/

.include "defs.s"

.code

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

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Setup Palette Colors ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; Addressing the PPU occurs in two instructions: first, we store the most
	; significant byte in PPU_ADDR, then the least significant byte. In this
	; case, we're going to set the background palette.
	ldx #PALETTE_UNIVERSAL_BG_MSB
	stx PPU_ADDR
	ldx #PALETTE_UNIVERSAL_BG_LSB
	stx PPU_ADDR

	; Store the universal background color first.
	ldx #PALETTE_COLOR_BLACK
	stx PPU_DATA

	; Upon setting the universal background color, PPU_ADDR is automatically
	; incremented, so that our next stx instruction will store background
	; palette 0 to $3f01-$3f03.
	ldx #PALETTE_COLOR_WHITE
	stx PPU_DATA
	stx PPU_DATA
	stx PPU_DATA

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;; Print "Hello, World!" to the screen ;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; We're going to start printing text at the very beginning of the screen,
	; which for nametable 0, starts being addressed at $2000 (however, because of
	; overscan, we actually begin addressing at $2020, which skips past the first
	; 31 tiles in row 0 and begins on tile 32, or $20.) For an explanation of
	; nametables, see:
	; http://wiki.nesdev.com/w/index.php/PPU_nametables
	ldx #$20
	stx PPU_ADDR
	ldx #$20
	stx PPU_ADDR

	; Index through the hello world string and send the corresponding tiles to
	; the PPU.

	; I would LOVE to be able to do something like "lda (hellostr, X)", but this
	; won't work because indirect addressing only works for base addresses that
	; are one byte or less, and the address of hellostr is 2 bytes. So, instead,
	; I've decided to be a bit clever and store the memory location of hellostr
	; in the zero page, then increment that value (basically a pointer.)
	ldx #<hellostr ; LSB
	ldy #>hellostr ; MSB
	stx $00 ; addresses are little-endian and have the LSB at the front
	sty $01

	; The tiles in fonts.chr are layed out in such a way that their offsets are
	; equal to the numeric values of the ASCII characters. In a real project,
	; this convenience may or may not be practical.
	ldy #0

helloloop:

	lda ($00), Y
	cmp #0
	beq endhello
	sta PPU_DATA
	iny
	jmp helloloop

endhello:

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

; ROM Variables
hellostr: .byte "Hello, World!", $00 ; C-style null-terminated string

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

	; Include background tiles with ASCII characters
	; Adapted from this: https://github.com/cirla/nesdev/blob/hello_world/sprites.chr?raw=true
	.incbin "font.chr"

.segment "CHR0b"

