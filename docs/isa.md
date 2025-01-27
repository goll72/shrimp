# SHRIMP ISA

SHRIMP instructions are at least 1 full word wide (16 bits, indexed 15 MSB to 0
LSB), though some instructions will use an additional word. Generally,
instructions take the following form:

```
opcode5 register4 flag? flag? flag? register4
```

The opcode is 5 bits wide, occupying bits 15 through 11. Each register address
is 4 bits wide, and the first register operand will typically occupy bits 10
through 7. The following three bits are typically flags, and the final four bits
are often a second register operand.

## Word format

SHRIMP contains the following instructions with respective formats:

| name    | opcode   | format |
| ----    | ------   | ------ |
| `add  ` | `00000`  | `opcode5 register4 imm? wrd? 0    register4` |
| `sub  ` | `00001`  | `opcode5 register4 imm? wrd? 0    register4` |
| `mul  ` | `00010`  | `opcode5 register4 imm? wrd? sgn? register4` |
| `div  ` | `00011`  | `opcode5 register4 imm? wrd? sgn? register4` |
| `sha  ` | `00100`  | `opcode5 register4 imm? wrd? 0    register4` |
| `mod  ` | `00101`  | `opcode5 register4 imm? wrd? sgn? register4` |
| `and  ` | `00110`  | `opcode5 register4 imm? wrd? 0    register4` |
| `or   ` | `00111`  | `opcode5 register4 imm? wrd? 0    register4` |
| `xor  ` | `01000`  | `opcode5 register4 imm? wrd? 0    register4` |
| `not  ` | `01001`  | `opcode5 register4 imm? wrd? 0    register4` |
| `shl  ` | `01010`  | `opcode5 register4 imm? 0    rot? register4` |
| `rol  ` | `01010`  | `opcode5 register4 imm? 0    rot? register4` |
| `shr  ` | `01011`  | `opcode5 register4 imm? 0    rot? register4` |
| `ror  ` | `01011`  | `opcode5 register4 imm? 0    rot? register4` |
| `jmp  ` | `01100`  | `opcode5 register4 imm? n? z? p? c? o? 0   ` |
| `call ` | `01100`  | `opcode5 register4 imm? n? z? p? c? o? 1   ` |
| `ret  ` | `01101`  | `opcode5 0 0000000000                      ` |
| `reti ` | `01101`  | `opcode5 1 0000000000                      ` |  
| `int  ` | `01110`  | `opcode5 0000      imm? x x       register4` |
| `mov  ` | `01111`  | `opcode5 register4 imm? wrd? 0    register4` |
| `ld   ` | `10000`  | `opcode5 register4 imm? 0    0    register4` |
| `st   ` | `10001`  | `opcode5 register4 imm? 0    0    register4` |
| `ldflg` | `10010`  | `opcode5 register4 0000000                 ` |
| `stflg` | `10011`  | `opcode5 register4 0000000                 ` |

The first register4 block will typically be the destination register, while the
second register4 block will typically be the source register.


### Flags

If a flag is "set", then its value is `1`. Otherwise its value will be `0`.

| flag | set                                      | unset |
| ---- | ---                                      | ----- |
| imm? | The following word is an immediate value | Use a second register |
| wrd? | The instruction operates on a word       | It operates on a byte |
| sgn? | The instruction is a signed operation    | It is unsigned |
| rot? | This shift instruction rotates the word  | It is a linear shift |
| n?   | Branch if negative flag is set           | Ignore |
| z?   | Branch if zero flag is set               | Ignore |
| p?   | Branch if positive flag is set           | Ignore |
| c?   | Branch if carryout flag is set           | Ignore |
| o?   | Branch if overflow flag is set           | Ignore |

### Special cases

* `jmp`/`call`: If `imm?` is set, then the first register4 slot is all zeros
* `shl`/`shr`/`rol`/`ror`/`sha`: If `imm?` is set, then the second register4
  slot is treated as a 4 bit immediate.
* add, sub, mul, div, mod, and, or, xor, not, mov, ld, st: If `imm?` is set, the
  then immediate is stored in the next word. If `wrd?` is also set, then the
  immediate is the lower 8 bits of the following word.
* `int`: If `imm?` is set, then the final 6 bits (bits 5 through 0) are treated
  as a 6 bit immediate.


## Instruction operation

"op1" refers to the first operand of an instruction (the first register4 block)
while "op2" is the second operand (typically the second register4 block or an
immediate).

"rd" is used to refer to the destination register (typically op1), while "rs"
refers to the source register (typically op2).

"PC" refers to the program counter.

The instructions will perform the following operations:

* `add`: Add the op2 to op1, and store the result in rd
* `sub`: Subtract op2 from op1 and store the result in rd
* `mul`: Store the product of op1 and op2 in rd, with signed and unsigned
  varieties
* `div`: Divide op1 by op2 and store the result in rd
* `sha`: Arithmetic right shift of op1 by op2, storing the result in rd
* `mod`: Find the remainder of op1 divided by op2, storing the result in rd
* `and`: Bitwise AND of op1 and op2, storing the result in rd
* `or `: Bitwise OR of op1 and op2, storing the result in rd
* `xor`: Bitwise XOR of op1 and op2, storing the result in rd
* `not`: Bitwise negation of op2, storing the result in rd
* `shl`: Left shift of op1 by op2, storing the result in rd
* `rol`: Rotate op1 left by op2, storing the result in rd
* `shr`: Right shift of op1 by op2, storing the result in rd
* `ror`: Rotate op1 right by op2, storing the result in rd
* `jmp`: When conditions are satisfied, jump to op1 (sets PC to op1)
* `call`: When conditions are satisfied, push PC onto the stack, and jump to op1
* `ret`: Pop PC from the stack (used to return from `call`)
* `reti`: Restore all registers from the stack, then pop PC off (used to return
  from an interrupt)
* `int`: Push PC onto the stack, save all registers onto the stack, then jump to
  the interrupt op1
* `mov`: Copy the value of op2 into rd
* `ld`: Load the value at memory address op2 into rd
* `st`: Store the value of rs (which is op1) into memory address op2
* `ldflg`: Load the flags register into rd
* `stflg`: Set the flags register to the value rs


# Registers

SHRIMP defines 16 general purpose registers addressed 0x0 through 0xF. The
register 0x0 is the zero register, which always contains the value zero, and
discards anything written to it. The register 0xF is the stack pointer, and
points to the top of the stack. The stack is defined as growing down (i.e. it
starts at some address `x` and the next entry in the stack is at address `x -
1`). However, it is the responsibility of the operating system to set the head
of the stack, as SHRIMP has no requirements on where it must begin.

# Memory

SHRIMP defines a memory consisting of 65536 (2^16) addressable, 16 bit (full
word) memory locations. The first 80 memory locations are reserved as such:

* `0x0000` through `0x000F` are the 16 memory mapped ports
* `0x0010` through `0x004F` is the 64 word wide interrupt descriptor table. This
  means that interrupts called via the `int` instruction will jump to the memory
address pointed to by `0x0010 + X`, where X is the interrupt vector.
* `0x0050` is the origin address for PC. This means that PC will be set to
  address `0x0050` on machine initialization, and origin programs need to have
an origin at `0x0050`.

All addresses from `0x0050` through `0xFFFF` are executable memory, meaning any
program may reside in these addresses, and may use these addresses in any
manner.
