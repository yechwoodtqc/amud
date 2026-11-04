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
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          },
          child: child,
        ),
      );
}
