[Home](Home) › [String Library](Category-String-Library) › [String Library](Category-String-Library) › **MoneyLocaleName**

# MoneyLocaleName

Returns the name of the locale that money is formatted for.

## Syntax

```freebasic
MoneyLocaleName( ) as ustring
```

## Notes

- Windows reports an NLS name such as `en-CA`. Linux and macOS report whatever `setlocale` returned for `LC_MONETARY`.
- Empty, or a C-locale name, when the system rejected the locale. Check [MoneyLocaleIsValid](Modern-String-MoneyLocaleIsValid) rather than reading anything into the name.
- Reads the snapshot, loading it on first use.

## Examples

```freebasic
print "money formatted as "; MoneyLocaleName( )
```

---

**Library:** [String Library](Category-String-Library)  
**Category:** [String Library](Category-String-Library)  
**Documented under:** Money Formatting
