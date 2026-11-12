[Home](Home) › [Terminal TUI Library](Category-Terminal-TUI-Library) › [Examples](Category-Terminal-TUI-Library) › **form.tiko**

# form.tiko

> **Focus traversal and a confirm dialog.** A complete, working program from [Terminal TUI Library](Category-Terminal-TUI-Library).

Text inputs, a checkbox, a radio group and a select, wired into a TuiFocusRing with Tab and Shift+Tab, and a TuiMessageBox on submit.

## Build and run

```freebasic
tiko form.tiko        ' windows-x86_64 on Windows, linux-x86_64 on Linux, macos-arm64 on macOS
```

Run it from a REAL TERMINAL. Redirected output is rejected with an honest error rather than a dashboard drawn into a pipe. tiko builds it with no diagnostics for windows-x86_64 and win64, and compiles it for linux-x86_64 with `-c` (built, not run: it is interactive).

## What to notice

- EVERY FOCUSABLE WIDGET IS A FIELD OF THE APP, not a local in View. The focus ring holds `TuiWidget ptr` and a local dies at END SUB.
- Widget STATE structs are fields too, and the widgets point at them. The widget never allocates or frees them.
- `normal` and `focused_` are set to visibly different styles. When they were equal the focus moved correctly and was invisible, which looks identical to broken.
- The message box is drawn last, over everything, and consumes every event while it is up.

## Source

```freebasic
'' examples/form.tiko -- focus, input widgets, a modal, and CAPTURING LAMBDAS.
''
'' This is the example that exercises the library's closure-carrying design:
'' a widget that carries a closure.
''
'' Build (windows-x86_64, linux-x86_64 or macos-arm64):
''     tiko form.tiko

#import "std/numeric"
#import "std/outcome"
#import "std/tui"
using tui, numeric, outcome

'' ---------------------------------------------------------------------------
'' WHERE A CLOSURE-CARRYING WIDGET CAN BE BUILT
''
'' A capturing lambda's type is ANONYMOUS, and it cannot be given module-level
'' storage: `var shared h = sub[...]` is `error 11: Expected constant`, and
'' `dim shared h = ...` needs a type name there is no way to write. So the
'' closure lives where `var` can hold it -- module level or a local scope --
'' and the widget is BUILT THERE and handed to the app as a TuiWidget ptr.
''
'' The generic parameter is erased at the container boundary, so the app only
'' ever sees TuiWidget ptr and never needs to name the closure type at all.
'' ---------------------------------------------------------------------------
dim shared as ustring gStatus
dim shared as boolean gConfirm

'' The app's owned widget list. A NAMED type, so this one can be shared.
dim shared as TuiWidgetPtrArray gFields

sub BuildButtons( byref theme as TuiTheme )
	'' the closures, and the widgets that carry them, in one scope
	var onReset = sub[ byref gStatus ]( byval id as int32 )
		gStatus = "cleared"
	end sub
	var onSubmit = sub[ byref gStatus, byref gConfirm ]( byval id as int32 )
		gConfirm = TRUE
		gStatus = "review and confirm"
	end sub

	'' The alias is how the anonymous type gets a name. Two DIFFERENT closures
	'' give two DIFFERENT types -- and both are still TuiWidgets.
	type ResetButton  as TuiButtonOf( of typeof( onReset ) )
	type SubmitButton as TuiButtonOf( of typeof( onSubmit ) )

	dim as ResetButton ptr rb = new ResetButton
	rb->label = " Reset "
	rb->id = 1
	rb->handler = onReset
	rb->normal = theme.normal
	rb->active = theme.selected

	dim as SubmitButton ptr sb = new SubmitButton
	sb->label = " Submit "
	sb->id = 2
	sb->handler = onSubmit
	sb->normal = theme.normal
	sb->active = theme.selected

	gFields.Push( rb )
	gFields.Push( sb )
end sub

'' ---------------------------------------------------------------------------
'' A FOCUSABLE WIDGET MUST BE PERSISTENT.
''
'' Immediate mode says widgets are values that live for one frame, and that is
'' true of DECORATION -- a Block or a Paragraph can be a local inside View.
'' It is NOT true of anything the focus ring points at: the ring holds
'' TuiWidget ptr, and a widget constructed inside View dies at the end of it.
''
'' So the focusable widgets are FIELDS of the app. Their state structs are
'' still caller-owned -- what changed is the lifetime of the widget, not of the state.
type FormApp extends TuiApp
	as TuiTheme theme
	as TuiTextInputState nameState, emailState
	as boolean subscribed
	as int32 planChoice
	as TuiFocusRing ring
	as TuiMessageBox confirmBox

	'' persistent, because they are focusable
	as TuiTextInput nameIn, emailIn
	as TuiCheckbox subscribeBox
	as TuiRadioGroup planGroup

	declare destructor( ) override
	declare function Init( ) as TuiCmd override
	declare function Update( byref e as TuiEvent ) as TuiCmd override
	declare sub View( byref f as TuiFrame ) override
end type

destructor FormApp( )
	'' whoever holds the pointers owns them.
	for i as int32 = 0 to gFields.Count( ) - 1
		if( gFields[i] <> 0 ) then delete gFields[i]
	next
	gFields.Clear( )
end destructor

function FormApp.Init( ) as TuiCmd
	theme = TuiThemeDefault( )
	TuiTextInputStateInit( nameState )
	TuiTextInputStateInit( emailState )
	subscribed = FALSE
	planChoice = 0
	gConfirm = FALSE
	gStatus = "Tab cycles all six fields, Esc quits"

	'' ---- the persistent, focusable widgets
	'' A FOCUSED FIELD MUST LOOK DIFFERENT. Setting focused_ to the same style
	'' as normal makes tabbing onto a text input change nothing on screen --
	'' the field is focused and accepting keys, and the user cannot tell. The
	'' terminal cursor alone is not enough of a cue.
	dim as TuiStyle fieldNormal = TuiStyleOf( TuiDefaultColor( ), TuiRgb( 38, 38, 38 ) )
	dim as TuiStyle fieldFocus  = TuiStyleOf( TuiRgb( 20, 20, 20 ), TuiRgb( 150, 220, 255 ) )

	nameIn.state = @nameState
	nameIn.placeholder = "your name"
	nameIn.normal = fieldNormal
	nameIn.focused_ = fieldFocus
	nameIn.placeholderStyle = TuiStylePatch( TuiRgb( 130, 130, 130 ), TuiDefaultColor( ), 0, 0 )
	nameIn.selectionStyle = theme.selected

	emailIn.state = @emailState
	emailIn.placeholder = "you@example.com"
	emailIn.normal = fieldNormal
	emailIn.focused_ = fieldFocus
	emailIn.placeholderStyle = TuiStylePatch( TuiRgb( 130, 130, 130 ), TuiDefaultColor( ), 0, 0 )
	emailIn.selectionStyle = theme.selected

	subscribeBox.label = "send me updates"
	subscribeBox.checked = @subscribed
	subscribeBox.useUnicode = TRUE
	subscribeBox.normal = theme.normal
	subscribeBox.focused_ = TuiStyleOf( TuiDefaultColor( ), TuiRgb( 38, 38, 38 ) )

	planGroup.horizontal = TRUE
	planGroup.selected = @planChoice
	planGroup.useUnicode = TRUE
	planGroup.normal = theme.normal
	planGroup.focused_ = TuiStyleOf( TuiDefaultColor( ), TuiRgb( 38, 38, 38 ) )
	planGroup.activeStyle = TuiStylePatch( TuiRgb( 90, 220, 220 ), TuiDefaultColor( ), TUIATTR_BOLD, TUIATTR_BOLD )
	planGroup.options.Push( "free" )
	planGroup.options.Push( "pro" )
	planGroup.options.Push( "team" )

	'' the two closure-carrying buttons, built where their closures live
	BuildButtons( theme )

	'' THE FOCUS RING, in tab order. It holds BORROWED pointers -- it does not
	'' own anything, and every one of these outlives the frame.
	ring.Add( @nameIn )
	ring.Add( @emailIn )
	ring.Add( @subscribeBox )
	ring.Add( @planGroup )
	for each w in gFields
		ring.Add( w )
	next

	confirmBox.title = " Confirm "
	confirmBox.message = "Submit this form?"
	confirmBox.buttons.Push( "Yes" )
	confirmBox.buttons.Push( "No" )
	confirmBox.theme = theme
	confirmBox.useUnicode = TRUE
	confirmBox.msgKind = TUIMSG_QUESTION
	return TuiNone( )
end function

function FormApp.Update( byref e as TuiEvent ) as TuiCmd
	'' A MODAL CONSUMES EVERYTHING IT DOES NOT USE.
	if( gConfirm ) then
		confirmBox.HandleEvent( e )
		if( confirmBox.Accepted( ) ) then return TuiQuit( 0 )
		if( confirmBox.Cancelled( ) ) then
			gConfirm = FALSE
			gStatus = "cancelled"
		end if
		return TuiRedraw( )
	end if

	if( e.kind <> TUIEVENT_KEY ) then return TuiNone( )
	if( e.key.code = TUIKEY_ESCAPE ) then return TuiQuit( 0 )

	'' Dispatch order: the focused widget FIRST.
	dim as Optional( of TuiWidget ptr ) cur = ring.Current( )
	if( cur.HasValue( ) ) then
		if( cur.Value( )->HandleEvent( e ) ) then return TuiRedraw( )
	end if

	'' then the global bindings
	if( e.key.code = TUIKEY_TAB ) then
		if( e.key.HasMod( TUIMOD_SHIFT ) ) then ring.Prev( ) else ring.Next_( )
		return TuiRedraw( )
	end if

	return TuiNone( )
end function

sub FormApp.View( byref f as TuiFrame )
	dim as TuiRect box = TuiCenter( f.Area( ), 56, 16 )

	dim as TuiBlock blk
	blk.borderKind = TUIBORDER_ROUNDED
	blk.sides = TUISIDE_ALL
	blk.borderStyle = theme.border
	blk.fill = TRUE
	blk.fillStyle = theme.normal
	blk.AddTitle( " Sign up ", theme.title, TUISIDE_TOP, TUIALIGN_CENTER )
	blk.AddTitle( " Esc quits ", theme.dim_, TUISIDE_BOTTOM, TUIALIGN_RIGHT )
	blk.Render( f, box )

	dim as TuiRect inner = TuiPadAll( blk.Inner( box ), 1 )

	dim as TuiConstraintArray rows
	rows.Push( TuiLength( 2 ) )      '' name
	rows.Push( TuiLength( 2 ) )      '' email
	rows.Push( TuiLength( 1 ) )      '' subscribe
	rows.Push( TuiLength( 2 ) )      '' plan
	rows.Push( TuiFill( ) )          '' spacer
	rows.Push( TuiLength( 1 ) )      '' buttons
	rows.Push( TuiLength( 1 ) )      '' status
	dim as TuiRectArray r = TuiSplitV( inner, rows )

	'' a label beside each input, so an empty focused field is still readable
	dim as TuiConstraintArray fc
	fc.Push( TuiLength( 8 ) )
	fc.Push( TuiFill( ) )

	dim as TuiRectArray nrow = TuiSplitH( TuiRectOf( r[0].x, r[0].y, r[0].w, 1 ), fc )
	dim as TuiParagraph nlab
	nlab.text = "Name" : nlab.st = theme.dim_
	nlab.Render( f, nrow[0] )
	nameIn.Render( f, nrow[1] )

	dim as TuiRectArray erow = TuiSplitH( TuiRectOf( r[1].x, r[1].y, r[1].w, 1 ), fc )
	dim as TuiParagraph elab
	elab.text = "Email" : elab.st = theme.dim_
	elab.Render( f, erow[0] )
	emailIn.Render( f, erow[1] )

	subscribeBox.Render( f, r[2] )
	planGroup.Render( f, r[3] )

	'' the two buttons -- both closure-backed, rendered through the SAME base
	'' pointer
	dim as TuiConstraintArray bc
	bc.Push( TuiFill( ) )
	bc.Push( TuiLength( 9 ) )
	bc.Push( TuiLength( 10 ) )
	dim as TuiRectArray bt = TuiSplitH( r[5], bc )
	if( gFields.Count( ) >= 2 ) then
		gFields[0]->Render( f, bt[1] )
		gFields[1]->Render( f, bt[2] )
	end if

	'' the status line names the focused widget, so "did Tab do anything?" is
	'' answerable without squinting
	dim as ustring focusName = "(none)"
	dim as Optional( of TuiWidget ptr ) cur = ring.Current( )
	if( cur.HasValue( ) ) then focusName = cur.Value( )->Kind( )

	dim as TuiParagraph st
	st.text = gStatus & "   [focus: " & focusName & "]"
	st.st = theme.dim_
	st.Render( f, r[6] )

	'' The modal draws into its own LAYER, so what is beneath survives
	'' dismissal intact.
	if( gConfirm ) then
		confirmBox.Render( f, TuiCenter( f.Area( ), 36, 7 ) )
	end if
end sub

'' ---------------------------------------------------------------------------
dim as TuiTermOptions opts = TuiTermOptionsDefault( )
opts.hideCursor = FALSE          '' a form wants a visible cursor

dim as FormApp app
dim as TuiRunResult r = TuiRun( app, opts )
if( r.IsOk( ) = false ) then
	print "form: " & r.Failure( ).Message( )
	end 1
end if
```

---

**Library:** [Terminal TUI Library](Category-Terminal-TUI-Library)  
**Other examples:** [hello.tiko](Modern-Tui-Example-Hello) · [dashboard.tiko](Modern-Tui-Example-Dashboard)



---

[Home](Home) · [Keyword Index](Keyword-Index)