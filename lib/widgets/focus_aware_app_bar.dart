import 'dart:async';

import 'package:flauncher/theme/emerald_shrine.dart';
import 'package:flauncher/theme/shrine_clock.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/settings_service.dart';
import 'network_widget.dart';

class FocusAwareAppBar extends StatefulWidget implements PreferredSizeWidget {
  static const double barHeight = 78;

  @override
  State<StatefulWidget> createState() => _FocusAwareAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);
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
              height: focused ? FocusAwareAppBar.barHeight : 0,
              child: widget!,
            ),
          );
        }

        return widget!;
      },
      child: const _EmeraldStatusBar(),
    );
  }
}

class _EmeraldStatusBar extends StatelessWidget {
  const _EmeraldStatusBar();

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
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 24, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (settings.showTimeInStatusBar)
                _StatusTime(format: settings.timeFormat),
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
              const NetworkWidget(),
              const SizedBox(width: 18),
              const _AjustesButton(),
            ],
          ),
        );
      },
    );
  }
}

class _StatusTime extends StatefulWidget {
  final String format;

  const _StatusTime({required this.format});

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
      style: EmeraldShrine.heading(fontSize: 40),
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

class _AjustesButton extends StatelessWidget {
  const _AjustesButton();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const Key('settings-button'),
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(EmeraldShrine.text),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
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
      ),
      icon: const Icon(Icons.settings_outlined),
      label:
          Text(localizations.settings, style: EmeraldShrine.body(fontSize: 16)),
      onPressed: () =>
          showDialog(context: context, builder: (_) => const SettingsPanel()),
    );
  }
}
