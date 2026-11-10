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
import 'dart:io';

import 'package:flauncher/models/recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _requiredItemFields = [
  "title",
  "description",
  "platform",
  "type",
  "status",
  "imageUrl",
];

void main() {
  test("parses the sample feed", () {
    final String source = File("test/fixtures/recommendations.json").readAsStringSync();
    final RecommendationFeed? feed = RecommendationFeed.tryParse(source);

    expect(feed, isNotNull);
    expect(feed!.updatedAt.toUtc(), DateTime.utc(2026, 11, 10));
    expect(feed.items, hasLength(3));
    expect(feed.items.first.platform, "Netflix");
    expect(feed.items.first.type, "serie");
    expect(feed.items.first.status, "en emisión");
    expect(feed.items.first.packageName, "com.netflix.ninja");
    expect(feed.items[1].type, "película");
    expect(feed.items[2].deepLink, isNull);
  });

  test("live feed matches the schema", () {
    final String source = File("recommendations/recommendations.json").readAsStringSync();
    final dynamic decoded = jsonDecode(source);
    expect(decoded, isA<Map>());
    final dynamic items = decoded["items"];
    expect(items, isA<List>());
    expect(items, isNotEmpty);
    expect(decoded["updatedAt"], isA<String>());
    expect((decoded["updatedAt"] as String).trim(), isNotEmpty);

    for (final dynamic item in items) {
      expect(item, isA<Map>());
      for (final String field in _requiredItemFields) {
        expect(item[field], isA<String>(), reason: field);
        expect((item[field] as String).trim(), isNotEmpty, reason: field);
      }
    }

    final RecommendationFeed? feed = RecommendationFeed.tryParse(source);
    expect(feed, isNotNull);
    expect(feed!.items, hasLength(items.length));
  });

  test("rejects invalid feeds and skips broken items", () {
    expect(RecommendationFeed.tryParse("not json"), isNull);
    expect(RecommendationFeed.tryParse('{"items": []}'), isNull);
    expect(RecommendationFeed.tryParse('{"updatedAt": "nope", "items": []}'), isNull);

    final RecommendationFeed? feed = RecommendationFeed.tryParse('''
      {
        "updatedAt": "2026-01-02T03:04:05Z",
        "items": [
          {"title": "Solo el título"},
          {
            "title": "Completa",
            "description": "Descripción corta",
            "platform": "Filmin",
            "type": "película",
            "status": "estreno",
            "imageUrl": "https://example.com/poster.png"
          }
        ]
      }
    ''');

    expect(feed, isNotNull);
    expect(feed!.items, hasLength(1));
    expect(feed.items.single.platform, "Filmin");
    expect(feed.items.single.deepLink, isNull);
    expect(feed.items.single.packageName, isNull);
  });
}
