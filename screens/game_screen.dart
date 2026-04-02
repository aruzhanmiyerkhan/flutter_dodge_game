import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/settings.dart';
import '../models/obstacle.dart';
import 'game_over_screen.dart';

// ─── Game Screen ──────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final GameSettings settings;
  const GameScreen({super.key, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation driver (replaces Timer for smooth movement) ─────────────────
  late final AnimationController _loop;

  // ── Game state ────────────────────────────────────────────────────────────
  bool _paused = false;
  bool _gameStarted = false;

  // Player
  static const double kPlayerW = 44;
  static const double kPlayerH = 44;
  double _playerX = 0; // center x of player
  double _targetX = 0; // where player is sliding to

  // Obstacles
  final List<Obstacle> _obstacles = [];
  double _currentSpeed = 0;  // pixels per second
  double _spawnTimer = 0;    // seconds since last spawn
  final Random _rng = Random();

  // Score (frames survived × some factor)
  int _score = 0;
  int _bestScore = 0;
  double _scoreAccum = 0; // accumulated score (float)

  // Screen dimensions (set in build)
  double _screenW = 0;
  double _screenH = 0;
  double _playerBottom = 0; // bottom edge y of player

  // Time tracking
  DateTime? _lastTick;

  // Swipe tracking
  double? _swipeStartX;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.settings.baseSpeed;

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1), // runs until we stop it
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  // ── Game loop ─────────────────────────────────────────────────────────────

  void _tick() {
    if (_paused || !_gameStarted) return;

    final now = DateTime.now();
    final dt = _lastTick == null
        ? 0.016
        : (now.difference(_lastTick!).inMicroseconds / 1_000_000)
            .clamp(0.0, 0.05);
    _lastTick = now;

    setState(() {
      // 1. Move player towards target (smooth sliding)
      const slideSpeed = 800.0;
      if ((_playerX - _targetX).abs() > 1) {
        final dir = _targetX > _playerX ? 1 : -1;
        _playerX += dir * slideSpeed * dt;
        // Clamp so we don't overshoot
        if (dir == 1 && _playerX > _targetX) _playerX = _targetX;
        if (dir == -1 && _playerX < _targetX) _playerX = _targetX;
      }
      // Clamp to screen
      _playerX = _playerX.clamp(
          kPlayerW / 2, _screenW - kPlayerW / 2);
      _targetX = _targetX.clamp(
          kPlayerW / 2, _screenW - kPlayerW / 2);

      // 2. Increase speed over time
      _currentSpeed += widget.settings.speedRampRate * dt;

      // 3. Spawn obstacles
      _spawnTimer += dt;
      if (_spawnTimer >= widget.settings.spawnInterval) {
        _spawnTimer = 0;
        _obstacles.add(Obstacle.spawn(screenWidth: _screenW, rng: _rng));
      }

      // 4. Move obstacles
      final dy = _currentSpeed * dt;
      for (final o in _obstacles) {
        o.fall(dy);
      }

      // 5. Remove off-screen obstacles
      _obstacles.removeWhere((o) => o.y > _screenH + 20);

      // 6. Collision detection
      final playerRect = _playerHitbox();
      for (final o in _obstacles) {
        if (playerRect.overlaps(o.hitbox)) {
          _endGame();
          return;
        }
      }

      // 7. Score
      _scoreAccum += dt * (_currentSpeed / 50);
      _score = _scoreAccum.floor();
      if (_score > _bestScore) _bestScore = _score;
    });
  }

  Rect _playerHitbox() {
    final left   = _playerX - kPlayerW / 2 + 4;
    final top    = _playerBottom - kPlayerH + 4;
    return Rect.fromLTWH(left, top, kPlayerW - 8, kPlayerH - 8);
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  void _moveLeft() {
    if (!_gameStarted) _startGame();
    _targetX -= 80;
  }

  void _moveRight() {
    if (!_gameStarted) _startGame();
    _targetX += 80;
  }

  void _startGame() {
    _gameStarted = true;
    _lastTick = DateTime.now();
    _loop.forward();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (!_paused) _lastTick = DateTime.now(); // reset dt after resume
    });
    HapticFeedback.lightImpact();
  }

  void _endGame() {
    _loop.stop();
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameOverScreen(
        score: _score,
        bestScore: _bestScore,
        settings: widget.settings,
      ),
    ));
  }

  // ── Swipe input ───────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    _swipeStartX = d.globalPosition.dx;
    if (!_gameStarted) _startGame();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_swipeStartX == null) return;
    final delta = d.globalPosition.dx - _swipeStartX!;
    _targetX = (_playerX + delta).clamp(
        kPlayerW / 2, _screenW - kPlayerW / 2);
  }

  void _onPanEnd(DragEndDetails _) {
    _swipeStartX = null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          _screenW = constraints.maxWidth;
          _screenH = constraints.maxHeight;
          _playerBottom = _screenH - 80; // player sits above controls

          // Init player position on first build
          if (_playerX == 0) {
            _playerX = _screenW / 2;
            _targetX = _screenW / 2;
          }

          return GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTap: () { if (!_gameStarted) _startGame(); },
            child: Stack(children: [
              // ── Game canvas ───────────────────────────
              _GameCanvas(
                screenW: _screenW,
                screenH: _screenH,
                playerX: _playerX,
                playerBottom: _playerBottom,
                obstacles: _obstacles,
                paused: _paused,
              ),

              // ── HUD (score + pause) ───────────────────
              _HUD(
                score: _score,
                speed: _currentSpeed,
                paused: _paused,
                onPause: _togglePause,
              ),

              // ── Start hint ────────────────────────────
              if (!_gameStarted)
                const Center(
                  child: Text(
                    'Tap or swipe to start',
                    style: TextStyle(
                      color: AppTheme.textSec,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),

              // ── Pause overlay ─────────────────────────
              if (_paused)
                _PauseOverlay(
                  onResume: _togglePause,
                  onHome: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),

              // ── Controls ──────────────────────────────
              Positioned(
                left: 0, right: 0,
                bottom: 0,
                child: _Controls(
                  onLeft: _moveLeft,
                  onRight: _moveRight,
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

// ─── Game Canvas (CustomPainter) ──────────────────────────────────────────────

class _GameCanvas extends StatelessWidget {
  final double screenW, screenH;
  final double playerX, playerBottom;
  final List<Obstacle> obstacles;
  final bool paused;

  const _GameCanvas({
    required this.screenW,
    required this.screenH,
    required this.playerX,
    required this.playerBottom,
    required this.obstacles,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(screenW, screenH),
      painter: _CanvasPainter(
        playerX: playerX,
        playerBottom: playerBottom,
        playerW: _GameScreenState.kPlayerW,
        playerH: _GameScreenState.kPlayerH,
        obstacles: obstacles,
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final double playerX, playerBottom, playerW, playerH;
  final List<Obstacle> obstacles;

  const _CanvasPainter({
    required this.playerX,
    required this.playerBottom,
    required this.playerW,
    required this.playerH,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.bg,
    );

    // Subtle vertical lane lines
    final lanePaint = Paint()
      ..color = AppTheme.surface
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
    }

    // Obstacles
    for (final o in obstacles) {
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(o.x, o.y, o.width, o.height),
          const Radius.circular(6));
      canvas.drawRRect(rect, Paint()..color = const Color(0xFFEF4444));
      // Top highlight
      canvas.drawRect(
        Rect.fromLTWH(o.x + 2, o.y + 2, o.width - 4, 4),
        Paint()..color = Colors.white.withOpacity(0.2),
      );
    }

    // Player shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(playerX, playerBottom + 4),
        width: playerW * 0.9,
        height: 10,
      ),
      Paint()..color = AppTheme.accent.withOpacity(0.25),
    );

    // Player square
    final playerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        playerX - playerW / 2,
        playerBottom - playerH,
        playerW,
        playerH,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(playerRect, Paint()..color = AppTheme.accent);
    // Player shine
    canvas.drawRect(
      Rect.fromLTWH(
          playerX - playerW / 2 + 4, playerBottom - playerH + 4, playerW - 8,
          6),
      Paint()..color = Colors.white.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class _HUD extends StatelessWidget {
  final int score;
  final double speed;
  final bool paused;
  final VoidCallback onPause;

  const _HUD({
    required this.score,
    required this.speed,
    required this.paused,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SCORE',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppTheme.muted)),
            Text('$score',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPri)),
          ]),

          // Pause button
          GestureDetector(
            onTap: onPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                color: AppTheme.textSec,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pause Overlay ────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onHome;

  const _PauseOverlay({required this.onResume, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'PAUSED',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: AppTheme.textPri,
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('RESUME'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home_outlined, color: AppTheme.textSec),
            label: const Text('HOME',
                style: TextStyle(color: AppTheme.textSec)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border, width: 1.5),
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _Controls({required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(children: [
        Expanded(child: _CtrlBtn(icon: Icons.chevron_left_rounded, onTap: onLeft)),
        const SizedBox(width: 16),
        Expanded(child: _CtrlBtn(icon: Icons.chevron_right_rounded, onTap: onRight)),
      ]),
    );
  }
}

class _CtrlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  State<_CtrlBtn> createState() => _CtrlBtnState();
}

class _CtrlBtnState extends State<_CtrlBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _down = true); widget.onTap(); HapticFeedback.selectionClick(); },
      onTapUp:   (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: _down ? AppTheme.accent.withOpacity(0.2) : AppTheme.surface,
          border: Border.all(
              color: _down
                  ? AppTheme.accent.withOpacity(0.6)
                  : AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(widget.icon,
              color: _down ? AppTheme.accent : AppTheme.muted, size: 32),
        ),
      ),
    );
  }
}
