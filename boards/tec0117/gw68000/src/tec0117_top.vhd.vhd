-- Top level for the gw68000 system
-- Version          Description
--   0.1:           initial version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gw68000_top;

entity tec0117_top is
    port
    (
        clk12M      : in std_logic;
        userbutton  : in std_logic;
        led         : out std_logic
    );
end;

architecture rtl of tec0117_top is
    signal spy_PC  : std_logic_vector(31 downto 0);
begin

    led <= spy_PC(1);

    u_gw68000: entity gw68000_top(rtl)
        port map
        (
            clk     => clk12M,
            reset_n => userbutton,
            spy_PC  => spy_PC
        );

end rtl;
