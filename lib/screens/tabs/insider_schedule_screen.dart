import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/social_service.dart';
import '../../theme/app_theme.dart';

/// Insider work-calendar page — shows 3 featured guide examples (with
/// clickable avatar → video) and the Insider's own job schedule.
class InsiderScheduleScreen extends StatefulWidget {
  const InsiderScheduleScreen({super.key});

  @override
  State<InsiderScheduleScreen> createState() => _InsiderScheduleScreenState();
}

class _InsiderScheduleScreenState extends State<InsiderScheduleScreen> {
  // ── 3 featured guide examples ──────────────────────────────────────
  static final List<_GuideInfo> _guides = [
    _GuideInfo(
      name: 'Emily Chen',
      subtitle: 'English · 🏛️ Sightseeing Guide',
      avatarAsset: 'assets/videos/en_pic.jpg',
      videoAsset: 'assets/videos/en_guide.mp4',
    ),
    _GuideInfo(
      name: 'Sophie Laurent',
      subtitle: 'Français · 🏛️ Guide Touristique',
      avatarAsset: 'assets/videos/fa_pic.jpg',
      videoAsset: 'assets/videos/fra_guide.mp4',
    ),
    _GuideInfo(
      name: 'Yuki Tanaka',
      subtitle: '日本語 · 💼 Business Translation',
      avatarAsset: 'assets/videos/ja_pic.jpg',
      videoAsset: 'assets/videos/ja_guide.mp4',
    ),
  ];

  // ── Jobs ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _jobs = [];
  bool _loadingJobs = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await SocialService.instance.myJobs();
      if (mounted) setState(() {
        _jobs = jobs;
        _loadingJobs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  // ── Play video ─────────────────────────────────────────────────
  Future<void> _playVideo(String assetPath) async {
    if (kIsWeb) {
      // On web, assets are served directly by the dev server
      await launchUrl(
        Uri.parse('/$assetPath'),
        mode: LaunchMode.platformDefault,
      );
      return;
    }

    // Copy asset to temp directory
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

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Group jobs by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final j in _jobs) {
      final date = j['date'] as String? ?? '';
      grouped.putIfAbsent(date, () => []).add(j);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(
          'Work Calendar',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        iconTheme: const IconThemeData(color: AppColors.ink),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Featured Insiders ──────────────────────────────────────
          _sectionHeader('Featured Insiders'),
          const SizedBox(height: 16),
          _buildGuideRow(),
          const SizedBox(height: 28),

          // ── Divider ────────────────────────────────────────────────
          Container(height: 1, color: AppColors.inkFaint.withOpacity(0.2)),
          const SizedBox(height: 20),

          // ── My Schedule ────────────────────────────────────────────
          _sectionHeader('My Schedule'),
          const SizedBox(height: 16),

          if (_loadingJobs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_jobs.isEmpty)
            _buildEmptySchedule()
          else
            ...sortedDates.map((date) => _buildDateGroup(date, grouped[date]!)),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildGuideRow() {
    return SizedBox(
      height: 210,
      child: Row(
        children: _guides.asMap().entries.map((entry) {
          final i = entry.key;
          final g = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 8 : 0, right: i < _guides.length - 1 ? 8 : 0),
              child: _GuideCard(
                guide: g,
                showFinger: i == 0,
                onPlay: () => _playVideo(g.videoAsset),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.inkFaint),
          const SizedBox(height: 12),
          const Text(
            'No scheduled jobs yet',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> jobs) {
    // Parse date for display
    final dt = DateTime.tryParse(date);
    final displayDate = dt != null
        ? '${dt.month}/${dt.day} ${_weekday(dt.weekday)}'
        : date;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.teal.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Jobs for this date
          ...jobs.map((j) => _buildJobCard(j)),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final note = job['note'] as String? ?? '';
    final touristName = job['tourist_name'] as String? ?? 'Traveller';
    final touristFlag = job['tourist_flag'] as String? ?? '🌍';

    // Try to extract time from the note (assumes format like "10:00 - description")
    String time = '';
    String desc = note;
    final timeMatch = RegExp(r'^(\d{1,2}:\d{2})\s*[-–—]\s*(.*)').firstMatch(note);
    if (timeMatch != null) {
      time = timeMatch.group(1) ?? '';
      desc = timeMatch.group(2) ?? note;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Time column
          if (time.isNotEmpty)
            Container(
              width: 56,
              alignment: Alignment.center,
              child: Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
          if (time.isNotEmpty) const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(touristFlag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      touristName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(int wd) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[wd.clamp(1, 7)];
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Helper models & widgets
// ═══════════════════════════════════════════════════════════════════════

class _GuideInfo {
  final String name;
  final String subtitle;
  final String avatarAsset;
  final String videoAsset;
  const _GuideInfo({
    required this.name,
    required this.subtitle,
    required this.avatarAsset,
    required this.videoAsset,
  });
}

/// A card showing one featured guide with a clickable avatar.
class _GuideCard extends StatefulWidget {
  final _GuideInfo guide;
  final bool showFinger;
  final VoidCallback onPlay;

  const _GuideCard({
    required this.guide,
    required this.showFinger,
    required this.onPlay,
  });

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Clickable avatar ──────────────────────────────────────
        GestureDetector(
          onTap: widget.onPlay,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              backgroundColor: AppColors.surface,
              backgroundImage: AssetImage(g.avatarAsset),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // ── 👆 Finger pointer (first guide only) ────────────────
        if (widget.showFinger)
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, _) => Transform.scale(
              scale: _pulseAnim.value,
              child: const Text('👆', style: TextStyle(fontSize: 22)),
            ),
          )
        else
          const SizedBox(height: 26),

        const SizedBox(height: 4),
        // ── Name ─────────────────────────────────────────────────
        Text(
          g.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        // ── Subtitle (lang + specialty) ──────────────────────────
        Text(
          g.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
