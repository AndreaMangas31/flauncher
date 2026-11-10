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
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.net.Uri;

import java.util.List;

/**
 * Resolves the device's live tuner/antenna player.
 *
 * Preference order:
 * 1. An activity that handles ACTION_VIEW on content://android.media.tv/channel
 *    (AOSP Live TV and Google Live Channels).
 * 2. A known live-TV package's leanback or launcher activity.
 * 3. The package that owns a {@link TvInputInfo#TYPE_TUNER} input, if that
 *    package itself has a launchable activity.
 *
 * Returns null when this device has no live TV activity. Callers hide the tile.
 */
final class LiveTv
{
    /** Must match `liveTvAction` in lib/default_layout.dart. */
    static final String ACTION = "me.efesser.flauncher.action.LIVE_TV";

    private static final Uri CHANNELS_URI = Uri.parse("content://android.media.tv/channel");

    private static final String[] PACKAGES = {
            "com.google.android.tv",
            "com.android.tv",
            "org.droidtv.playtv",
            "com.mediatek.wwtv.tvcenter",
            "com.mediatek.tv.service",
            "com.realtek.tv",
            "com.droidlogic.android.tv",
            "com.droidlogic.tvinput",
            "com.tcl.tv",
            "com.tcl.tvweishi",
            "com.hisense.tv.hitv",
            "com.sony.dtv.tvx",
            "com.sony.dtv.osat.tv",
            "com.amazon.tv.livetv",
            "com.nvidia.shield.livetv",
            "com.sharp.android.tv",
            "com.vestel.tv.launcher",
            "com.changhong.tv",
            "com.haier.tv.tvclient"
    };

    private LiveTv() { }

    static Intent resolve(Context context)
    {
        PackageManager packageManager = context.getPackageManager();

        Intent viewChannels = new Intent(Intent.ACTION_VIEW, CHANNELS_URI);
        viewChannels.addCategory(Intent.CATEGORY_DEFAULT);
        viewChannels.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        Intent resolved = pinComponent(packageManager, viewChannels);
        if (resolved != null) {
            return resolved;
        }

        for (String packageName : PACKAGES) {
            Intent launch = packageManager.getLeanbackLaunchIntentForPackage(packageName);
            if (launch == null) {
                launch = packageManager.getLaunchIntentForPackage(packageName);
            }
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                return launch;
            }

            Intent explicit = explicitActivity(packageManager, packageName);
            if (explicit != null) {
                return explicit;
            }
        }

        return tunerPackageIntent(context, packageManager);
    }

    private static Intent pinComponent(PackageManager packageManager, Intent intent)
    {
        ResolveInfo info = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
        if (info == null || info.activityInfo == null) {
            return null;
        }

        intent.setComponent(new ComponentName(info.activityInfo.packageName, info.activityInfo.name));
        return intent;
    }

    private static Intent explicitActivity(PackageManager packageManager, String packageName)
    {
        String[] classNames = {
                packageName + ".MainActivity",
                packageName + ".TvActivity",
                "com.android.tv.MainActivity"
        };

        for (String className : classNames) {
            ComponentName component = new ComponentName(packageName, className);
            try {
                packageManager.getActivityInfo(component, 0);
            }
            catch (PackageManager.NameNotFoundException ignored) {
                continue;
            }

            Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.setComponent(component);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return intent;
        }

        return null;
    }

    private static Intent tunerPackageIntent(Context context, PackageManager packageManager)
    {
        TvInputManager manager = (TvInputManager) context.getSystemService(Context.TV_INPUT_SERVICE);
        if (manager == null) {
            return null;
        }

        List<TvInputInfo> inputs;
        try {
            inputs = manager.getTvInputList();
        }
        catch (RuntimeException ignored) {
            return null;
        }

        for (TvInputInfo input : inputs) {
            if (input.getType() != TvInputInfo.TYPE_TUNER || input.getServiceInfo() == null) {
                continue;
            }

            String packageName = input.getServiceInfo().packageName;
            Intent launch = packageManager.getLeanbackLaunchIntentForPackage(packageName);
            if (launch == null) {
                launch = packageManager.getLaunchIntentForPackage(packageName);
            }
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                return launch;
            }
        }

        return null;
    }
}
