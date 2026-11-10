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

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/default_layout.dart';
import 'package:flauncher/models/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  test("existing Apps category switches to pinned and recent once", () async {
    final Directory temp = await Directory.systemTemp.createTemp("flauncher-sort");
    final File file = File("${temp.path}/db.sqlite");
    addTearDown(() async {
      if (temp.existsSync()) {
        await temp.delete(recursive: true);
      }
    });

    final FLauncherDatabase created = FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    await created.insertCategory(CategoriesCompanion.insert(name: appsCategoryName, order: 0));
    await created.insertCategory(CategoriesCompanion.insert(
      name: musicCategoryName,
      order: 1,
      sort: const Value(CategorySort.alphabetical),
    ));
    await created.insertCategory(CategoriesCompanion.insert(name: "Favorites", order: 2));
    await created.customStatement("PRAGMA wal_checkpoint(FULL)");
    await created.close();

    final sql.Database raw = sql.sqlite3.open(file.path);
    raw.execute("PRAGMA user_version = 7");
    raw.dispose();

    final FLauncherDatabase upgraded = FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    addTearDown(upgraded.close);
    final List<Category> categories = await upgraded.getCategories();

    expect(categories.singleWhere((category) => category.name == appsCategoryName).sort, CategorySort.pinnedAndRecent);
    expect(categories.singleWhere((category) => category.name == musicCategoryName).sort, CategorySort.alphabetical);
    expect(categories.singleWhere((category) => category.name == "Favorites").sort, CategorySort.manual);
  });
}
