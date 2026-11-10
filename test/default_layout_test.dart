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

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/default_layout.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("flauncher-layout");
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test("fresh install seeds Apps then YouTube y música", () async {
    final List<Map<String, Object?>> installed = [
      _app("com.netflix.ninja", "Netflix"),
      _app(youtubeTvPackage, "YouTube"),
      _app("com.crunchyroll.crunchyroid", "Crunchyroll"),
      _app(spotifyTvPackage, "Spotify"),
      _app("com.disney.disneyplus", "Disney+"),
    ];
    final database = FLauncherDatabase(DatabaseConnection(NativeDatabase.memory()));
    final service = await _start(database, installed);

    final List<Category> categories = service.launcherSections.whereType<Category>().toList();
    expect(categories.map((category) => category.name).toList(), [appsCategoryName, musicCategoryName]);
    expect(categories[0].sort, CategorySort.pinnedAndRecent);
    expect(
      categories[0].applications.map((app) => app.packageName).toList(),
      [crunchyrollPackage, netflixPackage, disneyPlusPackage],
    );
    expect(categories[0].applications.every((app) => !app.liveTv), isTrue);
    expect(
      categories[1].applications.map((app) => app.packageName).toList(),
      [youtubeTvPackage, spotifyTvPackage],
    );

    await database.close();
  });

  test("existing database is not reseeded", () async {
    final File file = File("${tempDir.path}/db.sqlite");
    final FLauncherDatabase created = FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    await created.customSelect("SELECT 1").get();
    expect(created.wasCreated, isTrue);
    await created.close();

    final FLauncherDatabase existing = FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    final service = await _start(existing, [
      _app("com.netflix.ninja", "Netflix"),
      _app(youtubeTvPackage, "YouTube"),
    ]);

    expect(existing.wasCreated, isFalse);
    expect(service.launcherSections.whereType<Category>(), isEmpty);

    await existing.close();
  });

  test("live TV is pinned first in Apps when the device exposes it", () async {
    final List<Map<String, Object?>> installed = [
      _app("com.netflix.ninja", "Netflix"),
      _app("com.google.android.tv", "Live Channels", liveTv: true),
      _app(youtubeTvPackage, "YouTube"),
      _app("com.filmin.filminapp", "Filmin"),
    ];
    final database = FLauncherDatabase(DatabaseConnection(NativeDatabase.memory()));
    final service = await _start(database, installed);

    final Category apps = service.launcherSections.whereType<Category>().first;
    expect(apps.name, appsCategoryName);
    expect(apps.applications.map((app) => app.packageName).toList(), [
      "com.google.android.tv",
      netflixPackage,
      filminPackage,
    ]);
    expect(apps.applications.first.liveTv, isTrue);
    expect(apps.applications.first.action, liveTvAction);
    expect(apps.applications.map((app) => app.packageName), isNot(contains(youtubeTvPackage)));

    await database.close();
  });

  test("usage stats reorder only the apps after the pinned favourites", () async {
    final List<Map<String, Object?>> installed = [
      _app("com.other.zebra", "Zebra"),
      _app(netflixPackage, "Netflix"),
      _app("com.other.alpha", "Alpha"),
    ];
    final database = FLauncherDatabase(DatabaseConnection(NativeDatabase.memory()));
    final service = await _start(database, installed, usage: {
      "com.other.zebra": 100,
      "com.other.alpha": 1,
      netflixPackage: 9999,
    });

    final Category apps = service.launcherSections.whereType<Category>().first;
    expect(apps.applications.map((app) => app.packageName).toList(), [
      netflixPackage,
      "com.other.zebra",
      "com.other.alpha",
    ]);

    await database.close();
  });
}

Map<String, Object?> _app(String packageName, String name, {bool liveTv = false}) => {
      "packageName": packageName,
      "name": name,
      "version": "1.0.0",
      "sideloaded": false,
      if (liveTv) "liveTv": true,
      if (liveTv) "action": liveTvAction,
    };

void _stubChannel(List<Map<String, Object?>> applications, {Map<String, int>? usage}) {
  const MethodChannel methodChannel = MethodChannel("me.efesser.flauncher/method");
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel,
      (call) async {
    switch (call.method) {
      case "getApplications":
        return applications;
      case "applicationExists":
        return false;
      case "getUsageStats":
        return usage;
      default:
        return null;
    }
  });

  const MethodChannel eventChannel = MethodChannel("me.efesser.flauncher/event_apps");
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(eventChannel,
      (call) async {
    return null;
  });
}

Future<AppsService> _start(
  FLauncherDatabase database,
  List<Map<String, Object?>> applications, {
  Map<String, int>? usage,
}) async {
  _stubChannel(applications, usage: usage);
  final service = AppsService(FLauncherChannel(), database);
  await _waitUntil(() => service.initialized);
  return service;
}

Future<void> _waitUntil(bool Function() condition) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail("AppsService did not finish initialising");
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
