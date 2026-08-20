import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/glide_logo.dart';
import '../home_shell.dart';

class FirstTimeScreen extends StatefulWidget {
  const FirstTimeScreen({super.key});

  @override
  State<FirstTimeScreen> createState() => _FirstTimeScreenState();
}

class _FirstTimeScreenState extends State<FirstTimeScreen> {
  bool? _firstTime;
  bool _selected = false;

  void _select(bool value) {
    if (_selected) return;
    setState(() {
      _firstTime = value;
      _selected = true;
    });
    // Brief highlight feedback, then navigate
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.setFirstTimeInChina(value);
      state.completeOnboarding();
      // Fire & forget: persist preference to backend
      ApiClient.instance.put('/api/user/profile', data: {
        'first_time_in_china': value,
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final yesColor = const Color(0xFF4CAF50);
    final noColor = const Color(0xFF42A5F5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlideBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // ── Glide swallow mascot with dynamic accessory ──
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const GlideLogo(size: 72, showBadge: true),
                      if (_firstTime == true)
                        const Positioned(
                          right: -8, bottom: -8,
                          child: Text('🎒', style: TextStyle(fontSize: 26)),
                        )
                      else if (_firstTime == false)
                        const Positioned(
                          right: -8, bottom: -8,
                          child: Text('😎', style: TextStyle(fontSize: 26)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── Title ──
                const Text(
                  'Is this your first time in China? 🇨🇳',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll customize your experience based on your answer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                // ── Two big rounded cards ──
                _BigCard(
                  emoji: '🆕',
                  title: 'Yes, first time!',
                  subtitle: 'I need help with apps, payments, and getting around',
                  selected: _firstTime == true,
                  highlightColor: yesColor,
                  onTap: () => _select(true),
                ),
                const SizedBox(height: 16),
                _BigCard(
                  emoji: '😎',
                  title: "No, I've been here before",
                  subtitle: 'Just show me the good stuff',
                  selected: _firstTime == false,
                  highlightColor: noColor,
                  onTap: () => _select(false),
                ),
                const SizedBox(height: 24),
                // ── Selection feedback text ──
                AnimatedOpacity(
                  opacity: _selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _firstTime == true ? yesColor : noColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _firstTime == true
                            ? "Got it! I'll guide you through everything step by step 🐣"
                            : "Welcome back! I'll skip the basics and show you the hidden gems 💎",
                        style: TextStyle(
                          color: _firstTime == true ? yesColor : noColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large rounded selection card used for the Yes / No choice.
class _BigCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final Color highlightColor;
  final VoidCallback onTap;

  const _BigCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
        decoration: BoxDecoration(
          color: selected ? highlightColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: highlightColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.5,
                color: selected ? Colors.white.withOpacity(0.9) : AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
