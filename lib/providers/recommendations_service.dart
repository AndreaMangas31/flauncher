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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RecommendationFetcher = Future<String?> Function(Uri uri);

const String recommendationsCacheKey = "recommendations_cache";
const Duration recommendationsRefreshInterval = Duration(hours: 6);

class RecommendationsService extends ChangeNotifier {
  final SharedPreferences _preferences;
  final SettingsService _settings;
  final FLauncherChannel _channel;
  final RecommendationFetcher _fetcher;

  RecommendationFeed? _feed;
  Timer? _timer;
  String? _loadedUrl;
  bool _refreshing = false;

  RecommendationsService(
    this._preferences,
    this._settings,
    this._channel, {
    RecommendationFetcher? fetcher,
    bool periodicRefresh = true,
  }) : _fetcher = fetcher ?? _fetchFeed {
    _restoreCache();
    _settings.addListener(_onSettingsChanged);
    if (periodicRefresh) {
      _timer = Timer.periodic(recommendationsRefreshInterval, (_) {
        refresh();
      });
    }
    // The cached feed is already on screen. The network refresh waits until
    // the first frame so it does not compete with the app list.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      refresh();
    });
  }

  bool get enabled => _settings.showRecommendations;

  List<Recommendation> get items {
    if (!_settings.showRecommendations) {
      return const [];
    }
    return _feed?.items ?? const [];
  }

  DateTime? get updatedAt => _settings.showRecommendations ? _feed?.updatedAt : null;

  @override
  void dispose() {
    _timer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> open(Recommendation item) async {
    try {
      await _channel.openRecommendation(item.deepLink, item.packageName);
    } catch (_) {
      // A missing platform app should not take down the launcher.
    }
  }

  Future<void> refresh() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    try {
      final String url = _settings.recommendationsFeedUrl;
      final Uri? uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != "https" && uri.scheme != "http") || uri.host.isEmpty) {
        return;
      }

      final String? body = await _fetcher(uri);
      if (body == null || body.trim().isEmpty) {
        return;
      }

      final RecommendationFeed? parsed = RecommendationFeed.tryParse(body);
      if (parsed == null) {
        return;
      }

      _feed = parsed;
      _loadedUrl = url;
      try {
        await _preferences.setString(recommendationsCacheKey, body);
      } catch (_) {}
      notifyListeners();
    } catch (_) {
      // Keep the last good copy.
    } finally {
      _refreshing = false;
    }
  }

  void _restoreCache() {
    try {
      final String? cached = _preferences.getString(recommendationsCacheKey);
      if (cached == null) {
        return;
      }
      _feed = RecommendationFeed.tryParse(cached);
    } catch (_) {
      _feed = null;
    }
  }

  void _onSettingsChanged() {
    notifyListeners();
    if (_settings.recommendationsFeedUrl != _loadedUrl) {
      refresh();
    }
  }

  static Future<String?> _fetchFeed(Uri uri) async {
    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final HttpClientRequest request = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final HttpClientResponse response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        await response.drain<void>();
        return null;
      }

      const int maxBytes = 1024 * 1024;
      final List<int> bytes = await response.fold<List<int>>(<int>[], (previous, List<int> chunk) {
        if (previous.length > maxBytes) {
          return previous;
        }
        previous.addAll(chunk);
        return previous;
      }).timeout(const Duration(seconds: 12));
      if (bytes.length > maxBytes) {
        return null;
      }
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
