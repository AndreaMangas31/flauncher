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

/// How many app tiles fit in a row before the "more" tile takes the last slot.
///
/// An unbounded width shows every app. Order is unchanged: the hidden tail is
/// the same sequence, just not drawn in the row.
int visibleAppCount({
  required double maxWidth,
  required double rowHeight,
  required int total,
}) {
  if (total <= 0) {
    return 0;
  }
  const double listPadding = 16;
  const double cardGap = 16;
  final double cardWidth = rowHeight * 16 / 9;
  final double slot = cardWidth + cardGap;
  if (!maxWidth.isFinite || slot <= 0) {
    return total;
  }
  final int fit = max(0, ((maxWidth - listPadding) / slot).floor());
  if (fit <= 0) {
    return 1;
  }
  if (total <= fit) {
    return total;
  }
  return max(1, fit - 1);
}
