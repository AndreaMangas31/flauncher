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
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
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

  testWidgets("Category is displayed", (tester) async {
    final appsService = MockAppsService();
    final favoritesCategory = fakeCategory(
        name: "Favorites",
        sort: CategorySort.alphabetical,
        type: CategoryType.grid,
        columnsCount: 6);
    when(appsService.launcherSections).thenReturn([favoritesCategory]);

    await _pump(tester, appsService);

    expect(find.text("Favorites"), findsOneWidget);
    expect(find.text("Alphabetical"), findsOneWidget);
    expect(find.text("Grid"), findsOneWidget);
    expect(find.text("6"), findsOneWidget);
  });

  testWidgets("Delete removes the section", (tester) async {
    final appsService = MockAppsService();
    final favoritesCategory = fakeCategory(name: "Favorites");
    when(appsService.launcherSections).thenReturn([favoritesCategory]);

    await _pump(tester, appsService);
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();

    verify(appsService.deleteSection(0));
  });

  testWidgets("Saving a new sort persists the category", (tester) async {
    final appsService = MockAppsService();
    final favoritesCategory = fakeCategory(
        name: "Favorites",
        sort: CategorySort.alphabetical,
        type: CategoryType.grid,
        columnsCount: 6);
    when(appsService.launcherSections).thenReturn([favoritesCategory]);

    await _pump(tester, appsService);
    await tester.tap(find.text("Alphabetical"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Manual").last);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Save"));
    await tester.pumpAndSettle();

    verify(appsService.updateCategory(
      favoritesCategory.id,
      "Favorites",
      CategorySort.manual,
      CategoryType.grid,
      6,
      110,
    ));
  });
}

Future<void> _pump(WidgetTester tester, AppsService appsService) async {
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
        home: Scaffold(body: LauncherSectionPanelPage(sectionIndex: 0)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
