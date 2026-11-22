# Memory errors

`-exx` catches an index out of bounds and a null pointer. It cannot catch a
pointer to memory that has been freed: the address is still real, and the
program reads whatever is there now. **`-fsanitize=address`** builds the
program with AddressSanitizer, which checks every memory access and stops at
the first bad one.

```tiko
{{#include ../../examples/testing/freed.tiko}}
```

**Output**

```text
{{#include ../../examples/testing/freed.out}}
```

````admonish warning title="Status in this version"
`-fsanitize=address` arrives after tiko 0.1.6, the toolchain this site is
pinned to. This example was compiled and run on Windows with the development
toolchain.
````

Without the `#cmdline` line the program prints a second, meaningless reading
and exits 0. Checked, it stops at line 8 and exits 1 (on macOS it aborts,
exit 134), and the report on standard error says where the freed block was
used, freed and allocated:

```text
ERROR: AddressSanitizer: heap-use-after-free ...
READ of size 8 ...
    #0 ... in main freed.tiko:8
freed by thread T0 here:
    #1 ... in main freed.tiko:7
previously allocated by thread T0 here:
    #1 ... in main freed.tiko:4
```

- **`-g` puts the line numbers in the report**; without it the report names
  procedures only.
- The same build stops a **double free**, a pointer past either end of an
  `allocate`d block or of a local array, and the **address of a local used
  after its procedure returned**.
- **`tiko build --profile asan`** builds a project this way: the built-in
  profile is `-g -exx -O1 -fsanitize=address`, into `out/asan/`.
- `__TIKO_ASAN__` is defined, as `1`, in a checked build.
- A checked program is slower and uses more memory. It is a build for finding
  bugs, not one to ship.

### Activities

1. Replace `delete reading` with two of them, and read the report.
2. Allocate `allocate( 4 * 4 )` bytes as a `long ptr` and write `p[4]`.
   Which line does the report name?
