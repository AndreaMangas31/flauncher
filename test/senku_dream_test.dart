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
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/widgets/senku_dream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets("a 1080p dream keeps the panel on screen without yellow underlines",
      (tester) async {
    await mockNetworkImagesFor(() async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const String synopsis =
          "Los cazadores se enfrentan en prueba tras prueba mientras Netflix España sigue la temporada completa con un final que no cabe en una sola línea.";
      final DateTime moment = DateTime(2026, 1, 24, 23, 53);
      await tester.pumpWidget(MaterialApp(
        theme: EmeraldShrine.theme(),
        home: SenkuDream(
          animate: false,
          clock: () => moment,
          items: const [
            Recommendation(
              title: "Black Clover T2",
              description: synopsis,
              platform: "Netflix",
              type: "serie",
              status: "airing",
              imageUrl: "https://example.com/a.jpg",
            ),
          ],
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);

      final Size logical =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      final Rect panel = tester.getRect(find.byKey(const Key("dream-panel")));
      final Rect description =
          tester.getRect(find.byKey(const Key("dream-description")));
      expect(panel.left, greaterThanOrEqualTo(logical.width * 0.04));
      expect(panel.right, lessThanOrEqualTo(logical.width * 0.96));
      expect(description.right, lessThanOrEqualTo(panel.right));
      expect(description.left, greaterThanOrEqualTo(panel.left));

      final Text synopsisText =
          tester.widget(find.byKey(const Key("dream-description")));
      expect(synopsisText.maxLines, 3);
      expect(synopsisText.overflow, TextOverflow.ellipsis);

      for (final String sample in ["23:53", "Netflix", synopsis]) {
        final RenderParagraph paragraph = tester.renderObject(find.text(sample));
        final TextSpan span = paragraph.text as TextSpan;
        expect(span.style?.decoration, isNot(TextDecoration.underline));
        expect(span.style?.decoration, anyOf(isNull, TextDecoration.none));
      }
      final RenderParagraph clock = tester.renderObject(find.text("23:53"));
      expect((clock.text as TextSpan).style?.fontFamily, EmeraldShrine.outfitFamily);
    });
  });
}
