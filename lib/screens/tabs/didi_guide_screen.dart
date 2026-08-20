import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Step-by-step tutorial: how to download and use Didi Chuxing.
class DidiGuideScreen extends StatelessWidget {
  const DidiGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Download Didi Chuxing',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: const FloatingBackButton(),
      ),
      body: GlideBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            _HeaderCard(),
            SizedBox(height: 16),
            _SectionTitle('Why you need Didi'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.info_outline,
              text: 'Didi is China\'s largest ride-hailing platform (like '
                  'Uber). It\'s the most reliable way to get around cities '
                  '— cheaper than taxis, available 24/7, and the app has '
                  'built-in English support.',
            ),
            SizedBox(height: 20),
            _SectionTitle('Step-by-Step Guide'),
            SizedBox(height: 10),
            _StepCard(
              number: 1,
              title: 'Download Didi Chuxing',
              details: [
                'Open App Store (iOS) or Google Play Store (Android).',
                'Search for "Didi Chuxing" (滴滴出行).',
                'Look for the app with a white taxi icon on a teal background.',
                'Tap "Install" (~120MB download).',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 2,
              title: 'Set up your account',
              details: [
                'Open Didi and select your language (English is supported).',
                'Tap "Register" and enter your phone number.',
                'A Chinese number works best — use the one from your eSIM.',
                'Enter the SMS verification code.',
                'You can skip adding a payment method initially — Didi '
                    'supports Alipay and WeChat Pay.',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 3,
              title: 'Link a payment method',
              details: [
                'Go to "Me" > "Payment" > "Add Payment Method".',
                'Option A: Link Alipay (recommended — simplest).',
                'Option B: Link WeChat Pay.',
                'Option C: Add an international credit card '
                    '(Visa/Mastercard — may have limited support).',
                'Note: Cash payment to the driver is also available in most cities.',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 4,
              title: 'Request your first ride',
              details: [
                'Enter your destination in English or Chinese.',
                'Select ride type:',
                '   • Express (快车) — standard, cheapest option',
                '   • Premier (专车) — premium car, higher quality',
                '   • Taxi (出租车) — regular metered taxi',
                '   • Hitch (顺风车) — carpool, even cheaper',
                'Confirm the price (shown upfront) and tap "Request".',
                'Track your driver on the map — they\'ll call or message you.',
                'Pay automatically via your linked method when the trip ends.',
              ],
            ),
            SizedBox(height: 20),
            _SectionTitle('💡 Pro Tips'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.lightbulb_outline,
              text: 'Your pickup/drop-off address will be in Chinese for '
                  'the driver. Always confirm your exact location using the '
                  'pin on the map rather than just the text address.',
            ),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.translate,
              text: 'Didi has a built-in chat translator — messages from '
                  'your driver are automatically translated. You can also '
                  'use the "Contact Driver" button to call directly.',
            ),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.safety_check,
              text: 'Safety features: share your trip with a friend, '
                  'emergency contact button, and driver verification. '
                  'All rides are GPS-tracked in real time.',
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
          colors: [Color(0xFF00A14B), Color(0xFF7FD13B)],
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
                child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Your ride, anywhere in China',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Didi is the go-to app for getting around Chinese cities. '
            'It\'s affordable, reliable, and the English interface makes '
            'it easy for first-time visitors.',
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
