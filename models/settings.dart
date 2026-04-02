// ─── Settings Model ───────────────────────────────────────────────────────────
// Simple value-holder passed between screens via constructor.
// No external state management library needed.

enum Difficulty { easy, medium, hard }

class GameSettings {
  bool soundEnabled;
  Difficulty difficulty;

  GameSettings({
    this.soundEnabled = true,
    this.difficulty = Difficulty.medium,
  });

  // Base obstacle speed per difficulty
  double get baseSpeed => switch (difficulty) {
        Difficulty.easy   => 120.0,
        Difficulty.medium => 200.0,
        Difficulty.hard   => 300.0,
      };

  // How fast the speed ramps up (pixels/s added per second)
  double get speedRampRate => switch (difficulty) {
        Difficulty.easy   => 8.0,
        Difficulty.medium => 18.0,
        Difficulty.hard   => 30.0,
      };

  // How often a new obstacle spawns (seconds between spawns)
  double get spawnInterval => switch (difficulty) {
        Difficulty.easy   => 1.4,
        Difficulty.medium => 1.0,
        Difficulty.hard   => 0.65,
      };

  String get label => switch (difficulty) {
        Difficulty.easy   => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard   => 'Hard',
      };
}
