-- stupidly simple SDRAM model
-- burst length = 1
-- cas latency  = 2
--
-- Copyright (c) Moseley Instruments 2024

library ieee;
use ieee.std_logic_1164.all;

entity sdram is
    generic
    (
        g_cas_latency : integer := 2
    );
    port
    (
        clk     : in std_logic;
        cke     : in std_logic;
        cs_n    : in std_logic;
        ras_n   : in std_logic;
        cas_n   : in std_logic;
        we_n    : in std_logic;
        
        addr    : in std_logic_vector(11 downto 0);
        ba      : in std_logic_vector(1 downto 0);
        dq      : inout std_logic_vector(15 downto 0);
        dqm     : in std_logic_vector(1 downto 0)
    );
end entity sdram;

architecture behavioral of sdram is
    signal active_enb       : std_logic;
    signal precharge_enb    : std_logic;
    signal read_enb         : std_logic;
    signal write_enb        : std_logic;

    type cmd_t is (CMD_ACT, CMD_NOP, CMD_READ, CMD_WRITE, CMD_PRECHARGE);
    type command_t is array (0 to 3) of cmd_t; 
    signal command : command_t;

    type col_addr_t is array(0 to 3) of std_logic_vector(addr'range);
    signal col_addr : col_addr_t;

    type bank_addr_t is array(0 to 3) of std_logic_vector(ba'range);
    signal bank_addr : bank_addr_t;

    signal dqm_r0  : std_logic_vector(dqm'range);
    signal dqm_r1  : std_logic_vector(dqm'range);

    signal b0_row_addr : std_logic_vector(11 downto 0);
    signal b1_row_addr : std_logic_vector(11 downto 0);
    signal b2_row_addr : std_logic_vector(11 downto 0);
    signal b3_row_addr : std_logic_vector(11 downto 0);

    signal b0_act : std_logic;  -- bank active flag
    signal b1_act : std_logic;
    signal b2_act : std_logic;
    signal b3_act : std_logic;
    signal b0_pch : std_logic;  -- bank precharge flag
    signal b1_pch : std_logic;
    signal b2_pch : std_logic;
    signal b3_pch : std_logic;

    signal ram_contents : std_logic_vector(dq'range);
begin

    active_enb      <= (not cs_n) and (not ras_n) and cas_n and we_n;
    precharge_enb   <= (not cs_n) and (not ras_n) and cas_n and (not we_n);
    read_enb        <= (not cs_n) and ras_n and (not cas_n) and we_n;
    write_enb       <= (not cs_n) and ras_n and (not cas_n) and (not we_n);

    proc_clk: process(clk)
        variable precharge_all : std_logic;
        variable current_cmd   : cmd_t;
    begin
        if (rising_edge(clk)) then
            current_cmd := command(1);
            command(0)  <= command(1);
            command(1)  <= command(2);
            command(2)  <= command(3);
            command(3)  <= CMD_NOP;

            col_addr(0) <= col_addr(1);
            col_addr(1) <= col_addr(2);
            col_addr(2) <= col_addr(3);
            col_addr(3) <= (others => '0');

            bank_addr(0) <= bank_addr(1);
            bank_addr(1) <= bank_addr(2);
            bank_addr(2) <= bank_addr(3);
            bank_addr(3) <= "00";

            dqm_r0 <= dqm_r1;
            dqm_r1 <= dqm;

            -- activate bank
            if (active_enb = '1') then
                case ba is
                    when "00" =>
                        b0_act      <= '1';
                        b0_pch      <= '0';
                        b0_row_addr <= addr;
                    when "01" =>
                        b1_act      <= '1';
                        b1_pch      <= '0';
                        b1_row_addr <= addr;
                    when "10" =>
                        b2_act      <= '1';
                        b2_pch      <= '0';
                        b2_row_addr <= addr;
                    when "11" =>
                        b3_act      <= '1';
                        b3_pch      <= '0';
                        b3_row_addr <= addr;
                    when others =>
                        null;
                end case;
            end if;

            -- precharge bank
            if (precharge_enb = '1') then
                precharge_all := addr(10);
                
                -- bank 0
                if ((precharge_all = '1') or (ba = "00")) and (b0_act = '1') then
                    b0_act <= '0';
                    b0_pch <= '1';
                end if;

                -- bank 1
                if ((precharge_all = '1') or (ba = "01")) and (b1_act = '1') then
                    b1_act <= '0';
                    b1_pch <= '1';
                end if;

                -- bank 2
                if ((precharge_all = '1') or (ba = "10")) and (b2_act = '1') then
                    b2_act <= '0';
                    b2_pch <= '1';
                end if;

                -- bank 3
                if ((precharge_all = '1') or (ba = "11")) and (b3_act = '1') then
                    b3_act <= '0';
                    b3_pch <= '1';
                end if;

                command(g_cas_latency-1) <= CMD_PRECHARGE;
            end if;

            -- read/write latch
            if (read_enb = '1') then
                command(g_cas_latency-1)   <= CMD_READ;
                col_addr(g_cas_latency-1)  <= addr;
                bank_addr(g_cas_latency-1) <= ba;
            end if;
            
            if (write_enb = '1') then
                current_cmd  := CMD_WRITE;
                col_addr(0)  <= addr;
                bank_addr(0) <= ba;
                -- latch the incoming data
                ram_contents <= dq;
            end if;

            case current_cmd is
                when CMD_READ =>
                    dq <= ram_contents;
                when others =>
                    dq <= (others => 'Z');
            end case;

        end if; -- rising edge clk

    end process proc_clk;

end architecture behavioral;
