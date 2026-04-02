import 'package:flutter/material.dart';
import '../main.dart';
import '../models/settings.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GameSettings _settings = GameSettings();
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(settings: _settings),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(settings: _settings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo / Hero ──────────────────────────────
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 52,
                    color: AppTheme.accent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ────────────────────────────────────
              const Text(
                'DODGE',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppTheme.textPri,
                  height: 1,
                ),
              ),
              const Text(
                'MASTER',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppTheme.accent,
                  height: 1,
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Survive as long as you can',
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSec,
                    letterSpacing: 1),
              ),

              const SizedBox(height: 60),

              // ── Buttons ──────────────────────────────────
              PrimaryButton(
                label: 'START GAME',
                icon: Icons.play_arrow_rounded,
                onTap: _startGame,
                width: 240,
              ),

              const SizedBox(height: 14),

              GhostButton(
                label: 'SETTINGS',
                icon: Icons.settings_outlined,
                onTap: _openSettings,
                width: 240,
              ),

              const SizedBox(height: 48),

              // ── Difficulty badge ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Difficulty: ',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSec)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _diffColor(_settings.difficulty)
                          .withOpacity(0.15),
                      border: Border.all(
                          color: _diffColor(_settings.difficulty)
                              .withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _settings.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _diffColor(_settings.difficulty),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _diffColor(Difficulty d) => switch (d) {
        Difficulty.easy   => AppTheme.success,
        Difficulty.medium => AppTheme.gold,
        Difficulty.hard   => AppTheme.danger,
      };
}
