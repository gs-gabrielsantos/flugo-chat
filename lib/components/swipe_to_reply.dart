import 'dart:math' as math;
import 'package:flutter/material.dart';

class SwipeToReply extends StatefulWidget {
  final bool isMe;
  final Widget child;
  final VoidCallback onReply;

  final double maxOffset;
  final double triggerOffset;

  const SwipeToReply({
    super.key,
    required this.isMe,
    required this.child,
    required this.onReply,
    this.maxOffset = 72,
    this.triggerOffset = 46,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  double _fromDx = 0;
  bool _triggered = false;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 160),
        )..addListener(() {
          // Evita setState depois do dispose (segurança extra)
          if (!mounted) return;

          // Anima _dx de _fromDx até 0
          setState(() {
            _dx = _fromDx * (1.0 - Curves.easeOut.transform(_ctrl.value));
          });
        });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _animateBack() {
    _fromDx = _dx;
    _ctrl.forward(from: 0);
  }

  double _applyResistance(double value) {
    final max = widget.maxOffset;
    final v = value.abs();
    if (v <= max) return value;

    final extra = v - max;
    final resisted = max + extra * 0.12;
    return math.min(resisted, max + 18) * value.sign;
  }

  bool _isAllowedDirection(double delta) {
    if (widget.isMe) return delta < 0;
    return delta > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = (_dx.abs() / widget.maxOffset).clamp(0.0, 1.0);
    final iconScale = (0.75 + (progress * 0.35)).clamp(0.75, 1.1);

    final iconAlign = widget.isMe
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final circleColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);

    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        if (!_isAllowedDirection(d.delta.dx)) return;

        if (_ctrl.isAnimating) _ctrl.stop();

        setState(() {
          _dx = _applyResistance(_dx + d.delta.dx);
          _triggered = _dx.abs() >= widget.triggerOffset;
        });
      },
      onHorizontalDragEnd: (_) {
        if (_triggered) widget.onReply();

        _triggered = false;
        _animateBack();
      },
      onHorizontalDragCancel: () {
        _triggered = false;
        _animateBack();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: iconAlign,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Transform.scale(
                  scale: iconScale,
                  child: Opacity(
                    opacity: progress,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.reply, size: 18, color: iconColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}
