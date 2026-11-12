[Home](Home) › [All Categories](Categories) › **Math Library**

# Math Library

```freebasic
#import "std/numeric"
#import "std/money"

using numeric, money
```

The built-in numeric surface is ABS SGN SQR SIN COS TAN ASIN ACOS ATN ATAN2 EXP LOG INT FIX FRAC RND RANDOMIZE and the operators. No MIN, no MAX, no ROUND, no pi, no way to ask whether a DOUBLE is NaN, no money type, no complex numbers, no vectors, no statistics, and no way to tell a failed parse from a legitimate zero.

These modules add those. Everything is a library behind an `#import` -- std/numeric, and std/money for the money types. **Nothing becomes a keyword** and nothing existing changes.

## Why It Exists

Four things the language gets wrong today. All four verified by compiling them, not asserted.

**`^` always yields DOUBLE.** There is no integer exponentiation: `a ^ b` converts to floating point, calls pow, converts back. Above 2^53 the result is wrong even when operands and true result all fit in a LONGINT. Constant folding **conceals** it -- a literal `2 ^ 62` is exact -- so it appears only once the operands become variables.

```freebasic
dim as int64 b = 3, e = 38
print b ^ e             ' 1350851717672992000  -- exact answer ends 089
```

Use `IPow( 3LL, 38LL )`.

**`MOD` truncates.** Every wrapping index, hash bucket and day-of-week computation wants 2.

```freebasic
print -7 mod 3          ' -1
```

Use `FloorMod( -7, 3 )`.

**`VAL` cannot fail.** Garbage and a legitimate zero are the same answer, and `val("12abc")` is 12 -- a prefix parse with the tail silently discarded.

```freebasic
print val( "abc" )      ' 0
print val( "0" )        ' 0
```

Use `TryParseDouble( s )`.

**`STR` does not round-trip.** The value that comes back is not the value that went in. `str(1.0/3.0)` happens to survive, so the failure is **data-dependent** and shows up later, in a file already on disk.

```freebasic
print str( 0.1 + 0.2 )              ' 0.3
print val( str( 0.1+0.2 ) ) = 0.1+0.2   ' FALSE
```

Use `ToString( d )`.

None of these four are fixed in place. `^`, `MOD`, `VAL`, `STR`, `RND` and `RANDOMIZE` are left exactly as they are. Each defect gets a correct neighbour under a different name.

## Nothing Becomes A Keyword

```freebasic
dim as int32 min = 1, max = 2, round = 3, clamp = 4      ' still compiles
```

Those four are the most obvious names here and all four are legal identifiers in tiko. Plenty of code uses them as variable names, so everything belongs to the module and `using numeric` is your decision. Your own local shadows the library cleanly and the qualified name still works:

```freebasic
#import "std/numeric"
using numeric
dim as float64 e = 2.0
print e, numeric.E              ' 2    2.718281828459045
```

Because these modules add no keyword and no grammar, they cannot change any existing diagnostic.

## math.tiko

### Constants

```text
PI TAU E SQRT2 LN2 LN10 DEG2RAD RAD2DEG
EPSILON_DOUBLE MAX_DOUBLE MIN_POSITIVE_DOUBLE
EPSILON_SINGLE MAX_SINGLE MIN_POSITIVE_SINGLE
```

The non-finite values are **functions**, not constants -- `const as double N = 0.0/0.0` is a compile-time division by zero and does not compile:

```text
NaN( )  Infinity( )  NegInfinity( )
NaNF( ) InfinityF( ) NegInfinityF( )
MinSubnormalDouble( )  MinSubnormalSingle( )
```

Integer bounds are **not** duplicated here; fblimits.bi already supplies `FB.MIN_VALUE_LONGINT` and friends. The module includes it for its own use, but an import does not pass it on -- `#include` it yourself.

### Classification

```text
IsNaN( x )      IsInfinite( x )   IsFinite( x )
IsNormal( x )   IsSubnormal( x )  IsNegative( x )
Classify( x ) -> FP_NAN FP_INFINITE FP_ZERO FP_SUBNORMAL FP_NORMAL
```

SINGLE and DOUBLE. These read the exponent and mantissa **fields** rather than comparing. `x <> x` is a correct NaN test only while the compiler may not assume finiteness.

One of these reads wrong at first glance:

```freebasic
IsNegative( -0.0 )      ' TRUE
-0.0 < 0.0              ' false
-0.0 = 0.0              ' true
```

IsNegative is a **sign-bit** query. The two zeros are equal as numbers and distinguishable as bit patterns, and this is what tells them apart.

### Selection

```text
Min( a, b )   Max( a, b )   Clamp( v, lo, hi )
Lerp( a, b, t )             Sign( x ) as LONG
```

Every integer type plus SINGLE and DOUBLE (Lerp is floating point only).

- **NaN propagates:** `Min( NaN( ), 1.0 )` is NaN. C's fmin returns the non-NaN operand; that is a defensible choice and it is not this one, because silently discarding a NaN turns a detectable error into an undetectable wrong answer.
- **Clamp with lo > hi returns hi.** Deterministic rather than right, because there is no right answer. A NaN v falls through and comes back unchanged.
- **Sign returns LONG always** -- that is the difference from SGN, whose result is the argument's own type and so cannot index an array or drive a SELECT CASE. `Sign( NaN( ) )` is 0.
- **Lerp is `a + t*(b-a)`:** monotonic, and **not** exact at t = 1 (may miss b by one ulp). The exact-at-endpoints form is not monotonic; both cannot be had at once, and C++20's std::lerp chooses the other one and pays a branch.
- **Min and Max are functions**, so both arguments are evaluated.

### Rounding

```text
Round( x )                 half away from zero:  2.5 -> 3,  -2.5 -> -3
RoundHalfEven( x )         banker's:             2.5 -> 2,  -2.5 -> -2
Round( x, digits )         0..17 decimal places
RoundHalfEven( x, digits )
Floor( x )  Ceil( x )  Truncate( x )
```

Floor and Ceil exist even though INT is floor: INT is floor and FIX is truncation, but the **names** do not say so and code often uses INT believing it truncates.

RoundHalfEven is what financial code wants -- half-up drifts upward across a ledger. It is implemented rather than delegated to C's rint, because rint honours the **current** rounding mode and would stop being deterministic the moment fenv.tiko's rounding control is used.

The digits form scales, and the scaling is visible:

```freebasic
Round( 2.675, 2 )       ' 2.68, not 2.67
```

The double nearest 2.675 is 2.67499999999999982..., so an exact decimal round gives 2.67 -- but `2.675*100` rounds **up** to exactly 267.5, so the tie rule fires. Inherent to any scale-and-round implementation. For money, use [Finance](Category-Finance).

Outside 0..17 the result is NaN; returning the input would hide the mistake.

### The libm surface

```text
Cbrt Hypot Exp2 Expm1 Log2 Log10 Log1p LogB Pow
Sinh Cosh Tanh Asinh Acosh Atanh
Fma CopySign NextAfter ScaleB Frexp Modf Ulp
DegToRad RadToDeg
```

Pages: [Cbrt](Modern-Math-Cbrt) · [Hypot](Modern-Math-Hypot) · [Exp2](Modern-Math-Exp2) · [Expm1](Modern-Math-Expm1) · [Log2](Modern-Math-Log2) · [Log10](Modern-Math-Log10) · [Log1p](Modern-Math-Log1p) · [LogB](Modern-Math-LogB) · [Pow](Modern-Math-Pow) · [Sinh](Modern-Math-Sinh) · [Cosh](Modern-Math-Cosh) · [Tanh](Modern-Math-Tanh) · [Asinh](Modern-Math-Asinh) · [Acosh](Modern-Math-Acosh) · [Atanh](Modern-Math-Atanh) · [Fma](Modern-Math-Fma) · [CopySign](Modern-Math-CopySign) · [NextAfter](Modern-Math-NextAfter) · [ScaleB](Modern-Math-ScaleB) · [Frexp](Modern-Math-Frexp) · [Modf](Modern-Math-Modf) · [Ulp](Modern-Math-Ulp) · [DegToRad](Modern-Math-DegToRad) · [RadToDeg](Modern-Math-RadToDeg)

Real overload sets: a SINGLE argument takes the SINGLE path and calls the `f` variant, it does not widen. That is the specific defect that makes crt/math.bi unusable in practice -- `sqrt` there takes a DOUBLE, so every single-precision call widens and narrows silently, twice.

Hypot does not overflow for a representable result:

```freebasic
Hypot( 1e200, 1e200 )               ' finite
sqr( 1e200*1e200 + 1e200*1e200 )    ' +inf
```

Log1p and Expm1 are the accurate-near-zero pair:

```freebasic
log( 1.0 + 1e-17 )      ' 0.0 -- the 1.0 swallowed it
Log1p( 1e-17 )          ' 1e-17
```

Pow is **not** a replacement for `^`; it is the double-to-double operation under a name. Integer exponentiation is IPow.

## mathint.tiko

### Division and modulo

Three conventions, all named:

```text
FloorDiv / FloorMod     sign follows the DIVISOR:  FloorMod(-7,3) = 2
EuclidDiv / EuclidMod    always non-negative:      EuclidMod(-7,-3) = 2
DivMod( a, b )           returns a TUPLE
```

```freebasic
var (q, r) = DivMod( total, perPage )
```

None of them is spelled `Mod`, so none can be confused with the operator. DivMod is where the tuple feature earns its keep: one idiv produces both.

Tuple identity is **structural**, so DivMod on LONG and on LONGINT return different types and neither converts to the other.

### Exponentiation, roots, number theory

```text
IPow( base, exp )        EXACT -- IPow( 3LL, 38LL ) = 1350851717672992089
IPowChecked( base, exp ) Optional
ISqrt( n )               exact floor of the true root
GCD( a, b )  LCM( a, b )
```

ISqrt is exact over the whole domain, which `int( sqr( n ) )` is not: the DOUBLE conversion loses bits above 2^53 and the result can land one below the floor.

### Checked, saturating and wrapping

```text
AddChecked SubChecked MulChecked DivChecked NegChecked AbsChecked
IPowChecked                        -> Optional( of T ), empty on overflow

AddSaturating SubSaturating MulSaturating NegSaturating AbsSaturating
AddWrapping SubWrapping MulWrapping NegWrapping
```

Every integer type. AbsChecked is not redundant:

```freebasic
abs( MIN_VALUE_LONGINT )        ' MIN_VALUE_LONGINT itself -- NEGATIVE
```

That is the classic overflow bug and it is silent today.

**The limitation, stated plainly:** these protect the call sites you thought about. Overflow bugs live at the call sites nobody thought about, which is why Rust traps by default in debug builds and Swift traps always. A global `-checked` mode is declined on cost; this does not pretend to be it.

The wrapping family is exactly what the operators already do. It exists so that **deliberate** wrapping -- a hash mix, a checksum, a ring index -- can be spelled as deliberate.

### Bits

```text
PopCount LeadingZeros TrailingZeros BitWidth Parity
RotateLeft RotateRight ByteSwap BitReverse IsPow2 NextPow2
```

UBYTE / USHORT / ULONG / ULONGINT, with signed overloads that **reinterpret**. Width comes from the operand's own type: LeadingZeros of a UBYTE counts within 8 bits.

```text
LeadingZeros( 0 )   returns the operand's FULL WIDTH
RotateLeft( x, 64 ) on a ULONGINT is x, not undefined
```

Both are decisions, not descriptions: the x86 instructions are undefined at zero without BMI, and the C rotate idiom is undefined at n = 0.

The **portable** implementation is the contract. Per-backend intrinsics would be an optimisation underneath a defined result, never the definition.

**No INTEGER / UINTEGER overloads.** INTEGER is the same width as LONGINT on every tiko target, so they add nothing.

### The money types

The money types live in their own category. std/money's Currency and Decimal are documented under [Finance](Category-Finance) -- exact fixed-point money in eight bytes, and the 128-bit .NET decimal. They are part of the same library and ship in the same tree; they are filed separately because money is a subject of its own, not a corner of arithmetic.

## mathtext.tiko

### Parsing

Strict by default:

```text
TryParseDouble( s [, flags] )   TryParseSingle( s [, flags] )
TryParseLongInt( s [, base] )   TryParseULongInt( s )
TryParseLong( s )               TryParseULong( s )
```

All return Optional. The **whole** string must be consumed:

| Input | Result | Input | Result |
| --- | --- | --- | --- |
| `"42"` | 42 | `"  42"` | empty |
| `"42abc"` | empty | `"1,234"` | empty |
| `"1e"` | empty | `""` | empty |
| `"nan"` / `"inf"` | the value | `"1.#INF"` | the value |

tiko's own PRINT spellings parse, so a program can read back what it wrote. Leniency is opted **into**, never out of:

```text
PARSE_TRIM  PARSE_ALLOW_TRAILING  PARSE_NO_SPECIAL
```

Integer overflow is **detected**, not clamped -- strtoll saturates and sets errno, which is the same "cannot fail" shape being replaced.

### Formatting

```text
ToString( v )               shortest string that reads back EXACTLY
ToString( v, fmt )          controlled
ToString( int64 )
```

```freebasic
ToString( 0.1 + 0.2 )       ' 0.30000000000000004
str( 0.1 + 0.2 )            ' 0.3
```

Seventeen characters where STR gives three, and it is the correct answer: the two values differ and a format that prints them the same is lying.

```text
type NumFormat
    style        NUM_SHORTEST NUM_FIXED NUM_SCIENTIFIC NUM_GENERAL NUM_PERCENT
    digits       -1 = natural
    grouping     thousands separators
    decimalSep   default "."
    groupSep     default ","
    prefix suffix plusSign
end type
```

```freebasic
ToString( 1234567.891, f )      ' 1,234,567.89
```

**Locale is explicit or absent** -- an implicitly locale-dependent number format is how a program writes a CSV its own importer cannot read on another machine.

## random.tiko

```freebasic
dim r as Rng = RngSeeded( 12345 )
print r.NextInt( 1, 6 )                  ' inclusive both ends, UNBIASED
print r.NextDouble( )                    ' [0, 1)
```

RND and RANDOMIZE are untouched. fbprng.bi already offers five algorithms behind `RANDOMIZE seed, algorithm`. Three things are missing and the first is structural:

- **RND is one global stream.** Two subsystems that both want reproducible randomness cannot have it; a test cannot seed its own generator without disturbing the program's.
- **There is no unbiased integer range.** `int( rnd * n )` is the usual idiom and it is biased. Nobody notices, which is what makes it worth fixing.
- **There are no distributions and no shuffle.**

The generator is `xoshiro256**`, four 64-bit words, so an Rng lives in a UDT without a pointer. **An Rng is a value:** copying it forks the stream, which is what makes a reproducible sub-simulation possible. There is no default global Rng.

```text
NextULongInt NextULong NextDouble NextDoubleRange NextSingle
NextInt( lo, hi )        INCLUSIVE both ends, matching tiko's TO
NextBoolean NextBooleanP( p )
NextNormal NextNormalP( mean, sd ) NextExponential( lambda )
NextPoisson( lambda )
Shuffle( r, a( ) )   Choice( r, a( ) )
ShuffleArray( r, a )  ShuffleDeque( r, d )  ShuffleList( r, l )
ChoiceArray( r, a )   ChoiceDeque( r, d )
CryptoBytes( ptr, n )  CryptoULongInt( )  RngFromEntropy( )
```

NextInt is unbiased by Lemire's multiply-and-reject: one multiply, no division in the common case. NextDouble is `[0,1)` with 53 bits of entropy; 1.0 is never returned.

Shuffle is Fisher-Yates **descending** with an inclusive bound -- the form that produces every permutation with equal probability. The other forms are subtly wrong and are what a hand-rolled shuffle usually is.

`ShuffleArray`, `ShuffleDeque` and `ShuffleList` do the same for the containers, with any element type, and make the same draws, so one seed gives a plain array and each container the same order. `ShuffleList` relinks nodes and copies no element. `ChoiceArray` and `ChoiceDeque` pick one element by reference, and raise out of bounds on an empty container. See [Shuffle](Modern-Math-Shuffle#containers) and [Choice](Modern-Math-Choice#containers).

**CryptoBytes is a separate surface and not an Rng.** No seed, no reproducibility, no state. One type with two contradictory contracts would invite exactly the mistake this separation prevents. `RngFromEntropy( )` is the bridge.

## stats.tiko

```text
Sum( a( ) )         compensated -- Neumaier
NaiveSum( a( ) )    the fast one, named so you meant it
Mean Variance VariancePopulation StdDev StdDevPopulation
Median Percentile MinOf MaxOf Range Covariance Correlation
Count
```

DOUBLE, SINGLE, LONG and LONGINT arrays, any lbound.

**Why summation is the interesting part:** naive summation accumulates rounding error at each step, and over a million values the result can be wrong in the fourth significant digit -- invisibly, because the answer stays plausible.

```text
a( 0 ) = 1e16, then 100000 ones
Sum      -> 10000000000100000     exact
NaiveSum -> 10000000000000000     off by 100000
```

Sum accumulates in DOUBLE regardless of element type: the sum of a million SINGLEs is not a single-precision quantity.

Variance is **Welford**, not `E[x^2] - E[x]^2`. The textbook form subtracts two large nearly-equal numbers and can return a **negative** variance for data with a large mean and small spread. The **sample** form (n-1) is the default, because almost every array is a sample; the population form is available under a name that says which it is.

Median and Percentile **do not sort in place** -- they copy. Asking a question does not modify your data. Percentile is the R type-7 / NumPy definition; nine definitions exist and disagree.

Mean of an empty sequence is NaN, not zero -- zero is a legitimate mean.

### Streaming

```freebasic
dim acc as RunningStats
acc.Add( x )
acc.Mean( ) acc.Variance( ) acc.StdDev( ) acc.MinValue( ) acc.MaxValue( )
acc.Merge( other )   acc.Reset( )   acc.Count( )
```

Constant space, one pass, Welford internally. Merge combines two accumulators exactly (Chan's formula), so a fan-out across threads reduces without re-reading the data.

## vector.tiko

```freebasic
dim as Vec3 a = Vec3f_( 1, 2, 3 )
print Dot( a, b ), Length( a )
dim as Mat4 mvp = proj * view * model
dim as Vec3 p = TransformPoint( mvp, v )
```

```text
Vec2f Vec3f Vec4f Mat4f Quatf               ' and the ...d doubles
Vec2 Vec3 Vec4 Mat4 Quat                    ' aliases for the SINGLE forms
```

**Concrete types**, because `Vec( of T, N )` is not expressible: generics take **type** parameters only and there is no way to bind one to the value 3.

Two conventions, stated because half of all matrix bugs are these:

- **Column-major storage, column-vector convention.** `m * v` transforms v and `proj * view * model` applies model **first**, matching OpenGL and GLSL.
- **TransformPoint and TransformVector are separate.** A point translates; a direction does not.

```text
Dot Cross Mul Length LengthSquared Distance DistanceSquared
Normalize Lerp Reflect Angle
Mat4fIdentity Translation Scaling RotationX/Y/Z Perspective Orthographic
Transpose Determinant TryInverse( m, out ) TransformPoint TransformVector
QuatfFromAxisAngle Conjugate Rotate ToMatrix Slerp
```

- **No `*` between two vectors:** it would have to mean the dot product or the component-wise product, both are wanted, and neither is obviously the default. `Dot( a, b )` and `Mul( a, b )` say which.
- **Normalize of a zero vector returns zero**, not NaN. That is the case that actually occurs -- a zero-length normal from a degenerate triangle -- and propagating NaN through a render loop turns one bad triangle into a blank frame.
- **LengthSquared is the one to use for comparisons:** `Length(a) < Length(b)` costs two square roots for a question that needs none.
- **Slerp takes the short path:** q and -q are the same rotation, and without negating one operand it takes the long way round three-quarters of the time.

**Complex numbers are not here** any more -- they moved to their own file, complex.tiko, below. They were generated from the same macro text as Vec/Mat/Quat on the grounds that they are the same kind of small operator-overloaded value type; that was true of the arithmetic and false of everything else, and a program that wants Dot should not pay for twelve inverse hyperbolic functions.

## complex.tiko

```freebasic
dim as Complex z = CSet( 3, 4 )
print CAbs( z )                 ' 5
print CToString( z * z )        ' -7+24i
dim as Complex w = CExp( z )
```

```text
Complex                         ' one type, 16 bytes, DOUBLE only

CSet CPolar  CZero COne CImaginaryOne CNaN CInfinity
CReal CImag CSetReal CSetImag CSwap
CIsNaN CIsInfinite CIsFinite CIsReal CIsZero
CAbs CNorm CArg CLogAbs CConj CNegate CReciprocal CSgn
CExp CLog CLog10 CSqrt CPow CNthRoot
CSin CCos CTan CSec CCsc CCot          CAsin CAcos CAtan CAsec CAcsc CAcot
CSinh CCosh CTanh CSech CCsch CCoth    CAsinh CAcosh CAtanh CAsech CAcsch CAcoth
CToString CToStringPolar

= <> + - * / ^    each in all three arrangements: Complex with Complex,
                  float64 with Complex, Complex with float64
```

### Naming

**Every function carries a `C` prefix.** Exp, Log, Sqr, Sin, Cos, Tan, Abs, Atn and Str are intrinsics, and when this library was headers in namespace FB, a function of one of those names **shadowed** the intrinsic for every later header -- measured, it broke what is now random.tiko -- after which the intrinsic could not be called back. The names stayed when the headers became std/numeric. Given that the transcendentals must be prefixed, the prefix is applied **uniformly**: a mixed scheme would need the reader to know which of `Sin` and `Real` is an intrinsic in order to guess the spelling. The **type** is `Complex`, unprefixed.

`CStr` is a keyword, so the string form is `CToString( z )` -- which also names what it is: the round-tripping form, not STR.

**DOUBLE only, and no macro.** With one element type the bodies are written once, plainly, and are greppable by name.

### Sources

**Numerics from .NET, MIT.** System.Numerics.Complex supplies Smith division, the scaled Abs, Asin_Internal, the stabilised Tan and the predicate set. **It is not followed where it is beaten.**

Two things the old vector header used to get wrong, and both are fixed:

- **`/` was the naive `( ac + bd ) / ( c^2 + d^2 )`.** Its denominator overflows once |d| passes about 1.3e154, so `( 1e200 + 1e200i ) / ( 1e200 + 1e200i )` came back NaN instead of 1. Smith's formula divides through by the larger component first and has no range restriction. All **three** division overloads get it.
- **CSqrt was the polar form**, `FromPolar( sqr(|z|), Arg(z)/2 )`. That is .NET Framework 4.7's, which .NET Core 3.0 replaced because it loses most of its significant digits near the negative real axis, where Arg is the difference of two nearly-equal quantities.

### Nine axis fast paths

Each was put there by a measured failure. A differential run against Python's cmath -- that is, against C99 -- over 3,030 (function, operand) pairs found eight defects, seven of them inherited and one in the platform:

- `CSqrt( -4 - 0i )` returned +2i. .NET tests `imaginary == 0` and hand back the positive root for both sides of their own cut.
- CAsin and CAcos are NaN at exactly +-1: Asin_Internal divides by zero there, so .NET's own `Asin( 1 )` is NaN rather than PI/2.
- .NET tests `imaginary < 0` where it has to test the **sign bit**. A negative zero is not less than zero, so .NET's `Asin( 2 - 0i )` has a **positive** imaginary part where C99 gives a negative one.
- CAtanh beyond +-1 cannot be reached through CAtan: forming `1 + iz` adds +0.0 to -0.0, IEEE gives +0.0, and the bit that decides the side of the cut is gone before the logarithm sees it.
- CAtan of a small pure imaginary cancels: `atan( 1e-8 i )` came out 9.999999994736e-9 for an answer that is 1e-8.
- mingw-w64's `asinh( +0.0 )` returns -0.0. asinh is odd and owes the sign back; that one is the platform's, not .NET's.

After the nine, 3,030 of 3,030 comparisons agree, signed zeros included, except 22 CReciprocal results that differ only in the sign of an exactly-zero component -- C99 Annex G does not specify those and the magnitudes are equal.

### Semantics

- **No ordering operators:** `<` on complex numbers has no meaning. CSgn returns z/|z|, the unit vector in z's direction, and `CZero( )` for zero -- not a LONG from comparing real parts and then imaginary ones, which would be such an ordering under another name.
- **The special values are functions**, not constants: `const as Complex N` cannot be initialised from 0.0/0.0, which is a compile-time division by zero. Same decision, same reason, as `NaN( )` in math.tiko.
- **CIsNaN is not "either part is NaN".** One infinite part and one NaN is **infinite**, because the infinity already answers every question anyone asks of the number.

Two things deliberately not done, stated rather than left to be discovered:

- **No infinity recovery on `*`.** C99's `__muldc3` rescues `( inf + 0i ) * ( 2 + 0i )` from NaN with a branch on every multiply; .NET does not, and neither does this. Pinned by a test so that adding it later is a deliberate act.
- **`CPow( 0, w )` is 0 for every w**, and `CPow( 0, 0 )` is 1. Those are .NET's answers and the last two are wrong -- 0 to a negative power is infinite. Kept for compatibility with .NET, and pinned.

The vendored test suites have no suite for this header, so there is no tiko result to report for it.

## fenv.tiko

```freebasic
scope
    dim r as ScopedRounding = ScopedRounding( ROUND_TOWARD_NEGATIVE )
    ' ... directed-rounding computation ...
end scope                          ' restored on EVERY exit path
```

```text
GetRoundingMode( )  SetRoundingMode( m )
ROUND_TO_NEAREST ROUND_TOWARD_NEGATIVE ROUND_TOWARD_POSITIVE ROUND_TOWARD_ZERO

ClearFpExceptions( )  ClearFpException( e )
TestFpException( e )  RaiseFpException( e )
FP_INVALID FP_DIVBYZERO FP_OVERFLOW FP_UNDERFLOW FP_INEXACT FP_ALL_EXCEPT
```

ScopedRounding is a **constructor**, not a factory: a factory returning by value builds a temporary, copies it, and then **destroys** the temporary -- restoring the mode before the guarded region runs.

**The hazard, stated rather than hidden.** The optimiser may move floating-point operations across a call, and moving one across a rounding-mode change silently produces the wrong answer. C solves this with `#pragma STDC FENV_ACCESS`.

The rounding mode is per-thread on every supported platform.

The constants above are **the library's own**, and are deliberately not the C library's. The C `FE_*` values are not a property of the platform: MSVC, and mingw-w64 since v8, define them in terms of the CRT's abstract `_RC_*` / `_SW_*` codes, while glibc, the BSDs, djgpp and mingw-w64 v7 use the x87 control- and status-word encoding directly. Which family applies is decided by the C runtime the program finally links against -- mingw-w64 changed sides between v7 and v8 without the target changing -- and the compiler cannot know that at compile time, so no `#ifdef` on target can be right. fenv.tiko therefore **detects** the family at startup, by offering the CRT the x87 spelling of FE_DOWNWARD and seeing whether it is accepted, and translates. Getting this wrong is silent, not loud: the two families overlap numerically without agreeing, so x87 FP_DIVBYZERO (&h04) reads as FP_OVERFLOW to a `_SW_*` CRT and fetestexcept cheerfully answers about the wrong flag.

## Exact vs Bounded

What is reproducible: two classes with two different guarantees, and the difference matters if you ship the same program for more than one target.

| Class | Guarantee | Covers |
| --- | --- | --- |
| **Exact** | Identical results everywhere. | All integer arithmetic, all of money.Currency, all of money.Decimal, rounding, classification, Min/Max/Clamp/Sign, the bit family, RNG streams, and vector/matrix arithmetic. |
| **Bounded** | Accurate to a stated ulp bound; the **platform** libm is the dependency. | Every transcendental, Sqr, Hypot, Slerp, everything in Complex beyond the four operators, StdDev's final root, and decimal->binary parsing. |

The second class cannot be the first without shipping correctly-rounded implementations of every transcendental -- a multi-year project that no mainstream language ships by default. glibc, MSVCRT and mingw-w64 do not agree to the last bit and are not required to.

So a financial total is reproducible across your builds and a Sin is not, and this library says which is which instead of implying both.

## Known Limits

All measured.

- **Four decimal places on Currency, fixed.** The central limitation of the eight-byte money type, and the reason `Decimal` exists beside it -- see [Finance](Category-Finance).
- Accuracy of the libm surface is the platform's; results are **not** identical across targets. Rounding, classification and all integer/Currency work **are**.
- `Round( x, digits )` decides the tie on the **scaled** value, so `Round( 2.675, 2 )` is 2.68 where an exact decimal round gives 2.67.
- Shortest-round-trip formatting is a **loop** (format, parse back, retry at higher precision), not Ryu. Same result, up to 17 snprintf/strtod pairs per call.
- Decimal->binary conversion on parse is strtod's. The **validation** is this library's and is strict; the last bit is the platform's.
- Statistics take plain arrays, not the iterator protocol.
- Checked arithmetic is opt-in per call site. It does not catch what you did not audit.
- LONG DOUBLE is not covered; crt/longdouble.bi declares the `l` variants as DOUBLE on this target.
- Nothing folds at compile time: `Round( 2.5 )` on a literal is a run-time call, because constant folding covers operators, not user functions.

## Tests

The fbcunit suites for these modules are vendored in tiko-lang under `tests/vendor/fbc-tests/math/`:

| Suite | What it covers |
| --- | --- |
| core.bas | constants, classification (**exhaustive** over all 2^32 SINGLE bit patterns, plus the population of each class as a checkable property of IEEE 754), selection, rounding at every tie, the two bugs in `int(x+0.5)` pinned, the libm identities |
| integer.bas | all three modulo conventions over every sign combination, DivMod, IPow against an independent reference with 3^38 and 7^22 pinned, ISqrt by its defining property, checked arithmetic at **both** boundaries of **every** integer type |
| bits.bas | **exhaustive** over the whole USHORT and UBYTE domains against naive bit-at-a-time references, the zero and full-width cases, rotation round trips |
| currency.bas | round-trip over the corpus, strict parse rejects, a+b-b = a bitwise, division ties, Invalid propagation through every operator, Apportion summing exactly to the total, the accumulate-vs-round-each-line case |
| text.bas | the four defects demonstrated against VAL and STR, strict parse table, round-trip over a large stratified SINGLE sample and a curated DOUBLE set, shortest-form checks, integer overflow detection, NumFormat |
| random.bas | identical streams from identical seeds, chi-squared uniformity, unbiased range, NextDouble never 1.0, distributions against analytic mean and variance, and **all** 24 permutations of 4 elements observed with equal frequency |
| stats.bas | compensation demonstrated by asserting NaiveSum **fails** the same test, Welford beating the textbook formula on data chosen to make it return a negative variance, non-mutation, Merge |
| vector.bas | identities only -- \|normalize(v)\|=1, cross orthogonal, M\*M-inverse=I, Det(AB)=Det(A)Det(B), q\*conj(q)=1, slerp endpoints, exp(log(z))=z |
| fenv.bas | each mode observably changes a result, ScopedRounding restores on fallthrough / EXIT / RETURN / nested scopes, each exception flag raised by what must raise it |

### Precision note

It decides five assertions across two suites: code evaluated on the x87 with the precision control at 64-bit mantissa keeps an intermediate that is never stored in 80 bits. C99 permits this (FLT_EVAL_METHOD = 2).

This bites the tests that demonstrate a **defect** rather than a result. Each is the counter-example half of a pair -- the naive form getting it wrong, beside the library getting it right -- and each was written assuming the intermediate had been rounded to double. In 80 bits the naive form quietly gets the **right** answer and stops demonstrating anything:

| Expression | Unstored | Stored |
| --- | --- | --- |
| `int( justunder + 0.5 )` | 0 | 1 |
| `sqr( big*big + big*big )` | 1.41e200 | inf |
| `log( 1.0 + 1e-17 )` | 1e-17 | 0 |
| `(3LL ^ 38LL) as longint` | ...089 | ...000 |

So `rounding_beats_the_idiom_` and `libm_surface_` in core.bas, and `ipow_exact_` in integer.bas, store the intermediate first. The store is load-bearing and is asserted in its own right, so a future compiler that keeps 80 bits fails at the cause rather than confusingly downstream.

### Not verified

Stated rather than implied:

- No differential test against OleAut32 `VarCy*` or .NET decimal was run for Currency; it is owed.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Numbers and math](Functions-Numbers) lists them beside the rest of the area.

### Round a number

| Function | What it does | From |
|---|---|---|
| [Round](Modern-Math-Round) | Rounds to the nearest whole number or number of decimals, halves away from zero. | `std/numeric` |
| [RoundHalfEven](Modern-Math-RoundHalfEven) | Rounds to the nearest whole number or number of decimals, halves to the even side. | `std/numeric` |
| [Floor](Modern-Math-Floor) | Rounds down, towards negative infinity, so Floor(-2.1) is -3. | `std/numeric` |
| [Ceil](Modern-Math-Ceil) | Rounds up, towards positive infinity, so Ceil(-2.7) is -2. | `std/numeric` |
| [Truncate](Modern-Math-Truncate) | Drops the fraction, rounding towards zero, so Truncate(-2.7) is -2. | `std/numeric` |
| [Modf](Modern-Math-Modf) | Splits a number into whole and fractional parts that both keep its sign. | `std/numeric` |

### Absolute value, sign, smaller and larger

| Function | What it does | From |
|---|---|---|
| [Sign](Modern-Math-Sign) | Returns -1, 0 or 1 for the sign of a number, always as a Long. | `std/numeric` |
| [Min](Modern-Math-Min) | Returns the smaller of two values; a NaN argument gives NaN. | `std/numeric` |
| [Max](Modern-Math-Max) | Returns the larger of two values; a NaN argument gives NaN. | `std/numeric` |
| [Clamp](Modern-Math-Clamp) | Limits a value to a range: below lo gives lo, above hi gives hi. | `std/numeric` |
| [Lerp](Modern-Math-Lerp) | Returns the point a fraction t of the way from a to b; t is not clamped. | `std/numeric` |

### Powers, roots and logarithms

| Function | What it does | From |
|---|---|---|
| [IPow](Modern-Math-IPow) | Raises a whole number to a whole-number power exactly, with no trip through Double. | `std/numeric` |
| [ISqrt](Modern-Math-ISqrt) | Returns the exact whole-number square root, rounded down. | `std/numeric` |
| [Hypot](Modern-Math-Hypot) | Returns the square root of x*x + y*y without overflowing for large values. | `std/numeric` |
| [Cbrt](Modern-Math-Cbrt) | Returns the cube root of a number, negative numbers included. | `std/numeric` |
| [Exp2](Modern-Math-Exp2) | Returns 2 raised to a power. | `std/numeric` |
| [Expm1](Modern-Math-Expm1) | Returns e raised to a power, minus one, accurately for powers near zero. | `std/numeric` |
| [Log2](Modern-Math-Log2) | Returns the base-2 logarithm of a number. | `std/numeric` |
| [Log10](Modern-Math-Log10) | Returns the base-10 logarithm of a number. | `std/numeric` |
| [Log1p](Modern-Math-Log1p) | Returns the natural logarithm of one plus a number, accurately near zero. | `std/numeric` |
| [Pow](Modern-Math-Pow) | Returns one floating-point number raised to the power of another. | `std/numeric` |

### Trigonometry and angles

| Function | What it does | From |
|---|---|---|
| [DegToRad](Modern-Math-DegToRad) | Converts an angle from degrees to radians. | `std/numeric` |
| [RadToDeg](Modern-Math-RadToDeg) | Converts an angle from radians to degrees. | `std/numeric` |
| [Sinh](Modern-Math-Sinh) | Returns the hyperbolic sine of a number. | `std/numeric` |
| [Cosh](Modern-Math-Cosh) | Returns the hyperbolic cosine of a number. | `std/numeric` |
| [Tanh](Modern-Math-Tanh) | Returns the hyperbolic tangent of a number, which lies between -1 and 1. | `std/numeric` |
| [Asinh](Modern-Math-Asinh) | Returns the inverse hyperbolic sine of a number. | `std/numeric` |
| [Acosh](Modern-Math-Acosh) | Returns the inverse hyperbolic cosine of a number of 1 or more. | `std/numeric` |
| [Atanh](Modern-Math-Atanh) | Returns the inverse hyperbolic tangent of a number between -1 and 1. | `std/numeric` |

### Divide whole numbers

| Function | What it does | From |
|---|---|---|
| [FloorDiv](Modern-Math-FloorDiv) | Divides whole numbers rounding towards negative infinity, so FloorDiv(-7, 2) is -4. | `std/numeric` |
| [FloorMod](Modern-Math-FloorMod) | Returns the remainder with the divisor's sign, so FloorMod(-1, 5) is 4. | `std/numeric` |
| [EuclidDiv](Modern-Math-EuclidDiv) | Divides whole numbers so that the matching EuclidMod remainder is never negative. | `std/numeric` |
| [EuclidMod](Modern-Math-EuclidMod) | Returns a remainder that is never negative, whatever the signs. | `std/numeric` |
| [DivMod](Modern-Math-DivMod) | Returns the quotient and the remainder of one division together, as a tuple. | `std/numeric` |
| [GCD](Modern-Math-GCD) | Returns the greatest common divisor of two whole numbers. | `std/numeric` |
| [LCM](Modern-Math-LCM) | Returns the least common multiple of two whole numbers, or 0 if either is 0. | `std/numeric` |

### Catch, clamp or wrap integer overflow

| Function | What it does | From |
|---|---|---|
| [AddChecked](Modern-Math-AddChecked) | Adds two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [SubChecked](Modern-Math-SubChecked) | Subtracts two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [MulChecked](Modern-Math-MulChecked) | Multiplies two integers, returning an empty Optional if the result would overflow. | `std/numeric` |
| [DivChecked](Modern-Math-DivChecked) | Divides two integers, returning an empty Optional on division by zero or overflow. | `std/numeric` |
| [NegChecked](Modern-Math-NegChecked) | Negates an integer, returning an empty Optional for the most negative value. | `std/numeric` |
| [AbsChecked](Modern-Math-AbsChecked) | Returns the absolute value as an Optional, empty for the most negative value. | `std/numeric` |
| [IPowChecked](Modern-Math-IPowChecked) | Raises an integer to a power, returning an empty Optional if the result overflows. | `std/numeric` |
| [AddSaturating](Modern-Math-AddSaturating) | Adds two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [SubSaturating](Modern-Math-SubSaturating) | Subtracts two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [MulSaturating](Modern-Math-MulSaturating) | Multiplies two integers, clamping the result to the type's minimum or maximum. | `std/numeric` |
| [NegSaturating](Modern-Math-NegSaturating) | Negates an integer; the most negative value becomes the maximum instead. | `std/numeric` |
| [AbsSaturating](Modern-Math-AbsSaturating) | Returns the absolute value; the most negative value becomes the maximum instead. | `std/numeric` |
| [AddWrapping](Modern-Math-AddWrapping) | Adds two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [SubWrapping](Modern-Math-SubWrapping) | Subtracts two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [MulWrapping](Modern-Math-MulWrapping) | Multiplies two integers and wraps around on overflow, on purpose. | `std/numeric` |
| [NegWrapping](Modern-Math-NegWrapping) | Negates an integer within its type, so the most negative value stays as it is. | `std/numeric` |

### Convert between numbers and text

| Function | What it does | From |
|---|---|---|
| [TryParseDouble](Modern-Math-TryParseDouble) | Parses a whole string as a Double, returning an empty Optional if it is not one. | `std/numeric` |
| [TryParseSingle](Modern-Math-TryParseSingle) | Parses a whole string as a Single, returning an empty Optional if it is not one. | `std/numeric` |
| [TryParseLong](Modern-Math-TryParseLong) | Parses a whole string as a Long, returning an empty Optional if invalid or too big. | `std/numeric` |
| [TryParseULong](Modern-Math-TryParseULong) | Parses a whole string as a ULong, returning an empty Optional if invalid or too big. | `std/numeric` |
| [TryParseLongInt](Modern-Math-TryParseLongInt) | Parses a whole string as a LongInt, in an optional base; empty if invalid or too big. | `std/numeric` |
| [TryParseULongInt](Modern-Math-TryParseULongInt) | Parses a whole string as a ULongInt, returning an empty Optional if invalid or too big. | `std/numeric` |
| [ToString](Modern-Math-ToString) | Returns a number as the shortest text that reads back as exactly the same value. | `std/numeric` |
| [CurrentLocaleFormat](Modern-Math-CurrentLocaleFormat) | Returns a NumFormat holding this machine's decimal and thousands separators. | `std/numeric` |

### Random numbers

| Function | What it does | From |
|---|---|---|
| [RngSeeded](Modern-Math-RngSeeded) | Creates a random generator from a seed, so the same seed repeats the same sequence. | `std/numeric` |
| [RngFromEntropy](Modern-Math-RngFromEntropy) | Creates a random generator seeded by the operating system, different on every run. | `std/numeric` |
| [Rng.NextInt](Modern-Math-NextInt) | Returns a random whole number from lo to hi, both included, without bias. | `std/numeric` |
| [Rng.NextDouble](Modern-Math-NextDouble) | Returns a random Double from 0 up to but not including 1, with 53 random bits. | `std/numeric` |
| [Rng.NextDoubleRange](Modern-Math-NextDoubleRange) | Returns a random Double from lo up to but not including hi. | `std/numeric` |
| [Rng.NextSingle](Modern-Math-NextSingle) | Returns a random Single from 0 up to but not including 1. | `std/numeric` |
| [Rng.NextULong](Modern-Math-NextULong) | Returns a random 32-bit unsigned value. | `std/numeric` |
| [Rng.NextULongInt](Modern-Math-NextULongInt) | Returns a random 64-bit unsigned value, the generator's raw output. | `std/numeric` |
| [Rng.NextBoolean](Modern-Math-NextBoolean) | Returns true or false with equal chance. | `std/numeric` |
| [Rng.NextBooleanP](Modern-Math-NextBooleanP) | Returns true with probability p, from 0 for never to 1 for always. | `std/numeric` |
| [Rng.NextNormal](Modern-Math-NextNormal) | Returns a random value from the normal distribution, mean 0 and standard deviation 1. | `std/numeric` |
| [Rng.NextNormalP](Modern-Math-NextNormalP) | Returns a random value from a normal distribution with the given mean and deviation. | `std/numeric` |
| [Rng.NextExponential](Modern-Math-NextExponential) | Returns a random waiting time between events at rate lambda; its mean is 1/lambda. | `std/numeric` |
| [Rng.NextPoisson](Modern-Math-NextPoisson) | Returns a random count of events in one interval at rate lambda; its mean is lambda. | `std/numeric` |
| [Shuffle](Modern-Math-Shuffle) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [Choice](Modern-Math-Choice) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |
| [ShuffleArray](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ShuffleDeque](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ShuffleList](Modern-Math-Shuffle#containers) | Shuffles an array or container in place so that every order is equally likely. | `std/numeric` |
| [ChoiceArray](Modern-Math-Choice#containers) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |
| [ChoiceDeque](Modern-Math-Choice#containers) | Returns one element of an array or container picked at random, by reference. | `std/numeric` |

### Secure random bytes

| Function | What it does | From |
|---|---|---|
| [CryptoBytes](Modern-Math-CryptoBytes) | Fills a buffer with secure random bytes from the operating system; false on failure. | `std/numeric` |
| [CryptoULongInt](Modern-Math-CryptoULongInt) | Returns a secure random 64-bit value from the operating system. | `std/numeric` |

### NaN, infinity and other special values

| Function | What it does | From |
|---|---|---|
| [IsNaN](Modern-Math-IsNaN) | Returns true if the value is NaN, which an equality test cannot detect. | `std/numeric` |
| [IsInfinite](Modern-Math-IsInfinite) | Returns true if the value is plus or minus infinity. | `std/numeric` |
| [IsFinite](Modern-Math-IsFinite) | Returns true if the value is neither infinite nor NaN. | `std/numeric` |
| [IsNormal](Modern-Math-IsNormal) | Returns true if the value is finite, not zero and not subnormal. | `std/numeric` |
| [IsSubnormal](Modern-Math-IsSubnormal) | Returns true if the value is nonzero but below the smallest normal number. | `std/numeric` |
| [IsNegative](Modern-Math-IsNegative) | Returns true if the sign bit is set, which includes negative zero. | `std/numeric` |
| [Classify](Modern-Math-Classify) | Returns whether a value is NaN, infinite, zero, subnormal or normal. | `std/numeric` |
| [NaN](Modern-Math-NaN) | Returns a Double that is NaN, not a number. | `std/numeric` |
| [NaNF](Modern-Math-NaNF) | Returns a Single that is NaN, not a number. | `std/numeric` |
| [Infinity](Modern-Math-Infinity) | Returns positive infinity as a Double. | `std/numeric` |
| [InfinityF](Modern-Math-InfinityF) | Returns positive infinity as a Single. | `std/numeric` |
| [NegInfinity](Modern-Math-NegInfinity) | Returns negative infinity as a Double. | `std/numeric` |
| [NegInfinityF](Modern-Math-NegInfinityF) | Returns negative infinity as a Single. | `std/numeric` |
| [MinSubnormalDouble](Modern-Math-MinSubnormalDouble) | Returns the smallest Double above zero. | `std/numeric` |
| [MinSubnormalSingle](Modern-Math-MinSubnormalSingle) | Returns the smallest Single above zero. | `std/numeric` |

### Look inside floating-point numbers

| Function | What it does | From |
|---|---|---|
| [Frexp](Modern-Math-Frexp) | Splits a number into a fraction from 0.5 to 1 and a power of two. | `std/numeric` |
| [ScaleB](Modern-Math-ScaleB) | Multiplies a number by a power of two exactly, by adjusting its exponent. | `std/numeric` |
| [Ulp](Modern-Math-Ulp) | Returns the gap between a number and the next one its type can hold. | `std/numeric` |
| [Fma](Modern-Math-Fma) | Returns x * y + z with a single rounding at the end. | `std/numeric` |
| [LogB](Modern-Math-LogB) | Returns the binary exponent of a number as a floating-point value. | `std/numeric` |
| [CopySign](Modern-Math-CopySign) | Returns a number's size with the sign of a second number, zero's sign included. | `std/numeric` |
| [NextAfter](Modern-Math-NextAfter) | Returns the next representable number after x in the direction of y. | `std/numeric` |

### Control floating-point rounding and exceptions

| Function | What it does | From |
|---|---|---|
| [GetRoundingMode](Modern-Math-GetRoundingMode) | Returns the direction floating-point results are currently rounded in. | `std/numeric` |
| [SetRoundingMode](Modern-Math-SetRoundingMode) | Sets the direction floating-point results are rounded in; returns true on success. | `std/numeric` |
| [ClearFpExceptions](Modern-Math-ClearFpExceptions) | Clears every floating-point exception flag. | `std/numeric` |
| [ClearFpException](Modern-Math-ClearFpException) | Clears one floating-point exception flag and leaves the others alone. | `std/numeric` |
| [TestFpException](Modern-Math-TestFpException) | Returns true if a floating-point exception flag has been raised since it was cleared. | `std/numeric` |
| [RaiseFpException](Modern-Math-RaiseFpException) | Raises a floating-point exception flag by hand; returns true on success. | `std/numeric` |

### Count, reverse and swap bits

| Function | What it does | From |
|---|---|---|
| [PopCount](Modern-Math-PopCount) | Counts the bits that are set. | `std/numeric` |
| [LeadingZeros](Modern-Math-LeadingZeros) | Counts the zero bits above the highest set bit; zero gives the type's full width. | `std/numeric` |
| [TrailingZeros](Modern-Math-TrailingZeros) | Counts the zero bits below the lowest set bit; zero gives the type's full width. | `std/numeric` |
| [BitWidth](Modern-Math-BitWidth) | Returns how many bits the value needs, or 0 for zero. | `std/numeric` |
| [Parity](Modern-Math-Parity) | Returns 1 if an odd number of bits are set, or 0 if an even number are. | `std/numeric` |
| [BitReverse](Modern-Math-BitReverse) | Reverses the order of all the bits in the value's type. | `std/numeric` |
| [ByteSwap](Modern-Math-ByteSwap) | Reverses the order of the bytes, converting between big-endian and little-endian. | `std/numeric` |
| [IsPow2](Modern-Math-IsPow2) | Returns true if the value is a power of two; zero is not one. | `std/numeric` |
| [NextPow2](Modern-Math-NextPow2) | Returns the smallest power of two at or above the value; zero gives 1. | `std/numeric` |

### Summarise an array of numbers

| Function | What it does | From |
|---|---|---|
| [Sum](Modern-Math-Sum) | Adds up an array with compensated summation, so small values are not lost. | `std/numeric` |
| [NaiveSum](Modern-Math-NaiveSum) | Adds up an array with a plain loop: faster than Sum, but small values can be lost. | `std/numeric` |
| [Count](Modern-Math-Count) | Counts the elements in an array. | `std/numeric` |
| [Mean](Modern-Math-Mean) | Returns the average of an array, or NaN if it is empty. | `std/numeric` |
| [Median](Modern-Math-Median) | Returns the middle value of an array, without reordering it. | `std/numeric` |
| [Percentile](Modern-Math-Percentile) | Returns the value below which p percent of an array falls, with p from 0 to 100. | `std/numeric` |
| [Variance](Modern-Math-Variance) | Returns the sample variance of an array, dividing by n-1. | `std/numeric` |
| [VariancePopulation](Modern-Math-VariancePopulation) | Returns the population variance of an array, dividing by n. | `std/numeric` |
| [StdDev](Modern-Math-StdDev) | Returns the sample standard deviation of an array, dividing by n-1. | `std/numeric` |
| [StdDevPopulation](Modern-Math-StdDevPopulation) | Returns the population standard deviation of an array, dividing by n. | `std/numeric` |
| [MinOf](Modern-Math-MinOf) | Returns the smallest value in an array, or NaN if it is empty. | `std/numeric` |
| [MaxOf](Modern-Math-MaxOf) | Returns the largest value in an array, or NaN if it is empty. | `std/numeric` |
| [Range](Modern-Math-Range) | Returns the largest value in an array minus the smallest. | `std/numeric` |
| [Covariance](Modern-Math-Covariance) | Returns the sample covariance of two arrays of the same length. | `std/numeric` |
| [Correlation](Modern-Math-Correlation) | Returns the Pearson correlation of two arrays, from -1 to 1. | `std/numeric` |

### Keep running statistics

| Function | What it does | From |
|---|---|---|
| [RunningStats.Add](Modern-Math-Add) | Adds one value to a running count, mean, variance, minimum and maximum. | `std/numeric` |
| [RunningStats.Merge](Modern-Math-Merge) | Combines another accumulator's values into this one, exactly. | `std/numeric` |
| [RunningStats.Reset](Modern-Math-Reset) | Empties the accumulator so that it can be reused. | `std/numeric` |
| [RunningStats.MinValue](Modern-Math-MinValue) | Returns the smallest value added so far. | `std/numeric` |
| [RunningStats.MaxValue](Modern-Math-MaxValue) | Returns the largest value added so far. | `std/numeric` |

### Vectors

| Function | What it does | From |
|---|---|---|
| [Dot](Modern-Math-Dot) | Returns the dot product of two vectors; zero means they are perpendicular. | `std/numeric` |
| [Cross](Modern-Math-Cross) | Returns a Vec3 perpendicular to both inputs; swapping them flips its direction. | `std/numeric` |
| [Mul](Modern-Math-Mul) | Multiplies two vectors component by component. | `std/numeric` |
| [Length](Modern-Math-Length) | Returns the length of a vector. | `std/numeric` |
| [LengthSquared](Modern-Math-LengthSquared) | Returns the squared length of a vector, the cheap way to compare lengths. | `std/numeric` |
| [Distance](Modern-Math-Distance) | Returns the distance between two points. | `std/numeric` |
| [DistanceSquared](Modern-Math-DistanceSquared) | Returns the squared distance between two points, the cheap way to test a range. | `std/numeric` |
| [Normalize](Modern-Math-Normalize) | Returns a vector of length 1 in the same direction; a zero vector stays zero. | `std/numeric` |
| [Reflect](Modern-Math-Reflect) | Reflects a vector off a surface, given the surface's normalised normal. | `std/numeric` |
| [Angle](Modern-Math-Angle) | Returns the angle between two vectors in radians, from 0 to pi. | `std/numeric` |

### Matrices and rotations

| Function | What it does | From |
|---|---|---|
| [Determinant](Modern-Math-Determinant) | Returns the determinant of a matrix; zero means it has no inverse. | `std/numeric` |
| [Transpose](Modern-Math-Transpose) | Returns a matrix with its rows and columns swapped. | `std/numeric` |
| [TryInverse](Modern-Math-TryInverse) | Writes the inverse of a matrix into a second one, or returns false if there is none. | `std/numeric` |
| [TransformPoint](Modern-Math-TransformPoint) | Applies a matrix to a point, translation included. | `std/numeric` |
| [TransformVector](Modern-Math-TransformVector) | Applies a matrix to a direction, leaving out the translation. | `std/numeric` |
| [Conjugate](Modern-Math-Conjugate) | Returns the conjugate of a quaternion, the reverse rotation when it is normalised. | `std/numeric` |
| [Rotate](Modern-Math-Rotate) | Rotates a vector by a normalised quaternion. | `std/numeric` |
| [ToMatrix](Modern-Math-ToMatrix) | Converts a quaternion into the matching rotation matrix. | `std/numeric` |
| [Slerp](Modern-Math-Slerp) | Blends between two rotations at constant speed, taking the shorter way round. | `std/numeric` |

### Complex numbers: build, read and print

| Function | What it does | From |
|---|---|---|
| [Complex](Modern-Math-Complex) | Holds a complex number as two Doubles, re and im. | `std/numeric` |
| [Complex operators](Modern-Math-Complex-Operators) | Adds, subtracts, multiplies, divides, raises and compares complex numbers. | `std/numeric` |
| [CSet](Modern-Math-CSet) | Builds a complex number from its real and imaginary parts. | `std/numeric` |
| [CPolar](Modern-Math-CPolar) | Builds a complex number from a modulus and an angle in radians. | `std/numeric` |
| [CZero](Modern-Math-CZero) | Returns the complex number 0. | `std/numeric` |
| [COne](Modern-Math-COne) | Returns the complex number 1. | `std/numeric` |
| [CImaginaryOne](Modern-Math-CImaginaryOne) | Returns the imaginary unit i. | `std/numeric` |
| [CNaN](Modern-Math-CNaN) | Returns a complex number whose two parts are both NaN. | `std/numeric` |
| [CInfinity](Modern-Math-CInfinity) | Returns a complex number whose two parts are both positive infinity. | `std/numeric` |
| [CReal](Modern-Math-CReal) | Returns the real part of a complex number. | `std/numeric` |
| [CImag](Modern-Math-CImag) | Returns the imaginary part of a complex number, without the i. | `std/numeric` |
| [CSetReal](Modern-Math-CSetReal) | Sets the real part of a complex variable in place. | `std/numeric` |
| [CSetImag](Modern-Math-CSetImag) | Sets the imaginary part of a complex variable in place. | `std/numeric` |
| [CSwap](Modern-Math-CSwap) | Swaps the values of two complex variables. | `std/numeric` |
| [CToString](Modern-Math-CToString) | Returns a complex number as text such as 3+4i that reads back exactly. | `std/numeric` |
| [CToStringPolar](Modern-Math-CToStringPolar) | Returns a complex number as polar text, such as 5 * exp(0.927i). | `std/numeric` |

### Complex numbers: test and measure

| Function | What it does | From |
|---|---|---|
| [CIsNaN](Modern-Math-CIsNaN) | Returns true if a complex number is NaN; one infinite part makes it infinite instead. | `std/numeric` |
| [CIsInfinite](Modern-Math-CIsInfinite) | Returns true if either part of a complex number is infinite. | `std/numeric` |
| [CIsFinite](Modern-Math-CIsFinite) | Returns true if both parts of a complex number are finite. | `std/numeric` |
| [CIsReal](Modern-Math-CIsReal) | Returns true if the imaginary part of a complex number is zero. | `std/numeric` |
| [CIsZero](Modern-Math-CIsZero) | Returns true if both parts of a complex number are zero. | `std/numeric` |
| [CAbs](Modern-Math-CAbs) | Returns the modulus, the distance from zero, without overflowing for large parts. | `std/numeric` |
| [CNorm](Modern-Math-CNorm) | Returns the modulus squared, the cheap way to compare sizes. | `std/numeric` |
| [CArg](Modern-Math-CArg) | Returns the phase angle of a complex number in radians, from -pi to pi. | `std/numeric` |
| [CLogAbs](Modern-Math-CLogAbs) | Returns the logarithm of the modulus, without overflowing for large parts. | `std/numeric` |
| [CConj](Modern-Math-CConj) | Returns the conjugate, the same number with its imaginary part negated. | `std/numeric` |
| [CNegate](Modern-Math-CNegate) | Returns a complex number with both parts negated. | `std/numeric` |
| [CReciprocal](Modern-Math-CReciprocal) | Returns one divided by a complex number; zero gives zero. | `std/numeric` |
| [CSgn](Modern-Math-CSgn) | Returns a complex number scaled to modulus 1, or zero for zero. | `std/numeric` |

### Complex numbers: powers, roots and logarithms

| Function | What it does | From |
|---|---|---|
| [CExp](Modern-Math-CExp) | Returns e raised to a complex power. | `std/numeric` |
| [CLog](Modern-Math-CLog) | Returns the natural logarithm of a complex number, or its logarithm to a given base. | `std/numeric` |
| [CLog10](Modern-Math-CLog10) | Returns the base-ten logarithm of a complex number. | `std/numeric` |
| [CSqrt](Modern-Math-CSqrt) | Returns the principal square root of a complex number or of a negative real. | `std/numeric` |
| [CPow](Modern-Math-CPow) | Raises a complex or real number to a complex or real power. | `std/numeric` |
| [CNthRoot](Modern-Math-CNthRoot) | Returns any one of the n nth roots of a complex number. | `std/numeric` |

### Complex numbers: trigonometry

| Function | What it does | From |
|---|---|---|
| [CSin](Modern-Math-CSin) | Returns the sine of a complex number. | `std/numeric` |
| [CCos](Modern-Math-CCos) | Returns the cosine of a complex number. | `std/numeric` |
| [CTan](Modern-Math-CTan) | Returns the tangent of a complex number, finite even for a large imaginary part. | `std/numeric` |
| [CSec](Modern-Math-CSec) | Returns the secant of a complex number, one over the cosine. | `std/numeric` |
| [CCsc](Modern-Math-CCsc) | Returns the cosecant of a complex number, one over the sine; zero gives zero. | `std/numeric` |
| [CCot](Modern-Math-CCot) | Returns the cotangent of a complex number, one over the tangent. | `std/numeric` |
| [CAsin](Modern-Math-CAsin) | Returns the inverse sine of a complex number, or of any real number. | `std/numeric` |
| [CAcos](Modern-Math-CAcos) | Returns the inverse cosine of a complex number, or of any real number. | `std/numeric` |
| [CAtan](Modern-Math-CAtan) | Returns the inverse tangent of a complex number. | `std/numeric` |
| [CAsec](Modern-Math-CAsec) | Returns the inverse secant of a complex number, or of any real number. | `std/numeric` |
| [CAcsc](Modern-Math-CAcsc) | Returns the inverse cosecant of a complex number, or of any real number. | `std/numeric` |
| [CAcot](Modern-Math-CAcot) | Returns the inverse cotangent of a complex number; zero gives zero. | `std/numeric` |
| [CSinh](Modern-Math-CSinh) | Returns the hyperbolic sine of a complex number. | `std/numeric` |
| [CCosh](Modern-Math-CCosh) | Returns the hyperbolic cosine of a complex number. | `std/numeric` |
| [CTanh](Modern-Math-CTanh) | Returns the hyperbolic tangent of a complex number. | `std/numeric` |
| [CSech](Modern-Math-CSech) | Returns the hyperbolic secant of a complex number, one over its cosh. | `std/numeric` |
| [CCsch](Modern-Math-CCsch) | Returns the hyperbolic cosecant of a complex number, one over its sinh; zero gives zero. | `std/numeric` |
| [CCoth](Modern-Math-CCoth) | Returns the hyperbolic cotangent of a complex number, one over its tanh. | `std/numeric` |
| [CAsinh](Modern-Math-CAsinh) | Returns the inverse hyperbolic sine of a complex number. | `std/numeric` |
| [CAcosh](Modern-Math-CAcosh) | Returns the inverse hyperbolic cosine of a complex number, or of any real number. | `std/numeric` |
| [CAtanh](Modern-Math-CAtanh) | Returns the inverse hyperbolic tangent of a complex number, or of any real number. | `std/numeric` |
| [CAsech](Modern-Math-CAsech) | Returns the inverse hyperbolic secant of a complex number. | `std/numeric` |
| [CAcsch](Modern-Math-CAcsch) | Returns the inverse hyperbolic cosecant of a complex number. | `std/numeric` |
| [CAcoth](Modern-Math-CAcoth) | Returns the inverse hyperbolic cotangent of a complex number. | `std/numeric` |

<!-- finder:end -->

---

[Home](Home) · [Keyword Index](Keyword-Index)
