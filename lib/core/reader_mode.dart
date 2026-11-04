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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'Reader mode D-pad');
    if (widget.active) _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(covariant ReaderModeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _requestFocus();
    if (!widget.active && oldWidget.active) _focusNode.unfocus();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) _focusNode.requestFocus();
    });
  }
  Offset? _down;
  Duration? _downTime;
  Duration? _lastTap;
  Timer? _hold;
  bool _held = false;

  @override
  void dispose() {
    _hold?.cancel();
    _focusNode.dispose();
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
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.active,
        canRequestFocus: widget.active,
        skipTraversal: !widget.active,
        onKeyEvent: (node, event) {
          final key = event.logicalKey;
          // The logical key remains in the pressed set for down/repeat events,
          // and is removed before the matching key-up is delivered.
          if (!HardwareKeyboard.instance.logicalKeysPressed.contains(key)) return KeyEventResult.ignored;
          if (key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter) {
            widget.onNext();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowLeft) {
            (widget.onPrevious ?? widget.onBackTwo)();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.escape) {
            widget.onExit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          // Opaque: while active the page underneath ignores pointers, and a
          // deferring listener would then never be hit itself.
          behavior: HitTestBehavior.opaque,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: (_) {
            _hold?.cancel();
            _down = null;
          },
          child: Stack(children: [
            Positioned.fill(child: IgnorePointer(ignoring: widget.active, child: widget.child)),
            if (widget.active)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: theme.colorScheme.inverseSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        context.tr('Reader mode: arrows or OK to step; Back to stop'),
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onInverseSurface),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
