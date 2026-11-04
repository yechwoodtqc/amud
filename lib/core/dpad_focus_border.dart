import 'package:flutter/material.dart';

/// Draws a persistent outline around a row whenever one of its descendants
/// owns D-pad focus. The wrapper itself is not a traversal stop.
class DpadFocusBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  const DpadFocusBorder({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<DpadFocusBorder> createState() => _DpadFocusBorderState();
}

class _DpadFocusBorderState extends State<DpadFocusBorder> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (_focused != focused && mounted) setState(() => _focused = focused);
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_focused)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 2),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
