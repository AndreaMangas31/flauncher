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

import 'package:flauncher/flauncher.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'mocks.dart';
import 'mocks.mocks.dart';

/// Logical size of a 1920×1080 panel at device pixel ratio 2.
const Size _tv = Size(960, 540);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const MethodChannel methodChannel =
        MethodChannel('me.efesser.flauncher/method');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'getActiveNetworkInformation') {
        return <String, Object>{'networkType': 4, 'internetAccess': false};
      }
      return null;
    });
    const MethodChannel networkEvents =
        MethodChannel('me.efesser.flauncher/event_network');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(networkEvents, (call) async => null);
  });

  testWidgets('seven app banners and the detail strip fit a 960x540 screen',
      (tester) async {
    await mockNetworkImagesFor(() async {
      tester.view.physicalSize = _tv;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<String> packages = [
        'com.google.android.tv',
        'com.crunchyroll.crunchyroid',
        'com.netflix.ninja',
        'com.disney.disneyplus',
        'com.amazon.amazonvideo.livingroom',
        'com.wbd.stream',
        'com.filmin.androidtv',
      ];
      final apps = MockAppsService();
      when(apps.initialized).thenReturn(true);
      when(apps.getAppBanner(any))
          .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
      when(apps.getAppIcon(any))
          .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
      final Category appsCategory =
          fakeCategory(name: 'Apps', order: 0, type: CategoryType.row);
      final Category music = fakeCategory(
          name: 'YouTube y música', order: 1, type: CategoryType.row);
      when(apps.launcherSections).thenReturn([
        withApps(appsCategory, [
          for (final String package in packages)
            fakeApp(name: package, packageName: package),
        ]),
        withApps(music, [
          fakeApp(name: 'YouTube', packageName: 'com.google.android.youtube.tv'),
        ]),
      ]);

      SharedPreferences.setMockInitialValues({
        'recommendations_cache': _feed,
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = MockSettingsService();
      when(settings.dateFormat).thenReturn(SettingsService.defaultDateFormat);
      when(settings.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
      when(settings.appHighlightAnimationEnabled).thenReturn(false);
      when(settings.appKeyClickEnabled).thenReturn(false);
      when(settings.autoHideAppBarEnabled).thenReturn(false);
      when(settings.showCategoryTitles).thenReturn(true);
      when(settings.showDateInStatusBar).thenReturn(true);
      when(settings.showTimeInStatusBar).thenReturn(true);
      when(settings.showRecommendations).thenReturn(true);
      when(settings.recommendationsFeedUrl).thenReturn('https://example.com/feed.json');

      final wallpaper = MockWallpaperService();
      when(wallpaper.gradient).thenReturn(FLauncherGradients.greatWhale);
      when(wallpaper.wallpaper).thenReturn(null);
      when(wallpaper.ready).thenReturn(true);
      when(wallpaper.hasCustomGradient).thenReturn(false);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperService>.value(value: wallpaper),
          ChangeNotifierProvider<AppsService>.value(value: apps),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider(create: (_) => LauncherState()),
          ChangeNotifierProvider(
              create: (_) => NetworkService(FLauncherChannel())),
          ChangeNotifierProvider(
            create: (_) => RecommendationsService(
              prefs,
              settings,
              FLauncherChannel(),
              fetcher: (_) async => _feed,
              periodicRefresh: false,
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: FLauncher(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final Size view = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final String package in packages) {
        final Finder tile = find.byKey(Key(package));
        expect(tile, findsOneWidget, reason: package);
        final Rect rect = tester.getRect(tile);
        expect(rect.right, lessThanOrEqualTo(view.width + 1), reason: package);
        expect(rect.bottom, lessThanOrEqualTo(view.height + 1), reason: package);
      }
      expect(find.byKey(const Key('more-apps')), findsNothing);

      final Rect posters =
          tester.getRect(find.byKey(const Key('recommendation-posters')));
      final Rect detail =
          tester.getRect(find.byKey(const Key('recommendation-detail')));
      expect(posters.bottom, lessThanOrEqualTo(view.height + 1));
      expect(detail.bottom, lessThanOrEqualTo(view.height + 1));
      expect(detail.top, greaterThanOrEqualTo(posters.top));
      expect(find.text('Black Clover T2'), findsWidgets);
    });
  });
}

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
    }
  ]
}
''';
