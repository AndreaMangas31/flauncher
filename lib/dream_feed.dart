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

import 'package:flauncher/models/recommendation.dart';

/// Reads the launcher's cached Senku feed. A missing or broken cache is an
/// empty list, so the screensaver still comes up with no network.
List<Recommendation> recommendationsFromCache(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  return RecommendationFeed.tryParse(raw)?.items ?? const [];
}
