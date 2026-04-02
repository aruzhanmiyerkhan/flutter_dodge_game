import 'package:flutter/material.dart';
import '../main.dart';
import '../models/settings.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';

// ─── Game Over Screen ─────────────────────────────────────────────────────────

class GameOverScreen extends StatefulWidget {
  final int score;
  final int bestScore;
  final GameSettings settings;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.bestScore,
    required this.settings,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween(begin: 40.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _restart() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameScreen(settings: widget.settings),
    ));
  }

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isNewBest = widget.score >= widget.bestScore && widget.score > 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(
                offset: Offset(0, _slide.value), child: child),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ──────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.12),
                      border: Border.all(
                          color: AppTheme.danger.withOpacity(0.4), width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppTheme.danger, size: 40),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ─────────────────────────────────
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppTheme.textPri,
                    ),
                  ),

                  if (isNewBest) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.15),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: AppTheme.gold, size: 16),
                          SizedBox(width: 4),
                          Text('New Best!',
                              style: TextStyle(
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Score cards ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatCard(
                        label: 'SCORE',
                        value: '${widget.score}',
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 16),
                      StatCard(
                        label: 'BEST',
                        value: '${widget.bestScore}',
                        color: AppTheme.gold,
                      ),
                    ],
                  ),

                  const SizedBox(height: 56),

                  // ── Buttons ───────────────────────────────
                  PrimaryButton(
                    label: 'PLAY AGAIN',
                    icon: Icons.replay_rounded,
                    onTap: _restart,
                    width: 260,
                  ),

                  const SizedBox(height: 14),

                  GhostButton(
                    label: 'BACK TO HOME',
                    icon: Icons.home_outlined,
                    onTap: _goHome,
                    width: 260,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
