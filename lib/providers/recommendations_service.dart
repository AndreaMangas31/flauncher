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
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RecommendationFetcher = Future<String?> Function(Uri uri);

const String recommendationsCacheKey = "recommendations_cache";
const Duration recommendationsRefreshInterval = Duration(hours: 6);

/// Minimum gap between Friday resume fetches. The weekly feed should show
/// up on the next return home, not on every trip back to the launcher.
const Duration recommendationsFridayResumeInterval = Duration(minutes: 15);

class RecommendationsService extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences _preferences;
  final SettingsService _settings;
  final FLauncherChannel _channel;
  final RecommendationFetcher _fetcher;
  final DateTime Function() _now;

  RecommendationFeed? _feed;
  Timer? _timer;
  String? _loadedUrl;
  bool _refreshing = false;
  DateTime? _lastFetchAttempt;

  RecommendationsService(
    this._preferences,
    this._settings,
    this._channel, {
    RecommendationFetcher? fetcher,
    bool periodicRefresh = true,
    DateTime Function()? now,
  })  : _fetcher = fetcher ?? _fetchFeed,
        _now = now ?? DateTime.now {
    _restoreCache();
    _settings.addListener(_onSettingsChanged);
    // The dream isolate never constructs this service (it only reads the
    // cached feed), so the resume observer does not run there.
    WidgetsBinding.instance.addObserver(this);
    if (periodicRefresh) {
      _timer = Timer.periodic(recommendationsRefreshInterval, (_) {
        refresh();
      });
    }
    // The cached feed is already on screen. The network refresh waits until
    // the first frame so it does not compete with the app list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOnFridayResume();
    }
  }

  // Friday return home. The feed is published that day in Europe/Madrid;
  // the television's local clock is the one we follow. The 6-hour timer
  // still runs every day. This only avoids waiting out the rest of that
  // window, and it will not start another fetch within
  // recommendationsFridayResumeInterval of the last attempt.
  void _refreshOnFridayResume() {
    final DateTime now = _now();
    if (now.weekday != DateTime.friday) {
      return;
    }
    final DateTime? lastAttempt = _lastFetchAttempt;
    if (lastAttempt != null && now.difference(lastAttempt) < recommendationsFridayResumeInterval) {
      return;
    }
    refresh();
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
    // Count a failed try as well as a success, so Friday resumes do not
    // retry in a loop while the network is down.
    _lastFetchAttempt = _now();
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
