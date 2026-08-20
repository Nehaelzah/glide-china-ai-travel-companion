import 'package:flutter/material.dart';
import '../l10n/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'tabs/chat_tab.dart';
import 'tabs/local_guides_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/mic_tab.dart';
import 'tabs/radar_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/social_service.dart';

/// The main app shell after onboarding: five tabs — Chat, Pocket, Mic, Radar,
/// Profile — with Mic given a raised centre button.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _isGuide = false;

  @override
  void initState() {
    super.initState();
    _checkGuide();
  }

  Future<void> _checkGuide() async {
    try {
      final isGuide = await SocialService.instance.guideStatus();
      if (mounted && isGuide != _isGuide) setState(() => _isGuide = isGuide);
    } catch (_) {}
  }

  List<Widget> get _pages => [
        const ChatTab(),
        _isGuide ? const JobsTab() : const LocalGuidesTab(),
        const MicTab(),
        const RadarTab(),
        const ProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlideBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: _GlideNavBar(
        index: _index,
        isGuide: _isGuide,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _GlideNavBar extends StatelessWidget {
  final int index;
  final bool isGuide;
  final ValueChanged<int> onTap;

  const _GlideNavBar(
      {required this.index, required this.onTap, this.isGuide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.chat_bubble_outline, Icons.chat_bubble, context.t('chat')),
              isGuide
                  ? _navItem(1, Icons.work_outline, Icons.work, context.t('jobs'))
                  : _navItem(1, Icons.volunteer_activism_outlined, Icons.volunteer_activism, context.t('local_guides')),
              _micItem(2, context.t('mic')),
              _navItem(3, Icons.radar_outlined, Icons.radar, context.t('radar')),
              _navItem(4, Icons.person_outline, Icons.person, context.t('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData active, String label) {
    final selected = index == i;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? active : icon,
                  color: selected ? AppColors.teal : AppColors.inkFaint,
                  size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.teal : AppColors.inkFaint,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micItem(int i, String label) {
    final selected = index == i;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected ? AppShadows.lift : AppShadows.soft,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.teal : AppColors.inkFaint,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
