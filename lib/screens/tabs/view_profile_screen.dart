import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/locale_provider.dart';
import '../../providers/app_state.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';

/// Screen to view another user's profile.
/// Upper half: background + avatar + user info.
/// Lower half: scrollable posts list.
class ViewProfileScreen extends StatefulWidget {
  final String nickname;
  final String flag;
  final String country;
  final int daysInChina;
  final String distance;
  final Color avatarColor;
  final bool isFriend;
  final String? backgroundImage;
  final List<String> tags;
  final String id;
  final int? userId; // backend user id

  const ViewProfileScreen({
    super.key,
    required this.nickname,
    required this.flag,
    required this.country,
    required this.daysInChina,
    required this.distance,
    required this.avatarColor,
    this.isFriend = false,
    this.backgroundImage,
    this.tags = const [],
    this.id = '',
    this.userId,
  });

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  late bool _isFriend;
  String _friendStatus = 'none'; // none/friends/pending_out/pending_in/self
  bool _isGuide = false;
  List<Map<String, dynamic>> _guideLanguages = [];
  List<String> _guideInterests = [];
  bool _guideHasCert = false;
  List<Map<String, dynamic>> _userPosts = [];
  bool _loadingPosts = true;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.isFriend;
    _loadFriendStatus();
    _loadGuideProfile();
    _loadUserPosts();
  }

  Future<void> _loadGuideProfile() async {
    if (widget.userId == null) return;
    try {
      final p = await SocialService.instance.guideProfile(widget.userId!);
      if (mounted && (p['is_local_guide'] as bool? ?? false)) {
        setState(() {
          _isGuide = true;
          _guideLanguages =
              ((p['languages'] as List?) ?? []).cast<Map<String, dynamic>>();
          _guideInterests =
              ((p['interests'] as List?) ?? []).cast<String>();
          _guideHasCert = (p['has_certificate'] as bool?) ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFriendStatus() async {
    if (widget.userId == null) return;
    try {
      final status = await SocialService.instance.friendStatus(widget.userId!);
      if (mounted) {
        setState(() {
          _friendStatus = status;
          _isFriend = status == 'friends';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserPosts() async {
    if (widget.userId == null) {
      setState(() => _loadingPosts = false);
      return;
    }
    try {
      final posts = await SocialService.instance.userPosts(widget.userId!);
      if (mounted) setState(() { _userPosts = posts; _loadingPosts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _sendRequest() async {
    if (widget.userId == null) return;
    try {
      await SocialService.instance.sendFriendRequest(widget.userId!);
      if (mounted) {
        setState(() => _friendStatus = 'pending_out');
        showGlideSnack(context, context.t('friend_request_sent'),
            icon: Icons.check_circle);
      }
    } catch (_) {
      if (mounted) {
        showGlideSnack(context, 'Could not send request',
            icon: Icons.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasBg = widget.backgroundImage != null &&
        File(widget.backgroundImage!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Upper: header with background/avatar ----
            _buildHeader(context, hasBg),
            const SizedBox(height: 12),
            // Info card
            _buildInfoCard(context),
            const SizedBox(height: 10),
            _buildTags(context),
            if (_isGuide) _buildGuideSection(context),
            // ---- Posts section title ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.article_outlined,
                        size: 18, color: AppColors.teal),
                  ),
                  const SizedBox(width: 10),
                  Text(context.t('posts'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ink)),
                ],
              ),
            ),
            // ---- Lower: scrollable posts list ----
            Expanded(child: _buildPostsSection(context)),
            // ---- Bottom: action buttons ----
            _buildActionButtons(context, state),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withOpacity(0.12),
            AppColors.teal.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.teal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              const Text('Verified Insider',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.teal)),
              if (_guideHasCert) ...[
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('English Certified',
                      style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          if (_guideLanguages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('LANGUAGES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final l in _guideLanguages)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      '${l['language']} · ${l['level']}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                    ),
                  ),
              ],
            ),
          ],
          if (_guideInterests.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('SPECIALTIES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final it in _guideInterests)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(it,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================================
  //  Header with background + avatar + back button
  // =====================================================================

  Widget _buildHeader(BuildContext context, bool hasBg) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.avatarColor.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadii.card),
              bottomRight: Radius.circular(AppRadii.card),
            ),
            image: hasBg
                ? DecorationImage(
              image: FileImage(File(widget.backgroundImage!)),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: hasBg
              ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.canvas.withOpacity(0.9),
                  Colors.transparent,
                ],
              ),
            ),
          )
              : null,
        ),
        // Back button
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: 0,
          left: 24,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: widget.avatarColor,
              child: Text(
                widget.nickname.isNotEmpty
                    ? widget.nickname[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  //  Info card
  // =====================================================================

  Widget _buildInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.nickname,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(width: 8),
                    Text(widget.flag,
                        style: const TextStyle(fontSize: 20)),
                    const Spacer(),
                    TagChip(
                      '${context.t('day')} ${widget.daysInChina}',
                      icon: Icons.calendar_today,
                      color: AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.country,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  //  Tags
  // =====================================================================

  Widget _buildTags(BuildContext context) {
    if (widget.tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: widget.tags
            .map((tag) => Chip(
          label: Text(tag,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          backgroundColor: AppColors.teal.withOpacity(0.1),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ))
            .toList(),
      ),
    );
  }

  // =====================================================================
  //  Posts section (scrollable list)
  // =====================================================================

  Widget _buildPostsSection(BuildContext context) {
    if (_loadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_userPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(context.t('no_posts_yet'),
              style: const TextStyle(
                  color: AppColors.inkFaint, fontSize: 14)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      itemCount: _userPosts.length,
      itemBuilder: (context, i) => _postCard(context, _userPosts[i]),
    );
  }

  Widget _postCard(BuildContext context, Map<String, dynamic> p) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: widget.avatarColor,
                  child: Text(widget.nickname[0],
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (p['content'] as String? ?? '').split('\n').first,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(p['time'] as String? ?? '',
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(p['content'] as String? ?? '',
                style: const TextStyle(
                    fontSize: 14, height: 1.4, color: AppColors.ink)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  (p['liked'] as bool? ?? false)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 15,
                  color: (p['liked'] as bool? ?? false)
                      ? Colors.red
                      : AppColors.inkFaint,
                ),
                const SizedBox(width: 3),
                Text('${p['likes'] ?? 0}',
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline,
                    size: 15, color: AppColors.inkFaint),
                const SizedBox(width: 3),
                Text('${p['comment_count'] ?? 0}',
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  //  Action buttons
  // =====================================================================

  Widget _buildActionButtons(BuildContext context, AppState state) {
    final canChat = _friendStatus == 'friends';

    Widget friendButton;
    if (_friendStatus == 'friends') {
      friendButton = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: BorderSide(color: AppColors.teal.withOpacity(0.3)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
        ),
        onPressed: null,
        icon: const Icon(Icons.check, size: 18),
        label: Text(context.t('friends'),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.teal)),
      );
    } else if (_friendStatus == 'pending_out') {
      friendButton = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkFaint,
          side: BorderSide(color: AppColors.line),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
        ),
        onPressed: null,
        icon: const Icon(Icons.hourglass_top, size: 18),
        label: const Text('Requested',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
      );
    } else if (_friendStatus == 'pending_in') {
      friendButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
        ),
        onPressed: () {
          showGlideSnack(context,
              'They sent you a request — accept it in your requests inbox.',
              icon: Icons.info_outline);
        },
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: const Text('Respond',
            style: TextStyle(fontWeight: FontWeight.w700)),
      );
    } else {
      friendButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
        ),
        onPressed: widget.userId == null ? null : _sendRequest,
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: Text(context.t('add_friend'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: friendButton),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: canChat ? AppColors.teal : AppColors.inkFaint,
                side: BorderSide(
                    color: (canChat ? AppColors.teal : AppColors.inkFaint)
                        .withOpacity(0.3)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              ),
              onPressed: () {
                if (!canChat) {
                  showGlideSnack(context,
                      'Add each other as friends first to chat.',
                      icon: Icons.lock_outline);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      friendId: '${widget.userId}',
                      friendUserId: widget.userId,
                      friendName: widget.nickname,
                      friendFlag: widget.flag,
                      friendAvatarColor: widget.avatarColor,
                      isFriend: true,
                      isGuide: _isGuide,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(context.t('chat'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: canChat ? AppColors.teal : AppColors.inkFaint)),
            ),
          ),
        ],
      ),
    );
  }
}
