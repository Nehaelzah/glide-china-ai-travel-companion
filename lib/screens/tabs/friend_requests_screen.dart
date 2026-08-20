import 'package:flutter/material.dart';
import '../../l10n/locale_provider.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Inbox of incoming friend requests, with accept / decline.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await SocialService.instance.incomingRequests();
      if (mounted) setState(() => _requests = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(Map<String, dynamic> req, bool accept) async {
    final requestId = req['request_id'] as int?;
    if (requestId == null) return;
    setState(() => _requests.remove(req));
    try {
      await SocialService.instance.respondToRequest(requestId, accept);
      if (mounted) {
        showGlideSnack(
            context,
            accept ? 'Friend added!' : 'Request declined',
            icon: accept ? Icons.check_circle : Icons.person_remove_outlined);
      }
    } catch (_) {
      if (mounted) {
        showGlideSnack(context, 'Something went wrong', icon: Icons.error);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Friend Requests',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.inkFaint),
                      const SizedBox(height: 12),
                      Text('No pending requests',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _requests.length,
                    itemBuilder: (context, i) => _requestCard(_requests[i]),
                  ),
                ),
    );
  }

  Widget _requestCard(Map<String, dynamic> req) {
    final nickname = (req['nickname'] as String?) ?? 'Traveller';
    final flag = (req['flag'] as String?) ?? '🌍';
    final nationality = (req['nationality'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.teal,
            child: Text(nickname[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nickname,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(flag, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                if (nationality.isNotEmpty)
                  Text(nationality,
                      style: const TextStyle(
                          color: AppColors.inkFaint, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _respond(req, true),
            icon: const Icon(Icons.check_circle, color: AppColors.teal),
          ),
          IconButton(
            onPressed: () => _respond(req, false),
            icon: const Icon(Icons.cancel_outlined, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
