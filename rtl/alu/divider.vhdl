library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity divider is
    port (
        d_in1 : in word_t;
        d_in2 : in word_t;
        sgn   : in std_logic;
        wrd   : in std_logic;
        d_out : out word_t; -- division output
        r_out : out word_t  -- remainder output
    );
end entity;

architecture rtl of divider is
    type div_matrix_t is array(WORD_BITS - 1 downto 0) of word_t;

    signal m : div_matrix_t;

    -- signed magnitude representations
    signal a, b, q : word_t;
    signal q_neg : word_t;
    signal a_sign, b_sign : std_logic;
begin
    -- handle signed magnitude
    a_magnitude : entity work.magnitude port map (
        d_in1 => d_in1,
        sgn => sgn,
        wrd => wrd,
        d_out => a,
        signb => a_sign
    );

    b_magnitude : entity work.magnitude port map (
        d_in1 => d_in2,
        sgn => sgn,
        wrd => wrd,
        d_out => b,
        signb => b_sign
    );

    q_twoscomplement : entity work.adder port map (
        d_in1 => not q,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => q_neg,
        cout => open,
        overflow => open
    );

    -- division is done below:
    m(0) <= (WORD_BITS - 1 downto 1 => '0') & a(a'high);

    divide : for i in m'range generate
        signal sub_in, sub_out : word_t;
        signal b_out : std_logic;

        -- Partial remainder
        signal pr : word_t;
    begin
        sub : entity work.subtractor port map (
            d_in1 => m(i),
            d_in2 => b,
            b_in => '0',
            b_out => b_out,
            result => sub_out
        );

        q(WORD_BITS - 1 - i) <= not b_out;
        pr <= m(i) when b_out = '1' else sub_out;

        next_bit : if i = WORD_BITS - 1 generate
            r_out <= pr;
        else generate
            m(i + 1) <= pr(pr'high - 1 downto 0) & a(WORD_BITS - 2 - i);
        end generate;
    end generate;

    d_out <= q_neg when sgn = '1' and (a_sign xor b_sign) = '1' else q;
end architecture;
