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

    final TextStyle themeBody = Theme.of(context).textTheme.bodyMedium ??
        EmeraldShrine.body(color: EmeraldShrine.text);
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: themeBody.copyWith(
          decoration: TextDecoration.none,
          color: EmeraldShrine.text,
          fontFamily: EmeraldShrine.interFamily,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            // About 5% so a TV's overscan does not clip the clock or the panel.
            final double inset = width * 0.05;
            final Offset wander = dreamDriftOffset(drift.value);
            return IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EmeraldBackdrop(poll: widget.animate, clock: widget.clock),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.05,
                        colors: [Color(0x000E1111), Color(0xA60E1111)],
                        stops: [0.45, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(inset, inset, inset, inset),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Transform.translate(
                            offset: Offset(
                              wander.dx.clamp(-inset * 0.35, inset * 0.35),
                              wander.dy.clamp(-inset * 0.25, inset * 0.25),
                            ),
                            child: _DreamClock(now: _now),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.topRight,
                          child: _DreamStatus(),
                        ),
                        if (item != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 1200),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _DreamCard(
                                key: ValueKey<String>(
                                    '${item.title}-${_index % widget.items.length}'),
                                item: item,
                                maxWidth: (width - inset * 2) * 0.62,
                                duration: widget.slideDuration,
                                animate: widget.animate,
                                onFinished: _advance,
                              ),
                            ),
                          ),
                        const Align(
                          alignment: Alignment.bottomLeft,
                          child: _UnlockHint(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: EmeraldShrine.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              'Pantalla bloqueada',
              style: EmeraldShrine.body(
                fontSize: 16,
                color: EmeraldShrine.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$hour:$minute',
          style: EmeraldShrine.posterTitle(fontSize: 64),
        ),
        const SizedBox(height: 4),
        Text(
          formatShrineDate(now),
          style: EmeraldShrine.body(
              fontSize: 22, color: EmeraldShrine.secondaryText),
        ),
      ],
    );
  }
}

class _DreamStatus extends StatelessWidget {
  const _DreamStatus();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi, color: EmeraldShrine.text, size: 22),
        SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0x55F3F8F6)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.settings_outlined,
                color: EmeraldShrine.text, size: 20),
          ),
        ),
      ],
    );
  }
}

class _UnlockHint extends StatelessWidget {
  const _UnlockHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EmeraldShrine.accent, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'OK',
              style: EmeraldShrine.body(
                  fontSize: 16, color: EmeraldShrine.accent),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Pulsa OK para desbloquear',
          style: EmeraldShrine.body(
              fontSize: 18, color: EmeraldShrine.text),
        ),
      ],
    );
  }
}

class _DreamCard extends StatefulWidget {
  final Recommendation item;
  final double maxWidth;
  final Duration duration;
  final bool animate;

  /// Returns true when the parent replaced this card with the next item.
  final bool Function() onFinished;

  const _DreamCard({
    super.key,
    required this.item,
    required this.maxWidth,
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
    const double posterWidth = 168;
    const double posterHeight = 252;
    return SizedBox(
      key: const Key('dream-panel'),
      width: widget.maxWidth,
      height: posterHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: posterWidth * 0.62,
            right: 0,
            top: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xC0141C18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x332FD08C)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(78, 16, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      key: const Key('dream-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EmeraldShrine.posterTitle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    _PlatformPill(platform: item.platform),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      key: const Key('dream-description'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: EmeraldShrine.body(
                        fontSize: 15,
                        color: EmeraldShrine.secondaryText,
                      ),
                    ),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _GenreRow(genres: item.genres),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _Poster(item: item, progress: progress),
          ),
        ],
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
        // The green ring stays still. Ken Burns only moves the picture inside it.
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmeraldShrine.posterRadius),
            border: Border.all(color: EmeraldShrine.accent, width: 2.5),
            boxShadow: EmeraldShrine.focusShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(EmeraldShrine.posterRadius - 2),
              child: SizedBox(
                width: 163,
                height: 247,
                child: Transform.translate(
                  offset: dreamPosterShift(t),
                  child: Transform.scale(
                    scale: dreamPosterScale(t),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        cacheWidth: 336,
        cacheHeight: 472,
        gaplessPlayback: true,
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

class _PlatformPill extends StatelessWidget {
  final String platform;

  const _PlatformPill({required this.platform});

  @override
  Widget build(BuildContext context) {
    final String? icon = platformIconAsset(platform);
    return Container(
      key: const Key('dream-platform'),
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 4, 3, 10, 3),
      decoration: BoxDecoration(
        color: const Color(0xCC0E1111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Image.asset(
              icon,
              width: 14,
              height: 14,
              cacheWidth: 32,
              cacheHeight: 32,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              platform,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EmeraldShrine.body(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreRow extends StatelessWidget {
  final List<String> genres;

  const _GenreRow({required this.genres});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('dream-genres'),
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final String genre in genres) _GenreChip(genre: genre),
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String genre;

  const _GenreChip({required this.genre});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_genreIcon(genre), size: 14, color: EmeraldShrine.secondaryText),
            const SizedBox(width: 6),
            Text(
              genre,
              style: EmeraldShrine.body(
                  fontSize: 13, color: EmeraldShrine.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _genreIcon(String genre) {
  final String name = genre.toLowerCase();
  if (name.contains('acci')) {
    return Icons.sports_martial_arts;
  }
  if (name.contains('anime')) {
    return Icons.movie_filter_outlined;
  }
  if (name.contains('romance') || name.contains('amor')) {
    return Icons.favorite_border;
  }
  if (name.contains('comedia')) {
    return Icons.sentiment_satisfied_alt_outlined;
  }
  return Icons.local_offer_outlined;
}
