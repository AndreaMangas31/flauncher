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

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Decoded RGBA bytes for a bitmap of [width] by [height].
int decodedRgbaBytes(int width, int height) => width * height * 4;

/// 48 MB is inside the 40–60 MB budget for a 1.8 GB television.
const int imageCacheByteBudget = 48 * 1024 * 1024;

/// Caps the Flutter image cache. A 1920×1080 plate is about 8 MB decoded,
/// so the cap still leaves room for banners and a few posters.
void installImageCacheBudget() {
  final ImageCache cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = 64;
  cache.maximumSizeBytes = imageCacheByteBudget;
}

void clearLauncherImageCache() {
  final ImageCache cache = PaintingBinding.instance.imageCache;
  cache.clear();
  cache.clearLiveImages();
}

/// Android [Activity.onTrimMemory] calls this on the method channel.
void listenForTrimMemory() {
  const MethodChannel('me.efesser.flauncher/method')
      .setMethodCallHandler((MethodCall call) async {
    if (call.method == 'trimMemory') {
      clearLauncherImageCache();
    }
    return null;
  });
}
