import 'package:flutter/material.dart';

const _offsetDistance = 5.0;

class ShadowCard extends StatelessWidget {
  final Widget child;
  final bool showAccent;
  final double elevation;
  final Color? color;

  const ShadowCard({
    super.key,
    required this.child,
    this.showAccent = false,
    this.elevation = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.secondary;
    final cardColor = color ?? theme.cardColor;
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.2);

    return Stack(
      children: [
        if (showAccent)
          Positioned(
            left: 0,
            top: 0,
            right: _offsetDistance,
            bottom: _offsetDistance,
            child: Container(
              decoration: BoxDecoration(
                color: accent.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
          ),
        Transform.translate(
          offset: showAccent
              ? const Offset(_offsetDistance, _offsetDistance)
              : Offset.zero,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(6.0),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: elevation,
                  offset: Offset(elevation / 2, elevation / 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
