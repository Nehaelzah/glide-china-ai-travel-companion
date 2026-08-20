import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/locale_provider.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import 'view_profile_screen.dart';

/// Bottom-tab screen: a LIST of nearby verified insiders.
class LocalGuidesTab extends StatefulWidget {
  const LocalGuidesTab({super.key});

  @override
  State<LocalGuidesTab> createState() => _LocalGuidesTabState();
}

class _LocalGuidesTabState extends State<LocalGuidesTab> {
  List<Map<String, dynamic>> _guides = [];
  bool _loading = true;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _dateKey() => _filterDate == null
      ? null
      : '${_filterDate!.year.toString().padLeft(4, '0')}-${_filterDate!.month.toString().padLeft(2, '0')}-${_filterDate!.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
      await SocialService.instance.nearbyGuides(date: _dateKey());
      // Sort: available first, then unknown, then unavailable — then distance
      const order = {'available': 0, 'unknown': 1, 'unavailable': 2};
      list.sort((a, b) {
        final ao = order[a['availability']] ?? 1;
        final bo = order[b['availability']] ?? 1;
        if (ao != bo) return ao.compareTo(bo);
        return (a['distance_meters'] as int? ?? 0)
            .compareTo(b['distance_meters'] as int? ?? 0);
      });
      if (mounted) setState(() => _guides = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
      _load();
    }
  }

  String _dist(int m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '$m m';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined,
                    color: AppColors.teal, size: 26),
                const SizedBox(width: 10),
                const Text('Insiders',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Verified insiders ready to guide you',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 13)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _guides.isEmpty
                ? _emptyState()
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: _guides.length,
                itemBuilder: (context, i) => _guideCard(_guides[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Column(
            children: [
              const Icon(Icons.travel_explore_outlined,
                  size: 48, color: AppColors.inkFaint),
              const SizedBox(height: 12),
              const Text('No insiders nearby yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              const Text('Pull down to refresh',
                  style: TextStyle(color: AppColors.inkFaint, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilityBadge(String status) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'available':
        bg = AppColors.teal.withOpacity(0.15);
        fg = AppColors.teal;
        label = 'Available';
        break;
      case 'unavailable':
        bg = AppColors.danger.withOpacity(0.12);
        fg = AppColors.danger;
        label = 'Busy';
        break;
      default:
        bg = AppColors.inkFaint.withOpacity(0.12);
        fg = AppColors.inkSoft;
        label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  void _openGuideProfile(Map<String, dynamic> g) {
    final userId = g['user_id'] as int?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewProfileScreen(
          id: '$userId',
          userId: userId,
          nickname: (g['nickname'] as String?) ?? 'Guide',
          flag: (g['flag'] as String?) ?? '🇨🇳',
          country: (g['nationality'] as String?) ?? '',
          daysInChina: 1,
          distance: _dist((g['distance_meters'] as int?) ?? 0),
          avatarColor: AppColors.teal,
        ),
      ),
    );
  }

  /// Play a guide's introduction video using the system media player.
  Future<void> _playVideo(String assetPath) async {
    if (kIsWeb) {
      // On web, assets are served directly by the dev server
      await launchUrl(
        Uri.parse('/$assetPath'),
        mode: LaunchMode.platformDefault,
      );
      return;
    }

    // Mobile/desktop: copy asset to temp directory
    final dir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List());
    }

    // Build the URI to share with the system player
    final Uri uri;
    if (Platform.isAndroid) {
      // Android 7+ requires content:// URI via FileProvider,
      // matching the <cache-path name="cache" path="." /> in file_paths.xml
      uri = Uri.parse(
          'content://com.example.glide_china.fileprovider/cache/$fileName');
    } else {
      uri = Uri.file(file.path);
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _guideCard(Map<String, dynamic> g) {
    final nickname = (g['nickname'] as String?) ?? 'Guide';
    final flag = (g['flag'] as String?) ?? '🇨🇳';
    final userId = g['user_id'] as int?;
    final dist = _dist((g['distance_meters'] as int?) ?? 0);
    final langs = (g['languages'] as List?)?.cast<String>() ?? const [];
    final interests = (g['interests'] as List?)?.cast<String>() ?? const [];
    final avatarAsset = g['avatar_asset'] as String?;
    final videoAsset = g['video_asset'] as String?;
    // Synthetic values for demo when backend doesn't provide them
    final rating = 4.5 + ((userId ?? 1).abs() % 6) * 0.1;
    //final pricePerHour = 30 + ((userId ?? 1).abs() % 12);
    final pricePerDay = 580;
    final bio = interests.isEmpty
        ? 'Local expert ready to show you around'
        : '${interests.take(2).join(' & ')} enthusiast — let me show you the best!';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card + 4),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + rating + price
          Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: videoAsset != null
                        ? () => _playVideo(videoAsset!)
                        : null,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.teal,
                      backgroundImage: avatarAsset != null
                          ? AssetImage(avatarAsset)
                          : null,
                      child: avatarAsset != null
                          ? null
                          : Text(nickname[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24)),
                    ),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified,
                          color: AppColors.teal, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.ink)),
                        const SizedBox(width: 6),
                        Text(flag, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Distance — weakened, inline, small grey
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 11, color: AppColors.inkFaint),
                        const SizedBox(width: 2),
                        Text('$dist away',
                            style: const TextStyle(color: AppColors.inkFaint, fontSize: 11)),
                        const SizedBox(width: 10),
                        const Icon(Icons.translate, size: 11, color: AppColors.inkFaint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(langs.take(2).join(', '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.inkFaint, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Rating + Price column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('¥$pricePerDay/day',
                  //Text('¥$pricePerHour/h',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.teal)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Personal bio
          Text(bio,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
          const SizedBox(height: 10),
          // Language tags
          Wrap(
            spacing: 6, runSpacing: 4,
            children: langs.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(lang,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teal)),
            )).toList(),
          ),
          const SizedBox(height: 14),
          // Book Now button — full width
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: userId == null ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      friendId: '$userId',
                      friendUserId: userId,
                      friendName: nickname,
                      friendFlag: flag,
                      friendAvatarColor: AppColors.teal,
                      isFriend: true,
                      isGuide: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text("Let's Chat",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.teal, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
