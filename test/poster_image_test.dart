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

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/poster_images.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/recommendations_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(debugResetPosterImages);

  test('a small layout shift keeps the same decode size', () {
    expect(stablePosterPixels(156, 2), 320);
    expect(stablePosterPixels(158, 2), stablePosterPixels(156, 2));
    expect(stablePosterPixels(248, 2), 512);
    expect(stablePosterPixels(250, 2), stablePosterPixels(248, 2));
  });

  test('one url and size is one provider', () async {
    var loads = 0;
    final ImageProvider<Object> image =
        MemoryImage(Uint8List.fromList(kTransparentImage));
    posterImageLoader = (String url, int width, int height) async {
      loads += 1;
      return image;
    };

    final ImageProvider<Object> first =
        await posterProvider('https://example.com/a.jpg', 320, 512);
    final ImageProvider<Object> second =
        await posterProvider('https://example.com/a.jpg', 320, 512);

    expect(identical(first, second), isTrue);
    expect(loads, 1);
  });

  testWidgets('moving focus does not reload the poster image', (tester) async {
    var loads = 0;
    final ImageProvider<Object> image = ResizeImage(
      MemoryImage(Uint8List.fromList(kTransparentImage)),
      width: 320,
      height: 512,
    );
    posterImageLoader = (String url, int width, int height) async {
      loads += 1;
      return image;
    };

    SharedPreferences.setMockInitialValues({
      'recommendations_cache': _feed,
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = MockSettingsService();
    when(settings.showRecommendations).thenReturn(true);
    when(settings.recommendationsFeedUrl).thenReturn('');

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => RecommendationsService(
            prefs,
            settings,
            _Channel(),
            fetcher: (_) async => null,
            periodicRefresh: false,
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(height: 420, child: RecommendationsRow())),
      ),
    ));
    await tester.pump();
    await tester.pump();

    final Finder posters = find.byWidgetPredicate(
      (Widget widget) => widget is Image && identical(widget.image, image),
    );
    expect(posters, findsNWidgets(2));
    expect(tester.widget<Image>(posters.first).gaplessPlayback, isTrue);
    final Element firstImage = tester.element(posters.first);
    final int loaded = loads;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(loads, loaded);
    expect(tester.element(posters.first), same(firstImage));
    expect(find.text('A court romance.'), findsOneWidget);
  });
}

class _Channel extends Fake implements FLauncherChannel {}

const String _feed = '''
{
  "updatedAt": "2026-11-10T12:00:00Z",
  "items": [
    {
      "title": "Black Clover T2",
      "description": "Magic battles.",
      "platform": "Crunchyroll",
      "type": "serie",
      "status": "airing",
      "imageUrl": "https://example.com/a.jpg"
    },
    {
      "title": "La emperatriz",
      "description": "A court romance.",
      "platform": "Disney+",
      "type": "serie",
      "status": "airing",
      "imageUrl": "https://example.com/b.jpg"
    }
  ]
}
''';
