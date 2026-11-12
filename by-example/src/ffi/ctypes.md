# C types

Every parameter in a C declaration needs the tiko type with the same size and
meaning. Most C types have one tiko equivalent on every platform; two do not,
and that is what this example shows. It prints different answers on each
platform, and the difference is the point.

```tiko
{{#include ../../examples/ffi/ctypes.tiko}}
```

**Output** on Windows:

```text
{{#include ../../examples/ffi/ctypes.windows-x86_64.out}}
```

**Output** on Linux:

```text
{{#include ../../examples/ffi/ctypes.linux-x86_64.out}}
```

**Output** on macOS:

```text
{{#include ../../examples/ffi/ctypes.macos-arm64.out}}
```

| C | tiko |
|---|---|
| `char`, `unsigned char` | `byte`, `uint8` |
| `short`, `unsigned short` | `int16`, `uint16` |
| `int`, `unsigned int` | `int32`, `uint32` |
| `long long`, `unsigned long long` | `int64`, `uint64` |
| `float`, `double` | `float32`, `float64` |
| `size_t`, `intptr_t` | `uinteger`, `integer` |
| `T *`, `void *` | `T ptr`, `any ptr` |
| `const char *` | `const zstring ptr` |
| `long`, `unsigned long` | `clong`, `culong`, from `crt/long.bi` |
| `wchar_t *` | `wstring ptr` |

**C's `long` is 4 bytes on Windows and 8 on Linux and macOS.** `clong` and
`culong` follow the platform. **`wchar_t` is 2 bytes on Windows and 4 on Linux
and macOS**, and tiko's `wstring` follows the same rule, so a `wstring ptr` is a
`wchar_t *` everywhere.

```admonish danger title="Pitfall"
**`long` is not `int32`.** A C function returning `long` declared `as int32`
works on Windows, where the two agree, and loses the top half of every value
on Linux and macOS. Nothing complains.
```

`__FB_WIN32__`, `__FB_LINUX__` and `__FB_DARWIN__` are defined on their platforms, for the rare
declaration that must differ.

### Activities

1. Add a line for `short` and for `size_t`.
2. Declare C's `labs`, which takes and returns a `long`, using `clong`.
