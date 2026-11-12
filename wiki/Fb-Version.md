[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_VERSION__**

# __FB_VERSION__

Intrinsic define (macro string) set by the compiler

## Syntax

```freebasic
__FB_VERSION__
```

## Description

Substituted by the version number of the compiler where used.

## Remarks

### Differences from QB

- Did not exist in QB

### See also

- [`__FB_SIGNATURE__`](Fb-Signature)
- [`__FB_WIN32__`](Fb-Win32)
- [`__FB_LINUX__`](Fb-Linux)
- [`__FB_DARWIN__`](Fb-Darwin)
- [`__FB_DOS__`](Fb-Dos)

## Examples

```freebasic
#if __FB_VERSION__ < "0.18"

#error  Please compile With FB version 0.18 Or above

#endif
```

 This will stop the compilation if the compiler version is below 0.18

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
