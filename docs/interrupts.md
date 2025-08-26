# SHRIMP Interrupts

## Interrupt Controller

The SHRIMP interrupt controller allows a variable number of irq signals to be
present on the processor (up to 32). Hardware interrupts take precedence over
software interrupts. Additionally, the interrupt controller may hold interrupt
requests in a queue, or mask simultaneous interrupts.

The IRC (interrupt request controller) requires three different inputs to assert
a proper interrupt:

1. The interrupt request (separate for hardware and software interrupts)
2. The interrupt id (the 5 bit position of the interrupt line or the interrupt
   vector directly from the int instruction)
3. An enable signal. This should come from the flags register.

When an interrupt request arrives on the IRC, the inputs are latched (assuming
the IRC enable signal is high). These latched inputs are then asserted on the
IRC's output lines. When the CPU receives an interrupt from the IRC, it should
first set the IRC enable signal low. This will prevent interrupts from being
asserted while handling an interrupt. When the CPU finishes handling the
interrupt, it should enable the IRC again and set its `claim` signal high. This
allows the IRC to discard the latched interrupt and handle other interrupts.

## Interrupt Handling

When handling an interrupt, the CPU will do the following things:

1. Place the program counter then flags register onto the stack
2. Place GPRs 1 through 14 onto the stack (GPR 0 is the zero register and 15 is
   the stack pointer)
3. Disable interrupts
4. Transfer control to the corresponding interrupt vector (as dictated by the
   asserted signals on the IRC)

When the interrupt handler returns (via `reti`), the CPU will:
1. Pop the GPRs from the stack
2. Pop the flags register then program counter from the stack

This will return execution to the previous process and ensure the interrupt
enable status is the same as before.

The CPU will handle an interrupt after the current instruction is done
executing.
