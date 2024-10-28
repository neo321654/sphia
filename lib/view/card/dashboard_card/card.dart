import 'package:flutter/material.dart';
import 'package:sphia/view/card/shadow_card.dart';

class CardData {
  final Widget? title;
  final IconData icon;
  final Widget widget;
  final bool showAccent;
  final bool horizontalPadding;

  const CardData({
    this.title,
    required this.icon,
    required this.widget,
    this.showAccent = false,
    this.horizontalPadding = true,
  });
}

Widget buildSingleRowCard(CardData cardData) {
  return ShadowCard(
    showAccent: cardData.showAccent,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(cardData.icon, size: 24, opticalSize: 24),
          ),
          cardData.title!,
          const Spacer(),
          cardData.widget,
        ],
      ),
    ),
  );
}

Widget buildMultipleRowCard(CardData cardData) {
  return Padding(
    padding: cardData.showAccent
        ? const EdgeInsets.only(bottom: 5)
        : EdgeInsets.zero,
    child: ShadowCard(
      showAccent: cardData.showAccent,
      child: Padding(
        padding: cardData.horizontalPadding
            ? const EdgeInsets.all(12)
            : const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: cardData.horizontalPadding ? 0 : 12,
                    right: 8,
                  ),
                  child: Icon(cardData.icon, size: 24, opticalSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: cardData.horizontalPadding
                    ? const EdgeInsets.only(left: 8)
                    : EdgeInsets.zero,
                child: cardData.widget,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildInkWellTile({
  required Widget title,
  Widget? subtitle,
  required void Function()? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(
      left: 12.0,
      right: 12.0,
      top: 4.0,
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: title,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4.0),
              Align(
                alignment: Alignment.centerLeft,
                child: subtitle,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class UnderlineText extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final Color underlineColor;
  final double underlineThickness;
  final void Function()? onTap;

  const UnderlineText({
    super.key,
    required this.text,
    required this.textStyle,
    this.underlineColor = Colors.grey,
    this.underlineThickness = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Text(
              text,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _UnderlinePainter(
              color: underlineColor,
              thickness: underlineThickness,
            ),
            child: Container(height: underlineThickness),
          ),
        ),
      ],
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  final Color color;
  final double thickness;

  _UnderlinePainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
