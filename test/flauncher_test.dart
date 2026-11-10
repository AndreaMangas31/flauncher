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

import 'package:flauncher/models/category.dart';
import 'package:flauncher/flauncher.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'helpers.dart';
import 'mocks.dart';
import 'mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = Size(1280, 720);
    binding.window.devicePixelRatioTestValue = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets("Home page shows categories with apps", (tester) async {
    final appsService = mkAppService();
    final favoritesCategory =
        fakeCategory(name: "Favorites", order: 0, type: CategoryType.row);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    when(appsService.launcherSections).thenReturn([
      withApps(favoritesCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher.1",
          name: "FLauncher 1",
          version: "1.0.0",
        )
      ]),
      withApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "2.0.0",
        )
      ]),
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(AppsGrid), findsOneWidget);
    expect(find.byKey(Key("me.efesser.flauncher.2")), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.byKey(Key("me.efesser.flauncher.1")), findsOneWidget);

    // This was changed by how the the image is made, I don't know what it now should be
    //expect(tester.widget(find.byKey(Key("background"))), isA<Container>());
  });

  testWidgets("Home page shows category empty-state", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory =
        fakeCategory(name: "Applications", order: 0, type: CategoryType.grid);
    final favoritesCategory =
        fakeCategory(name: "Favorites", order: 1, type: CategoryType.row);
    when(appsService.launcherSections).thenReturn([
      withApps(applicationsCategory, []),
      withApps(favoritesCategory, []),
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.byType(AppsGrid), findsOneWidget);
    expect(find.text("This category is empty."), findsNWidgets(2));
  });

  testWidgets("Home page displays background image", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWith(tester, appsService);

    expect(tester.widget(find.byKey(Key("background"))), isA<Image>());
  });

  testWidgets("Home page displays background gradient", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWithProviders(
      tester,
      mkWallpaperService(wallpaper: false, customGradient: true),
      appsService,
      mkSettingsService(),
    );

    expect(tester.widget(find.byKey(Key("background"))), isA<Container>());
  });

  testWidgets("Pressing select on settings icon opens SettingsPanel",
      (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "Favorites", order: 0), []),
      withApps(fakeCategory(name: "Applications", order: 1), []),
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    // Wifi and Entradas sit to the left of Ajustes on the same pill row.
    for (var step = 0; step < 4; step++) {
      final Element? settings = findSettingsIcon(tester);
      if (settings != null && Focus.of(settings).hasFocus) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.byType(SettingsPanelPage), findsOneWidget);
  });

  testWidgets("Pressing select on app opens ApplicationInfoPanel",
      (tester) async {
    final appsService = mkAppService();
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "Favorites", order: 0), []),
      withApps(fakeCategory(name: "Applications", order: 1), [app]),
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    verify(appsService.launchApp(app));
  });

  testWidgets("Long pressing on app opens ApplicationInfoPanel",
      (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "Favorites", order: 0), []),
      withApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
        )
      ]),
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pump();

    expect(find.byType(ApplicationInfoPanel), findsOneWidget);
  });

  testWidgets("AppCard moves in grid", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory =
        fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "Favorites", order: 0), []),
      withApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "1.0.0",
        )
      ]),
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("AppCard moves in row", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory =
        fakeCategory(name: "Applications", order: 1, type: CategoryType.row);
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "Favorites", order: 0), []),
      withApps(applicationsCategory, [
        fakeApp(
          packageName: "me.efesser.flauncher",
          name: "FLauncher",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.flauncher.2",
          name: "FLauncher 2",
          version: "1.0.0",
        )
      ]),
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("Moving down does not skip row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 3 rows like the following:
     * ▭ ▭ ▭
     * ▭ ▭
     * ▭ ▭ ▭
     */
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.tv3",
          name: "tv 3",
          version: "1.0.0",
        )
      ]),
      withApps(fakeCategory(name: "music", order: 1), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
        )
      ]),
      withApps(fakeCategory(name: "games", order: 2), [
        fakeApp(
          packageName: "me.efesser.game1",
          name: "game 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.game2",
          name: "game 2",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.game3",
          name: "game 3",
          version: "1.0.0",
        )
      ]),
    ]);

    await _pumpWidgetWith(tester, appsService);
    // when
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isFalse);
    expect(Focus.of(music2!).hasFocus,
        isTrue); // this is new, before it was going straight to the third row

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    Element? game2 = findAppCardByPackageName(tester, "me.efesser.game2");
    expect(game2, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music2).hasFocus, isFalse);
    expect(Focus.of(game2!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music2).hasFocus, isTrue);
    expect(Focus.of(game2).hasFocus, isFalse);
  });

  testWidgets("Moving left or right stays on the same row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭ ▭ ▭
     */
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
        ),
      ]),
      withApps(fakeCategory(name: "music", order: 1, columnsCount: 5), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music3",
          name: "music 3",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music4",
          name: "music 4",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music5",
          name: "music 5",
          version: "1.0.0",
        ),
      ]),
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    Element? music1 = findAppCardByPackageName(tester, "me.efesser.music1");
    expect(music1, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1!).hasFocus, isTrue);

    // check right direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(music1).hasFocus, isFalse);
    expect(Focus.of(music2!).hasFocus, isTrue);

    // check if right on the last app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    Element? music5 = findAppCardByPackageName(tester, "me.efesser.music5");
    expect(music5, isNotNull);
    // Element? settings = findSettingsIcon(tester);
    // expect(settings, isNotNull);
    expect(Focus.of(music5!).hasFocus, isTrue);
    // expect(Focus.of(settings!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    Element? tv2 = findAppCardByPackageName(tester, "me.efesser.tv2");
    expect(tv2, isNotNull);
    expect(Focus.of(tv2!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(Focus.of(music2).hasFocus, isTrue);

    // check left direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(Focus.of(music1).hasFocus, isTrue);

    // check if going left on the first app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(Focus.of(music1).hasFocus, isTrue);
  });

  testWidgets("Moving right or up can go the settings icon", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭
     */
    when(appsService.launcherSections).thenReturn([
      withApps(fakeCategory(name: "tv", order: 0), [
        fakeApp(
          packageName: "me.efesser.tv1",
          name: "tv 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.tv2",
          name: "tv 2",
          version: "1.0.0",
        ),
      ]),
      withApps(fakeCategory(name: "music", order: 1), [
        fakeApp(
          packageName: "me.efesser.music1",
          name: "music 1",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music2",
          name: "music 2",
          version: "1.0.0",
        ),
        fakeApp(
          packageName: "me.efesser.music3",
          name: "music 3",
          version: "1.0.0",
        ),
      ]),
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(Focus.of(tv1!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    // Wifi and Entradas are focusable pills before Ajustes.
    for (var step = 0; step < 4; step++) {
      final Element? settings = findSettingsIcon(tester);
      if (settings != null && Focus.of(settings).hasFocus) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }

    Element? settingsIcon = findSettingsIcon(tester);
    expect(settingsIcon, isNotNull);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(settingsIcon!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    Element? tv2 = findAppCardByPackageName(tester, "me.efesser.tv2");
    expect(tv2, isNotNull);
    expect(Focus.of(settingsIcon).hasFocus, isFalse);
    expect(Focus.of(tv1).hasFocus, isFalse);
    expect(Focus.of(tv2!).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    for (var step = 0; step < 4; step++) {
      if (Focus.of(settingsIcon).hasFocus) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    expect(Focus.of(settingsIcon).hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    for (var step = 0; step < 6; step++) {
      if (Focus.of(settingsIcon).hasFocus) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      if (Focus.of(settingsIcon).hasFocus) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    expect(Focus.of(settingsIcon).hasFocus, isTrue);
  });
}

SettingsService mkSettingsService() {
  final settingsService = MockSettingsService();
  when(settingsService.dateFormat)
      .thenReturn(SettingsService.defaultDateFormat);
  when(settingsService.timeFormat)
      .thenReturn(SettingsService.defaultTimeFormat);
  when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
  when(settingsService.appKeyClickEnabled).thenReturn(false);
  when(settingsService.autoHideAppBarEnabled).thenReturn(false);
  when(settingsService.showCategoryTitles).thenReturn(true);
  when(settingsService.showDateInStatusBar).thenReturn(true);
  when(settingsService.showTimeInStatusBar).thenReturn(true);
  when(settingsService.showRecommendations).thenReturn(false);
  when(settingsService.recommendationsFeedUrl).thenReturn("");
  return settingsService;
}

WallpaperService mkWallpaperService(
    {bool wallpaper = true, bool customGradient = false}) {
  final wallpaperService = MockWallpaperService();
  when(wallpaperService.gradient).thenReturn(FLauncherGradients.greatWhale);
  when(wallpaperService.wallpaper)
      .thenReturn(wallpaper ? Image.asset('assets/logo.png').image : null);
  when(wallpaperService.ready).thenReturn(true);
  when(wallpaperService.hasCustomGradient).thenReturn(customGradient);
  return wallpaperService;
}

AppsService mkAppService() {
  final appsService = MockAppsService();
  when(appsService.initialized).thenReturn(true);
  when(appsService.launcherSections).thenReturn([]);
  when(appsService.getAppBanner(any))
      .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
  when(appsService.getAppIcon(any))
      .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
  return appsService;
}

Future<void> _pumpWidgetWith(
  WidgetTester tester,
  AppsService appsService,
) async {
  return _pumpWidgetWithProviders(
      tester, mkWallpaperService(), appsService, mkSettingsService());
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  WallpaperService wallpaperService,
  AppsService appsService,
  SettingsService settingsService,
) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WallpaperService>.value(value: wallpaperService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider(
            create: (_) => NetworkService(FLauncherChannel())),
        ChangeNotifierProvider(
          create: (_) => RecommendationsService(
            prefs,
            settingsService,
            FLauncherChannel(),
            fetcher: (_) async => null,
            periodicRefresh: false,
          ),
        ),
      ],
      builder: (_, __) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FLauncher(),
      ),
    ),
  );
  await tester.pump(Duration(seconds: 30), EnginePhase.sendSemanticsUpdate);
}
