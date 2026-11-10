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

import 'package:flutter/material.dart';

/// Emerald Shrine tokens. Faces are the variable fonts bundled under
/// assets/fonts (OFL, from the Google Fonts repository). No runtime fetch.
class EmeraldShrine {
  static const Color background = Color(0xFF0E1111);
  static const Color surface = Color(0xFF171C1C);
  static const Color accent = Color(0xFF2FD08C);
  static const Color secondaryAccent = Color(0xFF6EE7D8);
  static const Color text = Color(0xFFF3F8F6);
  static const Color secondaryText = Color(0xFFB9C8C3);

  static const String outfitFamily = 'Outfit';
  static const String interFamily = 'Inter';

  static const double tileRadius = 13;
  static const double posterRadius = 14;

  static const Color surfaceTint = Color(0xD1171C1C);
  static const Color focusGlow = Color(0x8C2FD08C);

  static const List<BoxShadow> focusShadows = [
    BoxShadow(color: focusGlow, blurRadius: 16, spreadRadius: 1),
  ];

  static TextStyle heading({double fontSize = 22, Color color = text}) =>
      TextStyle(
        fontFamily: outfitFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation.weight(600)],
        color: color,
        height: 1.15,
      );

  static TextStyle posterTitle({double fontSize = 16, Color color = text}) =>
      TextStyle(
        fontFamily: outfitFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation.weight(700)],
        color: color,
        height: 1.15,
      );

  static TextStyle body(
          {double fontSize = 15,
          Color color = text,
          FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: interFamily,
        fontSize: fontSize,
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
        color: color,
        height: 1.35,
      );

  static TextTheme get textTheme {
    final TextTheme base = Typography.material2021().white.apply(
          fontFamily: interFamily,
          bodyColor: text,
          displayColor: text,
        );
    return base.copyWith(
      headlineMedium: heading(fontSize: 40),
      titleLarge: heading(fontSize: 22),
      titleMedium: heading(fontSize: 18),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 15),
      bodySmall: body(fontSize: 13, color: secondaryText),
      labelLarge: body(fontSize: 15),
    );
  }

  static ThemeData theme() {
    final ColorScheme scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: background,
      secondary: secondaryAccent,
      onSecondary: background,
      surface: surface,
      onSurface: text,
      error: const Color(0xFFFF6B6B),
      onError: background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: interFamily,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: surface,
      dialogBackgroundColor: surface,
      dividerColor: secondaryText.withOpacity(0.28),
      splashColor: accent.withOpacity(0.16),
      highlightColor: accent.withOpacity(0.10),
      focusColor: accent.withOpacity(0.20),
      iconTheme: const IconThemeData(color: text),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: accent)),
        labelStyle: body(fontSize: 14, color: secondaryText),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: Color(0x662FD08C),
        selectionHandleColor: accent,
      ),
    );
  }
}

/// Netflix red, Disney+ blue, Crunchyroll orange, Prime blue, HBO Max purple,
/// Filmin near-black. Unknown platforms fall back to the shrine surface.
Color recommendationPlatformColor(String platform) {
  switch (platform.toLowerCase()) {
    case 'netflix':
      return const Color(0xFFE50914);
    case 'disney+':
      return const Color(0xFF113CCF);
    case 'crunchyroll':
      return const Color(0xFFF47521);
    case 'prime video':
      return const Color(0xFF00A8E1);
    case 'hbo max':
      return const Color(0xFF7A3FF2);
    case 'filmin':
      return const Color(0xFF141816);
    default:
      return EmeraldShrine.surface;
  }
}

/// Tiny bundled mark for a platform badge. Null when we have no icon, so the
/// pill stays text-only. These are identifying badges, not modified logos.
String? platformIconAsset(String platform) {
  switch (platform.toLowerCase().trim()) {
    case 'netflix':
      return 'assets/platforms/netflix.png';
    case 'disney+':
    case 'disney plus':
      return 'assets/platforms/disney_plus.png';
    case 'crunchyroll':
      return 'assets/platforms/crunchyroll.png';
    case 'prime video':
    case 'prime':
      return 'assets/platforms/prime_video.png';
    case 'hbo max':
    case 'max':
      return 'assets/platforms/hbo_max.png';
    case 'filmin':
      return 'assets/platforms/filmin.png';
    default:
      return null;
  }
}
