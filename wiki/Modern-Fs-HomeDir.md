[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **HomeDir**

# HomeDir

Returns the user's home folder, without a trailing separator.

## Syntax

```freebasic
HomeDir( )
```

## Notes

- Windows: the Profile known folder (C:\Users\name), falling back to %USERPROFILE%.
- Linux and macOS: $HOME when it is set and absolute, otherwise the home directory in the user's passwd entry.
- Fails with FS_NOT_FOUND when there is no answer at all.

## Examples

```freebasic
#import "std/fs"
using fs

dim as ustring home = HomeDir( ).ValueOr( "" )
print IsDir( home )                              '' true
print cbool( PathJoin( home, ".myapprc" ) = ExpandHome( "~/.myapprc" ).ValueOr( "" ) )    '' true
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [Filesystem](Category-Filesystem)
**Documented under:** Directories
