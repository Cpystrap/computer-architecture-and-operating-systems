# NAND gates

This repository contains an implementation of a **dynamically loadable C library** that models combinational Boolean circuits built from NAND gates.  

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
```
---

## Function Specifications

### `nand_t *nand_new(unsigned n);`

Create a new NAND gate with `n` inputs.

- **Returns:**  
  - Pointer to the allocated `nand_t` structure on success  
  - `NULL` on memory allocation failure (set `errno` to `ENOMEM`)

---

### `void nand_delete(nand_t *g);`

Disconnect all signals from inputs and outputs, free all memory used by the gate, and remove it.

- **Parameter:**  
  - `g`: pointer to the NAND gate to delete  
- **Behavior:**  
  - If `g` is `NULL`, do nothing  
  - After this call, the pointer becomes invalid

---

### `int nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k);`

Connect the output of gate `g_out` to input `k` of gate `g_in`.

- **Parameters:**  
  - `g_out`: source gate  
  - `g_in`: destination gate  
  - `k`: input index on `g_in`  
- **Returns:**  
  - `0` on success  
  - `-1` on error (`errno` set to `EINVAL` or `ENOMEM`)

---

### `int nand_connect_signal(bool const *s, nand_t *g, unsigned k);`

Connect a boolean signal `s` to input `k` of gate `g`.

- **Parameters:**  
  - `s`: pointer to a `bool` signal  
  - `g`: pointer to the gate  
  - `k`: input index  
- **Returns:**  
  - `0` on success  
  - `-1` on error (`errno` set to `EINVAL` or `ENOMEM`)

---

### `ssize_t nand_evaluate(nand_t **g, bool *s, size_t m);`

Evaluate the outputs of the given gates and compute the critical path length.

- **Parameters:**  
  - `g`: array of `nand_t*` gates  
  - `s`: array of `bool` outputs  
  - `m`: size of arrays  
- **Returns:**  
  - Critical path length (non-negative) on success  
  - `-1` on error (`errno` set to `EINVAL`, `ECANCELED`, or `ENOMEM`)

#### Evaluation Rules

- Critical path of a signal or gate with no inputs is `0`
- For a gate:  
  `1 + max(S0, S1, ..., Sn-1)` where `Si` is the critical path of input `i`
- Must cache results during a single evaluation call
- Evaluation fails if any input is unconnected or a cycle is detected

---

### `ssize_t nand_fan_out(nand_t const *g);`

Return the number of gate inputs connected to the output of gate `g`.

- **Returns:**  
  - Fan-out count (non-negative)  
  - `-1` if `g` is `NULL` (`errno` set to `EINVAL`)

---

### `void* nand_input(nand_t const *g, unsigned k);`

Return the pointer to the signal or gate connected to input `k` of gate `g`.

- **Returns:**  
  - `bool*` or `nand_t*` if connected  
  - `NULL` if unconnected (`errno` set to `0`)  
  - `NULL` if `g` is `NULL` or `k` is invalid (`errno` set to `EINVAL`)

---

### `nand_t* nand_output(nand_t const *g, ssize_t k);`

Return the `k`-th gate connected to the output of gate `g`.

- **Parameters:**  
  - `g`: pointer to the gate  
  - `k`: index from `0` to `nand_fan_out(g) - 1`  
- **Returns:**  
  - Pointer to the `k`-th connected gate  
  - Result is unspecified if parameters are invalid

---

## Functional Requirements Summary

- Evaluation must respect input dependencies recursively
- Must detect and reject cycles or unconnected inputs
- Each gate’s output and path length must be computed only once per evaluation
- Arbitrary fan-out and input count must be supported

---

## Submission Format

Submit a compressed archive (`.zip`, `.7z`, `.rar`, or `tar.gz`) containing:

- `nand.c` and optionally other `.c/.h` files
- A `Makefile` that builds `libnand.so` using `make libnand.so`

### Makefile Requirements

- Must compile with:  
  `-Wall -Wextra -Wno-implicit-fallthrough -std=gnu17 -fPIC -O2`
- Must link with:  
  `-shared -Wl,--wrap=malloc -Wl,--wrap=calloc -Wl,--wrap=realloc -Wl,--wrap=reallocarray -Wl,--wrap=free -Wl,--wrap=strdup -Wl,--wrap=strndup`
- Must include `.PHONY` target
- `make clean` should remove all generated files

---

## Provided Files

- `memory_tests.c` — memory allocation wrapper
- `memory_tests.h` — header for memory tests
- `nand_example.c` — example usage and tests
- `nand.h` — interface declaration (do not modify)

---

## Notes

- Implementation must not leak memory (verified with `valgrind`)
- No artificial limits on structure sizes
- Must compile and run on teaching lab Linux machines
