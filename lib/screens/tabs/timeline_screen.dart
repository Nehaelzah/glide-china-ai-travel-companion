import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../l10n/locale_provider.dart';

/// Vertical timeline view for a single day's itinerary.
///
/// Layout:
///   Top: title banner + total hours
///   Middle: vertical line with circular nodes + time cards
///   Order: transport -> attraction -> food -> transport -> entertainment -> food -> attraction
class TimelineScreen extends StatelessWidget {
  final ItineraryDay day;

  const TimelineScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    // Group items by the 4 modules (category)
    final grouped = <String, List<ItineraryItem>>{};
    for (final item in day.items) {
      final cat = item.category.isEmpty ? 'misc' : item.category;
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    const moduleKeys = ['eat', 'stay', 'go', 'explore', 'misc'];
    final orderedKeys = moduleKeys.where((k) => grouped.containsKey(k)).toList();

    // Build a flat list of sections + items for the timeline
    final sections = <_SectionItem>[];
    for (final key in orderedKeys) {
      sections.add(_SectionItem(key: key, isHeader: true));
      final list = grouped[key]!;
      for (int i = 0; i < list.length; i++) {
        sections.add(_SectionItem(
          key: key,
          isHeader: false,
          item: list[i],
          isFirst: i == 0,
          isLast: i == list.length - 1,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(day.title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: sections.length,
              itemBuilder: (_, i) {
                final sec = sections[i];
                if (sec.isHeader) {
                  return _ModuleHeader(moduleKey: sec.key);
                }
                return _TimelineNode(
                  item: sec.item!,
                  isFirst: sec.isFirst,
                  isLast: sec.isLast,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timeline,
                    color: AppColors.teal, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(
                      '${day.items.length} stops . ${day.totalHours}h total',
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single node on the timeline: vertical line + circle + card.
class _TimelineNode extends StatelessWidget {
  final ItineraryItem item;
  final bool isFirst;
  final bool isLast;

  const _TimelineNode({
    required this.item,
    this.isFirst = false,
    this.isLast = false,
  });

  Color get _color {
    switch (item.type) {
      case 'transport':
        return Colors.blue;
      case 'food':
        return Colors.orange;
      case 'entertainment':
        return Colors.purple;
      case 'rest':
        return Colors.grey;
      default: // attraction
        return Colors.green;
    }
  }

  IconData get _icon {
    switch (item.type) {
      case 'transport':
        return Icons.directions_bus;
      case 'food':
        return Icons.restaurant;
      case 'entertainment':
        return Icons.nightlife;
      case 'rest':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineWidth = 2.0;
    final nodeRadius = 14.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Timeline column (line + node)
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Top line segment
                Expanded(
                  child: Container(
                    width: lineWidth,
                    color: isFirst ? Colors.transparent : AppColors.line,
                  ),
                ),
                // Circle node
                Container(
                  width: nodeRadius * 2,
                  height: nodeRadius * 2,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(_icon, color: Colors.white, size: 14),
                ),
                // Bottom line segment
                Expanded(
                  child: Container(
                    width: lineWidth,
                    color: isLast ? Colors.transparent : AppColors.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 6, bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: _color.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Time + duration
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: AppColors.inkFaint),
                            const SizedBox(width: 4),
                            Text(
                              item.time,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teal),
                            ),
                            if (item.duration.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.duration,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Title
                        Text(
                          item.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Location
                        if (item.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 12, color: AppColors.inkFaint),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.location,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkFaint),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Type label
                        const SizedBox(height: 4),
                        _typeLabel(item.type),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _typeLabel(String type) {
    String label;
    switch (type) {
      case 'transport':
        label = 'Transport';
        break;
      case 'food':
        label = 'Dining';
        break;
      case 'entertainment':
        label = 'Entertainment';
        break;
      case 'rest':
        label = 'Rest';
        break;
      default:
        label = 'Attraction';
    }
    return Text(
      label,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color.withOpacity(0.8)),
    );
  }
}

// ── Helper: a header or item entry in the grouped section list ──
class _SectionItem {
  final String key;
  final bool isHeader;
  final ItineraryItem? item;
  final bool isFirst;
  final bool isLast;

  const _SectionItem({
    required this.key,
    required this.isHeader,
    this.item,
    this.isFirst = false,
    this.isLast = false,
  });
}

// ── Module section header widget ──
class _ModuleHeader extends StatelessWidget {
  final String moduleKey;

  const _ModuleHeader({required this.moduleKey});

  (IconData, Color, String) _meta(BuildContext context) {
    final t = context.t;
    switch (moduleKey) {
      case 'eat':
        return (Icons.restaurant, Colors.orange, t('eat'));
      case 'stay':
        return (Icons.hotel, Colors.grey, t('stay'));
      case 'go':
        return (Icons.directions_bus, Colors.blue, t('go'));
      case 'explore':
        return (Icons.explore, Colors.green, t('explore'));
      default:
        return (Icons.event, Colors.grey, t('general'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _meta(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.line, thickness: 1)),
        ],
      ),
    );
  }
}
