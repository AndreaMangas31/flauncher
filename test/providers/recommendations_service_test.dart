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
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("friday resume after more than 15 minutes refreshes the feed", (tester) async {
    final DateTime friday = DateTime(2026, 11, 13, 21);
    expect(friday.weekday, DateTime.friday);
    final _Harness harness = await _start(tester, friday);

    expect(harness.fetches, 1);

    harness.clock.time = friday.add(const Duration(minutes: 16));
    await harness.comeHome();

    expect(harness.fetches, 2);
  });

  testWidgets("friday resume within 15 minutes does not refresh", (tester) async {
    final DateTime friday = DateTime(2026, 11, 13, 21);
    expect(friday.weekday, DateTime.friday);
    final _Harness harness = await _start(tester, friday);

    expect(harness.fetches, 1);

    harness.clock.time = friday.add(const Duration(minutes: 14));
    await harness.comeHome();

    expect(harness.fetches, 1);
  });

  testWidgets("a resume on any other day does not refresh", (tester) async {
    final DateTime thursday = DateTime(2026, 11, 12, 21);
    expect(thursday.weekday, DateTime.thursday);
    final _Harness harness = await _start(tester, thursday);

    expect(harness.fetches, 1);

    harness.clock.time = thursday.add(const Duration(minutes: 16));
    await harness.comeHome();

    expect(harness.fetches, 1);
  });
}

class _Clock {
  _Clock(this.time);

  DateTime time;
  int fetches = 0;
}

class _Harness {
  final WidgetTester tester;
  final _Clock clock;

  _Harness(this.tester, this.clock);

  int get fetches => clock.fetches;

  Future<void> comeHome() async {
    // paused then resumed is the return to the foreground. A second
    // resumed with no change is ignored by the binding.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }
}

Future<_Harness> _start(WidgetTester tester, DateTime now) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _Clock clock = _Clock(now);
  final RecommendationsService service = RecommendationsService(
    prefs,
    SettingsService(prefs),
    FLauncherChannel(),
    fetcher: (_) async {
      clock.fetches += 1;
      return null;
    },
    periodicRefresh: false,
    now: () => clock.time,
  );
  addTearDown(() {
    service.dispose();
    final AppLifecycleState state = tester.binding.lifecycleState ?? AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  });

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  return _Harness(tester, clock);
}
