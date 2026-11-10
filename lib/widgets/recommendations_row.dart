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

import 'package:flauncher/models/recommendation.dart';
import 'package:flauncher/providers/recommendations_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Non-editable row pinned under every launcher category.
class RecommendationsRow extends StatelessWidget {
  const RecommendationsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<RecommendationsService, List<Recommendation>>(
      selector: (_, service) => service.items,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final AppLocalizations localizations = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  localizations.recommendationsRow,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    shadows: const [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 8)],
                  ),
                ),
              ),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _RecommendationCard(item: items[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final Recommendation item;

  const _RecommendationCard({required this.item});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Recommendation item = widget.item;
    return EnsureVisible(
      alignment: 0.5,
      child: SizedBox(
        width: 148,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onFocusChange: (focused) => setState(() => _focused = focused),
            onTap: () => context.read<RecommendationsService>().open(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.diagonal3Values(_focused ? 1.04 : 1, _focused ? 1.04 : 1, 1),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _focused ? Colors.white : Colors.white24, width: _focused ? 2 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _poster(item),
                        Positioned(
                          top: 6,
                          left: 6,
                          right: 6,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _badge(item.platform),
                          ),
                        ),
                        if (_focused)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.82),
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                item.description,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          "${item.type} · ${item.status}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
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
      errorBuilder: (_, __, ___) => _placeholder(item),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Widget _placeholder(Recommendation item) {
    return ColoredBox(
      color: const Color(0xFF033662),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(item.platform, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _badge(String platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _platformColor(platform),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        platform,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case "netflix":
        return const Color(0xFFE50914);
      case "crunchyroll":
        return const Color(0xFFF47521);
      case "disney+":
        return const Color(0xFF113CCF);
      case "prime video":
        return const Color(0xFF00A8E1);
      case "hbo max":
        return const Color(0xFFB535F6);
      case "filmin":
        return const Color(0xFFFF5A1F);
      default:
        return Colors.black87;
    }
  }
}
