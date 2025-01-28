library ieee;

use ieee.std_logic_1164.all;

use work.attrs.all;

entity reg is
    port (
        clk, rst : in std_logic;
        w_en     : in std_logic;
        d : in word_t;
        q : out word_t
    );
end entity;

architecture behavioral of reg is
begin
    process(clk, rst, w_en) is
    begin
        if rst = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) and w_en = '1' then
            q <= d;
        end if;
    end process;
end architecture;
