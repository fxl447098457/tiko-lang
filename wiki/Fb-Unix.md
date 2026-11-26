[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_UNIX__**

# __FB_UNIX__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_UNIX__
```

## Description

Define created at compile time if the OS is reasonably enough like UNIX that you can call it UNIX, otherwise undefined.

## Remarks

In tiko this is `linux-x86_64`, `linux-arm64` and `macos-arm64`. tiko has no single name of its own for it: tiko code tests `defined( TIKO_OS_LINUX ) orelse defined( TIKO_OS_MACOS )` ([`TIKO_OS_`](Category-Tiko-Compiler-Define)).

### Differences from QB

- New to FreeBASIC

### See also

- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_FREEBSD__`](Fb-Freebsd)
- [`__FB_OPENBSD__`](Fb-Openbsd)
- [`__FB_NETBSD__`](Fb-Netbsd)
- [`__FB_CYGWIN__`](Fb-Cygwin)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_PCOS__`](Fb-Pcos)
- [`TIKO_OS_LINUX`](Category-Tiko-Compiler-Define)
- [Compiler Option: -target](Compiler-Option-Target)

## Examples

```freebasic
#ifdef __FB_UNIX__

  '...instructions for UNIX-family OSes...

#else

  '...instructions for other OSes

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
