; test $213C values via indirect hdma
; assemble using asar
; loosely based on Vitor Vilela's sa1 speed test

LOROM

!freeram = $7FFF00
!count #= !freeram-2

org $8000
fillbyte $00 : fill $008000

org $ffb0
dw $0000
dd $0000
db $00,$00,$00,$00,$00,$00,$00
db $00
db $00
db $00
;   123456789012345678901
db "hdot test            "
db $30 ; lorom fastrom
db $00 ; no sram
db $05 ; rom 32KB
db $00 ; sram size

db $00
db $33
db $01

dw $0000
dw $ffff

dd $00000000
dw break
dw break
dw break
dw NMI
dw break
dw break
dd $00000000
dw break
dw break
dw break
dw break
dw Reset
dw break

org $008000
Reset:
    sei						;\ irq disabled
    clc						;|
    xce						;| disable 6506 emulation
    stz $4200				;|
    stz $420b				;|
    stz $420c				;|
    stz $2140				;|
    stz $2141				;|
    stz $2142				;|
    stz $2143				;| disable dma, h-dma, nmi, auto-joy, "spc700"
    rep #$38				;| disable decimal, a/x/y
    lda #$01ff				;|
    tcs						;| stack pointer = 1fff
    lda #$0000				;|
    tcd						;| zero direct page
    pha						;|
    plb						;|
    plb						;| program bank = 00
    sep #$30				;/

    lda #$00				;\ fastrom off
    sta $420d				;/

    lda #$80				;\ f-blank on
    sta $2100				;/

    lda #$80
    sta $2115
    stz $2116
    stz $2117

    ; init ppu
    stz $2101
    stz $2102
    stz $2103
    stz $2105 ; mode 0, 256x256 tilemap
    stz $2106

    lda #$40
    sta $2107 ; layer 1 = tilemap $8000, 256x256 tilemap
    lda #$44
    sta $2108

    stz $210b ; l1 character data = $0000

    ; setup palette
    ; color 0 = $0000
    ; color 1 = $7bde
    ; color 2 = $0000
    ; color 3 = $39ce

    ldy #$20
-	sty $2121
    stz $2122
    stz $2122
    lda #$de
    sta $2122
    lda #$7b
    sta $2122
    stz $2122
    stz $2122
    lda #$ce
    sta $2122
    lda #$39
    sta $2122

    cpy #$00
    beq +
    ldy #$00
    bra -
+

    lda #$20
    sta $2132 ; COLDATA

    lda #$40
    sta $2132

    lda #$8d
    sta $2132

    ; dma graphics
    rep #$20
    stz $2116
    lda #$1801
    sta $4300
    lda #Graphics
    sta $4302
    stz $4304
    lda #$1000
    sta $4305
    ldy #$01
    sty $420b

    ; dma tilemap
    lda #$4000
    sta $2116
    lda #$1809
    sta $4300
    lda #tilemap
    sta $4302
    lda #$1000
    sta $4305
    sty $420b

    sep #$20
    stz $212c ; TM
	stz $212e ; TMW
    lda #$01
    sta $212d ; TS
	stz $212f ; TSW

    lda #$02
    sta $2130
    lda #$20
    sta $2131 ; CGADSUB

    lda #$fd
    sta $210e ; BG1HOFS
    stz $210e
    stz $210d
    stz $210d

    ; write "V", 5A22 version, ppu1 version, ppu2 version
    lda #$38
    sta $2116
    lda #$43
    sta $2117

    lda #$55
    sta $2118
    stz $2119

    lda $4210
    and #$0F
    sta $2118
    stz $2119

    lda $213E
    and #$0F
    sta $2118
    stz $2119

    lda $213F
    and #$0F
    sta $2118
    stz $2119

    stz $212a
    stz $212b

    stz $2123
    stz $2125
    stz $2133

    lda #$80
    sta $4201

    lda $213F
    lda $2137
    lda $213C
    sta !freeram

    ;     da-ifttt
    lda #%11000000
    sta $4350
    sta $4360
    lda.b #$2137
    sta $4351
    lda.b #$213C
    sta $4361

    lda.b #indirect_table
    sta $4352
    sta $4362
    lda.b #indirect_table>>8
    sta $4353
    sta $4363
    lda.b #indirect_table>>16
    sta $4354
    sta $4364
    lda #!freeram>>16
    sta $4357
    sta $4367

    lda #$40
    sta !count
    sta !count+1

    lda #$0f
    sta $2100 ; INIDISP

    lda $4210
    lda #$80
    sta $4200
break:
    -
    bra -

NMI:
    ;sep #$30
    ;sta $2115
    rep #$30
    lda !count
    sta $2116
    clc
    adc #$0004
    cmp #$4200
    bcc +
    lda #$4000
+
    sta !count
    sep #$30
    lda !freeram
    and #$F0
    lsr #4
    sta $2118
    lda #$00
    sta $2119

    lda !freeram
    and #$0F
    sta $2118
    lda #$00
    sta $2119

    lda.b #(1<<5)|(1<<6)
    sta $420C
    lda $213F ; "Note: as a side effect of reading this register, the high/low byte selector for $213C/D is reset to 'low'."
    rti

Graphics:
    incbin gfx.bin

indirect_table:
    db 37
    dw !freeram
    ;db 1
    ;dw !freeram
    db 0
    db 0

tilemap:
    db $78
