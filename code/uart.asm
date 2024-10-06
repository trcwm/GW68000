; write 0xAA to the UART continually
.org $0000

    dl $00000200
    dl $00000008

start:
    move.l #$01000000, A0   ; uart write address
    move.b #65, (A0)        ; write ASCII 'A' to uart tx data register
    jmp start
    
