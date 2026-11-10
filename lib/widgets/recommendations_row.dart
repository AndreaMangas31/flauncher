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

import 'dart:math';

import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/widgets/app_row_fit.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/section_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Counts poster builds so a focus move can be checked without a profiler.
int recommendationPosterBuilds = 0;

/// Portrait posters pinned under the categories. The strip under the row
/// follows whichever poster has focus.
class RecommendationsRow extends StatefulWidget {
  const RecommendationsRow({super.key});

  @override
  State<RecommendationsRow> createState() => _RecommendationsRowState();
}

class _RecommendationsRowState extends State<RecommendationsRow> {
  final ValueNotifier<int> _focusedIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _focusedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<RecommendationsService, List<Recommendation>>(
      selector: (_, service) => service.items,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        if (_focusedIndex.value >= items.length) {
          _focusedIndex.value = 0;
        }

        final AppLocalizations localizations = AppLocalizations.of(context)!;
        // Posters keep their 156×248 proportion and only shrink when the
        // column is shorter than that. The detail strip stays under them.
        return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    localizations.recommendationsRow,
                    mark: const ToriiMark(),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, posterConstraints) {
                        final double available = posterConstraints.maxHeight.isFinite
                            ? posterConstraints.maxHeight
                            : shrinePosterHeight;
                        final double posterHeight = min(
                            shrinePosterHeight, max(1, available));
                        final double posterWidth = posterHeight *
                            (shrinePosterWidth / shrinePosterHeight);
                        return Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            height: posterHeight,
                            child: ListView.separated(
                              key: const Key('recommendation-posters'),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              scrollDirection: Axis.horizontal,
                              // One extra poster, not the whole feed.
                              cacheExtent: 80,
                              clipBehavior: Clip.none,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) =>
                                  _RecommendationPoster(
                                item: items[index],
                                width: posterWidth,
                                autofocus: index == 0,
                                onFocused: () {
                                  if (_focusedIndex.value != index) {
                                    _focusedIndex.value = index;
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _focusedIndex,
                    builder: (context, index, _) {
                      final int safe = index >= items.length ? 0 : index;
                      return _DetailStrip(item: items[safe]);
                    },
                  ),
                ],
              ),
            );
      },
    );
  }
}

class _DetailStrip extends StatelessWidget {
  final Recommendation item;

  const _DetailStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('recommendation-detail'),
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: EmeraldShrine.surface.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmeraldShrine.accent, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: Text(
              item.title,
              key: const Key('recommendation-detail-title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: EmeraldShrine.posterTitle(fontSize: 20),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: EmeraldShrine.accent.withOpacity(0.85),
          ),
          Expanded(
            child: Text(
              item.description,
              key: const Key('recommendation-detail-description'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: EmeraldShrine.body(
                  fontSize: 15, color: EmeraldShrine.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPoster extends StatefulWidget {
  final Recommendation item;
  final double width;
  final bool autofocus;
  final VoidCallback onFocused;

  const _RecommendationPoster({
    required this.item,
    required this.width,
    required this.autofocus,
    required this.onFocused,
  });

  @override
  State<_RecommendationPoster> createState() => _RecommendationPosterState();
}

class _RecommendationPosterState extends State<_RecommendationPoster> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    recommendationPosterBuilds++;
    final Recommendation item = widget.item;
    return RepaintBoundary(
      child: EnsureVisible(
      alignment: 0.5,
      child: AnimatedScale(
        scale: _focused ? 1.05 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmeraldShrine.posterRadius),
            boxShadow: _focused ? EmeraldShrine.focusShadows : const [],
          ),
          child: Material(
            color: EmeraldShrine.surface,
            borderRadius: BorderRadius.circular(EmeraldShrine.posterRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              autofocus: widget.autofocus,
              focusColor: Colors.transparent,
              onFocusChange: (focused) {
                setState(() => _focused = focused);
                if (focused) {
                  widget.onFocused();
                }
              },
              onTap: () => context.read<RecommendationsService>().open(item),
              child: DecoratedBox(
                key: _focused ? const Key('emerald-focus-border') : null,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(EmeraldShrine.posterRadius),
                  border: Border.all(
                    color: _focused ? EmeraldShrine.accent : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _poster(item),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x000E1111),
                            Color(0x660E1111),
                            Color(0xF20E1111)
                          ],
                          stops: [0.42, 0.72, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: EmeraldShrine.posterTitle(fontSize: 15).copyWith(
                              shadows: const [
                                Shadow(color: Color(0xCC000000), blurRadius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _PlatformChip(platform: item.platform),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _poster(Recommendation item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double ratio = MediaQuery.devicePixelRatioOf(context);
        final int cacheWidth = (constraints.maxWidth * ratio).round().clamp(1, 480);
        final int cacheHeight =
            (constraints.maxHeight * ratio).round().clamp(1, 720);
        return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      gaplessPlayback: false,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => _placeholder(item),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const ColoredBox(color: EmeraldShrine.surface);
      },
    );
      },
    );
  }

  Widget _placeholder(Recommendation item) {
    return ColoredBox(
      color: EmeraldShrine.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            item.platform,
            textAlign: TextAlign.center,
            style: EmeraldShrine.body(
                fontSize: 13, color: EmeraldShrine.secondaryText),
          ),
        ),
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final String platform;

  const _PlatformChip({required this.platform});

  @override
  Widget build(BuildContext context) {
    final String? icon = platformIconAsset(platform);
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 8 : 3, 2, 8, 2),
      decoration: BoxDecoration(
        color: const Color(0xCC0E1111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.32)),
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
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              platform,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EmeraldShrine.body(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small shrine gate drawn next to the recommendations heading.
class ToriiMark extends StatelessWidget {
  const ToriiMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(16, 14),
      painter: _ToriiPainter(),
    );
  }
}

class _ToriiPainter extends CustomPainter {
  const _ToriiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0xFFE25B4A);
    final double w = size.width;
    final double h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h * 0.22),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.34, w * 0.84, h * 0.14), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.12, h * 0.72), paint);
    canvas.drawRect(Rect.fromLTWH(w * 0.70, h * 0.28, w * 0.12, h * 0.72), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
