[Home](Home) › [All Categories](Categories) › [sys/win](Category-Sys-Win) › [sys/win/com](SysWin-Com) › **CDispInvoke**

# CDispInvoke

Calls the methods and properties of a COM Automation object by name.

Automation objects (the scripting runtime, the shell, Office, WMI …) implement `IDispatch`: a
caller looks a member up by name, gets back a number for it (a `DISPID`) and calls it with its
arguments packed as `VARIANT`s. This is late binding, the way script languages talk to COM, and it
needs no interface declarations. `CDispInvoke` does the packing: you name the member and pass
[DVARIANT](DVARIANT)s, or plain literals and numbers that turn into them, and get a `DVARIANT`
back.

The model to keep in mind:

- **It holds one reference.** `CDispInvoke` keeps the object's `IDispatch` pointer in `m_pDisp`
  and releases it in its destructor. A property or method that returns an object gives a
  `DVARIANT` holding it; assign that to another `CDispInvoke` to call into it.
- **It initialises COM.** Every constructor calls `CoInitialize( NULL )` and the destructor
  calls `CoUninitialize()` to match, so a program that only uses `CDispInvoke` needs neither.
  One that calls `CoInitialize` itself must destroy its `CDispInvoke`s before `CoUninitialize`.
- **Creating an object from a ProgID** (`"Scripting.Dictionary"`) keeps the pointer the object
  returns for `IUnknown` and does not ask it for `IDispatch`. For most scripting objects the two
  are the same; for some, `WScript.Shell` among them, they are not, and the first call crashes.
  Create those from their CLSID instead, which asks for `IDispatch`: see
  [Constructor](#constructor).
- **Errors are reported, not raised.** Each call stores its `HRESULT`;
  [GetLastResult](#getlastresult-setresult) returns it and [GetErrorInfo](#geterrorinfo)
  describes it. A failed call returns an empty `DVARIANT`.
- **Arguments are given in order**, first to last, and reversed for `IDispatch` internally.
  `Invoke` takes up to 16, `Get` 2, `Set` 4, `SetRef` 3 and `Put` and `PutRef` one. To leave out
  an optional argument in the middle, pass a `DVARIANT` of type `VT_ERROR` holding
  `DISP_E_PARAMNOTFOUND`.

## Importing

```freebasic
#import "sys/win"
#import "sys/win/com"
using win, com
```

## Example

Calls methods of the scripting runtime's `FileSystemObject`, reads an error, and uses
`WScript.Shell` and the object one of its properties returns:

```freebasic
#import "sys/win"
#import "sys/win/com"
using win, com

function main() as long
    CoInitialize( NULL )
    scope
        ' Methods that take and return strings
        dim fso as CDispInvoke = "Scripting.FileSystemObject"
        if fso.IsObject() then
            print fso.Invoke( "BuildPath", "C:\Reports", "summary.txt" ).ToStr()
            print fso.Invoke( "GetExtensionName", "notes.final.docx" ).ToStr()
            ' Errors are reported, not raised
            fso.Invoke( "NoSuchMethod" )
            print fso.GetErrorInfo()
        end if

        ' WScript.Shell is created from its CLSID (see Constructor)
        dim clsid as CLSID
        CLSIDFromProgID( "WScript.Shell", @clsid )
        dim wsh as CDispInvoke = CDispInvoke( clsid )
        if wsh.IsObject() then
            print wsh.Invoke( "ExpandEnvironmentStrings", "%SystemRoot%" ).ToStr()
            ' A property that returns an object gives another CDispInvoke
            dim env as CDispInvoke = wsh.Get( "Environment", "Process" )
            print "OS = "; env.Get( "Item", "OS" ).ToStr()
        end if
    end scope
    CoUninitialize()
    return 0
end function

end main()
```

It prints:

```text
C:\Reports\summary.txt
docx
Error &h80020006
Unknown name.

C:\Windows
OS = Windows_NT
```

## Members

| Member | Does |
| --- | --- |
| [Constructor](#constructor) | Creates an object, or wraps one you already have. |
| [Destructor](#destructor) | Releases the object and uninitialises COM. |
| [IsObject](#isobject) | Tells whether there is an object. |
| [DispPtr](#dispptr) | Returns the `IDispatch` pointer. |
| [DispObj](#dispobj) | Returns the `IDispatch` pointer with a reference of its own. |
| [vptr](#vptr) | Releases the object and returns the address of the pointer, for an output parameter. |
| [Clear](#clear) | Releases the object. |
| [Let](#let) | Replaces the object with another. |
| [Attach](#attach) | Takes over an `IDispatch` pointer. |
| [Detach](#detach) | Gives up the object and returns it. |
| [GetLcid, SetLcid](#getlcid-setlcid) | Read or set the locale passed with each call. |
| [GetVarResult](#getvarresult) | Returns the result of the last call. |
| [GetArgErr](#getargerr) | Returns which argument a type error was about. |
| [GetLastResult, SetResult](#getlastresult-setresult) | Read or set the `HRESULT` of the last call. |
| [GetErrorInfo](#geterrorinfo) | Describes an `HRESULT` in words. |
| [DispInvoke](#dispinvoke) | Calls a member with an array of arguments and any flags. |
| [Get](#get) | Reads a property. |
| [Put](#put) | Sets a property. |
| [Set](#set) | Sets a property, with indexes, and returns the result. |
| [PutRef](#putref) | Sets a property to an object reference. |
| [SetRef](#setref) | Sets a property to an object reference, with indexes. |
| [Invoke](#invoke) | Calls a method. |

## Reference

### Constructor

```freebasic
constructor
constructor( byval pdisp as IDispatch ptr, byval fAddRef as boolean = false )
constructor( byval vDisp as VARIANT, byval fAddRef as boolean = true )
constructor( byval vDisp as VARIANT ptr, byval fAddRef as boolean = true )
constructor( byref cvDisp as DVARIANT )
constructor( byref wszProgID as const wstring, byref wszLicKey as wstring = "" )
constructor( byref wszClsID as const wstring, byref wszIID as const wstring )
constructor( byref classID as const CLSID )
constructor( byref classID as const CLSID, byref riid as const IID )
constructor( byref wszLibName as const wstring, byref rclsid as const CLSID, byref riid as const IID, byref wszLicKey as wstring = "" )
constructor( byref wszLibName as const wstring, byref wszClsid as const wstring, byref wszIid as const wstring, byref wszLicKey as wstring = "" )
```

Every form first initialises COM on the thread.

- **No argument**: an empty `CDispInvoke`, for [Attach](#attach), [Let](#let) or [vptr](#vptr).
- **An `IDispatch` pointer**: wraps it. With `fAddRef` = `false`, the default, the `CDispInvoke`
  takes over the reference you hold (the usual case for a pointer a method returned to you);
  with `true` it adds a reference of its own.
- **A `VARIANT`, `VARIANT ptr` or `DVARIANT`** of type `VT_DISPATCH`: wraps the object it holds,
  adding a reference (the `VARIANT` forms unless `fAddRef` is `false`). The variant keeps its own
  reference. Any other type gives an empty `CDispInvoke`. This is how an object returned by
  [Get](#get) or [Invoke](#invoke) becomes callable.
- **A ProgID or CLSID string**, such as `"Scripting.Dictionary"` or a CLSID in braces
  (`"{…}"`), with an optional licence key: creates an in-process object. The pointer kept is the
  object's `IUnknown`, not asked for `IDispatch`; see the introduction.
- **A CLSID string and an IID string**: has the same parameter types as the form above. With two
  string literals the build stops with an internal compiler error; with two `wstring` variables
  it compiles, but did not create `Scripting.Dictionary` from its CLSID and the IID of
  `IDictionary` in a test. Use the `CLSID` and `IID` form instead.
- **A `CLSID`**, optionally with an `IID`: creates an in-process object and asks it for
  `IDispatch`. If the object has none, the pointer it returned is kept anyway, and calls on it
  are not safe.
- **A DLL path, a CLSID and an IID** (as GUIDs or strings), with an optional licence key: loads
  the DLL itself and creates the object from its class factory, without the registry. Ask for
  `IID_IDispatch` or a dual interface. This suits only in-process components that are not part
  of Windows or of an application and do not need a container. Do not pass a licence key to
  these forms: with one they ask the DLL for `IClassFactory` and then call it as an
  `IClassFactory2`.

| Parameter | Meaning |
| --- | --- |
| `pdisp` | An `IDispatch` pointer. |
| `vDisp`, `cvDisp` | A variant holding an object. |
| `fAddRef` | Whether to add a reference (see above). |
| `wszProgID` | A ProgID, or a CLSID in braces. |
| `wszLicKey` | A licence key, for licensed components; usually omitted. |
| `wszClsID`, `wszIID` | A CLSID and an IID as strings. |
| `classID`, `rclsid`, `riid` | A CLSID and an IID as GUIDs. |
| `wszLibName` | The full path of the DLL. |

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim clsid as CLSID
CLSIDFromProgID( "WScript.Shell", @clsid )
dim pWsh as CDispInvoke = CDispInvoke( clsid )
```

Microsoft Learn: [CoCreateInstance](https://learn.microsoft.com/en-us/windows/win32/api/combaseapi/nf-combaseapi-cocreateinstance)

### Destructor

```freebasic
destructor
```

Clears the last result, releases the object and, when its constructor's `CoInitialize`
succeeded, calls `CoUninitialize()`.

**Example**

```freebasic
scope
    dim pDic as CDispInvoke = "Scripting.Dictionary"
end scope   ' the dictionary is released here
```

### IsObject

```freebasic
function IsObject() as boolean
```

Check it after creating an object: a ProgID that is not registered gives an empty
`CDispInvoke`, not an error.

**Returns** `true` when the `CDispInvoke` holds an object.

**Example**

```freebasic
dim p as CDispInvoke = "No.Such.Object"
if p.IsObject() = false then print "not registered"
```

### DispPtr

```freebasic
function DispPtr() as IDispatch ptr
```

Returns `m_pDisp`, to pass to a function that wants the object. The reference stays with the
`CDispInvoke`: do not release it. `*obj` returns the same.

**Returns** the pointer, or `NULL`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim pDisp as IDispatch ptr = pDic.DispPtr()
```

### DispObj

```freebasic
function DispObj() as IDispatch ptr
```

Returns the pointer after adding a reference, for code that keeps it. Release it when done, for
instance by handing it to a `CDispInvoke` constructor, which takes the reference over.

**Returns** the pointer, or `NULL` when there is no object.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim pSame as CDispInvoke = pDic.DispObj()   ' two wrappers, one object
```

### vptr

```freebasic
function vptr() as IDispatch ptr ptr
```

Releases the object, as [Clear](#clear) does, and returns the address of `m_pDisp`, for a method
with an output `IDispatch ptr ptr` parameter: the object it writes there becomes the
`CDispInvoke`'s.

**Returns** the address of `m_pDisp`.

**Example**

```freebasic
dim pObj as CDispInvoke
dim ppDisp as IDispatch ptr ptr = pObj.vptr()
```

### Clear

```freebasic
sub Clear
```

Releases the object and clears the last result, leaving the `CDispInvoke` empty.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Clear()
print pDic.IsObject()   ' false
```

### Let

```freebasic
operator let( byval pdisp as IDispatch ptr )
operator let( byval vDisp as VARIANT ptr )
operator let( byval vDisp as VARIANT )
operator let( byref cvDisp as DVARIANT )
```

Releases the current object and wraps another, adding a reference to it: an `IDispatch`
pointer, or a `VARIANT`, `VARIANT ptr` or `DVARIANT` of type `VT_DISPATCH`. Anything else, or
`NULL`, leaves the `CDispInvoke` empty.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim pOther as CDispInvoke
pOther = pDic.DispPtr()
```

### Attach

```freebasic
function Attach( byval pdisp as IDispatch ptr, byval fAddRef as boolean = false ) as HRESULT
function Attach( byval vDisp as VARIANT ptr ) as HRESULT
```

Releases the current object and takes over another.

- The pointer form takes over the reference you hold, or adds one when `fAddRef` is `true`.
- The `VARIANT ptr` form takes an object of type `VT_DISPATCH` and sets the variant to
  `VT_EMPTY` without releasing it. It also adds a reference, so the object keeps one reference
  more than it should and is not freed when the `CDispInvoke` releases it; prefer
  `Attach( pvar->pdispVal )` followed by `pvar->vt = VT_EMPTY`.

**Returns** `S_OK`, or `E_INVALIDARG` for `NULL` or a variant that holds no object.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim pDisp as IDispatch ptr = pDic.Detach()
dim pOwner as CDispInvoke
pOwner.Attach( pDisp )   ' takes over the reference Detach gave
```

### Detach

```freebasic
function Detach() as IDispatch ptr
function Detach( byval pvar as VARIANT ptr ) as HRESULT
```

Gives up the object and leaves the `CDispInvoke` empty. The first form returns the pointer,
whose reference is now yours to release; the second stores it in `pvar` as `VT_DISPATCH`,
clearing `pvar` first.

**Returns** the pointer; or, for the variant form, `S_OK`, `E_POINTER` when there is no object
and `E_INVALIDARG` for `NULL`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim v as VARIANT
pDic.Detach( @v )
VariantClear( @v )
```

### GetLcid, SetLcid

```freebasic
function GetLcid() as LCID
sub SetLcid( byval _lcid as LCID )
```

Read or set the locale identifier that [Get](#get), [Put](#put), [Set](#set),
[PutRef](#putref), [SetRef](#setref) and [Invoke](#invoke) pass with each call, for objects
that read numbers and dates in text by locale. It starts as `LOCALE_USER_DEFAULT` (`&h400`).
[DispInvoke](#dispinvoke) takes its own `lcid` argument instead.

**Returns** the locale identifier (`GetLcid`).

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.SetLcid( LOCALE_INVARIANT )
print hex( pDic.GetLcid() )   ' 7F
```

### GetVarResult

```freebasic
function GetVarResult() as DVARIANT
```

Returns a copy of the value the last call returned: what [Invoke](#invoke) and [Get](#get) give
back, and what is left after the forms that return an `HRESULT`.

**Returns** the value; empty when the call failed or returned nothing.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.DispInvoke( DISPATCH_PROPERTYGET, "Count" )
print pDic.GetVarResult().ToStr()   ' 0
```

### GetArgErr

```freebasic
function GetArgErr() as UINT
```

After a call that failed with `DISP_E_TYPEMISMATCH` or `DISP_E_PARAMNOTFOUND`, returns the
position of the argument at fault. Positions count in the reversed order `IDispatch` uses: the
last argument is 0.

**Returns** the position; 0 otherwise.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "Add", "k", "v" )
if pDic.GetLastResult() = DISP_E_TYPEMISMATCH then print "argument"; pDic.GetArgErr()
```

### GetLastResult, SetResult

```freebasic
function GetLastResult() as HRESULT
function SetResult( byval Result as HRESULT ) as HRESULT
```

`GetLastResult` returns the `HRESULT` of the last call: `S_OK` (0) on success,
`DISP_E_UNKNOWNNAME` for a member that does not exist, `DISP_E_EXCEPTION` when the object raised
an error, `E_POINTER` when there is no object. `SetResult` stores a code, as every call does.

**Returns** the code (`SetResult` returns the code it stored).

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "Add", "a", 1 )
pDic.Invoke( "Add", "a", 2 )   ' the key exists already
print hex( pDic.GetLastResult() )   ' 80020009
```

### GetErrorInfo

```freebasic
function GetErrorInfo( byval nError as long = -1 ) as ustring
```

Returns the system's description of an `HRESULT`, by default the last result. For a nonzero code
the text starts with `Error &h` and the code in hex on a line of its own. When the object raised
an error (`DISP_E_EXCEPTION`) only the general "Exception occurred." is available: the object's
own message is not collected.

**Returns** the description.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "NoSuchMethod" )
print pDic.GetErrorInfo()   ' Error &h80020006, Unknown name.
```

Microsoft Learn: [FormatMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-formatmessagew)

### DispInvoke

```freebasic
function DispInvoke( byval wFlags as WORD, byval dispID as .DISPID, byval prgArgs as VARIANT ptr = NULL, byval cArgs as UINT = 0, byval lcid as LCID = LOCALE_USER_DEFAULT ) as HRESULT
function DispInvoke( byval wFlags as WORD, byval pwszName as wstring ptr, byval prgArgs as VARIANT ptr = NULL, byval cArgs as UINT = 0, byval lcid as LCID = LOCALE_USER_DEFAULT ) as HRESULT
```

The call the other members are built on. Calls the member, given by `DISPID` or by name (looked
up with `GetIDsOfNames` first), with `cArgs` arguments in the array at `prgArgs` **in reverse
order**, the last argument first, and the `DISPATCH_*` flags in `wFlags`: `DISPATCH_METHOD`,
`DISPATCH_PROPERTYGET`, `DISPATCH_PROPERTYPUT` or `DISPATCH_PROPERTYPUTREF`. For a put, the
value is the first element of the array. The result goes to [GetVarResult](#getvarresult).

**Returns** the `HRESULT`, also stored for [GetLastResult](#getlastresult-setresult): `S_OK`,
`DISP_E_UNKNOWNNAME`, `DISP_E_MEMBERNOTFOUND`, `DISP_E_BADPARAMCOUNT`, `DISP_E_TYPEMISMATCH`,
`DISP_E_EXCEPTION` …; `E_POINTER` when there is no object.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "Add", "c", 3 )
dim key as DVARIANT = "c"
dim args(0) as VARIANT
args(0) = key   ' a shallow copy: key must outlive the call
pDic.DispInvoke( DISPATCH_PROPERTYGET, "Item", @args(0), 1 )
```

Microsoft Learn: [IDispatch::Invoke](https://learn.microsoft.com/en-us/windows/win32/api/oaidl/nf-oaidl-idispatch-invoke)

### Get

```freebasic
function Get( byval dispID as DISPID, byval prgArgs as VARIANT ptr, byval cArgs as UINT, byval lcid as LCID = LOCALE_USER_DEFAULT ) as HRESULT
function Get( byval pwszName as wstring ptr, byval prgArgs as VARIANT ptr, byval cArgs as UINT, byval lcid as LCID = LOCALE_USER_DEFAULT ) as HRESULT
function Get( byval pwszName as wstring ptr ) as DVARIANT
function Get( byval dispID as DISPID ) as DVARIANT
function Get( byval pwszName as wstring ptr, byref dv as DVARIANT ) as DVARIANT
function Get( byval dispID as DISPID, byref dv as DVARIANT ) as DVARIANT
function Get( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as DVARIANT
function Get( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as DVARIANT
```

Reads a property, by name or `DISPID`, with up to two arguments (an indexed property such as a
collection's `Item`). It calls with `DISPATCH_METHOD or DISPATCH_PROPERTYGET`, so a method that
returns a value works too. The forms with an argument array return the `HRESULT` and leave the
value for [GetVarResult](#getvarresult).

**Returns** the value (empty on failure), or the `HRESULT`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "Add", "a", "Apple" )
print pDic.Get( "Count" ).ToStr(), pDic.Get( "Item", "a" ).ToStr()   ' 1  Apple
```

Microsoft Learn: [IDispatch::Invoke](https://learn.microsoft.com/en-us/windows/win32/api/oaidl/nf-oaidl-idispatch-invoke)

### Put

```freebasic
property Put( byval dispID as DISPID, byref dv as DVARIANT )
property Put( byval pwszName as wstring ptr, byref dv as DVARIANT )
```

Sets a property that takes no index to `dv`. It is a property, so it is written as an
assignment; check [GetLastResult](#getlastresult-setresult) afterwards.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Put( "CompareMode" ) = DVARIANT( 1 )   ' text compare
```

### Set

```freebasic
function Set( byval dispID as DISPID, byref dv as DVARIANT ) as HRESULT
function Set( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as HRESULT
function Set( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT ) as HRESULT
function Set( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT, byref dv4 as DVARIANT ) as HRESULT
function Set( byval pwszName as wstring ptr, byref dv as DVARIANT ) as HRESULT
function Set( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as HRESULT
function Set( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT ) as HRESULT
function Set( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT, byref dv4 as DVARIANT ) as HRESULT
```

Sets a property; with more than one argument, the last is the new value and the ones before it
are the indexes: `Set( "Item", key, value )`. The four-argument forms pass only three of them to
the object: the first argument is left out.

**Returns** the `HRESULT`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim key as DVARIANT = "a"
dim value as DVARIANT = "Avocado"
pDic.Set( "Item", key, value )   ' adds or replaces the item
```

### PutRef

```freebasic
property PutRef( byval dispID as DISPID, byref dv as DVARIANT )
property PutRef( byval pwszName as wstring ptr, byref dv as DVARIANT )
property PutRef( byval dispID as DISPID, byval pv as any ptr )
property PutRef( byval pwszName as wstring ptr, byval pv as any ptr )
```

Sets a property that holds an object, by reference, as a `Set` statement does in a script. The
`any ptr` forms take an interface pointer and pass it as `VT_UNKNOWN`, adding a reference for the
call. Check [GetLastResult](#getlastresult-setresult) afterwards.

**Example**

```freebasic
dim pRs as CDispInvoke = "ADODB.Recordset"
dim pCn as CDispInvoke = "ADODB.Connection"
pRs.PutRef( "ActiveConnection" ) = DVARIANT( pCn.DispPtr(), true )
if pRs.GetLastResult() <> S_OK then print pRs.GetErrorInfo()
```

### SetRef

```freebasic
function SetRef( byval dispID as DISPID, byref dv as DVARIANT ) as HRESULT
function SetRef( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as HRESULT
function SetRef( byval dispID as DISPID, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT ) as HRESULT
function SetRef( byval pwszName as wstring ptr, byref dv as DVARIANT ) as HRESULT
function SetRef( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT ) as HRESULT
function SetRef( byval pwszName as wstring ptr, byref dv1 as DVARIANT, byref dv2 as DVARIANT, byref dv3 as DVARIANT ) as HRESULT
```

[PutRef](#putref) with indexes, like [Set](#set): the last argument is the object, those before
it are the indexes.

**Returns** the `HRESULT`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
dim pInner as CDispInvoke = "Scripting.Dictionary"
dim key as DVARIANT = "child"
dim obj as DVARIANT = DVARIANT( pInner.DispPtr(), true )
pDic.SetRef( "Item", key, obj )   ' stores the dictionary itself as the item
```

### Invoke

```freebasic
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT, BYREF dv15 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL dispID AS DISPID, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT, BYREF dv15 AS DVARIANT, BYREF dv16 AS DVARIANT) AS DVARIANT

DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT, BYREF dv15 AS DVARIANT) AS DVARIANT
DECLARE FUNCTION Invoke (BYVAL pwszName AS WSTRING PTR, BYREF dv1 AS DVARIANT, BYREF dv2 AS DVARIANT, BYREF dv3 AS DVARIANT, BYREF dv4 AS DVARIANT, BYREF dv5 AS DVARIANT, BYREF dv6 AS DVARIANT, BYREF dv7 AS DVARIANT, BYREF dv8 AS DVARIANT, BYREF dv9 AS DVARIANT, BYREF dv10 AS DVARIANT, BYREF dv11 AS DVARIANT, BYREF dv12 AS DVARIANT, BYREF dv13 AS DVARIANT, BYREF dv14 AS DVARIANT, BYREF dv15 AS DVARIANT, BYREF dv16 AS DVARIANT) AS DVARIANT
```

Calls a method, by name or `DISPID`, with up to 16 arguments in order. It calls with
`DISPATCH_METHOD or DISPATCH_PROPERTYGET`, so a property read works too. From three arguments on,
the declarations name the third parameter `dv2` again (and the eighth and ninth `cvAg7` and
`cvAg8`); the names do not matter to a caller, and the arguments still go in the order given.

**Returns** the value the method returned, empty for a method that returns nothing or on failure;
[GetLastResult](#getlastresult-setresult) tells which.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
pDic.Invoke( "Add", "a", "Apple" )
print pDic.Invoke( "Exists", "a" ).ToStr()   ' -1, VARIANT_TRUE
```

Microsoft Learn: [IDispatch::GetIDsOfNames](https://learn.microsoft.com/en-us/windows/win32/api/oaidl/nf-oaidl-idispatch-getidsofnames)

## Related functions

| Function | Does |
| --- | --- |
| [Operator * (dispatch pointer)](#operator--dispatch-pointer) | Returns the `IDispatch` pointer. |

### Operator * (dispatch pointer)

```freebasic
operator *( byref cdi as CDispInvoke ) as IDispatch ptr
```

Returns `m_pDisp`, like [DispPtr](#dispptr). The reference stays with the `CDispInvoke`.

**Returns** the pointer, or `NULL`.

**Example**

```freebasic
dim pDic as CDispInvoke = "Scripting.Dictionary"
if *pDic then print "created"
```

## See also

- [sys/win/com](SysWin-Com)
- [DVARIANT](DVARIANT), the type of every argument and result
- [DSafeArray](DSafeArray), for the arrays methods such as `Keys` return
- [COM procedures](SysWin-Com-Procedures) for `NewCom`, `GetCom` and `AnyCom`
- Microsoft Learn: [IDispatch](https://learn.microsoft.com/en-us/windows/win32/api/oaidl/nn-oaidl-idispatch)
