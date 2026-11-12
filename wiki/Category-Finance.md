[Home](Home) › [All Categories](Categories) › **Finance**

# Finance

```freebasic
#import "std/money"

using money
```

A module is imported whole. Its files, in `pkg/std/money/`, are `currency.tiko` and
`decimal.tiko` for the money types, and `finerror.tiko`, `fincore.tiko`, `finsolve.tiko`,
`fintvm.tiko`, `finloan.tiko`, `fincash.tiko`, `findeprec.tiko`, `finport.tiko` for the
finance functions.

This category is in two halves. **The money types** come first, because everything else
is built on them. **The finance functions** follow -- interest and rate conventions, the
time value of money, loans and amortization schedules, cash-flow appraisal, depreciation,
and portfolio returns and risk.

---

## The money types

An amount held in a `DOUBLE` is one rounding away from a penny that does not reconcile, because `0.1 + 0.2 <> 0.3` in binary floating point. These two types are the answer, and which one you want is a single question: **is four decimal places enough?**

| | `Currency` | `Decimal` |
|---|---|---|
| representation | `LONGINT` scaled by 10,000 | 96-bit mantissa + scale + sign |
| range | ±922,337,203,685,477.5807 | ±79,228,162,514,264,337,593,543,950,335 |
| decimal places | 4, always | 0..28, per value |
| significant digits | 19 | 28-29 |
| size | 8 bytes | 16 bytes |
| add | one instruction | software multi-precision |
| the type it already is | VB6/VBA `Currency`, COM `CY`, SQL Server `money` | .NET `System.Decimal`, COM `DECIMAL`, SQL Server `decimal(28,s)` |

**Use `Currency` when four places is enough.** It is the cheaper type by a wide margin and this category does not deprecate it. Use `Decimal` when four places is the thing standing in the way -- FX rates quoted to six or eight, per-unit costs, per-mille rates, interest accrual, tax tables. `DecimalFromCurrency( c )` and `d.ToCurrency( )` convert between them.

**Neither is a new representation.** Both are shapes that Windows, COM and SQL Server have used for decades: `win\wtypes.bi` declares `tagCY` at line 326 and `tagDEC` at line 329. Each type here has the matching layout, so the interop boundary is a reinterpret rather than a conversion.

**No arithmetic is delegated to OleAut32.** This compiler ships and gates on linux-x86_64 and macos-arm64, so the arithmetic is implemented in tiko and `VarCy*`, `VarDec*` and .NET itself are test oracles rather than dependencies. Both types behave identically on every target.

**One set of rules, not two.** The two types deliberately agree on everything they can:

- **Construction is by free function, not constructor.** A one-argument constructor taking `LONGINT` would also accept a `DOUBLE` through implicit conversion, so `Currency( 19.99 )` would have compiled and stored 19. Naming every conversion means the inexact one cannot be reached by accident.
- **Half-to-even is the default,** because half-up biases every tie the same way and across a million lines that is real money. The mode names match: `CUR_HALF_EVEN` / `DEC_HALF_EVEN` and their six siblings.
- **Overflow is `Invalid`, it is infectious, and `Invalid = Invalid` is FALSE** -- the same rule `std/chrono` uses for `DateTime`. Test with `IsValid( )`. A default-constructed value is zero and valid.
- **Text is exact both ways,** with no `DOUBLE` anywhere in the path, and parsing is strict: the whole string must be consumed, and more than the type's decimal places is an error rather than a truncation.
- **`Apportion` splits a total so the parts sum exactly to it.** Largest-remainder, in both types.

### Currency

Defined in `currency.tiko`.

```freebasic
dim as Currency price = CurrencyParse( "19.99" ).Value( )
dim as Currency line_ = price * 3            ' EXACT
print line_.ToString( )                      ' 59.9700
```

**A LONGINT scaled by 10,000.** Fifteen digits left of the point, four to the right, every value in range exactly representable.

```text
range        -922,337,203,685,477.5808 .. +922,337,203,685,477.5807
resolution   0.0001 exactly, everywhere
size         8 bytes
```

This is the VB6/VBA Currency type, the COM CY / VT_CY type, and SQL Server's money. `CY` is already declared in `win\wtypes.bi`, line 326, as a union whose int64 member is exactly this field, so the interop boundary is a reinterpret.

**The cost, up front: four decimal places, fixed.** FX rates are quoted to 6 or 8, per-unit costs and per-mille rates often need more, and a Currency cannot hold them. CurrencyAccum covers the case that actually loses money; it does not cover storage. If you need to *store* more than four places, this is the wrong type.

#### Construction is by free function

```text
CurrencyFromInt( n )         CurrencyFromRaw( scaled )
CurrencyFromParts( w, tt )   CurrencyFromDouble( d )
CurrencyParse( s ) -> Optional( of Currency )
```

A one-argument constructor taking LONGINT would also accept a DOUBLE through implicit conversion, so `Currency( 19.99 )` would have compiled and stored 19. Naming every conversion means the inexact one cannot be reached by accident.

#### Arithmetic

```text
a + b, a - b        EXACT, overflow-checked
a * n  (integer)    EXACT, overflow-checked
a * x  (float64)    rounded half-to-even
a / n  (integer)    rounded HALF-TO-EVEN, not truncated
a / b  (Currency)   DOUBLE -- a ratio is not an amount
a MOD b, -a, comparisons
```

**`Currency * Currency` does not exist**: money times money is not money.

**Division rounds; it does not truncate:**

```freebasic
Currency(1) / 3     ' 0.3333
Currency(2) / 3     ' 0.6667      -- truncation would give 0.6666
```

Truncation biases every result downward, systematically, across a ledger.

**Overflow is `Invalid`, it is infectious, and `Invalid = Invalid` is FALSE** -- the same rule as DateTime. Test with `IsValid( )`. A default-constructed Currency is zero and valid: zero is the meaningful default for money.

#### Rounding and apportioning

```text
c.Round( digits )                    half-to-even, digits 0..4
c.RoundMode( digits, mode )          CUR_HALF_EVEN CUR_HALF_UP
                                     CUR_HALF_DOWN CUR_UP CUR_DOWN
                                     CUR_CEILING CUR_FLOOR
c.Floor( ) c.Ceiling( ) c.Truncate( ) c.AbsValue( ) c.Sign( )

Apportion( total, weights( ), result( ) )
```

Apportion is the most useful function here. Splitting 100.00 three ways gives 33.3333 each, whose sum is 99.9999. Every accounting system has to decide where the missing unit goes, and doing it ad hoc is how a reconciliation fails. Largest-remainder: **the parts always sum to the total, exactly.**

```text
33.3334 + 33.3333 + 33.3333 = 100.0000
```

#### Accumulating below 0.0001

```freebasic
dim acc as CurrencyAccum
acc.Reset( )
for each line_ in invoice
    acc.AddProduct( line_.amount, taxRate )
next
dim as Currency tax = acc.Total( )        ' quantised ONCE
```

versus the version that loses money, which rounds at every line. The accumulator carries eight extra decimal places in a 128-bit value. `AddScaled( c, num, den )` is the exact form; `Add( c )` is exact addition.

#### Text

Text is exact both ways -- no DOUBLE anywhere in the path. ToString always prints four decimals, invariant separator, no grouping. **More than four decimal places on input is an error, not a truncation:**

```freebasic
CurrencyParse( "1.23456" )      ' empty -- not silently 1.2345
```

### Decimal

Defined in `decimal.tiko`.

```freebasic
dim as Decimal price = DecimalParse( "19.99" ).Value( )
dim as Decimal line_ = price * 3             ' 59.97   EXACT
dim as Decimal rate  = DecimalParse( "0.0825" ).Value( )
print ( line_ * rate ).ToString( )           ' 4.947525  EXACT, six places
```

**A 96-bit integer, a scale, and a sign.** The value is `( -1 ^ sign ) * mantissa / 10 ^ scale`, with mantissa in 0 .. 2^96-1 and scale in 0 .. 28.

```text
range        -79,228,162,514,264,337,593,543,950,335
              .. +79,228,162,514,264,337,593,543,950,335
precision    28-29 significant decimal digits
smallest     0.0000000000000000000000000001   (1e-28)
size         16 bytes
```

This is the .NET System.Decimal of C# and VB.NET, the COM DECIMAL / VT_DECIMAL type, and SQL Server's decimal(28,s). `win\wtypes.bi` declares `tagDEC` at line 329, and money.Decimal has the same sixteen bytes in the same order, so the interop boundary is a reinterpret rather than a conversion.

**Why, given Currency already exists?** Currency is four decimal places, fixed, in eight bytes, and its own source says up front that this is its central limitation. FX rates quoted to six or eight places, per-unit costs, per-mille rates and interest accrual all need more.

```text
Currency    +-922,337,203,685,477.5807      4 places, always      8 bytes
Decimal     +-7.9228162514264337e28         0..28, per value     16 bytes
```

The cost is size and speed: Currency's add is one instruction, Decimal's is software multi-precision. **If four places is enough, use Currency** -- Decimal does not deprecate it, and `DecimalFromCurrency( c )` / `d.ToCurrency( )` convert between them.

**The scale is part of the value, not part of the formatting.** 1.10 and 1.1 are equal, print differently, and report different scales -- exactly as in .NET. That is what lets a price read back from a file print the way it was written.

```freebasic
DecimalParse( "1.10" ).Value( ).ToString( )       ' 1.10
DecimalParse( "1.1"  ).Value( ).ToString( )       ' 1.1
DecimalParse( "1.10" ).Value( ) = _
    DecimalParse( "1.1" ).Value( )                ' TRUE
```

#### Construction is by free function

```text
DecimalZero( )      DecimalOne( )        DecimalMinusOne( )
DecimalMinValue( )  DecimalMaxValue( )   DecimalInvalid( )
DecimalFromInt( n )                   DecimalFromUInt( u )
DecimalFromScaled( mantissa, scale )  DecimalFromParts( lo, mid, hi, neg, scale )
DecimalFromDouble( d )                DecimalFromCurrency( c )
DecimalParse( s ) -> Optional( of Decimal )
```

A one-argument constructor taking LONGINT would also accept a DOUBLE through implicit conversion, so `Decimal( 19.99 )` would have compiled and stored 19. Naming every conversion means the inexact one cannot be reached by accident.

#### Arithmetic

```text
a + b, a - b        EXACT.  Scale = max( scale a, scale b ).
-a                  EXACT
a * b               EXACT at scale a + scale b
a / b               the terminating quotient when there is one, 28 digits
                    when there is not, rounded HALF-TO-EVEN
a MOD b             EXACT.  Sign follows the DIVIDEND.
a <op> n            n as LONGINT, on either side, for + - * /
```

**Unlike Currency, `Decimal * Decimal` and `Decimal / Decimal` exist.** Currency is an *amount* and money times money has the wrong units; Decimal is a *number* that happens to be decimal -- which is what .NET's type is -- and rates, factors and ratios are its ordinary business. There is deliberately no Decimal-and-DOUBLE operator: a DOUBLE is inexact, and DecimalFromDouble has to be written out so that it can be seen.

**Division rounds; it does not truncate:**

```text
1 / 3       0.3333333333333333333333333333
2 / 3       0.6666666666666666666666666667      ' truncation gives ...6666
1 / 4       0.25            ' the expansion terminates, so it stops there
100.00 / 4  25.00           ' and the scale the operands implied is kept
1 / 0       Invalid         ' not a trap and not a wrong number
```

**Overflow is `Invalid`, it is infectious, and `Invalid = Invalid` is FALSE** -- the same rule as Currency and DateTime. Test with `IsValid( )`. Every ordering comparison against an Invalid is FALSE, and DecimalCompare returns -2, which is no ordering at all. A default-constructed Decimal is zero and valid.

#### Members

```text
IsValid( ) IsZero( ) IsNegative( ) Sign( ) Scale( )
Lo( ) Mid( ) Hi( )                     ' the three mantissa limbs
ToString( )                            ' exact, EXACTLY 'scale' decimals
ToStringFixed( digits )                ' Rescale then ToString
ToDouble( )                            ' BOUNDED, named
ToLongInt( ) -> Optional( of int64 )   ' truncates; None if it will not fit
ToCurrency( )                          ' half-to-even to four places
Round( digits )                        ' half-to-even, 0..28
RoundMode( digits, mode )              ' DEC_HALF_EVEN DEC_HALF_UP
                                       ' DEC_HALF_DOWN DEC_UP DEC_DOWN
                                       ' DEC_CEILING DEC_FLOOR
Rescale( digits )                      ' forces the scale, up or down
Normalize( )                           ' strips trailing zeros
Floor( ) Ceiling( ) Truncate( ) AbsValue( )
DecimalCompare( a, b )                 ' -1 0 +1, and -2 for Invalid
DecimalApportion( total, scale, weights( ), result( ) )
```

**Round never increases the scale**, exactly as .NET's decimal.Round does; Rescale is the one that grows it.

Apportion is the most useful function here. Splitting 100.00 three ways gives 33.33 each, whose sum is 99.99. Every accounting system has to decide where the missing cent goes, and doing it ad hoc is how a reconciliation fails. Largest-remainder: **the parts always sum to the total, exactly** -- 33.34 + 33.33 + 33.33 = 100.00.

There is no DecimalAccum. Currency needed one because rounding at every line loses money at four places; Decimal has twenty-eight and its addition is exact, so the accumulator is just `+`.

#### Text

Text is exact both ways -- no DOUBLE anywhere in the parse or the print. **Parsing is strict**: the whole string must be consumed, and more than 28 decimal places is an error rather than a truncation.

```freebasic
DecimalParse( "12abc" )      ' empty -- not a prefix parse
DecimalParse( "1e3" )        ' empty -- there is no exponent grammar
DecimalParse( "0.000000000000000000000000000001" )
                             ' empty -- 29 places, not a silent 28
```

#### Verified against .NET

The point of naming an existing type is that an oracle already exists. 24,000 random operand pairs across `+`, `-`, `*`, `/` and `MOD`: 23,283 identical to .NET, value and scale. The 717 that differ are two deliberate classes -- 657 MOD cases where .NET pre-rounds or throws and this returns the exact remainder (checked against arbitrary precision: this is exact in all 657, and .NET in 2), and 60 multiplications that underflow to zero, where both answers are zero and only the reported scale differs. 3,000 unary cases -- Round at every digit count, Floor, Ceiling, Truncate, Compare, Abs, Negate, ToString -- are identical, with zero divergences.


---

## The finance functions

Without this module, every program that needs a payment, a present value, a rate
conversion, an internal rate of return, a depreciation or an amortization schedule writes
it, in `DOUBLE`, once per call site.

Here is what that costs. A $400,000 mortgage at 5.95% over thirty years, amortized the way
everyone amortizes it -- compute the payment, round it to cents, round each period's
interest to cents, subtract:

```freebasic
' COMPILES TODAY, AND THE LAST ROW IS WRONG
dim as float64 pmt = p * i / ( 1.0 - ( 1.0 + i ) ^ ( -n ) )
pmt = int( pmt * 100.0 + 0.5 ) / 100.0
for k as int32 = 1 to 360
    dim as float64 interest = int( bal * i * 100.0 + 0.5 ) / 100.0
    bal = bal - ( pmt - interest )
next
print bal                    ' -0.9699999996669249
```

The borrower overpaid **97 cents**, and the closing balance is not zero -- and not even a
clean -0.97 to apologise for. Three separate defects sit in those six lines and only one
is floating point: the payment is rounded once but the *residual* is never absorbed, the
interest is rounded independently of the principal so the row does not add up, and the
last period is treated like every other.

```freebasic
#import "std/money"
using money

var t     = LoanTermsCanadianMortgage( principal, rate, 25 )
var sched = LoanSchedule( t )
for each row in sched.Value( )
    print row.Period_, row.Interest_.ToStringFixed( 2 ), _
                       row.ClosingBalance_.ToStringFixed( 2 )
next                          ' the final ClosingBalance_ is EXACTLY zero
```

### Compounding and payment frequency are separate parameters

This is the decision the rest of the module follows from. A loan has **two** frequencies:
how often interest **compounds**, which is a property of how the rate is quoted, and how
often a **payment** is made, which is a property of the contract.

In the United States a mortgage compounds monthly and pays monthly, so the two collapse
and the distinction is invisible -- which is why almost every finance library elides it.
In Canada the *Interest Act* requires the rate to be quoted **semi-annually, not in
advance**, while payments are monthly, biweekly or weekly. The two differ, and a library
that assumed one number is wrong by dollars a month and thousands over the term.

So there is no `CanadianMortgagePayment` beside an American one. There is one code path,
and the two markets differ in **one enum**:

```freebasic
dim as Decimal p = DecimalParse( "400000" ).Value( )
dim as Decimal r = DecimalParse( "0.0595" ).Value( )

print LoanPayment( LoanTermsUsMortgage( p, r, 25 ) ).Value( ).ToStringFixed( 2 )        ' 2564.99
print LoanPayment( LoanTermsCanadianMortgage( p, r, 25 ) ).Value( ).ToStringFixed( 2 )  ' 2547.35
```

$17.64 a month, about $5,292 over the term.

### Exact where it matters, `float64` where it cannot be

`Decimal` has no `Pow`, `Exp`, `Log` or `Sqrt`, so anything needing a power is
either built from multiplication or is not exact. The boundary is drawn once and every
function states which side it is on, in its own doc comment:

| | |
|---|---|
| **Exact** | growth and discount over an **integer** number of periods; every sum, product and quotient of money; day-count fractions |
| **`float64`** | fractional exponents -- nominal-from-effective, the Canadian sixth root, dated discounting; continuous compounding; every solver; all of `finport.tiko` |

A rate that crosses into `float64` crosses back at a fixed scale, and **everything
downstream of it is exact again**. A Canadian mortgage crosses once, at the rate
conversion; the 300-row schedule that follows is exact `Decimal` arithmetic.

### Errors have a type

Every fallible call returns `Result( of T, FinanceError )`. `Optional` is used only where
absence *is* the answer -- `PaybackPeriod` on a project that never pays back -- and plain
values only where the function is total.

The distinction worth knowing: **`FIN_NO_SIGN_CHANGE` means no root can exist**, so
retrying with a better guess cannot help. `FIN_NO_CONVERGENCE` means the range was right
and the tolerance was not reached. Two different remedies, so two codes -- and a solver
failure carries how many iterations it ran and how close it got.

### What the schedules guarantee

The amortization rounding order is **normative**, not a matter of taste, because this is
where real implementations go wrong. The load-bearing rule is that **principal is the
residual** -- payment minus interest, never computed independently -- which makes
`Payment = Interest + Principal` an identity rather than a coincidence that fails on a few
rows out of 360. The final payment absorbs the remainder **by assignment**, so the closing
balance lands on exactly zero rather than on 0.0000000001.

Depreciation follows the same discipline: the salvage floor is absolute, and the book
value lands on exactly salvage.

### Verification

The suites are fbcunit suites, vendored in tiko-lang at `tests/vendor/fbc-tests/finance/` and
run against the module from `tests/std/finance/`: deprec, flows, loan, loanextra, portfolio,
rates, solve and tvm.

Where an oracle exists it is named: the IRS MACRS 200%-declining-balance five-year
schedule is reproduced **exactly**; ISDA's 30/360 and 30E/360 rules are applied including
the case that separates them. Where one does not, the tests assert **properties** instead
-- the time-value identity balancing, an IRR verified by substituting it back, a rate that
must compound back to the one it came from, and the five amortization invariants on every
row of every scenario.

**Not verified:** the published MACRS *percentage tables* carry display rounding that is
deliberately not reproduced -- only the arithmetic beneath them.

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Money and finance](Functions-Finance) lists them beside the rest of the area.

### Make a money value

| Function | What it does | From |
|---|---|---|
| [Currency](Modern-Finance-Currency) | Holds an exact amount with four decimal places, for money that needs no more. | `std/money` |
| [Decimal](Modern-Finance-Decimal) | Holds an exact decimal number with up to 28 places, for rates, prices and results. | `std/money` |
| [DecimalParse](Modern-Finance-DecimalParse) | Parses text into a Decimal exactly; returns empty on bad input or over 28 places. | `std/money` |
| [CurrencyParse](Modern-Finance-CurrencyParse) | Parses text into a Currency exactly; returns empty on bad input or over four places. | `std/money` |
| [CurrencyFromInt](Modern-Finance-CurrencyFromInt) | Returns a Currency of a whole number of units, exactly. | `std/money` |
| [CurrencyFromParts](Modern-Finance-CurrencyFromParts) | Returns a Currency from whole units and a ten-thousandths part, exactly. | `std/money` |
| [CurrencyFromRaw](Modern-Finance-CurrencyFromRaw) | Returns a Currency from its stored integer, which is the amount times 10000. | `std/money` |
| [CurrencyFromDouble](Modern-Finance-CurrencyFromDouble) | Converts a double to a Currency, rounded to four decimal places. | `std/money` |
| [DecimalFromInt](Modern-Finance-DecimalFromInt) | Returns a 64-bit integer as a Decimal, exactly. | `std/money` |
| [DecimalFromUInt](Modern-Finance-DecimalFromUInt) | Returns an unsigned 64-bit integer as a Decimal, exactly. | `std/money` |
| [DecimalFromScaled](Modern-Finance-DecimalFromScaled) | Returns a whole number over a power of ten as a Decimal: 1999 at scale 2 is 19.99. | `std/money` |
| [DecimalFromParts](Modern-Finance-DecimalFromParts) | Builds a Decimal from three 32-bit mantissa words, a sign flag and a scale. | `std/money` |
| [DecimalFromDouble](Modern-Finance-DecimalFromDouble) | Converts a double to a Decimal of 15 significant digits; NaN or infinity gives Invalid. | `std/money` |
| [DecimalFromCurrency](Modern-Finance-DecimalFromCurrency) | Converts a Currency to a Decimal, exactly. | `std/money` |

### Check and convert a value

| Function | What it does | From |
|---|---|---|
| [Currency.IsValid](Modern-Finance-IsValid) | Returns false if the Currency is Invalid; the only reliable test for a bad value. | `std/money` |
| [Currency.Raw](Modern-Finance-Raw) | Returns the stored integer, the amount times 10000, for saving to a file or database. | `std/money` |
| [Currency.ToDouble](Modern-Finance-ToDouble) | Returns the amount as a double, which loses precision above about 900 billion. | `std/money` |
| [DecimalCompare](Modern-Finance-DecimalCompare) | Returns -1, 0 or 1 comparing two Decimals by value, or -2 if either is Invalid. | `std/money` |

### Zero, one, limits and Invalid

| Function | What it does | From |
|---|---|---|
| [DecimalZero](Modern-Finance-DecimalZero) | Returns zero, the same value a new Decimal starts with. | `std/money` |
| [DecimalOne](Modern-Finance-DecimalOne) | Returns one as a Decimal. | `std/money` |
| [DecimalMinusOne](Modern-Finance-DecimalMinusOne) | Returns minus one as a Decimal. | `std/money` |
| [DecimalMinValue](Modern-Finance-DecimalMinValue) | Returns the most negative value a Decimal can hold. | `std/money` |
| [DecimalMaxValue](Modern-Finance-DecimalMaxValue) | Returns the largest value a Decimal can hold. | `std/money` |
| [DecimalInvalid](Modern-Finance-DecimalInvalid) | Returns the Invalid Decimal, which overflow and division by zero also produce. | `std/money` |
| [CurrencyInvalid](Modern-Finance-CurrencyInvalid) | Returns the Invalid Currency, which overflow also produces; it never equals anything. | `std/money` |

### Round and split amounts

| Function | What it does | From |
|---|---|---|
| [Currency.Ceiling](Modern-Finance-Ceiling) | Returns the amount rounded up to a whole unit, towards positive infinity. | `std/money` |
| [Currency.RoundMode](Modern-Finance-RoundMode) | Returns the amount rounded to 0 to 4 places by a rounding rule you name. | `std/money` |
| [Apportion](Modern-Finance-Apportion) | Splits a Currency total by weights into parts that add up to it exactly. | `std/money` |
| [DecimalApportion](Modern-Finance-DecimalApportion) | Splits a Decimal total by weights, at a scale you choose, into parts that add up exactly. | `std/money` |

### Total many amounts without rounding drift

| Function | What it does | From |
|---|---|---|
| [CurrencyAccum.AddProduct](Modern-Finance-AddProduct) | Adds an amount times a rate to a running total, rounding only once at the end. | `std/money` |
| [CurrencyAccum.AddScaled](Modern-Finance-AddScaled) | Adds an amount times a fraction, such as one third, to a running total exactly. | `std/money` |
| [CurrencyAccum.Total](Modern-Finance-Total) | Returns the running total as a Currency, rounded once; reading it does not reset it. | `std/money` |

### Choose a rounding policy

| Function | What it does | From |
|---|---|---|
| [MoneyRounding](Modern-Finance-MoneyRounding) | Holds a rounding policy: decimal places, rounding mode, and whether to round each amount. | `std/money` |
| [MoneyRoundingMake](Modern-Finance-MoneyRoundingMake) | Returns a rounding policy with the places, mode and round-each flag you choose. | `std/money` |
| [MoneyRoundingCents](Modern-Finance-MoneyRoundingCents) | Returns the default policy: two places, half-to-even, every posted amount rounded. | `std/money` |
| [MoneyRoundingBankersFour](Modern-Finance-MoneyRoundingBankersFour) | Returns a policy of four places, half-to-even, to match a Currency ledger. | `std/money` |
| [MoneyRoundingExact](Modern-Finance-MoneyRoundingExact) | Returns a policy that never rounds, to keep full precision or see what rounding costs. | `std/money` |
| [MoneyRound](Modern-Finance-MoneyRound) | Rounds a Decimal by a policy, or returns it unchanged if the policy does not round. | `std/money` |

### Handle a finance error

| Function | What it does | From |
|---|---|---|
| [FinanceError](Modern-Finance-FinanceError) | Holds why a finance call failed: a code, a message and, for solvers, how close it got. | `std/money` |
| [FinanceErrorCode](Modern-Finance-FinanceErrorCode) | Lists the failure codes, such as FIN_INVALID_RATE and FIN_NO_SIGN_CHANGE. | `std/money` |
| [FinanceErrorMessage](Modern-Finance-FinanceErrorMessage) | Returns a short, fixed English description of a failure code. | `std/money` |

### Convert interest rates

| Function | What it does | From |
|---|---|---|
| [Compounding](Modern-Finance-Compounding) | Lists how often interest compounds, as periods per year, plus simple and continuous. | `std/money` |
| [RatePerPeriod](Modern-Finance-RatePerPeriod) | Returns a quoted annual rate divided by its compounding periods, exactly. | `std/money` |
| [RateEffectiveFromNominal](Modern-Finance-RateEffectiveFromNominal) | Returns what a quoted annual rate really earns in a year once it compounds. | `std/money` |
| [RateNominalFromEffective](Modern-Finance-RateNominalFromEffective) | Returns the quoted annual rate that earns a given effective yearly return. | `std/money` |
| [RateConvertCompounding](Modern-Finance-RateConvertCompounding) | Restates a quoted annual rate for a different compounding frequency. | `std/money` |
| [RateContinuousFromEffective](Modern-Finance-RateContinuousFromEffective) | Returns the continuously compounded rate that gives an effective yearly return. | `std/money` |
| [RateEffectiveFromContinuous](Modern-Finance-RateEffectiveFromContinuous) | Returns the effective yearly return of a continuously compounded rate. | `std/money` |
| [RatePerPaymentFromNominal](Modern-Finance-RatePerPaymentFromNominal) | Returns the rate per payment when compounding and payment frequency differ. | `std/money` |

### Simple interest and day counts

| Function | What it does | From |
|---|---|---|
| [SimpleInterest](Modern-Finance-SimpleInterest) | Returns principal times rate times a fraction of a year, exactly. | `std/money` |
| [SimpleInterestBetween](Modern-Finance-SimpleInterestBetween) | Returns simple interest between two dates on a day-count basis you choose. | `std/money` |
| [DayCount](Modern-Finance-DayCount) | Lists the six day-count bases, such as actual/365 fixed and 30/360 US. | `std/money` |
| [DayCountDays](Modern-Finance-DayCountDays) | Counts the days between two dates on a day-count basis. | `std/money` |
| [DayCountFraction](Modern-Finance-DayCountFraction) | Returns the fraction of a year between two dates on a basis, as an exact Decimal. | `std/money` |
| [DayCountFractionDouble](Modern-Finance-DayCountFractionDouble) | Returns the fraction of a year between two dates on a basis, as a double. | `std/money` |

### Grow and discount over periods

| Function | What it does | From |
|---|---|---|
| [GrowthFactor](Modern-Finance-GrowthFactor) | Returns what one unit grows to over a whole number of periods at a rate, exactly. | `std/money` |
| [DiscountFactor](Modern-Finance-DiscountFactor) | Returns what one unit due after a whole number of periods is worth today. | `std/money` |
| [GrowthFactorFractional](Modern-Finance-GrowthFactorFractional) | Returns what one unit grows to over a fractional number of periods. | `std/money` |
| [GrowthFactorContinuous](Modern-Finance-GrowthFactorContinuous) | Returns what one unit grows to over a number of years with continuous compounding. | `std/money` |

### Present value, future value and payments

| Function | What it does | From |
|---|---|---|
| [AnnuityTerms](Modern-Finance-AnnuityTerms) | Holds rate, periods, payment, present value, future value and timing for annuity sums. | `std/money` |
| [AnnuityTermsMake](Modern-Finance-AnnuityTermsMake) | Returns annuity terms from the six values; the one being solved for is ignored. | `std/money` |
| [PaymentTiming](Modern-Finance-PaymentTiming) | Lists whether payments fall at the end or at the start of each period. | `std/money` |
| [PresentValue](Modern-Finance-PresentValue) | Returns what a stream of payments plus a final amount is worth today. | `std/money` |
| [FutureValue](Modern-Finance-FutureValue) | Returns what a stream of payments will be worth at the end of the term. | `std/money` |
| [PaymentAmount](Modern-Finance-PaymentAmount) | Returns the level payment per period, negative when the present value is positive. | `std/money` |
| [PresentValueOfLump](Modern-Finance-PresentValueOfLump) | Returns a single future amount discounted back a number of periods. | `std/money` |
| [FutureValueOfLump](Modern-Finance-FutureValueOfLump) | Returns a single amount compounded forward a number of periods. | `std/money` |
| [PeriodsRequired](Modern-Finance-PeriodsRequired) | Returns how many periods a payment takes to clear a balance, as a fractional double. | `std/money` |
| [PeriodsRequiredWhole](Modern-Finance-PeriodsRequiredWhole) | Returns how many payments clear a balance, rounded up to a whole number. | `std/money` |
| [SolveRatePerPeriod](Modern-Finance-SolveRatePerPeriod) | Returns the rate per period implied by a known payment, value and term. | `std/money` |
| [AnnuityPresentValueFactor](Modern-Finance-AnnuityPresentValueFactor) | Returns what one unit paid each period is worth today. | `std/money` |
| [AnnuityFutureValueFactor](Modern-Finance-AnnuityFutureValueFactor) | Returns what one unit paid each period grows to by the end of the term. | `std/money` |

### Set up a loan and its payment

| Function | What it does | From |
|---|---|---|
| [LoanTerms](Modern-Finance-LoanTerms) | Holds a loan's principal, rate, term, frequencies, rounding and first payment date. | `std/money` |
| [LoanTermsMake](Modern-Finance-LoanTermsMake) | Returns loan terms with the payment frequency and compounding you choose. | `std/money` |
| [LoanTermsUsMortgage](Modern-Finance-LoanTermsUsMortgage) | Returns loan terms for a US mortgage: monthly compounding and monthly payments. | `std/money` |
| [LoanTermsCanadianMortgage](Modern-Finance-LoanTermsCanadianMortgage) | Returns loan terms for a Canadian mortgage: semi-annual compounding, monthly payments. | `std/money` |
| [PaymentFrequency](Modern-Finance-PaymentFrequency) | Lists how often payments are made, including weekly and accelerated biweekly. | `std/money` |
| [LoanPayment](Modern-Finance-LoanPayment) | Returns a loan's level payment, rounded once; the last payment absorbs the remainder. | `std/money` |
| [LoanImpliedRate](Modern-Finance-LoanImpliedRate) | Returns the annual rate implied by a known principal, payment and term. | `std/money` |
| [LoanAnnualPercentageRate](Modern-Finance-LoanAnnualPercentageRate) | Returns the annual rate once financed fees are counted as a cost of borrowing. | `std/money` |

### Walk an amortization schedule

| Function | What it does | From |
|---|---|---|
| [LoanSchedule](Modern-Finance-LoanSchedule) | Returns a loan's amortization schedule, built lazily, to walk with for each. | `std/money` |
| [AmortizationSchedule](Modern-Finance-AmortizationSchedule) | Holds a loan schedule's terms and gives its scheduled payment count and payment. | `std/money` |
| [AmortizationIterator](Modern-Finance-AmortizationIterator) | Walks a loan schedule row by row, for stopping early or reading a window. | `std/money` |
| [AmortizationRow](Modern-Finance-AmortizationRow) | Holds one period: due date, balances, payment, interest, principal and running totals. | `std/money` |
| [ScheduleToArray](Modern-Finance-ScheduleToArray) | Returns every row of a loan schedule as an Array, for random access. | `std/money` |
| [LoanRowAt](Modern-Finance-LoanRowAt) | Returns one row of a loan schedule, rounded exactly as it would be posted. | `std/money` |
| [LoanBalanceAt](Modern-Finance-LoanBalanceAt) | Returns the balance after a period from a formula, without walking the schedule. | `std/money` |

### Loan totals, payoff and extra payments

| Function | What it does | From |
|---|---|---|
| [LoanInterestBetween](Modern-Finance-LoanInterestBetween) | Returns the interest posted across a range of periods, such as one tax year. | `std/money` |
| [LoanPrincipalBetween](Modern-Finance-LoanPrincipalBetween) | Returns the principal repaid across a range of periods, extra payments included. | `std/money` |
| [LoanPayoffAmount](Modern-Finance-LoanPayoffAmount) | Returns what settles a loan on a date: the balance plus interest accrued since. | `std/money` |
| [LoanSummarize](Modern-Finance-LoanSummarize) | Returns a loan's totals, payment count and payoff date, and what extra payments save. | `std/money` |
| [LoanSummary](Modern-Finance-LoanSummary) | Holds what LoanSummarize returns: payments, totals, effective rate and savings. | `std/money` |
| [ExtraPayment](Modern-Finance-ExtraPayment) | Holds extra principal paid over a range of periods; overlapping ranges add up. | `std/money` |
| [ExtraPaymentOnce](Modern-Finance-ExtraPaymentOnce) | Returns a single extra principal payment made in one period. | `std/money` |
| [ExtraPaymentRecurring](Modern-Finance-ExtraPaymentRecurring) | Returns the same extra principal payment in every period of a range. | `std/money` |

### Appraise cash flows: NPV, IRR and payback

| Function | What it does | From |
|---|---|---|
| [CashFlow](Modern-Finance-CashFlow) | Holds an amount and the date it happens, for the dated value and return functions. | `std/money` |
| [CashFlowMake](Modern-Finance-CashFlowMake) | Returns a cash flow on a date; the dates in a series must ascend. | `std/money` |
| [CashFlowAt](Modern-Finance-CashFlowAt) | Returns a cash flow with no date, placed by its period number. | `std/money` |
| [NetPresentValue](Modern-Finance-NetPresentValue) | Returns the net present value of flows at a rate; the first flow is not discounted. | `std/money` |
| [NetFutureValue](Modern-Finance-NetFutureValue) | Returns the net present value carried forward to the end of the series. | `std/money` |
| [NetPresentValueOnDates](Modern-Finance-NetPresentValueOnDates) | Returns the net present value of dated flows at an annual rate on a day-count basis. | `std/money` |
| [InternalRateOfReturn](Modern-Finance-InternalRateOfReturn) | Returns the rate at which the net present value of a series of flows is zero. | `std/money` |
| [InternalRateOfReturnOnDates](Modern-Finance-InternalRateOfReturnOnDates) | Returns the internal rate of return of flows on irregular dates. | `std/money` |
| [ModifiedInternalRateOfReturn](Modern-Finance-ModifiedInternalRateOfReturn) | Returns a rate of return with one answer, from separate finance and reinvestment rates. | `std/money` |
| [PaybackPeriod](Modern-Finance-PaybackPeriod) | Returns when the running total of flows turns positive, or empty if it never does. | `std/money` |
| [DiscountedPaybackPeriod](Modern-Finance-DiscountedPaybackPeriod) | Returns when the running total of discounted flows turns positive, or empty if never. | `std/money` |
| [ProfitabilityIndex](Modern-Finance-ProfitabilityIndex) | Returns the present value of the later flows divided by the initial outlay. | `std/money` |

### Depreciate an asset

| Function | What it does | From |
|---|---|---|
| [DepreciationTerms](Modern-Finance-DepreciationTerms) | Holds an asset's cost, salvage value, life in periods and declining-balance factor. | `std/money` |
| [DepreciationTermsMake](Modern-Finance-DepreciationTermsMake) | Returns depreciation terms from cost, salvage and life, with a factor of 2 and cents. | `std/money` |
| [DepreciationMethod](Modern-Finance-DepreciationMethod) | Lists the six methods, from straight line to units of production. | `std/money` |
| [DepreciationStraightLine](Modern-Finance-DepreciationStraightLine) | Returns one period's expense, with cost less salvage spread evenly over the life. | `std/money` |
| [DepreciationDecliningBalance](Modern-Finance-DepreciationDecliningBalance) | Returns one period's expense as a fixed fraction of the remaining book value. | `std/money` |
| [DepreciationDoubleDeclining](Modern-Finance-DepreciationDoubleDeclining) | Returns one period's expense at twice the straight-line rate, never below salvage. | `std/money` |
| [DepreciationSumOfYearsDigits](Modern-Finance-DepreciationSumOfYearsDigits) | Returns one period's expense, weighted by how many periods of the life are left. | `std/money` |
| [DepreciationUnitsOfProduction](Modern-Finance-DepreciationUnitsOfProduction) | Returns one period's expense from the units it produced out of the lifetime total. | `std/money` |
| [DepreciationScheduleOf](Modern-Finance-DepreciationScheduleOf) | Returns the full schedule for a method, including declining balance with a switch. | `std/money` |
| [DepreciationSchedule](Modern-Finance-DepreciationSchedule) | Holds every period of a write-off, to walk with for each. | `std/money` |
| [DepreciationScheduleIterator](Modern-Finance-DepreciationScheduleIterator) | Walks a depreciation schedule row by row, for stopping early. | `std/money` |
| [DepreciationRow](Modern-Finance-DepreciationRow) | Holds one period: opening and closing book value, expense and depreciation so far. | `std/money` |
| [DepreciationScheduleToArray](Modern-Finance-DepreciationScheduleToArray) | Returns every row of a depreciation schedule as an Array. | `std/money` |

### Measure investment returns

| Function | What it does | From |
|---|---|---|
| [ReturnFrequency](Modern-Finance-ReturnFrequency) | Lists how many observations make a year: annual, quarterly, monthly, weekly or daily. | `std/money` |
| [HoldingPeriodReturn](Modern-Finance-HoldingPeriodReturn) | Returns the gain plus income over a holding period, as a fraction of the start value. | `std/money` |
| [CompoundAnnualGrowthRate](Modern-Finance-CompoundAnnualGrowthRate) | Returns the steady yearly rate that grows a starting value to an ending value. | `std/money` |
| [AnnualizeReturn](Modern-Finance-AnnualizeReturn) | Converts a return per period to a yearly return by compounding, not multiplying. | `std/money` |
| [AnnualizeReturnOverPeriods](Modern-Finance-AnnualizeReturnOverPeriods) | Converts a total return over a number of observations to a yearly return. | `std/money` |
| [TimeWeightedReturn](Modern-Finance-TimeWeightedReturn) | Returns sub-period returns linked by compounding, ignoring when money moved in or out. | `std/money` |
| [ModifiedDietzReturn](Modern-Finance-ModifiedDietzReturn) | Returns an approximate time-weighted return, weighting each flow by days invested. | `std/money` |
| [MoneyWeightedReturn](Modern-Finance-MoneyWeightedReturn) | Returns the dated internal rate of return of contributions and the closing value. | `std/money` |
| [CumulativeReturnSeries](Modern-Finance-CumulativeReturnSeries) | Returns the compounded return after each observation, as a growth chart plots. | `std/money` |

### Measure risk and drawdowns

| Function | What it does | From |
|---|---|---|
| [Volatility](Modern-Finance-Volatility) | Returns the sample standard deviation of returns, annualized. | `std/money` |
| [DownsideDeviation](Modern-Finance-DownsideDeviation) | Returns the annualized shortfall of returns below a target, ignoring gains. | `std/money` |
| [MaxDrawdown](Modern-Finance-MaxDrawdown) | Returns the worst fall from a peak to a later low, as a positive fraction. | `std/money` |
| [MaxDrawdownPeak](Modern-Finance-MaxDrawdownPeak) | Returns the index of the peak the worst drawdown fell from, or empty if none. | `std/money` |
| [MaxDrawdownTrough](Modern-Finance-MaxDrawdownTrough) | Returns the index of the low point of the worst drawdown, or empty if none. | `std/money` |
| [DrawdownSeries](Modern-Finance-DrawdownSeries) | Returns the fall from the running peak at each observation, zero or negative. | `std/money` |
| [SharpeRatio](Modern-Finance-SharpeRatio) | Returns the annualized return above the risk-free rate per unit of volatility. | `std/money` |
| [SortinoRatio](Modern-Finance-SortinoRatio) | Returns the annualized return above a target per unit of downside deviation. | `std/money` |
| [SummarizeReturns](Modern-Finance-SummarizeReturns) | Returns total and yearly return, volatility, Sharpe, Sortino and drawdown in one call. | `std/money` |
| [ReturnSummary](Modern-Finance-ReturnSummary) | Holds the figures SummarizeReturns computes, one field each. | `std/money` |

### Compare a portfolio with its benchmark

| Function | What it does | From |
|---|---|---|
| [Beta](Modern-Finance-Beta) | Returns how much an asset moves when its benchmark moves by one. | `std/money` |
| [Alpha](Modern-Finance-Alpha) | Returns the annualized return beyond what the asset's beta to its benchmark explains. | `std/money` |
| [TrackingError](Modern-Finance-TrackingError) | Returns the annualized standard deviation of the asset's return less the benchmark's. | `std/money` |
| [InformationRatio](Modern-Finance-InformationRatio) | Returns the return above the benchmark per unit of tracking error. | `std/money` |
| [CorrelationToBenchmark](Modern-Finance-CorrelationToBenchmark) | Returns how closely an asset moves with its benchmark, from -1 to 1. | `std/money` |

### Find a root of your own function

| Function | What it does | From |
|---|---|---|
| [FinSolveRoot](Modern-Finance-FinSolveRoot) | Finds where your function is zero between two bounds, and reports how close it got. | `std/money` |
| [FinObjective](Modern-Finance-FinObjective) | Holds a pointer to the function the root finder calls with a value and a context. | `std/money` |
| [FinSolverOptions](Modern-Finance-FinSolverOptions) | Holds the root finder's bounds, starting guess, tolerances and iteration limits. | `std/money` |
| [FinSolverOptionsDefault](Modern-Finance-FinSolverOptionsDefault) | Returns the standard solver settings: rate bounds, 128 iterations and no guess. | `std/money` |
| [FinSolverOptionsWithGuess](Modern-Finance-FinSolverOptionsWithGuess) | Returns the standard solver settings with a starting guess. | `std/money` |
| [FinSolveResult](Modern-Finance-FinSolveResult) | Holds the root found, its residual, the iteration count and whether it converged. | `std/money` |

<!-- finder:end -->