library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity divider is
	port (
		d_in1 : in word_t;
		d_in2 : in word_t;
		d_out : out word_t; -- division output
		r_out : out word_t  -- remainder output
	);
end entity;

architecture rtl of divider is
    type div_matrix_t is array(WORD_BITS - 1 downto 0) of word_t;

    signal m : div_matrix_t;
begin
    m(0) <= (WORD_BITS - 1 downto 1 => '0') & d_in1(d_in1'high);

    divide : for i in m'range generate
        signal sub_in, sub_out : word_t;
        signal b_out : std_logic;

        -- Partial remainder
        signal pr : word_t;
    begin
        sub : entity work.subtractor port map (
            d_in1 => m(i),
            d_in2 => d_in2,
            b_in => '0',
            b_out => b_out,
            result => sub_out
        );

        d_out(WORD_BITS - 1 - i) <= not b_out;
        pr <= m(i) when b_out = '1' else sub_out;

        next_bit : if i = WORD_BITS - 1 generate
            r_out <= pr;
        else generate
            m(i + 1) <= pr(pr'high - 1 downto 0) & d_in1(WORD_BITS - 2 - i);
        end generate;
    end generate;
end architecture;
