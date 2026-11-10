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

import 'dart:convert';

class Recommendation {
  final String title;
  final String description;
  final String platform;
  final String type;
  final String status;
  final String imageUrl;
  final String? deepLink;
  final String? packageName;

  /// Labels from the feed. Empty when the feed does not include any.
  final List<String> genres;

  const Recommendation({
    required this.title,
    required this.description,
    required this.platform,
    required this.type,
    required this.status,
    required this.imageUrl,
    this.deepLink,
    this.packageName,
    this.genres = const [],
  });
}

class RecommendationFeed {
  final DateTime updatedAt;
  final List<Recommendation> items;

  const RecommendationFeed({required this.updatedAt, required this.items});

  /// Returns null when [source] is not a usable feed. Never throws.
  static RecommendationFeed? tryParse(String source) {
    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! Map) {
        return null;
      }

      final dynamic updatedAtRaw = decoded["updatedAt"];
      final dynamic itemsRaw = decoded["items"];
      if (updatedAtRaw is! String || itemsRaw is! List) {
        return null;
      }

      final DateTime updatedAt = DateTime.parse(updatedAtRaw);
      final List<Recommendation> items = [];
      for (final dynamic entry in itemsRaw) {
        final Recommendation? item = _parseItem(entry);
        if (item != null) {
          items.add(item);
        }
      }

      return RecommendationFeed(updatedAt: updatedAt, items: items);
    } catch (_) {
      return null;
    }
  }

  static Recommendation? _parseItem(dynamic entry) {
    if (entry is! Map) {
      return null;
    }

    final String? title = _text(entry["title"]);
    final String? description = _text(entry["description"]);
    final String? platform = _text(entry["platform"]);
    final String? type = _text(entry["type"]);
    final String? status = _text(entry["status"]);
    final String? imageUrl = _text(entry["imageUrl"]);
    if (title == null ||
        description == null ||
        platform == null ||
        type == null ||
        status == null ||
        imageUrl == null) {
      return null;
    }

    return Recommendation(
      title: title,
      description: description,
      platform: platform,
      type: type,
      status: status,
      imageUrl: imageUrl,
      deepLink: _optionalText(entry["deepLink"]),
      packageName: _optionalText(entry["packageName"]),
      genres: _genres(entry["genres"]),
    );
  }

  static List<String> _genres(dynamic value) {
    if (value is! List) {
      return const [];
    }
    final List<String> genres = [];
    for (final dynamic entry in value) {
      final String? genre = _text(entry);
      if (genre != null) {
        genres.add(genre);
      }
    }
    return genres;
  }

  static String? _text(dynamic value) {
    if (value is! String) {
      return null;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String? _optionalText(dynamic value) {
    if (value == null) {
      return null;
    }
    return _text(value);
  }
}
