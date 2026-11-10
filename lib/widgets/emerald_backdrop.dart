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

import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_lighting.dart';
import 'package:flutter/material.dart';

/// Shrine plate, or the user's own photo when one is set.
///
/// The time-of-day veil is a flat color, animated only when the part of
/// day changes. The legibility gradient is a static decoration, not a blur.
class EmeraldBackdrop extends StatefulWidget {
  final ImageProvider? userWallpaper;
  final DateTime Function()? clock;
  final Duration pollInterval;
  final bool poll;
  final Future<bool> Function(String asset)? assetExists;

  const EmeraldBackdrop({
    super.key,
    this.userWallpaper,
    this.clock,
    this.pollInterval = shrineLightingPollInterval,
    this.poll = true,
    this.assetExists,
  });

  @override
  State<EmeraldBackdrop> createState() => _EmeraldBackdropState();
}

class _EmeraldBackdropState extends State<EmeraldBackdrop> {
  late ShrineLighting _lighting;
  String _asset = shrineDayAsset;
  Timer? _timer;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  bool get _themed => widget.userWallpaper == null;

  @override
  void initState() {
    super.initState();
    _lighting = ShrineLighting.at(_now());
    if (_themed) {
      _resolveAsset();
      if (widget.poll) {
        _timer = Timer.periodic(widget.pollInterval, (_) => _onTick());
      }
    }
  }

  @override
  void didUpdateWidget(EmeraldBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_themed) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final ShrineLighting next = ShrineLighting.at(_now());
    if (next.part != _lighting.part) {
      _lighting = next;
      _resolveAsset();
    }
    if (_timer == null && widget.poll) {
      _timer = Timer.periodic(widget.pollInterval, (_) => _onTick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resolveAsset() async {
    final String asset = await resolveShrineAsset(
      _lighting.part,
      widget.assetExists ?? bundledShrineAssetExists,
    );
    if (!mounted || asset == _asset) {
      return;
    }
    setState(() => _asset = asset);
  }

  void _onTick() {
    final ShrineLighting next = ShrineLighting.at(_now());
    if (next.part == _lighting.part) {
      return;
    }
    setState(() => _lighting = next);
    _resolveAsset();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final int cacheWidth = (size.width * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 1920);

    return RepaintBoundary(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_themed)
              AnimatedSwitcher(
                duration: shrineLightingFade,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Image.asset(
                  _asset,
                  key: ValueKey<String>(_asset),
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  cacheWidth: cacheWidth,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: EmeraldShrine.background),
                ),
              )
            else
              Image(
                key: const Key('background'),
                image: widget.userWallpaper!,
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
                gaplessPlayback: true,
              ),
            if (_themed) ShrineTintVeil(tint: _lighting.tint),
            const _LegibilityScrim(),
          ],
        ),
      ),
    );
  }
}

/// Flat time-of-day color. Public so tests can read the active tint.
class ShrineTintVeil extends StatelessWidget {
  final Color tint;

  const ShrineTintVeil({super.key, required this.tint});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: shrineLightingFade,
        curve: Curves.easeInOut,
        color: tint,
      ),
    );
  }
}

class _LegibilityScrim extends StatelessWidget {
  const _LegibilityScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xC40E1111),
              Color(0x1A0E1111),
              Color(0x330E1111),
              Color(0xB30E1111),
            ],
            stops: [0.0, 0.24, 0.58, 1.0],
          ),
        ),
      ),
    );
  }
}
