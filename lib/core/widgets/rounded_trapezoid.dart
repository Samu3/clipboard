import 'package:flutter/material.dart';

/// 圆角梯形绘制器
class RoundedTrapezoidPainter extends CustomPainter {
  final Color color;
  final double topWidth;
  final double bottomWidth;
  final double cornerRadius;

  RoundedTrapezoidPainter({
    required this.color,
    required this.topWidth,
    required this.bottomWidth,
    this.cornerRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height;
    final centerX = size.width / 2;

    // 计算梯形四个顶点
    final topLeft = Offset(centerX - topWidth / 2, 0);
    final topRight = Offset(centerX + topWidth / 2, 0);
    final bottomRight = Offset(centerX + bottomWidth / 2, height);
    final bottomLeft = Offset(centerX - bottomWidth / 2, height);

    // 判断是否需要顶部圆角：高度小于200时不要顶部圆角
    final hasTopCorners = height >= 200;

    if (hasTopCorners) {
      // 从左上角开始（带圆角）
      path.moveTo(topLeft.dx + cornerRadius, topLeft.dy);

      // 顶部直线到右上角
      path.lineTo(topRight.dx - cornerRadius, topRight.dy);

      // 右上角圆角
      path.arcToPoint(
        Offset(topRight.dx, topRight.dy + cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
    } else {
      // 从左上角开始（不带圆角）
      path.moveTo(topLeft.dx, topLeft.dy);

      // 顶部直线到右上角（不带圆角）
      path.lineTo(topRight.dx, topRight.dy);
    }

    // 右边斜线到右下角
    path.lineTo(bottomRight.dx, bottomRight.dy - cornerRadius);

    // 右下角圆角
    path.arcToPoint(
      Offset(bottomRight.dx - cornerRadius, bottomRight.dy),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 底部直线到左下角
    path.lineTo(bottomLeft.dx + cornerRadius, bottomLeft.dy);

    // 左下角圆角
    path.arcToPoint(
      Offset(bottomLeft.dx, bottomLeft.dy - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 左边斜线到左上角
    if (hasTopCorners) {
      path.lineTo(topLeft.dx, topLeft.dy + cornerRadius);

      // 左上角圆角
      path.arcToPoint(
        Offset(topLeft.dx + cornerRadius, topLeft.dy),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );
    } else {
      // 左边斜线到左上角（不带圆角）
      path.lineTo(topLeft.dx, topLeft.dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RoundedTrapezoidPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.topWidth != topWidth ||
        oldDelegate.bottomWidth != bottomWidth ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

/// 圆角梯形 Widget
class RoundedTrapezoid extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double topWidth;
  final double bottomWidth;
  final double cornerRadius;
  final Widget? child;

  const RoundedTrapezoid({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.topWidth,
    required this.bottomWidth,
    this.cornerRadius = 12.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: RoundedTrapezoidPainter(
              color: color,
              topWidth: topWidth,
              bottomWidth: bottomWidth,
              cornerRadius: cornerRadius,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
