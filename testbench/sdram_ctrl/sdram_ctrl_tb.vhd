-- Testbench for SDRAM controller
-- Copyright Moseley Instruments (c) 2024

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl_tb is
end entity;

architecture tb of sdram_ctrl_tb is
    signal do_sim  : std_logic := '1';
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '1';
    signal we_n    : std_logic := '1';
    signal rw      : std_logic := '0';

    signal sdram_data_in  : std_logic_vector(15 downto 0);
    signal sdram_data_out : std_logic_vector(15 downto 0);
    signal sdram_addr     : std_logic_vector(11 downto 0);
    signal addr           : std_logic_vector(21 downto 0);

    signal sdram_wen_n    : std_logic;
    signal sdram_cas_n    : std_logic;
    signal sdram_ras_n    : std_logic;
    signal sdram_cs_n     : std_logic;
    signal sdram_ba       : std_logic_vector(1 downto 0);
    signal sdram_dq       : std_logic_vector(15 downto 0);
    signal sdram_dqm      : std_logic_vector(1 downto 0);

    signal busy  : std_logic;
    --signal ready : std_logic;
begin

    sdram_data_in <= x"AA55";
    sdram_dq      <= (others => 'L');
    addr          <= "0000000000000000000001";

    -- simulation control process
    proc_sim: process
    begin
        wait for 2 us;
        reset_n <= '0';
        wait for 8 us;
        reset_n <= '1';

        -- wait until SDRAM init is complete
        wait until (busy = '0');

        wait for 10 ns;

        -- issue write
        we_n    <= '0'; -- strobe uart write
        rw      <= '1';
        wait for 10 ns;
        rw      <= '0';
        we_n    <= '1';
        
        wait until (busy = '0');
        wait for 20 ns;

        -- issue read
        rw      <= '1';
        wait for 10 ns;
        rw      <= '0';

        wait until (busy = '0');
        wait for 40 ns;

        do_sim <= '0';  -- end simulation
        wait;
    end process proc_sim;

    -- generate a 100 MHz clock for simulation
    proc_clk: process
    begin
        if (do_sim = '1') then
            wait for 5 ns;
            clk <= not clk;
        else
            wait;
        end if;
    end process proc_clk;

    u_dut: entity work.sdram_ctrl(rtl)
        port map
        (
            clk         => clk,
            reset_n     => reset_n,

            sdram_wen_n => sdram_wen_n,
            sdram_cas_n => sdram_cas_n,
            sdram_ras_n => sdram_ras_n,
            sdram_cs_n  => sdram_cs_n,
            sdram_ba    => sdram_ba,
            sdram_dqm   => sdram_dqm,
            sdram_dq    => sdram_dq,
            sdram_addr  => sdram_addr,

            lds_n       => '0',
            uds_n       => '0',
            data_in     => sdram_data_in,
            data_out    => sdram_data_out,
            addr        => addr,
            wr_n        => we_n,
            io_stb      => rw,
            refresh_stb => '0',
            busy        => busy
        );
    
end tb;
