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
    type int2_t is array(15 downto 0) of word_t;
    signal int2 : int2_t;
    signal prod : std_logic_vector(WORD_BITS * 2 - 1 downto 0);
    signal a, b, p : word_t; -- operands a, b, and the product
    signal a_mag, b_mag, p_mag : word_t;
    signal negative : std_logic;
begin
    -- the following components find the magnitude of negative numbers
    a_magnitude : entity work.adder port map (
        d_in1 => not d_in1,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => a_mag,
        cout => open,
        overflow => open
    );

    b_magnitude : entity work.adder port map (
        d_in1 => not d_in2,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => b_mag,
        cout => open,
        overflow => open
    );

    p_twoscomplement : entity work.adder port map (
        d_in1 => not p,
        d_in2 => (others => '0'),
        cin => '1',
        wrd => '1',
        d_out => p_mag,
        cout => open,
        overflow => open
    );

    -- handle signed multiplication
    process (all)
        variable msb_pos : natural;
    begin
        -- if sgn? flag is set, then convert both inputs to signed magnitude
        if sgn = '1' then
            if wrd = '1' then
                msb_pos := WORD_BITS - 1;
            else
                msb_pos := BYTE_BITS - 1;
            end if;

            negative <= d_in1(msb_pos) xor d_in2(msb_pos);

            -- convert to signed magnitude
            if d_in1(msb_pos) = '1' then
                a <= a_mag;
            else
                a <= d_in1;
            end if;

            if d_in2(msb_pos) = '1' then
                b <= b_mag;
            else
                b <= d_in2;
            end if;
        else
            a <= d_in1;
            b <= d_in2;
        end if;
    end process;

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
        int2(n)(WORD_BITS - 1) <= cout;
        int2(n)(WORD_BITS - 2 downto 0) <= sumout(WORD_BITS - 1 downto 1);
    end generate;
    -- if any bit in the final int2 is set, then there is an overflow
    overflow <= or int2(int2_t'length - 1);

    process (all)
    begin
        if sgn = '1' and negative = '1' then
            d_out <= p_mag;
        else
            d_out <= p;
        end if;

		if sgn = '1' then
			overflow <= or int2(int2_t'length - 1) or p(WORD_BITS - 1);
		else
			overflow <= or int2(int2_t'length - 1);
		end if;
    end process;
end architecture;
