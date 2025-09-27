library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.attrs.all;

entity memioc is
    port (
        clk : in std_logic;
        en, r, w : in std_logic;
        addr : in word_t;
        d_in : in word_t;
        d_out : out word_t;

        porta : out word_t; -- cpu output port
        portb : in word_t -- cpu input port
    );
end entity;

architecture behavioral of memioc is
    -- port 0 is the output port (cpu writes to port 0)
    -- port 1 is the input port (gets input from outside)
    type port_array_t is array(0 to N_PORTS-1) of word_t;
    signal ports : port_array_t;

    signal mem_en : std_logic;
begin
    RAM : entity work.memory port map (
        clk => not clk, -- trigger on falling edge instead
        en => mem_en,
        r => r,
        w => w,
        addr => addr,
        d_in => d_in,
        d_out => d_out
    );

    process (all) is
        variable addr_idx : integer;
    begin
        addr_idx := to_integer(unsigned(addr));
        mem_en <= '0' when addr_idx < N_PORTS else en;
    end process;

    process (clk) is
        variable addr_idx : integer;
    begin
        if rising_edge(clk) then
            addr_idx := to_integer(unsigned(addr));

            porta <= ports(0);
            ports(1) <= portb;

            if en = '1' then
                if addr_idx = 1 and w = '1' then
                    -- idk what it means to write to an input
                    d_out <= (others => 'Z');
                elsif addr_idx < N_PORTS then
                    if r = '1' then
                        d_out <= ports(addr_idx);
                    elsif w = '1' then
                        ports(addr_idx) <= d_in;
                        d_out <= (others => 'Z');
                    end if;
                else
                    d_out <= (others => 'Z');
                    -- here, memory is enabled directly
                end if;
            else
                d_out <= (others => 'Z');
            end if;
        end if;
    end process;
end architecture;
