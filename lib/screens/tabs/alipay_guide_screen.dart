import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Step-by-step tutorial: how to download and set up Alipay.
class AlipayGuideScreen extends StatelessWidget {
  const AlipayGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Download & Set Up Alipay',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        leading: const FloatingBackButton(),
      ),
      body: GlideBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            _HeaderCard(),
            SizedBox(height: 16),
            _SectionTitle('Why you need Alipay'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.info_outline,
              text: 'Alipay is the most widely accepted mobile payment platform '
                  'in China. You can use it at restaurants, shops, taxis, '
                  'street vendors, and even temples. Cash is rarely needed.',
            ),
            SizedBox(height: 20),
            _SectionTitle('Step-by-Step Setup'),
            SizedBox(height: 10),
            _StepCard(
              number: 1,
              title: 'Download Alipay',
              details: [
                'Go to the App Store (iOS) or Google Play Store (Android).',
                'Search for "Alipay" — look for the blue app with the '
                    '蚂蚁集团 logo.',
                'Tap "Install" and wait for the download to complete.',
                'App size is ~150MB — ensure you have enough space.',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 2,
              title: 'Create your account',
              details: [
                'Open Alipay and tap "Register" / "Sign Up".',
                'Select your country/region code (e.g. +1 for US, +44 for UK).',
                'Enter your phone number — this is why you need a Chinese '
                    'SIM/eSIM first, or use your international number.',
                'Enter the SMS verification code sent to your phone.',
                'Set a strong password (8+ characters with letters and numbers).',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 3,
              title: 'Add your international card (Tour Pass)',
              details: [
                'Go to "Me" tab > "Bank Cards" or search "Tour Pass".',
                'Alipay\'s Tour Pass lets foreign visitors link Visa, '
                    'Mastercard, or JCB cards.',
                'You can top up with as little as ¥100 (~\$14 USD).',
                'Unused balance is refunded when you leave China.',
                'Alternatively, link your foreign card directly via '
                    '"Cards" section — some cards work without Tour Pass.',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 4,
              title: 'Explore essential features',
              details: [
                'Scan to Pay — the most common way. Open app > tap "Scan" '
                    'or "Pay" to show your QR code.',
                'Didipinche (ride-hailing) — available inside Alipay\'s app.',
                'Health Code / QR code for entry (if required).',
                'Hotel booking, flight tickets, and DiDi miniprograms.',
                'Translate feature: tap the language icon in the top bar.',
              ],
            ),
            SizedBox(height: 20),
            _SectionTitle('💡 Pro Tips'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.lightbulb_outline,
              text: 'Set up Alipay BEFORE you travel while you still have '
                  'access to your home SMS and email. Some verification steps '
                  'are easier with your home network.',
            ),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.security,
              text: 'Enable fingerprint / face ID in Alipay settings for '
                  'faster payments. Go to "Me" > "Settings" > "Security" '
                  '> "Biometric Payment".',
            ),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.language,
              text: 'Alipay supports English interface — switch in Settings '
                  '> "General" > "Language". Most menus and receipts will '
                  'be in English.',
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
          colors: [Color(0xFF1677FF), Color(0xFF69B1FF)],
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
                child: const Icon(Icons.payments, color: AppColors.ink, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Pay for almost everything with your phone',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Alipay is China\'s most popular payment app. Set it up once '
                'and you can pay at millions of merchants by scanning a QR code '
                '— no cash, no card swiping needed.',
            style: const TextStyle(
              color: AppColors.ink,
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
                                  color: AppColors.ink,
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
                    color: AppColors.ink, fontSize: 12.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
