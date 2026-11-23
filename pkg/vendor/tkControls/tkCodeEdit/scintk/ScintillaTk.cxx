// Copyright (C) 2026 Paul Squires, PlanetSquires Software
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ===========================================================================
// ScintillaTk.cxx -- a concrete Scintilla host, plus the C shim tkCodeEdit
// calls (scintk.h).
//
// A port of PsPlatform's src/scintilla/ScintillaPs.cxx, renamed SciPs_ ->
// SciTk_. The editor, its tickers, clipboard, notifications and menu are
// PsPlatform's. What changed: painting goes to a host TARGET through
// PlatTk's SurfaceTk instead of a Blend2D image, the font path is set on its
// own (SciTk_SetFontPath), and Lexilla's CreateLexer is exported as
// SciTk_CreateLexer so the host needs no second library.
// ===========================================================================

#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <cmath>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <set>
#include <optional>
#include <algorithm>
#include <memory>
#include <chrono>
// PerLine.h uses std::forward_list without including it, relying on the header
// arriving transitively. MSVC's standard library provides it that way and gcc's
// does not, so building this tree outside Visual Studio needs it here. Same for
// <forward_list>'s neighbours below -- listed explicitly rather than hoping.
#include <forward_list>
#include <deque>
#include <cassert>
#include <cstdint>
#include <iterator>
#include <numeric>
#include <functional>

#include "ScintillaTypes.h"
#include "ScintillaMessages.h"
#include "ScintillaStructures.h"
#include "ILoader.h"
#include "ILexer.h"

#include "Debugging.h"
#include "Geometry.h"
#include "Platform.h"

#include "CharacterCategoryMap.h"
#include "Position.h"
#include "UniqueString.h"
#include "SplitVector.h"
#include "Partitioning.h"
#include "RunStyles.h"
#include "ContractionState.h"
#include "CellBuffer.h"
#include "PerLine.h"
#include "KeyMap.h"
#include "Indicator.h"
#include "LineMarker.h"
#include "Style.h"
#include "ViewStyle.h"
#include "CharClassify.h"
#include "Decoration.h"
#include "CaseFolder.h"
#include "Document.h"
#include "UniConversion.h"
#include "Selection.h"
#include "PositionCache.h"
#include "EditModel.h"
#include "MarginView.h"
#include "EditView.h"
#include "Editor.h"
#include "CallTip.h"
#include "AutoComplete.h"
#include "ScintillaBase.h"

#include "Lexilla.h"

#include "scintk.h"

using namespace Scintilla;
using namespace Scintilla::Internal;

// Provided by PlatPs.cxx. SetFontPath is extern "C" there -- it is part of the
// door the host knocks on -- so it must be declared that way here too, or the
// two names mangle differently and the link fails on the C++ one.
std::unique_ptr<Surface> PlatTk_SurfaceForTarget(void *target);
void PlatTk_SetWindowRect(int w, int h);
extern "C" void PlatTk_SetFontPath(const char *p);
int PlatTk_CursorOf(void *wid);
void PlatTk_SetEditorRect(void *wid, int w, int h);
void PlatTk_ForgetEditor(void *wid);
const SciTkMenuHost *PlatTk_MenuHost();
void *PlatTk_MenuUser();
void PlatTk_CallTipRegister(void *wid, void *editor, const SciTkCallTipHost *host, void *user);
void PlatTk_CallTipForget(void *wid);

namespace {

class ScintillaTk : public ScintillaBase {
public:
	std::string clipboard;      // process-local; see CopyToClipboard and Paste
	int notifyCount = 0;
	int lastNotification = 0;
	bool mouseCaptured = false;
	SciTkNotifyFn notifyFn = nullptr;
	void *notifyUser = nullptr;
	SciTkClipGetFn clipGetFn = nullptr;
	SciTkClipSetFn clipSetFn = nullptr;
	void *clipUser = nullptr;
	const SciTkCallTipHost *callTipHost = nullptr;
	void *callTipUser = nullptr;
	int dpi = 0;                // 0: the process default (SciTk_SetDpi)

	// Editor's input entry points are PROTECTED -- reachable from a derived
	// class, not from the free functions of the C shim. These forwarders are
	// the whole reason they exist; they add nothing but access.
	int TkKeyDown(int key, int mods) {
		bool consumed = false;
		KeyDownWithModifiers(static_cast<Keys>(key), static_cast<KeyMod>(mods), &consumed);
		return consumed ? 1 : 0;
	}
	// Committed text. A composition in progress is TENTATIVE text and goes
	// first, as ScintillaGTK::CommitThis does: the commit replaces it.
	void TkTextInput(std::string_view sv) {
		view.imeCaretBlockOverride = false;
		if (pdoc->TentativeActive()) pdoc->TentativeUndo();
		InsertCharacter(sv, CharacterSource::DirectInput);
	}

	// ScintillaGTK::PreeditChangedInlineThis, without GTK: the pre-edit is
	// inserted tentatively, one character at a time, marked with the IME
	// indicator, and the carets moved to the input method's cursor.
	void TkImeCompose(std::string_view text, int cursorChars) {
		if (pdoc->IsReadOnly() || SelectionContainsProtected()) return;
		view.imeCaretBlockOverride = false;
		bool initialCompose = false;
		if (pdoc->TentativeActive()) pdoc->TentativeUndo();
		else initialCompose = true;
		if (text.empty()) {
			ShowCaretAtCurrentPosition();
			return;
		}
		if (initialCompose) ClearBeforeTentativeStart();
		pdoc->TentativeStart();
		int nChars = 0;
		size_t i = 0;
		while (i < text.size()) {
			const unsigned char lead = static_cast<unsigned char>(text[i]);
			size_t len = (lead >= 0xF0) ? 4 : (lead >= 0xE0) ? 3 : (lead >= 0xC0) ? 2 : 1;
			if (i + len > text.size()) len = text.size() - i;
			InsertCharacter(text.substr(i, len), CharacterSource::TentativeInput);
			DrawImeIndicator(static_cast<int>(IndicatorNumbers::Ime), static_cast<Sci::Position>(len));
			i += len;
			nChars++;
		}
		if (cursorChars >= 0 && cursorChars <= nChars) {
			const Sci::Position imeCaret = pdoc->GetRelativePosition(CurrentPosition(), cursorChars - nChars);
			MoveImeCarets(-CurrentPosition() + imeCaret);
		}
		EnsureCaretVisible();
		ShowCaretAtCurrentPosition();
	}
	void TkCaretRect(int *x, int *y, int *lh) {
		const Point pt = PointMainCaret();
		if (x) *x = static_cast<int>(pt.x);
		if (y) *y = static_cast<int>(pt.y);
		if (lh) *lh = vs.lineHeight;
	}
	void TkSetDpi(int dpi_) {
		dpi = dpi_;
		InvalidateStyleRedraw();
	}

	// ---- Call tips ---------------------------------------------------------
	void TkPaintCallTip(void *target, int w, int h) {
		std::unique_ptr<Surface> surf = PlatTk_SurfaceForTarget(target);
		surf->SetMode(SurfaceMode(CodePage(), false));
		// THE TIP IS AS LARGE AS ITS WINDOW. A window is a whole number of SDL units, so on a
		// density-2 (Retina) display an odd pixel size comes out one larger than CallTipStart's,
		// and PaintCT, which fills and frames its own rect, left that strip unpainted.
		if (w > 0 && h > 0) {
			const PRectangle rc = ct.wCallTip.GetPosition();
			ct.wCallTip.SetPosition(PRectangle(rc.left, rc.top, rc.left + w, rc.top + h));
		}
		// A FLAT BORDER IN THE TIP'S OWN COLOURS, not Scintilla's raised one (silver top and left,
		// black right and bottom, fixed): on a dark tip the silver read as a white frame (tkEdit,
		// 2026-10-28). 15% of the way from the tip's back toward its text, whatever the theme.
		ct.colourLight = ct.colourBG.MixedWith(ct.colourUnSel, 0.15);
		ct.colourShade = ct.colourLight;
		ct.PaintCT(surf.get());
#if defined(__APPLE__)
		// CallTip.cxx draws no border under __APPLE__ (Cocoa's help tags have none) and fills only
		// inside it, so the 1-pixel edge was never painted. scintk is not Cocoa: the same frame here.
		if (w > 2 && h > 2) {
			const XYPOSITION fw = static_cast<XYPOSITION>(w), fh = static_cast<XYPOSITION>(h);
			surf->FillRectangle(PRectangle(0, 0, fw, 1), ct.colourLight);
			surf->FillRectangle(PRectangle(0, fh - 1, fw, fh), ct.colourShade);
			surf->FillRectangle(PRectangle(0, 1, 1, fh - 1), ct.colourLight);
			surf->FillRectangle(PRectangle(fw - 1, 1, fw, fh - 1), ct.colourShade);
		}
#endif
		surf->Release();
	}
	void TkCallTipClick(Point pt) {
		ct.MouseClick(pt);
		CallTipClick();
	}

	// TEXT DRAG WITHOUT AN OS DRAG. Editor::StartDrag is "always handled by
	// subclasses": ScintillaWin starts OLE, ScintillaGTK a GTK drag. Here the
	// drag stays inside the editor -- Editor's own ButtonUp moves (or, with Ctrl,
	// copies) the text once inDragDrop says dragging, and the host already holds
	// the mouse capture until the release.
	//
	// THE CAPTURE IS TAKEN BACK. Editor releases it just before StartDrag (an
	// OS drag owns the mouse from there), but ButtonUp drops only while it
	// holds it -- without this the drop was silently a click (measured).
	void StartDrag() override {
		inDragDrop = DragDrop::dragging;
		ChangeMouseCapture(true);
	}
	// THE RECTANGLE KEY IS THE PLATFORM'S. Editor makes a rectangle when the
	// mouse carries Alt; SCI_SETRECTANGULARSELECTIONMODIFIER is handled by each
	// platform, which reports its chosen key AS Alt (ScintillaGTK's
	// ModifierFlags). Alt by default, as on Win32 and GTK.
	int rectangularModifier = static_cast<int>(KeyMod::Alt);
	KeyMod MouseMods(int mods) const noexcept {
		int m = mods & ~static_cast<int>(KeyMod::Alt);
		if (mods & rectangularModifier) m |= static_cast<int>(KeyMod::Alt);
		return static_cast<KeyMod>(m);
	}
	sptr_t WndProc(Message iMessage, uptr_t wParam, sptr_t lParam) override {
		switch (iMessage) {
		case Message::SetRectangularSelectionModifier:
			rectangularModifier = static_cast<int>(wParam);
			return 0;
		case Message::GetRectangularSelectionModifier:
			return rectangularModifier;
		default:
			return ScintillaBase::WndProc(iMessage, wParam, lParam);
		}
	}

	void TkMouseDown(Point pt, unsigned int t, int mods, bool bRight) {
		if (bRight) RightButtonDownWithModifiers(pt, t, MouseMods(mods));
		else        ButtonDownWithModifiers(pt, t, MouseMods(mods));
	}
	void TkMouseMove(Point pt, unsigned int t, int mods) {
		ButtonMoveWithModifiers(pt, t, MouseMods(mods));
		// a text drag in progress shows where it would drop (GTK's DragMotion)
		if (inDragDrop == DragDrop::dragging)
			SetDragPosition(SPositionFromLocation(pt, false, false, false));
	}
	// THE RELEASE POINT COUNTS. While captured, Editor throttles moves
	// (autoScrollTimer) and lets the scroll ticker catch up later, so a release
	// right after a fast move ended a rectangle one line short (measured). The
	// last move is applied, unthrottled, before the release.
	void TkMouseUp(Point pt, unsigned int t, int mods) {
		if (HaveMouseCapture()) {
			autoScrollTimer.ticksToWait = 0;
			ButtonMoveWithModifiers(pt, t, MouseMods(mods));
		}
		ButtonUpWithModifiers(pt, t, MouseMods(mods));
	}
	void TkSetFocus(bool on) { SetFocusState(on); }
	void TkChangeSize() { ChangeSize(); }

	// ContextMenu is protected and is NOT called by Scintilla itself -- on
	// Win32 it is ScintillaWin's WM_CONTEXTMENU handler that calls it. So when
	// the context menu appears is the platform's decision, and here that means
	// the host's: tkCodeEdit raises it on the right-button RELEASE, which
	// is where a context menu conventionally appears.
	void TkContextMenu(Point pt) { ContextMenu(pt); }

	// TickFor is protected on Editor, like the input entry points above -- and
	// so is TickReason itself, which is why this takes an int and casts inside
	// the class rather than exposing the enum to the C shim.
	void TkTick(int reason) { TickFor(static_cast<TickReason>(reason)); }

	// ---- Fine tickers ---------------------------------------------------
	// Editor's base implementations are assert(false): they exist to catch a
	// subclass that forgot. Any edit starts the caret-blink ticker, so without
	// these the FIRST insertion aborts a debug build.
	//
	// They RECORD, and then TELL THE HOST. Caret blink, scroll auto-repeat and
	// dwell are all timing, and the host owns the clock -- it is the only thing
	// that has a pump. Scintilla starts and cancels these at arbitrary moments
	// inside an edit, so the host cannot poll for them; it is called.
	//
	// The host's obligation is two lines: arm a timer of `millis` on start,
	// kill it on cancel, and call SciTk_Tick(reason) when it fires.
	//
	// WITHOUT A HOST CALLBACK THESE STILL ONLY RECORD, and the caret does not
	// blink. That is what shipped, and it was the honest behaviour rather than
	// a silent one -- but it is no longer necessary.
	bool tickers[8] = {};
	int tickerMs[8] = {};
	SciTkTickerFn tickerFn = nullptr;
	void *tickerUser = nullptr;
	static size_t TickIx(TickReason r) {
		const size_t i = static_cast<size_t>(r);
		return (i < 8) ? i : 0;
	}
	void FineTickerStart(TickReason reason, int millis, int) override {
		const size_t ix = TickIx(reason);
		tickers[ix] = true;
		tickerMs[ix] = millis;
		// The TOLERANCE is dropped. It is a coalescing hint for platforms with a
		// timer-slack API; neither host has one, and honouring it by firing
		// early would make the blink irregular rather than cheap.
		if (tickerFn) {
			try {
				tickerFn(tickerUser, static_cast<int>(reason), millis, 1);
			} catch (...) {
			}
		}
	}
	void FineTickerCancel(TickReason reason) override {
		const size_t ix = TickIx(reason);
		// Only on a real transition. Scintilla cancels unconditionally before
		// every start -- see Editor::ShowCaretAtCurrentPosition -- so a host
		// that killed and re-created an OS timer on each one would churn two
		// timers per keystroke.
		if (!tickers[ix]) return;
		tickers[ix] = false;
		tickerMs[ix] = 0;
		if (tickerFn) {
			try {
				tickerFn(tickerUser, static_cast<int>(reason), 0, 0);
			} catch (...) {
			}
		}
	}
	bool FineTickerRunning(TickReason reason) override {
		return tickers[TickIx(reason)];
	}

	ScintillaTk(int w, int h) {
		wMain = reinterpret_cast<WindowID>(this);   // opaque; never an OS handle
		PlatTk_SetWindowRect(w, h);
		PlatTk_SetEditorRect(this, w, h);
		Initialise();
	}
	~ScintillaTk() override { PlatTk_CallTipForget(&ct); PlatTk_ForgetEditor(this); }

	// ---- Editor's 14 -----------------------------------------------------
	void Initialise() override {}

	// BOTH are no-ops, and the horizontal one is a no-op DELIBERATELY. These are
	// "push the editor's scroll position OUT to the platform scrollbar widget";
	// this backend has no widget -- the host owns the bars and polls
	// SCI_GETXOFFSET / SCI_GETFIRSTVISIBLELINE. Scinterm writes `xOffset = 0`
	// here because a curses backend genuinely cannot scroll sideways; copying
	// that makes SCI_SETXOFFSET a no-op (it assigns xOffset, then calls this),
	// which silently disables ALL horizontal scrolling -- the bar, caret
	// tracking and Shift+wheel alike.
	void SetVerticalScrollPos() override {}
	void SetHorizontalScrollPos() override {}
	bool ModifyScrollBars(Sci::Line, Sci::Line) override { return false; }

	// SelectionText() default-constructs an EMPTY object -- it is a type, not an
	// accessor. The selected text has to be fetched with CopySelectionRange,
	// exactly as ScintillaWin::Copy does. Getting this wrong copies nothing and
	// reports no error.
	void Copy() override {
		if (!sel.Empty()) {
			SelectionText selectedText;
			CopySelectionRange(&selectedText);
			CopyToClipboard(selectedText);
		}
	}
	// THE HOST OWNS THE CLIPBOARD, and it has to: the only two hosts this shim
	// has do not share one. A demo runs on SDL3 and wants g_plat.clip; tiko runs
	// on PsWin32Host, never initialises the SDL tables at all, and wants the
	// Win32 clipboard. Calling either from here would be wrong for the other.
	//
	// Until a host installs these, `clipboard` below is a process-local buffer:
	// copy and paste then work WITHIN the editor and exchange nothing with the
	// desktop. That is what shipped, and it is why paste appeared dead --
	// nothing read the buffer back, because Paste() was an empty override.
	void Paste() override {
		std::string text;
		if (clipGetFn) {
			const char *p = clipGetFn(clipUser);
			if (p) text.assign(p);
		} else {
			text = clipboard;
		}
		if (text.empty()) return;

		// ScintillaWin's shape, minus the rectangular/line clipboard formats:
		// this clipboard carries plain UTF-8 and nothing records that a copy
		// was a rectangular selection, so every paste is a stream paste.
		//
		// THE UNDO GROUP IS NOT OPTIONAL. ClearSelection and the insert are two
		// document modifications; without the group a single Ctrl+V takes two
		// presses of Ctrl+Z to undo.
		UndoGroup ug(pdoc);
		ClearSelection(multiPasteMode == Scintilla::MultiPaste::Each);
		InsertPasteShape(text.c_str(), static_cast<Sci::Position>(text.length()),
		                 PasteShape::stream);
		EnsureCaretVisible();
	}
	void ClaimSelection() override {}
	void NotifyChange() override {}
	// The one place a C++ notification becomes a plain C record. Every field is
	// copied rather than aliased, because NotificationData is upstream's type
	// and its layout is upstream's business; see scintk.h.
	void NotifyParent(NotificationData scn) override {
		notifyCount++;
		lastNotification = static_cast<int>(scn.nmhdr.code);
		if (!notifyFn) return;

		SciTkNotification n{};
		n.code                 = static_cast<int>(scn.nmhdr.code);
		n.position             = static_cast<long long>(scn.position);
		n.ch                   = scn.ch;
		n.modifiers            = static_cast<int>(scn.modifiers);
		n.modificationType     = static_cast<int>(scn.modificationType);
		n.text                 = scn.text;
		n.length               = static_cast<long long>(scn.length);
		n.linesAdded           = static_cast<long long>(scn.linesAdded);
		n.message              = static_cast<int>(scn.message);
		n.wParam               = static_cast<long long>(scn.wParam);
		n.lParam               = static_cast<long long>(scn.lParam);
		n.line                 = static_cast<long long>(scn.line);
		n.foldLevelNow         = static_cast<int>(scn.foldLevelNow);
		n.foldLevelPrev        = static_cast<int>(scn.foldLevelPrev);
		n.margin               = scn.margin;
		n.listType             = scn.listType;
		n.x                    = scn.x;
		n.y                    = scn.y;
		n.token                = scn.token;
		n.annotationLinesAdded = static_cast<long long>(scn.annotationLinesAdded);
		n.updated              = static_cast<int>(scn.updated);
		n.listCompletionMethod = static_cast<int>(scn.listCompletionMethod);

		// A handler that throws would unwind through Scintilla's own edit
		// machinery and leave the document half-modified. Contained here.
		try {
			notifyFn(notifyUser, &n);
		} catch (...) {
		}
	}
	void CopyToClipboard(const SelectionText &selectedText) override {
		// The local buffer is kept even when a host is installed: it is what
		// SciTk_ClipboardText reports, and the suite asserts a copy through it
		// without needing a desktop clipboard to be present in CI.
		clipboard.assign(selectedText.Data(), selectedText.Length());
		if (clipSetFn) {
			try {
				clipSetFn(clipUser, clipboard.c_str());
			} catch (...) {
			}
		}
	}
	void SetMouseCapture(bool on) override { mouseCaptured = on; }
	bool HaveMouseCapture() override { return mouseCaptured; }

	// The document is UTF-8 throughout this spike, so both directions are
	// identity. tiko's encoding handling lives above Scintilla and is unaffected.
	std::string UTF8FromEncoded(std::string_view encoded) const override {
		return std::string(encoded);
	}
	std::string EncodedFromUTF8(std::string_view utf8) const override {
		return std::string(utf8);
	}

	sptr_t DefWndProc(Message, uptr_t, sptr_t) override { return 0; }

	// ---- ScintillaBase's 2 ----------------------------------------------
	// The tip's window is named after its CallTip and registered with this
	// editor's host table; Window's methods route the rest (PlatTk.cxx).
	void CreateCallTipWindow(PRectangle rc) override {
		ct.wCallTip = static_cast<WindowID>(&ct);
		PlatTk_CallTipRegister(&ct, this, callTipHost, callTipUser);
		ct.wCallTip.SetPosition(rc);
	}
	// Each item of the context menu ScintillaBase built. An EMPTY LABEL IS A
	// SEPARATOR -- Scintilla's convention, and passed through as such rather
	// than dropped, because the host cannot tell otherwise.
	void AddToPopUp(const char *label, int cmd, bool enabled) override {
		const SciTkMenuHost *h = PlatTk_MenuHost();
		if (h && h->AddItem)
			h->AddItem(PlatTk_MenuUser(), label ? label : "", cmd, enabled ? 1 : 0);
	}

	// ScintillaBase's idcmd* ids are its OWN, not SCI_* messages. ScintillaWin
	// does this same translation in its WM_COMMAND handler; keeping it here is
	// what stops the host having to know a set of ids it never sees defined.
	void TkMenuCommand(int cmd) {
		switch (cmd) {
		case idcmdUndo:      WndProc(Message::Undo, 0, 0); break;
		case idcmdRedo:      WndProc(Message::Redo, 0, 0); break;
		case idcmdCut:       WndProc(Message::Cut, 0, 0); break;
		case idcmdCopy:      WndProc(Message::Copy, 0, 0); break;
		case idcmdPaste:     WndProc(Message::Paste, 0, 0); break;
		case idcmdDelete:    WndProc(Message::Clear, 0, 0); break;
		case idcmdSelectAll: WndProc(Message::SelectAll, 0, 0); break;
		default: break;
		}
	}

	// ---- painting --------------------------------------------------------
	void PaintTo(void *target, int w, int h) {
		std::unique_ptr<Surface> surf = PlatTk_SurfaceForTarget(target);
		surf->SetMode(SurfaceMode(CodePage(), false));
		rcPaint = PRectangle(0, 0, w, h);
		paintState = PaintState::painting;
		paintingAllText = true;
		Paint(surf.get(), rcPaint);
		paintState = PaintState::notPainting;
		surf->Release();
	}

	int CodePage() const {
		return pdoc ? pdoc->dbcsCodePage : 0;
	}
};

} // namespace

// ===========================================================================
// C shim -- the ABI FreeBASIC binds to.
//
// SciTk_Send has the SAME SHAPE as tiko's Scintilla_DirectFunction:
//     sptr_t (*)(void *ptr, unsigned int msg, uptr_t wParam, sptr_t lParam)
// which is the entire reason the 801 existing call sites can survive.
// ===========================================================================
// EVERY ENTRY POINT THAT REACHES AN EDITOR GOES THROUGH Use(). Scintilla asks
// a Surface for LogPixelsY, and a Surface carries no editor, so the DPI is a
// process value (PlatTk's g_dpiY); Use() makes it this editor's before the
// call. That is what lets two editors on monitors of different scale coexist.
// LINKED STATICALLY INTO A WINDOWS PROGRAM (SCITK_STATIC, the archive build.sh makes for
// tiko's 'link static'), nothing has initialised the static C++ runtime's per-thread
// exception data: libcmt's startup does that, and a tiko program starts through tiko-rt
// instead. The first throw then crashed. tiko-rt does run C++ static constructors, so one
// here initialises it before any entry point is called. The DLL build must not: its own
// startup already has, and initialising twice is not supported.
// __vcrt_initialize IS libcmt's OWN, and only the MSVC ABI has it: the MinGW flavour's C++
// runtime initialises itself, and the call there is an undefined reference (measured,
// 'undefined symbol: __vcrt_initialize'). _MSC_VER is what tells the two apart -- clang
// defines it for the MSVC target and not for the MinGW one.
#if defined(_WIN32) && defined(_MSC_VER) && defined(SCITK_STATIC)
extern "C" bool __cdecl __vcrt_initialize();
[[maybe_unused]] static const bool g_vcrtReady = __vcrt_initialize();
#endif

static ScintillaTk *Use(void *p) {
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	if (sci->dpi > 0) SciTk_SetDpi(sci->dpi);
	return sci;
}

extern "C" {

SCITK_API void SciTk_SetFontPath(const char *path) { PlatTk_SetFontPath(path); }

SCITK_API void *SciTk_Create(int w, int h) {
	try {
		return new ScintillaTk(w, h);
	} catch (...) {
		return nullptr;
	}
}

SCITK_API void SciTk_Destroy(void *p) {
	delete static_cast<ScintillaTk *>(p);
}

SCITK_API intptr_t SciTk_Send(void *p, unsigned int msg, uintptr_t wParam, intptr_t lParam) {
	if (!p) return 0;
	try {
		return Use(p)->WndProc(
			static_cast<Message>(msg),
			static_cast<uptr_t>(wParam),
			static_cast<sptr_t>(lParam));
	} catch (...) {
		// Scintilla throws on some invalid arguments; a thrown exception must
		// never cross back into FreeBASIC, which has no way to catch it.
		return 0;
	}
}

// Paint the whole view into the host's target. The host has made it current;
// every pixel of (0,0,w,h) is drawn, so it need not be cleared first.
SCITK_API int SciTk_Paint(void *p, void *target, int w, int h) {
	if (!p || !target || w <= 0 || h <= 0) return 0;
	try {
		Use(p)->PaintTo(target, w, h);
		return 1;
	} catch (...) {
		return 0;
	}
}

// ---- Input -------------------------------------------------------------
// Thin on purpose: these are Editor's own methods with a try/catch and a cast.
// Every decision about WHAT to send is the host's, on the FreeBASIC side.

SCITK_API int SciTk_KeyDown(void *p, int key, int mods) {
	if (!p) return 0;
	try {
		return Use(p)->TkKeyDown(key, mods);
	} catch (...) {
		return 0;
	}
}

SCITK_API void SciTk_TextInput(void *p, const char *utf8, int nBytes) {
	if (!p || !utf8 || nBytes <= 0) return;
	try {
		// string_view, not a C string: committed IME text can contain anything
		// and the length is what the host actually knows.
		Use(p)->TkTextInput(
			std::string_view(utf8, static_cast<size_t>(nBytes)));
	} catch (...) {
	}
}

SCITK_API void SciTk_MouseDown(void *p, int x, int y, unsigned int timeMs, int mods, int bRight) {
	if (!p) return;
	try {
		Use(p)->TkMouseDown(
			Point::FromInts(x, y), timeMs, mods, bRight != 0);
	} catch (...) {
	}
}

SCITK_API void SciTk_MouseMove(void *p, int x, int y, unsigned int timeMs, int mods) {
	if (!p) return;
	try {
		Use(p)->TkMouseMove(Point::FromInts(x, y), timeMs, mods);
	} catch (...) {
	}
}

SCITK_API void SciTk_MouseUp(void *p, int x, int y, unsigned int timeMs, int mods) {
	if (!p) return;
	try {
		Use(p)->TkMouseUp(Point::FromInts(x, y), timeMs, mods);
	} catch (...) {
	}
}

SCITK_API void SciTk_SetFocus(void *p, int bFocused) {
	if (!p) return;
	try {
		Use(p)->TkSetFocus(bFocused != 0);
	} catch (...) {
	}
}

// Scintilla lays out from the rect it was given. A pane whose bounds changed
// and did not say so scrolls and wraps against the OLD size.
SCITK_API void SciTk_SetSize(void *p, int w, int h) {
	if (!p || w <= 0 || h <= 0) return;
	try {
		PlatTk_SetEditorRect(p, w, h);
		Use(p)->TkChangeSize();
	} catch (...) {
	}
}

SCITK_API void SciTk_ContextMenu(void *p, int x, int y) {
	if (!p) return;
	try {
		Use(p)->TkContextMenu(Point::FromInts(x, y));
	} catch (...) {
	}
}

SCITK_API void SciTk_MenuCommand(void *p, int cmd) {
	if (!p) return;
	try {
		Use(p)->TkMenuCommand(cmd);
	} catch (...) {
	}
}

SCITK_API void SciTk_SetNotifyCallback(void *p, SciTkNotifyFn fn, void *user) {
	if (!p) return;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	sci->notifyFn = fn;
	sci->notifyUser = user;
}

SCITK_API int SciTk_NotifyCount(void *p) {
	return p ? Use(p)->notifyCount : 0;
}

SCITK_API void SciTk_SetTickerCallback(void *p, SciTkTickerFn fn, void *user) {
	if (!p) return;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	sci->tickerFn = fn;
	sci->tickerUser = user;
}

SCITK_API void SciTk_Tick(void *p, int reason) {
	if (!p) return;
	if (reason < 0 || reason > 4) return;
	Use(p)->TkTick(reason);
}

SCITK_API int SciTk_TickerRunning(void *p, int reason) {
	if (!p) return 0;
	if (reason < 0 || reason > 4) return 0;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	return sci->tickers[static_cast<size_t>(reason)] ? 1 : 0;
}

SCITK_API int SciTk_TickerInterval(void *p, int reason) {
	if (!p) return 0;
	if (reason < 0 || reason > 4) return 0;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	return sci->tickerMs[static_cast<size_t>(reason)];
}

SCITK_API void SciTk_SetClipboardHooks(void *p, SciTkClipGetFn getFn, SciTkClipSetFn setFn,
                             void *user) {
	if (!p) return;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	sci->clipGetFn = getFn;
	sci->clipSetFn = setFn;
	sci->clipUser = user;
}

SCITK_API const char *SciTk_ClipboardText(void *p) {
	return p ? Use(p)->clipboard.c_str() : "";
}

SCITK_API int SciTk_Cursor(void *p) {
	return p ? PlatTk_CursorOf(p) : 0;
}

SCITK_API void SciTk_SetCallTipHost(void *p, const SciTkCallTipHost *host, void *user) {
	if (!p) return;
	ScintillaTk *sci = static_cast<ScintillaTk *>(p);
	sci->callTipHost = host;
	sci->callTipUser = user;
}

SCITK_API int SciTk_PaintCallTip(void *p, void *target, int w, int h) {
	if (!p || !target || w <= 0 || h <= 0) return 0;
	try {
		Use(p)->TkPaintCallTip(target, w, h);
		return 1;
	} catch (...) {
		return 0;
	}
}

SCITK_API void SciTk_CallTipClick(void *p, int x, int y) {
	if (!p) return;
	try {
		Use(p)->TkCallTipClick(Point::FromInts(x, y));
	} catch (...) {
	}
}

SCITK_API void SciTk_ImeCompose(void *p, const char *utf8, int nBytes, int cursorChars) {
	if (!p) return;
	try {
		Use(p)->TkImeCompose(std::string_view(utf8 ? utf8 : "", utf8 && nBytes > 0 ? static_cast<size_t>(nBytes) : 0),
		                     cursorChars);
	} catch (...) {
	}
}

SCITK_API void SciTk_CaretRect(void *p, int *x, int *y, int *lineHeight) {
	if (!p) return;
	try {
		Use(p)->TkCaretRect(x, y, lineHeight);
	} catch (...) {
	}
}

SCITK_API void SciTk_SetEditorDpi(void *p, int dpi) {
	if (!p || dpi < 48 || dpi > 960) return;
	try {
		ScintillaTk *sci = static_cast<ScintillaTk *>(p);
		sci->dpi = dpi;
		Use(p)->TkSetDpi(dpi);
	} catch (...) {
	}
}

SCITK_API void *SciTk_CreateLexer(const char *name) {
	if (!name) return nullptr;
	try {
		return CreateLexer(name);
	} catch (...) {
		return nullptr;
	}
}

SCITK_API int SciTk_AbiVersion(void) { return SCITK_ABI_VERSION; }
SCITK_API int SciTk_NotificationSize(void) { return static_cast<int>(sizeof(SciTkNotification)); }

} // extern "C"
