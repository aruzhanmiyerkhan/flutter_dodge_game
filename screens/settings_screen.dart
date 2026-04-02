import 'package:flutter/material.dart';
import '../main.dart';
import '../models/settings.dart';
import '../widgets/common_widgets.dart';

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local copies — committed on "Back"
  late bool _sound;
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    _sound      = widget.settings.soundEnabled;
    _difficulty = widget.settings.difficulty;
  }

  void _save() {
    widget.settings.soundEnabled = _sound;
    widget.settings.difficulty   = _difficulty;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textSec),
          onPressed: _save,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textPri,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sound ────────────────────────────────────
              const SectionHeader(title: 'AUDIO'),
              SettingsRow(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.volume_up_rounded,
                          color: AppTheme.accent, size: 20),
                      SizedBox(width: 12),
                      Text('Sound Effects',
                          style: TextStyle(
                              color: AppTheme.textPri, fontSize: 15)),
                    ]),
                    Switch(
                      value: _sound,
                      onChanged: (v) => setState(() => _sound = v),
                      activeColor: AppTheme.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Difficulty ───────────────────────────────
              const SectionHeader(title: 'DIFFICULTY'),
              ...Difficulty.values.map((d) => _DiffTile(
                    difficulty: d,
                    selected: _difficulty == d,
                    onTap: () => setState(() => _difficulty = d),
                  )),

              const Spacer(),

              // ── Save button ──────────────────────────────
              Center(
                child: PrimaryButton(
                  label: 'SAVE & BACK',
                  icon: Icons.check_rounded,
                  onTap: _save,
                  width: 240,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Difficulty Tile ──────────────────────────────────────────────────────────

class _DiffTile extends StatelessWidget {
  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  const _DiffTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  static const _meta = {
    Difficulty.easy: (
      label: 'Easy',
      subtitle: 'Slow obstacles, relaxed pace',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: AppTheme.success,
    ),
    Difficulty.medium: (
      label: 'Medium',
      subtitle: 'Balanced challenge',
      icon: Icons.sentiment_neutral_rounded,
      color: AppTheme.gold,
    ),
    Difficulty.hard: (
      label: 'Hard',
      subtitle: 'Fast and unforgiving',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: AppTheme.danger,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta[difficulty]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? m.color.withOpacity(0.1) : AppTheme.surface,
          border: Border.all(
            color: selected ? m.color : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(m.icon, color: m.color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? m.color : AppTheme.textPri,
                      )),
                  Text(m.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSec)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: m.color, size: 20),
          ],
        ),
      ),
    );
  }
}
