-- Top level SDRAM capture
-- Version          Description
--   0.1:           initial version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.SDRAM_controller;

entity tec0117_top is
    port
    (
        clk12M          : in std_logic;
        userbutton      : in std_logic;
        leds            : out std_logic_vector(7 downto 0);

        serial_out      : out std_logic;
        serial_in       : in std_logic;
        serial_cts_n    : in std_logic;

        -- sdram IO
        O_sdram_clk     : out std_logic;
        O_sdram_cs_n    : out std_logic;
        O_sdram_cke     : out std_logic;
        O_sdram_cas_n   : out std_logic;
        O_sdram_ras_n   : out std_logic;
        O_sdram_wen_n   : out std_logic;
        O_sdram_dqm     : out std_logic_vector(1 downto 0);
        O_sdram_ba      : out std_logic_vector(1 downto 0);
        IO_sdram_dq     : inout std_logic_vector(15 downto 0);
        O_sdram_addr    : out std_logic_vector(11 downto 0)
    );
end;

architecture rtl of tec0117_top is

    signal sdram_in_data    : std_logic_vector(15 downto 0);
    signal sdram_out_data   : std_logic_vector(15 downto 0);
    signal sdram_init_done  : std_logic;
    signal sdram_busy_n     : std_logic;
    signal sdram_rd_valid   : std_logic;
    signal sdram_wrd_ack    : std_logic;

    signal reset_n : std_logic;

    signal counter : unsigned(20 downto 0); -- event counter
    signal rw_stb  : std_logic;

    signal counter2: unsigned(7 downto 0);  -- memory data counter

    type state_t is (S_wait_for_init, S_idle, S_write, S_wait_wr_ack, S_wait, S_read, S_wait2);

    signal state : state_t := S_idle;

    signal wr_n : std_logic := '1';
    signal rd_n : std_logic := '1';

begin

    reset_n <= userbutton;

    serial_out <= '1';

    u_sdram: entity work.SDRAM_controller(beh)
        port map
        (
            O_sdram_clk     => O_sdram_clk,
            O_sdram_cke     => O_sdram_cke,
            O_sdram_cs_n    => O_sdram_cs_n,
            O_sdram_cas_n   => O_sdram_cas_n,
            O_sdram_ras_n   => O_sdram_ras_n,
            O_sdram_wen_n   => O_sdram_wen_n,
            O_sdram_dqm     => O_sdram_dqm,
            O_sdram_addr    => O_sdram_addr,
            O_sdram_ba      => O_sdram_ba,
            IO_sdram_dq     => IO_sdram_dq,
            I_sdrc_rst_n    => userbutton,
            I_sdrc_clk      => clk12M,
            I_sdram_clk     => not clk12M,
            I_sdrc_selfrefresh => '0',
            I_sdrc_power_down  => '0',
            I_sdrc_wr_n     => wr_n,
            I_sdrc_rd_n     => rd_n,
            I_sdrc_addr     => (others => '0'),
            I_sdrc_data_len => (others => '0'),     -- one word
            I_sdrc_dqm      => "00",
            I_sdrc_data     => sdram_in_data,
            O_sdrc_data     => sdram_out_data,
            O_sdrc_init_done => sdram_init_done,
            O_sdrc_busy_n   => sdram_busy_n,
            O_sdrc_rd_valid => sdram_rd_valid,
            O_sdrc_wrd_ack  => sdram_wrd_ack
        );

    proc_pulser: process(clk12M)
    begin
        if rising_edge(clk12M) then
            if (reset_n = '0') then
                counter <= (others => '0');
                rw_stb  <= '0';
            else
                rw_stb  <= '0';
                counter <= counter + 1;
                if (counter = 0) then
                    rw_stb <= '1';
                end if;                
            end if;
        end if;
    end process proc_pulser;

    proc_rw: process(clk12M)
    begin
        if rising_edge(clk12M) then

            if (reset_n = '0') then
                counter2 <= (others => '0');
                state <= S_wait_for_init;
            else
                case state is
                    when S_wait_for_init =>
                        if (sdram_init_done = '1') then
                            state <= S_idle;
                        end if;
                    when S_idle =>
                        if (rw_stb = '1') then
                            state <= S_write;
                        end if;
                    when S_write =>
                        sdram_in_data <= std_logic_vector(counter2 & counter2);
                        wr_n <= '0';
                        counter2 <= counter2 + 1;
                        state <= S_wait_wr_ack;
                    when S_wait_wr_ack =>
                        wr_n <= '1';
                        if (sdram_busy_n = '0') then
                            state <= S_wait;
                        end if;
                    when S_wait =>                        
                        if (sdram_busy_n = '1') then
                            rd_n <= '0';
                            state <= S_read;
                        end if;
                    when S_read =>      
                        rd_n <= '1';
                        if (sdram_rd_valid = '1') then
                            leds <= sdram_out_data(7 downto 0);
                            state <= S_wait2;
                        end if;
                    when S_wait2 =>
                        if (sdram_busy_n = '1') then
                            state <= S_idle;
                        end if;
                end case;
            end if;
        end if;
    end process proc_rw;

end rtl;
