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

import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Handler;
import android.os.Looper;
import android.service.dreams.DreamService;
import android.util.Log;

import androidx.annotation.Nullable;

import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Daydream / screensaver "Senku · Santuario".
 *
 * <p>Order when the screen turns on:
 * <ol>
 *   <li>A new {@link FlutterEngine} running {@code dreamMain} in
 *       {@code package:flauncher/main.dart}.</li>
 *   <li>If that isolate never draws a frame, a native shrine plate and clock.</li>
 *   <li>If that view cannot be attached, try an exported Backdrop activity.
 *       The Backdrop dream itself is not startable by a normal app.</li>
 * </ol>
 *
 * <p>Enable with:
 * {@code settings put secure screensaver_components me.efesser.flauncher/me.efesser.flauncher.SenkuDreamService}
 *
 * <p>A successful Flutter frame logs
 * {@code Senku dream rendered its first frame} on tag {@code SenkuDream}.
 */
public class SenkuDreamService extends DreamService implements SenkuNativeDream.DreamContent {
    static final String TAG = "SenkuDream";
    private static final String ENTRYPOINT_LIBRARY = "package:flauncher/main.dart";
    private static final String ENTRYPOINT = "dreamMain";
    private static final String DREAM_CHANNEL = "me.efesser.flauncher/dream";
    private static final long FIRST_FRAME_TIMEOUT_MS = 5000;

    /** Documented component of Google's photo screensaver. It is a dream, not an activity. */
    private static final String BACKDROP_PACKAGE = "com.google.android.backdrop";

    @Nullable private FlutterEngine flutterEngine;
    @Nullable private FlutterView flutterView;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean flutterFrameShown;
    private boolean nativeShown;
    private boolean finishedCleanly;
    private final Runnable firstFrameTimeout = this::onFirstFrameTimeout;

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(false);
        setFullscreen(true);
        setScreenBright(false);
    }

    @Override
    public void onDreamingStarted() {
        super.onDreamingStarted();
        startEngine();
    }

    @Override
    public void onDreamingStopped() {
        tearDown();
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

    @Override
    public void setDreamContent(android.view.View view) {
        setContentView(view);
    }

    private void startEngine() {
        if (flutterEngine != null || nativeShown || finishedCleanly) {
            return;
        }
        try {
            // automaticallyRegisterPlugins is false. The one-argument
            // constructor registers plugins itself, and a second
            // GeneratedPluginRegistrant call logs "already registered".
            flutterEngine = new FlutterEngine(this, /* dartVmArgs */ null, /* automaticallyRegisterPlugins */ false);
            GeneratedPluginRegistrant.registerWith(flutterEngine);
            new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DREAM_CHANNEL)
                    .setMethodCallHandler((call, result) -> {
                        if ("firstFrame".equals(call.method)) {
                            onFirstFrame();
                            result.success(null);
                        } else {
                            result.notImplemented();
                        }
                    });
            flutterEngine.getDartExecutor().executeDartEntrypoint(
                    new DartExecutor.DartEntrypoint(
                            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                            ENTRYPOINT_LIBRARY,
                            ENTRYPOINT));

            flutterView = new FlutterView(this, new FlutterTextureView(this));
            flutterView.attachToFlutterEngine(flutterEngine);
            flutterView.setFocusable(false);
            flutterView.setFocusableInTouchMode(false);
            setContentView(flutterView);
            flutterEngine.getLifecycleChannel().appIsResumed();
            handler.postDelayed(firstFrameTimeout, FIRST_FRAME_TIMEOUT_MS);
        } catch (Throwable error) {
            Log.e(TAG, "Senku dream Flutter failed to start", error);
            showNativeOrFinish();
        }
    }

    private void onFirstFrame() {
        if (flutterFrameShown || nativeShown) {
            return;
        }
        flutterFrameShown = true;
        handler.removeCallbacks(firstFrameTimeout);
        // Grep this after install. The ADB script treats its absence as failure.
        Log.i(TAG, "Senku dream rendered its first frame");
    }

    private void onFirstFrameTimeout() {
        if (flutterFrameShown || nativeShown || finishedCleanly) {
            return;
        }
        Log.e(TAG, "Senku dream Flutter produced no frame");
        showNativeOrFinish();
    }

    private void showNativeOrFinish() {
        destroyEngine();
        if (nativeShown || finishedCleanly) {
            return;
        }
        if (SenkuNativeDream.show(this, this)) {
            nativeShown = true;
            Log.i(TAG, "Senku dream showing native shrine");
            return;
        }
        Log.e(TAG, "Senku dream native fallback failed");
        handOffToBackdropOrFinish();
    }

    /**
     * Backdrop's screensaver is a {@code DreamService}. The system is the only
     * caller allowed to bind one
     * ({@code android.permission.BIND_DREAM_SERVICE}, signature|privileged;
     * see DreamService and Manifest.permission). Writing
     * {@code Settings.Secure.SCREENSAVER_COMPONENTS} needs
     * {@code WRITE_SECURE_SETTINGS}, which a normal app does not have.
     * The only public attempt left is an exported activity in that package.
     * Google TV does not document one; if none resolves, the dream ends.
     */
    private void handOffToBackdropOrFinish() {
        Intent main = new Intent(Intent.ACTION_MAIN);
        main.setPackage(BACKDROP_PACKAGE);
        main.addCategory(Intent.CATEGORY_DEFAULT);
        ResolveInfo info = getPackageManager().resolveActivity(main, PackageManager.MATCH_DEFAULT_ONLY);
        if (info != null && info.activityInfo != null && info.activityInfo.exported) {
            Intent launch = new Intent(Intent.ACTION_MAIN);
            launch.setComponent(new ComponentName(
                    info.activityInfo.packageName, info.activityInfo.name));
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            try {
                startActivity(launch);
                Log.i(TAG, "Senku dream handed off to Backdrop activity " + info.activityInfo.name);
                finishDream();
                return;
            } catch (RuntimeException error) {
                Log.w(TAG, "Backdrop activity did not start", error);
            }
        } else {
            Log.w(TAG, "Backdrop dream is not startable without WRITE_SECURE_SETTINGS");
        }
        finishDream();
    }

    private void finishDream() {
        if (finishedCleanly) {
            return;
        }
        finishedCleanly = true;
        Log.i(TAG, "Senku dream finishing");
        tearDown();
        finish();
    }

    private void tearDown() {
        handler.removeCallbacks(firstFrameTimeout);
        destroyEngine();
    }

    private void destroyEngine() {
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
