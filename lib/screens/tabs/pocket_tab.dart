import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/app_guide_sheet.dart';

class PocketTab extends StatefulWidget {
  const PocketTab({super.key});

  @override
  State<PocketTab> createState() => _PocketTabState();
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

class _PocketTabState extends State<PocketTab> {
  String _category = 'All';
  List<ChinaApp> _apps = [];
  List<String> _categories = [];
  bool _loading = true;
  // Most apps are "downloaded" (ready to open); a couple remain un-downloaded for demo.
  final Set<String> _notDownloaded = {'12306'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await MockData.fetchPocketCategories();
    final apps = await MockData.fetchPocketApps();
    if (mounted) {
      setState(() {
        _categories = cats;
        _apps = apps;
        _loading = false;
      });
    }
  }

  Future<void> _downloadApp(BuildContext context, ChinaApp app) async {
    final isDownloaded = !_notDownloaded.contains(app.name);
    if (isDownloaded || app.appStoreUrl.isNotEmpty) {
      final uri = Uri.tryParse(app.appStoreUrl.isNotEmpty
          ? app.appStoreUrl
          : 'https://www.example.com');
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          showGlideSnack(
            context,
            'Opening ${app.name}...',
            icon: Icons.open_in_new,
          );
        }
        return;
      }
    }
    if (context.mounted) {
      showGlideSnack(
        context,
        '${context.t('download')} ${app.name} — ${context.t('coming_soon')}.',
        icon: Icons.download_outlined,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final categories = ['All', ..._categories];
    final apps = _category == 'All'
        ? _apps
        : _apps.where((a) => a.category == _category).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                context.t('pocket'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                context.t('pocket_subtitle'),
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final selected = c == _category;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brandGradient : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        boxShadow: selected ? null : AppShadows.soft,
                      ),
                      child: Text(
                        c == 'All' ? context.t('all') : _categoryLabel(context, c),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: selected ? AppColors.ink : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: apps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _appCard(apps[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadedButton(BuildContext context, ChinaApp app) {
    final isDownloaded = !_notDownloaded.contains(app.name);
    if (isDownloaded) {
      return OutlinedButton.icon(
        onPressed: () => _downloadApp(context, app),
        icon: const Icon(Icons.check_circle, size: 18, color: AppColors.green),
        label: const Text(
          'Opened',
          style: TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: const BorderSide(color: AppColors.green),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => _downloadApp(context, app),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text(
        'Download',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _appCard(ChinaApp app) {
    return SoftCard(
      onTap: () => showAppGuide(context, app),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: app.icon,
                color: app.color,
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
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.tagline,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showAppGuide(context, app),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(
                    context.t('setup_guide'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _downloadedButton(context, app),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
