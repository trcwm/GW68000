; echo the rx uart to the tx uart
.org $0000

    dl $00000200
    dl $00000008

start:

print:
    move.l #$01000000, A0   ; tx uart write and status address
    move.l #$01000004, A1   ; rx uart read address
again:
    ; wait for the rx UART to be ready
    move.l (A0), D0         ; read uart status register
    and.l  #2, D0           ; mask RX full bit
    beq.s  again            ; jump if bit not set

    ; read the rx uart
    move.l (A1), D0

    ; copy to tx uart
    move.l D0, (A0)
    jmp    again
