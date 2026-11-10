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

import 'dart:io';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService extends ChangeNotifier {
  final FLauncherChannel _fLauncherChannel;
  final SettingsService _settingsService;

  late File _wallpaperFile;

  ImageProvider? _wallpaper;
  bool _ready = false;

  ImageProvider? get wallpaper => _wallpaper;

  /// False until the saved photo has been looked up, so the shrine does not
  /// flash over a wallpaper that is about to appear.
  bool get ready => _ready;

  /// True when the user picked a gradient in settings. That choice replaces
  /// the shrine; a null uuid means "keep the theme default".
  bool get hasCustomGradient => _settingsService.gradientUuid != null;

  FLauncherGradient get gradient => FLauncherGradients.all.firstWhere(
        (gradient) => gradient.uuid == _settingsService.gradientUuid,
        orElse: () => FLauncherGradients.greatWhale,
      );

  WallpaperService(this._fLauncherChannel, this._settingsService)
      : _wallpaper = null {
    _init();
  }

  Future<void> _init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _wallpaperFile = File("${directory.path}/wallpaper");
      if (await _wallpaperFile.exists()) {
        _wallpaper = FileImage(_wallpaperFile);
      }
    } catch (_) {
      // Storage can be missing on a fresh profile. The shrine still works.
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> pickWallpaper() async {
    if (!await _fLauncherChannel.checkForGetContentAvailability()) {
      throw NoFileExplorerException();
    }

    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      await _wallpaperFile.writeAsBytes(bytes);

      _wallpaper = MemoryImage(bytes);
      notifyListeners();
    }
  }

  Future<void> setGradient(FLauncherGradient fLauncherGradient) async {
    if (await _wallpaperFile.exists()) {
      await _wallpaperFile.delete();
    }

    _wallpaper = null;
    _settingsService.setGradientUuid(fLauncherGradient.uuid);
    notifyListeners();
  }
}

class NoFileExplorerException implements Exception {}
