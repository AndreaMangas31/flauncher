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

import 'package:flauncher/image_budget.dart';
import 'package:flutter/widgets.dart';

/// Remembers the Entradas focus node and the horizontal rows so a return
/// to the launcher can scroll home and focus that tile.
class HomeReturnController {
  FocusNode? _entradas;
  final List<ScrollController> _rows = [];
  bool _armed = false;
  bool _callbackScheduled = false;

  void attachEntradas(FocusNode node) {
    _entradas = node;
    if (_armed) {
      _schedule();
    }
  }

  void detachEntradas(FocusNode node) {
    if (_entradas == node) {
      _entradas = null;
    }
  }

  void attachRow(ScrollController row) {
    if (_rows.contains(row)) {
      return;
    }
    _rows.add(row);
  }

  void detachRow(ScrollController row) {
    _rows.remove(row);
  }

  /// Scroll every row back to the first tile, then focus Entradas.
  ///
  /// The tile may not be built yet (cold start, or it was scrolled out of
  /// the list). The request waits until the node is attached.
  void focusEntradas() {
    _armed = true;
    for (final ScrollController row in List<ScrollController>.of(_rows)) {
      if (row.hasClients && row.offset != 0) {
        row.jumpTo(0);
      }
    }
    _schedule();
  }

  void dispose() {
    _armed = false;
    _entradas = null;
    _rows.clear();
  }

  void _schedule() {
    if (_callbackScheduled) {
      return;
    }
    _callbackScheduled = true;
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callbackScheduled = false;
      if (!_armed) {
        return;
      }
      final FocusNode? node = _entradas;
      if (node == null || node.context == null) {
        return;
      }
      node.requestFocus();
      _armed = false;
    });
  }
}

class HomeReturn extends InheritedWidget {
  final HomeReturnController controller;

  const HomeReturn({super.key, required this.controller, required super.child});

  static HomeReturnController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeReturn>()?.controller;
  }

  @override
  bool updateShouldNotify(HomeReturn oldWidget) =>
      controller != oldWidget.controller;
}

/// Cold start, and every return to the launcher, focuses Entradas.
///
/// Android delivers [Activity.onPause] as [AppLifecycleState.inactive] and
/// [Activity.onStop] as [AppLifecycleState.paused]. Sleep, the dream, and
/// leaving for another app (including the HDMI picker) all pass through one
/// of those. The following resumed event is the return. D-pad movement never
/// changes the lifecycle, so it does not pull focus back.
class HomeFocusHost extends StatefulWidget {
  final Widget child;

  const HomeFocusHost({super.key, required this.child});

  @override
  State<HomeFocusHost> createState() => _HomeFocusHostState();
}

class _HomeFocusHostState extends State<HomeFocusHost>
    with WidgetsBindingObserver {
  final HomeReturnController _home = HomeReturnController();
  bool _away = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenForTrimMemory();
    setHomeReturnHandler(_home.focusEntradas);
    _home.focusEntradas();
  }

  @override
  void dispose() {
    setHomeReturnHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    _home.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_away) {
        _away = false;
        _home.focusEntradas();
      }
      return;
    }
    _away = true;
  }

  @override
  Widget build(BuildContext context) {
    return HomeReturn(controller: _home, child: widget.child);
  }
}

/// Owns the [ScrollController] of one horizontal home row and registers it
/// so a return to the launcher can jump back to the first tile.
class HomeRow extends StatefulWidget {
  final Widget Function(ScrollController controller) builder;

  const HomeRow({super.key, required this.builder});

  @override
  State<HomeRow> createState() => _HomeRowState();
}

class _HomeRowState extends State<HomeRow> {
  final ScrollController _controller = ScrollController();
  HomeReturnController? _home;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final HomeReturnController? next = HomeReturn.maybeOf(context);
    if (next == _home) {
      return;
    }
    _home?.detachRow(_controller);
    _home = next;
    _home?.attachRow(_controller);
  }

  @override
  void dispose() {
    _home?.detachRow(_controller);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}
