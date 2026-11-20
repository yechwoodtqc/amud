import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

/// Hardware D-pad support shared by every route in the app.
///
/// Reading-order traversal gives directional keys a predictable path through
/// focusable controls. Android maps the physical D-pad center key to SELECT;
/// map that key to Flutter's normal activation action so buttons and other
/// actionable controls respond to OK just as they do to Enter or Space.
class DpadNavigation extends StatelessWidget {
  final Widget child;

  const DpadNavigation({super.key, required this.child});

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
            child: child,
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

