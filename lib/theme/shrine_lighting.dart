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

import 'package:flutter/services.dart';

/// Day plate shipped with the theme, lossy WebP. Dusk and night plates are
/// optional: drop `emerald_shrine_dusk.webp` or `emerald_shrine_night.webp`
/// next to the day image (a `.jpg` of the same name still works) and they
/// are picked up on the next launch. No code change. No AVIF.
const String shrineDayAsset = 'assets/backgrounds/emerald_shrine_day.webp';
const String shrineDayAssetJpeg = 'assets/backgrounds/emerald_shrine_day.jpg';
const String shrineDuskAsset = 'assets/backgrounds/emerald_shrine_dusk.webp';
const String shrineDuskAssetJpeg = 'assets/backgrounds/emerald_shrine_dusk.jpg';
const String shrineNightAsset = 'assets/backgrounds/emerald_shrine_night.webp';
const String shrineNightAssetJpeg = 'assets/backgrounds/emerald_shrine_night.jpg';

const Duration shrineLightingPollInterval = Duration(minutes: 3);
const Duration shrineLightingFade = Duration(milliseconds: 800);

enum ShrineDayPart { morning, afternoon, dusk, night }

/// Local-time grade over the shrine plate.
///
/// Morning lifts the plate with a neutral veil, afternoon warms it, dusk
/// darkens it toward amber, and night pushes it bluer. The optional dusk
/// and night photographs replace the day plate when they are bundled.
class ShrineLighting {
  static const Color morningTint = Color(0x1AFFFFFF);
  static const Color afternoonTint = Color(0x26E8A85A);
  static const Color duskTint = Color(0x4A3A2418);
  static const Color nightTint = Color(0x662A4060);

  final ShrineDayPart part;
  final Color tint;

  const ShrineLighting(this.part, this.tint);

  static ShrineLighting at(DateTime time) {
    final int hour = time.hour;
    if (hour >= 5 && hour < 11) {
      return const ShrineLighting(ShrineDayPart.morning, morningTint);
    }
    if (hour >= 11 && hour < 17) {
      return const ShrineLighting(ShrineDayPart.afternoon, afternoonTint);
    }
    if (hour >= 17 && hour < 21) {
      return const ShrineLighting(ShrineDayPart.dusk, duskTint);
    }
    return const ShrineLighting(ShrineDayPart.night, nightTint);
  }
}

final Map<String, bool> _bundledAssetCache = {};

/// Whether [asset] is in the binary. Missing optional plates return false
/// instead of throwing, and the answer is cached for the process.
Future<bool> bundledShrineAssetExists(String asset) async {
  final bool? cached = _bundledAssetCache[asset];
  if (cached != null) {
    return cached;
  }
  try {
    await rootBundle.load(asset);
    return _bundledAssetCache[asset] = true;
  } catch (_) {
    return _bundledAssetCache[asset] = false;
  }
}

Future<String> resolveShrineAsset(
  ShrineDayPart part,
  Future<bool> Function(String asset) exists,
) async {
  final List<String> preferred;
  switch (part) {
    case ShrineDayPart.dusk:
      preferred = const [shrineDuskAsset, shrineDuskAssetJpeg];
    case ShrineDayPart.night:
      preferred = const [shrineNightAsset, shrineNightAssetJpeg];
    case ShrineDayPart.morning:
    case ShrineDayPart.afternoon:
      preferred = const [];
  }
  for (final String asset in preferred) {
    if (await exists(asset)) {
      return asset;
    }
  }
  if (await exists(shrineDayAsset)) {
    return shrineDayAsset;
  }
  if (await exists(shrineDayAssetJpeg)) {
    return shrineDayAssetJpeg;
  }
  return shrineDayAsset;
}
