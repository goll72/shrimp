-- full adder description --
library ieee;
use ieee.std_logic_1164.all;

entity adder_fulladder is
    port (
        a, b, cin : in std_logic;
        s, cout : out std_logic
    );
end entity;

architecture behavioral of adder_fulladder is
    -- first and second sums and carries
    signal s1, s2, c1, c2 : std_logic;
begin
    s1 <= a xor b;
    c1 <= a and b;
    s2 <= s1 xor cin;
    c2 <= s1 and cin;

    s <= s2;
    cout <= c1 or c2;
end architecture;


-- ripple carry adder --
library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity adder is
    port (
        d_in1 : in word_t;
        d_in2 : in word_t;
        cin   : in std_logic;
        d_out : out word_t;
        cout  : out std_logic;
        overflow : out std_logic
    );
end entity;

architecture behavioral of adder is
    component adder_fulladder is
        port (
            a, b, cin : in std_logic;
            s, cout : out std_logic
        );
    end component;

    -- 0th bit is the carry in
    signal carries : std_logic_vector(WORD_BITS downto 0);
begin
    carries(0) <= cin;

    bit_adders: for i in d_out'range generate
        fa : adder_fulladder port map (
            a => d_in1(i),
            b => d_in2(i),
            cin => carries(i),
            s => d_out(i),
            cout => carries(i + 1)
        );
    end generate;

    cout <= carries(WORD_BITS);
    overflow <= carries(WORD_BITS) xor carries(WORD_BITS - 1);
end architecture;
