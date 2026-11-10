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

import 'dart:math';

import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/home_focus.dart';
import 'package:flauncher/widgets/app_row_fit.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/emerald_backdrop.dart';
import 'package:flauncher/widgets/recommendations_row.dart';
import 'package:flauncher/widgets/launcher_alternative_view.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/category.dart';

class FLauncher extends StatelessWidget {
  const FLauncher();

  @override
  Widget build(BuildContext context) => HomeFocusHost(
      child: FocusTraversalGroup(
          policy: RowByRowTraversalPolicy(),
          child: Stack(children: [
            Consumer<WallpaperService>(
                builder: (_, wallpaperService, __) =>
                    _wallpaper(context, wallpaperService)),
            Consumer<LauncherState>(
                builder: (_, state, child) => Visibility(
                    child: child!,
                    replacement: const Center(child: AlternativeLauncherView()),
                    visible: state.launcherVisible),
                child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Consumer<AppsService>(
                        builder: (context, appsService, _) {
                      if (!appsService.initialized) {
                        return _emptyState(context);
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final int rowCount = appsService.launcherSections
                              .whereType<Category>()
                              .where((category) =>
                                  category.type == CategoryType.row)
                              .length;
                          final double barHeight = constraints.maxHeight < 600
                              ? 52
                              : FocusAwareAppBar.barHeight;
                          final double rowHeight = homeRowHeight(
                            rowWidth: max(0, constraints.maxWidth - 32),
                            bodyHeight:
                                max(0, constraints.maxHeight - barHeight - 8),
                            rowCount: rowCount,
                          );
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Column(
                              children: [
                                FocusAwareAppBar(height: barHeight),
                                _sections(
                                    appsService.launcherSections, rowHeight),
                                const Expanded(child: RecommendationsRow()),
                              ],
                            ),
                          );
                        },
                      );
                    })))
          ])));

  Widget _sections(List<LauncherSection> sections, double rowHeight) => Column(
        children: sections.map((section) {
          final Key sectionKey = Key(section.id.toString());
          final Widget categoryWidget;

          if (section is LauncherSpacer) {
            return SizedBox(key: sectionKey, height: section.height.toDouble());
          }

          Category category = section as Category;
          switch (category.type) {
            case CategoryType.row:
              categoryWidget = CategoryRow(
                  key: sectionKey,
                  category: category,
                  applications: category.applications,
                  rowHeight: rowHeight);
            case CategoryType.grid:
              categoryWidget = AppsGrid(
                  key: sectionKey,
                  category: category,
                  applications: category.applications);
          }

          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: categoryWidget);
        }).toList(),
      );

  Widget _wallpaper(BuildContext context, WallpaperService wallpaperService) {
    if (!wallpaperService.ready) {
      return const ColoredBox(
          key: Key("background"), color: EmeraldShrine.background);
    }
    // A photo the user picked wins over the shrine. A gradient they picked
    // in settings still wins over the shrine, which is only the default.
    if (wallpaperService.wallpaper != null) {
      return EmeraldBackdrop(userWallpaper: wallpaperService.wallpaper);
    }
    if (wallpaperService.hasCustomGradient) {
      return Container(
        key: const Key("background"),
        decoration: BoxDecoration(gradient: wallpaperService.gradient.gradient),
      );
    }
    return const EmeraldBackdrop();
  }

  Widget _emptyState(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(localizations.loading,
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
