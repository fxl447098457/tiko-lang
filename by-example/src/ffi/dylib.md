# Loading a library at run time

A library linked when the program is built must be present for the program to
start at all. **`dylibload`** opens a shared library while the program runs,
so the program can decide what to do when a plugin or an optional library is
missing.

```tiko
{{#include ../../examples/ffi/dylib.tiko}}
```

**Output**

```text
{{#include ../../examples/ffi/dylib.out}}
```

| Call | Does |
|---|---|
| `dylibload( name )` | opens the library and returns a handle, or `nullptr` |
| `dylibsymbol( handle, "name" )` | finds a function or variable by name and returns its address, or `nullptr` |
| `dylibfree( handle )` | closes the library |

Library names differ by platform: `name.dll` on Windows, `libname.so` on Linux,
often with a version number as in `libm.so.6`, and `libname.dylib` on macOS.
The example loads the C runtime's maths library on each, chosen with
`#if defined( TIKO_OS_WINDOWS )` and its `#elseif`s, and calls its `sqrt`.

`dylibsymbol` returns an untyped address. Assigning it to a variable of a
function pointer type, here `MathFn`, makes it callable, and that type is a
promise exactly as a `declare` is: nothing checks it. A plugin system usually
agrees on one entry point with a fixed signature, looks that up, and gets
everything else through it.

After `dylibfree`, every address taken from the library is invalid. Look a
symbol up once and keep the pointer while the library is open; the search
costs time.

### Activities

1. Look up `cbrt` as well and print the cube root of 27.
2. Make the program print a message and carry on when the library is
   missing, instead of ending.
