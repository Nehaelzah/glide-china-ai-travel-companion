import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/mock_data.dart';
import '../../services/api_client.dart';
import '../../services/social_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/radar_map.dart';
import 'view_profile_screen.dart';

class RadarTab extends StatefulWidget {
  const RadarTab({super.key});

  @override
  State<RadarTab> createState() => _RadarTabState();
}

class _RadarTabState extends State<RadarTab> {
  String _sort = 'Distance';
  List<NearbyTourist> _tourists = [];
  double _userLat = 39.9042;
  double _userLng = 116.4074;
  bool _locating = true;
  int _selectedTab = 0; // 0 = Nearby, 1 = Ask
  List<UserPost> _communityPosts = [];
  bool _loadingPosts = false;
  Timer? _countsTimer;

  /// Poll lightweight like/comment counts every few seconds and update the
  /// existing cards in place (no image re-download).
  void _startCountsPolling() {
    _countsTimer?.cancel();
    _countsTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _communityPosts.isEmpty) return;
      // Only poll while the Community tab is showing.
      if (_selectedTab != 1) return;
      try {
        final counts = await SocialService.instance.postCounts();
        if (!mounted) return;
        final byId = {for (final c in counts) '${c['id']}': c};
        var changed = false;
        for (final p in _communityPosts) {
          final c = byId[p.id];
          if (c == null) continue;
          final newLikes = (c['likes'] as int?) ?? p.likes;
          final newLiked = (c['liked'] as bool?) ?? p.liked;
          final newComments = (c['comment_count'] as int?) ?? p.commentCount;
          if (newLikes != p.likes ||
              newLiked != p.liked ||
              newComments != p.commentCount) {
            p.likes = newLikes;
            p.liked = newLiked;
            p.commentCount = newComments;
            changed = true;
          }
        }
        if (changed) setState(() {});
      } catch (_) {}
    });
  }

  /// Load the shared community feed from the backend.
  Future<void> _loadCommunityPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final raw = await SocialService.instance.listPosts();
      final posts = raw.map(_postFromJson).toList();
      if (mounted) setState(() => _communityPosts = posts);
    } catch (_) {
      // leave existing list; feed just won't update
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  UserPost _postFromJson(Map<String, dynamic> j) {
    Uint8List? img;
    final imageStr = j['image'] as String?;
    if (imageStr != null && imageStr.isNotEmpty) {
      try {
        final b64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        img = base64Decode(b64);
      } catch (_) {}
    }
    return UserPost(
      id: '${j['id']}',
      nickname: (j['nickname'] as String?) ?? 'Traveller',
      flag: (j['flag'] as String?) ?? '🌍',
      content: (j['content'] as String?) ?? '',
      time: (j['time'] as String?) ?? '',
      likes: (j['likes'] as int?) ?? 0,
      avatarColor: AppColors.teal,
      imageBytes: img,
      liked: (j['liked'] as bool?) ?? false,
      commentCount: (j['comment_count'] as int?) ?? 0,
    );
  }

  List<NearbyTourist> get _sortedTourists {
    switch (_sort) {
      case 'Online':
        return _tourists.where((t) => t.online).toList();
      case 'Country':
        final sorted = List<NearbyTourist>.from(_tourists);
        sorted.sort((a, b) => a.country.compareTo(b.country));
        return sorted;
      default: // Distance
        return List<NearbyTourist>.from(_tourists);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadTourists();
    _loadCommunityPosts();
    _startCountsPolling();
  }

  @override
  void dispose() {
    _countsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    // 1. Try real device GPS first (most accurate).
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high),
          ).timeout(const Duration(seconds: 8));
          if (mounted) {
            setState(() {
              _userLat = pos.latitude;
              _userLng = pos.longitude;
              _locating = false;
            });
          }
          return; // got real GPS, done
        }
      }
    } catch (_) {
      // fall through to IP-based fallback below
    }

    // 2. Fallback: approximate location from the backend (IP-based).
    try {
      final res = await ApiClient.instance.get('/api/map/locate').timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('timeout'),
      );
      if (mounted) {
        setState(() {
          _userLat = (res.data['lat'] as num?)?.toDouble() ?? 39.9042;
          _userLng = (res.data['lng'] as num?)?.toDouble() ?? 116.4074;
          _locating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _loadTourists() async {
    try {
      final raw = await SocialService.instance.nearbyUsers();
      if (raw.isNotEmpty) {
        final list = raw.map((j) {
          return NearbyTourist(
            userId: j['id'] as int?,
            nickname: (j['nickname'] as String?) ?? 'Traveller',
            country: (j['country'] as String?) ?? '',
            flag: (j['flag'] as String?) ?? '🌍',
            distanceMeters: (j['distance_meters'] as int?) ?? 500,
            daysInChina: (j['days_in_china'] as int?) ?? 1,
            languages:
            (j['languages'] as List?)?.cast<String>() ?? const ['English'],
            interests: (j['interests'] as List?)?.cast<String>() ?? const [],
            online: (j['online'] as bool?) ?? true,
            avatarColor: AppColors.teal,
            dx: (j['dx'] as num?)?.toDouble() ?? 0,
            dy: (j['dy'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        if (mounted) setState(() => _tourists = list);
        return;
      }
    } catch (_) {}
    // Fallback to mock/default when backend has no other users.
    final list = await MockData.fetchNearbyTourists();
    if (mounted) {
      setState(() => _tourists = list.isEmpty ? _defaultTourist : list);
    }
  }

  /// One virtual example traveller when API returns empty.
  static List<NearbyTourist> get _defaultTourist => [
    NearbyTourist(
      nickname: 'Yuki',
      country: 'Japan',
      flag: '\u{1F1EF}\u{1F1F5}',
      distanceMeters: 340,
      languages: ['Japanese', 'English'],
      interests: ['Photography', 'Sushi'],
      online: true,
      avatarColor: const Color(0xFFE91E63),
      dx: 0.1,
      dy: -0.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton(
        onPressed: () => _showHelpRequestDialog(context),
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _header(state),
            _sortBar(),
            const SizedBox(height: 4),
            Expanded(flex: 5, child: _map(state)),
            _tabBar(context),
            Expanded(
              flex: 6,
              child: _selectedTab == 0
                  ? _buildNearbySection()
                  : _buildCommunityContent(state),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  //  Header
  // =====================================================================

  Widget _header(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(context.t('radar'),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const Spacer(),
          Row(
            children: [
              Text(state.showOnRadar ? context.t('visible') : context.t('hidden'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                      fontSize: 13)),
              Switch(
                value: state.showOnRadar,
                activeColor: AppColors.teal,
                onChanged: state.setShowOnRadar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  //  Sort bar (above map, replaces old filter chips)
  // =====================================================================

  Widget _sortBar() {
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _sort = v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'Distance',
                    child: Text(context.t('sort_distance'),
                        style: const TextStyle(color: AppColors.ink))),
                PopupMenuItem(
                    value: 'Online',
                    child: Text(context.t('sort_online'),
                        style: const TextStyle(color: AppColors.ink))),
                PopupMenuItem(
                    value: 'Country',
                    child: Text(context.t('sort_country'),
                        style: const TextStyle(color: AppColors.ink))),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_vert, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _sortLabel(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${_sortedTourists.length} ${context.t('nearby')}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sort) {
      case 'Online': return context.t('sort_online');
      case 'Country': return context.t('sort_country');
      default: return context.t('sort_distance');
    }
  }

  // =====================================================================
  //  Map (uses sorted/filtered tourists)
  // =====================================================================

  Widget _map(AppState state) {
    if (_locating) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }
    final displayList = _sortedTourists;
    // Generate help marker positions from community posts (pseudo-random near user)
    final helpLatLngs = _communityPosts
        .take(5)
        .toList()
        .asMap()
        .entries
        .map((e) {
      final i = e.key;
      final angle = i * 1.3 + _communityPosts.length * 0.7;
      final dist = 0.005 + (i % 5) * 0.004;
      final dLat = math.sin(angle) * dist;
      final dLng = math.cos(angle) * dist / (math.cos(_userLat * math.pi / 180));
      return LatLng(_userLat + dLat, _userLng + dLng);
    }).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RadarMap(
        userLat: _userLat,
        userLng: _userLng,
        tourists: displayList,
        helpMarkers: helpLatLngs,
      ),
    );
  }

  // =====================================================================
  //  Tab bar: Nearby | Ask
  // =====================================================================

  Widget _tabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          _tabButton(context, 'Nearby', 0),
          const SizedBox(width: 8),
          _tabButton(context, 'Ask', 1),
        ],
      ),
    );
  }

  Widget _tabButton(BuildContext context, String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: selected ? null : AppShadows.soft,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.black : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  //  Nearby Travelers section (tab 0)
  // =====================================================================

  Widget _buildNearbySection() {
    final list = _sortedTourists;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 40, color: AppColors.inkFaint),
              const SizedBox(height: 12),
              Text(context.t('no_travellers_yet'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(context.t('no_travellers_msg'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkFaint, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      itemCount: list.length,
      itemBuilder: (context, i) => _nearbyCard(list[i]),
    );
  }

  Widget _nearbyCard(NearbyTourist t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: t.avatarColor,
                  child: Text(t.nickname[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                if (t.online)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + country + distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.nickname,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.ink)),
                      const SizedBox(width: 6),
                      Text(t.flag, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${t.country} \u00B7 ${_distLabel(t.distanceMeters)}',
                      style: const TextStyle(color: AppColors.inkFaint, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Visit Profile button
            SizedBox(
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _visitProfile(t),
                child: Text(context.t('view'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _visitProfile(NearbyTourist t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewProfileScreen(
          id: t.nickname.toLowerCase(),
          userId: t.userId,
          nickname: t.nickname,
          flag: t.flag,
          country: t.country,
          daysInChina: t.daysInChina,
          distance: _distLabel(t.distanceMeters),
          avatarColor: t.avatarColor,
          tags: t.interests,
        ),
      ),
    );
  }

  String _distLabel(int meters) {
    return meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // =====================================================================
  //  Ask section (tab 1)
  // =====================================================================

  Widget _buildCommunityContent(AppState state) {
    final posts = _communityPosts;
    if (_loadingPosts && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCommunityPosts,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 40, color: AppColors.inkFaint),
                      const SizedBox(height: 12),
                      Text(context.t('no_posts_yet'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink)),
                      const SizedBox(height: 6),
                      const Text('Pull down to refresh',
                          style: TextStyle(
                              color: AppColors.inkFaint, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCommunityPosts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        children: posts.map((p) => _helpRequestCard(p)).toList(),
      ),
    );
  }

  void _showHelpRequestDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Ask for Help',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you need help with?',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.ink),
              cursorColor: AppColors.teal,
              decoration: const InputDecoration(
                hintText: 'Brief title…',
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.ink),
              cursorColor: AppColors.teal,
              decoration: const InputDecoration(
                hintText: 'Describe your situation…',
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          GradientButton(
            label: 'Post',
            icon: Icons.send,
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (title.isEmpty && desc.isEmpty) return;
              final content = title.isNotEmpty ? '$title\n$desc' : desc;
              Navigator.pop(ctx);
              try {
                await SocialService.instance.createPost(content);
                await _loadCommunityPosts();
              } catch (_) {
                if (mounted) {
                  showGlideSnack(context, 'Failed to post', icon: Icons.error);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

Widget _helpRequestCard(UserPost p) {
  return StatefulBuilder(
    builder: (context, setLocalState) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppShadows.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + name + flag (avatar is tappable)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProfileScreen(
                        id: p.nickname.toLowerCase(),
                        nickname: p.nickname,
                        flag: p.flag,
                        country: 'Traveler',
                        daysInChina: 1,
                        distance: '',
                        avatarColor: p.avatarColor,
                        tags: [],
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: p.avatarColor,
                      child: Text(p.nickname[0],
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.ink)),
                        Text(p.time,
                            style: const TextStyle(
                                color: AppColors.inkFaint, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Text(p.flag, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Title + status row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.content.contains('\n')
                          ? p.content.split('\n').first
                          : p.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isResolved(p)
                          ? AppColors.teal.withOpacity(0.15)
                          : AppColors.inkFaint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isResolved(p) ? 'Solved' : 'Open',
                      style: TextStyle(
                        color: _isResolved(p) ? AppColors.teal : AppColors.inkSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Distance + time row
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 13, color: AppColors.inkFaint),
                  const SizedBox(width: 3),
                  Text('${_randomDist(p.id)} away',
                      style: const TextStyle(
                          color: AppColors.inkFaint, fontSize: 11)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time,
                      size: 13, color: AppColors.inkFaint),
                  const SizedBox(width: 3),
                  Text(p.time,
                      style: const TextStyle(
                          color: AppColors.inkFaint, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              // Description (rest of content)
              if (p.content.contains('\n'))
                Text(
                  p.content.split('\n').skip(1).join('\n'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.inkSoft),
                ),
              if (p.imageBytes != null) ...[
                const SizedBox(height: 10),
                _postImage(p.imageBytes!),
              ],
              const SizedBox(height: 10),
              // Action bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final postId = int.tryParse(p.id);
                      if (postId == null) return;
                      // Optimistic update
                      setLocalState(() {
                        p.liked = !p.liked;
                        p.likes += p.liked ? 1 : -1;
                      });
                      try {
                        final res = await SocialService.instance
                            .toggleLike(postId);
                        setLocalState(() {
                          p.liked = res['liked'] as bool? ?? p.liked;
                          p.likes = res['likes'] as int? ?? p.likes;
                        });
                      } catch (_) {
                        // revert on failure
                        setLocalState(() {
                          p.liked = !p.liked;
                          p.likes += p.liked ? 1 : -1;
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.liked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: p.liked ? AppColors.danger : AppColors.inkFaint,
                        ),
                        const SizedBox(width: 4),
                        Text('${p.likes}',
                            style: TextStyle(
                                color: p.liked ? AppColors.danger : AppColors.inkFaint,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showCommentDialog(context, p, setLocalState),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 16, color: AppColors.inkFaint),
                        const SizedBox(width: 4),
                        Text('${p.commentCount}',
                            style: const TextStyle(
                                color: AppColors.inkFaint, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showShareSheet(context, p),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share_outlined,
                            size: 16, color: AppColors.inkFaint),
                        SizedBox(width: 4),
                        Text('Share',
                            style: TextStyle(
                                color: AppColors.inkFaint, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Deterministic pseudo-distance based on the post id (for demo).
String _randomDist(String id) {
  final hash = id.hashCode.abs();
  final meters = 50 + (hash % 2500);
  return meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(1)}km';
}

/// Rough heuristic: posts with even-length ids are considered solved.
bool _isResolved(UserPost p) {
  return p.id.length % 3 == 0;
}

void _editPostContent(
    BuildContext context, UserPost p, void Function(VoidCallback) setLocal) {
  final ctrl = TextEditingController(text: p.content);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card)),
      title: const Text('Edit Post',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink)),
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.ink),
        cursorColor: AppColors.teal,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Update your post...',
          hintStyle: TextStyle(color: AppColors.inkFaint),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final newContent = ctrl.text.trim();
            if (newContent.isNotEmpty) {
              setLocal(() => p.content = newContent);
            }
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showCommentDialog(
    BuildContext context, UserPost p, void Function(VoidCallback) setLocal) {
  final ctrl = TextEditingController();
  final postId = int.tryParse(p.id);
  Timer? pollTimer;

  // Helper to refresh comments from the backend.
  Future<void> refreshComments(void Function(VoidCallback) rebuild) async {
    if (postId == null) return;
    try {
      final list = await SocialService.instance.listComments(postId);
      final texts = list.map((c) => (c['content'] as String?) ?? '').toList();
      // Only rebuild if something changed.
      if (texts.length != p.commentList.length) {
        rebuild(() {
          p.commentList
            ..clear()
            ..addAll(texts);
          p.commentCount = p.commentList.length;
        });
        setLocal(() {}); // update the card behind the sheet too
      }
    } catch (_) {}
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        // Kick off initial load + start polling once.
        pollTimer ??= () {
          WidgetsBinding.instance.addPostFrameCallback(
                  (_) => refreshComments(setSheet));
          return Timer.periodic(const Duration(seconds: 4),
                  (_) => refreshComments(setSheet));
        }();
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                      color: AppColors.line, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Text('Comments (${p.commentCount})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: p.commentList.isEmpty
                    ? const Center(
                  child: Text('No comments yet',
                      style: TextStyle(color: AppColors.inkFaint)),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: p.commentList.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 40),
                  itemBuilder: (context, i) {
                    final comment = p.commentList[i];
                    final commenterName =
                    i.isEven ? p.nickname : 'Traveler';
                    final commenterColor =
                    i.isEven ? p.avatarColor : AppColors.teal;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: commenterColor,
                        child: Text(commenterName[0],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      title: Row(
                        children: [
                          Text(commenterName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.ink)),
                          const Spacer(),
                          Text('2h ago',
                              style: const TextStyle(
                                  color: AppColors.inkFaint, fontSize: 10)),
                        ],
                      ),
                      subtitle: Text(comment,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink)),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          style: const TextStyle(color: AppColors.ink),
                          cursorColor: AppColors.teal,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(color: AppColors.inkFaint),
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final text = ctrl.text.trim();
                          if (text.isNotEmpty) {
                            setSheet(() {
                              p.commentList.add(text);
                              p.commentCount = p.commentList.length;
                            });
                            setLocal(() {}); // update card behind the sheet
                            ctrl.clear();
                            if (postId != null) {
                              SocialService.instance
                                  .addComment(postId, text)
                                  .catchError((_) => <String, dynamic>{});
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  ).whenComplete(() => pollTimer?.cancel());
}

void _showShareSheet(BuildContext context, UserPost post) {
  final state = context.read<AppState>();
  final friends = state.friends;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44, height: 5,
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.share_outlined,
                  size: 20, color: AppColors.teal),
              const SizedBox(width: 8),
              const Text('Share with a friend',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              '"${post.content.length > 40 ? '${post.content.substring(0, 40)}...' : post.content}"',
              style: const TextStyle(
                  color: AppColors.inkFaint, fontSize: 12)),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No friends to share with yet',
                    style: TextStyle(color: AppColors.inkFaint)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final f = friends[i];
                  return Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: f.avatarColor,
                        child: Text(f.nickname[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                      title: Text('${f.nickname} ${f.flag}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.ink)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showGlideSnack(
                            context,
                            'Shared post with ${f.nickname}!',
                            icon: Icons.check_circle,
                          );
                        },
                        child: const Text('Share',
                            style:
                            TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _postImage(Uint8List bytes) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.chip),
    child: Image.memory(
      bytes,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 180,
        color: AppColors.surfaceAlt,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 40, color: AppColors.inkFaint),
        ),
      ),
    ),
  );
}
