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

import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("AppsService initialised correctly", () {
    test("persists the apps reported by the system", () async {
      final channel = MockFLauncherChannel();
      final database = MockFLauncherDatabase();
      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'me.efesser.flauncher',
              'name': 'FLauncher',
              'version': null,
            },
            {
              'packageName': 'me.efesser.flauncher.2',
              'name': 'FLauncher 2',
              'version': '2.0.0',
            }
          ]));
      when(channel.getUsageStats()).thenAnswer((_) async => null);
      when(database.getApplications()).thenAnswer((_) => Future.value([]));
      when(database.getCategories()).thenAnswer((_) async => []);
      when(database.getAppsCategories()).thenAnswer((_) async => []);
      when(database.getLauncherSpacers()).thenAnswer((_) async => []);
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.wasCreated).thenReturn(false);
      AppsService(channel, database);
      await untilCalled(channel.addAppsChangedListener(any));

      verify(database.persistApps([
        AppsCompanion(
          packageName: const Value("me.efesser.flauncher"),
          name: const Value("FLauncher"),
          version: const Value(""),
        ),
        AppsCompanion(
          packageName: const Value("me.efesser.flauncher.2"),
          name: const Value("FLauncher 2"),
          version: const Value("2.0.0"),
        ),
      ]));
      verify(database.deleteApps([]));
    });

    test("with newly installed, uninstalled and existing apps", () async {
      final channel = MockFLauncherChannel();
      final database = MockFLauncherDatabase();
      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'me.efesser.flauncher',
              'name': 'FLauncher',
              'version': '2.0.0',
            },
            {
              'packageName': 'me.efesser.flauncher.2',
              'name': 'FLauncher 2',
              'version': '1.0.0',
            }
          ]));
      when(channel.getUsageStats()).thenAnswer((_) async => null);
      when(channel.applicationExists("uninstalled.app"))
          .thenAnswer((_) => Future.value(false));
      when(channel.applicationExists("not.uninstalled.app"))
          .thenAnswer((_) => Future.value(true));
      when(database.getApplications()).thenAnswer((_) => Future.value([
            fakeApp(
                packageName: "me.efesser.flauncher",
                name: "FLauncher",
                version: "1.0.0"),
            fakeApp(
                packageName: "uninstalled.app",
                name: "Uninstalled Application",
                version: "1.0.0"),
            fakeApp(
                packageName: "not.uninstalled.app",
                name: "Not Uninstalled Application",
                version: "1.0.0")
          ]));
      when(database.getCategories()).thenAnswer((_) async => []);
      when(database.getAppsCategories()).thenAnswer((_) async => []);
      when(database.getLauncherSpacers()).thenAnswer((_) async => []);
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.wasCreated).thenReturn(false);
      AppsService(channel, database);
      await untilCalled(channel.addAppsChangedListener(any));

      verify(database.persistApps([
        AppsCompanion(
          packageName: const Value("me.efesser.flauncher"),
          name: const Value("FLauncher"),
          version: const Value("2.0.0"),
        ),
        AppsCompanion(
          packageName: const Value("me.efesser.flauncher.2"),
          name: const Value("FLauncher 2"),
          version: const Value("1.0.0"),
        ),
      ]));
      verify(database.deleteApps(["uninstalled.app"]));
    });
  });

  test("launchApp calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);
    final app = fakeApp();

    await appsService.launchApp(app);
  });

  test("openAppInfo calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);
    final app = fakeApp();

    await appsService.openAppInfo(app);

    verify(channel.openAppInfo(app.packageName));
  });

  test("uninstallApp calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);
    final app = fakeApp();

    await appsService.uninstallApp(app);

    verify(channel.uninstallApp(app.packageName));
  });

  test("openSettings calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);

    await appsService.openSettings();

    verify(channel.openSettings());
  });

  test("isDefaultLauncher calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    when(channel.isDefaultLauncher()).thenAnswer((_) => Future.value(true));
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);

    final isDefaultLauncher = await appsService.isDefaultLauncher();

    verify(channel.isDefaultLauncher());
    expect(isDefaultLauncher, isTrue);
  });

  test("startAmbientMode calls channel", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);

    await appsService.startAmbientMode();

    verify(channel.startAmbientMode());
  });

  test("addToCategory adds app to category", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);
    final category = fakeCategory(name: "Category");
    when(database.nextAppCategoryOrder(category.id))
        .thenAnswer((_) => Future.value(1));

    await appsService.addToCategory(
        fakeApp(packageName: "app.to.be.added"), category);

    verify(database.insertAppsCategories([
      AppsCategoriesCompanion.insert(
          categoryId: category.id, appPackageName: "app.to.be.added", order: 1)
    ]));
  });

  test("removeFromCategory removes app from category", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final appsService =
        await _buildInitialisedAppsService(channel, database, []);
    final app = fakeApp(packageName: "app.to.be.added");
    final category = fakeCategory(name: "Category");

    await appsService.removeFromCategory(app, category);

    verify(database.deleteAppCategory(category.id, app.packageName));
  });

  test("saveOrderInCategory persists apps order from memory to database",
      () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final category = fakeCategory(name: "Category");
    final appsService = await _buildInitialisedAppsService(channel, database, [
      withApps(category,
          [fakeApp(packageName: "app.1"), fakeApp(packageName: "app.2")])
    ]);

    await appsService.saveApplicationOrderInCategory(category);

    verify(database.replaceAppsCategories([
      AppsCategoriesCompanion.insert(
          categoryId: category.id, appPackageName: "app.1", order: 0),
      AppsCategoriesCompanion.insert(
          categoryId: category.id, appPackageName: "app.2", order: 1)
    ]));
  });

  test("reorderApplication changes application order in-memory", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final category = fakeCategory(name: "Category");
    final appsService = await _buildInitialisedAppsService(channel, database, [
      withApps(category,
          [fakeApp(packageName: "app.1"), fakeApp(packageName: "app.2")])
    ]);

    appsService.reorderApplication(category, 1, 0);

    expect(
        (appsService.launcherSections[0] as Category)
            .applications[0]
            .packageName,
        "app.2");
    expect(
        (appsService.launcherSections[0] as Category)
            .applications[1]
            .packageName,
        "app.1");
  });

  test("addCategory adds category at index 0 and moves others", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final existingCategory = fakeCategory(name: "Existing Category", order: 0);
    final appsService = await _buildInitialisedAppsService(
      channel,
      database,
      [withApps(existingCategory, [])],
    );

    when(database.insertCategory(any)).thenAnswer((_) async => 7);
    when(database.updateCategories(any)).thenAnswer((_) async {});

    await appsService.addCategory("New Category");

    verify(database.insertCategory(CategoriesCompanion.insert(
      name: "New Category",
      order: 0,
      sort: const Value(CategorySort.manual),
      type: const Value(CategoryType.row),
      columnsCount: const Value(6),
      rowHeight: const Value(110),
    )));
    verify(database.updateCategories([
      CategoriesCompanion(id: Value(existingCategory.id), order: Value(1))
    ]));
  });

  test("renameCategory renames category", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final category = fakeCategory(name: "Old name", order: 0);
    final appsService = await _buildInitialisedAppsService(
      channel,
      database,
      [withApps(category, [])],
    );

    await appsService.renameCategory(category, "New name");

    verify(database.updateCategory(
        category.id, CategoriesCompanion(name: Value("New name"))));
  });

  test("deleteCategory deletes category", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final defaultCategory = fakeCategory(name: "Applications", order: 0);
    final categoryToDelete = fakeCategory(name: "Delete Me", order: 1);
    final appInDefaultCategory = fakeApp();
    final appInCategoryToDelete = fakeApp(packageName: "app.to.be.moved.1");
    final hiddenAppInCategoryToDelete =
        fakeApp(packageName: "app.to.be.moved.2", hidden: true);
    final appsService = await _buildInitialisedAppsService(
      channel,
      database,
      [
        withApps(defaultCategory, [appInDefaultCategory]),
        withApps(categoryToDelete,
            [appInCategoryToDelete, hiddenAppInCategoryToDelete])
      ],
    );

    await appsService.deleteSection(1);

    verify(database.deleteCategory(categoryToDelete.id));
  });

  test("moveSection changes categories order", () async {
    final channel = MockFLauncherChannel();
    final database = MockFLauncherDatabase();
    final applicationsCategory = fakeCategory(name: "Applications", order: 0);
    final favoritesCategory = fakeCategory(name: "Favorites", order: 1);
    final appsService = await _buildInitialisedAppsService(
      channel,
      database,
      [withApps(applicationsCategory, []), withApps(favoritesCategory, [])],
    );
    when(database.nextAppCategoryOrder(applicationsCategory.id))
        .thenAnswer((_) => Future.value(1));

    await appsService.moveSection(1, 0);

    verify(database.updateCategories(
      [
        CategoriesCompanion(id: Value(favoritesCategory.id), order: Value(0)),
        CategoriesCompanion(id: Value(applicationsCategory.id), order: Value(1))
      ],
    ));
  });

  test("hideApplication hides application", () async {
    final database = MockFLauncherDatabase();
    final application = fakeApp();
    final appsService =
        await _buildInitialisedAppsService(MockFLauncherChannel(), database, [
      withApps(fakeCategory(), [application]),
    ]);

    await appsService.hideApplication(application);

    verify(database.updateApp(
        application.packageName, const AppsCompanion(hidden: Value(true))));
    expect(appsService.applications.single.hidden, isTrue);
  });

  test("showApplication hides application", () async {
    final database = MockFLauncherDatabase();
    final application = fakeApp();
    final appsService = await _buildInitialisedAppsService(
        MockFLauncherChannel(), database, []);

    await appsService.showApplication(application);

    verify(database.updateApp(
        application.packageName, const AppsCompanion(hidden: Value(false))));
  });

  test("setCategoryType persists change in database", () async {
    final database = MockFLauncherDatabase();
    final category = fakeCategory(type: CategoryType.row);
    final appsService = await _buildInitialisedAppsService(
        MockFLauncherChannel(), database, []);

    await appsService.setCategoryType(category, CategoryType.grid);

    verify(database.updateCategory(
        category.id, CategoriesCompanion(type: Value(CategoryType.grid))));
  });

  test("setCategorySort persists change in database", () async {
    final database = MockFLauncherDatabase();
    final category = fakeCategory(sort: CategorySort.manual);
    final appsService = await _buildInitialisedAppsService(
        MockFLauncherChannel(), database, []);

    await appsService.setCategorySort(category, CategorySort.alphabetical);

    verify(database.updateCategory(category.id,
        CategoriesCompanion(sort: Value(CategorySort.alphabetical))));
  });

  test("setCategoryColumnsCount persists change in database", () async {
    final database = MockFLauncherDatabase();
    final category = fakeCategory(columnsCount: 6);
    final appsService = await _buildInitialisedAppsService(
        MockFLauncherChannel(), database, []);

    await appsService.setCategoryColumnsCount(category, 8);

    verify(database.updateCategory(
        category.id, CategoriesCompanion(columnsCount: Value(8))));
  });

  test("setCategoryRowHeight persists change in database", () async {
    final database = MockFLauncherDatabase();
    final category = fakeCategory(rowHeight: 110);
    final appsService = await _buildInitialisedAppsService(
        MockFLauncherChannel(), database, []);

    await appsService.setCategoryRowHeight(category, 120);

    verify(database.updateCategory(
        category.id, CategoriesCompanion(rowHeight: Value(120))));
  });
}

Future<AppsService> _buildInitialisedAppsService(
  MockFLauncherChannel channel,
  MockFLauncherDatabase database,
  List<Category> categories,
) async {
  final List<App> apps = [
    for (final Category category in categories) ...category.applications,
  ];
  when(channel.getApplications()).thenAnswer((_) async => [
        for (final App app in apps)
          {
            'packageName': app.packageName,
            'name': app.name,
            'version': app.version,
          },
      ]);
  when(channel.getUsageStats()).thenAnswer((_) async => null);
  when(database.getApplications()).thenAnswer((_) async => apps);
  when(database.getCategories()).thenAnswer((_) async => categories);
  when(database.getAppsCategories()).thenAnswer((_) async => []);
  when(database.getLauncherSpacers()).thenAnswer((_) async => []);
  when(database.transaction(any))
      .thenAnswer((realInvocation) => realInvocation.positionalArguments[0]());
  when(database.wasCreated).thenReturn(false);
  final appsService = AppsService(channel, database);
  await untilCalled(channel.addAppsChangedListener(any));
  clearInteractions(channel);
  clearInteractions(database);
  return appsService;
}
