library ieee;

use ieee.std_logic_1164.all;

use work.attrs.all;

package opcode is
    constant OP_ADD   : opcode_t := "00000";
    constant OP_SUB   : opcode_t := "00001";
    constant OP_MUL   : opcode_t := "00010";
    constant OP_DIV   : opcode_t := "00011";
    constant OP_SHA   : opcode_t := "00100";
    constant OP_MOD   : opcode_t := "00101";
    constant OP_AND   : opcode_t := "00110";
    constant OP_OR    : opcode_t := "00111";
    constant OP_XOR   : opcode_t := "01000";
    constant OP_NOT   : opcode_t := "01001";
    constant OP_SHL   : opcode_t := "01010";
    constant OP_ROL   : opcode_t := "01010";
    constant OP_SHR   : opcode_t := "01011";
    constant OP_ROR   : opcode_t := "01011";
    constant OP_JMP   : opcode_t := "01100";
    constant OP_CALL  : opcode_t := "01100";
    constant OP_RET   : opcode_t := "01101";
    constant OP_RETI  : opcode_t := "01101";
    constant OP_INT   : opcode_t := "01110";
    constant OP_MOV   : opcode_t := "01111";
    constant OP_LD    : opcode_t := "10000";
    constant OP_ST    : opcode_t := "10001";
    constant OP_LDFLG : opcode_t := "10010";
    constant OP_STFLG : opcode_t := "10011";
end package;
