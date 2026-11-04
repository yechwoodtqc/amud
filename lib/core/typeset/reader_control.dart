import 'package:flutter/material.dart';

/// A tappable row inside the reader's text: a folded section, a collapsed
/// note, the chazzan's repetition. It is a real focusable control so a
/// hardware D-pad can reach and activate it.
class ReaderControl extends StatefulWidget {
  final IconData icon;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Color tone;
  final bool dashed;
  final bool open;
  final VoidCallback? onTap;
  final bool attachedBelow;
  final double gap;

  const ReaderControl({
    super.key,
    required this.icon,
    required this.title,
    required this.tone,
    this.subtitle,
    this.trailing,
    this.dashed = false,
    this.open = false,
    this.onTap,
    this.attachedBelow = false,
    this.gap = 4,
  });

  @override
  State<ReaderControl> createState() => _ReaderControlState();
}

class _ReaderControlState extends State<ReaderControl> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.attachedBelow
        ? const BorderRadius.vertical(top: Radius.circular(14))
        : BorderRadius.circular(14);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: widget.tone.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(widget.icon, size: 17, color: widget.tone),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium?.copyWith(color: widget.tone, fontFamily: theme.textTheme.bodyMedium?.fontFamily),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              widget.title,
              if (widget.subtitle != null)
                DefaultTextStyle.merge(
                  style: theme.textTheme.bodySmall?.copyWith(color: widget.tone.withValues(alpha: 0.8)),
                  child: widget.subtitle!,
                ),
            ]),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          DefaultTextStyle.merge(style: theme.textTheme.labelMedium?.copyWith(color: widget.tone), child: widget.trailing!),
        ],
        const SizedBox(width: 2),
        Icon(widget.open ? Icons.expand_less : Icons.expand_more, size: 20, color: widget.tone),
      ]),
    );
    return Padding(
      padding: EdgeInsets.only(top: widget.gap, bottom: widget.attachedBelow ? 0 : widget.gap),
      child: Semantics(
        button: true,
        expanded: widget.open,
        child: CustomPaint(
          foregroundPainter: widget.dashed && !_focused ? _DashedBorder(widget.tone.withValues(alpha: 0.55), radius) : null,
          child: Material(
            color: widget.tone.withValues(alpha: widget.dashed ? 0.04 : 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: _focused
                    ? theme.colorScheme.primary
                    : widget.dashed
                        ? Colors.transparent
                        : widget.tone.withValues(alpha: 0.35),
                width: _focused ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              canRequestFocus: widget.onTap != null,
              onFocusChange: (focused) {
                if (_focused != focused && mounted) setState(() => _focused = focused);
              },
              onTap: widget.onTap,
              focusColor: theme.colorScheme.primary.withValues(alpha: 0.10),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  final BorderRadius radius;
  _DashedBorder(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 5.0, space = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + space) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color || old.radius != radius;
}
