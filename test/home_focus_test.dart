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

import 'package:flauncher/default_layout.dart';
import 'package:flauncher/home_focus.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'helpers.dart';
import 'mocks.dart';
import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppsService apps;
  late MockSettingsService settings;

  setUp(() {
    apps = MockAppsService();
    when(apps.getAppBanner(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    when(apps.getAppIcon(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    settings = MockSettingsService();
    when(settings.showCategoryTitles).thenReturn(false);
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
  });

  testWidgets(
      'cold start and resume focus Entradas, and the row returns to the start',
      (tester) async {
    await _pumpHome(tester, apps, settings);
    await tester.pump();

    expect(_focused(tester, _entradas(tester)), isTrue);
    expect(
        _focused(
            tester, findAppCardByPackageName(tester, 'com.netflix.ninja')!),
        isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final Element netflix =
        findAppCardByPackageName(tester, 'com.netflix.ninja')!;
    expect(_focused(tester, _entradas(tester)), isFalse);
    expect(_focused(tester, netflix), isTrue);
    expect(_appsOffset(tester), greaterThan(0));

    // Moving around the home screen does not pull focus back.
    await tester.pump(const Duration(milliseconds: 400));
    expect(_focused(tester, netflix), isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(_focused(tester, _entradas(tester)), isTrue);
    expect(_focused(tester, netflix), isFalse);
    expect(_appsOffset(tester), 0);
  });

  testWidgets('a screen-on, dream-end, or Home event focuses Entradas',
      (tester) async {
    await _pumpHome(tester, apps, settings);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(_focused(tester, _entradas(tester)), isFalse);

    const MethodChannel channel = MethodChannel('me.efesser.flauncher/method');
    final ByteData? message =
        channel.codec.encodeMethodCall(const MethodCall('returnHome'));
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      message,
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(_focused(tester, _entradas(tester)), isTrue);
    expect(_appsOffset(tester), 0);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  MockAppsService apps,
  MockSettingsService settings,
) {
  final Category appsCategory = fakeCategory(
    name: appsCategoryName,
    type: CategoryType.row,
    sort: CategorySort.pinnedAndRecent,
  );
  final Category music =
      fakeCategory(name: 'music', type: CategoryType.row, order: 1);
  return tester.pumpWidget(MultiProvider(
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
      home: HomeFocusHost(
        child: Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              children: [
                CategoryRow(
                  category: appsCategory,
                  applications: [
                    fakeApp(name: 'Netflix', packageName: 'com.netflix.ninja'),
                    fakeApp(name: 'Max', packageName: 'com.wbd.stream'),
                    fakeApp(
                        name: 'Filmin', packageName: 'com.filmin.androidtv'),
                  ],
                  rowHeight: 180,
                ),
                CategoryRow(
                  category: music,
                  applications: [
                    fakeApp(
                        name: 'YouTube',
                        packageName: 'com.google.android.youtube.tv'),
                  ],
                  rowHeight: 180,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
}

Element _entradas(WidgetTester tester) {
  return tester.element(find.descendant(
    of: find.byKey(const Key('inputs-tile')),
    matching: find.byType(InkWell),
  ));
}

bool _focused(WidgetTester tester, Element element) {
  final Widget widget = element.widget;
  if (widget is InkWell && widget.focusNode != null) {
    return widget.focusNode!.hasFocus;
  }
  return Focus.of(element).hasFocus;
}

double _appsOffset(WidgetTester tester) {
  final Finder scrollable = find.descendant(
    of: find.byKey(const Key('apps-row-scroll')),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
}
