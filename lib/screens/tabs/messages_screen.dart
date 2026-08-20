import 'package:flutter/material.dart';
import '../../services/social_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

/// Messages screen showing Insider conversations + Ask (post) reply notifications.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Tab 0: Insider conversations
  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;

  // Tab 1: Ask reply notifications
  List<_AskNotification> _askNotifs = [];
  bool _loadingAsk = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadAskNotifications();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final list = await SocialService.instance.listFriends();
      if (mounted) setState(() => _friends = list);
    } catch (_) {}
    // Also seed demo conversations with Insider guides
    if (mounted) {
      setState(() {
        final existingIds = _friends.map((f) => f['user_id']).toSet();
        final demoGuides = [
          {
            'user_id': 90001,
            'nickname': 'Li Wei',
            'flag': '\u{1F1E8}\u{1F1F3}',
            'nationality': 'China',
            'is_guide': true,
          },
          {
            'user_id': 90002,
            'nickname': 'Zhang Mei',
            'flag': '\u{1F1E8}\u{1F1F3}',
            'nationality': 'China',
            'is_guide': true,
          },
        ];
        for (final g in demoGuides) {
          if (!existingIds.contains(g['user_id'])) {
            _friends.add(g);
          }
        }
        _loadingFriends = false;
      });
    }
  }

  Future<void> _loadAskNotifications() async {
    setState(() => _loadingAsk = true);
    try {
      // Fetch the user's own posts, then check for comments on each
      final res = await ApiClient.instance.get('/api/posts/');
      final posts = (res.data as List).cast<Map<String, dynamic>>();
      final notifs = <_AskNotification>[];
      for (final post in posts.take(10)) {
        final postId = post['id'] as int;
        final comments = await SocialService.instance.listComments(postId);
        for (final c in comments) {
          notifs.add(_AskNotification(
            postId: postId,
            postContent:
            (post['content'] as String? ?? '').split('\n').first,
            commenterName: (c['nickname'] as String?) ?? 'Traveller',
            commenterFlag: (c['flag'] as String?) ?? '\u{1F30D}',
            comment: (c['content'] as String?) ?? '',
            time: (c['time'] as String?) ?? '',
          ));
        }
      }
      if (mounted) setState(() => _askNotifs = notifs);
    } catch (_) {}
    // Seed demo notifications when empty
    if (mounted && _askNotifs.isEmpty) {
      setState(() {
        _askNotifs = [
          _AskNotification(
            postId: -1,
            postContent: 'Just arrived in Shanghai! The Bund at night...',
            commenterName: 'Li Wei',
            commenterFlag: '\u{1F1E8}\u{1F1F3}',
            comment:
            'Welcome! I\'m a local guide here. Let me know if you need any tips!',
            time: '1h ago',
          ),
          _AskNotification(
            postId: -1,
            postContent: 'Looking for a guide to the Great Wall...',
            commenterName: 'Zhang Mei',
            commenterFlag: '\u{1F1E8}\u{1F1F3}',
            comment:
            'I can help! I organize trips to Mutianyu section every weekend.',
            time: '3h ago',
          ),
          _AskNotification(
            postId: -2,
            postContent: 'Where to get good espresso in the hutongs?',
            commenterName: 'Emma',
            commenterFlag: '\u{1F1EC}\u{1F1E7}',
            comment:
            'Try Soloist Coffee near Qianmen — amazing single origins!',
            time: '5h ago',
          ),
        ];
      });
    }
    if (mounted) setState(() => _loadingAsk = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.teal,
          indicatorWeight: 3,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.inkSoft,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Insiders'),
            Tab(text: 'Ask Replies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildInsiderTab(),
          _buildAskTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Tab 0: Insider conversations (friends + guides)
  // ─────────────────────────────────────────────────────────────

  Widget _buildInsiderTab() {
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            const Text('No conversations yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Connect with Insiders to start chatting',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _friends.length,
        itemBuilder: (context, i) => _conversationTile(_friends[i]),
      ),
    );
  }

  Widget _conversationTile(Map<String, dynamic> f) {
    final nickname = (f['nickname'] as String?) ?? 'Traveller';
    final flag = (f['flag'] as String?) ?? '\u{1F30D}';
    final userId = f['user_id'] as int?;
    final isGuide = (f['is_guide'] as bool?) ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isGuide ? AppColors.teal : AppColors.surfaceAlt,
              child: Text(nickname[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ),
            if (isGuide)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified,
                      size: 14, color: AppColors.teal),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(nickname,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink)),
            const SizedBox(width: 6),
            Text(flag, style: const TextStyle(fontSize: 15)),
            if (isGuide) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Insider',
                    style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isGuide ? 'Tap to chat with your Insider guide' : 'Tap to chat',
          style: const TextStyle(color: AppColors.inkFaint, fontSize: 12),
        ),
        trailing: const Icon(Icons.chat_bubble_outline,
            color: AppColors.teal, size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                friendId: '$userId',
                friendUserId: userId,
                friendName: nickname,
                friendFlag: flag,
                friendAvatarColor: isGuide ? AppColors.teal : AppColors.surfaceAlt,
                isFriend: true,
                isGuide: isGuide,
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Tab 1: Ask reply notifications
  // ─────────────────────────────────────────────────────────────

  Widget _buildAskTab() {
    if (_loadingAsk) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_askNotifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.question_answer_outlined,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            const Text('No replies yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Post a question in Ask to get replies',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAskNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _askNotifs.length,
        itemBuilder: (context, i) => _askNotifCard(_askNotifs[i]),
      ),
    );
  }

  Widget _askNotifCard(_AskNotification n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
        border: Border(left: BorderSide(color: AppColors.teal, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Who replied + when
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.teal,
                child: Text(n.commenterName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(n.commenterName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.ink)),
                        const SizedBox(width: 4),
                        Text(n.commenterFlag,
                            style: const TextStyle(fontSize: 13)),
                        const Spacer(),
                        Text(n.time,
                            style: const TextStyle(
                                color: AppColors.inkFaint, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('replied to your post',
                        style: TextStyle(
                            color: AppColors.inkSoft, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Their reply content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(n.comment,
                style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.ink)),
          ),
          const SizedBox(height: 8),
          // Your original post (truncated)
          Row(
            children: [
              const Icon(Icons.article_outlined,
                  size: 12, color: AppColors.inkFaint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Your post: "${n.postContent}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.inkFaint,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AskNotification {
  final int postId;
  final String postContent;
  final String commenterName;
  final String commenterFlag;
  final String comment;
  final String time;

  const _AskNotification({
    required this.postId,
    required this.postContent,
    required this.commenterName,
    required this.commenterFlag,
    required this.comment,
    required this.time,
  });
}
