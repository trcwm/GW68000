-- simple SDRAM controller
-- N.A. Moseley, Moseley Instruments
-- Copyright 2024
--
-- 64Mbit, 4 banks, CAS latency 2
-- https://github.com/Colin-Suckow/fpga_vga_display/blob/master/sdram.v

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl_cl2 is
    port
    (
        clk             : in std_logic;     --- 100 MHz clock
        reset_n         : in std_logic;
        
        -- signals to the SDRAM
        sdram_clk       : out std_logic;
        sdram_cke       : out std_logic;
        sdram_cs_n      : out std_logic;
        sdram_wen_n     : out std_logic;
        sdram_cas_n     : out std_logic;
        sdram_ras_n     : out std_logic;
        sdram_ba        : out std_logic_vector(1 downto 0);
        sdram_dqm       : out std_logic_vector(1 downto 0);
        sdram_addr      : out std_logic_vector(11 downto 0);
        sdram_dq        : inout std_logic_vector(15 downto 0);

        busy            : out std_logic;

        addr            : in std_logic_vector(21 downto 0);
        rw_stb          : in std_logic;
        refresh_stb     : in std_logic;
        wen_n           : in std_logic;        
        uds_n           : in std_logic;
        lds_n           : in std_logic;
        data_in         : in std_logic_vector(15 downto 0);
        data_out        : out std_logic_vector(15 downto 0)
    );
end sdram_ctrl_cl2;


architecture rtl of sdram_ctrl_Cl2 is
    type state_type is (init_power_up, 
        init_precharge, init_precharge_nop,
        init_refresh, init_refresh_nop, 
        init_refresh2, init_refresh_nop2, 
        init_set_mode, init_delay,
        sd_read, 
        sd_read2,
        sd_read3,
        sd_read4,
        sd_read5,
        sd_read6,
        sd_write, 
        sd_write2,
        sd_write3,
        sd_write4,
        idle);

    signal state      : state_type := init_power_up;
    signal next_state : state_type;

    --type cmd_type is (cmd_nop, cmd_precharge_all);
    --signal cmd : cmd_type := cmd_nop;

    signal wait_counter : unsigned(15 downto 0) := (others => '0');

    signal rd_data : std_logic;
    signal wr_data : std_logic;

    ------------------------------------------------------------------
    --   BANK  |            ROW ADDRESS            |   COL ADDRESS   |
    -- BA1 BA0 |              12 bits              |      8 bits     |
    --  21  20 | 19 18 17 16 15 14 13 12 11 10 9 8 | 7 6 5 4 3 2 1 0 |
    ------------------------------------------------------------------

    signal addr_r       : std_logic_vector(addr'range);
    signal data_in_r    : std_logic_vector(data_in'range);
    signal dqm_r        : std_logic_vector(1 downto 0);

    alias  row_addr     : std_logic_vector(11 downto 0) is addr_r(19 downto 8);
    alias  col_addr     : std_logic_vector(7 downto 0) is addr_r(7 downto 0);
    alias  ba_addr      : std_logic_vector(1 downto 0) is addr_r(21 downto 20);

    signal cmd              : std_logic_vector(2 downto 0);
    constant CMD_NOP        : std_logic_vector(2 downto 0) := "111";
    constant CMD_PRECHARGE  : std_logic_vector(2 downto 0) := "010";
    constant CMD_ACTIVE     : std_logic_vector(2 downto 0) := "011";
    constant CMD_MODE       : std_logic_vector(2 downto 0) := "000";
    constant CMD_READ       : std_logic_vector(2 downto 0) := "101";
    constant CMD_WRITE      : std_logic_vector(2 downto 0) := "100";
    constant CMD_REFRESH    : std_logic_vector(2 downto 0) := "001";

begin
    
    sdram_clk <= not clk;
    sdram_cke <= '1';
    (sdram_ras_n, sdram_cas_n, sdram_wen_n) <= cmd;

    proc_clk: process(clk)
    begin
        -- defaults
        if (rising_edge(clk)) then
            if (reset_n = '0') then
                state <= init_power_up;
                sdram_dq(data_out'range) <= (others => 'Z');
                wait_counter <= (others => '0');
            else
                if (state /= next_state) then
                    wait_counter <= (others => '0');
                else 
                    wait_counter <= wait_counter + 1;
                end if;

                if (rd_data = '1') then
                    data_out <= sdram_dq(data_out'range);
                elsif (wr_data = '1') then
                    sdram_dq(data_out'range) <= data_in;
                else
                    sdram_dq(data_out'range) <= (others => 'Z');
                end if;

                if (rw_stb = '1') and (state = idle) then
                    dqm_r  <= (not uds_n) & (not lds_n);
                    addr_r <= addr;
                end if;

                state <= next_state;
            end if;
        end if;
    end process proc_clk;

    proc_comb: process(state, wait_counter, 
        rw_stb, refresh_stb, 
        wen_n,
        data_in,
        addr_r,
        dqm_r)
    begin
        -- nop condition
        sdram_dqm   <= "11";
        sdram_ba    <= "00";        
        cmd         <= CMD_NOP;
        sdram_cs_n  <= '1';
        rd_data     <= '0';
        wr_data     <= '0';
        sdram_addr  <= (others => '0');
        busy        <= '1';
        case state is
            when init_power_up => -- wait for power up
                next_state <= init_power_up;
                if wait_counter = 20000 then    -- 200us delay at 100 MHz clock
                    next_state <= init_precharge;
                end if;
            when init_precharge => -- issue pre-charge
                sdram_cs_n     <= '0';
                sdram_addr(10) <= '1';
                cmd            <= CMD_PRECHARGE;
                next_state <= init_precharge_nop;
            when init_precharge_nop =>
                cmd        <= CMD_NOP;
                next_state <= init_precharge_nop;
                if wait_counter = 200 then     -- 8us delay
                    next_state <= init_refresh;
                end if;
            when init_refresh => -- issue refresh
                cmd        <= CMD_REFRESH;
                sdram_cs_n <= '0';
                next_state <= init_refresh_nop; 
            when init_refresh_nop =>
                cmd        <= CMD_NOP;
                next_state <= init_refresh_nop;
                if wait_counter = 100 then    -- 8us delay
                    next_state <= init_refresh2;
                end if;
            when init_refresh2 => -- issue refresh 2
                cmd        <= CMD_REFRESH;
                sdram_cs_n <= '0';
                next_state <= init_refresh_nop2; 
            when init_refresh_nop2 =>
                cmd        <= CMD_NOP;
                next_state <= init_refresh_nop2;
                if wait_counter = 100 then    -- 8us delay
                    next_state <= init_set_mode;
                end if;
            when init_set_mode =>
                sdram_cs_n     <= '0';
                cmd            <= CMD_MODE;
                sdram_ba       <= "00";
                sdram_addr(10) <= '0';
                sdram_addr(2 downto 0) <= "000";    -- read burst length = 1
                sdram_addr(3)  <= '0';              -- sequential counting
                sdram_addr(6 downto 4) <= "010";    -- CAS latency 2
                sdram_addr(8 downto 7) <= "00";     -- operating mode: reserved
                sdram_addr(9) <= '1';               -- write burst length = 1
                next_state <= init_delay;
            when init_delay =>
                cmd         <= CMD_NOP;
                next_state <= init_delay;
                if wait_counter = 3 then            -- 3 clock delay (or is it 4 .. :) ) 
                    next_state <= idle;
                end if;
            when idle => -- idle
                cmd  <= CMD_NOP;
                busy <= '0';
                next_state <= idle;
                if (rw_stb = '1') then
                    if (wen_n = '0') then
                        data_in_r  <= data_in;
                        next_state <= sd_write;
                    else
                        next_state <= sd_read;
                    end if;
                end if;
            when sd_read =>
                -- emit row address and activate bank
                sdram_addr   <= row_addr;
                sdram_ba     <= ba_addr;
                CMD          <= CMD_ACTIVE;
                sdram_cs_n   <= '0';
                next_state   <= sd_read2;
            when sd_read2 =>
                cmd        <= CMD_NOP;
                next_state <= sd_read2;
                if wait_counter = 1 then
                    next_state <= sd_read3;
                end if;
            when sd_read3 =>
                -- emit column address and bank
                -- with auto precharge
                next_state   <= sd_read4;
                sdram_addr   <= "0010" & col_addr;  -- with auto-precharge
                sdram_ba     <= ba_addr;
                cmd          <= CMD_READ;
                sdram_cs_n   <= '0';
                sdram_dqm    <= dqm_r;
            when sd_read4 =>
                cmd         <= CMD_NOP;
                next_state  <= sd_read5;
                sdram_dqm   <= dqm_r;
                rd_data     <= '1';
            when sd_read5 =>
                cmd         <= CMD_NOP;
                next_state  <= sd_read6;
                sdram_dqm   <= dqm_r;
            when sd_read6 =>
                -- delay
                next_state   <= sd_read6;
                if wait_counter = 3 then
                    next_state <= idle;
                end if;
                sdram_dqm   <= dqm_r;
            when sd_write =>
                -- emit row address
                sdram_addr   <= row_addr;
                sdram_ba     <= ba_addr;
                CMD          <= CMD_ACTIVE;
                sdram_cs_n   <= '0';
                next_state <= sd_write2;
            when sd_write2 =>
                next_state   <= sd_write2;
                if wait_counter = 1 then
                    wr_data  <= '1';
                    next_state <= sd_write3;
                end if;
            when sd_write3 =>
                -- emit column address and bank
                -- with auto precharge
                next_state   <= sd_write4;
                sdram_addr   <= "0010" & col_addr;
                cmd          <= CMD_WRITE;
                sdram_cs_n   <= '0';
                sdram_dqm    <= dqm_r;
            when sd_write4 =>
                -- delay
                next_state   <= sd_write4;
                if wait_counter = 4 then
                    next_state <= idle;
                end if;
        end case;
    end process proc_comb;

end rtl;

