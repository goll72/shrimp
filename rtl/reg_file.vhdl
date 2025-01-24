library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;

entity reg_file is
    port (
        clk, rst   : in std_logic;
        w_en, word : in std_logic;
        reg1_addr, reg2_addr : in std_logic_vector(4 downto 0);
        reg_w_addr : in std_logic_vector(5 downto 0);
        reg1, reg2 : out word_t;
        test       : out std_logic_vector(3 downto 0)
    );
end entity;

architecture behavioral of reg_file is
    signal reg_w : std_logic_vector(15 downto 0);
begin
    decoder : for i in reg_w'range generate
        reg_w(i) <= '1' when std_logic_vector(to_unsigned(i, reg_w_addr'length)) = reg_w_addr else '0';
    end generate;
end architecture;
