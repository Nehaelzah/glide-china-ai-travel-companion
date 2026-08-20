import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'timeline_screen.dart';
import 'chat_tab.dart';

/// Full monthly calendar view showing saved itineraries with color-coded dots.
class MyItineraryScreen extends StatefulWidget {
  const MyItineraryScreen({super.key});

  @override
  State<MyItineraryScreen> createState() => _MyItineraryScreenState();
}

class _MyItineraryScreenState extends State<MyItineraryScreen> {
  late DateTime _viewMonth; // first day of the displayed month
  DateTime? _selectedDate;
  bool _loading = false;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
    _fetchMonth();
  }

  Future<void> _fetchMonth() async {
    setState(() => _loading = true);
    try {
      final state = context.read<AppState>();
      final from = _viewMonth;
      final to = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
      final res = await ApiClient.instance.get(
        '/api/itineraries',
        params: {
          'from_date': _fmt(from),
          'to_date': _fmt(to),
        },
      );
      final list = res.data as List? ?? [];
      for (final item in list) {
        final day = ItineraryDay.fromJson(item as Map<String, dynamic>);
        state.setItinerary(day);
      }
      state.setItinerariesLoaded();
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
      _fetchMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
      _fetchMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = _viewMonth.weekday; // 1=Mon ... 7=Sun

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(context.t('my_itinerary'), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMonth,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ---- Month navigator ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.ink),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_viewMonth.year} / ${_viewMonth.month}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.ink),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ---- Day-of-week header ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _dayNames.map((name) {
                return SizedBox(
                  width: 38,
                  child: Text(name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkFaint)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // ---- Month grid ----
            ..._buildWeeks(daysInMonth, firstWeekday, now, state),
            const SizedBox(height: 24),
            // ---- Selected day itinerary ----
            if (_selectedDate != null)
              _selectedDaySection(state, _selectedDate!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeeks(int daysInMonth, int firstWeekday, DateTime now, AppState state) {
    final cells = <Widget>[];
    // Pad before first day
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox(width: 38, height: 46));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(_viewMonth.year, _viewMonth.month, day);
      final key = _fmt(d);
      final itinerary = state.getItinerary(key);
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final isSelected = _selectedDate != null &&
          d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;

      // Determine dot color based on items
      Color? dotColor;
      if (itinerary != null && itinerary.items.isNotEmpty) {
        // Use the most common type color
        final colorCount = <Color, int>{};
        for (final item in itinerary.items) {
          final c = _itemDotColor(item.type);
          colorCount[c] = (colorCount[c] ?? 0) + 1;
        }
        dotColor = colorCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDate = d),
        child: Container(
          width: 38,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.teal
                : isToday
                    ? AppColors.teal.withOpacity(0.15)
                    : Colors.transparent,
            border: isToday && !isSelected
                ? Border.all(color: AppColors.teal, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$day',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.teal
                              : AppColors.ink)),
              if (dotColor != null)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
            ],
          ),
        ),
      ));
    }
    // Grid: 7 per row
    final rows = <Widget>[];
    int idx = 0;
    while (idx < cells.length) {
      final rowCells = cells.sublist(idx, (idx + 7) > cells.length ? cells.length : idx + 7);
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: rowCells,
        ),
      ));
      idx += 7;
    }
    return rows;
  }

  Color _itemDotColor(String type) {
    switch (type) {
      case 'attraction':
      case 'entertainment':
        return Colors.blue;
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _selectedDaySection(AppState state, DateTime date) {
    final key = _fmt(date);
    final day = state.getItinerary(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${date.year}/${date.month}/${date.day}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (day != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${day.totalHours}h',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (day != null) ...[
          ...day.items.map((item) => _itineraryItemCard(item, day)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TimelineScreen(day: day),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timeline, size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(context.t('view_timeline'),
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Delete day button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _deleteItinerary(day),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(context.t('delete_itinerary')),
            ),
          ),
        ] else ...[
          _emptyDay(date),
        ],
      ],
    );
  }

  Widget _itineraryItemCard(ItineraryItem item, ItineraryDay day) {
    final (mIcon, mColor) = _itemMeta(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            if (item.time.isNotEmpty)
              SizedBox(
                width: 48,
                child: Text(item.time,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal)),
              ),
            // Icon
            Icon(mIcon, size: 18, color: mColor),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.ink)),
                  if (item.location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.inkFaint),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(item.location,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkFaint),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  if (item.duration.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('⏱ ${item.duration}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkFaint)),
                    ),
                ],
              ),
            ),
            // Delete button
            InkWell(
              onTap: () => _deleteItem(day, item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 16, color: AppColors.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _itemMeta(String type) {
    switch (type) {
      case 'food':
        return (Icons.restaurant, Colors.orange);
      case 'transport':
        return (Icons.directions_bus, Colors.green);
      case 'entertainment':
        return (Icons.nightlife, Colors.purple);
      case 'rest':
        return (Icons.hotel, Colors.grey);
      default:
        return (Icons.place, Colors.blue);
    }
  }

  Widget _emptyDay(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 44, color: AppColors.inkFaint),
          const SizedBox(height: 10),
          Text(context.t('no_itinerary'),
              style: TextStyle(
                  color: AppColors.inkFaint, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back to Chat tab (tab 0)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.chat, size: 18),
            label: Text(context.t('go_to_chat_plan')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(ItineraryDay day, ItineraryItem item) async {
    final updatedItems = day.items.where((i) => i != item).toList();
    try {
      final res = await ApiClient.instance.post('/api/itineraries/save', data: {
        'date': day.date,
        'title': day.title,
        'items': updatedItems.map((i) => i.toJson()).toList(),
      });
      final updated = ItineraryDay.fromJson(res.data as Map<String, dynamic>);
      if (mounted) {
        context.read<AppState>().setItinerary(updated);
      }
    } catch (_) {
      if (mounted) showGlideSnack(context, 'Failed to delete', icon: Icons.error);
    }
  }

  Future<void> _deleteItinerary(ItineraryDay day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('confirm_delete')),
        content: Text(context.t('delete_itinerary_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (day.id != null) {
        await ApiClient.instance.delete('/api/itineraries/${day.id}');
      } else {
        // Save empty items to clear the day
        await ApiClient.instance.post('/api/itineraries/save', data: {
          'date': day.date,
          'title': day.title,
          'items': [],
        });
      }
      if (mounted) {
        context.read<AppState>().removeItinerary(day.date);
      }
    } catch (_) {
      if (mounted) showGlideSnack(context, 'Failed to delete', icon: Icons.error);
    }
  }
}
