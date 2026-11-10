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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../flauncher_test.dart';
import '../../mocks.mocks.dart';

MockSettingsService _settings() {
  final settings = MockSettingsService();
  when(settings.appHighlightAnimationEnabled).thenReturn(true);
  when(settings.appKeyClickEnabled).thenReturn(false);
  when(settings.showCategoryTitles).thenReturn(true);
  when(settings.showRecommendations).thenReturn(false);
  when(settings.recommendationsFeedUrl).thenReturn("");
  when(settings.dateFormat).thenReturn(SettingsService.defaultDateFormat);
  when(settings.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
  when(settings.backButtonAction).thenReturn("");
  when(settings.setAppHighlightAnimationEnabled(any)).thenAnswer((_) async {});
  when(settings.setAppKeyClickEnabled(any)).thenAnswer((_) async {});
  when(settings.setShowCategoryTitles(any)).thenAnswer((_) async {});
  when(settings.setShowRecommendations(any)).thenAnswer((_) async {});
  when(settings.setRecommendationsFeedUrl(any)).thenAnswer((_) async {});
  when(settings.setDateTimeFormat(any, any)).thenAnswer((_) async {});
  when(settings.setBackButtonAction(any)).thenAnswer((_) async {});
  return settings;
}

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = Size(1280, 720);
    binding.window.devicePixelRatioTestValue = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("'Applications' opens ApplicationsPanelPage", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Applications"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("ApplicationsPanelPage")), findsOneWidget);
  });

  testWidgets("'Categories' opens CategoriesPanelPage", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Sections"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("CategoriesPanelPage")), findsOneWidget);
  });

  testWidgets("'Wallpaper' navigates to WallpaperPanelPage", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Wallpaper"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("WallpaperPanelPage")), findsOneWidget);
  });

  testWidgets("'Android settings' calls AppsService", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    verify(appsService.openSettings());
  });

  testWidgets("'Use 24-hour time format' toggle calls SettingsService",
      (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mkSettingsService(), appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    //verify(settingsService.setDateTimeFormat("EEE", "HHH"));
  });

  testWidgets("'Crash Reporting' toggle calls SettingsService", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  });

  testWidgets("'Analytics Reporting' toggle calls SettingsService",
      (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  });

  testWidgets("'About FLauncher' opens about dialog", (tester) async {
    final settingsService = _settings();
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
    PackageInfoPlatform.instance = _MockPackageInfoPlatform();

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("About FLauncher"));
    await tester.pumpAndSettle();
    expect(find.byType(FLauncherAboutDialog), findsOneWidget);
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  SettingsService settingsService,
  AppsService appsService,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, __) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          LauncherSectionsPanelPage.routeName: (_) =>
              Container(key: Key("CategoriesPanelPage")),
          WallpaperPanelPage.routeName: (_) =>
              Container(key: Key("WallpaperPanelPage")),
          ApplicationsPanelPage.routeName: (_) =>
              Container(key: Key("ApplicationsPanelPage")),
        },
        home: Material(child: SettingsPanelPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockPackageInfoPlatform
    with MockPlatformInterfaceMixin
    implements PackageInfoPlatform {
  @override
  Future<PackageInfoData> getAll({String? baseUrl}) async => PackageInfoData(
        appName: "FLauncher",
        packageName: "me.efesser.flauncher",
        version: "1.0.0",
        buildNumber: "1",
        buildSignature: "",
      );
}
