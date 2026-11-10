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

/// Horizontal padding of the app list, both sides together (`EdgeInsets.all(8)`).
const double appRowListPadding = 16;

/// Horizontal padding around one card, both sides together.
const double appRowCardGap = 16;

/// Vertical padding inside the row, both sides together. The 16:9 banner is
/// this much shorter than the row, which is what actually decides the width.
const double appRowVerticalPadding = 16;

/// Poster size shipped with the shrine row. The home scales both axes by the
/// same factor when a short 16:9 screen cannot keep this height.
const double shrinePosterWidth = 156;
const double shrinePosterHeight = 248;

/// How many app tiles fit in a row before the "more" tile takes the last slot.
///
/// [reservedSlots] are tiles that are not apps (the inputs tile). An unbounded
/// width shows every app. Order is unchanged: the hidden tail is the same
/// sequence, just not drawn in the row.
int visibleAppCount({
  required double maxWidth,
  required double rowHeight,
  required int total,
  int reservedSlots = 0,
}) {
  if (total <= 0) {
    return 0;
  }
  final double cardHeight = max(1, rowHeight - appRowVerticalPadding);
  final double cardWidth = cardHeight * 16 / 9;
  final double slot = cardWidth + appRowCardGap;
  if (!maxWidth.isFinite || slot <= 0) {
    return total;
  }
  final int fit = max(0, ((maxWidth - appRowListPadding) / slot).floor());
  final int appSlots = max(0, fit - reservedSlots);
  if (appSlots <= 0) {
    return 1;
  }
  if (total <= appSlots) {
    return total;
  }
  // The overflow tile takes one slot, and it has to stay on screen together
  // with the reserved tiles. A very narrow row may show only the overflow.
  final int withOverflow = appSlots - 1;
  return withOverflow < 1 ? 0 : withOverflow;
}

/// Row height whose banners leave [slots] places across [rowWidth].
double rowHeightForSlots(double rowWidth, {int slots = 9}) {
  if (!rowWidth.isFinite || rowWidth <= appRowListPadding || slots <= 0) {
    return 110;
  }
  final double slot = (rowWidth - appRowListPadding) / slots;
  // One pixel under the slot so floor() still counts [slots] after rounding.
  final double cardWidth = max(24, slot - appRowCardGap - 1);
  final double cardHeight = cardWidth * 9 / 16;
  return cardHeight + appRowVerticalPadding;
}

/// App-row height for the home column. Wide enough for nine 16:9 slots
/// (eight banners plus the overflow tile) and short enough that the
/// recommendations block keeps the rest of a 16:9 screen.
double homeRowHeight({
  required double rowWidth,
  required double bodyHeight,
  required int rowCount,
  int slots = 9,
}) {
  final double fromWidth = rowHeightForSlots(rowWidth, slots: slots);
  final int rows = max(1, rowCount);
  const double chromePerRow = 34;
  final double recShare = bodyHeight * 0.42;
  final double budget = (bodyHeight - recShare - rows * chromePerRow) / rows;
  final double chosen =
      budget.isFinite && budget > 0 ? min(fromWidth, budget) : fromWidth;
  return chosen.clamp(44.0, 110.0);
}
