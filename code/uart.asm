; write 0xAA to the UART continually
.org $0000

    dl $00000200
    dl $00000008

start:

print:
    eor D0, D0              ; zero D0
    move.l #$01000000, A0   ; uart write address
    lea  text, A1           ; address of string

again:
    ; wait for the UART to be ready
wait:
    move.l (A0), D1         ; read status
    cmp.b #1, D1
    bne.s wait

    move.b (A1)+, D0        ; load character in D0
    cmp.b #0, D0
    beq.s exit
    move.b D0, (A0)         ; write character to uart
    jmp again

exit:
    jmp print

text:
    db "Hello, world!",10,13,0
