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

import 'package:flauncher/dream_feed.dart';
import 'package:flauncher/image_budget.dart';
import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/widgets/senku_dream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs inside the dream isolate. [dreamMain] in `main.dart` is the symbol
/// the engine looks up; this is the body, so the screensaver still does not
/// open the launcher database.
void dreamMain() {
  WidgetsFlutterBinding.ensureInitialized();
  installImageCacheBudget();
  runApp(const SenkuDreamApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    const MethodChannel('me.efesser.flauncher/dream').invokeMethod<void>('firstFrame');
  });
}

class SenkuDreamApp extends StatefulWidget {
  const SenkuDreamApp({super.key});

  @override
  State<SenkuDreamApp> createState() => _SenkuDreamAppState();
}

class _SenkuDreamAppState extends State<SenkuDreamApp> {
  List<Recommendation> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Recommendation> items =
          recommendationsFromCache(prefs.getString(recommendationsCacheKey));
      if (!mounted) {
        return;
      }
      setState(() => _items = items);
    } catch (_) {
      // The clock and the shrine plate still run without the feed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EmeraldShrine.theme(),
      home: SenkuDream(items: _items),
    );
  }
}
