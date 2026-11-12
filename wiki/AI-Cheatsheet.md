[Home](Home) › **AI Cheatsheet**

# tiko AI Cheatsheet

**Who this is for:** an AI coding agent (or a human in a hurry) writing applications in tiko.
It packs the syntax, the standard library's entry points and the mistakes that are most
likely to cost you a build. Drop it into your project as `AGENTS.md`, `CLAUDE.md` or your
agent's equivalent, or paste it into the agent's context.

Every `freebasic` block on this page is a complete program that compiles and runs. Where a
snippet's output matters it is shown in `'' →` comments.

## The rules that cost the most builds

1. **Declare everything, with a type.** `dim as int32 n`, `dim as ustring s`, or
   `var n = 10`. An undeclared name is error `TKO0743`; type suffixes (`n%`, `s$`) are refused.
2. **Text is `ustring`.** `string` holds bytes. Use `string` only at a byte or C boundary.
3. **Join text with `&`**, which converts numbers for you: `"n = " & n`.
4. **`#import` lines come first**, before any code in the file (`TKO0362`).
5. **Anything from `std/tasks` (`spawn`, channels) needs the thread-safe runtime.** Put
   `#cmdline "-mt"` in the main file.
6. **Indexing bases differ.** String functions (`mid`, `instr`, `left`) count from **1**.
   Containers (`xs[ 0 ]`), slices (`s[0 to 2]`) and `s[ i ]` on a `ustring` count from **0**.
   Plain arrays use the bounds you declare, and **`dim a( 4 )` is `0 to 4`, five elements**.
7. **`=` is comparison and assignment**; there is no `==`. Not-equal is `<>`.
8. **Use `andalso` / `orelse`** for conditions. `and` / `or` / `not` are bitwise and
   don't short-circuit.
9. **Many short English words are keywords** and can't be variable names: `step`, `out`,
   `name`, `dir`, `data`, `read`, `open`, `close`, `input`, `line`, `width`, `color`, `len`,
   `str`, `error`, `next`, `print`. Pick another word. The examples append `_` (`out_`, `dir_`)
   to locals and parameters, but never to public API names.
10. **Lambda captures must say `byval` or `byref`**: `sub[ byref total ]( ... )`.
11. **A module's names are private unless marked `public`.**
12. **`defer` is per block.** A `defer` inside an `if` runs at `end if`. A `defer` at
    module level is refused (`TKO0814`). Put it in a procedure.
13. **Identifiers are case-insensitive.** `entry.Key` and `entry.key` are the same member.
    A procedure `F` and a variable `f` collide (`TKO0600`), and `#define X` also rewrites
    every `x`.
14. **A bare integer literal is `integer` (64-bit), not `int32`.** Generic calls that infer
    from it (`outcome.Some( 1 )`, `containers.IndexOf( xs, 3 )`) fail to match. Pass a typed
    variable or `cast( int32, 1 )`.

## Files, build and run

| | |
| --- | --- |
| Source files | `.tiko`; headers `.ti` (`.bas` / `.bi` are still accepted) |
| One file | `tiko app.tiko` → `app.exe` (Windows) or `./app` |
| Optimised | `tiko -O2 app.tiko` |
| Debug + runtime checks | `tiko -g -exx app.tiko` (bounds, null pointers) |
| Thread-safe runtime | `tiko -mt app.tiko`, or `#cmdline "-mt"` in the source |
| Name the output | `-o name` (exact, so `-o name.exe` on Windows) |
| Define a symbol | `-d NAME=value` |
| Machine-readable errors | `--diagnostics-file <path>` |
| Every option | `tiko --help` |

Build needs **clang 18+** (not bundled): `C:\Program Files\LLVM\bin\clang.exe`,
`/usr/bin/clang`, Homebrew's `/opt/homebrew/opt/llvm/bin/clang`, or `TIKO_CLANG`.

**Projects.** A directory with a `tiko.toml`:

```toml
[package]
name = "app"

[dependencies]
units = { path = "../units" }     # a package of modules elsewhere on disk

[target.app]
main = "main.tiko"                # an executable target
# kind = "lib", sources = [...], options = ["-mt"], libs = [...], libpaths = [...]

[target.app.defines]
EDITION = "2"                     # as if -d EDITION=2

[profile.fast]
inherits = "release"
options  = ["-mt"]
```

| Command | Does |
| --- | --- |
| `tiko build [target]` | builds into `out/<profile>/` (incremental) |
| `tiko run [target] [-- args]` | builds an executable target and runs it |
| `tiko check` | reports every error and warning, writes nothing |
| `tiko clean` | removes what `tiko build` wrote |

Diagnostics look like `file.tiko(5,35): error TKO0698: message`, then a caret excerpt.
Fix the first error first.

## A complete program

There is no `main`: top-level statements run from top to bottom. `''` starts a comment,
`/' … '/` is a block comment, `_` at the end of a line continues it, and `:` separates
statements on one line.

```freebasic
#import "std/strings"
#import "std/containers"

type Item
    name as ustring
    price as float64
end type

function Total( byref items as containers.Array( of Item ) ) as float64
    dim as float64 sum = 0
    for each it in items
        sum += it.price
    next
    return sum
end function

dim cart as containers.Array( of Item )
dim as Item x
x.name = "tea"    : x.price = 3.5  : cart.Push( x )
x.name = "scones" : x.price = 4.25 : cart.Push( x )

for each it in cart
    print strings.Format( "{:<8} {:>6.2f}", it.name, it.price )
next
print strings.Format( "{} items, total {:.2f}", cart.Count( ), Total( cart ) )
'' → tea        3.50
'' → scones     4.25
'' → 2 items, total 7.75
```

## Types and declarations

| Type | Notes |
| --- | --- |
| `int8 int16 int32 int64` | signed, size in the name |
| `uint8 uint16 uint32 uint64` | unsigned; `ubyte` = `uint8` |
| `float32 float64` | a bare literal `1.5` is `float64` |
| `boolean` | `true` / `false` |
| `integer` / `uinteger` | pointer-sized (64-bit). A bare `1` literal is `integer`. `long` is 32-bit |
| `ustring` | text, UTF-16, grows as needed. The default text type |
| `string` | bytes (UTF-8 when converted from `ustring`) |
| `zstring ptr` | C `char*` |
| `uslice` | a view into a `ustring`, no copy |
| `T ptr`, `any ptr` | pointers; `nullptr` is the null pointer |

```freebasic
dim as int32 count                  '' starts at 0; "" for text, false for boolean
dim as float64 rate = 0.25, limit = 10
dim total as int64 = 100            '' "dim name as T" works too
var n = 10                          '' inferred: integer
var label = "x" & n                 '' inferred from the expression
const MaxItems = 100                '' compile-time constant
dim as const int32 lives = 3        '' run-time value, then read-only
dim as int32 scratch = any          '' skip zeroing; write before reading
dim as typeof( rate ) other = 1.5   '' typeof( x ) names x's type
type Score as int32                 '' a type alias
print count; rate; total; n; " "; label; MaxItems; lives; other
'' →  0 0.25 100 10 x10 100 3 1.5
```

Conversions: `cast( T, v )`, `cint`, `clng` (int32), `clngint` (int64), `cdbl`, `csng`,
`cbool`, `cubyte`. **Float to integer rounds** (`cint( 2.7 )` is 3, `cint( 2.5 )` is 2, to
even). Use `fix( x )` to truncate and `int( x )` for the floor. Narrowing an integer wraps
silently. Text: `str( n )`, `val( s )`, `valint( s )`, `hex( n )`, `bin( n )`.

Operators: `+ - * /` (`/` is always floating-point), `\` integer division, `mod`, `^` power,
`shl` / `shr`, `&` join, `+=` `-=` `*=` `&=`, `= <> < > <= >=`, `andalso orelse`,
`and or xor not` (bitwise), `iif( cond, a, b )`. A comparison prints as `-1` / `0`, so wrap it
in `cbool( … )` to print `true` / `false`.

`print a; b` puts no gap between items, but a signed number prints with a sign position, so a
positive one gets a leading space (` 5`). Unsigned results such as `asc( )` and C's `strlen`
get none. A trailing `;` stays on the line, and `print` alone ends it.

**A bare integer literal is `integer` (64-bit).** Where a generic's type is inferred from a
literal, it becomes `integer`, which won't match `int32`. Pass a typed variable or
`cast( int32, 1 )`.

## Control flow

```freebasic
dim as int32 n = 7
if n > 5 andalso n < 10 then
    print "mid"
elseif n = 0 then
    print "zero"
else
    print "other"
end if
if n mod 2 = 1 then print "odd"          '' one-line if

select case n
case 0                : print "zero"
case 1, 2, 3          : print "small"
case 4 to 9           : print "digit"
case is < 0           : print "negative"
case else             : print "big"
end select

for i as int32 = 1 to 10 step 3          '' both ends included
    if i = 4 then continue for
    print i;
next
print

dim as int32 k = 0
do while k < 3                           '' also: do until, loop while, loop until
    k += 1
    if k = 2 then exit do
loop

dim as int32 primes( 0 to 3 ) = { 2, 3, 5, 7 }
for each p in primes                     '' element type is inferred
    print p;
next
print
'' → mid
'' → odd
'' → digit
'' →  1 7 10
'' →  2 3 5 7
```

`exit for` / `exit do` / `exit sub` / `exit function` leave; `continue for` / `continue do` skip.
`for each byref x in xs` lets the loop change elements.

## Procedures

```freebasic
'' sub: no result. function: returns one.
sub Greet( byval who as ustring, byval times as int32 = 1 )   '' a default value
    for i as int32 = 1 to times
        print "hello, " & who
    next
end sub

function Square( byval x as float64 ) as float64
    return x * x
end function

'' byref changes the caller's variable; byref ... as const reads it without a copy.
sub Bump( byref n as int32 )
    n += 1
end sub

'' Several results: return a tuple, optionally with named elements.
function Divide( byval a as int32, byval b as int32 ) as ( q as int32, r as int32 )
    return ( a \ b, a mod b )
end function

'' Overloads say so.
function Describe overload ( byval n as int32 ) as ustring
    return "int " & n
end function
function Describe overload ( byval s as ustring ) as ustring
    return "text " & s
end function

Greet( "ada" )
Greet( "bob", 2 )
print Square( 1.5 )
dim as int32 c = 1
Bump( c ) : print c
var ( q, r ) = Divide( 17, 5 )
print q; r; Divide( 9, 2 ).q
print Describe( 3 ); " / "; Describe( "x" )
'' → hello, ada
'' → hello, bob
'' → hello, bob
'' →  2.25
'' →  2
'' →  3 2 4
'' → int 3 / text x
```

Write `byval` or `byref` on every parameter. When neither is written, numbers are passed by
value but `ustring`s and UDTs are passed **by reference**.

**Lambdas and closures.** A lambda that captures nothing is a plain function pointer (it
works as a C callback).

```freebasic
type IntFn as function( byval x as int32 ) as int32

sub ApplyAll( values( ) as int32, byval f as IntFn )
    for each byref v in values
        v = f( v )
    next
end sub

dim as int32 xs( 0 to 2 ) = { 1, 2, 3 }
ApplyAll( xs( ), function( byval x as int32 ) as int32
    return x * 10
end function )
print xs( 0 ); xs( 1 ); xs( 2 )

dim as int32 calls = 0, offset = 5
var tick = sub[ byref calls ]( )          '' byref: works on the caller's variable
    calls += 1
end sub
var add = function[ byval offset ]( byval x as int32 ) as int32   '' byval: a copy, taken now
    return x + offset
end function
tick( ) : tick( )
offset = 1000
print calls; add( 1 )
'' →  10 20 30
'' →  2 6
```

## Arrays

```freebasic
dim as int32 fixed( 1 to 3 ) = { 10, 20, 30 }  '' bounds as written
dim as ustring names( 0 to 1 ) = { "a", "b" }
dim grid( 1 to 2, 1 to 3 ) as float64

dim values( any ) as int32                    '' dynamic, empty: 0 to -1
redim values( 1 to 3 )                        '' resize, zeroed
redim preserve values( 1 to 5 )               '' resize, keep contents
erase values                                  '' free

'' Pass with "name( )", on both sides. The callee sees the caller's array.
function Sum( a( ) as const int32 ) as int64
    dim as int64 t = 0
    for each v in a
        t += v
    next
    return t
end function

'' Return an array: result type ends in ( ).
function Squares( byval n as int32 ) as int32( )
    dim as int32 r( )
    redim r( 1 to n )
    for i as int32 = 1 to n
        r( i ) = i * i
    next
    return r
end function

print Sum( fixed( ) ); lbound( fixed ); ubound( fixed ); ubound( grid, 2 )
var sq = Squares( 4 )
print sq( 4 ); ubound( sq )
'' →  60 1 3 3
'' →  16 4
```

For a growable list, prefer `containers.Array( of T )` (see [Containers](#containers)).

## Strings

```freebasic
#import "std/strings"

dim as ustring s = "The quick brown fox"
print left( s, 3 ); "|"; right( s, 3 ); "|"; mid( s, 5, 5 )   '' 1-based
print instr( s, "brown" ); instr( s, "zebra" )               '' 0 when not found
print ucase( s ); " "; len( s )
print trim( "  pad  " ) & "|" & space( 2 ) & string( 3, "=" )
print chr( 65 ); asc( "B" ); " "; str( 42 ); val( "2.5" ) * 2

'' std/strings
print strings.Format( "{} + {} = {:05}", 2, 3, 5 )            '' {} {0} {:>8} {:.3f} {:x}
var parts = strings.Split( "a,b,,c", "," )                    '' containers.Array( of ustring )
print parts.Count( ); " "; strings.Join( parts, "|" )
print strings.Replace( "a-b-c", "-", "+" ); " "; strings.StartsWith( s, "The" )
print strings.PadLeft( "7", 3, "0" ); " "; strings.Repeat( 3, "ab" )

'' Escapes need the ! prefix. A doubled quote is a quote.
print !"tab:\there"; " say ""hi"""

'' Block strings: the closing """ line's indentation is removed from every line.
dim as ustring sql = """
    select *
      from users
    """
print sql
'' → The|fox|quick
'' →  11 0
'' → THE QUICK BROWN FOX  19
'' → pad|  ===
'' → A66 42 5
'' → 2 + 3 = 00005
'' →  4 a|b||c
'' → a+b+c true
'' → 007 ababab
'' → tab:	here say "hi"
'' → select *
'' →   from users
```

- Build long strings with `&=` (amortised), or collect pieces and `strings.Join` them.
- `s[lo to hi]` is a zero-copy `uslice`, 0-based and inclusive. Assign it to a `ustring` to
  keep it.
- `len` counts UTF-16 units. Keep non-ASCII text in `ustring` variables, or build it with
  `wchr( codepoint )`. `len` of a bare non-ASCII literal counts UTF-8 bytes.
- Other `std/strings` functions: `EndsWith( s, x, ignoreCase )`, `Contains`, `Tally`,
  `Extract`, `Remain`, `Between`, `Remove`, `Shrink`, `MCase`, `Reverse`, `PadRight`,
  `PadCenter`, `IsNumeric`, `IsBlank`, `SplitChars`, `Find`, `SplitSlices`, `TrimSpace`.

## User-defined types and objects

```freebasic
type Account
  public:
    declare constructor( byval opening as int64 = 0 )
    declare destructor( )
    declare sub Deposit( byval amount as int64 )
    declare property Balance( ) as int64                 '' read-only property
    declare property Owner as ustring get, set           '' auto-property
  private:
    balance_ as int64
end type

constructor Account( byval opening as int64 )
    balance_ = opening
end constructor

destructor Account( )
    print "closing " & Owner
end destructor

sub Account.Deposit( byval amount as int64 )
    if amount > 0 then balance_ += amount
end sub

property Account.Balance( ) as int64
    return balance_
end property

'' Binary operators are global procedures.
operator = ( byref a as Account, byref b as Account ) as boolean
    return a.Balance = b.Balance
end operator

scope
    var acct = Account( 100 )
    acct.Owner = "ada"
    acct.Deposit( 50 )
    print acct.Balance; " "; cbool( acct = Account( 150 ) )
end scope                                 '' destructors run here, in reverse order
'' →  150 true
'' → closing
'' → closing ada
```

- Inside methods, members are reached directly or with `this.`.
- `with obj … end with` lets you write `.field`.
- Members can also be written `as T name` or `name as T`. Fields can have defaults:
  `sep as ustring = "="`.
- A type with no constructor can be built from a positional list:
  `dim as Point p = ( 1, 2 )`, or `type( 1, 2 )` as an expression.
- `enum Color … end enum`, `union … end union` and `type … extends Base` exist too.

**Inheritance and interfaces.**

```freebasic
type Animal extends Object                  '' extends Object: has a vtable
    declare virtual function Sound( ) as ustring
    declare abstract function Legs( ) as int32
end type
function Animal.Sound( ) as ustring
    return "..."
end function

type Dog extends Animal
    declare function Sound( ) as ustring override
    declare function Legs( ) as int32 override
end type
function Dog.Sound( ) as ustring
    return "woof"
end function
function Dog.Legs( ) as int32
    return 4
end function

interface INamed                            '' a contract: no data, no code
    function Name( ) as ustring
end interface

class Robot                                 '' class = a type that extends Object
    implements INamed
    declare function Name( ) as ustring implements INamed.Name
end class
function Robot.Name( ) as ustring
    return "R2"
end function

sub Speak( byref a as Animal )
    print a.Sound( ); a.Legs( ); " "; cbool( a is Dog )
end sub
sub Show( byval n as INamed )               '' an interface value
    print n.Name( )
end sub

dim as Dog d
dim as Robot r
Speak( d )
Show( r )
'' → woof 4 true
'' → R2
```

## Generics

```freebasic
type Stack( of T )
    declare sub Push( byval item as T )
    declare function Pop( ) as T
    declare property Count( ) as int32
private:
    as T items( any )
    as int32 used
end type

sub Stack( of T ).Push( byval item as T )
    if used > ubound( items ) then redim preserve items( used * 2 + 3 )
    items( used ) = item
    used += 1
end sub
function Stack( of T ).Pop( ) as T
    used -= 1
    return items( used )
end function
property Stack( of T ).Count( ) as int32
    return used
end property

function Larger( of T )( byval a as T, byval b as T ) as T   '' T inferred at the call
    return iif( a > b, a, b )
end function

dim s as Stack( of ustring )
s.Push( "a" ) : s.Push( "b" )
print s.Pop( ); s.Count; " "; Larger( 3, 9 ); " "; Larger( of float64 )( 2, 2.5 )
'' → b 1  9  2.5
```

## Errors: Result and Optional

Fallible library calls return a `Result` or an `Optional`. Check before taking `.Value( )`.

```freebasic
#import "std/outcome"
#import "std/fs"

type PortResult as outcome.Result( of int32, ustring )

function ParsePort( byref text as ustring ) as PortResult
    var p = valint( text )
    if str( p ) <> text orelse p < 1 orelse p > 65535 then
        return outcome.Fail( of int32, ustring )( "bad port '" & text & "'" )
    end if
    return outcome.Ok( of int32, ustring )( p )
end function

function Find( byref needle as ustring ) as outcome.Optional( of int32 )
    if needle = "b" then return outcome.Some( cast( int32, 1 ) )   '' not a bare 1: that is integer
    return outcome.None( of int32 )( )
end function

var r = ParsePort( "80x" )
if r.IsOk( ) then print r.Value( ) else print "error: "; r.Failure( )
print ParsePort( "8080" ).ValueOr( 0 ); Find( "z" ).ValueOr( -1 ); " "; Find( "b" ).HasValue( )

'' Library errors carry a message.
var t = fs.ReadAllText( "no-such-file.txt" )
if t.IsOk( ) = false then print "read failed: "; cbool( len( t.Failure( ).Message( ) ) > 0 )
'' → error: bad port '80x'
'' →  8080-1 true
'' → read failed: true
```

Pass a failure up by returning a new `Fail` built from `inner.Failure( )`. There are no
exceptions. `assert( cond )` stops the program when built with `-g`, and `-exx` adds bounds
and null checks.

## Memory and resources

Strings, arrays, containers and objects free themselves at the end of their scope. There is
no GC.

```freebasic
#import "std/memory"

type Conn
    id as int32
    declare destructor( )
end type
destructor Conn( )
    print "close"; id
end destructor

sub Work( )
    dim as int64 ptr buf = allocate( 8 * sizeof( int64 ) )
    defer deallocate( buf )               '' runs on every way out of this block
    if buf = nullptr then return
    buf[ 0 ] = 42
    print buf[ 0 ]
end sub
Work( )

dim as Conn ptr c = new Conn( 1 )         '' new / delete; new T[ n ] / delete[]
delete c

var s = memory.MakeShared( of Conn )( )   '' reference-counted owner
s->id = 2
scope
    var s2 = s
    print s.UseCount( )
end scope
s.Reset( )
'' →  42
'' → close 1
'' →  2
'' → close 2
```

`@x` takes an address, `*p` dereferences, `p->field` reaches a field, and `cptr( T ptr, p )`
casts. Test pointers against `nullptr`.

## Modules and packages

A **module is a directory**, and its files start with `#module "name"`:

```freebasic
'' greet/greet.tiko
#module "greet"

public function Hello( byval who as ustring ) as ustring   '' public: importers see it
    return "Hello, " & Cap( who ) & "!"
end function

public const DEFAULT_NAME = "world"

function Cap( byval s as ustring ) as ustring              '' no keyword: this module only
    return ucase( left( s, 1 ) ) & mid( s, 2 )
end function
```

```freebasic
'' main.tiko, beside greet/
#import "./greet"                    '' a relative path: the directory greet/
#import "std/strings" as txt         '' rename the prefix in this file
#import "std/containers"
using containers                     '' drop the prefix for this module's names

dim words as Array( of ustring )
words.Push( greet.Hello( greet.DEFAULT_NAME ) )
print txt.Join( words, "" )
'' → Hello, World!
```

- Names are reached as `module.Name`. The module name is the last part of the path.
- With no keyword, a name is visible to every file of the module and refused to importers.
  `private` also keeps it inside the module, and hides it from outside completely.
- `#import "../x" public` re-exports a module to your importers.
- A dependency in `tiko.toml` (`units = { path = "../units" }`) lets you write
  `#import "units/length"`.
- `#include once "file.ti"` is textual inclusion, for headers and C bindings.
- `tiko --print-graph main.tiko` lists the modules a program imports.

## Standard library map

Import with `#import "std/<name>"` and call as `<name>.Function( )`.

| Module | Main entry points |
| --- | --- |
| `std/strings` | `Format`, `Split`, `Join`, `Replace`, `StartsWith`, `Contains`, `PadLeft`, `Repeat`, … (see [Strings](#strings)) |
| `std/containers` | `Array`, `Map`, `Set`, `OrderedMap`, `OrderedSet`, `LinkedList`, `Deque`, `PriorityQueue`, `BitSet`; `Sort`, `SortBy`, `StableSortBy`, `IsSorted`, `IndexOf`, `Contains`, `BinarySearch`, `LowerBound`, `UpperBound`; `Hashable`, `HashOf` |
| `std/outcome` | `Result( of T, E )`, `Optional( of T )`, `Ok`, `Fail`, `Some`, `None` |
| `std/memory` | `SharedPtr`, `WeakPtr`, `MakeShared` |
| `std/fs` | `ReadAllText`, `WriteAllText`, `AppendAllText`, `ReadAllLines`, `ReadAllBytes`, `ReadLines`, `WriteAtomic`, `File`, `TextWriter`, `PathJoin`, `PathFileName`, `PathStem`, `PathExtension`, `PathParent`, `Exists`, `CreateDirAll`, `CreateTempDir`, `RemoveDirAll`, `WalkDir` |
| `std/os` | `Args`, `GetEnv` (Optional), `SetEnv`, `UnsetEnv`, `ExpandEnv`, `OS_NAME`, `ARCH_NAME` |
| `std/process` | running and talking to child processes |
| `std/tasks` | `Channel`, `SendChan`, `RecvChan`, `WaitGroup`, cancellation (needs `-mt`) |
| `std/chrono` | `LocalDate`, `DateTime`, `Stopwatch`, durations, ISO 8601, formats |
| `std/tz`, `std/tzdata` | named time zones, and the zone database built into the program |
| `std/numeric` | math, statistics, vectors and matrices, seeded random |
| `std/money` | exact `Currency` and `Decimal`, finance functions |
| `std/config` | `LoadToml`, INI files |
| `std/codec`, `std/hash`, `std/uuids` | base64, hex and URL encoding; checksums and hashes; UUIDs |
| `std/logs` | `Logger`, sinks, levels, structured fields |
| `std/net`, `std/http`, `std/tls` | TCP and UDP, `http.Fetch`, TLS |
| `std/tui` | terminal UI toolkit |
| `vendor/sqlite3`, `vendor/cJSON` | C libraries shipped with the toolchain, used through their C API |
| `vendor/tkControls`, `vendor/SDL3`, `vendor/raylib6` | cross-platform GUI and graphics |
| `vendor/PsControls`, `sys/win` | Windows-only GUI and the Windows API |

Each feature has a reference page in the [Feature Index](Feature-Index).

## Containers

```freebasic
#import "std/containers"

dim xs as containers.Array( of int32 ) = { 5, 3, 9 }
xs.Push( 7 ) : xs[ 0 ] = 50                   '' 0-based
print xs.Count( ); xs.Pop( ); xs[ xs.Count( ) - 1 ]
xs.Insert( 0, 1 ) : xs.Remove( 1 )            '' Remove( index )
containers.Sort( xs )
containers.SortBy( xs, function( byref a as int32, byref b as int32 ) as boolean
    return a > b                              '' true when a goes first
end function )
dim as int32 wanted = 3
print xs[ 0 ]; containers.IndexOf( xs, wanted )   '' a bare 3 would be integer, not int32

dim ages as containers.Map( of ustring, int32 )   '' hash map, unordered
ages[ "ada" ] = 36                                '' insert or replace
print ages.Add( "ada", 99 ); " "; ages.Contains( "bob" ); ages[ "ada" ]   '' Add refuses an existing key
dim as int32 age
if ages.TryGet( "ada", age ) then print age        '' read without inserting
for each e in ages
    print e.Key; e.Value
next

dim om as containers.OrderedMap( of ustring, int32 ) = { { "b", 2 }, { "a", 1 } }
for each (k, v) in om.Pairs( )                    '' sorted by key
    print k; v;
next
print

dim seen as containers.Set( of ustring ) = { "x", "y", "x" }
print seen.Count( ); " "; seen.Contains( "y" )
'' →  4 7 9
'' →  9 1
'' → false false 36
'' →  36
'' → ada 36
'' → a 1b 2
'' →  2 true
```

`Map` and `Set` iterate in no particular order. Use `OrderedMap` / `OrderedSet`, or sort
`m.Keys( )` / `s.Items( )`. A `Map` key type of your own must extend `containers.Hashable`,
override `HashOf( ) as ulongint`, and define `operator =`.

## Concurrency

```freebasic
#cmdline "-mt"
#import "std/tasks"

sub Squares( byval out_ as tasks.SendChan( of int32 ), byval n as int32 )
    for i as int32 = 1 to n
        out_.Send( i * i )
    next
    out_.Close( )
end sub

var results = tasks.Channel( of int32 )( 8 )   '' capacity 8
spawn Squares( results, 5 )                    '' arguments are copied at the spawn
dim as int32 total = 0
for each v in results                          '' ends when the sender closes
    total += v
next
print total

var quick = tasks.Channel( of ustring )( 1 )
dim as ustring msg
select channel
    case receive msg from quick : print msg
    case timeout 50             : print "timed out"
end select
'' →  55
'' → timed out
```

- A channel has `Send`, `Receive( byref v ) as boolean` (false once it is closed and empty),
  `TrySend`, `ReceiveFor( v, ms )`, `Close`, `Count` and `Capacity`.
- `tasks.WaitGroup` has `Add( )`, `Done( )` and `Wait( )`. Pass it as a `ptr` to spawned
  procedures.
- `spawn` takes a `sub` call. A goroutine reports its results through a channel.
- Low-level primitives (`threadcreate`, `mutexcreate`, `condcreate`) and atomics exist too.

## Files, environment, processes

```freebasic
#import "std/fs"
#import "std/os"
#import "std/containers"

dim as ustring dir_ = fs.CreateTempDir( "demo" ).Value( )
dim as ustring p = fs.PathJoin( dir_, "notes.txt" )
fs.WriteAllText( p, "one" & chr( 10 ) & "two" & chr( 10 ) )
fs.AppendAllText( p, "three" & chr( 10 ) )

dim lines as containers.Array( of ustring )
print fs.ReadAllLines( p, lines ).Value( ); " lines"
for each ln in fs.ReadLines( p )                 '' streaming; each item is a Result
    print ln.Value( );
next
print
print fs.PathFileName( p ); " "; fs.PathExtension( p ); " "; fs.Exists( p )
fs.RemoveDirAll( dir_ )

print os.GetEnv( "SURELY_UNSET_VAR" ).ValueOr( "default" )
print cbool( os.Args( ).Count( ) >= 1 ); " "; cbool( len( command( 0 ) ) > 0 )   '' argv[0] is the program
'' →  3 lines
'' → onetwothree
'' → notes.txt .txt true
'' → default
'' → true true
```

- `command( n )` is argument n (`""` past the end).
- `environ( "NAME" )` reads a variable, and `setenviron "NAME=value"` sets one.
- `end n` exits with status n.
- `exec( program, args )` returns the child's exit code, and `shell( cmdline )` runs through
  the system shell.
- `open pipe cmd for input as #f` reads a command's output.

## Calling C

```freebasic
#cinclude once "stdlib.h"            '' reads the real C header: no binding to write

function ByValue cdecl( byval a as const any ptr, byval b as const any ptr ) as int32
    return *cptr( const int32 ptr, a ) - *cptr( const int32 ptr, b )
end function

dim nums( 0 to 4 ) as int32 = { 5, 3, 9, 1, 7 }
qsort( @nums( 0 ), 5, sizeof( int32 ), @ByValue )
for each n in nums
    print n;
next
print

'' Or declare a function by hand.
extern "C"
    declare function strlen( byval s as const zstring ptr ) as uinteger
end extern
dim as string bytes = "hello"
print strlen( strptr( bytes ) )
'' →  1 3 5 7 9
'' → 5
```

- A C field named like a tiko keyword gets a `_` suffix (`rem` becomes `rem_`).
- A `ustring` passed to a `zstring ptr` goes as UTF-8.
- Copy C-owned text out with `dim as ustring s = *zptr`.
- Memory that C allocated, C frees.
- `#foreignlib` links a library kept in your source tree.
- [tiko c2t](C2t-Tutorial) turns a C header into a readable `.ti`.

## Preprocessor and platforms

```freebasic
#if defined( __FB_WIN32__ )
    const PLATFORM = "windows"
#elseif defined( __FB_LINUX__ )
    const PLATFORM = "linux"
#elseif defined( __FB_DARWIN__ )
    const PLATFORM = "macos"
#endif

#ifndef EDITION
    #define EDITION 1                '' override with -d EDITION=2
#endif

print cbool( len( PLATFORM ) > 0 ); EDITION; " "; cbool( __LINE__ > 0 )
#ifdef __TIKO_COMPILER__
    print "tiko"
#endif
'' → true 1 true
'' → tiko
```

- `#cmdline "-mt -d X=1"` puts compiler options in the source.
- `#error "msg"`, `#assert`, `__FB_64BIT__`, `__FB_UNIX__`, `__FB_DEBUG__` and `__FB_MT__`
  are available too.
- Write code that builds on every platform. A branch for a platform you didn't build for
  is never compiled, so it can hide errors.

## Testing

```freebasic
#include once "fbcunit.bi"

function Clamp( byval v as int32, byval lo as int32, byval hi as int32 ) as int32
    if v < lo then return lo
    if v > hi then return hi
    return v
end function

SUITE( clamping )
    TEST( inside )
        CU_ASSERT_EQUAL( Clamp( 5, 0, 10 ), 5 )
    END_TEST
    TEST( edges )
        CU_ASSERT_EQUAL( Clamp( -3, 0, 10 ), 0 )
        CU_ASSERT_TRUE( Clamp( 99, 0, 10 ) = 10 )
    END_TEST
END_SUITE

end iif( fbcu.run_tests( ), 0, 1 )   '' exit 0 only if every test passed
```

Also available: `CU_ASSERT`, `CU_ASSERT_FALSE`, `CU_ASSERT_NOT_EQUAL` and
`CU_ASSERT_DOUBLE_EQUAL( a, b, tolerance )`. Build with `-g` for source-level debugging
(lldb, gdb, or tkEdit's debugger).

## Older forms to avoid

tiko accepts older BASIC code, but new code should use the modern forms:

| Avoid | Write |
| --- | --- |
| `string` for text | `ustring` |
| `long`, `integer` for counts | `int32`, `int64` |
| `while … wend` | `do while … loop` |
| `+` to join strings | `&` |
| `goto` / `gosub` / `on error` | structured flow, `Result`, `defer` |
| `n%`, `s$` suffixes, undeclared variables | `dim as int32 n`, `dim as ustring s` |
| `#lang "qb"` / `"fblite"` | not supported; the `fb` dialect is the only one |

See [Compatibility](Compatibility) for the full list.

## Where to look next

- [tiko by Example](https://tiko-lang.net/by-example/): a short runnable program for every
  feature, with its output. It is the best source of idiomatic code to copy.
- [The tiko Programming Language](https://tiko-lang.net/book/): the book.
- [Feature Index](Feature-Index): one reference page per language feature and library
  module.
- [Packages and Modules Tutorial](Packages-and-Modules-Tutorial),
  [Interfaces Tutorial](Interfaces-Tutorial),
  [Goroutines Tutorial](Modern-Goroutines-Tutorial).
- [Compiler Error Messages](Compiler-Error-Messages): the `TKOnnnn` diagnostics.
