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

import 'package:flauncher/apps_order.dart';
import 'package:flauncher/default_layout.dart';
import 'package:flauncher/models/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("pinned favourites stay first without usage permission", () {
    final List<App> apps = [
      _app("com.other.b", "B"),
      _app(filminPackage, "Filmin"),
      _app(netflixPackage, "Netflix", lastTimeUsed: 50),
      _app("com.other.a", "A"),
      _app(disneyPlusPackage, "Disney+", lastTimeUsed: 999),
      _app("com.google.android.tv", "TV", liveTv: true, lastTimeUsed: 1),
      _app(crunchyrollPackage, "Crunchyroll"),
    ];

    applyPinnedThenRecentOrder(apps, usageAvailable: false);

    expect(apps.map((app) => app.packageName).toList(), [
      "com.google.android.tv",
      crunchyrollPackage,
      netflixPackage,
      disneyPlusPackage,
      filminPackage,
      "com.other.b",
      "com.other.a",
    ]);
  });

  test("recent use orders only the apps after the pinned ones", () {
    final List<App> apps = [
      _app("com.other.old", "Old", lastTimeUsed: 10),
      _app(netflixPackage, "Netflix", lastTimeUsed: 1),
      _app("com.other.new", "New", lastTimeUsed: 100),
      _app(maxPackage, "Max", lastTimeUsed: 5000),
      _app("com.other.mid", "Mid", lastTimeUsed: 40),
      _app(hboNowPackage, "HBO", lastTimeUsed: 5000),
    ];

    applyPinnedThenRecentOrder(apps, usageAvailable: true);

    expect(apps.map((app) => app.packageName).toList(), [
      netflixPackage,
      maxPackage,
      hboNowPackage,
      "com.other.new",
      "com.other.mid",
      "com.other.old",
    ]);
  });

  test("missing favourites are skipped", () {
    final List<App> apps = [
      _app(primeVideoPackage, "Prime"),
      _app("org.example.player", "Player"),
    ];

    applyPinnedThenRecentOrder(apps, usageAvailable: false);

    expect(apps.map((app) => app.packageName).toList(), [
      primeVideoPackage,
      "org.example.player",
    ]);
  });
}

App _app(String packageName, String name, {bool liveTv = false, int lastTimeUsed = 0}) {
  final App app = App(packageName: packageName, name: name, version: "1", hidden: false);
  app.liveTv = liveTv;
  app.lastTimeUsed = lastTimeUsed;
  return app;
}
