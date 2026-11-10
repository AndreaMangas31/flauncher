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

import 'dart:typed_data';

import 'package:flauncher/default_layout.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/models/hdmi_input.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_row_fit.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/inputs_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'mocks.dart';
import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('eight banners still fit when one slot is reserved for Entradas', () {
    final double height = rowHeightForSlots(928, slots: 9);
    expect(
      visibleAppCount(
        maxWidth: 928,
        rowHeight: height,
        total: 7,
        reservedSlots: 1,
      ),
      7,
    );
    expect(
      visibleAppCount(
        maxWidth: 928,
        rowHeight: height,
        total: 12,
        reservedSlots: 1,
      ),
      greaterThanOrEqualTo(7),
    );
  });

  testWidgets('the picker lists HDMI ports and reports the one chosen',
      (tester) async {
    HdmiInput? chosen;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: InputsPicker(
        inputs: const [
          HdmiInput(id: 'HW5', label: 'HDMI 1'),
          HdmiInput(id: 'HW6', label: 'HDMI 2'),
        ],
        onSelected: (input) => chosen = input,
        onOpenSystem: () {},
      ),
    ));
    await tester.pump();

    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('HDMI 1'), findsOneWidget);
    expect(find.text('HDMI 2'), findsOneWidget);

    await tester.tap(find.text('HDMI 2'));
    expect(chosen?.id, 'HW6');
  });

  testWidgets('a television with no HDMI ports keeps a quiet empty picker',
      (tester) async {
    var openedSystem = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: InputsPicker(
        inputs: const [],
        onSelected: (_) {},
        onOpenSystem: () => openedSystem = true,
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('inputs-empty')), findsOneWidget);
    expect(find.text('HDMI 1'), findsNothing);

    await tester.tap(find.byKey(const Key('inputs-system')));
    expect(openedSystem, isTrue);
  });

  testWidgets('Entradas is the first tile of Apps, before the pinned apps',
      (tester) async {
    final apps = MockAppsService();
    when(apps.getAppBanner(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    when(apps.getAppIcon(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    final settings = MockSettingsService();
    when(settings.showCategoryTitles).thenReturn(true);
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    final category = fakeCategory(
      name: appsCategoryName,
      type: CategoryType.row,
      sort: CategorySort.pinnedAndRecent,
    );
    final List<String> pinned = [
      'com.google.android.tv',
      netflixPackage,
      crunchyrollPackage,
    ];

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 960,
            child: CategoryRow(
              category: category,
              applications: [
                for (final String package in pinned)
                  fakeApp(name: package, packageName: package),
              ],
              rowHeight: rowHeightForSlots(960, slots: 9),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('inputs-tile')), findsOneWidget);
    expect(find.text('Entradas'), findsWidgets);
    final double inputsX = tester.getTopLeft(find.byKey(const Key('inputs-tile'))).dx;
    final double tvX =
        tester.getTopLeft(find.byKey(const Key('com.google.android.tv'))).dx;
    final double netflixX = tester.getTopLeft(find.byKey(Key(netflixPackage))).dx;
    expect(inputsX, lessThan(tvX));
    expect(tvX, lessThan(netflixX));
    expect(find.byKey(const Key('more-apps')), findsNothing);
  });
}
