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

/// Fresh-install home screen. Existing databases are left untouched.
const String appsCategoryName = "Apps";
const String musicCategoryName = "YouTube y música";

const String youtubeTvPackage = "com.google.android.youtube.tv";
const String spotifyTvPackage = "com.spotify.tv.android";

/// Sentinel stored on the in-memory app so select launches the tuner intent
/// instead of the package's ordinary leanback activity.
const String liveTvAction = "me.efesser.flauncher.action.LIVE_TV";

/// YouTube and Spotify are the only apps that leave [appsCategoryName].
bool isMusicApp(String packageName) => packageName == youtubeTvPackage || packageName == spotifyTvPackage;

/// YouTube first, then Spotify. Anything else sorts after them.
int musicAppRank(String packageName) {
  if (packageName == youtubeTvPackage) {
    return 0;
  }
  if (packageName == spotifyTvPackage) {
    return 1;
  }
  return 2;
}
