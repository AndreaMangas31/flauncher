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

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Decode size for a poster. Nearby layouts share one cache entry so a
/// focus change, or a one-line difference in the detail strip, does not
/// allocate a second bitmap.
int stablePosterPixels(double logical, double devicePixelRatio) {
  final int px = (logical * devicePixelRatio).round().clamp(1, 720);
  const int step = 32;
  final int snapped = ((px + step ~/ 2) ~/ step) * step;
  return snapped.clamp(step, 720);
}

typedef PosterImageLoader = Future<ImageProvider<Object>> Function(
  String url,
  int width,
  int height,
);

/// Test hook. Production downloads once and reuses the file.
PosterImageLoader posterImageLoader = loadPosterImage;

final Map<String, Future<ImageProvider<Object>>> _posterProviders = {};

/// Same url and decode size always return the same provider instance.
Future<ImageProvider<Object>> posterProvider(String url, int width, int height) {
  final String key = '$width x $height|$url';
  return _posterProviders.putIfAbsent(key, () => posterImageLoader(url, width, height));
}

void debugResetPosterImages() {
  _posterProviders.clear();
  posterImageLoader = loadPosterImage;
}

/// Network posters are written under the temp directory so a later focus
/// move decodes from disk instead of downloading again.
Future<ImageProvider<Object>> loadPosterImage(String url, int width, int height) async {
  final File file = await _cachedFile(url, width, height);
  return ResizeImage(
    FileImage(file),
    width: width,
    height: height,
    policy: ResizeImagePolicy.fit,
  );
}

Future<File> _cachedFile(String url, int width, int height) async {
  final Directory root = await getTemporaryDirectory();
  final Directory folder = Directory('${root.path}/flauncher_posters');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final File file = File('${folder.path}/${width}x$height-${_fnv(url)}.img');
  if (await file.exists() && await file.length() > 32) {
    return file;
  }

  final HttpClient client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  try {
    final HttpClientRequest request =
        await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
    final HttpClientResponse response =
        await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      await response.drain<void>();
      throw HttpException('poster ${response.statusCode}', uri: Uri.parse(url));
    }
    final List<int> bytes = await response.fold<List<int>>(<int>[], (previous, chunk) {
      previous.addAll(chunk);
      return previous;
    });
    await file.writeAsBytes(bytes, flush: true);
    unawaited(_trimFolder(folder));
    return file;
  } finally {
    client.close(force: true);
  }
}

Future<void> _trimFolder(Directory folder) async {
  final List<File> files = folder.listSync().whereType<File>().toList();
  if (files.length <= 40) {
    return;
  }
  files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
  for (final File extra in files.take(files.length - 40)) {
    try {
      await extra.delete();
    } catch (_) {}
  }
}

int _fnv(String value) {
  var hash = 0x811c9dc5;
  for (final int byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
