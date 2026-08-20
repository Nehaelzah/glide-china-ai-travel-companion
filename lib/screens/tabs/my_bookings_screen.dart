import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';
import 'view_profile_screen.dart';

/// A booking order for the My Bookings page.
class _Booking {
  final int id;
  final String guideName;
  final String guideFlag;
  final int guideId;
  final double rating;
  final String serviceType;
  final String dateTime;
  final int people;
  final String status; // pending | confirmed | ongoing | review | completed | cancelled

  const _Booking({
    required this.id,
    required this.guideName,
    required this.guideFlag,
    required this.guideId,
    required this.rating,
    required this.serviceType,
    required this.dateTime,
    required this.people,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mock data for demo
// ─────────────────────────────────────────────────────────────────────────────

final _mockBookings = [
  _Booking(
    id: 1, guideName: 'Li Wei', guideFlag: '🇨🇳', guideId: 90001,
    rating: 4.9, serviceType: '4-hour City Walk', dateTime: '2026-07-15 10:00', people: 2,
    status: 'ongoing',
  ),
  _Booking(
    id: 2, guideName: 'Zhang Mei', guideFlag: '🇨🇳', guideId: 90002,
    rating: 4.8, serviceType: 'Food Tour', dateTime: '2026-07-20 11:30', people: 1,
    status: 'confirmed',
  ),
  _Booking(
    id: 3, guideName: 'Chen Xiaoyun', guideFlag: '🇨🇳', guideId: 90004,
    rating: 4.7, serviceType: 'Photo Walk', dateTime: '2026-07-25 08:00', people: 3,
    status: 'pending',
  ),
  _Booking(
    id: 4, guideName: 'Huang Ting', guideFlag: '🇨🇳', guideId: 90006,
    rating: 4.9, serviceType: 'History & Culture Tour', dateTime: '2026-06-28 14:00', people: 2,
    status: 'review',
  ),
  _Booking(
    id: 5, guideName: 'Li Wei', guideFlag: '🇨🇳', guideId: 90001,
    rating: 4.9, serviceType: 'Airport Pick-up', dateTime: '2026-06-10 09:00', people: 1,
    status: 'completed',
  ),
  _Booking(
    id: 6, guideName: 'Wang Jun', guideFlag: '🇨🇳', guideId: 90003,
    rating: 4.5, serviceType: 'Nightlife Guide', dateTime: '2026-06-05 20:00', people: 4,
    status: 'cancelled',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('My Bookings',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink)),
      ),
      body: _mockBookings.isEmpty
          ? _emptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _mockBookings.length,
        itemBuilder: (_, i) => _bookingCard(context, _mockBookings[i]),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Empty state
  // ───────────────────────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('No bookings yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Find an Insider to explore China like a local!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkFaint, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Insiders →',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Booking card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _bookingCard(BuildContext context, _Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Guide info row ──
          Row(
            children: [
              GestureDetector(
                onTap: () => _viewProfile(context, b),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.teal,
                  child: Text(b.guideName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(b.guideName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.ink)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: AppColors.teal),
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Color(0xFFFFB800)),
                            const SizedBox(width: 2),
                            Text(b.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.ink)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(b.serviceType,
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                  ],
                ),
              ),
              // Status label
              _statusBadge(b.status),
            ],
          ),
          const SizedBox(height: 10),
          // ── Service details ──
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: AppColors.inkFaint),
              const SizedBox(width: 4),
              Text(b.dateTime,
                  style: const TextStyle(color: AppColors.inkFaint, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 13, color: AppColors.inkFaint),
              const SizedBox(width: 4),
              Text('${b.people} ${b.people == 1 ? 'person' : 'people'}',
                  style: const TextStyle(color: AppColors.inkFaint, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          // ── Dynamic action buttons ──
          _buildActions(context, b),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Status badge
  // ───────────────────────────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'pending':
        bg = const Color(0xFFFF8C00).withOpacity(0.15);
        fg = const Color(0xFFFF8C00);
        label = 'Pending';
        break;
      case 'confirmed':
        bg = Colors.blue.withOpacity(0.12);
        fg = Colors.blue;
        label = 'Confirmed';
        break;
      case 'ongoing':
        bg = AppColors.teal.withOpacity(0.15);
        fg = AppColors.teal;
        label = 'In Progress';
        break;
      case 'review':
        bg = Colors.purple.withOpacity(0.12);
        fg = Colors.purple;
        label = 'Review';
        break;
      case 'completed':
        bg = AppColors.inkFaint.withOpacity(0.12);
        fg = AppColors.inkSoft;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = AppColors.inkFaint.withOpacity(0.08);
        fg = AppColors.inkFaint;
        label = 'Cancelled';
        break;
      default:
        bg = AppColors.inkFaint.withOpacity(0.12);
        fg = AppColors.inkSoft;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Dynamic action buttons
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, _Booking b) {
    switch (b.status) {
      case 'pending':
        return Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: () => _cancelBooking(context, b),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Cancel', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.danger)),
            ),
          ],
        );
      case 'confirmed':
      case 'ongoing':
        return Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed: () => _viewDetails(context, b),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
              ),
              child: const Text('Details', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.ink)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _chatGuide(context, b),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: const Text('Contact', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white)),
            ),
          ],
        );
      case 'review':
        return Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed: () => _viewDetails(context, b),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
              ),
              child: const Text('Details', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.ink)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _reviewBooking(context, b),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: const Text('Review', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white)),
            ),
          ],
        );
      case 'completed':
        return Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed: () => _viewDetails(context, b),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
              ),
              child: const Text('Details', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.ink)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _rebook(context, b),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              child: const Text('Rebook', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white)),
            ),
          ],
        );
      case 'cancelled':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Actions
  // ───────────────────────────────────────────────────────────────────────────

  void _viewProfile(BuildContext context, _Booking b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewProfileScreen(
          id: b.guideName.toLowerCase(),
          userId: b.guideId,
          nickname: b.guideName,
          flag: b.guideFlag,
          country: 'China',
          daysInChina: 1,
          distance: '',
          avatarColor: AppColors.teal,
        ),
      ),
    );
  }

  void _chatGuide(BuildContext context, _Booking b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          friendId: '${b.guideId}',
          friendUserId: b.guideId,
          friendName: b.guideName,
          friendFlag: b.guideFlag,
          friendAvatarColor: AppColors.teal,
          isFriend: true,
          isGuide: true,
        ),
      ),
    );
  }

  void _viewDetails(BuildContext context, _Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: Text('Booking #${b.id}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Guide', '${b.guideName} ${b.guideFlag}'),
            _detailRow('Service', b.serviceType),
            _detailRow('Date & Time', b.dateTime),
            _detailRow('People', '${b.people}'),
            _detailRow('Rating', '${b.rating}'),
            _detailRow('Status', b.status.toUpperCase()),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Price Breakdown',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            _detailRow('Service fee', '¥${(b.rating * 50).toStringAsFixed(0)}'),
            _detailRow('Platform fee', '¥${(b.rating * 5).toStringAsFixed(0)}'),
            const Divider(),
            _detailRow('Total',
                '¥${(b.rating * 55).toStringAsFixed(0)}',
                bold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.inkFaint, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(BuildContext context, _Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Cancel Booking',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        content: Text('Cancel ${b.serviceType} on ${b.dateTime}?',
            style: const TextStyle(color: AppColors.ink)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No', style: TextStyle(color: AppColors.ink))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showGlideSnack(context, 'Booking cancelled',
                  icon: Icons.check_circle);
            },
            child: const Text('Yes, cancel',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _reviewBooking(BuildContext context, _Booking b) {
    int stars = 5;
    final reviewCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card)),
          title: const Text('Leave a Review',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate ${b.guideName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setDialogState(() => stars = i + 1),
                  icon: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.ink),
                cursorColor: AppColors.teal,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: const TextStyle(color: AppColors.inkFaint),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.ink)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showGlideSnack(context,
                    'Thanks! Your ${stars}-star review has been submitted.',
                    icon: Icons.check_circle);
              },
              child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _rebook(BuildContext context, _Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Rebook',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        content: Text('Book ${b.guideName} for ${b.serviceType} again?',
            style: const TextStyle(color: AppColors.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              showGlideSnack(context,
                  'Rebooked ${b.guideName}! Check your bookings for details.',
                  icon: Icons.check_circle);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
