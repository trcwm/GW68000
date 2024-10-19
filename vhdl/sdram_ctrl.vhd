-- SDRAM controller 
-- Copyright Moseley Instruments (c) 2024
--
-- For embedded 64Mbit SDRAM in GW1RN9 FPGA.
-- With 16 bit databus and four banks, each bank is 1 megaword
--
-- A similar part is AS4C4M16SA.
--
-- notes: https://dnotq.io/sdram/sdram.html
--
-- The GOWIN tools require the following signal names
-- to the SDRAM:
-- 
-- IO_PORT "O_sdram_clk"    IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_cke"    IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_cas_n"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_ras_n"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_wen_n"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_dqm[0]" IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_dqm[1]" IO_TYPE=LVTTL33
-- 
-- IO_PORT "O_sdram_ba[0]" IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_ba[1]" IO_TYPE=LVTTL33
-- 
-- IO_PORT "IO_sdram_dq[0]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[1]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[2]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[3]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[4]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[5]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[6]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[7]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[8]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[9]"  IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[10]" IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[11]" IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[12]" IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[13]" IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[14]" IO_TYPE=LVTTL33
-- IO_PORT "IO_sdram_dq[15]" IO_TYPE=LVTTL33
-- 
-- IO_PORT "O_sdram_addr[0]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[1]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[2]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[3]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[4]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[5]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[6]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[7]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[8]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[9]"  IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[10]" IO_TYPE=LVTTL33
-- IO_PORT "O_sdram_addr[11]" IO_TYPE=LVTTL33

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl is
    generic
    (
        g_clkfreq       : real    := 100.0e6;   -- 100 MHz
        g_caslatency    : integer := 3          -- latency in clock cycles
    );
    port
    (
        -- clock and reset
        clk         : in std_logic;
        reset_n     : in std_logic;
        
        -- signals to SDRAM
        sdram_clk   : out std_logic;
        sdram_cke   : out std_logic;
        sdram_cs_n  : out std_logic;
        sdram_wen_n : out std_logic;
        sdram_cas_n : out std_logic;
        sdram_ras_n : out std_logic;
        sdram_ba    : out std_logic_vector(1 downto 0);
        sdram_dqm   : out std_logic_vector(1 downto 0);
        sdram_addr  : out std_logic_vector(11 downto 0);
        sdram_dq    : inout std_logic_vector(15 downto 0);

        -- signals to system
        busy        : out std_logic;    -- when high the controller is busy, i.e. don't strobe wr_stb or refresh_stb
        lds_n       : in std_logic;     -- lower data byte enable, active low
        uds_n       : in std_logic;     -- uppper data byte enable, avtive low
        data_in     : in std_logic_vector(15 downto 0);
        data_out    : out std_logic_vector(15 downto 0);
        addr        : in std_logic_vector(21 downto 0);
        we_n        : in std_logic;     -- write enable, active low
        wr_stb      : in std_logic;     -- interface read/write strobe, active high
        refresh_stb : in std_logic;     -- initiate a refresh cycle
        done        : out std_logic     -- done is high when operation is complete
    );
end entity sdram_ctrl;

-- A0-A7 are used for the column address (A10 defines Auto Precharge)
-- A0-A11 are are used fo the row address
-- Address bits:
-- 
-- BA1 | BA0 | ROW (A11-A0) | COL (A7-A0) |
--  1     1         12            8
--
-- so the supported address width is 2+12+8 = 22 bits
-- which is equivalent to 8 MByte of SDRAM
--
--
-- Startup sequence:
--   -- wait at least 200us with DQM = "11", and a NOP command
--
--
--

architecture rtl of sdram_ctrl is

    type state_type is(
        S_init_power_up,
        S_init_wait,
        S_init_precharge,
        S_idle,
        S_activate,
        S_rcd,
        S_rw,
        S_ras1,
        S_ras2,
        S_precharge,
        s_refresh
    );

    signal state      : state_type := S_init_power_up;
    signal next_state : state_type;

    -- a 16 bit timer at 100 MHz can delay a max of
    -- 0.6 milliseconds.
    signal timer            : unsigned(15 downto 0);
    signal timer_reset      : std_logic;
    constant c_tim_200us    : integer := integer(g_clkfreq * 10.0e-6);

    -- SDRAM command bits:
    -- RAS_n, CAS_n, WE_n
    subtype cmd_type is std_logic_vector(2 downto 0);
    constant CMD_ACTIVE    : cmd_type := "011"; -- activate bank
    constant CMD_PRECHARGE : cmd_type := "010"; -- precharge bank
    constant CMD_WRITE     : cmd_type := "100"; -- with auto precharge
    constant CMD_READ      : cmd_type := "101"; -- with auto precharge
    constant CMD_MODE      : cmd_type := "000";
    constant CMD_NOP       : cmd_type := "111";
    constant CMD_REFRESH   : cmd_type := "001"; -- auto refresh

    signal cmd : cmd_type := CMD_NOP;

    -- SDRAM bank, row and column aliases from incoming address
    alias addr_ba  : std_logic_vector(1 downto 0) is addr(21 downto 20);
    alias addr_row : std_logic_vector(11 downto 0) is addr(19 downto 8);
    alias addr_col : std_logic_vector(7 downto 0) is addr(7 downto 0);

begin

    sdram_clk <= not clk;
    sdram_cke <= '1';

    (sdram_ras_n, sdram_cas_n, sdram_wen_n) <= cmd;

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= S_init_power_up;
                sdram_dq(sdram_dq'range) <= (others => 'Z');
                timer <= (others => '0');
            else
                state <= next_state;
                if (timer_reset = '1') then
                    timer <= (others => '0');
                else
                    timer <= timer + 1;
                end if;
            end if;
        end if;
    end process proc_clk;

    proc_comb: process(state, wr_stb, refresh_stb, we_n, timer)
    begin 
        -- SDRAM NOP condition as default
        sdram_dqm   <= "11";
        sdram_ba    <= "00";
        sdram_cs_n  <= '1';
        sdram_addr  <= "0000" & addr_col;
        busy        <= '1';
        done        <= '0';

        timer_reset <= '0';
        next_state  <= state;   -- default: stay in current state

        case state is
            when S_init_power_up =>
                cmd <= CMD_NOP;
                timer_reset <= '1';
                next_state <= S_init_wait;
            when S_init_wait =>
                -- wait for chip to come online
                cmd <= CMD_NOP;
                if (timer = c_tim_200us) then
                    next_state <= S_init_precharge;
                    timer_reset <= '1';
                end if;
            when S_init_precharge =>
                cmd <= CMD_PRECHARGE;
                -- 8 cycles of precharge
                sdram_ba <= "00";
                sdram_addr(10) <= '1';  -- precharge all banks
                if (timer = 8) then
                    next_state <= S_idle;
                end if;
            when S_idle =>
                cmd <= CMD_NOP;
                if (refresh_stb = '1') then
                    cmd <= CMD_REFRESH;
                    timer_reset <= '1';
                    next_state <= S_refresh;
                elsif (wr_stb = '1') then
                    next_state <= S_activate;
                end if;
            when S_activate =>
                cmd <= CMD_ACTIVE;
                sdram_addr <= addr_row;
                sdram_ba   <= addr(21 downto 20);
                next_state <= S_rcd;
            when S_rcd =>
                -- one cylce delay to satisfy Trcd
                -- unknown what the timing specs are 
                -- for the embedded SDRAM
                if (we_n = '0') then
                    cmd <= CMD_WRITE;
                    sdram_wen_n  <= '0';
                    sdram_dqm(1) <= uds_n;
                    sdram_dqm(0) <= lds_n;
                else 
                    cmd <= CMD_READ;
                end if;
                next_state <= S_rw;
            when S_rw =>
                next_state <= S_ras1;
            when S_ras1 =>
                next_state <= S_ras2;
            when S_ras2 =>
                cmd <= CMD_PRECHARGE;
                next_state <= S_precharge;
            when S_precharge =>
                next_state <= S_idle;
                done <= '1';
            when S_refresh =>
                cmd <= CMD_REFRESH;
                if (timer = 7) then
                    next_state <= S_idle;
                    done <= '1';
                end if;
        end case;

    end process proc_comb;

end architecture rtl;
