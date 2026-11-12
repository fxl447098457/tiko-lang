[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **PathSeparator**

# PathSeparator

Returns the platform's path separator: a backslash on Windows, a slash on Linux and macOS.

## Syntax

```freebasic
PathSeparator( )
```

## Notes

- "\" or "/"

## Examples

```freebasic
#import "std/fs"
using fs

'' The native separator, as a string
print PathSeparator( )       '' \ on Windows, / elsewhere

'' Or ask for a grammar explicitly -- every Path* function takes the
'' same optional final argument
print PathSeparator( FB_PATH_POSIX )     '' /
print PathSeparator( FB_PATH_WIN32 )     '' \
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Paths
