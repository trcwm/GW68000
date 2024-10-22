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


architecture rtl of sdram_ctrl_cl2 is
    type state_type is (
        S_init,
        S_init_wait100us,
        S_init_precharge,
        S_init_tRP,
        S_init_refresh1,
        S_init_tRFC_1,
        S_init_refresh2,
        S_init_tRFC_2,
        S_init_mode,
        S_init_tMRD,
        S_idle,
        S_active,
        S_wait1,
        S_readwrite,
        S_cas_latency1,
        S_cas_latency2,
        S_precharge);

    signal state      : state_type := S_init;
    --signal next_state : state_type;
    ------------------------------------------------------------------
    --   BANK  |            ROW ADDRESS            |   COL ADDRESS   |
    -- BA1 BA0 |              12 bits              |      8 bits     |
    --  21  20 | 19 18 17 16 15 14 13 12 11 10 9 8 | 7 6 5 4 3 2 1 0 |
    ------------------------------------------------------------------

    signal addr_r       : std_logic_vector(addr'range);
    signal data_in_r    : std_logic_vector(data_in'range);
    signal dqm_r        : std_logic_vector(1 downto 0);
    signal wen_n_r      : std_logic;

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

    signal waitcounter      : unsigned(15 downto 0);    

    -- approximate PC133 SDRAM timings
    -- PRECHARGE command period         tRP         20 ns
    -- ACTIVE-to-ACTIVE command period  tRC         66 ns
    -- ACTIVE-to_PRECHARGE command      tRAS        44 ns
    -- AUTO REFRESH period              tRFC        66 ns
    -- LOAD MODE to ACTIVE or REFRESH   tMRD        26 clock cylces
    
    constant c_wait100us : unsigned(15 downto 0) := to_unsigned(10000, 16);     -- 100us at 100MHz
    constant c_tRP  : unsigned(15 downto 0) := to_unsigned(0, 16);
    constant c_tRFC : unsigned(15 downto 0) := to_unsigned(1, 16);
    constant c_tMRD : unsigned(15 downto 0) := to_unsigned(25, 16);

begin

    busy <= '0' when (state = S_idle) else '1';
    
    sdram_clk   <= clk;
    sdram_cke   <= '1';
    sdram_cs_n  <= '0';

    (sdram_ras_n, sdram_cas_n, sdram_wen_n) <= cmd;

    proc_clk: process(clk)
    begin
        if (rising_edge(clk)) then
            -- defauls
            sdram_dqm  <= "11";
            sdram_dq   <= (others => 'Z');
            sdram_ba   <= (others => '0');
            sdram_addr <= (others => '0');

            if (reset_n = '0') then
                --sdram_cs_n  <= '1';
                state       <= S_init;
                cmd         <= CMD_NOP;
                waitcounter <= (others =>'0');
            else 
                waitcounter <= waitcounter + 1;

                case state is
                    when S_init =>
                        cmd         <= CMD_NOP;
                        state       <= S_init_wait100us;
                        waitcounter <= (others => '0');
                    when S_init_wait100us =>
                        cmd <= CMD_NOP;
                        if (waitcounter = c_wait100us) then
                            state <= S_init_refresh1;
                        end if;
                    when S_init_precharge =>
                        cmd         <= CMD_PRECHARGE;
                        sdram_addr(10) <= '1';  -- all banks precharge
                        state       <= S_init_tRP;
                        waitcounter <= (others => '0');
                    when S_init_tRP =>
                        cmd <= CMD_NOP;
                        if (waitcounter <= c_tRP) then
                            state <= S_init_refresh1;
                        end if;
                    when S_init_refresh1 =>
                        cmd         <= CMD_REFRESH;
                        state       <= S_init_tRFC_1;
                        waitcounter <= (others => '0');
                    when S_init_tRFC_1 =>
                        cmd <= CMD_NOP;
                        if (waitcounter = c_tRFC) then
                            state <= S_init_refresh2;
                        end if;
                    when S_init_refresh2 =>
                        cmd        <= CMD_REFRESH;
                        state      <= S_init_tRFC_2;
                        waitcounter <= (others => '0');
                    when S_init_tRFC_2 =>
                        cmd <= CMD_NOP;
                        if (waitcounter = c_tRFC) then
                            state <= S_init_mode;
                        end if;
                    when S_init_mode =>
                        cmd        <= CMD_MODE;
                        sdram_addr <= "000000100000";   -- burst length = 1, sequential, CL=2
                        state      <= S_init_tMRD;
                        waitcounter <= (others => '0');
                    when S_init_tMRD =>
                        cmd <= CMD_NOP;
                        if (waitcounter = c_tMRD) then
                            state <= S_idle;
                        end if;
                    when S_idle =>
                        sdram_dqm  <= "11";
                        cmd        <= CMD_NOP;
                        if (rw_stb = '1') then                        
                            addr_r     <= addr;
                            data_in_r  <= data_in;
                            wen_n_r    <= wen_n;
                            dqm_r      <= (not uds_n) & (not lds_n);
                            state      <= S_active;
                        end if;
                    when S_active =>
                        cmd        <= CMD_ACTIVE;
                        state      <= S_wait1;
                        sdram_addr <= row_addr;
                        sdram_ba   <= ba_addr;
                    when S_wait1 =>
                        cmd        <= CMD_NOP;
                        state      <= S_readwrite;
                        sdram_addr <= (others => '0');
                        sdram_ba   <= ba_addr;
                    when S_readwrite =>
                        if (wen_n_r = '1') then
                            cmd      <= CMD_READ;
                        else
                            cmd      <= CMD_WRITE;
                            sdram_dq <= data_in_r;
                        end if;
                        state      <= S_cas_latency1;
                        sdram_ba   <= ba_addr;
                        sdram_addr <= "0000" & col_addr; -- no auto precharge
                        sdram_ba   <= ba_addr;
                        sdram_dqm  <= dqm_r;
                    when S_cas_latency1 =>
                        cmd        <= CMD_NOP;
                        state      <= S_cas_latency2;
                        sdram_dqm  <= dqm_r;
                    when S_cas_latency2 =>
                        cmd        <= CMD_NOP;
                        state      <= S_precharge;
                        sdram_dqm  <= dqm_r;                        
                        if (wen_n_r = '1') then
                            data_out <= sdram_dq;
                        end if;
                    when S_precharge =>
                        --if (wen_n_r = '1') then
                        --    data_out <= sdram_dq;
                        --end if;
                        cmd        <= CMD_PRECHARGE;
                        state      <= S_idle;
                        sdram_addr(10) <= '1';  -- all banks precharge
                end case;
            end if; -- reset
        end if; -- rising edge
    end process proc_clk;

end rtl;

