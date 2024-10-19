-- SDRAM controller 
-- Copyright Moseley Instruments (c) 2024
--
-- SDRAM in GW1RN9 FPGA is most likely a M12L64322A
--
-- notes: https://dnotq.io/sdram/sdram.html

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl is
    generic
    (
        g_bankwidth : integer := 2;
        g_addrwidth : integer := 12;
        g_datawidth : integer := 16
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
        sdram_ba    : out std_logic_vector(g_bankwidth-1 downto 0);
        sdram_dqm   : out std_logic_vector(1 downto 0);
        sdram_addr  : out std_logic_vector(g_addrwidth-1 downto 0);
        sdram_dq    : inout std_logic_vector(g_datawidth-1 downto 0);

        -- signals to system
        busy        : out std_logic;    -- when high the controller is busy, i.e. don't strobe wr_stb or refresh_stb
        lds_n       : in std_logic;     -- lower data byte enable, active low
        uds_n       : in std_logic;     -- uppper data byte enable, avtive low
        data_in     : in std_logic_vector(g_datawidth-1 downto 0);
        data_out    : out std_logic_vector(g_datawidth-1 downto 0);
        addr        : in std_logic_vector(g_addrwidth-1 downto 0);
        we_n        : in std_logic;     -- write enable, active low
        wr_stb      : in std_logic;     -- interface read/write strobe, active high
        refresh_stb : in std_logic      -- initiate a refresh cycle
    );
end entity sdram_ctrl;


architecture rtl of sdram_ctrl is

    type state_type is(init_power_up
    );

    signal state      : state_type := init_power_up;
    signal next_state : state_type;

begin

    sdram_clk <= not clk;
    sdram_cke <= '1';

    proc_clk: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                state <= init_power_up;
                sdram_dq(sdram_dq'range) <= (others => 'Z');
            else
                state <= next_state;
            end if;
        end if;
    end process proc_clk;

    proc_comb: process(state, wr_stb, refresh_stb, we_n)
    begin 
        -- SDRAM NOP condition as default
        sdram_dqm   <= "11";
        sdram_ba    <= "00";
        sdram_cas_n <= '1';
        sdram_ras_n <= '1';
        sdram_wen_n <= '1';
        sdram_cs_n  <= '1';
        sdram_addr  <= (others => '0');
        busy        <= '1';
    end process proc_comb;

end architecture rtl;
