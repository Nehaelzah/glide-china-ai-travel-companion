import 'api_client.dart';

/// Central client for all social features: posts, likes, comments, friends, chat.
class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();
  final _client = ApiClient.instance;

  // ---------------- Posts ----------------

  Future<List<Map<String, dynamic>>> listPosts() async {
    final res = await _client.get('/api/posts/');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// Lightweight counts for polling (no images).
  Future<List<Map<String, dynamic>>> postCounts() async {
    final res = await _client.get('/api/posts/counts');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> createPost(String content, {String? imageB64}) async {
    await _client.post('/api/posts/', data: {
      'content': content,
      'image': imageB64,
    });
  }

  Future<void> deletePost(int postId) async {
    await _client.delete('/api/posts/$postId');
  }

  /// Get all posts by a specific user.
  Future<List<Map<String, dynamic>>> userPosts(int userId) async {
    final res = await _client.get('/api/posts/user/$userId');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  // ---------------- Likes ----------------

  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final res = await _client.post('/api/social/posts/$postId/like');
    return (res.data as Map).cast<String, dynamic>();
  }

  // ---------------- Comments ----------------

  Future<List<Map<String, dynamic>>> listComments(int postId) async {
    final res = await _client.get('/api/social/posts/$postId/comments');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addComment(int postId, String content) async {
    final res = await _client.post('/api/social/posts/$postId/comments',
        data: {'content': content});
    return (res.data as Map).cast<String, dynamic>();
  }

  // ---------------- Friends ----------------

  Future<void> sendFriendRequest(int toUserId) async {
    await _client.post('/api/social/friends/request/$toUserId');
  }

  Future<List<Map<String, dynamic>>> incomingRequests() async {
    final res = await _client.get('/api/social/friends/requests');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> respondToRequest(int requestId, bool accept) async {
    await _client.post(
        '/api/social/friends/respond/$requestId?accept=$accept');
  }

  Future<List<Map<String, dynamic>>> listFriends() async {
    final res = await _client.get('/api/social/friends');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<String> friendStatus(int otherId) async {
    final res = await _client.get('/api/social/friends/status/$otherId');
    return res.data['status'] as String? ?? 'none';
  }

  // ---------------- Direct Messages ----------------

  Future<List<Map<String, dynamic>>> getConversation(int otherId) async {
    final res = await _client.get('/api/social/messages/$otherId');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> sendMessage(int toUserId, String content) async {
    final res = await _client.post('/api/social/messages/$toUserId',
        data: {'content': content});
    return (res.data as Map).cast<String, dynamic>();
  }

  // ---------------- Insiders ----------------

  Future<bool> registerGuide({
    required String chinaId,
    String? idFront,
    String? idBack,
    required List<Map<String, String>> languages,
    String? cert,
    required List<String> interests,
    required bool acceptedTerms,
  }) async {
    final res = await _client.post('/api/guides/register', data: {
      'china_id': chinaId,
      'id_front': idFront,
      'id_back': idBack,
      'languages': languages,
      'cert_uploaded': cert,
      'interests': interests,
      'accepted_terms': acceptedTerms,
    });
    return (res.data['is_local_guide'] as bool?) ?? false;
  }

  Future<bool> guideStatus() async {
    final res = await _client.get('/api/guides/status');
    return (res.data['is_local_guide'] as bool?) ?? false;
  }

  Future<Map<String, dynamic>> guideProfile(int userId) async {
    final res = await _client.get('/api/guides/profile/$userId');
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> nearbyGuides({String? date}) async {
    final res = await _client.get('/api/guides/nearby',
        params: date != null ? {'date': date} : null);
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  // Availability
  Future<List<Map<String, dynamic>>> myAvailability() async {
    final res = await _client.get('/api/guides/availability');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> setAvailability(String date, bool available) async {
    await _client.post('/api/guides/availability',
        data: {'date': date, 'available': available});
  }

  // Jobs
  Future<List<Map<String, dynamic>>> myJobs() async {
    final res = await _client.get('/api/guides/jobs');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> bookJob(int guideId, String date, {String? note}) async {
    await _client.post('/api/guides/jobs/book',
        data: {'guide_id': guideId, 'date': date, 'note': note});
  }

  // ---------------- Radar (nearby real users) ----------------

  Future<List<Map<String, dynamic>>> nearbyUsers() async {
    final res = await _client.get('/api/radar/nearby');
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
