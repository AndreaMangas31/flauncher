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

import 'package:flauncher/home_focus.dart';
import 'package:flauncher/models/hdmi_input.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Opens the HDMI picker. A device with no ports still gets the panel, and
/// choosing the system button falls through to the television's inputs UI.
Future<void> showInputsPicker(BuildContext context) async {
  List<HdmiInput> inputs = const [];
  try {
    final List<Map<String, String>> rows =
        await context.read<AppsService>().hdmiInputs();
    inputs = [
      for (final Map<String, String> row in rows) HdmiInput.fromMap(row)
    ];
  } catch (_) {
    inputs = const [];
  }
  if (!context.mounted) {
    return;
  }

  final AppsService apps = context.read<AppsService>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => InputsPicker(
      inputs: inputs,
      onSelected: (HdmiInput input) {
        Navigator.of(dialogContext).pop();
        apps.openHdmiInput(input.id);
      },
      onOpenSystem: () {
        Navigator.of(dialogContext).pop();
        apps.openHdmiInput('');
      },
    ),
  );
}

class InputsPicker extends StatelessWidget {
  final List<HdmiInput> inputs;
  final ValueChanged<HdmiInput> onSelected;
  final VoidCallback onOpenSystem;

  const InputsPicker({
    super.key,
    required this.inputs,
    required this.onSelected,
    required this.onOpenSystem,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          key: const Key('inputs-picker'),
          width: 420,
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(
            color: EmeraldShrine.surface.withOpacity(0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EmeraldShrine.accent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(localizations.inputs,
                  style: EmeraldShrine.heading(fontSize: 22)),
              const SizedBox(height: 12),
              if (inputs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    localizations.noHdmiInputs,
                    key: const Key('inputs-empty'),
                    style:
                        EmeraldShrine.body(color: EmeraldShrine.secondaryText),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: inputs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final HdmiInput input = inputs[index];
                      return _InputTile(
                        label: input.label,
                        autofocus: index == 0,
                        onPressed: () => onSelected(input),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('inputs-system'),
                  onPressed: onOpenSystem,
                  child: Text(localizations.openSystemInputs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  final String label;
  final bool autofocus;
  final VoidCallback onPressed;

  const _InputTile({
    required this.label,
    required this.autofocus,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      autofocus: autofocus,
      style: ButtonStyle(
        alignment: Alignment.centerLeft,
        foregroundColor: const WidgetStatePropertyAll(EmeraldShrine.text),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return EmeraldShrine.accent.withOpacity(0.18);
          }
          return Colors.white.withOpacity(0.04);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: EmeraldShrine.accent, width: 2);
          }
          return BorderSide(color: Colors.white.withOpacity(0.10));
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: EmeraldShrine.body(fontSize: 16)),
    );
  }
}

/// First tile of the Apps row. Same 16:9 slot as a banner.
class InputsTile extends StatefulWidget {
  const InputsTile({super.key});

  @override
  State<InputsTile> createState() => _InputsTileState();
}

class _InputsTileState extends State<InputsTile> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'entradas');
  HomeReturnController? _home;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final HomeReturnController? next = HomeReturn.maybeOf(context);
    if (next == _home) {
      return;
    }
    _home?.detachEntradas(_focusNode);
    _home = next;
    _home?.attachEntradas(_focusNode);
  }

  @override
  void dispose() {
    _home?.detachEntradas(_focusNode);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
            _focused ? 1.06 : 1, _focused ? 1.06 : 1, 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
          boxShadow: _focused ? EmeraldShrine.focusShadows : const [],
        ),
        child: Material(
          color: EmeraldShrine.surfaceTint,
          borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            focusNode: _focusNode,
            autofocus: true,
            focusColor: Colors.transparent,
            onFocusChange: (focused) {
              setState(() => _focused = focused);
              if (focused) {
                // Pin the tile to the start of the row. Centering it would
                // leave a gap where the row should begin.
                Scrollable.ensureVisible(
                  context,
                  alignment: 0,
                  duration: const Duration(milliseconds: 100),
                );
              }
            },
            onTap: () => showInputsPicker(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EmeraldShrine.tileRadius),
                border: Border.all(
                  color: _focused
                      ? EmeraldShrine.accent
                      : Colors.white.withOpacity(0.10),
                  width: _focused ? 2.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.input,
                      color: EmeraldShrine.accent, size: _focused ? 22 : 20),
                  const SizedBox(height: 4),
                  Text(
                    localizations.inputs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EmeraldShrine.heading(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
