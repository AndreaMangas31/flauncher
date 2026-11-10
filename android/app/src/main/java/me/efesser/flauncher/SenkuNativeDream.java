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

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextClock;
import android.widget.TextView;

import java.io.InputStream;
import java.util.Calendar;

import io.flutter.FlutterInjector;

/**
 * Clock and shrine plate drawn with Android widgets. Used when the Flutter
 * dream isolate does not produce a frame.
 */
final class SenkuNativeDream {
    private static final int BACKGROUND = 0xFF0E1111;
    private static final int TEXT = 0xFFF3F8F6;
    private static final int SECONDARY = 0xFFB9C8C3;
    private static final String PLATE = "assets/backgrounds/emerald_shrine_day.webp";

    private static final String[] WEEKDAYS = {
            "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"
    };
    private static final String[] MONTHS = {
            "enero", "febrero", "marzo", "abril", "mayo", "junio",
            "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    };

    private SenkuNativeDream() { }

    /** False only when no view at all could be attached. A missing photo still shows the clock. */
    static boolean show(Context context, DreamContent host) {
        try {
            FrameLayout root = new FrameLayout(context);
            root.setBackgroundColor(BACKGROUND);

            Bitmap plate = loadPlate(context);
            if (plate != null) {
                ImageView photo = new ImageView(context);
                photo.setImageBitmap(plate);
                photo.setScaleType(ImageView.ScaleType.CENTER_CROP);
                root.addView(photo, new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT));
            }

            LinearLayout column = new LinearLayout(context);
            column.setOrientation(LinearLayout.VERTICAL);
            column.setGravity(Gravity.CENTER_HORIZONTAL);

            TextClock clock = new TextClock(context);
            clock.setFormat12Hour("H:mm");
            clock.setFormat24Hour("H:mm");
            clock.setTextColor(TEXT);
            clock.setTextSize(72);
            column.addView(clock);

            TextView date = new TextView(context);
            date.setText(spanishDate());
            date.setTextColor(SECONDARY);
            date.setTextSize(22);
            date.setGravity(Gravity.CENTER_HORIZONTAL);
            column.addView(date);

            FrameLayout.LayoutParams columnParams = new FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER);
            root.addView(column, columnParams);
            host.setDreamContent(root);
            return true;
        } catch (RuntimeException error) {
            return false;
        }
    }

    private static Bitmap loadPlate(Context context) {
        try {
            String key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(PLATE);
            InputStream input = context.getAssets().open(key);
            try {
                return BitmapFactory.decodeStream(input);
            } finally {
                input.close();
            }
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String spanishDate() {
        Calendar calendar = Calendar.getInstance();
        int weekday = calendar.get(Calendar.DAY_OF_WEEK);
        // Calendar.SUNDAY is 1. shrine weekdays start on Monday.
        int index = (weekday + 5) % 7;
        int month = calendar.get(Calendar.MONTH);
        int day = calendar.get(Calendar.DAY_OF_MONTH);
        return WEEKDAYS[index] + ", " + day + " de " + MONTHS[month];
    }

    interface DreamContent {
        void setDreamContent(android.view.View view);
    }
}
