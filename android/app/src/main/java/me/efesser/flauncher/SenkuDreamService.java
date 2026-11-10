/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package me.efesser.flauncher;

import android.service.dreams.DreamService;
import android.util.Log;

import androidx.annotation.Nullable;

import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Daydream / screensaver "Senku · Santuario".
 *
 * <p>Flutter draws it. The shrine lighting, Outfit and Inter faces, and the
 * Senku feed cache already live in Dart, and a second engine does not open
 * the launcher database. A texture view is used instead of a surface view:
 * surface views punch a hole that stays black in a dream window.
 *
 * <p>The dream is not interactive. Any key or touch is handled by
 * {@link DreamService} and dismisses it.
 *
 * <p>Enable with:
 * {@code settings put secure screensaver_components me.efesser.flauncher/me.efesser.flauncher.SenkuDreamService}
 */
public class SenkuDreamService extends DreamService {
    private static final String TAG = "SenkuDream";
    private static final String ENTRYPOINT_LIBRARY = "package:flauncher/dream_main.dart";
    private static final String ENTRYPOINT = "dreamMain";

    @Nullable private FlutterEngine flutterEngine;
    @Nullable private FlutterView flutterView;
    private boolean tornDown;

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(false);
        setFullscreen(true);
        setScreenBright(false);

        try {
            flutterEngine = new FlutterEngine(this);
            GeneratedPluginRegistrant.registerWith(flutterEngine);
            flutterEngine
                .getDartExecutor()
                .executeDartEntrypoint(
                    new DartExecutor.DartEntrypoint(
                        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                        ENTRYPOINT_LIBRARY,
                        ENTRYPOINT));

            flutterView = new FlutterView(this, new FlutterTextureView(this));
            flutterView.attachToFlutterEngine(flutterEngine);
            flutterView.setFocusable(false);
            flutterView.setFocusableInTouchMode(false);
            setContentView(flutterView);
        } catch (Throwable error) {
            Log.e(TAG, "Could not start the shrine dream", error);
            tearDown();
            finish();
        }
    }

    @Override
    public void onDreamingStarted() {
        super.onDreamingStarted();
        if (flutterEngine != null) {
            flutterEngine.getLifecycleChannel().appIsResumed();
        }
    }

    @Override
    public void onDreamingStopped() {
        if (flutterEngine != null) {
            flutterEngine.getLifecycleChannel().appIsPaused();
        }
        super.onDreamingStopped();
    }

    @Override
    public void onDetachedFromWindow() {
        tearDown();
        super.onDetachedFromWindow();
    }

    @Override
    public void onDestroy() {
        tearDown();
        super.onDestroy();
    }

    private void tearDown() {
        if (tornDown) {
            return;
        }
        tornDown = true;
        if (flutterView != null) {
            flutterView.detachFromFlutterEngine();
            flutterView = null;
        }
        if (flutterEngine != null) {
            flutterEngine.getLifecycleChannel().appIsDetached();
            flutterEngine.destroy();
            flutterEngine = null;
        }
    }
}
