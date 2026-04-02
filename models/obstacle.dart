import 'dart:math';

// ─── Obstacle Model ───────────────────────────────────────────────────────────

class Obstacle {
  double x;      // left edge in logical pixels
  double y;      // top edge in logical pixels
  double width;
  double height;

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Move obstacle downward by [dy] pixels.
  void fall(double dy) => y += dy;

  /// Bounding rect for collision detection (with small inset for fairness).
  Rect get hitbox => Rect.fromLTWH(
        x + 4,
        y + 4,
        width - 8,
        height - 8,
      );

  /// Factory: spawn a new obstacle at the top, random horizontal position.
  static Obstacle spawn({
    required double screenWidth,
    required Random rng,
  }) {
    const double minW = 40, maxW = 90;
    const double minH = 24, maxH = 44;

    final w = minW + rng.nextDouble() * (maxW - minW);
    final h = minH + rng.nextDouble() * (maxH - minH);
    final x = rng.nextDouble() * (screenWidth - w);

    return Obstacle(x: x, y: -h, width: w, height: h);
  }
}
