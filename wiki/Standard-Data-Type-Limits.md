[Home](Home) › **Standard Data Type Limits**

# Standard Data Type Limits

Standard variable types and limits.

 ***Numeric Types***

| Type | Size in bits | Format | Minimum Value | Maximum Value | Literal Suffix | Sig. Digits |
| --- | --- | --- | --- | --- | --- | --- |
| BYTE | 8 | signed integer | -128 | +127 | | 2+ |
| UBYTE | 8 | unsigned integer | 0 | +255 | | 2+ |
| SHORT | 16 | signed integer | -32768 | +32767 | | 4+ |
| USHORT | 16 | unsigned integer | 0 | 65535 | | 4+ |
| LONG | 32 | signed integer | -2147483648 | +2147483647 | &, l | 9+ |
| ULONG | 32 | unsigned integer | 0 | +4294967295 | ul | 9+ |
| INTEGER | 32/64 \[\*\] | signed integer | \[\*\]32bit: -2147483648, 64bit: -9223372036854775808 | \[\*\]32bit: +2147483647, 64bit: +9223372036854775807 | % | \[\*\] |
| UINTEGER | 32/64 \[\*\] | unsigned integer | 0 | \[\*\]32bit: +4294967295, 64bit: +18446744073709551615 | u | \[\*\] |
| LONGINT | 64 | signed integer | -9223372036854775808 | +9223372036854775807 | ll | 18+ |
| ULONGINT | 64 | unsigned integer | 0 | +18446744073709551615 | ull | 19+ |
| INT128 \[\*\*\*\] | 128 | signed integer | -170141183460469231731687303715884105728 | +170141183460469231731687303715884105727 | | 38+ |
| UINT128 \[\*\*\*\] | 128 | unsigned integer | 0 | +340282366920938463463374607431768211455 | | 38+ |
| SINGLE | 32 | floating point | \[\*\*\]+/-1.401 298 E-45 | \[\*\*\]+/-3.402 823 E+38 | !, f | 6+ |
| DOUBLE | 64 | floating point | \[\*\*\]+/-4.940 656 458 412 465 E-324 | \[\*\*\]+/-1.797 693 134 862 316 E+308 | #, d | 15+ |
| enums | 32/64 \[\*\] | signed integer | \[\*\]32bit: -2147483648, 64bit: -9223372036854775808 | \[\*\]32bit: +2147483647, 64bit: +9223372036854775807 | | \[\*\] |

\[\*\] *[`Integer`](Integer) and [`UInteger`](Uinteger) data types vary with platform, matching the size of pointers.*  
 \[\*\*\] *The minimum and maximum values for the floating-point types [`Single`](Single) and [`Double`](Double) are, respectively, the values closest to zero and the values closest to positive and negative infinity.*  
 \[\*\*\*\] ***tiko:** [`Int128` and `UInt128`](Category-Fixed-Width-Types#128-bit-integers) have no literal suffix: a literal too big for 64 bits is 128-bit by itself.*

***String Types***

| Type | Character Size (in bytes) | Minimum Size (in characters) | Maximum Size (in characters), including terminating padding | Literal Suffix |
| --- | --- | --- | --- | --- |
| String | 1 | 0 | \[\*\*\]32bit: +2147483647, 64bit: +9223372036854775807 | $ |
| String\*N | 1 | 1 | \[\*\*\]+2147483647 | $ |
| Zstring\*N | 1 | 1 | \[\*\*\]+2147483647 | \[N/A\] |
| Wstring\*N | \[\*\] | \[\*\]1 | \[\*,\*\*\]+2147483647 | \[N/A\] |

\[\*\] *Unicode, or "wide", characters vary in both size and availability with platform.*  
 \[\*\*\] *All runtime library string procedures take and produce [`Integer`](Integer) values for sizes and positions. The actual maximum size will vary (smaller) with storage location and/or platform.*

***Boolean Type***

| Type | Internal size in bits | Value |
| --- | --- | --- |
| Boolean | 1-bit wide data (in a Byte) | 'False' or 'True' |

***Arrays***

| Platform | Maximum Subscript Range | Maximum Elements per Dimension | Minimum/Maximum Dimensions | Maximum Size (in bytes) |
| --- | --- | --- | --- | --- |
| 32bit | \[\*\]\[-2147483648, +2147483647\] | \[\*\]+2147483647 | 1/8 | \[\*\]+2147483647 |
| 64bit | \[\*\]\[-9223372036854775808, +9223372036854775807\] | \[\*\]+9223372036854775807 | 1/8 | \[\*\]+9223372036854775807 |

\[\*\] *All runtime library array procedures take and produce [`Integer`](Integer) values for subscripts and indexes. The actual limits will vary (smaller) with the number of dimensions, element size, storage location and/or platform.*

***UDTs***

| Platform | Maximum Size (in bytes) |
| --- | --- |
| 32bit | \[\*\]+2147483647 |
| 64bit | \[\*\]+2147483647 |

\[\*\] *The actual maximum size will vary (smaller) with storage location and/or platform.*

See also

 [Usage of suffixes for literals / numbers](Literals)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
