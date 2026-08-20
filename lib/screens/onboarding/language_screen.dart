import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/locale_provider.dart';
import '../../l10n/app_translations.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/glide_logo.dart';
import 'login_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  AppLanguage? _selected;
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Default to first language so wheel starts centred.
    _selected = AppLanguage.all.firstWhere((l) => l.code != 'zh');
    _scrollController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _helloFriendText(String code) {
    const map = <String, String>{
      'en': 'Hello Friend',
      'es': 'Hola Amigo',
      'fr': 'Bonjour Ami',
      'hi': 'नमस्ते दोस्त',
      'ja': 'こんにちは、友達',
      'ko': '안녕 친구',
      'ar': 'مرحباً صديقي',
      'de': 'Hallo Freund',
    };

    return map[code] ?? 'Hello Friend';
  }

  @override
  Widget build(BuildContext context) {
    // Interface languages exclude Chinese (that's the local language, not UI).
    final all = AppLanguage.all.where((l) => l.code != 'zh').toList();
    final selectedCode = _selected?.code ?? 'en';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlideBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const GlideLogo(size: 60),
                const SizedBox(height: 12),

                // App name: clean, bold, dark, and visually consistent.
                const Text(
                  'glide China',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: 22),

                // Friendly Chinese welcome.
                // Removed the old decorative font because it rendered 你好 and 朋友
                // in different visual styles on some devices.
                const Text(
                  '你好，朋友',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 46,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: 10),

                // This changes live with the selected language.
                Text(
                  _helloFriendText(selectedCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Better visual balance: the old gap was too large.
                const Spacer(flex: 2),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppTranslations.get(
                      'choose_language',
                      selectedCode,
                    ),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Wheel picker — centred item auto-selected.
                _buildWheelPicker(all),

                const Spacer(flex: 1),

                GradientButton(
                  label: context.t('continue'),
                  icon: Icons.arrow_forward,
                  onPressed: _selected == null
                      ? null
                      : () {
                    context.read<AppState>().setLanguage(_selected!);
                    context
                        .read<LocaleProvider>()
                        .setLanguage(_selected!.code);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWheelPicker(List<AppLanguage> all) {
    return SizedBox(
      height: 260,
      child: ListWheelScrollView(
        controller: _scrollController,
        itemExtent: 54,
        diameterRatio: 1.5,
        offAxisFraction: 0.05,
        physics: const FixedExtentScrollPhysics(
          parent: BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
        ),
        onSelectedItemChanged: (index) {
          setState(() => _selected = all[index]);
        },
        children: all.map((lang) {
          final selected = _selected?.code == lang.code;
          return _langPill(lang, selected);
        }).toList(),
      ),
    );
  }

  Widget _langPill(AppLanguage lang, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
      child: Opacity(
        opacity: selected ? 1.0 : 0.34,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.teal.withAlpha(90),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              BoxShadow(
                color: selected
                    ? AppColors.teal.withAlpha(60)
                    : Colors.black.withAlpha(8),
                blurRadius: selected ? 14 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                lang.nativeName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
