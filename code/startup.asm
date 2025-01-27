; GW68000 startup 
; echo the rx uart to the tx uart
.org $0000

    dl $00000200
    dl $00000008

    move.l  #1000, D0
start:
    subq    #1,D0
    cmp     #0,D0
    bne.s   start

print:
    move.l  #$01000000, A0   ; tx uart write and status address
    move.l  #$01000004, A1   ; rx uart read address
    lea     message, A2

again:
    ; wait for the tx UART to be ready
    move.b  (A0), D0         ; read uart status register
    and.b   #1, D0           ; mask TX empty bit
    tst.b   D0
    beq.s   again            ; jump if bit not set

    ; copy to tx uart
    move.b  (A2)+, D0        ; read string data
    cmp.b   #0, D0
    beq.s   wait
    move.b  D0, (A0)
    jmp     again
    
wait:
    jmp     wait

message:
    db "GW68000 Computer v1.0\n\r",0
