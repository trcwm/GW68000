-- 7 segment driver for DE0
-- Copyright Moseley Instruments (c) 2025

library ieee;
use ieee.std_logic_1164.all;

entity seg7 is
    port
    (
        digit_in : in std_logic_vector(3 downto 0);
        dot_in   : in std_logic;
        segs_out : out std_logic_vector(7 downto 0)
    );
end seg7;

architecture rtl of seg7 is
begin

    process(digit_in)
    begin
        case digit_in is
            when "0000" => segs_out(6 downto 0) <= "1000000"; -- "0" ok
            when "0001" => segs_out(6 downto 0) <= "1111001"; -- "1" ok
            when "0010" => segs_out(6 downto 0) <= "0101100"; -- "2" ok
            when "0011" => segs_out(6 downto 0) <= "0110000"; -- "3" ok
            when "0100" => segs_out(6 downto 0) <= "0011001"; -- "4" ok
            when "0101" => segs_out(6 downto 0) <= "0010010"; -- "5" ok
            when "0110" => segs_out(6 downto 0) <= "0000010"; -- "6" ok 
            when "0111" => segs_out(6 downto 0) <= "1111000"; -- "7" ok
            when "1000" => segs_out(6 downto 0) <= "0000000"; -- "8" ok  
            when "1001" => segs_out(6 downto 0) <= "0010000"; -- "9" ok
            when "1010" => segs_out(6 downto 0) <= "0001000"; -- a ok
            when "1011" => segs_out(6 downto 0) <= "0000011"; -- b ok
            when "1100" => segs_out(6 downto 0) <= "1000110"; -- C ok
            when "1101" => segs_out(6 downto 0) <= "0100001"; -- d ok
            when "1110" => segs_out(6 downto 0) <= "0110000"; -- E ok
            when "1111" => segs_out(6 downto 0) <= "0111000"; -- F ok
        end case;
    end process;

    segs_out(7) <= not dot_in;

end architecture rtl;