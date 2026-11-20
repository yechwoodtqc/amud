import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;

/// Hardware D-pad support shared by every route in the app.
///
/// Reading-order traversal gives directional keys a predictable path through
/// focusable controls. Android maps the physical D-pad center key to SELECT;
/// map that key to Flutter's normal activation action so buttons and other
/// actionable controls respond to OK just as they do to Enter or Space.
class DpadNavigation extends StatefulWidget {
  final Widget child;

  const DpadNavigation({super.key, required this.child});

  @override
  State<DpadNavigation> createState() => _DpadNavigationState();
}

class _DpadNavigationState extends State<DpadNavigation> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_moveOutOfInputControls);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_moveOutOfInputControls);
    super.dispose();
  }

  // Text fields otherwise keep Up/Down for caret movement, and sliders can
  // retain focus indefinitely. On this D-pad-first app those two keys leave
  // the control; horizontal keys remain available to adjust a slider.
  bool _moveOutOfInputControls(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      _ => null,
    };
    if (direction == null) return false;
    final node = FocusManager.instance.primaryFocus;
    final context = node?.context;
    if (node == null || context == null) return false;
    final isTextField = context.findAncestorWidgetOfExactType<EditableText>() != null;
    final isSlider = context.findAncestorWidgetOfExactType<Slider>() != null ||
        context.findAncestorWidgetOfExactType<RangeSlider>() != null;
    if (!isTextField && !isSlider) return false;
    return node.focusInDirection(direction);
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: CallbackShortcuts(
          // Some feature phones deliver the physical Back key as a keyboard
          // event (GO_BACK), rather than as Android's system-pop callback.
          // Resolve the Navigator from the currently focused control so this
          // works in the active nested tab, dialog, or pushed reader route.
          bindings: {
            const SingleActivator(LogicalKeyboardKey.goBack): _popFocusedRoute,
            const SingleActivator(LogicalKeyboardKey.endCall): _popFocusedRoute,
            const SingleActivator(LogicalKeyboardKey.browserBack): _popFocusedRoute,
            const SingleActivator(LogicalKeyboardKey.escape): _popFocusedRoute,
          },
          child: Shortcuts(
            shortcuts: const {
            // Make directional navigation explicit. On small Android devices
            // the platform key map can send arrows to a scrollable before
            // focus traversal gets a chance to move focus.
              SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
              SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
              SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
              SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
              SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            },
            child: widget.child,
          ),
        ),
      );
}

void _popFocusedRoute() {
              final focusedContext = FocusManager.instance.primaryFocus?.context;
              if (focusedContext == null) return;
              final navigator = Navigator.maybeOf(focusedContext);
              if (navigator != null) unawaited(navigator.maybePop().then<void>((_) {}));
            }

