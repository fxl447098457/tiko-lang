[Home](Home) › [Intrinsic Defines](Category-Intrinsic-Defines) › **__FB_ANDROID__**

# __FB_ANDROID__

Intrinsic define set by the compiler

## Syntax

```freebasic
__FB_ANDROID__
```

## Description

Define without a value created at compile time when targeting `android` platforms, when the `-target android` command line option is used. It can be used to compile parts of the program only for a such target.

## Remarks

In tiko, `__FB_ANDROID__` is defined with `-target android-x86_64` and `-target android-arm64` ([experimental](Android)), together with `__FB_UNIX__`; `__FB_LINUX__` is not. New tiko code tests [`TIKO_OS_ANDROID`](Category-Tiko-Compiler-Define) instead.

### Differences from QB

- New to FreeBASIC

### See also

- [Android](Android)
- [`TIKO_OS_ANDROID`](Category-Tiko-Compiler-Define)

## Examples

```freebasic
#ifdef __FB_ANDROID__

  '...instructions only for android target...

#else

  '...instructions not for android target...

#endif
```

---

**Category:** [Intrinsic Defines](Category-Intrinsic-Defines)  
**Kind:** keyword

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
