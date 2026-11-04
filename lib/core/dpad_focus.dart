import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A focusable, SELECT-activated surface with a persistent high-contrast
/// outline. Use for custom reader rows that are not Material buttons.
class DpadFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback onActivate;
  final bool autofocus;
  final BorderRadius borderRadius;

  const DpadFocusable({
    super.key,
    required this.child,
    required this.onActivate,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<DpadFocusable> createState() => _DpadFocusableState();
}

class _DpadFocusableState extends State<DpadFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (value) {
        if (mounted && value != _focused) setState(() => _focused = value);
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) {
          widget.onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: _focused ? color : Colors.transparent,
            width: _focused ? 2.5 : 0,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
