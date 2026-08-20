import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Step-by-step tutorial: emergency phrase cards for China travel.
class EmergencyGuideScreen extends StatelessWidget {
  const EmergencyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Save Emergency Phrase Cards',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: const FloatingBackButton(),
      ),
      body: GlideBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            _HeaderCard(),
            SizedBox(height: 16),
            _SectionTitle('Why you need phrase cards'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.info_outline,
              text: 'English is not widely spoken in China outside of '
                  'international hotels and tourist hotspots. Having key '
                  'phrases ready on your phone can be a lifesaver in '
                  'emergencies, restaurants, and taxis.',
            ),
            SizedBox(height: 20),
            _SectionTitle('📱 Save these to your phone'),
            SizedBox(height: 10),
            _PhraseCard(
              emoji: '🚑',
              title: 'Medical Emergency',
              english: 'I need a doctor / hospital',
              chinese: '我需要看医生 / 去医院',
              pinyin: 'Wǒ xūyào kàn yīshēng / qù yīyuàn',
              usage: 'Show this to a taxi driver or call 120',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '🆘',
              title: 'Help / Police',
              english: 'Please help me, I need the police',
              chinese: '请帮帮我，我需要报警',
              pinyin: 'Qǐng bāng bāng wǒ, wǒ xūyào bàojǐng',
              usage: 'Call 110 for police — show this to anyone nearby',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '🤧',
              title: 'Allergy / Medical Condition',
              english: 'I am allergic to [peanuts / dairy / shellfish]',
              chinese: '我对[花生 / 牛奶 / 海鲜]过敏',
              pinyin: 'Wǒ duì [huāshēng / niúnǎi / hǎixiān] guòmǐn',
              usage: 'Show to restaurant staff when ordering food',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '🔥',
              title: 'Fire Emergency',
              english: 'Fire! Please evacuate immediately',
              chinese: '着火了！请立即疏散',
              pinyin: 'Zháohuǒ le! Qǐng lìjí shūsàn',
              usage: 'Call 119 for fire — show this to building staff',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '🧭',
              title: 'I\'m Lost',
              english: 'I\'m lost. Can you help me find this address?',
              chinese: '我迷路了。你能帮我找到这个地址吗？',
              pinyin: 'Wǒ mílù le. Nǐ néng bāng wǒ zhǎodào zhège dìzhǐ ma?',
              usage: 'Show your hotel business card or saved address',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '🍽️',
              title: 'Dietary Restriction',
              english: 'I don\'t eat [meat / spicy food / garlic]',
              chinese: '我不吃[肉 / 辣的 / 大蒜]',
              pinyin: 'Wǒ bù chī [ròu / là de / dàsuàn]',
              usage: 'Show to restaurant staff when ordering',
            ),
            SizedBox(height: 8),
            _PhraseCard(
              emoji: '💊',
              title: 'Pharmacy',
              english: 'Where can I find a pharmacy? I need medicine',
              chinese: '哪里有药店？我需要买药',
              pinyin: 'Nǎlǐ yǒu yàodiàn? Wǒ xūyào mǎi yào',
              usage: 'Show to hotel staff or search on Amap',
            ),
            SizedBox(height: 20),
            _SectionTitle('📋 How to use these cards'),
            SizedBox(height: 10),
            _StepCard(
              number: 1,
              title: 'Take screenshots',
              details: [
                'Screenshot each phrase card above.',
                'Save them to a dedicated album "China Travel".',
                'You can access them offline anytime.',
              ],
            ),
            SizedBox(height: 8),
            _StepCard(
              number: 2,
              title: 'Save to Notes / Favorites',
              details: [
                'Copy the Chinese text and paste into your Notes app.',
                'Pin each note to the top for quick access.',
                'Optional: add shortcut widget to your home screen.',
              ],
            ),
            SizedBox(height: 8),
            _StepCard(
              number: 3,
              title: 'Use translation apps as backup',
              details: [
                'Google Translate — works offline with downloaded Chinese.',
                'Apple Translate (iOS) — built-in, works offline.',
                'Pleco — the best Chinese dictionary app.',
                'Point your camera at Chinese text to translate instantly.',
              ],
            ),
            SizedBox(height: 8),
            _StepCard(
              number: 4,
              title: 'Keep hotel info handy',
              details: [
                'Always carry your hotel\'s business card with Chinese address.',
                'Save your hotel\'s Chinese name and phone number.',
                'Share your live location via WeChat or Maps when needed.',
              ],
            ),
            SizedBox(height: 20),
            _SectionTitle('📞 Emergency Numbers'),
            SizedBox(height: 10),
            _EmergencyNumberCard(
              number: '110',
              label: 'Police (公安)',
              icon: Icons.local_police,
            ),
            const SizedBox(height: 6),
            _EmergencyNumberCard(
              number: '120',
              label: 'Ambulance (急救)',
              icon: Icons.medical_services,
            ),
            const SizedBox(height: 6),
            _EmergencyNumberCard(
              number: '119',
              label: 'Fire (火警)',
              icon: Icons.fire_extinguisher,
            ),
            const SizedBox(height: 6),
            _EmergencyNumberCard(
              number: '12110',
              label: 'SMS Police (短信报警)',
              icon: Icons.sms,
              note: 'Text-only police service — useful if you can\'t speak',
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.phone_in_talk,
              text: 'These numbers are FREE to call from any phone in China, '
                  'including your home SIM roaming. Operators may speak '
                  'limited English — say "English please" (请说英语).',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE74C3C), Color(0xFFF39C12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Be prepared for any situation',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Having essential Chinese phrases ready on your phone helps '
            'you navigate unexpected situations with confidence. Save '
            'these cards before you travel.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink));
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final List<String> details;

  const _StepCard({
    required this.number,
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line.withOpacity(0.3)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                for (final d in details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(color: AppColors.teal)),
                        Expanded(
                          child: Text(d,
                              style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12.5,
                                  height: 1.45)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String english;
  final String chinese;
  final String pinyin;
  final String usage;

  const _PhraseCard({
    required this.emoji,
    required this.title,
    required this.english,
    required this.chinese,
    required this.pinyin,
    required this.usage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line.withOpacity(0.3)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(english,
                    style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(chinese,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
                const SizedBox(height: 2),
                Text(pinyin,
                    style: const TextStyle(
                        color: AppColors.inkFaint,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: AppColors.teal.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(usage,
                        style: TextStyle(
                            color: AppColors.teal.withOpacity(0.8),
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.inkSoft, fontSize: 12.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _EmergencyNumberCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final String? note;

  const _EmergencyNumberCard({
    required this.number,
    required this.label,
    required this.icon,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.red)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
                if (note != null)
                  Text(note!,
                      style: const TextStyle(
                          color: AppColors.inkFaint, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
