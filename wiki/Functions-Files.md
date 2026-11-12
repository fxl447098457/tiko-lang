[Home](Home) › [Function Finder](Function-Finder) › **Files and folders**

# Files and folders

The functions to read and write files, build paths, list and walk directories, grouped by what you want to do. The **From** column says what a program needs before it can call one:

- **built-in**: nothing; it is always available.
- `std/config`: `#import "std/config"`, then `using config` to call it by its bare name.
- `std/fs`: `#import "std/fs"`, then `using fs` to call it by its bare name.

Jump to: [Read or write a whole file](#read-or-write-a-whole-file) · [Check that a file or folder exists](#check-that-a-file-or-folder-exists) · [Build and take apart paths](#build-and-take-apart-paths) · [Clean up, compare and resolve paths](#clean-up-compare-and-resolve-paths) · [List and walk folders](#list-and-walk-folders) · [Copy, move and delete files](#copy-move-and-delete-files) · [Create, copy and remove folders](#create-copy-and-remove-folders) · [Find standard folders and make temporary files](#find-standard-folders-and-make-temporary-files) · [FileInfo: size, kind, times and flags](#fileinfo-size-kind-times-and-flags) · [File numbers: open and close files](#file-numbers-open-and-close-files) · [File numbers: read, write and seek](#file-numbers-read-write-and-seek) · [Read and write text a line at a time](#read-and-write-text-a-line-at-a-time) · [File: open a file and work in place](#file-open-a-file-and-work-in-place) · [Read and write fixed-size records](#read-and-write-fixed-size-records) · [Streams: read and write bytes](#streams-read-and-write-bytes) · [Find files by pattern](#find-files-by-pattern) · [Control a folder walk](#control-a-folder-walk) · [FsError: find out why a call failed](#fserror-find-out-why-a-call-failed) · [Links, permissions and file identity](#links-permissions-and-file-identity) · [Disk space and volumes](#disk-space-and-volumes) · [Lock, map and watch files](#lock-map-and-watch-files) · [Open devices, pipes and the console](#open-devices-pipes-and-the-console) · [Read and write settings files: TOML and INI](#read-and-write-settings-files-toml-and-ini)

## Read or write a whole file

| Function | What it does | From |
|---|---|---|
| [ReadAllText](Modern-Fs-ReadAllText) | Reads a whole file as UTF-8 text into a string, or fails if it cannot be read. | `std/fs` |
| [ReadAllLines](Modern-Fs-ReadAllLines) | Reads a file's lines into an Array, without their line endings; returns the count. | `std/fs` |
| [ReadAllBytes](Modern-Fs-ReadAllBytes) | Reads a whole file into an Array of bytes; returns the number read. | `std/fs` |
| [WriteAllText](Modern-Fs-WriteAllText) | Writes a string to a file as UTF-8, creating the file or replacing it. | `std/fs` |
| [WriteAllBytes](Modern-Fs-WriteAllBytes) | Writes an Array of bytes to a file, creating the file or replacing it. | `std/fs` |
| [AppendAllText](Modern-Fs-AppendAllText) | Adds text to the end of a file, creating the file if it is not there. | `std/fs` |
| [AppendAllBytes](Modern-Fs-AppendAllBytes) | Adds an Array of bytes to the end of a file, creating the file if it is not there. | `std/fs` |
| [WriteAtomic](Modern-Fs-WriteAtomic) | Replaces a file so a reader sees the old or the new contents, never a half-written file. | `std/fs` |

## Check that a file or folder exists

| Function | What it does | From |
|---|---|---|
| [Exists](Modern-Fs-Exists) | Returns true if a file or folder is there; false also when access is denied. | `std/fs` |
| [IsFile](Modern-Fs-IsFile) | Returns true if the path is a file, following links; false if it cannot tell. | `std/fs` |
| [IsDir](Modern-Fs-IsDir) | Returns true if the path is a folder, following links; false if it cannot tell. | `std/fs` |
| [IsLink](Modern-Fs-IsLink) | Returns true if the path itself is a symbolic link. | `std/fs` |
| [TryExists](Modern-Fs-TryExists) | Returns whether a path exists, or fails when it cannot tell, as when access is denied. | `std/fs` |

## Build and take apart paths

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

## Clean up, compare and resolve paths

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

## List and walk folders

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

## Copy, move and delete files

| Function | What it does | From |
|---|---|---|
| [CopyFile](Modern-Fs-CopyFile) | Copies a file; fails if the destination exists unless overwrite is true. | `std/fs` |
| [MoveFile](Modern-Fs-MoveFile) | Moves or renames a file, even across volumes; refuses an existing destination by default. | `std/fs` |
| [RemoveFile](Modern-Fs-RemoveFile) | Deletes a file; fails if it is not there. | `std/fs` |
| [ReplaceFile](Modern-Fs-ReplaceFile) | Replaces one file with another in a single step, so the target is never missing. | `std/fs` |

## Create, copy and remove folders

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

## Find standard folders and make temporary files

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

## FileInfo: size, kind, times and flags

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

## File numbers: open and close files

| Function | What it does | From |
|---|---|---|
| [Open](Open) | Opens a file on a file number for reading or writing text, bytes or records. | built-in |
| [FreeFile](Freefile) | Returns an unused file number for Open, or 0 if all 255 are taken. | built-in |
| [Close](Close) | Closes one or more file numbers, or every open file when given none. | built-in |
| [Reset](Reset) | Closes every open file, or resets a redirected standard input or output stream. | built-in |
| [Input](Input-File-Mode) (file mode) | Opens a text file for reading with Open; the file must already exist. | built-in |
| [Output](Output) | Opens a text file for writing with Open, creating it or emptying it first. | built-in |
| [Append](Append) | Opens a text file with Open to add to its end, creating the file if needed. | built-in |
| [Binary](Binary) | Opens a file with Open for reading and writing bytes at any position. | built-in |
| [Random](Random) | Opens a file with Open for reading and writing fixed-size records, 128 bytes by default. | built-in |
| [Access](Access) | Limits a Binary or Random file in Open to reading, writing, or both. | built-in |
| [Read](Read-File-Access) (access) | Opens a Binary or Random file for reading only, in an Access clause. | built-in |
| [Write](Write-File-Access) (access) | Opens a Binary or Random file for writing only; an existing file is emptied first. | built-in |
| [Read Write](Read-Write-File-Access) (access) | Opens a Binary or Random file for both reading and writing, the default. | built-in |
| [Encoding](Encoding) | Sets the Unicode encoding of a text file in Open; a file read this way needs a BOM. | built-in |

## File numbers: read, write and seek

| Function | What it does | From |
|---|---|---|
| [Print #](procedures-Print) | Writes values as text to an open file; a trailing comma or semicolon skips the line break. | built-in |
| [Write #](procedures-Write) | Writes values to a file as comma-separated text, strings in quotes, for Input # to read. | built-in |
| [Input #](Input) | Reads comma- or line-separated values from a text file into variables. | built-in |
| [Line Input #](Line-Input) | Reads one line of a text file into a string, without its line ending. | built-in |
| [Get #](Get-File-I-O) | Reads a variable, string or array from a file as bytes, at a position or the current one. | built-in |
| [Put #](Put-File-I-O) | Writes a variable, string or array to a file as bytes, at a position or the current one. | built-in |
| [EOF](Eof) | Returns true when an open file has nothing left to read. | built-in |
| [LOF](Lof) | Returns the length in bytes of an open file. | built-in |
| [LOC](Loc) | Returns where the last read or write happened in an open file, counted in records. | built-in |
| [Seek](Seek-Function) (function) | Returns the 1-based position of the next read or write: bytes, or records for Random. | built-in |
| [Seek](Seek-Statement) (statement) | Sets the 1-based position of the next read or write: bytes, or records for Random. | built-in |
| [Lock](Lock) | Restricts other programs' access to a record or byte range of an open file. | built-in |
| [Unlock](Unlock) | Removes a restriction that Lock put on a record or byte range. | built-in |

## Read and write text a line at a time

| Function | What it does | From |
|---|---|---|
| [ReadLines](Modern-Fs-ReadLines) | Reads a file a line at a time in a for each loop, never holding the whole file in memory. | `std/fs` |
| [TextReader](Modern-Fs-TextReader) | Holds a reader that decodes lines and text from any Stream, in UTF-8 or UTF-16. | `std/fs` |
| [TextReader.ReadLine](Modern-Fs-TextReader-ReadLine) | Reads the next decoded line into a string; returns false at the end. | `std/fs` |
| [TextReader.ReadToEnd](Modern-Fs-TextReader-ReadToEnd) | Appends all the remaining decoded text to a string. | `std/fs` |
| [TextReader.Encoding](Modern-Fs-TextReader-Encoding) | Returns the encoding found at the start: utf-8, utf-16le or utf-16be. | `std/fs` |
| [TextErrorMode](Modern-Fs-TextErrorMode) | Holds what a TextReader does with invalid UTF-8: replace it or fail. | `std/fs` |
| [TextWriter](Modern-Fs-TextWriter) | Holds a writer that sends text to any Stream as UTF-8, with an optional BOM. | `std/fs` |
| [TextWriter.WriteLine](Modern-Fs-TextWriter-WriteLine) | Writes a string followed by the writer's NewLine. | `std/fs` |

## File: open a file and work in place

| Function | What it does | From |
|---|---|---|
| [File](Modern-Fs-File) | Holds an open file: a Stream over a handle it owns and closes when it goes out of scope. | `std/fs` |
| [File.Open](Modern-Fs-File-Open) | Opens a file the way an OpenOptions says: read, write, append, create and more. | `std/fs` |
| [File.OpenRead](Modern-Fs-File-OpenRead) | Opens an existing file for reading only. | `std/fs` |
| [File.Create](Modern-Fs-File-Create) | Opens a file for writing, creating it or emptying it first. | `std/fs` |
| [File.CreateNew](Modern-Fs-File-CreateNew) | Creates a new file for writing; fails if one is already there. | `std/fs` |
| [File.OpenAppend](Modern-Fs-File-OpenAppend) | Opens a file so every write goes to its end, creating it if needed. | `std/fs` |
| [File.OpenTemp](Modern-Fs-File-OpenTemp) | Creates and opens a new, randomly named file in a folder or the temporary folder. | `std/fs` |
| [File.Close](Modern-Fs-File-Close) | Closes the file and reports any error the close itself raised. | `std/fs` |
| [File.IsOpen](Modern-Fs-File-IsOpen) | Returns true if the File has a file open. | `std/fs` |
| [File.Path](Modern-Fs-File-Path) | Returns the path the file was opened with. | `std/fs` |
| [File.ReadAt](Modern-Fs-File-ReadAt) | Reads up to n bytes at an offset without moving the position. | `std/fs` |
| [File.WriteAt](Modern-Fs-File-WriteAt) | Writes bytes at an offset without moving the position; refused in append mode. | `std/fs` |
| [File.Size](Modern-Fs-File-Size) | Returns the open file's current size in bytes. | `std/fs` |
| [File.SetSize](Modern-Fs-File-SetSize) | Truncates the file to a size, or extends it with zero bytes. | `std/fs` |
| [File.Sync](Modern-Fs-File-Sync) | Forces the file's data and metadata onto the disk, so a write survives a power cut. | `std/fs` |
| [File.SyncData](Modern-Fs-File-SyncData) | Forces the file's data onto the disk; can be cheaper than Sync on Linux. | `std/fs` |
| [File.Stat](Modern-Fs-File-Stat) | Returns the open file's FileInfo, read from the handle even if the file was renamed. | `std/fs` |
| [File.Lock](Modern-Fs-File-Lock) | Locks the whole file, waiting until it is free: exclusive by default, or shared. | `std/fs` |
| [File.TryLock](Modern-Fs-File-TryLock) | Locks the whole file if it is free, or fails at once if another holder has it. | `std/fs` |
| [File.Unlock](Modern-Fs-File-Unlock) | Releases this handle's lock; succeeds when none is held. | `std/fs` |
| [File.Id](Modern-Fs-File-Id) | Returns the FileId of the open file, still right after a rename. | `std/fs` |
| [File.NativeHandle](Modern-Fs-File-NativeHandle) | Returns the operating-system handle or descriptor, or -1 when closed. | `std/fs` |
| [OpenOptions](Modern-Fs-OpenOptions) | Holds the flags that say how File.Open opens a file: read, write, create, share and more. | `std/fs` |
| [OpenOptionsRead](Modern-Fs-OpenOptionsRead) | Returns the OpenOptions for reading a file that must already exist. | `std/fs` |
| [OpenOptionsWrite](Modern-Fs-OpenOptionsWrite) | Returns the OpenOptions for writing a new file or an existing one emptied. | `std/fs` |
| [OpenOptionsAppend](Modern-Fs-OpenOptionsAppend) | Returns the OpenOptions for adding to the end of a file, creating it if needed. | `std/fs` |

## Read and write fixed-size records

| Function | What it does | From |
|---|---|---|
| [RecordFile](Modern-Fs-RecordFile) | Holds a file of fixed-size records of one type, read and written by number. | `std/fs` |
| [RecordFile.Open](Modern-Fs-RecordFile-Open) | Opens a file of records for reading and writing, creating it if it is missing. | `std/fs` |
| [RecordFile.GetRecord](Modern-Fs-RecordFile-GetRecord) | Reads record n into a variable; false when the file has no such record. | `std/fs` |
| [RecordFile.PutRecord](Modern-Fs-RecordFile-PutRecord) | Writes a variable as record n, growing the file when n is past the end. | `std/fs` |
| [RecordFile.Append](Modern-Fs-RecordFile-Append) | Writes a variable after the last record and returns its record number. | `std/fs` |
| [RecordFile.Count](Modern-Fs-RecordFile-Count) | Returns the number of whole records in the file. | `std/fs` |
| [ReadRecord](Modern-Fs-ReadRecord) | Reads record n of a type from an open File, counting records from 1. | `std/fs` |
| [WriteRecord](Modern-Fs-WriteRecord) | Writes a value as record n of an open File, growing the file if needed. | `std/fs` |
| [RecordCount](Modern-Fs-RecordCount) | Returns the number of whole records of a type in an open File. | `std/fs` |

## Streams: read and write bytes

| Function | What it does | From |
|---|---|---|
| [Stream](Modern-Fs-Stream) | Holds the base type of every byte stream, with read, write, seek and flush. | `std/fs` |
| [Stream.Read](Modern-Fs-Stream-Read) | Reads up to n bytes and returns how many; 0 means the end of the data. | `std/fs` |
| [Stream.ReadExact](Modern-Fs-Stream-ReadExact) | Reads exactly n bytes, or fails if the data ends first. | `std/fs` |
| [Stream.ReadToEnd](Modern-Fs-Stream-ReadToEnd) | Appends every remaining byte to an Array; returns how many. | `std/fs` |
| [Stream.Write](Modern-Fs-Stream-Write) | Writes up to n bytes and returns how many it wrote, which may be fewer. | `std/fs` |
| [Stream.WriteAll](Modern-Fs-Stream-WriteAll) | Writes all n bytes, calling Write as often as it takes. | `std/fs` |
| [Stream.WriteBytes](Modern-Fs-Stream-WriteBytes) | Writes every byte of an Array. | `std/fs` |
| [Stream.WriteUtf8](Modern-Fs-Stream-WriteUtf8) | Writes a string as UTF-8, with no BOM. | `std/fs` |
| [Stream.WriteText](Modern-Fs-Stream-WriteText) | Writes a string in a text encoding, the bytes WriteAllText would write. | `std/fs` |
| [Stream.Seek](Modern-Fs-Stream-Seek) | Moves the position from the start, the current place or the end; returns the new position. | `std/fs` |
| [Stream.Position](Modern-Fs-Stream-Position) | Returns the current position, or fails on a stream that cannot seek. | `std/fs` |
| [Stream.Flush](Modern-Fs-Stream-Flush) | Passes any buffered bytes on to where they are going. | `std/fs` |
| [Stream.CanRead](Modern-Fs-Stream-CanRead) | Returns true if Read can succeed on this stream. | `std/fs` |
| [Stream.CanWrite](Modern-Fs-Stream-CanWrite) | Returns true if Write can succeed on this stream. | `std/fs` |
| [Stream.CanSeek](Modern-Fs-Stream-CanSeek) | Returns true if Seek can succeed on this stream. | `std/fs` |
| [SeekOrigin](Modern-Fs-SeekOrigin) | Holds where Stream.Seek measures from: the start, the current position or the end. | `std/fs` |
| [Copy](Modern-Fs-Copy) | Copies a stream from its position to its end into another; returns the byte count. | `std/fs` |
| [MemoryStream](Modern-Fs-MemoryStream) | Holds a growable byte buffer in memory that reads, writes and seeks like a file. | `std/fs` |
| [MemoryStream.Length](Modern-Fs-MemoryStream-Length) | Returns the number of bytes held, whatever the position. | `std/fs` |
| [MemoryStream.Clear](Modern-Fs-MemoryStream-Clear) | Empties the stream; its length and position become 0. | `std/fs` |
| [MemoryStream.ToBytes](Modern-Fs-MemoryStream-ToBytes) | Copies every byte held into an Array; returns the count. | `std/fs` |
| [MemoryStream.ToUtf8Text](Modern-Fs-MemoryStream-ToUtf8Text) | Returns the bytes held decoded as text, the same way ReadAllText decodes a file. | `std/fs` |
| [MemoryStream.ToText](Modern-Fs-MemoryStream-ToText) | Returns the bytes held decoded in a text encoding, as ReadAllText would read them. | `std/fs` |
| [BufferedReader](Modern-Fs-BufferedReader) | Holds a Stream that reads another in large pieces, so many small reads stay fast. | `std/fs` |
| [BufferedReader.ReadByte](Modern-Fs-BufferedReader-ReadByte) | Reads the next byte; returns false at the end. | `std/fs` |
| [BufferedReader.ReadLine](Modern-Fs-BufferedReader-ReadLine) | Reads the next line as raw bytes in a string, not decoded; returns false at the end. | `std/fs` |
| [BufferedReader.ReadUntil](Modern-Fs-BufferedReader-ReadUntil) | Appends bytes up to and including a delimiter to an Array; returns the count. | `std/fs` |
| [BufferedReader.Peek](Modern-Fs-BufferedReader-Peek) | Copies up to n upcoming bytes into an Array without consuming them. | `std/fs` |
| [BufferedWriter](Modern-Fs-BufferedWriter) | Holds a Stream that gathers small writes and passes them on in large pieces. | `std/fs` |

## Find files by pattern

| Function | What it does | From |
|---|---|---|
| [Glob](Modern-Fs-Glob) | Fills an Array with the paths that match a wildcard pattern; returns the count. | `std/fs` |
| [MatchPattern](Modern-Fs-MatchPattern) | Returns true if a string matches a wildcard pattern, without touching the disk. | `std/fs` |
| [GlobRoot](Modern-Fs-GlobRoot) | Returns the folder a pattern search starts from: the part before the first wildcard. | `std/fs` |
| [PatternWildcardAt](Modern-Fs-PatternWildcardAt) | Returns the offset of a pattern's first wildcard, or -1 if it has none. | `std/fs` |
| [PatternIsRecursive](Modern-Fs-PatternIsRecursive) | Returns true if a pattern has a double-star part that searches every subfolder. | `std/fs` |

## Control a folder walk

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

## FsError: find out why a call failed

| Function | What it does | From |
|---|---|---|
| [FsError.Code](Modern-Fs-FsError-Code) | Returns the portable error code, such as FS_NOT_FOUND, to branch on. | `std/fs` |
| [FsError.Message](Modern-Fs-FsError-Message) | Returns a fixed one-line description of the error code. | `std/fs` |
| [FsError.Path](Modern-Fs-FsError-Path) | Returns the path the failed call was working on, or an empty string. | `std/fs` |
| [FsError.Path2](Modern-Fs-FsError-Path2) | Returns the second path of a failed copy, move or link call. | `std/fs` |
| [FsError.OsCode](Modern-Fs-FsError-OsCode) | Returns the operating system's own error number, or 0 if the library raised the error. | `std/fs` |
| [FsError.Operation](Modern-Fs-FsError-Operation) | Returns the name of the call that failed, for diagnostics only. | `std/fs` |

## Links, permissions and file identity

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

## Disk space and volumes

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

## Lock, map and watch files

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

## Open devices, pipes and the console

| Function | What it does | From |
|---|---|---|
| [Open Com](Open-Com) | Opens a serial port on a file number, with its speed, parity and other settings. | built-in |
| [Open Cons](Open-Cons) | Opens standard input or output on a file number, to use like a file. | built-in |
| [Open Err](Open-Err) | Opens standard input and standard error on a file number, to use like a file. | built-in |
| [Open Lpt](Open-Lpt) | Opens a printer on a file number, so Print # and Put # send data to it. | built-in |
| [Open Pipe](Open-Pipe) | Runs a shell command and opens its input or output on a file number. | built-in |
| [Open Scrn](Open-Scrn) | Opens the screen on a file number, for reading and writing like a file. | built-in |

## Read and write settings files: TOML and INI

| Function | What it does | From |
|---|---|---|
| [ParseToml](Category-Config#toml) | Parses TOML text into a TomlValue tree whose root is a table, or a ConfigError. | `std/config` |
| [LoadToml](Category-Config#toml) | Reads a UTF-8 TOML file into a TomlValue tree, or a ConfigError. | `std/config` |
| [TomlValue](Category-Config#looking-things-up) | Holds one TOML value or table; look keys up with Get, Find or a dotted Path. | `std/config` |
| [ToTomlText](Category-Config#building-and-writing) | Returns a TomlValue table as TOML text; comments are not kept. | `std/config` |
| [ParseIni](Category-Config#ini) | Parses INI text into an IniFile of sections and keys, or a ConfigError. | `std/config` |
| [LoadIni](Category-Config#ini) | Reads an INI file into an IniFile, or a ConfigError. | `std/config` |
| [SaveIni](Category-Config#ini) | Writes an IniFile to a file as INI text. | `std/config` |
| [IniFile](Category-Config#ini) | Holds an INI file's sections and keys in file order: Get, SetValue, Remove. | `std/config` |

## See Also

- [Filesystem library guide](Category-Filesystem)
- [File streams guide](Category-File-Streams)
- [File I/O functions](Category-File-I-O-Functions)
- [Config: INI and TOML files](Category-Config)
- [Embed: a file's bytes inside the program](Category-Embed)
- [Result](Category-Result)
- [Operating system functions (Kill, FileExists, Dir)](Category-Operating-System-Functions)

---

[Home](Home) · [Function Finder](Function-Finder) · [Keyword Index](Keyword-Index)

<!-- Generated by tools/wikifinder/finder.py. Edit the data, not this page. -->
