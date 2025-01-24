SHRIMP
======

SHRIMP (Simple Hardware Reduced Instruction MicroProcessor) is a 
16-bit CPU.

## Usage

Simulation with both `nvc` and `ghdl` is supported. Set `ENV` to
either `nvc` or `ghdl` when running `make`.

To run a simulation/testbench, the `run` target may be used. The
`TOP` variable has to be set to the name of the top-level 
entity/unit to be run.
