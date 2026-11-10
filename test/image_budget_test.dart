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

import 'package:flauncher/image_budget.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a 1080p plate is about 8 MB and the cache stays under 60 MB', () {
    installImageCacheBudget();
    expect(decodedRgbaBytes(1920, 1080), 8294400);
    expect(
      PaintingBinding.instance.imageCache.maximumSizeBytes,
      imageCacheByteBudget,
    );
    expect(imageCacheByteBudget, inInclusiveRange(40 << 20, 60 << 20));
    clearLauncherImageCache();
  });
}
