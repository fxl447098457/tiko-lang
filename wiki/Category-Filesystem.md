[Home](Home) › [All Categories](Categories) › **Filesystem**

# Filesystem

```freebasic
#import "std/fs"
using fs

print PathJoin( "C:\dev", "tiko", "src" )    ' C:\dev\tiko\src
print PathExtension( "frmMain.tiko" )         ' .tiko
print PathStem( ".gitignore" )               ' .gitignore -- no extension

dim as FsResultInfo info = Stat( "C:\dev\tiko" )
if( info.IsOk( ) ) then
    print info.Value( ).Size( ), info.Value( ).IsDirectory( )
else
    print info.Failure( ).Message( ), info.Failure( ).Path( )
end if

for each entry in WalkDir( "C:\dev\tiko" )
    if( entry.IsOk( ) ) then
        print entry.Value( ).Path( )
    else
        print "skipped: "; entry.Failure( ).Path( )
    end if
next
```

## Why It Exists

std/fs is tiko's filesystem library: paths, file information, directories and files, behind one import and with the same behaviour on windows-x86_64, linux-x86_64 and macos-arm64.

This page covers the filesystem and its paths. Reading and writing what is inside a file -- whole files, open files, streams and text -- is on [File Streams](Category-File-Streams).

**A complete path toolkit.** Paths are ordinary strings, and free functions take them apart and put them together: PathJoin, PathSplit, PathParent, PathFileName, PathStem, PathExtension, PathChangeExtension, PathNormalize, PathRelativeTo, PathEquals and more. Drive letters, UNC shares, `\\?\` prefixes and trailing separators are handled, so no program has to slice a path by hand.

**Everything about a file in one call.** Stat( p ) returns one FileInfo: whether it exists, which of the four kinds it is (file, directory, symbolic link or other), its size, its modified, created and accessed times, and its read-only and hidden flags -- all read together, in one call. LStat( p ) does the same without following a symbolic link.

**Directories you walk with FOR EACH.** ReadDir lists one directory and WalkDir a whole tree, and both plug straight into FOR EACH. Every walk keeps its own position, so two scans can run side by side or one inside the other. ListDir gives an eager, sortable listing when you want to change entries as you go.

**Whole files in one line.** ReadAllText, WriteAllText, WriteAtomic and the rest read or replace a file in one call; they, File and the streams are described on [File Streams](Category-File-Streams).

**Errors you cannot ignore by accident.** Every call that can fail returns a Result( of T, FsError ) carrying a code, a message and the path involved, and a default-constructed Result is a failure. Calls that cannot fail return their value directly, so the signature alone says which is which.

**Unicode paths everywhere.** Every entry point takes a USTRING, and STRING, ZSTRING and WSTRING convert to it, so names in any language work on every platform.

And beyond those: copying, moving and removing files and whole trees (CopyFile, CopyDir, MoveFile, CreateDirAll, RemoveDirAll), temporary files and directories created safely, glob patterns, links and permissions, volumes, advisory file locks, memory-mapped files and directory watching.

## Using It

One import pulls in everything:

```freebasic
#import "std/fs"
```

Everything belongs to the module `fs`, and a module is imported whole. Nothing is a keyword: Stat, ReadDir, CopyFile and the rest stay available as your own identifiers, because nothing is added to a program until it imports std/fs, and the bare names only after `using fs`. JoinPath, DirName, BaseName, Extension, IsAbsolute and Separator are exported macros, written qualified: `fs.JoinPath( a, b )`.

There is no Path type: paths are strings, and the path functions are free functions over them. Directory iteration follows the structural iterator protocol, which is what lets FOR EACH walk a directory.

This is a library, with no compiler support involved. The runtime half is in tiko-rt (lib/rt/src/fs/) and the tiko types in the std/fs module (pkg/std/fs/), whose files are fspath, fsinfo, fsdir, fsops, fsglob, fslink, fsvolume, fsadvanced and fserror.

## Errors

**Every fallible call returns a Result.** Every call that cannot fail returns its value directly. The split is visible in the signature, which is the point.

```freebasic
dim as FsResultUStr r = ReadAllText( "a.txt" )
if( r.IsOk( ) ) then
    print r.Value( )
else
    print r.Failure( ).Code( ), r.Failure( ).Message( )
end if
```

**A default-constructed Result is a failure**, so a forgotten assignment reads as an error rather than as a silent success. Reading the wrong side -- Value( ) on a failure, Failure( ) on a success -- raises FB_RTERROR_ILLEGALFUNCTIONCALL. IsOk( ) is the guard and costs nothing.

There is no `?` operator and no must-use diagnostic, so ignoring a Result stays a convention. What the type buys is that the failure has a name and a shape, not that you are forced to look at it.

### FsError

```text
.Code( )        FsErrorCode -- the portable code. Branch on this.
.OsCode( )      GetLastError( ) / errno, VERBATIM and unmapped. Zero when
                the library synthesised the error itself.
.Path( )        the path the call was operating on. Empty if none.
.Path2( )       the second path, for CopyFile / MoveFile / CreateSymlink.
.Operation( )   "CreateFileW", "unlink", "CopyDir". For diagnostics, NEVER
                for branching.
.Message( )     a fixed English one-liner derived from Code( ).
```

### FsErrorCode

Twenty-five codes plus FS_OK, closed on purpose:

```text
FS_OK                (never appears inside a failure)
FS_NOT_FOUND         no such file or directory
FS_ACCESS_DENIED     permission, or in use by policy
FS_ALREADY_EXISTS    create refused because the target is there
FS_NOT_A_DIRECTORY   a component that must be a directory is not
FS_IS_A_DIRECTORY    a directory where a file is required
FS_DIR_NOT_EMPTY     RemoveDir on a populated directory
FS_INVALID_PATH      malformed, or a character the OS refuses
FS_NAME_TOO_LONG     component or whole path exceeds the OS limit
FS_LOOP              too many symbolic links resolving one path
FS_NO_SPACE          the volume is full, or a quota is exhausted
FS_READ_ONLY         the volume or the object is write-protected
FS_IN_USE            a sharing violation, or the file is locked
FS_CROSS_DEVICE      rename across volumes
FS_INTERRUPTED       a signal interrupted the call (POSIX EINTR)
FS_UNSUPPORTED       the platform or filesystem cannot do this AT ALL
FS_UNKNOWN           mapped to nothing; OsCode( ) is the real answer
FS_CLOSED            an operation on a file that is not open
FS_UNEXPECTED_EOF    the data ended before the amount asked for
FS_NOT_SEEKABLE      a seek or positional IO on a pipe, socket or terminal
FS_INVALID_DATA      text decoding met data it was told to reject
FS_TOO_LARGE         a size limit was exceeded
FS_WOULD_BLOCK       a non-blocking attempt found the lock held
FS_TOO_MANY_LINKS    the hard-link limit was reached
FS_BROKEN_PIPE       a write to a pipe with no reader
FS_INVALID_ARGUMENT  contradictory options, a negative offset, a zero size
```

The codes after FS_UNKNOWN were added later and appended, so every code keeps its number.

**FS_UNSUPPORTED means this will never work here**, as distinct from FS_ACCESS_DENIED, which means try again with more privilege. A caller can branch on it once at startup instead of treating it as transient.

Message( ) is not FormatMessageW and not strerror. Those are locale-dependent, vary between Windows builds and libc versions, and produce text no test could assert. It is a fixed table, so the same code gives the same words on every machine. For the OS's own wording, use OsCode( ) and ask the OS.

### The Result Aliases

One per returned type:

```text
FsResultBool   FsResultLong   FsResultI64    FsResultUStr   FsResultStr
FsResultInfo   FsResultULong  FsResultSpace  FsResultVol    DirEntryResult
```

They are concrete typedefs rather than one generic alias because tiko has no generic typedef: `type FsResult( of T ) as ...` is read as the opening of a generic TYPE body and does not compile.

## Strings

**The kernel is USTRING.** Every entry point takes USTRING, and all four string types reach it: STRING, ZSTRING and WSTRING convert implicitly.

**The conversion is UTF-8, both ways, on every platform, and it is lossy:**

```text
STRING  -> USTRING    decoded as UTF-8; invalid bytes become U+FFFD
USTRING -> STRING     encoded as UTF-8
```

It is not the ANSI codepage, and it does not fail. A lone &hE9 -- what a Latin-1 or Windows-codepage string holds for 'e-acute' -- becomes U+FFFD silently, with no error and no way to detect it afterwards. That path will not open, and the library does not pretend otherwise. So **a Windows program holding an ANSI-codepage path in a STRING cannot use it here**: decode it to USTRING yourself first.

**Paths that came from the filesystem are USTRING, and should stay that way.** DirEntry.Name, ReadLink, CanonicalPath, CurrentDir and the rest return USTRING deliberately, and there are no STRING-returning versions -- adding them would offer a convenient, type-matching way to do the one thing this design exists to prevent. NTFS permits unpaired surrogates in file names; such a name does not survive a trip through STRING, which means afterwards you cannot open, delete or walk it.

The path functions are different, because they are pure string manipulation and nothing they touch came from the filesystem. They carry the full three-overload family and **return the width they were given**:

```text
string, zstring  ->  string
wstring, ustring ->  ustring
```

so `dim as string p = PathParent( someString )` involves no conversion at all.

## Paths

**Pure.** No syscalls, no filesystem access, no locale. Whether a path names anything is Stat's question. Every function takes an optional final `gram` argument selecting the path grammar; it defaults to the host's and ordinary code never passes it. It exists so the Windows rules can be tested on Linux and the POSIX rules on Windows.

### Decompose

```text
PathRoot( p )            "C:\", "\\srv\share\", "/", "" -- see below
PathParent( p )          "" for a root and for a single relative component
PathFileName( p )        the leaf; "" for a root
PathStem( p )            the leaf without its extension
PathExtension( p )       ".tiko", WITH the dot; "" when there is none
PathSplit( p, comps )    fills an Array( of ustring ); returns the count
```

### Compose

```text
PathJoin( a, b )         also 3- and 4-argument forms
PathChangeExtension( p, ext )    ext with or without its dot; "" removes
```

### Transform

```text
PathNormalize( p )       collapses '.', resolves '..' LEXICALLY, removes
                         duplicate separators and a trailing one
PathToNative( p )        separators to native, duplicates collapsed, but
                         NO '.' or '..' resolution
PathRelativeTo( p, base )        FsResultUStr
```

### Interrogate

```text
PathIsAbsolute( p )      see the Windows note below
PathIsRoot( p )          the whole path is exactly its root
PathRootLen( p )         length of the root prefix, in code units
PathHasExtension( p )
PathEquals( a, b )       normalized, case-insensitive on Windows
PathStartsWith( p, pre ) WHOLE COMPONENTS -- see below
PathNextComponent( p, gram, from, outlen )     the cursor PathSplit uses
PathSeparator( )         "\" or "/"
PathIsCaseSensitive( )   compile-time, per platform -- NOT per volume
```

### Components, Prefixes And Safety

```text
PathComponents( p [, gram ] )          for each -- PATH_PREFIX PATH_ROOT PATH_CURDIR PATH_PARENT PATH_NORMAL
PathComponentList( p, comps [, gram ] )   the same, into an Array( of PathComponent )
PathFilePrefix( p )                    "a.tar.gz" -> "a"     (PathStem gives "a.tar")
PathAddExtension( p, ext )             "a.tar" + "gz" -> "a.tar.gz"
PathIsLocal( p )                       safe to join under a directory, lexically
PathIsReserved( p )                    CON, NUL, COM1 ... under the Windows grammar
CanonicalPath( p, allowMissing )       canonical even when the end of it does not exist yet
```

**Join an untrusted name only after PathIsLocal.** PathJoin( base, name ) discards base when name is absolute, and a name with ".." can climb out of it; PathIsLocal rejects both, and reserved device names on Windows. It is lexical, so a symbolic link inside base can still lead elsewhere.

### The Eight Windows Path Forms

Three of them are where hand-rolled path code goes wrong:

| Path | Root | Absolute? |
| --- | --- | --- |
| `C:\dev\tiko` | `C:\` | **yes** |
| `C:dev\tiko` | `C:` | **no** |
| `\dev\tiko` | `\` | **no** |
| `dev\tiko` | (empty) | no |
| `\\srv\share\dev` | `\\srv\share\` | yes |
| `\\?\C:\dev` | `\\?\C:\` | yes |
| `\\?\UNC\srv\share\dev` | `\\?\UNC\srv\share\` | yes |
| `\\.\PhysicalDrive0` | `\\.\` | yes |

**Drive-relative `C:dev` is not absolute.** It names a path relative to the per-drive current directory, which Windows still maintains. It is not `C:\dev`, and treating it as such is a real bug with real consequences. PathRoot tells them apart by the trailing separator: `C:` versus `C:\`.

**Rooted-no-drive `\dev` is not absolute either.** It is on the current drive.

**Under `\\?\` the OS does no parsing at all.** `.` and `..` are ordinary names and `/` is not a separator, so PathNormalize deliberately leaves the interior of such a path alone -- collapsing it would change which file is named.

### The Path Rules

Each of these has a defensible opposite:

1. **PathJoin yields b when b is absolute or rooted**, discarding a. This matches Go, Python, Rust and .NET. It also makes `PathJoin( base, userInput )` a security consideration rather than a convenience -- if you need containment, check PathStartsWith afterwards.
2. PathJoin inserts exactly one separator and never a leading one. An empty argument contributes nothing.
3. **PathJoin does not normalize.** `PathJoin( "a/b", ".." )` is `"a/b/.."`. A join that quietly resolved `..` would be resolving it without knowing whether b is a symlink.
4. `PathNormalize( "" )` is `"."`. A root normalizes to itself.
5. **`..` clamps at a root** and never escapes it: `"/a/../.."` is `"/"`. A relative path has no root to clamp to, so leading `..` survive: `"a/../../b"` is `"../b"`.
6. PathParent of a root is `""`, and of a single relative component is `""`. A trailing separator does not create a phantom empty component.
7. PathFileName of a root is `""`.
8. **The extension is the final `.` in the file name**, and only when that dot is neither the first character of the name nor the last:

   ```text
   "a.tiko"      -> ".tiko"       "a.b.c"     -> ".c"
   ".gitignore"  -> ""            "a."        -> ""
   "C:\a.b\c"    -> ""
   ```

   A dotfile has no extension -- it is a name. `PathStem( ".gitignore" )` is `".gitignore"`. This matches Python, Rust and Go.
9. PathChangeExtension takes the new extension with or without its dot; `""` removes the extension including the dot.
10. **PathEquals compares normalized paths**, case-insensitively under the Windows grammar, treating `\` and `/` as equal there. It is a lexical answer: two paths naming one file through a symlink compare unequal. CanonicalPath is the call that answers identity.
11. **PathStartsWith compares whole components.** `C:\abc` does not start with `C:\ab`. Anything else would make it useless for the containment check rule 1 sends you here for.
12. PathSplit normalizes first and does not include the root. PathRoot joined with its components reconstructs PathNormalize exactly.
13. **PathRelativeTo fails with FS_INVALID_PATH when the two have different roots** -- different drives, one absolute and one relative, UNC versus local. There is no relative path between `C:\a` and `D:\b`, and returning `..\..\D:\b` would be a fabrication. Two equal paths give `"."`.
14. NUL is never valid in a path and is rejected everywhere.

**Normalize to build, canonicalize to compare identity.** PathNormalize resolves `..` lexically. If a/b is a symlink, a/b/.. is `/` to the OS but `a` here. Both answers are correct for their question, and resolving properly would mean hitting the disk from a pure function -- making it fallible, slow, and dependent on whether the path exists yet, which is exactly wrong for something whose main use is building a path before creating it.

## Metadata

```text
Stat( p )       FsResultInfo -- FOLLOWS symbolic links
LStat( p )      FsResultInfo -- does NOT follow

Exists( p )     boolean
IsFile( p )     boolean -- follows links
IsDir( p )      boolean -- follows links
TryExists( p )  FsResultBool -- follows links; fails when it cannot tell
```

**Absence is an error, not an empty success.** Stat and LStat fail with FS_NOT_FOUND, so FS_NOT_FOUND and FS_ACCESS_DENIED stay distinguishable. That is the whole argument for Result over Optional here.

**The three predicates collapse every failure to false.** Exists( p ) is false when p is absent and also when the directory above it denies access. That is a real loss of information and it is deliberate -- it is what makes them usable in an IF. So false means "could not confirm", not "does not exist". Call TryExists when you need the distinction: Ok( true ) when p is there, Ok( false ) only when it is absent (or a component of the path is a file), and a failure -- FS_ACCESS_DENIED, FS_LOOP -- when the answer is unknown. A dangling symbolic link is Ok( false ).

There is deliberately no IsSymlink( p ) predicate: the answer depends on whether you followed, a two-valued result cannot say which it did, and LStat( p ) is one line away.

### FileInfo

```text
.Exists( ) .IsFile( ) .IsDirectory( ) .IsSymlink( ) .IsOther( )
.Size( )                        uint64
.ModifiedUtc( )                 int64 -- ticks, see below
.CreatedUtc( ) .AccessedUtc( )
.HasCreated( ) .HasAccessed( )
.IsReadOnly( ) .IsHidden( )
.NativeAttributes( )            dwFileAttributes / st_mode
```

**The four kinds are exclusive and exhaustive.** Exactly one of IsFile, IsDirectory, IsSymlink and IsOther is true whenever Exists is true, and none is when it is false. IsOther covers devices, FIFOs, sockets and Windows reparse points that are not name surrogates -- things a program should notice and refuse rather than treat as files.

**IsSymlink is only ever true from LStat.** Stat follows, so it reports what the link points at; a Stat result with IsSymlink true would be a contradiction.

**Times are ticks of 100 ns since 0001-01-01 UTC** -- the same unit std/chrono uses, so the two libraries interoperate without conversion.

Not every platform has every time, and the library says so rather than inventing one:

| | Windows | Linux | macOS |
| --- | --- | --- | --- |
| Modified | always | always | always |
| Created | always | statx birth time, where available | always (the file's birth time) |
| Accessed | always | always | always |

HasCreated( ) and HasAccessed( ) report availability. When false the getter is exactly 0 and means nothing. There is no HasModified -- modification time is universal. st_ctime is the inode change time, not a birth time, and is deliberately not reported as CreatedUtc.

Access time is often stale on both platforms -- NTFS LastAccess updates are frequently disabled and Linux mounts default to relatime -- so a program that branches on AccessedUtc is building on sand.

IsReadOnly and IsHidden are the portable two, and they mean different things underneath:

| | Windows | Linux | macOS |
| --- | --- | --- | --- |
| IsReadOnly | FILE_ATTRIBUTE_READONLY | no write bit for this user | no write bit for this user |
| IsHidden | FILE_ATTRIBUTE_HIDDEN | the name begins with `.` | the name begins with `.` |

A dotfile is hidden on Linux and macOS and not on Windows. That divergence is real.

### Identity, Owner And Instants

```text
GetFileId( p [, followLinks ] )   FsResultId -- the volume and the file's number on it
SameFile( a, b )                  FsResultBool -- follows links; a missing path is a failure
File.Id( )                        the identity of an open file
FileInfo.Modified( ) .Created( ) .Accessed( )   the same times as chrono.Instant
FileInfo.HasOwner( ) .OwnerUid( ) .OwnerGid( )  POSIX
Chown( p, uid, gid ) / LChown( p, uid, gid )    POSIX; -1 leaves an id unchanged
SetTimes( p, modified, accessed )               with chrono.Instant
SetTimesNoFollow( p, ... )                      a symbolic link's own times
```

**A FileId is not a FileInfo field.** On Windows the file id needs an open handle, so Stat does not pay for it: ask with GetFileId or File.Id when you need to know whether two paths are one file.

**FileInfo's ticks are chrono.Instant's ticks** -- 100 ns since 0001-01-01 UTC -- so Modified( ), Created( ) and Accessed( ) convert nothing, and SetTimes takes an Instant directly.

### Resolvers

```text
AbsolutePath( p )     FsResultUStr
CanonicalPath( p )    FsResultUStr
CurrentDir( )         FsResultUStr
SetCurrentDir( p )    FsResultBool
```

| | AbsolutePath | CanonicalPath |
| --- | --- | --- |
| must exist | no | yes |
| resolves links | no | yes |
| `..` semantics | lexical | filesystem |
| use it to | build a path | compare identity |

AbsolutePath does not require the path to exist, which is the point -- the usual caller is about to create it. On Windows it delegates to GetFullPathNameW because "the relevant current directory" is not one thing: a drive-relative `C:foo` resolves against the per-drive current directory.

CanonicalPath on Windows returns a `\\?\`-prefixed path and strips the prefix unless the result exceeds MAX_PATH, where removing it would produce a path the OS cannot open. So **compare canonical paths with PathEquals, not with `=`**.

SetCurrentDir changes a process-global, so calling it from one thread races every other thread's relative paths. This library never calls it.

## Directories

```text
ReadDir( p )                    one level
WalkDir( p )                    recursive, pre-order
WalkDir( p, opts )
ListDir( p, entries )           eager; fills an Array( of DirEntry )
```

**Every iterator owns its own handle.** Nesting, recursion, two concurrent scans on one thread and scans on many threads are all simply correct.

```freebasic
for each r in ReadDir( "C:\dev" )
    if( r.IsOk( ) ) then
        print r.Value( ).Name( )
    else
        print "skipped: "; r.Failure( ).Message( )
    end if
next
```

**The element is a Result.** The iterator protocol has three members and none of them is an error channel, but a scan can fail partway -- permission denied, a device that went away. Making the failure an element puts it where the loop already looks. The cost is that every loop body unwraps; the alternative is a walk that lies about its coverage.

**Value( ) returns BYREF, and the reference is invalidated by the next MoveNext.** Copy the entry if you need to keep it.

`.` and `..` are never yielded -- not as an option, not ever.

**An unopenable directory yields exactly one element** -- the failure -- rather than looking like an empty directory.

### DirEntry

```text
.Name( )          the leaf
.Path( )          the full path, directly usable
.Depth( )         0 for the immediate children of the walk root
.IsFile( ) .IsDirectory( ) .IsSymlink( ) .IsOther( )
.Info( )          FsResultInfo -- MAY cost a stat
```

The kind predicates are free and LStat-shaped: a symlink reports IsSymlink, not the kind of its target. Info( ) is free on Windows, where the enumeration record already carries size, times and attributes, and costs one lstat on Linux and macOS, where dirent carries neither.

### WalkOptions

```text
                     default
.FollowSymlinks      FALSE
.YieldDirectories    TRUE
.IncludeHidden       TRUE
.StopOnError         FALSE
.MaxDepth            0 = unbounded
```

```freebasic
dim as WalkOptions o        ' constructed, so the TRUE defaults are set
o.MaxDepth = 1
for each r in WalkDir( root, o ) : ... : next
```

### Pruning, Order And Filters

```text
.Filter / .FilterUser     a WalkFilter returning WalkDecision bits, with your pointer
.ContentsFirst            FALSE; TRUE = a directory after what is in it
.SortByName               FALSE; TRUE = ordinal name order in every directory
WalkIterator.SkipChildren( )   do not enter the entry just yielded
```

**The filter sees every entry the walk reaches.** An entry is yielded only when the options and the filter both allow it, and walked into only when both do, so a filter can prune a directory that YieldDirectories = FALSE would never show. WALK_STOP ends the whole walk. A for each loop prunes this way; an explicit iterator loop can also call SkipChildren on the entry it was just given.

**ContentsFirst** is the order for a recursive delete: everything inside a directory comes before it. **SortByName** compares names code unit by code unit, so the order is the same everywhere.

### The Walk Rules

1. **Pre-order.** A directory is yielded before its contents.
2. **The root itself is not yielded.** Its immediate children are at depth 0.
3. **Directory symlinks are not followed** by default, and neither are Windows junctions and mount points. This makes the traversal a tree by construction: no cycle is possible and no visited set is needed. It is also what makes RemoveDirAll safe.
4. With FollowSymlinks a visited set becomes mandatory and is used. It is scoped to the current path, so a directory legitimately reachable twice by different routes is visited twice and only a genuine cycle is cut.
5. **Hidden entries are included** by default. Excluding them would silently omit .git and every hidden system directory. Go, Rust and Python all include them.
6. **Depth is unbounded** by default. MaxDepth = 1 yields only the immediate children.
7. **An error yields an element and the walk continues.** The failing subtree is skipped; everything else is still visited. StopOnError makes the failure the last thing yielded -- it is still yielded.
8. No directory handle is held across the descent; each level is listed and its handle closed. The walk cannot exhaust a handle limit.

**ListDir is eager and closes its handle before returning.** Use it for the two things the iterator cannot do: produce a sorted listing, and let you delete or rename entries while working through them. Mutating a directory's structure during iteration invalidates the iterator, and on Windows is explicitly undefined.

### Driving An Iterator By Hand

FOR EACH is the normal way, but the protocol types are public and can be driven directly -- which is what you want for two independent cursors over one directory, or to interleave two scans:

```text
DirRange       what ReadDir returns; .GetIterator( ) as DirIterator
WalkRange      what WalkDir returns; .GetIterator( ) as WalkIterator

DirIterator / WalkIterator
  .IsValid( )        still on an element?
  .Value( )          BYREF DirEntryResult -- see the warning above
  .MoveNext( )       advance
```

```freebasic
dim as DirIterator a = ReadDir( "C:\dev" ).GetIterator( )
while( a.IsValid( ) )
    if( a.Value( ).IsOk( ) ) then print a.Value( ).Value( ).Name( )
    a.MoveNext( )
wend
```

**A freshly returned iterator is already on the first element.** There is no before-the-first state, and MoveNext is not called before the first Value.

**The handle opens lazily**, on the first IsValid or Value. A copy taken before first use is therefore harmless -- which is the copy FOR EACH makes at loop entry. A copy taken mid-scan shares one cursor and is a bug. The destructor closes the handle if one was opened, including on EXIT FOR and while an error unwinds the scope.

## File Operations

### Creating And Removing Directories

```text
CreateDir( p )        fails with FS_ALREADY_EXISTS if the target is there
CreateDirAll( p )     mkdir -p; SUCCEEDS if it is already a directory
RemoveDir( p )        FS_DIR_NOT_EMPTY on a populated directory
RemoveDirAll( p )     rm -rf; FsResultI64, the number of objects removed
CopyDir( src, dst )   FsResultI64, the number created
CopyDir( src, dst, opts )
```

CreateDirAll tolerates another process creating the same tree concurrently: an FS_ALREADY_EXISTS on an intermediate component is re-checked and accepted if what is there is a directory. A file in the way is FS_NOT_A_DIRECTORY.

### Files

```text
CopyFile( src, dst [, overwrite ] )      overwrite defaults FALSE
MoveFile( src, dst [, overwrite ] )
RemoveFile( p )
```

### Atomic

```text
ReplaceFile( target, replacement )
WriteAtomic( p, s )
WriteAtomic( p, bytes )          Array( of ubyte ), written as given
```

What WriteAtomic guarantees is set out on [File Streams](Category-File-Streams#writeatomic).

### Temporary Files

```text
TempDir( )                       the system temp directory; creates nothing
CreateTempFile( [ prefix ] )     CREATES it and returns the path; prefix defaults to "tiko"
CreateTempDir( [ prefix ] )      CREATES it and returns the path; prefix defaults to "tiko"
```

### RemoveDirAll

Four rules, and the second and third are the most important destructive behaviour in the library:

1. It lists each directory whole before deleting anything in it, because deleting while enumerating is undefined.
2. **A symlink or junction inside the tree is unlinked, never descended.** This is what stops a recursive delete of a tree containing a link to `C:\` from doing what it sounds like.
3. **It cannot be raced into following a link.** Each directory is opened relative to its already-open parent and without following a link, and every deletion is made relative to an open directory, so a subdirectory swapped for a link while the removal runs is removed as that link. For the same reason **p itself a link is refused** with FS_NOT_A_DIRECTORY and nothing is deleted.
4. Read-only files are removed, as `rm -rf` does. Without that the call fails partway through a checked-out repository.

On failure it reports the first error and stops; it does not continue destructively past something it did not understand.

### CopyDir

**CopyDir refuses when the destination is inside the source**, with FS_INVALID_PATH. Without that check `CopyDir( "a", "a\b" )` never terminates. The check is lexical, because the destination usually does not exist yet and CanonicalPath requires that it does.

```text
CopyOptions          default
.PreserveTimestamps  FALSE
.PreservePermissions FALSE
.CopySymlinksAsLinks TRUE
.Overwrite           FALSE
```

**Without PreserveTimestamps the behaviour is platform-defined:** Windows CopyFileW carries the source's last-write time across on its own, and the POSIX read/write loop creates a file with the current time. If you care, pass the option. PreservePermissions is the platform's own model on each side -- POSIX mode bits or Windows attributes -- not a translation between them.

### MoveFile

**Without overwrite, MoveFile refuses an existing destination atomically** wherever the system can: Windows refuses in the rename itself, Linux uses renameat2 with RENAME_NOREPLACE and macOS renamex_np with RENAME_EXCL, or link-then-unlink on a filesystem without it. Only on a filesystem that supports neither (vfat, exFAT) does it fall back to checking first and renaming after, which is not atomic.

**MoveFile handles FS_CROSS_DEVICE.** On a cross-volume rename it copies, then deletes. If the delete then fails, the copy is not rolled back: the call reports the delete's error and the destination exists. Losing the destination to tidy up after a partial failure is worse than leaving both. The fallback is not atomic, and no API on any platform can make it so.

### CreateTempFile And CreateTempDir

They **create** the object and return its path. They do not hand back a name for you to create: that is the classic tmpnam race, where the window between choosing and creating is an attacker's opportunity. Creation is atomic and the names come from the platform CSPRNG, never from RND. **Neither is deleted automatically.**

## Glob

```text
MatchPattern( s, pattern )    boolean. PURE -- no syscalls.
Glob( pattern, results )      FsResultLong; fills Array( of ustring )
GlobRoot( pattern )           the directory a pattern will be walked from
PatternWildcardAt( pattern )  offset of the first wildcard, or -1
PatternIsRecursive( pattern ) does it contain a '**' component
```

### The Grammar

```text
?           exactly one character, NOT a separator
*           zero or more characters, NOT crossing a separator
**          zero or more WHOLE COMPONENTS, including none
[abc]       one character from the set
[a-z]       one from the range
[!abc]      one NOT in the set; [^abc] also works
\x          a literal x -- POSIX ONLY
```

### The Glob Rules

1. **`*` does not cross a separator.** `a*c` does not match `a/b/c`.
2. `**` is only special as a whole component. `a**b` is a single `*`.
3. **`**` matches zero components**, so `a/**/c` matches `a/c`. This is the most-missed glob behaviour anywhere.
4. Case follows the grammar: insensitive on Windows, sensitive on POSIX.
5. Separators are equivalent under the Windows grammar, so a pattern written with `/` matches a path written with `\`.
6. **There is no escape character on Windows**, because `\` is the separator. A literal `[` is matched there by the class `[[]`.
7. **A malformed class is a literal.** `[abc` matches those four characters. A glob that raised on a typo in a user-supplied pattern would be worse.
8. Matching is whole-string. There is no implicit `*` at either end.
9. The empty string is one empty component, so `*` matches `""`.

Glob splits the pattern at the last component with no wildcard and walks from there, so `C:\dev\tiko\src\*.tiko` walks src and not the whole volume. A pattern without `**` does a single ReadDir and never engages the walk.

**Results are not sorted** -- directory order is whatever the filesystem gives. **Errors during the walk are skipped:** this is the one place in the library that swallows one, because Glob returns an array and has nowhere to put a per-entry failure. It fails as a whole only when the walk root cannot be opened. If you need per-entry errors, use WalkDir with MatchPattern -- which is what Glob itself does.

**Hidden entries are matched.** Unlike a shell, `*` here matches a leading dot.

## Links And Permissions

```text
CreateSymlink( target, lnk [, targetIsDir ] )    FsResultBool
CreateHardLink( target, lnk )                    FsResultBool
ReadLink( lnk )                                  FsResultUStr
IsLink( p )                                      boolean
LinkCount( p )                                   FsResultULong
```

**Argument order is (target, link)** -- the thing that exists first, matching `ln -s`, symlink(2) and Python. It is the opposite of CreateSymbolicLinkW. Getting it backwards silently creates a dangling link pointing at the wrong place.

**targetIsDir is required on Windows and ignored on POSIX.** Windows encodes the target's kind in the link and needs it at creation time -- even when the target does not exist yet, which is exactly why it cannot be inferred. This is the ugliest portability seam in the library and it is not smoothable.

**On Windows, creating a symlink usually needs privilege:** expect FS_ACCESS_DENIED unless the process is elevated or Developer Mode is on.

ReadLink returns the target as stored -- unresolved, possibly relative, possibly dangling. It does not canonicalize; conflating the two would make a dangling link unreadable. FS_INVALID_PATH when the path is not a link, on both platforms. Junctions are readable but not creatable.

### Permissions

Three separate things, not one:

```text
SetReadOnly( p, v )              portable
SetHidden( p, v )                portable IN NAME ONLY
GetPosixMode( p ) / SetPosixMode( p, mode )      FS_UNSUPPORTED on Windows
GetWin32Attributes( p ) / SetWin32Attributes( p, attrs )
                                                FS_UNSUPPORTED on POSIX
SetTimes( p, mtimeUtc [, atimeUtc ] )           0 leaves one alone
```

The two platforms have no common core worth the name: POSIX has nine mode bits plus setuid/setgid/sticky, an owner and a group; Windows has attribute flags plus a full discretionary ACL. Mapping either onto the other produces something wrong in both directions.

SetReadOnly is genuinely portable, but **is not an exact inverse on POSIX** -- clearing restores the write bits subject to the current umask. Use GetPosixMode/SetPosixMode when you need exactness.

SetHidden is portable in name only: on POSIX hiddenness is a naming convention, so honouring it would mean renaming the file behind your back. It returns FS_UNSUPPORTED there instead.

**There is no owner, group or ACL API.** There is no portable subset beyond the read-only bit, and a partial ACL API is worse than none -- it invites code that looks portable and silently grants more than it meant to on one platform.

## User Directories

```text
HomeDir( )            the home directory
ConfigDir( )          user configuration         AppData\Roaming     $XDG_CONFIG_HOME  ~/.config
DataDir( )            user data                  AppData\Local       $XDG_DATA_HOME    ~/.local/share
CacheDir( )           files that can be rebuilt  AppData\Local       $XDG_CACHE_HOME   ~/.cache
StateDir( )           logs, history, recents     AppData\Local       $XDG_STATE_HOME   ~/.local/state
ExecutablePath( )     the running program's full path
ExpandHome( p )       a leading ~ replaced by HomeDir( )
```

Each returns an FsResultUStr without a trailing separator. **Nothing is created and no application name is added**: join your own name and CreateDirAll it before writing there. On Windows the answers come from the shell's known folders, falling back to the environment; on Linux and macOS an XDG variable is honoured only when it is an absolute path, and $HOME falls back to the passwd entry.

```freebasic
#import "std/fs"
using fs

dim as ustring cfg = PathJoin( ConfigDir( ).ValueOr( "." ), "myapp" )
CreateDirAll( cfg )
WriteAtomic( PathJoin( cfg, "settings.ini" ), "[main]" & chr( 10 ) )
```

## Volumes

```text
GetDiskSpace( p )      FsResultSpace
GetVolumeInfo( p )     FsResultVol
GetVolumes( vols )     FsResultLong; fills Array( of VolumeInfo )
```

p is any path on the volume, not a volume name. The path must exist.

### DiskSpace

```text
.TotalBytes        capacity
.FreeBytes         free, IGNORING quota -- for reporting
.AvailableBytes    free TO THIS USER -- the one to branch on
```

**AvailableBytes is the one to use.** FreeBytes counts space you may not be permitted to consume: reserved blocks on ext4, a per-user quota on any platform. Where there is no quota the two are equal, which is why the distinction is invisible on a developer machine and bites in production.

All three are snapshots and are stale on return. A program that checks free space and then writes is racing every other process on the machine; the write's FS_NO_SPACE is the real answer.

### VolumeInfo

```text
.RootPath          "C:\", "/", "\\srv\share\"
.Name              the label. MAY BE EMPTY -- always is on Linux and macOS
.FileSystem        "NTFS", "ext4", "exFAT". May be empty.
.MaxComponentLen
.IsReadOnly
.IsCaseSensitive
.SupportsLinks
```

**IsCaseSensitive is per-volume** and is not the same question as PathIsCaseSensitive( ), which is a compile-time per-platform constant. They disagree in two real cases: an NTFS directory with per-directory case sensitivity enabled (WSL sets this), and a case-insensitive filesystem mounted on Linux or, by default, on macOS. Use PathIsCaseSensitive for lexical comparison, which must be deterministic and must not do IO; use this one for "will these two names collide on this disk".

**SupportsLinks is asymmetric:** a FALSE is reliable, a TRUE is best-effort. Windows reports the filesystem's own flag; Linux and macOS have no portable probe, so everything but the FAT family and ISO 9660 is assumed able.

GetVolumes on Windows is the logical drives, skipping any reporting no media. On Linux there are no drives, only mount points, so it reads /proc/self/mountinfo and reports only filesystems backed by a real block device -- which filters proc, sysfs, cgroup and tmpfs. macOS has no drives either: it reads getmntinfo and applies the same rule. That is a judgement call: it will occasionally omit something you wanted, such as a network mount.

## Locking, Mapping And Watching

Three subsystems that share nothing but a file.

### FileLock

Advisory, whole-file:

```text
.Acquire( p [, exclusive ] [, timeoutMs ] )    FsResultBool
.Release( )
.IsHeld( )
```

timeoutMs below 0 waits indefinitely, 0 tries once, and above 0 gives up with FS_IN_USE. The destructor releases.

Only one cooperating process at a time gets past `Acquire`. The lock file is created if it does not exist:

```freebasic
#import "std/fs"
using fs

dim lk as FileLock
dim r as FsResultBool = lk.Acquire( "app.lock", true, 2000 )   ' exclusive; wait up to 2 s
if r.IsOk( ) then
    print "got the lock"
    ' ... the part only one cooperating process may run at a time ...
    lk.Release( )
else
    print "busy: "; r.Failure( ).Message( )
end if
```

FileLock holds a whole file against other processes. It is a different tool from the LOCK and UNLOCK statements, which lock byte ranges of a file already open on a file number.

**It is advisory everywhere, and that is the contract.** Windows LockFileEx is mandatory -- the kernel enforces it against every process. POSIX flock is advisory -- it binds only processes that also ask. The only promise every platform can keep is the weaker one, so **all participants must use this API**. Code written against the Windows behaviour silently protects nothing on Linux and macOS.

### MemoryMappedFile

```text
.Open( p [, writable ] )    FsResultBool
.Close( )
.Data( )                    uint8 ptr
.Size( )                    uint64
.IsOpen( )
.Flush( )                   FsResultBool
```

Count the lines of a file by reading the mapped bytes in place, without copying the file into memory:

```freebasic
#import "std/fs"
using fs

dim mm as MemoryMappedFile
if mm.Open( "data.txt" ).IsOk( ) then             ' read-only; Open( p, TRUE ) to write
    dim as uint8 ptr bytes = mm.Data( )
    dim as longint lines = 0
    for i as longint = 0 to mm.Size( ) - 1
        if bytes[i] = 10 then lines += 1           ' count line feeds, no copy made
    next
    print lines; " lines"
    mm.Close( )
end if
```

Data( ) is a raw pointer, which is the point -- the alternative is a copy, and a copy is ReadAllBytes. Three things no library can protect you from:

- the pointer is **invalid after Close** or destruction;
- **another process truncating the file turns reads into a fault** -- SIGBUS on POSIX, a structured exception on Windows -- not an error return, which is why mapping is not a drop-in replacement for reading;
- mapping a file on a network share is permitted, and is a good way to hang.

**A zero-length file cannot be mapped** and reports FS_INVALID_PATH on every platform, rather than handing back a pointer that cannot be dereferenced.

### FileWatcher

```text
.Start( p [, recursive ] )              FsResultBool
.Stop( )
.IsWatching( )
.Poll( changes, [ timeoutMs ] )         FsResultLong -- the count
```

FsChange:

```text
.Kind( )      FsChangeKind
.Path( )      the FULL path, not a bare leaf
```

FsChangeKind:

```text
FS_CHANGE_CREATED  FS_CHANGE_DELETED  FS_CHANGE_MODIFIED
FS_CHANGE_RENAMED_FROM  FS_CHANGE_RENAMED_TO  FS_CHANGE_OVERFLOW
```

Report what happens in a folder until a key is pressed. Each Poll refills the array with the changes since the last one:

```freebasic
#import "std/containers"
#import "std/fs"
using fs, containers

dim w as FileWatcher
if w.Start( "C:\dev\inbox" ).IsOk( ) then
    dim changes as Array( of FsChange )
    do
        if w.Poll( changes, 1000 ).IsOk( ) then      ' wait up to 1 s; refills changes
            for each c in changes
                select case c.Kind( )
                case FS_CHANGE_CREATED  : print "new:     "; c.Path( )
                case FS_CHANGE_MODIFIED : print "changed: "; c.Path( )
                case FS_CHANGE_DELETED  : print "gone:    "; c.Path( )
                case FS_CHANGE_OVERFLOW : print "too many changes -- rescan the folder"
                end select
            next
        end if
    loop until len( inkey ) > 0                       ' any key stops watching
    w.Stop( )
end if
```

**Polling, not callbacks.** A callback fires on the watcher's own thread, so every user immediately needs a queue and a lock and most get the threading wrong. Poll puts the events on your thread.

**A timeout is an empty success, not a failure** -- "nothing happened" and "the watch broke" are different answers.

**FS_CHANGE_OVERFLOW is an event, not an error.** Both platforms drop events under load, and every correct consumer must respond by rescanning. Modelling it as an error would let you ignore it.

**Renames are two events.** RENAMED_FROM and RENAMED_TO arrive as a pair, and a rename out of the watched tree produces only the first -- a single event carrying both paths could not represent that.

A single change may produce more than one event: writing a new file yields both CREATED and MODIFIED on Windows. Do not assume a count.

## The Rules That Are Easy To Get Wrong

- A default-constructed FsResult is a **failure**, not a success.
- Value( ) on a failure **raises**. IsOk( ) is the guard.
- Exists( ) is false for "denied" as well as "absent". Stat tells them apart.
- `C:dev` is **not** absolute. Neither is `\dev`.
- `.gitignore` has no extension; its stem is `.gitignore`.
- PathJoin **discards the left side** when the right is absolute -- check PathStartsWith if you need containment.
- PathEquals is lexical. Two paths naming one file through a symlink compare unequal.
- PathNormalize resolves `..` lexically, which is not what the OS does through a symlink.
- Compare canonical paths with PathEquals, not `=` -- because of the `\\?\` prefix.
- The walk's element is a Result. Unwrap it, or you are not checking.
- Value( ) byref dies at the next MoveNext. Copy to keep.
- WalkDir does not follow directory symlinks unless you ask.
- RemoveDirAll **unlinks** a directory symlink; it does not descend it.
- A STRING path is UTF-8 and lossy. ANSI-codepage paths do not work.
- Paths that came from the filesystem are USTRING. Keep them that way.
- There is no automatic `\\?\` prefixing: paths over MAX_PATH are refused on Windows, with FS_NAME_TOO_LONG and the native code preserved.
- Free space is a snapshot and is stale on return.
- A FileLock is **advisory**, even on Windows, as far as this API promises.

## What Is NOT Here

Each was considered and excluded:

- **Async, overlapped or promise-based IO.** Introducing an async model inside a filesystem library would be a language project wearing a library's clothes.
- **A Path value type.** Free functions over strings -- a Path type would have to pick one of STRING and USTRING and force a conversion at every boundary with the other. It remains additive later.
- **A virtual filesystem abstraction.** It needs an interface feature independent of inheritance, which tiko does not have.
- **Archives and compression.** Zip and tar are file formats, not filesystem operations, and share no code with this.
- **Recycle Bin / trash deletion.** Shell APIs, COM-dependent, no POSIX counterpart worth the name.
- **Extended attributes, alternate data streams, full ACLs.** No portable subset that means anything; NativeAttributes( ) is the escape hatch.
- **CreateJunction.** Junctions are readable but not creatable -- CreateSymlink with targetIsDir covers the portable need.
- **Checksums of files.** `hash.DigestFile` in [std/hash](Category-Hash) reads a file in blocks and returns its CRC-32 or SHA-256; `hash.HashStream` does the same for any `Stream`.

## Implementation

The tiko side, in pkg/std/fs/:

| File | Holds |
| --- | --- |
| fserror.tiko | FsError, the codes, the result aliases |
| fspath.tiko | the path family |
| fsinfo.tiko | FileInfo, Stat, the resolvers |
| fsdir.tiko | DirEntry, the iterators, ReadDir, WalkDir |
| fsops.tiko | whole-file, bulk, atomic, temp |
| fsglob.tiko | MatchPattern, Glob |
| fslink.tiko | links, permissions, SetTimes, CopyOptions |
| fsvolume.tiko | DiskSpace, VolumeInfo |
| fsadvanced.tiko | FileLock, MemoryMappedFile, FileWatcher |
| fs.tiko | the umbrella |

The runtime side, in tiko-rt's lib/rt/src/fs/:

| File | Holds |
| --- | --- |
| path.tiko | the path algebra: pure, portable, one copy, both grammars always compiled |
| glob.tiko | the matcher: pure, portable, iterative |
| text.tiko | the BOM and encoding rules, portable |
| errmsg.tiko | the message table |
| dirent.tiko | record-to-USTRING accessors, ABI size hooks |
| error, stat, dir, ops, link, volume, lock, mmap, watch (.tiko) | each split by platform with `#if` |

**The unit is FB_UCHAR (UTF-16), not FB_WCHAR**, which is 4 bytes on Linux and macOS -- building the kernel on it would silently change the path encoding depending on the host. Every struct crossing the C/tiko boundary uses fixed-width fields for the same reason: `unsigned long` is 4 bytes on Windows and 8 on Linux and macOS while tiko's ULONG is 32-bit everywhere, and getting that wrong shifts every field after it.

**The glob matcher is iterative, not recursive.** A recursive matcher on a hostile pattern such as `a*a*a*a*a*b` is exponential and will blow the stack.

**Platform code is split by `#if`, one file per area.** tiko-rt's build has no per-target source selection, so error, stat, dir, ops, link, volume, lock, mmap and watch each hold a Windows half and a POSIX half. The path and glob grammars are the exception -- they take the grammar as a parameter, so both are testable on either host.

## Tests

Nine fbcunit suites in tests/vendor/fbc-tests/filesystem/, and the fs-p run tests in tests/codegen/. The tests for files and streams are listed on [File Streams](Category-File-Streams#tests).

| Suite | Covers |
| --- | --- |
| fspath_core | one block per numbered path rule, every case run under both grammars regardless of host |
| fserror_codes | the tiko enum cross-checked against its C constants |
| fsinfo_dir | Stat, the kinds, and the interleaved-scan test |
| fsops_walk | the encoding rules, the bulk operations, the walk |
| fsglob | one block per glob rule, plus the pathological pattern |
| fslink | links, permissions, and the two destructive rules |
| fsvolume | invariants, plus the one ground-truth check |
| fsadvanced | locking, mapping, watching |
| fsstrings | the whole STRING overload layer |
| fs-p1 | the error codes added after FS_UNKNOWN, WriteAtomic's guarantees, MoveFile refusing an existing destination, TryExists |
| fs-p5 | FileId through hard and symbolic links, SameFile, File.Id, Instant round trips, owner and Chown, SetTimesNoFollow on a link |
| fs-p6 | walk order, filters, pruning and SkipChildren; components of every Windows prefix; PathIsLocal and PathIsReserved tables; CanonicalPath with a missing tail; CreateDirAll's mode |
| fs-p7 | the user directories against the platform's own answer, XDG overrides and the passwd fallback, ExecutablePath, ExpandHome |
| fs-p8 | RemoveDirAll's count, read-only files, a link inside the tree, p itself a link or a file, and a subdirectory swapped for a link to an outside sentinel while the removal runs |

The suites deliberately do not assert that a truncating writer faults a live mapping, nor cross-process lock exclusion.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Files and folders](Functions-Files) lists them beside the rest of the area.

### Check that a file or folder exists

| Function | What it does | From |
|---|---|---|
| [Exists](Modern-Fs-Exists) | Returns true if a file or folder is there; false also when access is denied. | `std/fs` |
| [IsFile](Modern-Fs-IsFile) | Returns true if the path is a file, following links; false if it cannot tell. | `std/fs` |
| [IsDir](Modern-Fs-IsDir) | Returns true if the path is a folder, following links; false if it cannot tell. | `std/fs` |
| [IsLink](Modern-Fs-IsLink) | Returns true if the path itself is a symbolic link. | `std/fs` |
| [TryExists](Modern-Fs-TryExists) | Returns whether a path exists, or fails when it cannot tell, as when access is denied. | `std/fs` |

### Build and take apart paths

| Function | What it does | From |
|---|---|---|
| [PathJoin](Modern-Fs-PathJoin) | Joins two to four path parts with one separator; an absolute part drops those before it. | `std/fs` |
| [PathParent](Modern-Fs-PathParent) | Returns the path without its last part, or an empty string for a root. | `std/fs` |
| [PathFileName](Modern-Fs-PathFileName) | Returns the last part of a path, the file name, or an empty string for a root. | `std/fs` |
| [PathStem](Modern-Fs-PathStem) | Returns the file name without its extension; a dotfile such as .gitignore keeps its name. | `std/fs` |
| [PathExtension](Modern-Fs-PathExtension) | Returns the extension with its dot, such as .tiko, or an empty string if there is none. | `std/fs` |
| [PathFilePrefix](Modern-Fs-PathFilePrefix) | Returns the file name up to its first dot, so a.tar.gz gives a. | `std/fs` |
| [PathHasExtension](Modern-Fs-PathHasExtension) | Returns true if the file name has an extension; a dotfile has none. | `std/fs` |
| [PathChangeExtension](Modern-Fs-PathChangeExtension) | Replaces a path's extension, or removes it when the new one is empty. | `std/fs` |
| [PathAddExtension](Modern-Fs-PathAddExtension) | Adds an extension after any already there, so a.tar becomes a.tar.gz. | `std/fs` |
| [PathSplit](Modern-Fs-PathSplit) | Splits a normalised path into its parts, without the root, in an Array; returns the count. | `std/fs` |
| [PathComponents](Modern-Fs-PathComponents) | Returns the parts of a path as written, drive and root included, for a for each loop. | `std/fs` |
| [PathComponent](Modern-Fs-PathComponent) | Holds one part of a path: its kind, such as root or parent, and its text. | `std/fs` |
| [PathNextComponent](Modern-Fs-PathNextComponent) | Finds the next part of a path from an offset; returns a negative number when none is left. | `std/fs` |
| [PathRoot](Modern-Fs-PathRoot) | Returns the root of a path, such as C:\ or /, or an empty string for a relative path. | `std/fs` |
| [PathRootLen](Modern-Fs-PathRootLen) | Returns the length of a path's root, in characters. | `std/fs` |
| [PathSeparator](Modern-Fs-PathSeparator) | Returns the platform's path separator: a backslash on Windows, a slash on Linux and macOS. | `std/fs` |

### Clean up, compare and resolve paths

| Function | What it does | From |
|---|---|---|
| [PathNormalize](Modern-Fs-PathNormalize) | Returns a tidied path: . removed, .. resolved as text, duplicate separators collapsed. | `std/fs` |
| [PathToNative](Modern-Fs-PathToNative) | Returns the path with the platform's separators, duplicates collapsed, nothing resolved. | `std/fs` |
| [PathRelativeTo](Modern-Fs-PathRelativeTo) | Returns a path relative to a base folder; fails if the two have different roots. | `std/fs` |
| [PathEquals](Modern-Fs-PathEquals) | Returns true if two paths match once normalised; case-insensitive on Windows. | `std/fs` |
| [PathStartsWith](Modern-Fs-PathStartsWith) | Returns true if a path begins with another, comparing whole parts, not characters. | `std/fs` |
| [PathIsAbsolute](Modern-Fs-PathIsAbsolute) | Returns true if a path needs no current folder; C:dev and \dev are not absolute. | `std/fs` |
| [PathIsRoot](Modern-Fs-PathIsRoot) | Returns true if the whole path is just a root, such as C:\ or /. | `std/fs` |
| [PathIsLocal](Modern-Fs-PathIsLocal) | Returns true if a relative path stays inside the folder it is joined to. | `std/fs` |
| [PathIsReserved](Modern-Fs-PathIsReserved) | Returns true if a part of the path is a Windows device name such as CON or NUL. | `std/fs` |
| [PathIsCaseSensitive](Modern-Fs-PathIsCaseSensitive) | Returns true if paths compare case-sensitively here: on Linux and macOS, not Windows. | `std/fs` |
| [AbsolutePath](Modern-Fs-FileInfo-AbsolutePath) | Returns the full form of a path against the current folder; the path need not exist. | `std/fs` |
| [CanonicalPath](Modern-Fs-FileInfo-CanonicalPath) | Returns the real path with links resolved; it must exist unless allowMissing is true. | `std/fs` |

### List and walk folders

| Function | What it does | From |
|---|---|---|
| [ReadDir](Modern-Fs-ReadDir) | Lists the entries of one folder for a for each loop; each entry may be a failure to check. | `std/fs` |
| [WalkDir](Modern-Fs-WalkDir) | Lists every entry under a folder, subfolders included, for a for each loop. | `std/fs` |
| [ListDir](Modern-Fs-ListDir) | Fills an Array with one folder's entries at once; returns the count. | `std/fs` |
| [DirEntry.Name](Modern-Fs-DirEntry-Name) | Returns the entry's name, without its folder. | `std/fs` |
| [DirEntry.Path](Modern-Fs-DirEntry-Path) | Returns the entry's full path, ready to open. | `std/fs` |
| [DirEntry.Depth](Modern-Fs-DirEntry-Depth) | Returns how deep the entry is in a walk, 0 for the children of the folder walked. | `std/fs` |
| [DirEntry.IsFile](Modern-Fs-DirEntry-IsFile) | Returns true if the entry is a file; a link reports as a link, not as its target. | `std/fs` |
| [DirEntry.IsDirectory](Modern-Fs-DirEntry-IsDirectory) | Returns true if the entry is a folder; a link to a folder reports as a link. | `std/fs` |
| [DirEntry.IsSymlink](Modern-Fs-DirEntry-IsSymlink) | Returns true if the entry is a symbolic link. | `std/fs` |
| [DirEntry.IsOther](Modern-Fs-DirEntry-IsOther) | Returns true if the entry is a device, pipe or socket rather than a file, folder or link. | `std/fs` |
| [DirEntry.Info](Modern-Fs-DirEntry-Info) | Returns the entry's FileInfo: free on Windows, one extra system call on Linux and macOS. | `std/fs` |

### Copy, move and delete files

| Function | What it does | From |
|---|---|---|
| [CopyFile](Modern-Fs-CopyFile) | Copies a file; fails if the destination exists unless overwrite is true. | `std/fs` |
| [MoveFile](Modern-Fs-MoveFile) | Moves or renames a file, even across volumes; refuses an existing destination by default. | `std/fs` |
| [RemoveFile](Modern-Fs-RemoveFile) | Deletes a file; fails if it is not there. | `std/fs` |
| [ReplaceFile](Modern-Fs-ReplaceFile) | Replaces one file with another in a single step, so the target is never missing. | `std/fs` |

### Create, copy and remove folders

| Function | What it does | From |
|---|---|---|
| [CreateDir](Modern-Fs-CreateDir) | Creates one folder; fails if something is already there. | `std/fs` |
| [CreateDirAll](Modern-Fs-CreateDirAll) | Creates a folder and any missing parents; succeeds if it already exists. | `std/fs` |
| [RemoveDir](Modern-Fs-RemoveDir) | Deletes an empty folder; fails if it still holds anything. | `std/fs` |
| [RemoveDirAll](Modern-Fs-RemoveDirAll) | Deletes a folder and all it holds without following links; returns how many it removed. | `std/fs` |
| [CopyDir](Modern-Fs-CopyDir) | Copies a folder and everything in it; returns how many entries it created. | `std/fs` |
| [CopyOptions.Overwrite](Modern-Fs-Overwrite) | Chooses whether CopyDir replaces files already at the destination; false by default. | `std/fs` |
| [CopyOptions.PreserveTimestamps](Modern-Fs-PreserveTimestamps) | Chooses whether CopyDir keeps each file's times; false by default. | `std/fs` |
| [CopyOptions.PreservePermissions](Modern-Fs-PreservePermissions) | Chooses whether CopyDir keeps permission bits or attributes; false by default. | `std/fs` |
| [CopyOptions.CopySymlinksAsLinks](Modern-Fs-CopySymlinksAsLinks) | Chooses whether CopyDir copies a link as a link rather than its target; true by default. | `std/fs` |

### Find standard folders and make temporary files

| Function | What it does | From |
|---|---|---|
| [TempDir](Modern-Fs-TempDir) | Returns the system's temporary folder; creates nothing. | `std/fs` |
| [CreateTempFile](Modern-Fs-CreateTempFile) | Creates a uniquely named temporary file and returns its path; it is not deleted for you. | `std/fs` |
| [CreateTempDir](Modern-Fs-CreateTempDir) | Creates a uniquely named temporary folder and returns its path; it is not deleted for you. | `std/fs` |
| [HomeDir](Modern-Fs-HomeDir) | Returns the user's home folder, without a trailing separator. | `std/fs` |
| [ConfigDir](Modern-Fs-ConfigDir) | Returns the folder for user settings, such as AppData\Roaming or ~/.config. | `std/fs` |
| [DataDir](Modern-Fs-DataDir) | Returns the folder for user data files, such as AppData\Local or ~/.local/share. | `std/fs` |
| [CacheDir](Modern-Fs-CacheDir) | Returns the folder for files that can be rebuilt, such as AppData\Local or ~/.cache. | `std/fs` |
| [StateDir](Modern-Fs-StateDir) | Returns the folder for logs, history and recent files, such as ~/.local/state. | `std/fs` |
| [ExecutablePath](Modern-Fs-ExecutablePath) | Returns the full path of the running program, however it was started. | `std/fs` |
| [ExpandHome](Modern-Fs-ExpandHome) | Returns a path with a leading ~ replaced by the user's home folder. | `std/fs` |
| [CurrentDir](Modern-Fs-FileInfo-CurrentDir) | Returns the program's current folder. | `std/fs` |
| [SetCurrentDir](Modern-Fs-FileInfo-SetCurrentDir) | Changes the program's current folder, for every thread at once. | `std/fs` |

### FileInfo: size, kind, times and flags

| Function | What it does | From |
|---|---|---|
| [Stat](Modern-Fs-Stat) | Returns a path's FileInfo, following symbolic links; fails if the path is missing. | `std/fs` |
| [LStat](Modern-Fs-LStat) | Returns a path's FileInfo without following a symbolic link, so a link describes itself. | `std/fs` |
| [FileInfo.Exists](Modern-Fs-FileInfo-Exists) | Returns true if the FileInfo describes something that exists. | `std/fs` |
| [FileInfo.IsFile](Modern-Fs-FileInfo-IsFile) | Returns true if the path is a regular file. | `std/fs` |
| [FileInfo.IsDirectory](Modern-Fs-FileInfo-IsDirectory) | Returns true if the path is a folder. | `std/fs` |
| [FileInfo.IsSymlink](Modern-Fs-FileInfo-IsSymlink) | Returns true if the path is a symbolic link; only ever true from LStat. | `std/fs` |
| [FileInfo.IsOther](Modern-Fs-FileInfo-IsOther) | Returns true if the path is a device, pipe or socket rather than a file, folder or link. | `std/fs` |
| [FileInfo.Size](Modern-Fs-FileInfo-Size) | Returns the size in bytes. | `std/fs` |
| [FileInfo.Modified](Modern-Fs-FileInfo-Modified) | Returns the last-write time as a chrono.Instant. | `std/fs` |
| [FileInfo.ModifiedUtc](Modern-Fs-FileInfo-ModifiedUtc) | Returns the last-write time in ticks of 100 ns since 0001-01-01 UTC. | `std/fs` |
| [FileInfo.Created](Modern-Fs-FileInfo-Created) | Returns the creation time as a chrono.Instant; check HasCreated first. | `std/fs` |
| [FileInfo.CreatedUtc](Modern-Fs-FileInfo-CreatedUtc) | Returns the creation time in ticks, or 0 when HasCreated is false. | `std/fs` |
| [FileInfo.Accessed](Modern-Fs-FileInfo-Accessed) | Returns the last-access time as a chrono.Instant; often not kept up to date. | `std/fs` |
| [FileInfo.AccessedUtc](Modern-Fs-FileInfo-AccessedUtc) | Returns the last-access time in ticks, or 0 when HasAccessed is false. | `std/fs` |
| [FileInfo.HasCreated](Modern-Fs-FileInfo-HasCreated) | Returns true if the platform records creation times, so Created means something. | `std/fs` |
| [FileInfo.HasAccessed](Modern-Fs-FileInfo-HasAccessed) | Returns true if the platform records access times, so Accessed means something. | `std/fs` |
| [FileInfo.IsReadOnly](Modern-Fs-FileInfo-IsReadOnly) | Returns true if unwritable: the read-only flag, or no write bit on Linux and macOS. | `std/fs` |
| [FileInfo.IsHidden](Modern-Fs-FileInfo-IsHidden) | Returns true if hidden: the hidden flag on Windows, a leading dot on Linux and macOS. | `std/fs` |
| [FileInfo.NativeAttributes](Modern-Fs-FileInfo-NativeAttributes) | Returns the raw attribute word: attributes on Windows, mode bits on Linux and macOS. | `std/fs` |
| [NativeAttributes](Modern-Fs-NativeAttributes) | Returns the raw attribute word: attributes on Windows, mode bits on Linux and macOS. | `std/fs` |
| [FileInfo.HasOwner](Modern-Fs-FileInfo-HasOwner) | Returns true if OwnerUid and OwnerGid are filled in: on Linux and macOS, not on Windows. | `std/fs` |
| [FileInfo.OwnerUid](Modern-Fs-FileInfo-OwnerUid) | Returns the owner's user id, or 0 unless HasOwner is true. | `std/fs` |
| [FileInfo.OwnerGid](Modern-Fs-FileInfo-OwnerGid) | Returns the owner's group id, or 0 unless HasOwner is true. | `std/fs` |

### Find files by pattern

| Function | What it does | From |
|---|---|---|
| [Glob](Modern-Fs-Glob) | Fills an Array with the paths that match a wildcard pattern; returns the count. | `std/fs` |
| [MatchPattern](Modern-Fs-MatchPattern) | Returns true if a string matches a wildcard pattern, without touching the disk. | `std/fs` |
| [GlobRoot](Modern-Fs-GlobRoot) | Returns the folder a pattern search starts from: the part before the first wildcard. | `std/fs` |
| [PatternWildcardAt](Modern-Fs-PatternWildcardAt) | Returns the offset of a pattern's first wildcard, or -1 if it has none. | `std/fs` |
| [PatternIsRecursive](Modern-Fs-PatternIsRecursive) | Returns true if a pattern has a double-star part that searches every subfolder. | `std/fs` |

### Control a folder walk

| Function | What it does | From |
|---|---|---|
| [WalkOptions.MaxDepth](Modern-Fs-DirEntry-MaxDepth) | Limits how deep a walk goes: 1 is the immediate children, 0 (the default) no limit. | `std/fs` |
| [WalkOptions.FollowSymlinks](Modern-Fs-DirEntry-FollowSymlinks) | Chooses whether a walk enters linked folders; false by default, so it cannot loop. | `std/fs` |
| [WalkOptions.YieldDirectories](Modern-Fs-DirEntry-YieldDirectories) | Chooses whether a walk returns folders as well as files; true by default. | `std/fs` |
| [WalkOptions.IncludeHidden](Modern-Fs-DirEntry-IncludeHidden) | Chooses whether a walk returns hidden entries; true by default. | `std/fs` |
| [WalkOptions.StopOnError](Modern-Fs-DirEntry-StopOnError) | Chooses whether a walk ends at its first error; false by default, so it carries on. | `std/fs` |
| [WalkOptions.ContentsFirst](Modern-Fs-DirEntry-ContentsFirst) | Chooses whether a walk returns each folder after its contents; false by default. | `std/fs` |
| [WalkOptions.SortByName](Modern-Fs-DirEntry-SortByName) | Chooses whether a walk lists each folder in name order; false by default. | `std/fs` |
| [WalkOptions.Filter](Modern-Fs-DirEntry-Filter) | Sets a function that decides, entry by entry, what a walk returns and what it enters. | `std/fs` |
| [WalkFilter](Modern-Fs-WalkFilter) | Holds the type of a walk filter: a function that says skip, yield, descend or stop. | `std/fs` |
| [WalkDecision](Modern-Fs-WalkDecision) | Holds a walk filter's answer: skip, yield, descend into, or stop after an entry. | `std/fs` |
| [WalkIterator.SkipChildren](Modern-Fs-WalkIterator-SkipChildren) | Skips the contents of the folder a walk has just returned. | `std/fs` |
| [DirIterator](Modern-Fs-DirEntry-DirIterator) | Holds the iterator ReadDir hands out, for stepping through a folder without for each. | `std/fs` |
| [WalkIterator](Modern-Fs-DirEntry-WalkIterator) | Holds the iterator WalkDir hands out, for stepping through a walk without for each. | `std/fs` |
| [DirIterator.IsValid](Modern-Fs-DirEntry-IsValid) | Returns true while the iterator is on an entry. | `std/fs` |
| [DirIterator.MoveNext](Modern-Fs-DirEntry-MoveNext) | Moves the iterator on to the next entry. | `std/fs` |
| [DirIterator.Value](Modern-Fs-DirEntry-Value) | Returns the current entry by reference; the next MoveNext makes it invalid. | `std/fs` |

### FsError: find out why a call failed

| Function | What it does | From |
|---|---|---|
| [FsError.Code](Modern-Fs-FsError-Code) | Returns the portable error code, such as FS_NOT_FOUND, to branch on. | `std/fs` |
| [FsError.Message](Modern-Fs-FsError-Message) | Returns a fixed one-line description of the error code. | `std/fs` |
| [FsError.Path](Modern-Fs-FsError-Path) | Returns the path the failed call was working on, or an empty string. | `std/fs` |
| [FsError.Path2](Modern-Fs-FsError-Path2) | Returns the second path of a failed copy, move or link call. | `std/fs` |
| [FsError.OsCode](Modern-Fs-FsError-OsCode) | Returns the operating system's own error number, or 0 if the library raised the error. | `std/fs` |
| [FsError.Operation](Modern-Fs-FsError-Operation) | Returns the name of the call that failed, for diagnostics only. | `std/fs` |

### Links, permissions and file identity

| Function | What it does | From |
|---|---|---|
| [CreateSymlink](Modern-Fs-CreateSymlink) | Creates a symbolic link to a target; on Windows this usually needs privilege. | `std/fs` |
| [CreateHardLink](Modern-Fs-CreateHardLink) | Gives an existing file a second name on the same volume. | `std/fs` |
| [ReadLink](Modern-Fs-ReadLink) | Returns the target a symbolic link points to, as stored; fails if it is not a link. | `std/fs` |
| [IsLink](Modern-Fs-IsLink) | Returns true if the path itself is a symbolic link. | `std/fs` |
| [LinkCount](Modern-Fs-LinkCount) | Returns how many hard links, or names, a file has. | `std/fs` |
| [GetFileId](Modern-Fs-GetFileId) | Returns the FileId of a path, which tells whether two paths are the same file. | `std/fs` |
| [SameFile](Modern-Fs-SameFile) | Returns whether two paths name the same file; fails if either is missing. | `std/fs` |
| [FileId](Modern-Fs-FileId) | Holds a volume and file number that are equal for every name of one file. | `std/fs` |
| [SetReadOnly](Modern-Fs-SetReadOnly) | Sets or clears a file's read-only flag, or its write bits on Linux and macOS. | `std/fs` |
| [SetHidden](Modern-Fs-SetHidden) | Sets or clears a file's hidden flag on Windows; fails as unsupported on Linux and macOS. | `std/fs` |
| [GetPosixMode](Modern-Fs-GetPosixMode) | Returns a file's permission bits on Linux and macOS; fails as unsupported on Windows. | `std/fs` |
| [SetPosixMode](Modern-Fs-SetPosixMode) | Sets a file's permission bits on Linux and macOS; fails as unsupported on Windows. | `std/fs` |
| [GetWin32Attributes](Modern-Fs-GetWin32Attributes) | Returns a file's raw Windows attribute flags; fails as unsupported on Linux and macOS. | `std/fs` |
| [SetWin32Attributes](Modern-Fs-SetWin32Attributes) | Replaces a file's whole Windows attribute word; fails as unsupported on Linux and macOS. | `std/fs` |
| [SetTimes](Modern-Fs-SetTimes) | Sets a file's modified and accessed times; a time of 0 leaves that one alone. | `std/fs` |
| [SetTimesNoFollow](Modern-Fs-SetTimesNoFollow) | Sets a symbolic link's own times, leaving its target alone. | `std/fs` |
| [Chown](Modern-Fs-Chown) | Changes a file's owner and group on Linux and macOS, -1 keeping one; fails on Windows. | `std/fs` |
| [LChown](Modern-Fs-LChown) | Changes a symbolic link's own owner and group, on Linux and macOS only. | `std/fs` |

### Disk space and volumes

| Function | What it does | From |
|---|---|---|
| [GetDiskSpace](Modern-Fs-GetDiskSpace) | Returns the total, free and available bytes of the volume a path is on. | `std/fs` |
| [DiskSpace.TotalBytes](Modern-Fs-DiskSpace-TotalBytes) | Returns the capacity of the volume in bytes. | `std/fs` |
| [DiskSpace.FreeBytes](Modern-Fs-DiskSpace-FreeBytes) | Returns the free bytes on the volume, ignoring quotas; the number to report. | `std/fs` |
| [DiskSpace.AvailableBytes](Modern-Fs-DiskSpace-AvailableBytes) | Returns the bytes this user may still write; the number to check before writing. | `std/fs` |
| [GetVolumeInfo](Modern-Fs-GetVolumeInfo) | Returns the VolumeInfo of the volume a path is on: its root, label and file system. | `std/fs` |
| [GetVolumes](Modern-Fs-GetVolumes) | Fills an Array with a VolumeInfo for each drive or mounted disk; returns the count. | `std/fs` |
| [VolumeInfo.RootPath](Modern-Fs-VolumeInfo-RootPath) | Returns where the volume is mounted, such as C:\ or /. | `std/fs` |
| [VolumeInfo.Name](Modern-Fs-VolumeInfo-Name) | Returns the volume's label, which may be empty and always is on Linux and macOS. | `std/fs` |
| [VolumeInfo.FileSystem](Modern-Fs-VolumeInfo-FileSystem) | Returns the file system's name, such as NTFS or ext4, or an empty string. | `std/fs` |
| [VolumeInfo.MaxComponentLen](Modern-Fs-VolumeInfo-MaxComponentLen) | Returns the longest file or folder name the volume allows, not the longest path. | `std/fs` |
| [VolumeInfo.IsReadOnly](Modern-Fs-VolumeInfo-IsReadOnly) | Returns true if the whole volume is read-only. | `std/fs` |
| [VolumeInfo.IsCaseSensitive](Modern-Fs-VolumeInfo-IsCaseSensitive) | Returns true if names on this volume are case-sensitive. | `std/fs` |
| [VolumeInfo.SupportsLinks](Modern-Fs-VolumeInfo-SupportsLinks) | Returns true if the volume can hold symbolic links; false is certain, true a best guess. | `std/fs` |

### Lock, map and watch files

| Function | What it does | From |
|---|---|---|
| [FileLock.Acquire](Modern-Fs-FileLock-Acquire) | Takes a lock on a file that cooperating programs share, waiting up to a timeout. | `std/fs` |
| [FileLock.Release](Modern-Fs-FileLock-Release) | Releases the lock; harmless when none is held. | `std/fs` |
| [FileLock.IsHeld](Modern-Fs-FileLock-IsHeld) | Returns true while this FileLock holds its lock. | `std/fs` |
| [MemoryMappedFile.Open](Modern-Fs-MemoryMappedFile-Open) | Maps a file into memory, read-only unless writable is true; an empty file fails. | `std/fs` |
| [MemoryMappedFile.Data](Modern-Fs-MemoryMappedFile-Data) | Returns a pointer to the mapped bytes, valid until Close. | `std/fs` |
| [MemoryMappedFile.Size](Modern-Fs-MemoryMappedFile-Size) | Returns the size of the mapped file in bytes. | `std/fs` |
| [MemoryMappedFile.Flush](Modern-Fs-MemoryMappedFile-Flush) | Writes changed mapped bytes to the disk now. | `std/fs` |
| [MemoryMappedFile.IsOpen](Modern-Fs-MemoryMappedFile-IsOpen) | Returns true while a file is mapped. | `std/fs` |
| [MemoryMappedFile.Close](Modern-Fs-MemoryMappedFile-Close) | Unmaps the file; harmless when nothing is mapped. | `std/fs` |
| [FileWatcher.Start](Modern-Fs-FileWatcher-Start) | Starts watching a folder for changes, subfolders too when recursive is true. | `std/fs` |
| [FileWatcher.Poll](Modern-Fs-FileWatcher-Poll) | Fills an Array with the changes seen since the last call, waiting up to a timeout. | `std/fs` |
| [FileWatcher.Stop](Modern-Fs-FileWatcher-Stop) | Stops watching; harmless when not watching. | `std/fs` |
| [FileWatcher.IsWatching](Modern-Fs-FileWatcher-IsWatching) | Returns true while the watcher is running. | `std/fs` |
| [FsChange.Kind](Modern-Fs-FsChange-Kind) | Returns what happened: created, deleted, modified, renamed, or overflow. | `std/fs` |
| [FsChange.Path](Modern-Fs-FsChange-Path) | Returns the full path of the entry that changed. | `std/fs` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
