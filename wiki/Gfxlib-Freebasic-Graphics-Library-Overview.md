[Home](Home) › [Graphics Library Reference](Category-Graphics-Library-Reference) › **GfxLib - FreeBASIC graphics library overview**

# GfxLib - FreeBASIC graphics library overview

The libary named GfxLib is the built-in graphics library included in FreeBASIC. As well as re-creating every QuickBASIC graphics command, GfxLib has built-in commands to handle input from the keyboard and mouse. Major contributors of the library are Lillo, coderJeff and DrV.

> **In tiko.** tiko's graphics library, libtkogfx, is a drop-in for GfxLib and ships for Windows, Linux and macOS. Its drivers are **GDI** on Windows, **X11** on Linux (libX11 loaded at run time) and **Cocoa** on macOS, plus **`Null`** everywhere. The DirectX, Direct2D, OpenGL and FBDev drivers listed below are not provided. See [Compatibility](Compatibility).

 The library supports various drivers depending on the platform:

- All:

  - **`Null`** Does nothing, allows to use graphics functions on in-memory buffers and such, without anything being displayed in a graphics window. [(gfxlib2/gfx_driver_null.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/gfx_driver_null.c)

  Windows:

  - **`Direct2D`** the default selection of FB GfxLib. For the compiler built on WinXP + mingw.org (very old tool chain now), the **`Direct2D`** driver is disabled in the gfxlib.
  **`DirectX`** is fallback if **`Direct2D`** can't be initialized. May not be available on old Windows installations. [(gfxlib2/win32/gfx_driver_ddraw.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/win32/gfx_driver_ddraw.c)
  **`GDI`** as last resort, the "safest" one, available in all Windows versions.
  **`OpenGL`** [(gfxlib2/win32/gfx_driver_opengl.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/win32/gfx_driver_opengl.c)

  Linux & others:

  - **`X11`** The default on Unix systems [(gfxlib2/unix/gfx_driver_x11.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/unix/gfx_driver_x11.c)
  **`OpenGL`** (on top of X11) [(gfxlib2/unix/gfx_driver_opengl_x11.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/unix/gfx_driver_opengl_x11.c)
  **`FBDev`** Linux framebuffer device -- fallback in case X11 is disabled [(gfxlib2/linux/gfx_driver_fbdev.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/linux/gfx_driver_fbdev.c)

  DOS:

  - **`BIOS`** [(gfxlib2/dos/gfx_driver_bios.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/dos/gfx_driver_bios.c)
  **`ModeX`** "tuned" 320x240x8bpp VGA mode [(gfxlib2/dos/gfx_driver_modex.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/dos/gfx_driver_modex.c)
  **`VESA banked`** compatible with very old VESA 1.x implementations [(gfxlib2/dos/gfx_driver_vesa_bnk.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/dos/gfx_driver_vesa_bnk.c)
  **`VESA linear`** needs VESA version at least 2.0, usually faster than banked VESA [(gfxlib2/dos/gfx_driver_vesa_lin.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/dos/gfx_driver_vesa_lin.c)
  **`VGA`** [(gfxlib2/dos/gfx_driver_vga.c)](http://sourceforge.net/p/fbc/code/ci/master/tree/src/gfxlib2/dos/gfx_driver_vga.c)
  Bug note: [Palette](Palette) doesn't work well [(forum discussion: t=12691 2008)](http://freebasic.net/forum/viewtopic.php?t=12691) [(forum discussion: t=19980 2012)](http://freebasic.net/forum/viewtopic.php?t=19980)

[`ScreenControl`](Screencontrol) can be used (SET_DRIVER_NAME 103) to override the default driver preferences.

Platform Differences

- In DOS, GfxLib will create and "manage" a mouse arrow if a mouse driver is detected. There is no "official" way to disable this. Also note that the arrow doesn't react to mouse movements while the screen is locked.
  In DOS, Windowing and OpenGL related commands and switches are not available (they exist but do nothing, or return some values with no meaning)  
  In DOS, the refresh rate setting is not available (some VESA cards do support it, but FreeBASIC for now doesn't)  
  In DOS, the resolution must match one supported by the graphics card. GfxLib will try to find an appropriate mode from VGA modes, ModeX or VESA, preferring VESA LFB interface if available, or banked VESA otherwise. Unsupported resolutions may currently crash the program (if you fail to check SCREENPTR for ZERO before using it), though in future GfxLib may try to find a close match instead. For optimal compatibility, you should support "safe" resolutions like 640x480 and 800x600, and maybe 1024x768. There are various additional modes like 768x576 around, but they are vendor specific and lacking on many other cards. Also modes 1024x768 and above are not available on older cards and laptops.  
  It has been observed that SCREEN and SCREENRES may fail to clear the screen in DOS, actually this is probably a BIOS bug that GfxLib currently doesn't workaround.

Differences from QB

- Graphics support was internally redesigned. QB used VGA graphics modes, and wrote directly into the VGA RAM. Multiple pages were available as long as the card supported them. FB uses backbuffers, one per defined page, and copies them to the video RAM (VGA (DOS), VESA (DOS), DirectX (Win32), ...) in the background. Graphics commands do work as they used to in QB, but a few notable differences are present:

  - The background screen updating eats a considerable amount of CPU performance.
  There is a thread (Win32 and Linux) or ISR (DOS, uses the PIT) active for this.  
  Mixing FB's graphics support with low-level screen accesses (VGA) is not supported, even in DOS. However direct screen memory access is possible using Screenptr and Screenlock and is fully portable. In DOS VGA and VESA are still available, but can't be mixed with FB's graphics support.

See also

- [GFX Functions Index](Graphics-Keyword-List)
- [`Screen (Graphics)`](Screen-Graphics) The QB-like way to set graphics mode
- [`ScreenRes`](Screenres) More flexible alternative to `Screen`
- [`ScreenList`](Screenlist) Check display modes available for FB GfxLib to use
- [`ScreenControl`](Screencontrol) Select driver and more
- [`ScreenLock`](Screenlock)
- [`ScreenUnlock`](Screenunlock)
- [`ScreenPtr`](Screenptr) Semi-low level access
- [`ScreenSet`](Screenset)
- [`ScreenCopy`](Screencopy)
- [`ScreenInfo`](Screeninfo)
- [`ScreenGLProc`](Screenglproc)

---

**Category:** [Graphics Library Reference](Category-Graphics-Library-Reference)

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
