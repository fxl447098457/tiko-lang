[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **StateDir**

# StateDir

Returns the folder for logs, history and recent files, such as ~/.local/state.

## Syntax

```freebasic
StateDir( )
```

## Notes

- Windows: the LocalAppData known folder, falling back to %LOCALAPPDATA%.
- Linux: $XDG_STATE_HOME when it is set and absolute, otherwise ~/.local/state.
- macOS: $XDG_STATE_HOME when it is set and absolute, otherwise ~/Library/Application Support.
- Nothing is created and no application name is added: it says where the directory SHOULD be, and the caller joins its own name and creates what it needs with CreateDirAll.

## Examples

```freebasic
#import "std/fs"
using fs

dim as FsResultUStr r = StateDir( )
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
