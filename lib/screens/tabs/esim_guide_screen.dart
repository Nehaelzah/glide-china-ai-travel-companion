import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Step-by-step tutorial: how to get a Chinese SIM / eSIM before you arrive.
class EsimGuideScreen extends StatelessWidget {
  const EsimGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Get Your Chinese SIM / eSIM',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: const FloatingBackButton(),
      ),
      body: GlideBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            _HeaderCard(),
            SizedBox(height: 16),
            _SectionTitle('Why you need a Chinese number'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.info_outline,
              text: 'A Chinese phone number is essential for DiDi (rides), '
                  'Alipay/WeChat Pay verification, 12306 (trains), and '
                  'restaurant waitlists. An eSIM lets you activate before '
                  'you land — no SIM swap needed.',
            ),
            SizedBox(height: 20),
            _SectionTitle('Step-by-Step Guide'),
            SizedBox(height: 10),
            _StepCard(
              number: 1,
              title: 'Check your phone compatibility',
              details: [
                'Make sure your phone is unlocked and supports eSIM.',
                'Most iPhones (XR and later, except Chinese models) support eSIM.',
                'Most recent Android flagships (Samsung, Google Pixel, Huawei) '
                    'also support eSIM — check your settings under '
                    'Settings > Mobile Network > SIM Manager.',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 2,
              title: 'Choose an eSIM provider',
              details: [
                'We recommend Nomad eSIM — they offer reliable China data '
                    'plans with competitive pricing.',
                'Other options: Airalo, Holafly, or China Unicom direct eSIM.',
              ],
              highlight: true,
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 3,
              title: 'Purchase & install your eSIM',
              details: [
                'Download the Nomad app (or provider\'s app) from App Store '
                    '/ Google Play.',
                'Select "China" as your destination.',
                'Choose a plan (see recommended plans below).',
                'Complete payment — they accept Visa, Mastercard, PayPal.',
                'Follow the in-app instructions to install the eSIM profile '
                    'to your phone (usually just tap "Install").',
              ],
            ),
            SizedBox(height: 10),
            _StepCard(
              number: 4,
              title: 'Activate when you arrive',
              details: [
                'Most eSIMs activate automatically upon connecting to a '
                    'Chinese network.',
                'Enable the eSIM line in your phone settings.',
                'Ensure "Data Roaming" is ON for the eSIM line.',
                'You\'ll receive a confirmation SMS — keep it as proof.',
                'Your Chinese number is now active!',
              ],
            ),
            SizedBox(height: 20),
            _SectionTitle('🏆 Recommended: Nomad eSIM Plans'),
            SizedBox(height: 10),
            _PlanCard(
              name: 'China 5GB – 30 Days',
              price: '\$8.99 USD',
              features: [
                '5GB high-speed data on China Unicom 4G/5G',
                '30-day validity',
                'No contract, no ID required',
                'Instant delivery via email',
              ],
              tag: 'Best Value',
            ),
            SizedBox(height: 10),
            _PlanCard(
              name: 'China 10GB – 30 Days',
              price: '\$14.99 USD',
              features: [
                '10GB high-speed data on China Unicom 4G/5G',
                '30-day validity',
                'Includes a Chinese phone number (SMS only)',
                'Top up online if you run out',
              ],
              tag: 'Most Popular',
            ),
            SizedBox(height: 10),
            _PlanCard(
              name: 'China Unlimited – 15 Days',
              price: '\$24.99 USD',
              features: [
                'Unlimited data (2GB high-speed, then throttled)',
                '15-day validity — perfect for short trips',
                'Chinese phone number included',
                'Supports hotspot tethering',
              ],
              tag: 'Heavy User',
            ),
            SizedBox(height: 24),
            _SectionTitle('💡 Pro Tips'),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.lightbulb_outline,
              text: 'Install the eSIM before you travel — you\'ll need a '
                  'Wi-Fi connection to download the profile. Once installed, '
                  'it activates automatically when you land in China.',
            ),
            SizedBox(height: 10),
            _InfoCard(
              icon: Icons.wifi,
              text: 'Keep your home SIM active for iMessage / WhatsApp / '
                  'banking OTPs. Most phones support dual SIM — use your '
                  'home SIM for calls/SMS and Chinese eSIM for data.',
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
          colors: [AppColors.teal, AppColors.green],
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
                child: const Icon(Icons.sim_card, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Stay connected from the moment you land',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'A Chinese SIM/eSIM gives you data, lets you use ride-hailing, '
            'food delivery, and maps, and is required for most Chinese apps. '
            'Setting one up before you arrive saves time and hassle.',
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
  final bool highlight;

  const _StepCard({
    required this.number,
    required this.title,
    required this.details,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlight ? AppColors.teal : AppColors.line;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.teal.withOpacity(0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: borderColor.withOpacity(highlight ? 0.5 : 0.3)),
        boxShadow: highlight ? AppShadows.soft : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight ? AppColors.teal : AppColors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: TextStyle(
                    color: highlight ? Colors.white : AppColors.teal,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  )),
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

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final String tag;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.features,
    required this.tag,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(price,
              style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f,
                        style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12.5,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
