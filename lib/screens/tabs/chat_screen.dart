import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Instagram-style chat screen.
///
/// If not friends: only one invitation message can be sent ("View my profile").
/// If friends: full chat with text input.
/// For Insider guides: includes a "Send Payment Link" button.
class ChatScreen extends StatefulWidget {
  final String friendId;
  final int? friendUserId;
  final String friendName;
  final String friendFlag;
  final Color friendAvatarColor;
  final bool isFriend;
  final bool isGuide;
  final VoidCallback? onFriendAdded;

  const ChatScreen({
    super.key,
    required this.friendId,
    this.friendUserId,
    required this.friendName,
    required this.friendFlag,
    required this.friendAvatarColor,
    this.isFriend = false,
    this.isGuide = false,
    this.onFriendAdded,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late bool _isFriend;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];
  Timer? _pollTimer;
  bool get _isGuide => widget.isGuide || (widget.friendUserId != null && widget.friendUserId! >= 90000 && widget.friendUserId! <= 99999);

  @override
  void initState() {
    super.initState();
    _isFriend = true; // Always allow chatting (guides, bookings, etc.)
    _loadMessages();
    // Poll for new messages every 3 seconds (simple near-real-time).
    _pollTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    if (widget.friendUserId == null) return;
    try {
      final raw =
      await SocialService.instance.getConversation(widget.friendUserId!);
      if (!mounted) return;
      final msgs = raw.map((m) => _ChatBubble(
        text: (m['content'] as String?) ?? '',
        isMe: (m['from_me'] as bool?) ?? false,
        time: DateTime.now(),
      )).toList();
      // Only update if the count changed (avoid pointless rebuilds).
      if (msgs.length != _messages.length) {
        setState(() {
          _messages
            ..clear()
            ..addAll(msgs);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (widget.friendUserId == null) return;

    setState(() {
      _messages.add(_ChatBubble(text: text, isMe: true, time: DateTime.now()));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await SocialService.instance
          .sendMessage(widget.friendUserId!, text);
    } catch (e) {
      debugPrint('[ChatScreen] send error: $e');
      if (mounted) {
        String msg = 'Could not send message';
        if (e is DioException) {
          final detail = e.response?.data;
          if (detail is Map && detail.containsKey('detail')) {
            msg = detail['detail'].toString();
          }
        }
        showGlideSnack(context, msg, icon: Icons.error);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendPaymentLink() async {
    final link = 'https://glidechina.com/pay/booking-${DateTime.now().millisecondsSinceEpoch}';
    final text = '📋 Payment Link\n\nPlease complete your booking payment:\n$link\n\nAmount: ¥580 (Platform secured)';

    // Add locally first
    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isMe: false,
        time: DateTime.now(),
        isPaymentLink: true,
      ));
    });
    _scrollToBottom();

    // Also persist to server so the 3s poll won't overwrite it
    if (widget.friendUserId != null) {
      try {
        await SocialService.instance
            .sendMessage(widget.friendUserId!, text);
      } catch (_) {
        // Local copy remains even if server persist fails
      }
    }

    if (mounted) {
      showGlideSnack(context, 'Payment link sent!', icon: Icons.payment);
    }
  }

  String _randomReply() {
    final replies = [
      "That's awesome! Tell me more!",
      "Haha, I love that!",
      "Cool! Where are you based?",
      "Sounds great! Let's meet up!",
      "I'm in Shanghai this week!",
      "No way, me too! 😄",
      "Have you tried the local food?",
      "I'd recommend the tea house nearby!",
    ];
    return replies[DateTime.now().millisecond % replies.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) =>
                  _buildBubble(_messages[i]),
            ),
          ),
          // Input area
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
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
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.friendAvatarColor,
            child: Text(
              widget.friendName.isNotEmpty
                  ? widget.friendName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.friendName} ${widget.friendFlag}',
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              Text(
                _isFriend ? 'Friend' : 'Friend request pending',
                style: const TextStyle(
                    color: AppColors.inkFaint, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          if (_isGuide)
            IconButton(
              onPressed: _sendPaymentLink,
              icon: const Icon(Icons.payment, size: 20, color: AppColors.ink),
              tooltip: 'Send Payment Link',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.all(8),
            ),
          if (!_isFriend)
            TextButton(
              onPressed: () {
                if (widget.friendId.isNotEmpty) {
                  context.read<AppState>().addFriend(FriendInfo(
                    id: widget.friendId,
                    nickname: widget.friendName,
                    flag: widget.friendFlag,
                    country: '',
                    avatarColor: widget.friendAvatarColor,
                  ));
                  setState(() => _isFriend = true);
                  widget.onFriendAdded?.call();
                  showGlideSnack(context, 'Friend request accepted!',
                      icon: Icons.check_circle);
                }
              },
              child: const Text('Accept',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 48, color: AppColors.inkFaint),
          const SizedBox(height: 12),
          const Text('Start a conversation!',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatBubble msg) {
    final isMe = msg.isMe;
    final isPayment = msg.isPaymentLink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: isPayment ? AppColors.teal : widget.friendAvatarColor,
                child: isPayment
                    ? const Icon(Icons.payment, color: Colors.white, size: 14)
                    : Text(
                  widget.friendName.isNotEmpty
                      ? widget.friendName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 11),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isPayment
                    ? AppColors.teal.withOpacity(0.12)
                    : (isMe ? AppColors.teal : AppColors.surfaceAlt),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isPayment
                    ? Border.all(color: AppColors.teal, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPayment)
                    const Row(
                      children: [
                        Icon(Icons.verified_user, size: 14, color: AppColors.teal),
                        SizedBox(width: 4),
                        Text('Platform Secured Payment',
                            style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  if (isPayment) const SizedBox(height: 6),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isPayment
                          ? AppColors.ink
                          : (isMe ? Colors.black : AppColors.ink),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (isPayment) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showGlideSnack(context, 'Opening payment...',
                              icon: Icons.payment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pay Now — ¥580',
                            style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe)
            const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final canSend = true; // Always allow messaging

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: canSend,
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              cursorColor: AppColors.teal,
              decoration: InputDecoration(
                hintText: canSend ? 'Message...' : 'Add friend to chat',
                hintStyle:
                const TextStyle(color: AppColors.inkFaint, fontSize: 14),
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          if (canSend)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
                padding: const EdgeInsets.all(10),
                constraints:
                const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isPaymentLink;

  _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
    this.isPaymentLink = false,
  });
}
