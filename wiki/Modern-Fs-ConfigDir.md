[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **ConfigDir**

# ConfigDir

Returns the folder for user settings, such as AppData\Roaming or ~/.config.

## Syntax

```freebasic
ConfigDir( )
```

## Notes

- Windows: the RoamingAppData known folder (C:\Users\name\AppData\Roaming), falling back to %APPDATA%.
- Linux: $XDG_CONFIG_HOME when it is set and absolute, otherwise ~/.config. A relative XDG value is ignored, as the XDG specification requires.
- macOS: $XDG_CONFIG_HOME when it is set and absolute, otherwise ~/Library/Application Support.
- Nothing is created and no application name is added: it says where the directory SHOULD be, and the caller joins its own name and creates what it needs with CreateDirAll.

## Examples

```freebasic
#import "std/fs"
using fs

dim as FsResultUStr r = ConfigDir( )
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
