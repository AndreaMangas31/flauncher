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
import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/app_row_fit.dart';
import 'package:flauncher/widgets/category_container_common.dart';
import 'package:flauncher/widgets/more_apps_tile.dart';
import 'package:flauncher/widgets/section_heading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';
import '../providers/settings_service.dart';

class CategoryRow extends StatelessWidget {
  final Category category;
  final List<App> applications;

  CategoryRow({
    Key? key,
    required this.category,
    required this.applications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget categoryContent;
    if (applications.isEmpty) {
      categoryContent = categoryContainerEmptyState(context);
    } else {
      categoryContent = LayoutBuilder(
        builder: (context, constraints) {
          final int visible = visibleAppCount(
            maxWidth: constraints.maxWidth,
            rowHeight: category.rowHeight.toDouble(),
            total: applications.length,
          );
          final int hidden = applications.length - visible;
          return SizedBox(
            height: category.rowHeight.toDouble(),
            child: ListView.custom(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              childrenDelegate: SliverChildBuilderDelegate(
                childCount: visible + (hidden > 0 ? 1 : 0),
                findChildIndexCallback: _findChildIndex,
                (context, index) {
                  if (index >= visible) {
                    return Padding(
                      key: const Key('more-apps'),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MoreAppsTile(
                        category: category,
                        hiddenApplications: applications.sublist(visible),
                        indexOffset: visible,
                      ),
                    );
                  }
                  return Padding(
                    key: Key(applications[index].packageName),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppCard(
                      category: category,
                      application: applications[index],
                      autofocus: index == 0,
                      onMove: (direction) => _onMove(context, direction, index),
                      onMoveEnd: () => _onMoveEnd(context),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Selector<SettingsService, bool>(
            selector: (context, service) => service.showCategoryTitles,
            builder: (context, showCategoriesTitle, _) {
              if (showCategoriesTitle) {
                return SectionHeading(category.name);
              }

              return SizedBox.shrink();
            }),
        categoryContent
      ],
    );
  }

  int? _findChildIndex(Key key) {
    final int index = applications.indexWhere(
        (app) => app.packageName == (key as ValueKey<String>).value);
    return index < 0 ? null : index;
  }

  void _onMove(BuildContext context, AxisDirection direction, int index) {
    int newIndex = 0;

    if (direction == AxisDirection.right && index < applications.length - 1) {
      newIndex = index + 1;
    } else if (direction == AxisDirection.left && index > 0) {
      newIndex = index - 1;
    } else {
      return;
    }

    final appsService = context.read<AppsService>();
    appsService.reorderApplication(category, index, newIndex);
  }

  void _onMoveEnd(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.saveApplicationOrderInCategory(category);
  }
}
