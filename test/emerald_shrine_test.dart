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
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/theme/shrine_lighting.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/app_row_fit.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/emerald_backdrop.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/recommendations_row.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1280, 720);
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  group("shrine lighting", () {
    test("morning, afternoon, dusk and night follow local hour", () {
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 4)).part,
          ShrineDayPart.night);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 5)).part,
          ShrineDayPart.morning);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 10)).part,
          ShrineDayPart.morning);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 11)).part,
          ShrineDayPart.afternoon);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 16)).part,
          ShrineDayPart.afternoon);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 17)).part,
          ShrineDayPart.dusk);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 20)).part,
          ShrineDayPart.dusk);
      expect(ShrineLighting.at(DateTime(2026, 11, 10, 21)).part,
          ShrineDayPart.night);
    });

    test("tints stay distinct: morning neutral, afternoon warm, night blue",
        () {
      expect(ShrineLighting.morningTint, const Color(0x1AFFFFFF));
      expect(ShrineLighting.afternoonTint, isNot(ShrineLighting.morningTint));
      expect(ShrineLighting.nightTint, isNot(ShrineLighting.duskTint));
      expect(
          (ShrineLighting.afternoonTint.red / 255) >
              (ShrineLighting.afternoonTint.blue / 255),
          isTrue);
      expect(
          (ShrineLighting.nightTint.blue / 255) >
              (ShrineLighting.nightTint.red / 255),
          isTrue);
    });

    test("optional dusk and night plates replace the day plate when present",
        () async {
      Future<bool> exists(String asset) async => asset == shrineNightAsset;

      expect(await resolveShrineAsset(ShrineDayPart.morning, exists),
          shrineDayAsset);
      expect(await resolveShrineAsset(ShrineDayPart.afternoon, exists),
          shrineDayAsset);
      expect(
          await resolveShrineAsset(ShrineDayPart.dusk, exists), shrineDayAsset);
      expect(await resolveShrineAsset(ShrineDayPart.night, exists),
          shrineNightAsset);

      Future<bool> both(String asset) async =>
          asset == shrineDuskAsset || asset == shrineNightAsset;
      expect(
          await resolveShrineAsset(ShrineDayPart.dusk, both), shrineDuskAsset);
    });
  });

  test("status date reads like Sáb, 25 de enero", () {
    // 24 January 2026 is a Saturday. The 25th in the mock is the shape, not this year.
    expect(formatShrineDate(DateTime(2026, 1, 24)), "Sáb, 24 de enero");
    expect(formatShrineDate(DateTime(2026, 11, 10)), "Mar, 10 de noviembre");
  });

  test(
      "a row keeps every app when they fit, and reserves a slot when they do not",
      () {
    expect(visibleAppCount(maxWidth: 1200, rowHeight: 110, total: 2), 2);
    expect(visibleAppCount(maxWidth: 400, rowHeight: 110, total: 8), 1);
    expect(visibleAppCount(maxWidth: double.infinity, rowHeight: 110, total: 8),
        8);

    final double height = rowHeightForSlots(928, slots: 9);
    expect(visibleAppCount(maxWidth: 928, rowHeight: height, total: 8), 8);
    expect(
        visibleAppCount(maxWidth: 928, rowHeight: height, total: 12),
        greaterThanOrEqualTo(7));
  });

  test("platform chips use the brief's colours", () {
    expect(recommendationPlatformColor("Netflix"), const Color(0xFFE50914));
    expect(recommendationPlatformColor("Disney+"), const Color(0xFF113CCF));
    expect(recommendationPlatformColor("Crunchyroll"), const Color(0xFFF47521));
    expect(recommendationPlatformColor("Prime Video"), const Color(0xFF00A8E1));
    expect(recommendationPlatformColor("HBO Max"), const Color(0xFF7A3FF2));
    expect(recommendationPlatformColor("Filmin").computeLuminance(),
        lessThan(0.2));
  });

  testWidgets("the shrine plate is the default background", (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EmeraldBackdrop(poll: false, clock: _fixedMorning),
    ));
    await tester.pump();

    final Image plate = tester.widget<Image>(find.byType(Image));
    final ImageProvider provider = plate.image is ResizeImage
        ? (plate.image as ResizeImage).imageProvider
        : plate.image;
    expect(provider, isA<AssetImage>());
    expect((provider as AssetImage).assetName, shrineDayAsset);
    expect(tester.widget<ShrineTintVeil>(find.byType(ShrineTintVeil)).tint,
        ShrineLighting.morningTint);
  });

  testWidgets("a user wallpaper replaces the shrine plate", (tester) async {
    final ImageProvider photo =
        MemoryImage(Uint8List.fromList(kTransparentImage));
    await tester.pumpWidget(MaterialApp(
      home: EmeraldBackdrop(userWallpaper: photo, poll: false),
    ));
    await tester.pump();

    final Image plate =
        tester.widget<Image>(find.byKey(const Key("background")));
    expect(plate.image, same(photo));
    expect(find.byType(ShrineTintVeil), findsNothing);
  });

  testWidgets("the veil animates when the part of day changes", (tester) async {
    DateTime now = DateTime(2026, 11, 10, 9);
    await tester.pumpWidget(MaterialApp(
      home: EmeraldBackdrop(poll: false, clock: () => now),
    ));
    await tester.pump();
    expect(tester.widget<ShrineTintVeil>(find.byType(ShrineTintVeil)).tint,
        ShrineLighting.morningTint);

    now = DateTime(2026, 11, 10, 22);
    await tester.pumpWidget(MaterialApp(
      home: EmeraldBackdrop(poll: false, clock: () => now),
    ));
    await tester.pump();
    expect(tester.widget<ShrineTintVeil>(find.byType(ShrineTintVeil)).tint,
        ShrineLighting.nightTint);
    await tester.pump(shrineLightingFade);
  });

  testWidgets("Ajustes opens settings and the date is Spanish", (tester) async {
    final settings = MockSettingsService();
    when(settings.showDateInStatusBar).thenReturn(true);
    when(settings.showTimeInStatusBar).thenReturn(true);
    when(settings.timeFormat).thenReturn("H:mm");
    when(settings.autoHideAppBarEnabled).thenReturn(false);
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    when(settings.appKeyClickEnabled).thenReturn(false);
    when(settings.showCategoryTitles).thenReturn(true);
    when(settings.showRecommendations).thenReturn(false);
    when(settings.recommendationsFeedUrl).thenReturn("");

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider(
            create: (_) => NetworkService(FLauncherChannel())),
      ],
      child: MaterialApp(
        locale: const Locale("es"),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home:
            Scaffold(appBar: FocusAwareAppBar(), body: const SizedBox.expand()),
      ),
    ));
    await tester.pump();

    expect(find.text(formatShrineDate(DateTime.now())), findsOneWidget);
    expect(find.text("Ajustes"), findsOneWidget);

    await tester.tap(find.byKey(const Key("settings-button")));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPanelPage), findsOneWidget);
  });

  testWidgets("focusing a poster updates the detail strip", (tester) async {
    await mockNetworkImagesFor(() async {
      SharedPreferences.setMockInitialValues({
        recommendationsCacheKey: _feed,
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = MockSettingsService();
      when(settings.showRecommendations).thenReturn(true);
      when(settings.recommendationsFeedUrl)
          .thenReturn("https://example.com/feed.json");

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider(
            create: (_) => RecommendationsService(
              prefs,
              settings,
              nullChannel(),
              fetcher: (_) async => _feed,
              periodicRefresh: false,
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale("es"),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RecommendationsRow()),
        ),
      ));
      await tester.pump();

      expect(find.text("Magic battles."), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.text("A court romance."), findsOneWidget);
      expect(find.text("Crunchyroll"), findsWidgets);
      expect(find.text("Disney+"), findsWidgets);
    });
  });

  testWidgets("a focused app tile wears the accent border", (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    final apps = MockAppsService();
    when(apps.getAppBanner(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    when(apps.getAppIcon(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    final settings = MockSettingsService();
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    final category = fakeCategory(name: "Apps", type: CategoryType.row);
    final app = fakeApp(name: "Netflix", packageName: "com.netflix.ninja");

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: AppCard(
                application: app,
                category: category,
                autofocus: true,
                onMove: (_) {},
                onMoveEnd: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key("emerald-focus-border")), findsOneWidget);
    final DecoratedBox border = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key("emerald-focus-border")),
        matching: find.byType(DecoratedBox),
      ),
    );
    final BoxDecoration decoration = border.decoration as BoxDecoration;
    expect(decoration.border, isA<Border>());
    expect((decoration.border! as Border).top.color, EmeraldShrine.accent);
  });

  testWidgets("apps that do not fit open from Más apps", (tester) async {
    final apps = MockAppsService();
    when(apps.getAppBanner(any)).thenAnswer((_) async => Uint8List(0));
    when(apps.getAppIcon(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    final settings = MockSettingsService();
    when(settings.showCategoryTitles).thenReturn(true);
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    final category = fakeCategory(
        name: "Apps",
        type: CategoryType.row,
        sort: CategorySort.pinnedAndRecent);
    final List<App> applications = [
      for (int i = 0; i < 6; i++)
        fakeApp(name: "App $i", packageName: "app.$i"),
    ];

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
      ],
      child: MaterialApp(
        locale: const Locale("es"),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: CategoryRow(category: category, applications: applications),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text("Más apps"), findsOneWidget);
    expect(find.text("recientes"), findsOneWidget);
    expect(find.text("App 5"), findsNothing);

    await tester.tap(find.text("Más apps"));
    await tester.pumpAndSettle();

    expect(find.text("App 5"), findsOneWidget);
  });
}

DateTime _fixedMorning() => DateTime(2026, 11, 10, 8);

/// RecommendationsService requires a channel, but this test never opens a title.
FLauncherChannelShim nullChannel() => FLauncherChannelShim();

class FLauncherChannelShim extends Fake implements FLauncherChannel {
  @override
  Future<bool> openRecommendation(
          String? deepLink, String? packageName) async =>
      false;
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
    },
    {
      "title": "La emperatriz divorciada",
      "description": "A court romance.",
      "platform": "Disney+",
      "type": "serie",
      "status": "airing",
      "imageUrl": "https://example.com/b.jpg"
    }
  ]
}
''';
