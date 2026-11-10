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

/// Portrait posters pinned under the categories. The strip under the row
/// follows whichever poster has focus.
class RecommendationsRow extends StatefulWidget {
  const RecommendationsRow({super.key});

  @override
  State<RecommendationsRow> createState() => _RecommendationsRowState();
}

class _RecommendationsRowState extends State<RecommendationsRow> {
  int _focusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Selector<RecommendationsService, List<Recommendation>>(
      selector: (_, service) => service.items,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        if (_focusedIndex >= items.length) {
          _focusedIndex = 0;
        }

        final AppLocalizations localizations = AppLocalizations.of(context)!;
        final Recommendation focused = items[_focusedIndex];
        // Posters keep their 156×248 proportion and only shrink when the
        // column is shorter than that. The detail strip stays under them.
        return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(localizations.recommendationsRow),
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
                                  if (_focusedIndex != index) {
                                    setState(() => _focusedIndex = index);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _DetailStrip(item: focused),
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
          const SizedBox(width: 24),
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
    final Recommendation item = widget.item;
    return EnsureVisible(
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
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(EmeraldShrine.posterRadius),
                  border: Border.all(
                    color: _focused ? EmeraldShrine.accent : Colors.transparent,
                    width: 2,
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
                            Color(0x000E1111),
                            Color(0xF20E1111)
                          ],
                          stops: [0.0, 0.45, 1.0],
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
                            style: EmeraldShrine.posterTitle(fontSize: 15),
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
    );
  }

  Widget _poster(Recommendation item) {
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 360,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _placeholder(item),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const ColoredBox(color: EmeraldShrine.surface);
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
    final Color color = recommendationPlatformColor(platform);
    final bool darkChip = color.computeLuminance() < 0.2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border:
            darkChip ? Border.all(color: Colors.white.withOpacity(0.28)) : null,
      ),
      child: Text(
        platform,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: EmeraldShrine.body(fontSize: 11, color: Colors.white),
      ),
    );
  }
}
