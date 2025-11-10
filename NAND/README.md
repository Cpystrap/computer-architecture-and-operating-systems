# NAND gates — library task

This repository contains an implementation (or should contain an implementation) of a **dynamically loadable C library** that models combinational Boolean circuits built from NAND gates.  
Below is a full English specification you can paste into `README.md`.

---

## Problem summary

A **NAND gate** has a non-negative integer number of inputs and one output.

- A NAND gate with **zero inputs** always produces `false` on its output.
- A NAND gate with **one input** acts as logical **NOT** (output = negation of the single input).
- For a gate with `n > 0` inputs, inputs are numbered `0 .. n-1`.
- Each input accepts a Boolean signal (`true` or `false`).
- The NAND output is `false` **iff** *all* its inputs are `true`; otherwise the output is `true`.
- A gate output can be connected to **many** inputs (fan-out).
- Each input may be connected to **exactly one** source (either a `bool` signal or another gate output).

The task is to implement the library interface declared in the supplied `nand.h` and match the behaviour shown in the supplied `nand_example.c`.

---

## Library interface

The interface is declared in the provided `nand.h` (do **not** modify `nand.h`). The important declarations (reference) are:

```c
typedef struct nand nand_t;

nand_t * nand_new(unsigned n);
void     nand_delete(nand_t *g);

int      nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k);
int      nand_connect_signal(bool const *s, nand_t *g, unsigned k);

ssize_t  nand_evaluate(nand_t **g, bool *s, size_t m);

ssize_t  nand_fan_out(nand_t const *g);
void *   nand_input(nand_t const *g, unsigned k);
nand_t * nand_output(nand_t const *g, ssize_t k);
