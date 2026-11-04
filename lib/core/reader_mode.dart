import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';

/// Reader mode: step through a text one passage at a time with taps
/// anywhere on the page.
///
///  * one tap: the next passage, at once (no waiting to see whether a
///    second tap follows, so going forward never lags);
///  * two quick taps: back one passage. The first tap has already moved
///    forward, so the second goes back two; the jump shows, by design;
///  * press and hold: leave reader mode.
///
/// While it is on, taps don't reach the page underneath (they would open
/// or select things), and a small banner says how it works.
class ReaderModeLayer extends StatefulWidget {
  final bool active;
  final VoidCallback onNext;

  /// Called on the second of two quick taps: go back two from where the
  /// first tap moved to.
  final VoidCallback onBackTwo;
  final VoidCallback? onPrevious;
  final VoidCallback onExit;
  final Widget child;
  const ReaderModeLayer({
    super.key,
    required this.active,
    required this.onNext,
    required this.onBackTwo,
    this.onPrevious,
    required this.onExit,
    required this.child,
  });

  @override
  State<ReaderModeLayer> createState() => _ReaderModeLayerState();
}

class _ReaderModeLayerState extends State<ReaderModeLayer> {
  Offset? _down;
  Duration? _downTime;
  Duration? _lastTap;
  Timer? _hold;
  bool _held = false;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent e) {
    if (!widget.active) return;
    _down = e.position;
    _downTime = e.timeStamp;
    _held = false;
    _hold?.cancel();
    _hold = Timer(kLongPressTimeout, () {
      _held = true;
      _lastTap = null;
      widget.onExit();
    });
  }

  void _pointerMove(PointerMoveEvent e) {
    if (_down != null && (e.position - _down!).distance > kTouchSlop) _hold?.cancel();
  }

  void _pointerUp(PointerUpEvent e) {
    _hold?.cancel();
    final down = _down, downTime = _downTime;
    _down = null;
    if (!widget.active || _held || down == null || downTime == null) return;
    if ((e.position - down).distance > kTouchSlop || e.timeStamp - downTime > kLongPressTimeout) return;
    final last = _lastTap;
    if (last != null && e.timeStamp - last < kDoubleTapTimeout) {
      _lastTap = null;
      widget.onBackTwo();
    } else {
      _lastTap = e.timeStamp;
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<void>(
      canPop: !widget.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.active) widget.onExit();
      },
      child: CallbackShortcuts(
        // Passage stepping remains available while the visible Exit control
        // owns focus. The old parent Focus node swallowed SELECT before the
        // banner button could receive it.
        bindings: {
          if (widget.active) ...{
            const SingleActivator(LogicalKeyboardKey.arrowDown): widget.onNext,
            const SingleActivator(LogicalKeyboardKey.arrowRight): widget.onNext,
            const SingleActivator(LogicalKeyboardKey.arrowUp): widget.onPrevious ?? widget.onBackTwo,
            const SingleActivator(LogicalKeyboardKey.arrowLeft): widget.onPrevious ?? widget.onBackTwo,
            const SingleActivator(LogicalKeyboardKey.select): widget.onExit,
            const SingleActivator(LogicalKeyboardKey.escape): widget.onExit,
          },
        },
        child: Stack(children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: _pointerUp,
              onPointerCancel: (_) {
                _hold?.cancel();
                _down = null;
              },
              child: ExcludeFocus(
                excluding: widget.active,
                child: IgnorePointer(ignoring: widget.active, child: widget.child),
              ),
            ),
          ),
          if (widget.active)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: theme.colorScheme.inverseSurface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        context.tr('Reader mode: arrows step through passages'),
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onInverseSurface),
                      ),
                    ),
                    TextButton.icon(
                      autofocus: true,
                      onPressed: widget.onExit,
                      icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onInverseSurface),
                      label: Text(context.tr('Exit'), style: TextStyle(color: theme.colorScheme.onInverseSurface)),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
