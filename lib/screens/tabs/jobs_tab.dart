import 'package:flutter/material.dart';
import '../../l10n/locale_provider.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';

/// Guide-side screen: availability calendar + upcoming jobs.
class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, bool> _availability = {}; // 'YYYY-MM-DD' -> available
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final av = await SocialService.instance.myAvailability();
      final jobs = await SocialService.instance.myJobs();
      if (mounted) {
        setState(() {
          _availability.clear();
          for (final a in av) {
            _availability[a['date'] as String] = (a['available'] as bool?) ?? true;
          }
          _jobs = jobs;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _tapDay(DateTime day) {
    final key = _key(day);
    final current = _availability[key];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Availability for ${day.day}/${day.month}/${day.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
                current == null
                    ? 'Not set yet'
                    : (current ? 'Currently: Available' : 'Currently: Not available'),
                style:
                    const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white),
                    onPressed: () => _setDay(key, true, ctx),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Available'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger)),
                    onPressed: () => _setDay(key, false, ctx),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Not available'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDay(String key, bool available, BuildContext ctx) async {
    setState(() => _availability[key] = available);
    Navigator.pop(ctx);
    try {
      await SocialService.instance.setAvailability(key, available);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          color: AppColors.teal, size: 26),
                      const SizedBox(width: 10),
                      Text(context.t('jobs'),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Set your availability, then see your bookings',
                      style:
                          TextStyle(color: AppColors.inkFaint, fontSize: 13)),
                  const SizedBox(height: 16),
                  _calendar(),
                  const SizedBox(height: 12),
                  _legend(),
                  const SizedBox(height: 20),
                  const Text('UPCOMING JOBS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.ink)),
                  const SizedBox(height: 10),
                  if (_jobs.isEmpty)
                    _emptyJobs()
                  else
                    ..._jobs.map(_jobCard),
                ],
              ),
            ),
    );
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun=0
    final today = DateTime.now();
    final cells = <Widget>[];
    for (final w in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      cells.add(Center(
          child: Text(w,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.inkFaint))));
    }
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      final key = _key(day);
      final avail = _availability[key];
      final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
      Color? bg;
      Color fg = AppColors.ink;
      if (avail == true) {
        bg = AppColors.teal.withOpacity(0.22);
        fg = AppColors.ink;
      } else if (avail == false) {
        bg = AppColors.danger.withOpacity(0.15);
        fg = AppColors.danger;
      }
      cells.add(GestureDetector(
        onTap: isPast ? null : () => _tapDay(day),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('$d',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPast ? AppColors.inkFaint.withOpacity(0.4) : fg)),
          ),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left, color: AppColors.ink),
              ),
              Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink)),
              IconButton(
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right, color: AppColors.ink),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _legend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(AppColors.teal, 'Available'),
        const SizedBox(width: 16),
        dot(AppColors.danger.withOpacity(0.15), 'Not available'),
        const SizedBox(width: 16),
        dot(AppColors.surfaceAlt, 'Not set'),
      ],
    );
  }

  Widget _emptyJobs() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.event_available_outlined,
              size: 40, color: AppColors.inkFaint),
          SizedBox(height: 10),
          Text('No upcoming jobs yet',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          SizedBox(height: 4),
          Text('Bookings from travellers will show here',
              style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> j) {
    final name = (j['tourist_name'] as String?) ?? 'Traveller';
    final flag = (j['tourist_flag'] as String?) ?? '🌍';
    final date = (j['date'] as String?) ?? '';
    final touristId = j['tourist_id'] as int?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name $flag',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(date,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: touristId == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          friendId: '$touristId',
                          friendUserId: touristId,
                          friendName: name,
                          friendFlag: flag,
                          friendAvatarColor: AppColors.teal,
                          isFriend: true,
                        ),
                      ),
                    ),
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.teal),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];
}
