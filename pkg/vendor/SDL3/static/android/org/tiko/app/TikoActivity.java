// TikoActivity -- the Activity of every 'tiko -app' APK (docs/tiko-android A4, D-A4-2).
//
// SDL is linked STATICALLY into the program's libmain.so, so there is no libSDL3.so to load: SDL's
// JNI_OnLoad and its natives come with libmain.so itself. SDLActivity's default list is
// {"SDL3", "main"}, and loading a library that is not in the APK fails the start; this is the
// whole difference. SDL_main, the entry tiko's -app emits, is still found in the last library.
//
// THE SAFE AREA IS WHERE NOTHING COVERS THE APP (docs/fasting-android F5). SDL's surface reports
// the system bars, the display cutout AND the system gesture zones as one inset, and the gesture
// zones are the back-swipe strips down both sides: 30 dp a side on a phone in gesture navigation,
// 60 of 411 dp of width lost, though nothing is drawn there. Android's own rule is that gesture
// insets are for swipeable controls to avoid, not for layout; SDL_GetWindowSafeArea now holds the
// bars and the cutout only. SDL's handler still runs first, for the keyboard's shown/hidden.
package org.tiko.app;

import android.content.Context;
import android.graphics.Insets;
import android.os.Build;
import android.view.View;
import android.view.WindowInsets;
import org.libsdl.app.SDLActivity;
import org.libsdl.app.SDLSurface;

public class TikoActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] { "main" };
    }

    @Override
    protected SDLSurface createSDLSurface(Context context) {
        return new TikoSurface(context);
    }

    static class TikoSurface extends SDLSurface {
        TikoSurface(Context context) {
            super(context);
        }

        @Override
        public WindowInsets onApplyWindowInsets(View v, WindowInsets insets) {
            WindowInsets r = super.onApplyWindowInsets(v, insets);
            if (Build.VERSION.SDK_INT >= 30 /* Android 11 (R) */) {
                Insets s = insets.getInsets(WindowInsets.Type.systemBars() |
                                            WindowInsets.Type.displayCutout());
                SDLActivity.onNativeInsetsChanged(s.left, s.right, s.top, s.bottom);
            }
            return r;
        }
    }
}
