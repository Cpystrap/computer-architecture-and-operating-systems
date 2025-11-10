# NAND gates — library task

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
The type nand_t is a structural type that represents a NAND gate. You must define (implement) that type as part of this task.

Below follow the required behaviour and return values for each function.

nand_t * nand_new(unsigned n);

Create a new NAND gate with n inputs.

Return value

pointer to the allocated nand_t structure on success;

NULL on memory allocation failure; in that case the function sets errno to ENOMEM.

void nand_delete(nand_t *g);

Disconnect any signals from the inputs and outputs of the specified gate, free all memory used by the gate, and remove it. If called with a NULL pointer, do nothing. After this call the passed pointer becomes invalid.

Parameter

g — pointer to the NAND gate to delete.

int nand_connect_nand(nand_t *g_out, nand_t *g_in, unsigned k);

Connect the output of gate g_out to input k of gate g_in. If that input was previously connected, it is disconnected first.

Parameters

g_out — pointer to the source gate (whose output will be connected);

g_in — pointer to the destination gate (whose input k will be connected);

k — index of the input on g_in.

Return value

0 on success;

-1 on error (if any pointer is NULL, k is invalid, or memory allocation fails). In case of error set errno to EINVAL (invalid pointer or invalid index) or ENOMEM (allocation failure), as appropriate.

int nand_connect_signal(bool const *s, nand_t *g, unsigned k);

Connect the boolean signal pointed to by s to input k of gate g. If that input was previously connected, it is disconnected first.

Parameters

s — pointer to a bool variable (the signal source);

g — pointer to the gate;

k — input index on g.

Return value

0 on success;

-1 on error (if any pointer is NULL, k is invalid, or memory allocation fails). In case of error set errno to EINVAL or ENOMEM, as appropriate.

ssize_t nand_evaluate(nand_t **g, bool *s, size_t m);

Evaluate the outputs of the given gates and compute the length of the critical path.

The critical path length for a boolean signal (a bool source) and for a gate without inputs is 0.

For a gate, the critical path length at its output is 1 + max(S0, S1, ..., S_{n-1}), where Si is the critical path length at the gate's i-th input.

The critical path length of the whole circuit for the set of gates passed to nand_evaluate is the maximum of the critical path lengths at the outputs of those gates.

Parameters

g — pointer to an array of m pointers to nand_t (the gates whose outputs are to be evaluated);

s — pointer to an array of m bool elements where the computed output values will be stored;

m — size of the arrays g and s.

Return value

the critical path length (non-negative) on success; array s contains the computed output values, where s[i] is the output of g[i];

-1 on error (if any pointer is NULL, m is zero, the operation failed due to an unconnected input or a combinational loop, or memory allocation failed). On error set errno to EINVAL (invalid pointer or m == 0), ECANCELED (evaluation failed due to missing connection or cycle), or ENOMEM (allocation failure). The contents of s are then undefined.

Additional evaluation requirements

Computing the output value and critical path length of a gate requires first computing those values for each of its inputs (unless the gate has zero inputs).

Evaluation may fail if some input is not connected, the evaluation procedure enters a loop (gates do not form a combinational circuit), or memory allocation fails.

Ensure that for the duration of a single nand_evaluate call, the output value and critical path length for each gate are computed only once (i.e., cache results for that evaluation).

ssize_t nand_fan_out(nand_t const *g);

Return the number of gate inputs that are connected to the output of gate g (the fan-out size).

Parameter

g — pointer to the gate.

Return value

fan-out count (non-negative) on success;

-1 if g is NULL; in that case set errno to EINVAL.

void* nand_input(nand_t const *g, unsigned k);

Return a pointer to the signal or gate connected to input k of gate g, or NULL if nothing is connected there.

Parameters

g — pointer to the gate;

k — input index.

Return value

pointer of type bool* (if a boolean signal is connected) or nand_t* (if another gate is connected);

NULL if nothing is connected to the specified input — in that case the function sets errno to 0;

NULL also if g is NULL or k is invalid — in that case the function sets errno to EINVAL.

nand_t* nand_output(nand_t const *g, ssize_t k);

Iterate over gates connected to the output of gate g. This function returns the k-th gate (indexing from 0) among those inputs that are connected to g's output. If the output of g is connected multiple times to different inputs (or multiple inputs of the same gate), the same gate may appear multiple times during iteration.

Parameters

g — pointer to the gate;

k — index from 0 to nand_fan_out(g) - 1.

Return value

pointer to the k-th gate connected to the output of g. The result is unspecified if parameters are invalid.

Functional requirements (summary)

The implementation must compute a gate's output value and critical path length by first computing those quantities at the gate's inputs (recursive dependency). A non-recursive implementation that respects dependencies is allowed.

Evaluation should fail (and nand_evaluate must return -1 with errno = ECANCELED) if any input is unconnected or if there is a cycle (not a combinational circuit).

During a single nand_evaluate call, each gate's output value and critical path length must be computed only once.

A gate's output may drive multiple inputs (fan-out). The implementation must support arbitrary fan-out and arbitrary numbers of inputs (bounded only by available memory and machine word size).

Formal requirements (submission format and build)

Submit a compressed archive (ZIP, 7z, RAR, or tar+gzip) containing:

nand.c and optionally other .c/.h files implementing the library,

a makefile or Makefile.

The archive must not contain other files or subdirectories (in particular, no binary files). After unpacking, all files should reside in a single common subdirectory.

The provided Makefile must define the target libnand.so so that running make libnand.so builds the shared library libnand.so in the current directory. The build must also compile and link the attached file memory_tests.c into the library.

The Makefile must specify file dependencies so that only changed files (or files that depend on them) are rebuilt. The make clean target should remove all files produced by make.

Include a .PHONY pseudo-target in the Makefile. You may add other targets (for example, a target that builds and links the example nand_example.c against the library, or a test runner).

Use gcc to compile. The library must compile on the teaching lab Linux machines.

Source files implementing the library must be compiled with:
-Wall -Wextra -Wno-implicit-fallthrough -std=gnu17 -fPIC -O2

When linking the library, use the following linker options:
-shared -Wl,--wrap=malloc -Wl,--wrap=calloc -Wl,--wrap=realloc -Wl,--wrap=reallocarray -Wl,--wrap=free -Wl,--wrap=strdup -Wl,--wrap=strndup

The --wrap= options cause calls to malloc, calloc, etc. to be intercepted by __wrap_malloc, __wrap_calloc, etc.; those wrapper functions are implemented in the provided memory_tests.c file.

The implementation must not leak memory or leave data structures in an inconsistent state, including when memory allocation fails. Correctness will be verified with valgrind.

Do not impose artificial limits on data structure sizes; the only limits are available memory and the machine word size.

Attachments (provided with the assignment)

The assignment package contains these files:

memory_tests.c — implementation of the testing module that simulates allocation failures;

memory_tests.h — header for the memory testing module;

nand_example.c — example tests and usage of the library (part of the specification);

nand.h — declaration of the library interface (do not modify this file).

The testing environment may modify memory_tests.c and memory_tests.h, and test cases may be changed during grading.
