#!/usr/bin/python3

import serial

class DecodeFSM:

    state = 0
    cnt   = 0
    byte1 = 0
    byte2 = 0
    byte3 = 0
    byte4 = 0

    cmd_txt = ["MODE   ", "REFRESH", "PRECHRG", "ACTIVE ", "WRITE  ", "READ   ", "BUSTERM", "NOP    "]

    def __init__(self):
        self.state = 0

    def process(self, v : int):
        #print(self.state)

        if (self.state == 0):
            if (v == 0xAA):
                self.state = 1
        elif (self.state == 1):
            if (v == 0x55):
                self.state = 2
            elif (v == 0xAA):
                self.state = 1
            else: 
                self.state = 0
        elif (self.state == 2):
            self.cnt = v
            self.state = 3            
        elif (self.state == 3):
            self.byte1 = v
            self.state = 4
        elif (self.state == 4):
            self.byte2 = v
            self.state = 5
        elif (self.state == 5):
            self.byte3 = v
            self.state = 6
        elif (self.state == 6):
            self.byte4 = v
            self.state = 0

    # byte1 <= sdram_init_done & 
    #     O_sdram_dqm    &
    #     O_sdram_cs_n   &
    #     O_sdram_cs_n   &
    #     O_sdram_ras_n  &
    #     O_sdram_cas_n  &
    #     O_sdram_wen_n;
    # byte4 = sdram_busy_n & sdram_rd_valid & sdram_wrd_ack;

            addr = int(self.byte2) | ((int(self.byte3) & 0x0F) << 8)
            ba   = self.byte3 >> 6
            cmd  = int(self.byte1) & 0x07
            dqm  = (int(self.byte1) >> 5) & 0x03
            dqdrive = (self.byte1 >> 4) & 1
            
            wr_n     = (self.byte4 >> 4) & 1
            rd_n     = (self.byte4 >> 3) & 1
            busy_n   = (self.byte4 >> 2) & 1
            rd_valid = (self.byte4 >> 1) & 1
            wrd_ack  = self.byte4 & 1

            print(f"{self.cnt:03d}   {self.byte1:02X} {self.byte2:02X} {self.byte3:02X} addr={addr:03X} cmd={self.cmd_txt[cmd]} {dqm=} {ba=} {dqdrive=} {busy_n=} {rd_valid=} {wrd_ack=} {rd_n=} {wr_n=}")

            if (cmd == 0):
                # mode register
                burst_length = addr & 0x7
                cas_latency  = (addr >> 4) & 0x07
                print(f"  MODE: burst length={burst_length}  cas latency={cas_latency}")

gowinserial = serial.Serial(
    port = '/dev/ttyUSB1',
    baudrate = 115200,
    parity = serial.PARITY_NONE,
    stopbits = serial.STOPBITS_ONE,
    bytesize = serial.EIGHTBITS,
    timeout = 1
)

rcvd = []
while True:
    c = gowinserial.read()
    if len(c) == 0:
        break
    rcvd += c

    for ch in c:
        print(f"{ch:02X}")
        
print(f"Received {len(rcvd)} bytes")

# decode 
decoder = DecodeFSM()
for b in rcvd:
    decoder.process(b)

gowinserial.close()
