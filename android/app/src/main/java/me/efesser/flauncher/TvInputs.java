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
import android.media.tv.TvContract;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * HDMI ports for the Entradas picker.
 *
 * <p>Passthrough uses the same {@code ACTION_VIEW} pattern as {@link LiveTv},
 * on {@link TvContract#buildChannelUriForPassthroughInput(String)}. On a
 * MediaTek Google TV that view often resolves to nothing, so the system
 * inputs screen is the fallback.
 */
final class TvInputs {
    private TvInputs() { }

    static List<Map<String, String>> list(Context context) {
        List<Map<String, String>> ports = new ArrayList<>();
        TvInputManager manager = (TvInputManager) context.getSystemService(Context.TV_INPUT_SERVICE);
        if (manager == null) {
            return ports;
        }

        List<TvInputInfo> inputs;
        try {
            inputs = manager.getTvInputList();
        } catch (RuntimeException ignored) {
            return ports;
        }
        if (inputs == null) {
            return ports;
        }

        for (TvInputInfo input : inputs) {
            if (input == null || input.getType() != TvInputInfo.TYPE_HDMI || isCecChild(input)) {
                continue;
            }
            Map<String, String> row = new HashMap<>();
            row.put("id", input.getId());
            row.put("label", label(context, input));
            ports.add(row);
        }
        return ports;
    }

    static boolean open(Context context, String inputId) {
        if (inputId != null && !inputId.isEmpty()) {
            Uri uri = TvContract.buildChannelUriForPassthroughInput(inputId);
            Intent view = new Intent(Intent.ACTION_VIEW, uri);
            view.addCategory(Intent.CATEGORY_DEFAULT);
            view.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (startIfResolves(context, view)) {
                return true;
            }
        }

        String[] actions = {
                "com.android.tv.action.VIEW_INPUTS",
                "android.settings.INPUT_SETTINGS",
                Settings.ACTION_SETTINGS
        };
        for (String action : actions) {
            Intent intent = new Intent(action);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (startIfResolves(context, intent)) {
                return true;
            }
        }

        String[][] components = {
                {"com.android.tv.settings", "com.android.tv.settings.system.InputsActivity"},
                {"com.android.tv.settings", "com.android.tv.settings.device.display.input.InputsActivity"}
        };
        for (String[] component : components) {
            Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.setComponent(new ComponentName(component[0], component[1]));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (startIfResolves(context, intent)) {
                return true;
            }
        }
        return false;
    }

    private static boolean isCecChild(TvInputInfo input) {
        // Hardware ports are .../HW5. MediaTek CEC devices are .../HDMI100004.
        String id = input.getId();
        if (id != null && id.contains("/HDMI")) {
            return true;
        }
        // getParentId() is the public signal that this input hangs off another
        // HDMI port. getHdmiDeviceInfo() is @SystemApi and is not in the SDK.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return input.getParentId() != null;
        }
        return false;
    }

    private static String label(Context context, TvInputInfo input) {
        CharSequence custom = null;
        try {
            custom = input.loadCustomLabel(context);
        } catch (RuntimeException ignored) { }
        if (custom != null && custom.length() > 0) {
            return custom.toString();
        }

        CharSequence loaded = null;
        try {
            loaded = input.loadLabel(context);
        } catch (RuntimeException ignored) { }
        if (loaded != null && loaded.length() > 0) {
            return loaded.toString();
        }

        int port = portNumber(input);
        if (port > 0) {
            return "HDMI " + port;
        }
        return "HDMI";
    }

    private static int portNumber(TvInputInfo input) {
        Bundle extras = input.getExtras();
        if (extras != null) {
            int port = extras.getInt("hdmi_port", extras.getInt("port", 0));
            if (port > 0) {
                return port;
            }
        }
        return 0;
    }

    private static boolean startIfResolves(Context context, Intent intent) {
        PackageManager manager = context.getPackageManager();
        if (manager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) == null) {
            return false;
        }
        try {
            context.startActivity(intent);
            return true;
        } catch (RuntimeException ignored) {
            return false;
        }
    }
}
