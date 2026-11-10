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

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/tv_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class RecommendationsSettings extends StatefulWidget {
  const RecommendationsSettings({super.key});

  @override
  State<RecommendationsSettings> createState() => _RecommendationsSettingsState();
}

class _RecommendationsSettingsState extends State<RecommendationsSettings> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: context.read<SettingsService>().recommendationsFeedUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settings, _) => Column(
        children: [
          RoundedSwitchListTile(
            value: settings.showRecommendations,
            onChanged: (value) => settings.setShowRecommendations(value),
            title: Text(localizations.showRecommendations, style: Theme.of(context).textTheme.bodyMedium),
            secondary: const Icon(Icons.live_tv_outlined),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TvTextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: localizations.recommendationsFeedUrl),
              onFieldSubmitted: (value) => settings.setRecommendationsFeedUrl(value),
            ),
          ),
        ],
      ),
    );
  }
}
