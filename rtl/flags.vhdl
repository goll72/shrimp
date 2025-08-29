library ieee;
use ieee.std_logic_1164.all;

use work.attrs.all;

entity flags is
    port (
        clk, rst : in std_logic;
        n_in, w_n : in std_logic;
        z_in, w_z : in std_logic;
        p_in, w_p : in std_logic;
        c_in, w_c : in std_logic;
        o_in, w_o : in std_logic;
        ien_in, w_ien : in std_logic; -- IRC enable
        d : in word_t; -- full word input
        w_word : in std_logic;
        q : out word_t
    );
end entity;

architecture behavioral of flags is
begin
    process(clk, rst) is
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q <= (others => '0');
            elsif w_word = '1' then
                q <= d;
            else
                q(FLAG_N_BIT) <= n_in when w_n = '1';
                q(FLAG_Z_BIT) <= z_in when w_z = '1';
                q(FLAG_P_BIT) <= p_in when w_p = '1';
                q(FLAG_C_BIT) <= c_in when w_c = '1';
                q(FLAG_O_BIT) <= o_in when w_o = '1';
                q(FLAG_IEN_BIT) <= ien_in when w_ien = '1';
            end if;
        end if;
    end process;
end architecture;
