[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **DataDir**

# DataDir

Returns the folder for user data files, such as AppData\Local or ~/.local/share.

## Syntax

```freebasic
DataDir( )
```

## Notes

- Windows: the LocalAppData known folder (C:\Users\name\AppData\Local), falling back to %LOCALAPPDATA%.
- Linux: $XDG_DATA_HOME when it is set and absolute, otherwise ~/.local/share.
- macOS: $XDG_DATA_HOME when it is set and absolute, otherwise ~/Library/Application Support.
- Nothing is created and no application name is added: it says where the directory SHOULD be, and the caller joins its own name and creates what it needs with CreateDirAll.

## Examples

```freebasic
#import "std/fs"
using fs

dim as FsResultUStr r = DataDir( )
if r.IsOk( ) then
    dim as ustring mine = PathJoin( r.Value( ), "myapp" )
    print PathIsAbsolute( mine )    '' true
    '' CreateDirAll( mine ) before writing anything there
else
    print r.Failure( ).Message( )
end if
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [Filesystem](Category-Filesystem)
**Documented under:** Directories
