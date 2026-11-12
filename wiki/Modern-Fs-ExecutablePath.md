[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **ExecutablePath**

# ExecutablePath

Returns the full path of the running program, however it was started.

## Syntax

```freebasic
ExecutablePath( )
```

## Notes

- Windows: GetModuleFileNameW of the program, however long. Linux: the target of /proc/self/exe. macOS: _NSGetExecutablePath, then realpath.
- Unlike COMMAND( 0 ), it does not depend on how the program was started, so it is the way to find files installed next to the program.

## Examples

```freebasic
#import "std/fs"
using fs

dim as ustring exe = ExecutablePath( ).ValueOr( "" )
print PathIsAbsolute( exe )      '' true
print IsFile( exe )              '' true
dim as ustring beside = PathJoin( PathParent( exe ), "settings.ini" )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [Filesystem](Category-Filesystem)
**Documented under:** Directories
