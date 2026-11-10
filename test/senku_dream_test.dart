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
import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/widgets/senku_dream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1280, 720);
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  test("cache reader keeps a usable feed and ignores a broken one", () {
    const String raw = '''
{"updatedAt":"2026-11-10T21:00:00Z","items":[
  {"title":"Black Clover T2","description":"Magic battles.","platform":"Crunchyroll","type":"serie","status":"airing","imageUrl":"https://example.com/a.jpg"}
]}''';
    final items = recommendationsFromCache(raw);
    expect(items.single.title, "Black Clover T2");
    expect(recommendationsFromCache(null), isEmpty);
    expect(recommendationsFromCache("not json"), isEmpty);
  });

  test("clock drift and poster zoom stay small", () {
    expect(dreamDriftOffset(0.5), Offset.zero);
    expect(dreamDriftOffset(0).dx, lessThan(0));
    expect(dreamDriftOffset(1).dx, greaterThan(0));
    expect(dreamDriftOffset(1).dx.abs(), lessThan(48));
    expect(dreamPosterScale(0), 1);
    expect(dreamPosterScale(1), closeTo(1.06, 0.001));
    expect(dreamPosterShift(0.5), Offset.zero);
  });

  testWidgets("shows the shrine clock and the cached recommendation",
      (tester) async {
    await mockNetworkImagesFor(() async {
      final DateTime moment = DateTime(2026, 1, 24, 21, 47);
      await tester.pumpWidget(MaterialApp(
        home: SenkuDream(
          animate: false,
          clock: () => moment,
          items: const [
            Recommendation(
              title: "Black Clover T2",
              description: "Magic battles.",
              platform: "Crunchyroll",
              type: "serie",
              status: "airing",
              imageUrl: "https://example.com/a.jpg",
            ),
          ],
        ),
      ));
      await tester.pump();

      expect(find.text("21:47"), findsOneWidget);
      expect(find.text(formatShrineDate(moment)), findsOneWidget);
      expect(find.text("Black Clover T2"), findsOneWidget);
      expect(find.text("Crunchyroll"), findsOneWidget);
      expect(find.text("Magic battles."), findsOneWidget);
    });
  });

  testWidgets("an empty cache still shows the clock", (tester) async {
    final DateTime moment = DateTime(2026, 11, 10, 8, 5);
    await tester.pumpWidget(MaterialApp(
      home: SenkuDream(
        animate: false,
        clock: () => moment,
      ),
    ));
    await tester.pump();

    expect(find.text("8:05"), findsOneWidget);
    expect(find.text(formatShrineDate(moment)), findsOneWidget);
    expect(find.byKey(const Key("dream-title")), findsNothing);
  });

  testWidgets("recommendations crossfade to the next item", (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(MaterialApp(
        home: SenkuDream(
          clock: () => DateTime(2026, 1, 24, 21, 47),
          slideDuration: const Duration(milliseconds: 200),
          driftPeriod: const Duration(seconds: 2),
          items: const [
            Recommendation(
              title: "Black Clover T2",
              description: "Magic battles.",
              platform: "Crunchyroll",
              type: "serie",
              status: "airing",
              imageUrl: "https://example.com/a.jpg",
            ),
            Recommendation(
              title: "La emperatriz divorciada",
              description: "A court romance.",
              platform: "Disney+",
              type: "serie",
              status: "airing",
              imageUrl: "https://example.com/b.jpg",
            ),
          ],
        ),
      ));
      await tester.pump();
      expect(find.text("Black Clover T2"), findsWidgets);

      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text("La emperatriz divorciada"), findsWidgets);
      expect(find.text("A court romance."), findsWidgets);
      expect(find.text("Disney+"), findsWidgets);
    });
  });
}
