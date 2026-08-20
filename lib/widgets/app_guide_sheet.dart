import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/locale_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Bottom sheet showing an app's setup guide plus Open/Install action.
void showAppGuide(BuildContext context, ChinaApp app) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppGuideSheet(app: app),
  );
}

String _categoryLabel(BuildContext context, String category) {
  const map = <String, String>{
    'Payments': 'cat_payments',
    'Maps': 'cat_maps',
    'Transport': 'cat_transport',
    'Food': 'cat_food',
  };
  final key = map[category];
  return key != null ? context.t(key) : category;
}

class _AppGuideSheet extends StatelessWidget {
  final ChinaApp app;
  const _AppGuideSheet({required this.app});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                AppIconTile(
                  icon: app.icon,
                  color: app.color,
                  size: 60,
                  imageAsset: app.imageAssetPath,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: app.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: app.color.withOpacity(0.25)),
                        ),
                        child: Text(
                          _categoryLabel(context, app.category),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              app.tagline,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            // ---- Permissions section ----
            if (app.category == 'Payments' || app.category == 'Maps')
              _permissionSection(context),
            // ---- Setup steps ----
            Text(
              context.t('setup_guide'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(app.setupSteps.length, (i) {
              final step = app.setupSteps[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              step.instruction,
                              style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Screenshot when imageAsset is provided
                    if (step.imageAsset != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                          child: Image.asset(
                            step.imageAsset!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppRadii.chip),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppColors.inkFaint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 22),
            GradientButton(
              label: '${context.t('open_install')} ${app.name}',
              icon: Icons.download_outlined,
              onPressed: () {
                Navigator.pop(context);
                _downloadApp(context, app);
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                context.t('glide_never_opens'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionSection(BuildContext context) {
    final isPayments = app.category == 'Payments';
    final permissions = isPayments
        ? [
      _PermItem(Icons.camera_alt_outlined,
          'Camera — for scanning QR codes', 'Camera'),
      _PermItem(Icons.folder_outlined,
          'Storage — for saving receipts', 'Storage'),
    ]
        : [
      _PermItem(Icons.location_on_outlined,
          'Location — for navigation', 'Location'),
      _PermItem(Icons.storage_outlined,
          'Storage — for offline maps', 'Storage'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppColors.teal),
                SizedBox(width: 6),
                Text(
                  'Permissions required',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...permissions.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(p.icon, size: 14, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 4),
            Text(
              'These will be requested when you first open ${app.name}.',
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermItem {
  final IconData icon;
  final String desc;
  final String label;
  const _PermItem(this.icon, this.desc, this.label);
}

Future<void> _downloadApp(BuildContext context, ChinaApp app) async {
  if (app.appStoreUrl.isNotEmpty) {
    final uri = Uri.tryParse(app.appStoreUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }
  if (context.mounted) {
    showGlideSnack(context,
        '${context.t('download')} ${app.name} — ${context.t('coming_soon')}.',
        icon: Icons.download_outlined);
  }
}
