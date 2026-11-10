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

import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/widgets/emerald_backdrop.dart';
import 'package:flutter/material.dart';

/// How far the clock wanders, in logical pixels, for a progress in 0..1.
/// The path is a slow diagonal so no glyph sits on the same pixels.
Offset dreamDriftOffset(double t) {
  final double centered = ((t.clamp(0.0, 1.0)) - 0.5) * 2;
  return Offset(centered * 36, centered * 22);
}

/// Slow zoom used by the poster. The image itself is decoded once; this is
/// only a transform, and it stays under 8% so the layer stays small.
double dreamPosterScale(double t) => 1.0 + (0.06 * t.clamp(0.0, 1.0));

Offset dreamPosterShift(double t) {
  final double centered = t.clamp(0.0, 1.0) - 0.5;
  return Offset(centered * 16, centered * 10);
}

/// Emerald Shrine screensaver. Not interactive: the Android dream finishes
/// on any key. Motion is a couple of slow transforms, not a blur.
class SenkuDream extends StatefulWidget {
  final List<Recommendation> items;
  final DateTime Function()? clock;
  final Duration slideDuration;
  final Duration driftPeriod;
  final bool animate;

  const SenkuDream({
    super.key,
    this.items = const [],
    this.clock,
    this.slideDuration = const Duration(seconds: 24),
    this.driftPeriod = const Duration(minutes: 3),
    this.animate = true,
  });

  @override
  State<SenkuDream> createState() => _SenkuDreamState();
}

class _SenkuDreamState extends State<SenkuDream> with TickerProviderStateMixin {
  AnimationController? _drift;
  Timer? _minute;
  DateTime _now = DateTime.now();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _now = widget.clock?.call() ?? DateTime.now();
    if (widget.animate && widget.clock == null) {
      _minute = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _now = DateTime.now());
      });
    }
    if (widget.animate) {
      _drift = AnimationController(vsync: this, duration: widget.driftPeriod)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _minute?.cancel();
    _drift?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Recommendation? item = widget.items.isEmpty
        ? null
        : widget.items[_index % widget.items.length];
    final Animation<double> drift = _drift ?? const AlwaysStoppedAnimation(0.5);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          EmeraldBackdrop(poll: widget.animate, clock: widget.clock),
          AnimatedBuilder(
            animation: drift,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: dreamDriftOffset(drift.value) + const Offset(72, 64),
                  child: child,
                ),
              );
            },
            child: _DreamClock(now: _now),
          ),
          if (item != null)
            AnimatedBuilder(
              animation: drift,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.bottomLeft,
                  child: Transform.translate(
                    offset:
                        -dreamDriftOffset(drift.value) + const Offset(72, -56),
                    child: child,
                  ),
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _DreamCard(
                  key: ValueKey<String>(
                      '${item.title}-${_index % widget.items.length}'),
                  item: item,
                  duration: widget.slideDuration,
                  animate: widget.animate,
                  onFinished: _advance,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _advance() {
    if (!mounted || widget.items.length < 2) {
      return false;
    }
    setState(() => _index = (_index + 1) % widget.items.length);
    return true;
  }
}

class _DreamClock extends StatelessWidget {
  final DateTime now;

  const _DreamClock({required this.now});

  @override
  Widget build(BuildContext context) {
    final String hour = now.hour.toString();
    final String minute = now.minute.toString().padLeft(2, '0');
    return Column(
      key: const Key('dream-clock'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$hour:$minute',
          style: EmeraldShrine.heading(fontSize: 84),
        ),
        const SizedBox(height: 8),
        Text(
          formatShrineDate(now),
          style: EmeraldShrine.body(
              fontSize: 28, color: EmeraldShrine.secondaryText),
        ),
      ],
    );
  }
}

class _DreamCard extends StatefulWidget {
  final Recommendation item;
  final Duration duration;
  final bool animate;

  /// Returns true when the parent replaced this card with the next item.
  final bool Function() onFinished;

  const _DreamCard({
    super.key,
    required this.item,
    required this.duration,
    required this.animate,
    required this.onFinished,
  });

  @override
  State<_DreamCard> createState() => _DreamCardState();
}

class _DreamCardState extends State<_DreamCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _slide;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      return;
    }
    _slide = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) {
          return;
        }
        final bool replaced = widget.onFinished();
        if (!replaced && mounted) {
          _slide?.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _slide?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> progress =
        _slide ?? const AlwaysStoppedAnimation(0);
    final Recommendation item = widget.item;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EmeraldShrine.surface.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Poster(item: item, progress: progress),
              const SizedBox(width: 20),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      key: const Key('dream-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EmeraldShrine.posterTitle(fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                    _Chip(platform: item.platform),
                    const SizedBox(height: 12),
                    Text(
                      item.description,
                      key: const Key('dream-description'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: EmeraldShrine.body(
                        fontSize: 16,
                        color: EmeraldShrine.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final Recommendation item;
  final Animation<double> progress;

  const _Poster({required this.item, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final double t = progress.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(EmeraldShrine.posterRadius),
          child: SizedBox(
            width: 168,
            height: 252,
            child: Transform.translate(
              offset: dreamPosterShift(t),
              child: Transform.scale(
                scale: dreamPosterScale(t),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        cacheWidth: 336,
        cacheHeight: 504,
        gaplessPlayback: false,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) =>
            const ColoredBox(color: EmeraldShrine.surface),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const ColoredBox(color: EmeraldShrine.surface);
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String platform;

  const _Chip({required this.platform});

  @override
  Widget build(BuildContext context) {
    final Color color = recommendationPlatformColor(platform);
    return Container(
      key: const Key('dream-platform'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: color.computeLuminance() < 0.2
            ? Border.all(color: Colors.white.withOpacity(0.28))
            : null,
      ),
      child: Text(
        platform,
        style: EmeraldShrine.body(fontSize: 13, color: Colors.white),
      ),
    );
  }
}
