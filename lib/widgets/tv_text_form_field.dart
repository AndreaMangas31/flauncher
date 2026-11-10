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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field for a D-pad remote.
///
/// Focus can land on the field without opening the soft keyboard. The keyboard
/// opens only after Select/OK (or a tap). Done, Back, or dismissing the
/// keyboard returns focus to the field so the next D-pad press can move on.
class TvTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool autofocus;
  final TextInputAction textInputAction;

  const TvTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autovalidateMode,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<TvTextFormField> createState() => _TvTextFormFieldState();
}

class _TvTextFormFieldState extends State<TvTextFormField> with WidgetsBindingObserver {
  final FocusNode _traversalNode = FocusNode(debugLabel: 'tv-text-traversal');

  /// Kept out of D-pad traversal until the user explicitly starts editing.
  /// A focused [TextFormField] opens the IME, which is what we want to avoid
  /// while the remote is only moving highlight around the form.
  final FocusNode _editingNode = FocusNode(
    debugLabel: 'tv-text-editing',
    skipTraversal: true,
    canRequestFocus: false,
  );

  bool _editing = false;
  bool _keyboardWasShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _traversalNode.addListener(_onFocusChanged);
    _editingNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _traversalNode.removeListener(_onFocusChanged);
    _editingNode.removeListener(_onFocusChanged);
    _traversalNode.dispose();
    _editingNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeMetrics() {
    if (!_editing) {
      return;
    }

    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) {
      return;
    }

    final double inset = views.first.viewInsets.bottom;
    if (inset > 0) {
      _keyboardWasShown = true;
      return;
    }

    if (_keyboardWasShown) {
      _keyboardWasShown = false;
      // The IME was dismissed (Back on most TV keyboards) without a Flutter
      // key event. Return to D-pad focus on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editing) {
          _stopEditing();
        }
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_editing) {
      if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
        _stopEditing();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      node.focusInDirection(TraversalDirection.up);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      node.focusInDirection(TraversalDirection.down);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _startEditing();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startEditing() {
    if (_editing) {
      return;
    }
    setState(() {
      _editing = true;
      _editingNode
        ..skipTraversal = false
        ..canRequestFocus = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) {
        _editingNode.requestFocus();
      }
    });
  }

  void _stopEditing() {
    if (!_editing) {
      _traversalNode.requestFocus();
      return;
    }
    setState(() {
      _editing = false;
      _keyboardWasShown = false;
      _editingNode
        ..canRequestFocus = false
        ..skipTraversal = true;
    });
    _traversalNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool highlighted = _traversalNode.hasFocus || _editingNode.hasFocus;

    return Focus(
      focusNode: _traversalNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: highlighted ? Colors.white : Colors.white24, width: highlighted ? 2 : 1),
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          focusNode: _editingNode,
          readOnly: !_editing,
          enableInteractiveSelection: _editing,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          autovalidateMode: widget.autovalidateMode,
          validator: widget.validator,
          decoration: widget.decoration,
          onTap: _startEditing,
          onChanged: widget.onChanged,
          onFieldSubmitted: (value) {
            widget.onFieldSubmitted?.call(value);
            _stopEditing();
          },
          onEditingComplete: _stopEditing,
        ),
      ),
    );
  }
}
