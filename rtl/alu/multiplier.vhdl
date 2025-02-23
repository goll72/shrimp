library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity multiplier is
    port (
        d_in1 : in word_t;
        d_in2 : in word_t;
        sgn   : in std_logic;
        wrd   : in std_logic;
        d_out : out word_t;
        overflow : out std_logic
    );
end entity;

architecture behavioral of multiplier is
    -- intermediate signal to add
    type int2_t is array(WORD_BITS - 1 downto 0) of word_t;
    signal int2 : int2_t;
    signal a, b, p : word_t; -- operands a, b, and the product
    signal p_neg : word_t;
    signal a_sign, b_sign : std_logic;

    signal negative : std_logic;
begin
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

    negative <= a_sign xor b_sign;

    p_twoscomplement : entity work.adder port map (
        d_in1 => not p,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => p_neg,
        cout => open,
        overflow => open
    );

    -- generate the second intermediate for the first time
    p(0) <= a(0) and b(0);
    firstop2 : for i in 1 to WORD_BITS - 1 generate
    begin
        int2(0)(i - 1) <= b(0) and a(i);
    end generate;
    int2(0)(WORD_BITS - 1) <= '0';

    sums : for n in 1 to WORD_BITS - 1 generate
        signal int1, sumout : word_t;
        signal cout : std_logic;
    begin
        -- first intermediate is `BN and A15 & ... & BN and A0`
        op1 : for i in p'range generate
            int1(i) <= b(n) and a(i);
        end generate;

        -- int2 for the adder is the previous int2
        adder : entity work.adder port map (
            d_in1 => int1,
            d_in2 => int2(n - 1),
            cin => '0',
            wrd => wrd,
            d_out => sumout,
            cout => cout,
            overflow => open
        );

        -- LSB of adder output is the n-th bit of the product
        -- then the carryout and remaining bits are the next intermediate word
        p(n) <= sumout(0);
        int2(n) <= cout & sumout(sumout'high downto 1);
    end generate;

    d_out <= p_neg when sgn = '1' and negative = '1' else p;
    -- if any bit in the final int2 is set, then there is an overflow
    overflow <= (or int2(int2'high)) or p(p'high) when sgn = '1' else
                (or int2(int2'high));
end architecture;
