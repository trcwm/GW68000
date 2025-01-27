-- SDRAM controller for Gowin GW1NR-9
-- Copyright Moseley Instruments (c) 2024, 2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl is
    port(
        clk             : in std_logic;
        reset_n         : in std_logic;
        clk_sdram_out   : out std_logic;

        sdram_wen_n : out std_logic;
        sdram_cas_n : out std_logic;
        sdram_ras_n : out std_logic;
        sdram_cs_n  : out std_logic;
        sdram_ba    : out std_logic_vector(1 downto 0);
        sdram_dqm   : out std_logic_vector(1 downto 0);
        sdram_dq    : inout std_logic_vector(15 downto 0);
        sdram_addr  : out std_logic_vector(11 downto 0);

        lds_n       : in std_logic;
        uds_n       : in std_logic;
        data_in     : in std_logic_vector(15 downto 0);
        data_out    : out std_logic_vector(15 downto 0);
        addr        : in std_logic_vector(21 downto 0);
        wr_n        : in std_logic;
        io_stb      : in std_logic;
        refresh_stb : in std_logic;
        busy        : out std_logic;
        dtack_n     : out std_logic
    );
end sdram_ctrl;

architecture rtl of sdram_ctrl is
    signal drive_dq_n     : std_logic := '1';
    signal data_from_ram  : std_logic_vector(data_out'RANGE);
    signal data_to_ram    : std_logic_vector(data_out'RANGE);

    -- gowin specific IOBUF
    component IOBUF
        port 
        (
            O   : out std_logic;
            IO  : inout std_logic;
            I   : in std_logic;
            OEN : in std_logic
        );
    end component;

    signal counter   : unsigned(3 downto 0);
    signal data_in_r : std_logic_vector(data_in'RANGE);
    signal dqm_r     : std_logic_vector(1 downto 0);
    alias  ba_addr   : std_logic_vector(1 downto 0)  is addr(21 downto 20);
    alias  row_addr  : std_logic_vector(11 downto 0) is addr(19 downto 8);
    alias  col_addr  : std_logic_vector(7 downto 0)  is addr(7 downto 0);

    type state_t is (S_init, 
        S_init_precharge, 
        S_init_precharge_wait, 
        S_init_refresh_wait,
        S_init_refresh2_wait,
        S_init_mode_wait,
        S_idle,
        S_read,
        S_read2,
        S_read3,
        S_read4,
        S_read5,
        S_write,
        S_write2,
        S_write3,
        S_write4,
        S_write5
        );

    signal state : state_t;

    signal cmd   : std_logic_vector(2 downto 0);    
    constant CMD_MODE     : std_logic_vector(2 downto 0) := "000";
    constant CMD_REFRESH  : std_logic_vector(2 downto 0) := "001";
    constant CMD_PRECHARGE: std_logic_vector(2 downto 0) := "010";
    constant CMD_ACTIVE   : std_logic_vector(2 downto 0) := "011";
    constant CMD_WRITE    : std_logic_vector(2 downto 0) := "100";
    constant CMD_READ     : std_logic_vector(2 downto 0) := "101";    
    constant CMD_NOP      : std_logic_vector(2 downto 0) := "111";
begin

    clk_sdram_out <= not clk;
    sdram_cs_n    <= '0';

    (sdram_ras_n, sdram_cas_n, sdram_wen_n) <= cmd;

    -- part specific IO buffers to enable
    -- a bi-directional bus
    --g_GENERATE_FOR: for i in 0 to 15 generate
        --u_entity: IOBUF
        --    port map
        --    (
        --        O   => data_from_ram(i),
        --        I   => data_to_ram(i),
        --        IO  => sdram_dq(i),
        --        OEN => drive_dq_n
        --    );

    --end generate g_GENERATE_FOR;
    
    proc_iobuffer: process(data_to_ram, drive_dq_n, sdram_dq)
    begin
        if (drive_dq_n = '1') then
            sdram_dq <= (others => 'Z');    -- tristate 
            data_from_ram <= sdram_dq;
        else
            sdram_dq <= data_to_ram;
            data_from_ram <= (others => '0');            
        end if;
    end process proc_iobuffer;

    proc_clk: process(clk)
    begin
        if (rising_edge(clk)) then
            -- defaults
            drive_dq_n  <= '1'; -- dq as input as default
            sdram_ba    <= "11";
            sdram_dqm   <= "00";
            sdram_addr  <= x"FFF";

            busy        <= '1';
            cmd         <= CMD_NOP;
            dtack_n     <= '1';

            if (reset_n = '0') then
                data_in_r <= (others => '0');
                counter   <= (others => '0');
                dqm_r     <= (others => '0');
                state     <= S_init;
            else
                counter <= counter + 1;

                case (state) is

                    -- --------------------------------
                    -- INIT SEQUENCE
                    -- --------------------------------

                    when S_init =>
                        if (counter = 1) then   -- two cycles nop
                            state   <= S_init_precharge;
                            counter <= (others => '0');
                        end if;
                    when S_init_precharge =>
                        cmd     <= CMD_PRECHARGE;
                        state   <= S_init_precharge_wait;
                        counter <= (others => '0');
                    when S_init_precharge_wait =>
                        if (counter = 2) then   -- two cycles nop
                            cmd     <= CMD_REFRESH;
                            state   <= S_init_refresh_wait;
                            counter <= (others => '0');
                        end if;
                    when S_init_refresh_wait =>
                        if (counter = 5) then   -- 5 cycles nop
                            cmd     <= CMD_REFRESH;
                            state   <= S_init_refresh2_wait;
                            counter <= (others => '0');
                        end if;
                    when S_init_refresh2_wait =>
                        if (counter = 5) then   -- 5 cycles nop
                            cmd        <= CMD_MODE;
                            sdram_addr <= x"030";  -- burstlen = 0, CAS latency = 3
                            state      <= S_init_mode_wait;
                            sdram_ba   <= "00";
                            counter    <= (others => '0');
                        end if;
                    when S_init_mode_wait =>
                        if (counter = 8) then   -- 8 cycles nop
                            state   <= S_idle;
                            counter <= (others => '0');
                        end if;

                    -- --------------------------------
                    -- IDLE
                    -- --------------------------------

                    when S_idle =>
                        busy <= '0';
                        if (io_stb = '1') then
                            data_in_r <= data_in;           -- latch data in
                            dqm_r     <= uds_n & lds_n;     -- and byte selects
                            busy      <= '1';
                            if (wr_n = '1') then
                                state <= S_read;
                            else
                                state <= S_write;
                            end if;
                            counter   <= (others => '0');
                        end if;

                    -- --------------------------------
                    -- READ SEQUENCE
                    -- --------------------------------
                    when S_read =>
                        sdram_addr <= row_addr;
                        sdram_ba   <= ba_addr;
                        sdram_dqm  <= dqm_r;
                        cmd        <= CMD_ACTIVE;
                        state      <= S_read2;
                    when S_read2 =>
                        -- single nop
                        sdram_dqm  <= dqm_r;
                        state      <= S_read3;
                    when S_read3 =>
                        sdram_addr <= "0000" & col_addr;
                        sdram_ba   <= ba_addr;
                        sdram_dqm  <= dqm_r;
                        cmd        <= CMD_READ;
                        state      <= S_read4;
                        counter    <= (others => '0');
                    when S_read4 =>
                        sdram_dqm  <= dqm_r;
                        cmd        <= CMD_PRECHARGE;    -- all banks
                        state      <= S_read5;
                        counter    <= (others => '0');
                    when S_read5 =>
                        sdram_dqm  <= dqm_r;
                        if (counter = 2) then           -- depends on CAS latency
                            data_out <= data_from_ram;
                            state    <= S_idle;
                            dtack_n  <= '0';
                        end if;
                    -- --------------------------------
                    -- WRITE SEQUENCE
                    -- --------------------------------
                    when S_write =>                        
                        sdram_addr <= row_addr;
                        sdram_ba   <= ba_addr;
                        sdram_dqm  <= dqm_r;
                        cmd        <= CMD_ACTIVE;
                        state      <= S_write2;
                    when S_write2 =>
                        -- single nop
                        sdram_dqm  <= dqm_r;
                        state      <= S_write3;
                    when S_write3 =>
                        sdram_addr <= "0000" & col_addr;
                        sdram_ba   <= ba_addr;
                        sdram_dqm  <= dqm_r;
                        data_to_ram <= data_in;
                        cmd        <= CMD_WRITE;                        
                        state      <= S_write4;
                        drive_dq_n <= '0';
                        counter    <= (others => '0');
                    when S_write4 =>
                        -- 2 nops
                        drive_dq_n <= '0';
                        sdram_dqm  <= dqm_r;
                        if (counter = 2) then
                            cmd     <= CMD_PRECHARGE;    -- all banks
                            state   <= S_write5;
                            counter <= (others => '0');
                        end if;
                    when S_write5 =>
                        -- 3 nops
                        sdram_dqm  <= dqm_r;
                        drive_dq_n <= '0';
                        if (counter = 3) then
                            state   <= S_idle;
                            dtack_n <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process proc_clk;

end architecture rtl;
