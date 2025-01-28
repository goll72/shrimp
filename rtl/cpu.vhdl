library ieee;

use ieee.std_logic_1164.all;

use work.attrs.all;

entity cpu is 
    port (
        clk, rst : in std_logic;
        d_in : in word_t;
        d_out : out word_t
    );
end entity;

architecture structural of cpu is 
    signal reg1, reg2 : word_t;
begin
    registers : entity work.reg_file
     port map(
        clk => clk,
        rst => rst,
        w_en => '1',
        w_word => '1',
        w_addr => (others => '0'),
        w_data => (others => '1'),
        reg1_addr => (others => '0'),
        reg2_addr => "0000" & clk,
        reg1 => reg1,
        reg2 => reg2
    );
end architecture;
