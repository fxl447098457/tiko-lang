[Home](Home) › [All Categories](Categories) › [tkControls](Category-tkControls) › **tkTimer**

# tkTimer

Calls a procedure every so many milliseconds.

`tkTimer` is the [tkControls](Category-tkControls) timer: a component, not a control. It is a hidden, zero-size child widget that is never shown, never a tab stop and never hit, so it has a handle, an id and a parent like any control and goes when its parent goes. While it is enabled and has an interval it calls its Tick callback every `Interval` milliseconds, on the UI thread.

The interval starts at 0, which means stopped: set one with `tkTimer_SetInterval`. A timer is enabled and disabled as any widget is, with `tkWidget_Enable` (a designed form's `.Enabled`). Setting the interval again starts the wait again. Setters are silent.

## Importing

```freebasic
#import "vendor/tkControls/tkTimer"

using tkTimer
using tkHost
```

The module brings in [tkHost](tkHost).

## Example

`host` is a `TK_HOST ptr` from `tkHost_Create`, set up as in the [tkButton](tkButton) example, and `clock` a label showing the time.

```freebasic
sub Clock_Tick( byval hTimer as TK_WIDGET ptr )
    tkLabel_SetText( clock, time )
end sub

dim as TK_WIDGET ptr ticker = tkTimer_Create( tkHost_Root( host ), 2200 )
tkTimer_SetTickCallback( ticker, @Clock_Tick )
tkTimer_SetInterval( ticker, 1000 )          ' once a second

tkWidget_Enable( ticker, false )             ' paused
tkWidget_Enable( ticker, true )              ' and going again
```

## Typed wrapper

The module also provides `Timer`, a typed value for designed forms (see [tkForms](tkForms) and the [Form Designer](Form-Designer)). `Timer.Handle` is the `TK_WIDGET ptr`. It has `Create( hParent, id )` and these properties, each read and write:

`Enabled`, `Interval`.

A component has no `Visible` and no `SetFocus`.

## Behaviour notes

- It runs while it is enabled **and** its interval is above 0; `tkTimer_IsRunning` says whether it is.
- An interval of 0 or less stops it, and `tkTimer_GetInterval` then answers 0.
- A tick already on its way when the timer stops or is destroyed is dropped, not delivered.
- `tkWidget_Show( timer, true )` leaves it hidden.
- Disabling the timer's parent does not stop it: only the timer's own enabled state counts.

## Public declarations

Every public name the module declares, as the source declares it. Signatures are exact; type bodies keep their field comments and drop the rest.

### Types

```freebasic
type TMR_TickCallbackSub as sub( byval hTimer as TK_WIDGET ptr )

type TKTIMER_STATE   ' per-instance state; reach it through the procedures
```

### Procedures

```freebasic
function tkTimer_Create( byval hParent as TK_WIDGET ptr, byval ctrlId as long ) as TK_WIDGET ptr
function tkTimer_GetInterval( byval h as TK_WIDGET ptr ) as long
sub tkTimer_SetInterval( byval h as TK_WIDGET ptr, byval ms as long )
function tkTimer_IsRunning( byval h as TK_WIDGET ptr ) as boolean
sub tkTimer_SetTickCallback( byval h as TK_WIDGET ptr, byval usersub as TMR_TickCallbackSub )
```

### See also

- [tkControls](Category-tkControls)
- [tkApp](tkApp), [tkHost](tkHost)
- [Form Designer](Form-Designer)
