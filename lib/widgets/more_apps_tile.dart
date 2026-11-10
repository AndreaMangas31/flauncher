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

import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Last slot of a row that does not fit on screen. Opens the tail of the
/// same ordered list; it does not reorder anything.
class MoreAppsTile extends StatefulWidget {
  final Category category;
  final List<App> hiddenApplications;
  final int indexOffset;

  const MoreAppsTile({
    super.key,
    required this.category,
    required this.hiddenApplications,
    required this.indexOffset,
  });

  @override
  State<MoreAppsTile> createState() => _MoreAppsTileState();
}

class _MoreAppsTileState extends State<MoreAppsTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool recent = widget.category.sort == CategorySort.pinnedAndRecent;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedScale(
        scale: _focused ? 1.06 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
            boxShadow: _focused ? EmeraldShrine.focusShadows : const [],
          ),
          child: Material(
            color: EmeraldShrine.surfaceTint,
            borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onFocusChange: (focused) => setState(() => _focused = focused),
              onTap: () => _open(context),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
                  border: Border.all(
                    color: _focused
                        ? EmeraldShrine.accent
                        : Colors.white.withOpacity(0.08),
                    width: _focused ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.more_horiz,
                            color: _focused
                                ? EmeraldShrine.accent
                                : EmeraldShrine.text),
                        const SizedBox(height: 2),
                        Text(
                          localizations.moreApps,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: EmeraldShrine.body(fontSize: 13),
                        ),
                        if (recent)
                          Text(
                            localizations.moreAppsRecent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: EmeraldShrine.body(
                                fontSize: 11,
                                color: EmeraldShrine.secondaryText),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => MoreAppsDialog(
        category: widget.category,
        applications: widget.hiddenApplications,
        indexOffset: widget.indexOffset,
      ),
    );
  }
}

class MoreAppsDialog extends StatefulWidget {
  final Category category;
  final List<App> applications;
  final int indexOffset;

  const MoreAppsDialog({
    super.key,
    required this.category,
    required this.applications,
    required this.indexOffset,
  });

  @override
  State<MoreAppsDialog> createState() => _MoreAppsDialogState();
}

class _MoreAppsDialogState extends State<MoreAppsDialog> {
  late final List<App> _applications = List<App>.of(widget.applications);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: EmeraldShrine.surface.withOpacity(0.94),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.moreApps,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: widget.category.rowHeight.toDouble(),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _applications.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => AppCard(
                  key: Key(_applications[index].packageName),
                  category: widget.category,
                  application: _applications[index],
                  autofocus: index == 0,
                  onMove: (direction) => _onMove(context, direction, index),
                  onMoveEnd: () => context
                      .read<AppsService>()
                      .saveApplicationOrderInCategory(widget.category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMove(BuildContext context, AxisDirection direction, int index) {
    int? localTarget;
    if (direction == AxisDirection.right && index < _applications.length - 1) {
      localTarget = index + 1;
    } else if (direction == AxisDirection.left && index > 0) {
      localTarget = index - 1;
    }
    if (localTarget == null) {
      return;
    }

    context.read<AppsService>().reorderApplication(
          widget.category,
          widget.indexOffset + index,
          widget.indexOffset + localTarget,
        );
    setState(() {
      final App moved = _applications.removeAt(index);
      _applications.insert(localTarget!, moved);
    });
  }
}
