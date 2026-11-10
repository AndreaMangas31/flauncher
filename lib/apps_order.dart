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
import 'package:flauncher/models/app.dart';

/// Live TV is always first. The configured packages follow, in list order.
/// Anything else is not pinned.
int? favouriteRank(App application, {List<String> pinnedPackages = pinnedFavouritePackages}) {
  if (application.liveTv) {
    return 0;
  }
  final int index = pinnedPackages.indexOf(application.packageName);
  if (index < 0) {
    return null;
  }
  return index + 1;
}

/// Pinned favourites stay in [pinnedPackages] order even when [usageAvailable]
/// is false. The other apps are ordered by [App.lastTimeUsed] (newest first)
/// only when usage data was actually granted; otherwise their current order
/// is left alone.
void applyPinnedThenRecentOrder(
  List<App> applications, {
  required bool usageAvailable,
  List<String> pinnedPackages = pinnedFavouritePackages,
}) {
  final List<App> pinned = [];
  final List<App> rest = [];
  for (final App application in applications) {
    if (favouriteRank(application, pinnedPackages: pinnedPackages) != null) {
      pinned.add(application);
    } else {
      rest.add(application);
    }
  }

  pinned.sort((a, b) => favouriteRank(a, pinnedPackages: pinnedPackages)!
      .compareTo(favouriteRank(b, pinnedPackages: pinnedPackages)!));

  if (usageAvailable) {
    final List<MapEntry<int, App>> indexed = rest.asMap().entries.toList();
    indexed.sort((a, b) {
      final int byUse = b.value.lastTimeUsed.compareTo(a.value.lastTimeUsed);
      if (byUse != 0) {
        return byUse;
      }
      return a.key.compareTo(b.key);
    });
    rest
      ..clear()
      ..addAll(indexed.map((entry) => entry.value));
  }

  applications
    ..clear()
    ..addAll(pinned)
    ..addAll(rest);
}
