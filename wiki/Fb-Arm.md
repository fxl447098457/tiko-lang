[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_ARM__**

# __FB_ARM__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_ARM__
```

## Description

Define created at compile time if the compilation target uses the ARM CPU architecture, otherwise undefined. In tiko that is the `linux-arm64` and `macos-arm64` targets.

## Remarks

[`TIKO_ARCH_ARM64`](Category-Tiko-Compiler-Define) is tiko's own name for the same test; tiko code uses it.

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_X86__`](Fb-X86)
- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_FREEBSD__`](Fb-Freebsd)
- [`__FB_OPENBSD__`](Fb-Openbsd)
- [`__FB_NETBSD__`](Fb-Netbsd)
- [`__FB_CYGWIN__`](Fb-Cygwin)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_PCOS__`](Fb-Pcos)
- [`TIKO_ARCH_ARM64`](Category-Tiko-Compiler-Define)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_ARM__

  '...instructions for ARM OSes...

#else

  '...instructions for other OSes

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
