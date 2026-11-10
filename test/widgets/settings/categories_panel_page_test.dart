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
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1280, 720);
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Sections are displayed", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);

    await _pumpWidgetWithProviders(tester, appsService);

    expect(find.text("Favorites"), findsOneWidget);
    expect(find.text("Applications"), findsOneWidget);
  });

  testWidgets("The down arrow moves that section", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.byIcon(Icons.arrow_downward).first);
    await tester.pumpAndSettle();

    verify(appsService.moveSection(0, 1));
  });

  testWidgets("Settings opens the section editor", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("SectionPanelPage")), findsOneWidget);
  });

  testWidgets("Add section opens a blank editor", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.text("Add section"));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("SectionPanelPage")), findsOneWidget);
  });
}

Future<void> _pumpWidgetWithProviders(
    WidgetTester tester, AppsService appsService) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
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
          LauncherSectionPanelPage.routeName: (_) =>
              const SizedBox(key: Key("SectionPanelPage")),
        },
        home: Scaffold(body: LauncherSectionsPanelPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
