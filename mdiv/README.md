# Assembly Task: Integer Division with Remainder

## Function Declaration

You must implement the following function in x86-64 assembly, callable from C:

```c
int64_t mdiv(int64_t *x, size_t n, int64_t y);
```

# `mdiv` Function Specification

## Function Behavior

The function performs **signed integer division with remainder**, treating all values as **two's complement signed integers**.

### Dividend Representation

- The dividend is stored in an array `x` of `n` 64-bit integers.
- Total bit length: `64 * n`.
- Stored in **little-endian** order (least significant word first).

### Division Details

- The divisor is a 64-bit signed integer `y`.
- The **quotient** is written back into the array `x`.
- The **remainder** is returned as the function result.

---

## Overflow Handling

- If the quotient cannot fit into the array `x`, this is considered **overflow**.
- **Division by zero** is also treated as overflow.
- On overflow, the function must raise **interrupt 0**, just like `div` and `idiv` instructions.
- In Linux, this results in a **SIGFPE** signal being sent to the process.

---

## Assumptions

- The pointer `x` is valid.
- The value `n` is positive.

---

## Example Usage

An example is provided in the file `mdiv_example.c`. It demonstrates:

- How signs of dividend, divisor, quotient, and remainder relate.

### Compilation Steps

```bash
gcc -c -Wall -Wextra -std=c17 -O2 -o mdiv_example.o mdiv_example.c
gcc -z noexecstack -o mdiv_example mdiv_example.o mdiv.o
```

### Submit a single file named: mdiv.asm
### Compilation Command: 
```bash
nasm -f elf64 -w+all -w+error -o mdiv.o mdiv.asm
```

# Grading Criteria for `mdiv.asm`

## Automatic Tests

- Correctness of results
- ABI compliance
- Memory access correctness
- Penalty for excessive use of `.bss`, `.data`, `.rodata`, stack, or heap
- Penalty for exceeding `.text` section size threshold
- Performance (slow solutions will not receive full points)
- Incorrect filename: −1 point

---

## Code Formatting and Quality

### Formatting Rules

- Labels start in column 1
- Mnemonics aligned to a fixed column
- No other indentation

### Commenting Guidelines

- Each code block must be explained
- Register usage must be documented
- All key or non-trivial lines must be commented
- Avoid redundant comments that simply restate the code


