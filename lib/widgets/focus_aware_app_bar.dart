import 'dart:async';

import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/apps_service.dart';
import '../providers/settings_service.dart';
import 'inputs_picker.dart';
import 'network_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  static const double barHeight = 78;

  final double height;

  const FocusAwareAppBar({super.key, this.height = barHeight});

  @override
  State<StatefulWidget> createState() => _FocusAwareAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _FocusAwareAppBarState extends State<FocusAwareAppBar> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsService, bool>(
      selector: (_, settings) => settings.autoHideAppBarEnabled,
      builder: (context, autoHide, widget) {
        if (autoHide) {
          return Focus(
            canRequestFocus: false,
            onFocusChange: (hasFocus) => setState(() => focused = hasFocus),
            child: AnimatedContainer(
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 250),
              height: focused ? this.widget.height : 0,
              child: widget!,
            ),
          );
        }

        return widget!;
      },
      child: _EmeraldStatusBar(barHeight: widget.height),
    );
  }
}

class _EmeraldStatusBar extends StatelessWidget {
  final double barHeight;

  const _EmeraldStatusBar({required this.barHeight});

  @override
  Widget build(BuildContext context) {
    return Selector<
        SettingsService,
        ({
          bool showDateInStatusBar,
          bool showTimeInStatusBar,
          String timeFormat,
        })>(
      selector: (context, service) => (
        showDateInStatusBar: service.showDateInStatusBar,
        showTimeInStatusBar: service.showTimeInStatusBar,
        timeFormat: service.timeFormat,
      ),
      builder: (context, settings, _) {
        return SizedBox(
          height: barHeight,
          child: Padding(
          padding: EdgeInsets.fromLTRB(28, barHeight < 64 ? 4 : 10, 24, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (settings.showTimeInStatusBar)
                _StatusTime(
                    format: settings.timeFormat,
                    fontSize: barHeight < 64 ? 28 : 40),
              if (settings.showTimeInStatusBar &&
                  settings.showDateInStatusBar) ...[
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 28,
                  color: EmeraldShrine.secondaryText.withOpacity(0.45),
                ),
                const SizedBox(width: 16),
              ],
              if (settings.showDateInStatusBar)
                const Flexible(child: _StatusDate()),
              const Spacer(),
              const _WifiButton(),
              const SizedBox(width: 10),
              const _EntradasButton(),
              const SizedBox(width: 10),
              const _AjustesButton(),
            ],
          ),
        ),
        );
      },
    );
  }
}

class _StatusTime extends StatefulWidget {
  final String format;
  final double fontSize;

  const _StatusTime({required this.format, this.fontSize = 40});

  @override
  State<_StatusTime> createState() => _StatusTimeState();
}

class _StatusTimeState extends State<_StatusTime> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Once a minute is enough for an hours-and-minutes clock, and it stays
    // off the 30s pumps the home tests use.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_now, widget.format),
      style: EmeraldShrine.heading(fontSize: widget.fontSize),
    );
  }

  String _format(DateTime time, String pattern) {
    try {
      return DateFormat(pattern).format(time);
    } catch (_) {
      final String hour = time.hour.toString();
      final String minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }
}

class _StatusDate extends StatefulWidget {
  const _StatusDate();

  @override
  State<_StatusDate> createState() => _StatusDateState();
}

class _StatusDateState extends State<_StatusDate> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatShrineDate(_now),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          EmeraldShrine.body(fontSize: 20, color: EmeraldShrine.secondaryText),
    );
  }
}

ButtonStyle _pillStyle() => ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(EmeraldShrine.text),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return EmeraldShrine.accent.withOpacity(0.18);
        }
        return EmeraldShrine.surfaceTint;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: EmeraldShrine.accent, width: 2);
        }
        return BorderSide(color: Colors.white.withOpacity(0.10));
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );

class _WifiButton extends StatelessWidget {
  const _WifiButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('wifi-button'),
      tooltip: 'Wi-Fi',
      style: _pillStyle(),
      onPressed: () => context.read<AppsService>().openWifiSettings(),
      icon: const NetworkWidget(),
    );
  }
}

class _EntradasButton extends StatelessWidget {
  const _EntradasButton();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const Key('inputs-button'),
      style: _pillStyle(),
      icon: const Icon(Icons.input),
      label: Text(localizations.inputs, style: EmeraldShrine.body(fontSize: 16)),
      onPressed: () => showInputsPicker(context),
    );
  }
}

class _AjustesButton extends StatelessWidget {
  const _AjustesButton();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const Key('settings-button'),
      style: _pillStyle(),
      icon: const Icon(Icons.settings_outlined),
      label:
          Text(localizations.settings, style: EmeraldShrine.body(fontSize: 16)),
      onPressed: () =>
          showDialog(context: context, builder: (_) => const SettingsPanel()),
    );
  }
}
