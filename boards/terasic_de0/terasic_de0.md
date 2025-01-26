# Terasic DE0 board

* https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=56&No=364&PartNo=2#heading

* FPGA 
* EPCS4 onboard serial EEPROM
* Cyclone III 3C16F484 FPGA 

# Clocks
* G21 / CLK$ connected to 50 MHz
* B12 / CLK9 connected to 50 MHz

# LEDS
* J1 LED0
* J2 LED1
* J3 LED2
* H1 LED3
* F2 LED4
* E1 LED5
* C1 LED6
* C2 LED7
* B2 LED8
* B1 LED9

# Switched
* J6 SW0
* H5 SW1
* H6 SW2
* G4 SW3
* G5 SW4
* J7 SW5
* H7 SW6
* E3 SW7
* E4 SW8
* D2 SW9

# LCD 
* F21 -> LCD BACKLIGHT ON
* D22 -> DATA0
* D21 -> DATA1
* C22 -> DATA2
* C21 -> DATA3
* B22 -> DATA4
* B21 -> DATA5
* D20 -> DATA6
* C20 -> DATA7
* E21 -> LCD ENABLE
* F22 -> LCD RS
* E22 -> LCD RW

# VGA
* H19, H17, H20, H21 -> R0 .. R3
* H22, J17, K17, J21 -> G0 .. G3
* K22, K21, J22, K18 -> B0 .. B3
* L22 -> VGA VS
* L21 -> VGA HS

# Serial
* U22 UART_RXD (input to FPGA)
* V22 UART_RTS (input to FPGA)
* U21 UART_TXD (output from FPGA)
* V21 UART_CTS (output from FPGA)

# PS/2
* P22 KBCLK
* R21 MSCLK
* R22 MSDAT
* P21 KBDAT

# 7 Segment digits
E11 Seven Segment Digit 0[0]
F11 Seven Segment Digit 0[1]
H12 Seven Segment Digit 0[2]
H13 Seven Segment Digit 0[3]
G12 Seven Segment Digit 0[4]
F12 Seven Segment Digit 0[5]
F13 Seven Segment Digit 0[6]
D13 Seven Segment Decimal Point 0

A13 Seven Segment Digit 1[0]
B13 Seven Segment Digit 1[1]
C13 Seven Segment Digit 1[2]
A14 Seven Segment Digit 1[3]
B14 Seven Segment Digit 1[4]
E14 Seven Segment Digit 1[5]
A15 Seven Segment Digit 1[6]
B15 Seven Segment Decimal Point 1

D15 Seven Segment Digit 2[0]
A16 Seven Segment Digit 2[1]
B16 Seven Segment Digit 2[2]
E15 Seven Segment Digit 2[3]
A17 Seven Segment Digit 2[4]
B17 Seven Segment Digit 2[5]
F14 Seven Segment Digit 2[6]
A18 Seven Segment Decimal Point 2

B18 Seven Segment Digit 3[0]
F15 Seven Segment Digit 3[1]
A19 Seven Segment Digit 3[2]
B19 Seven Segment Digit 3[3]
C19 Seven Segment Digit 3[4]
D19 Seven Segment Digit 3[5]
G15 Seven Segment Digit 3[6]
G16 Seven Segment Decimal Point 3

# SDCARD
* Y21 SDCLK
* Y22 SD CMD bidir
* AA22 DATA0 bidir
* W20 WD WriteProtect_n
* W21 DATA3 bidir

# SDRAM
* B5 DRAM_BA_0
* A4 DRAM_BA_1
* E7 DRAM_LQDM
* B8 DRAM_UDDM
* D6 DRAM_WE_N
* G8 DRAM_CAS_N
* F7 DRAM_RAS_N
* G7 DRAM_CS_N
* E5 DRAM_CLK
* E6 DRAM_CKE

* C4 SDRAM Address[0]
* A3 SDRAM Address[1]
* B3 SDRAM Address[2]
* C3 SDRAM Address[3]
* A5 SDRAM Address[4]
* C6 SDRAM Address[5]
* B6 SDRAM Address[6]
* A6 SDRAM Address[7]
* C7 SDRAM Address[8]
* B7 SDRAM Address[9]
* B4 SDRAM Address[10]
* A7 SDRAM Address[11]
* C8 SDRAM Address[13]

* D10 SDRAM Data[0]
* G10 SDRAM Data[1]
* H10 SDRAM Data[2]
* E9 SDRAM Data[3]
* F9 SDRAM Data[4]
* G9 SDRAM Data[5]
* H9 SDRAM Data[6]
* F8 SDRAM Data[7]
* A8 SDRAM Data[8]
* B9 SDRAM Data[9]
* A9 SDRAM Data[10]
* C10 SDRAM Data[11]
* B10 SDRAM Data[12]
* A10 SDRAM Data[13]
* E10 SDRAM Data[14]
* F10 SDRAM Data[15]

# FLASH
* Y2 FL_DQ15_AM1
* P4 FL_WE_N
* R1 FL_RST_N
* T3 FL_WP_N
* M7 FL_RY
* G8 FL_CE_N
* R6 FL_OE_N
* AA1 FL_BYTE_N

* P7 FLASH Address[0]
* P5 FLASH Address[1]
* P6 FLASH Address[2]
* N7 FLASH Address[3]
* N5 FLASH Address[4]
* N6 FLASH Address[5]
* M8 FLASH Address[6]
* M4 FLASH Address[7]
* P2 FLASH Address[8]
* N2 FLASH Address[9]
* N1 FLASH Address[10]
* M3 FLASH Address[11]
* M2 FLASH Address[12]
* M1 FLASH Address[13]
* L7 FLASH Address[14]
* L6 FLASH Address[15]
* AA2 FLASH Address[16]
* M5 FLASH Address[17]
* M6 FLASH Address[18]
* P1 FLASH Address[19]
* P3 FLASH Address[20]
* R2 FLASH Address[21]
* R7 FLASH Data[0]
* P8 FLASH Data[1]
* R8 FLASH Data[2]
* U1 FLASH Data[3]
* V2 FLASH Data[4]
* V3 FLASH Data[5]
* W1 FLASH Data[6]
* Y1 FLASH Data[7]
* T5 FLASH Data[8]
* T7 FLASH Data[9]
* T4 FLASH Data[10]
* U2 FLASH Data[11]
* V1 FLASH Data[12]
* V4 FLASH Data[13]
* W2 FLASH Data[14]
* Y2 FLASH Data[15]
