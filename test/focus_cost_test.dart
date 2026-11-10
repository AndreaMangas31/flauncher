import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/recommendations_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'mocks.dart';
import 'mocks.mocks.dart';

class _Channel extends Fake implements FLauncherChannel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a focus move does not rebuild every app tile on later frames',
      (tester) async {
    final apps = MockAppsService();
    when(apps.getAppBanner(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    when(apps.getAppIcon(any))
        .thenAnswer((_) async => Uint8List.fromList(kTransparentImage));
    final settings = MockSettingsService();
    when(settings.showCategoryTitles).thenReturn(false);
    when(settings.appHighlightAnimationEnabled).thenReturn(true);
    final category = fakeCategory(name: 'tv', type: CategoryType.row);
    final applications = [
      for (int i = 0; i < 4; i++) fakeApp(name: 'App $i', packageName: 'app.$i'),
    ];

    AppCard.buildCount = 0;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: CategoryRow(
              category: category,
              applications: applications,
              rowHeight: 80,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    final int built = AppCard.buildCount;
    AppCard.buildCount = 0;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Before: 4 builds for one focus move (the whole row). The pulse, when
    // enabled, used to schedule a border rebuild on every following frame.
    // The row must not keep rebuilding after the move.
    expect(built, 4);
    expect(AppCard.buildCount, lessThanOrEqualTo(4));
  });

  testWidgets('focusing a poster does not rebuild the whole row',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'recommendations_cache': '''
{
  "updatedAt": "2026-11-10T12:00:00Z",
  "items": [
    {"title": "A", "description": "a", "platform": "Netflix", "type": "serie", "status": "airing", "imageUrl": "https://example.com/a.jpg"},
    {"title": "B", "description": "b", "platform": "Disney+", "type": "serie", "status": "airing", "imageUrl": "https://example.com/b.jpg"},
    {"title": "C", "description": "c", "platform": "Filmin", "type": "serie", "status": "airing", "imageUrl": "https://example.com/c.jpg"}
  ]
}
''',
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = MockSettingsService();
    when(settings.showRecommendations).thenReturn(true);
    when(settings.recommendationsFeedUrl).thenReturn('');
    recommendationPosterBuilds = 0;
    await mockNetworkImagesFor(() async {
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
        home: Scaffold(body: SizedBox(height: 400, child: RecommendationsRow())),
      ),
    ));
    await tester.pump();
    final int built = recommendationPosterBuilds;
    recommendationPosterBuilds = 0;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    // Before this pass a focus move rebuilt all 3 posters (the row called
    // setState). Only the poster that lost focus and the one that gained it
    // should build now.
    expect(built, greaterThanOrEqualTo(3));
    expect(recommendationPosterBuilds, lessThanOrEqualTo(2));
    });
  });
}
