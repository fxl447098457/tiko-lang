[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkLanguage**

# tkLanguage

Shows a designed program's captions in another language, from TOML catalogs.

A form marked Translatable in the [Form Designer](Form-Designer) asks [tkForms](tkForms) for each caption it sets: `tkForms_Tr( "frmMain.btnOK.Text", "OK" )`. `tkLanguage` answers those questions. You register one catalog per language, by its code, and `tkLanguage_Use` makes one of them the program's: it reads the catalog and installs it as tkForms' translator. A key the catalog lacks shows the text the form was designed with, so a catalog can be partial.

A catalog is either **built in**, its bytes inside the executable with `#embed`, so the program needs nothing beside it, or **loose**, a file read when the language is used. Registering a code a second time replaces the first registration, so a loose file registered after the built-in data overrides it: a user can correct a translation without a rebuild.

The forms' own language, the one they were designed in, is the **base language**. It has no catalog: `tkLanguage_SetBase` names it, and using it shows the designed text.

## With the Form Designer

A project with languages needs none of the calls below written by hand. The designer writes the catalogs (`appLanguages/lang/<code>.toml`) and a generated module, `appLanguages.design.tiko`, whose `Register` calls `tkLanguage_SetBase` and then, for each language, `tkLanguage_AddData` for a catalog built in and `tkLanguage_AddFile` for one beside the program (after the data, so the file overrides it). The module wraps the choice for your code:

```freebasic
appLanguages.UseSystem( )      ' tkLanguage_UseSystem: the user's language, else the base
appLanguages.Use( "fr" )       ' tkLanguage_Use: a language from your own settings
```

The generated `main` calls `appLanguages.UseSystem( )` before the first form is shown. Everything else on this page is for programs that call tkLanguage themselves, and for reading what the generated code does.

**Captions are read when a form is built.** `tkLanguage_Use` changes what `tkForms_Tr` answers from then on; a form that is already open keeps the captions it was built with until it is built again. Choose the language before the first form is shown.

## Importing

```freebasic
#import "vendor/tkControls/tkLanguage"

using tkLanguage
```

The module imports [tkForms](tkForms) for its translator, and `std/config`, `std/fs`, `std/codec` and `std/containers` to read catalogs. It keeps that out of tkForms: a program that does not translate never links the TOML reader.

## Example

```freebasic
#import "vendor/tkControls/tkLanguage"
#import "vendor/tkControls/tkForms"
using tkLanguage
using tkForms

#embed gLangFr "lang/fr.toml"          ' inside the executable
tkLanguage_SetBase( "en", "English" )  ' the forms' own text
tkLanguage_AddData( "fr", "Français", @gLangFr(0), ubound( gLangFr ) + 1 )
tkLanguage_AddFile( "de", "Deutsch", exepath( ) & "/lang/de.toml" )   ' read when used

tkLanguage_UseSystem( )                ' the user's language: fr, de or the base
print tkForms_Tr( "frmMain.btnOK.Text", "OK" )

if tkLanguage_Use( "de" ) = false then print tkLanguage_Warnings( )
tkLanguage_Use( "en" )                 ' back to the designed text; so does ""
```

## Catalogs

A catalog is a TOML file in UTF-8, in the format tkEdit's own translations use:

```toml
format = 1
name = "Français"

[frmMain]
Caption = "Fenêtre principale"
"btnOK.Text" = "Valider"
"btnOK.ToolTip" = "Ferme la fenêtre"
"mnuMain.0" = "Fichier"
"mnuMain.3" = "Ouvrir"

[_source.frmMain]
"btnOK.Text" = "OK"
```

- **Keys are flattened** to the dotted name `tkForms_Tr` asks for: the table's name, a dot, and the key as written. A quoted key's dots are part of the key, so `[frmMain]` `"btnOK.Text"` is `frmMain.btnOK.Text`. The key is `<Form>.<control>.<Property>`, with a numeric last part for items in a list (`frmMain.mnuMain.3`). The designer writes one table a form, as above.
- **Nested tables flatten the same way**, so a catalog written by hand can say `[frmMain.btnOK]` `Text = "Valider"` for the same key.
- **`format`** is 1. Another number is read anyway, with a warning.
- **`name`** is for people reading the file. The name `tkLanguage_Name` gives is the one the catalog was registered with.
- **A top-level table whose name starts with `_`** is not text and is skipped, with everything under it. The designer keeps the base text each translation was made from in `[_source.<Form>]`, to tell which translations are out of date.
- **The reader is lenient.** Only text that is not TOML fails. A value that is not a string, or a top-level value that is not a table, is skipped and noted in `tkLanguage_Warnings`.

## Language codes

A code is whatever the program registers: `"fr"`, `"pt_BR"`, `"zh_Hant"`. Codes are compared without regard to case, and `-` matches `_`, so `"pt-BR"`, `"PT_br"` and `"pt_BR"` are one code. `tkLanguage_Current` and `tkLanguage_Code` give the code as it was registered.

`tkLanguage_UseSystem` asks SDL for the user's preferred locales (`SDL_GetPreferredLocales`), most preferred first, and tries each as `ll_CC`, then as `ll`: a user whose first locale is `fr_CA` gets `fr_CA` if it is registered, else `fr`, before their second locale is tried. It stops at the first that is the base language or a registered language whose catalog can be read. So with base `en`, a user who prefers `en_US`, then `fr`, gets the designed English text, not French. When nothing matches, the forms show their designed text and it returns false. A general code does not reach a specific one: `pt` does not use `pt_BR`.

The base code wins over a registered catalog with the same code: `tkLanguage_Use` of the base code always shows the designed text.

`tkLanguage_UseLocales` does the same with a list you give it, `"fr_CA,de"`: a language the user chose in your settings, a command-line switch, or a test. POSIX suffixes are dropped, so `"de_DE.UTF-8"` and `"de_DE@euro"` are `de_DE`.

## Procedures

- `tkLanguage_AddData( code, langName, p, n )` registers a built-in catalog: `n` bytes of UTF-8 at `p`. The bytes are borrowed, not copied, and must stay for as long as the language can be used; an `#embed` array always does. A UTF-8 byte order mark is allowed. An empty code is ignored.
- `tkLanguage_AddFile( code, langName, path )` registers a catalog file. It is read each time the language is used, not now, so it need not exist yet.
- `tkLanguage_SetBase( code, langName )` names the base language, the one the forms were designed in. It has no catalog and is not counted by `tkLanguage_Count`. `tkLanguage_BaseCode( )` and `tkLanguage_BaseName( )` give it back; `""` until it is set.
- `tkLanguage_Count( )` is the number of registered languages. `tkLanguage_Code( i )` and `tkLanguage_Name( i )`, for `i` from 0 to `Count - 1`, give each one's code and name, in the order they were first registered; out of range they return `""`.
- `tkLanguage_Use( code )` makes `code`'s catalog the program's and returns true. It returns false, and leaves the language in use as it was, when `code` is not registered, its file cannot be read, or its text is not TOML; `tkLanguage_Warnings` says why. `tkLanguage_Use( "" )`, or of the base code, removes the translator: the designed text again. Registering a code again does not reload it; `tkLanguage_Use` does.
- `tkLanguage_UseLocales( list )` uses the first entry of a comma-separated locale list that is the base or a registered language, as described above. False, with the designed text, when none matches.
- `tkLanguage_UseSystem( )` is `tkLanguage_UseLocales( tkLanguage_SystemLocales( ) )`.
- `tkLanguage_SystemLocales( )` is the user's preferred locales as a list: `"en_US"`, `"fr_CA,de"`. `""` when the system gives none.
- `tkLanguage_Current( )` is the code in use, as registered. While the designed text shows it is the base code, or `""` when no base is set.
- `tkLanguage_Warnings( )` is what the last `tkLanguage_Use` skipped, or why it failed, one line each; `""` when there was nothing to say. After `tkLanguage_UseLocales`, it holds why each matching catalog passed over failed.

`tkLanguage_Use` installs its translator with `tkForms_SetTranslator`. A program that installs its own translator afterwards replaces it, and `tkLanguage_Current` no longer says what `tkForms_Tr` answers with.

## Public declarations

Every public name the module declares, as the source declares it.

### Constants

```freebasic
const as long TKLANGUAGE_FORMAT = 1
```

### Procedures

```freebasic
sub tkLanguage_AddData( byref code as const ustring, byref langName as const ustring, byval p as const ubyte ptr, byval n as longint )
sub tkLanguage_AddFile( byref code as const ustring, byref langName as const ustring, byref path as const ustring )
sub tkLanguage_SetBase( byref code as const ustring, byref langName as const ustring )
function tkLanguage_BaseCode( ) as ustring
function tkLanguage_BaseName( ) as ustring
function tkLanguage_Count( ) as long
function tkLanguage_Code( byval i as long ) as ustring
function tkLanguage_Name( byval i as long ) as ustring
function tkLanguage_Current( ) as ustring
function tkLanguage_Warnings( ) as ustring
function tkLanguage_Use( byref code as const ustring ) as boolean
function tkLanguage_UseLocales( byref locales as const ustring ) as boolean
function tkLanguage_SystemLocales( ) as ustring
function tkLanguage_UseSystem( ) as boolean
```

### See also

- [tkControls](Category-tkControls)
- [tkForms](tkForms), [Form Designer](Form-Designer)
- [Category-Embed](Category-Embed)
