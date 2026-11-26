[Home](Home) › [All Categories](Categories) › **__TIKO_COMPILER__**

# __TIKO_COMPILER__

tiko defines `__TIKO_COMPILER__`, always `1`:

```freebasic
#ifdef __TIKO_COMPILER__
	print "tiko"; __TIKO_COMPILER__      '' tiko prints: tiko 1
#else
	print "not tiko"                     '' another compiler prints this
#endif
```

## Guarding tiko-only code

Test it with `#ifdef` or `defined( )`, so that a compiler which does not define it takes the other branch rather than stopping:

```freebasic
#import "std/containers"
#ifdef __TIKO_COMPILER__
	dim names as containers.Array( of ustring )  '' tiko builds this
#else
	dim names(0 to 63) as string         '' another compiler builds this
#endif
```

Comparing the VALUE is not a portable guard: `#if __TIKO_COMPILER__ = 1` fails on a compiler that does not define the name.

`__FB_MIN_VERSION__` is not defined by tiko, so `#if __FB_MIN_VERSION__( 1, 20, 0 )` is an error under tiko:

```
error TKO0308: invalid expression in '#if'
```

## Which operating system

tiko defines one `TIKO_OS_` name for the target being built, always `1`:

| Target | Defined | Not defined |
| --- | --- | --- |
| `windows-x86_64` | `TIKO_OS_WINDOWS` | `TIKO_OS_LINUX`, `TIKO_OS_MACOS`, `TIKO_OS_ANDROID` |
| `linux-x86_64` | `TIKO_OS_LINUX` | `TIKO_OS_WINDOWS`, `TIKO_OS_MACOS`, `TIKO_OS_ANDROID` |
| `linux-arm64` | `TIKO_OS_LINUX` | `TIKO_OS_WINDOWS`, `TIKO_OS_MACOS`, `TIKO_OS_ANDROID` |
| `macos-arm64` | `TIKO_OS_MACOS` | `TIKO_OS_WINDOWS`, `TIKO_OS_LINUX`, `TIKO_OS_ANDROID` |
| `android-x86_64`, `android-arm64` ([experimental](Android)) | `TIKO_OS_ANDROID` | `TIKO_OS_WINDOWS`, `TIKO_OS_LINUX`, `TIKO_OS_MACOS` |

Android is not Linux to tiko: its C library is not glibc, so `TIKO_OS_LINUX` is not defined there. Code meant for any Linux kernel tests both names.

The name follows `-target`, not the machine running the compiler, so `-target linux-x86_64` on Windows takes the Linux branch:

```freebasic
#ifdef TIKO_OS_WINDOWS
	print "windows"; TIKO_OS_WINDOWS     '' windows-x86_64 prints: windows 1
#elseif defined( TIKO_OS_LINUX )
	print "linux"; TIKO_OS_LINUX         '' linux-x86_64 and linux-arm64 print: linux 1
#elseif defined( TIKO_OS_MACOS )
	print "macos"; TIKO_OS_MACOS         '' macos-arm64 prints: macos 1
#else
	print "other"
#endif
```

Exactly one of the three is defined on every target.

## What tiko defines

| Define | tiko |
| --- | --- |
| `__TIKO_COMPILER__` | `1` |
| `__TIKO_VERSION__` | `"0.1.0-dev"` |
| `__FB_VERSION__` | `"1.20.0"` |
| `__FB_SIGNATURE__` | `"tiko-lang"` |
| `__FB_BACKEND__` | `"llvm"` |
| `__FB_MIN_VERSION__` | not defined |
| `TIKO_OS_WINDOWS` | `1` on `windows-x86_64`, otherwise not defined |
| `TIKO_OS_LINUX` | `1` on `linux-x86_64` and `linux-arm64`, otherwise not defined |
| `TIKO_OS_MACOS` | `1` on `macos-arm64`, otherwise not defined |
| `TIKO_OS_ANDROID` | `1` on `android-x86_64` and `android-arm64`, otherwise not defined |
| `__TIKO_ASAN__` | `1` when built with [`-fsanitize=address`](Compiler-Option-Fsanitize), otherwise not defined |
| `TIKO_ARCH_X86_64` | `1` on `windows-x86_64`, `linux-x86_64` and `android-x86_64`, otherwise not defined |
| `TIKO_ARCH_ARM64` | `1` on `linux-arm64`, `macos-arm64` and `android-arm64`, otherwise not defined |
| `__TIKO_CALLER_LOCATION__` | `1`: [`__CALLER_LINE__` and `__CALLER_FILE__`](Caller-Line) exist |

`__TIKO_COMPILER__` says **which compiler** is building; `__TIKO_VERSION__` says which version of it. Neither says which features it has, so code that must build with several versions still tests more than one symbol. `__TIKO_CALLER_LOCATION__` is one such feature test.

tests/pp/tiko-compiler-define.test holds the define and its value; tests/pp/tiko-target-defines.test holds the `TIKO_OS_` and `TIKO_ARCH_` names on each target.

### See also

- [Compatibility](Compatibility) — compatibility notes
- [Feature Index](Feature-Index) — the language features these guards protect
- [`__FB_VERSION__`](Fb-Version) · [`__FB_SIGNATURE__`](Fb-Signature) · [`__FB_BACKEND__`](Fb-Backend)
- [Intrinsic Defines](Category-Intrinsic-Defines) — the full list

---

**Category:** [__TIKO_COMPILER__](Category-Tiko-Compiler-Define)
**Kind:** intrinsic define
