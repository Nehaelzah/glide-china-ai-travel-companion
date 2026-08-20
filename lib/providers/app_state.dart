import 'package:flutter/material.dart';
import '../models/models.dart';

/// Demo seed friends so the friend list is non-empty immediately.
List<FriendInfo> _seedFriends() => [
  FriendInfo(
    id: 'sakura',
    nickname: 'Sakura',
    flag: '🇯🇵',
    country: 'Japan',
    daysInChina: 14,
    avatarColor: const Color(0xFFE91E63),
    tags: ['Photography', 'Foodie', 'Anime'],
  ),
  FriendInfo(
    id: 'marco',
    nickname: 'Marco',
    flag: '🇮🇹',
    country: 'Italy',
    daysInChina: 21,
    avatarColor: const Color(0xFFFF9800),
    tags: ['Cooking', 'History', 'Wine'],
  ),
];

/// App-wide state shared across every screen (user profile, language, privacy,
/// mood, saved places). Held with Provider so any screen can read or update it.
///
/// NOTE: This is in-memory only for the prototype. When you add a backend,
/// persist these fields on sign-in and hydrate this class from it.
class AppState extends ChangeNotifier {
  // ---- Onboarding / auth ----
  AppLanguage _language = AppLanguage.all.first;
  bool _loggedIn = false;
  bool _firstTimeInChina = true;
  bool _onboarded = false;
  bool _isNewRegistration = false;

  // ---- Profile ----
  String _nickname = 'Traveller';
  String _phone = '';
  String _nationality = 'United States';
  String _nationFlag = '🇺🇸';
  int _daysInChina = 1;
  String? _avatarPath;
  String? _avatarBase64;

  // ---- Preferences ----
  Mood? _mood;
  final Set<String> _savedPlaces = {};
  final Set<String> _dietaryRestrictions = {};
  String? _backgroundPath;
  List<String> _profileTags = [];

  // ---- Privacy / Radar visibility ----
  bool _showOnRadar = true;
  bool _showExactLocation = false;
  bool _allowMessages = true;
  bool _hideProfile = false;
  bool _allowProfileView = true;
  bool _notificationsEnabled = true;

  // ---- Friends ----
  final Map<String, FriendInfo> _friends = {
    for (final f in _seedFriends()) f.id: f,
  };
  final Set<String> _pendingRequests = {};
  final Map<String, FriendInfo> _incomingRequests = {
    'yuki': FriendInfo(
      id: 'yuki',
      nickname: 'Yuki',
      flag: '🇯🇵',
      country: 'Japan',
      daysInChina: 7,
      avatarColor: const Color(0xFFE91E63),
      tags: ['Photography', 'Sushi'],
    ),
  };

  // ---- Community Posts ----
  final List<UserPost> _communityPosts = [
    UserPost(
      id: 'sakura-post-1',
      nickname: 'Sakura',
      flag: '🇯🇵',
      content: 'Just arrived in Shanghai! The Bund at night is absolutely stunning. Anyone want to grab dinner tomorrow?',
      time: '2h ago',
      likes: 12,
      comments: 4,
      avatarColor: Color(0xFFE91E63),
      commentList: [
        'Welcome to Shanghai! Would love to join!',
        'The Bund is amazing at night! Try the Huangpu river cruise!',
        "I'm free tomorrow! Let me know where!",
        'Check out the bars on the Bund, great views!',
      ],
    ),
    UserPost(
      id: 'marco-post-1',
      nickname: 'Marco',
      flag: '🇮🇹',
      content: 'Tried authentic Beijing duck today. Life changing! Does anyone know where to get good espresso in the hutongs?',
      time: '5h ago',
      likes: 24,
      comments: 8,
      avatarColor: Color(0xFFFF9800),
      commentList: [
        'Try the Great Leap Brewing in the hutongs, great coffee!',
        'Beijing duck is the best! Which restaurant did you go to?',
        "There's a great little coffee shop near Nanluoguxiang!",
        'You have to try the street food in Wangfujing too!',
        'I know a place! Check out Soloist Coffee near Qianmen.',
        'The duck looks amazing! Adding to my list!',
        'Did you go to Sijimin Fu? Best duck in town!',
        'If you like espresso, try the Italian place in Sanlitun!',
      ],
    ),
  ];

  // ---- Getters ----
  AppLanguage get language => _language;
  bool get loggedIn => _loggedIn;
  bool get firstTimeInChina => _firstTimeInChina;
  bool get onboarded => _onboarded;
  bool get isNewRegistration => _isNewRegistration;
  String get nickname => _nickname;
  String get phone => _phone;
  String get nationality => _nationality;
  String get nationFlag => _nationFlag;
  String? get backgroundPath => _backgroundPath;
  List<String> get profileTags => List.unmodifiable(_profileTags);
  int get daysInChina => _daysInChina;
  String? get avatarPath => _avatarPath;
  String? get avatarBase64 => _avatarBase64;
  Mood? get mood => _mood;
  Set<String> get savedPlaces => _savedPlaces;
  Set<String> get dietaryRestrictions => Set.unmodifiable(_dietaryRestrictions);
  bool get showOnRadar => _showOnRadar;
  bool get showExactLocation => _showExactLocation;
  bool get allowMessages => _allowMessages;
  bool get hideProfile => _hideProfile;
  bool get allowProfileView => _allowProfileView;
  bool get notificationsEnabled => _notificationsEnabled;
  int get friendCount => _friends.length;
  Set<String> get friendIds => Set.unmodifiable(_friends.keys);
  List<FriendInfo> get friends => _friends.values.toList();
  Set<String> get pendingRequests => Set.unmodifiable(_pendingRequests);
  Map<String, FriendInfo> get incomingRequests => Map.unmodifiable(_incomingRequests);
  bool get hasIncomingRequests => _incomingRequests.isNotEmpty;
  int get incomingRequestCount => _incomingRequests.length;

  List<UserPost> get communityPosts => _communityPosts;

  // ---- Itineraries ----
  final Map<String, ItineraryDay> _itineraries = {};
  bool _itinerariesLoaded = false;

  Map<String, ItineraryDay> get itineraries => Map.unmodifiable(_itineraries);
  bool get itinerariesLoaded => _itinerariesLoaded;

  ItineraryDay? getItinerary(String date) => _itineraries[date];

  void setItinerary(ItineraryDay day) {
    _itineraries[day.date] = day;
    notifyListeners();
  }

  void setItinerariesLoaded() {
    _itinerariesLoaded = true;
    notifyListeners();
  }

  void removeItinerary(String date) {
    _itineraries.remove(date);
    notifyListeners();
  }

  FriendInfo? friendInfo(String id) => _friends[id];
  bool isFriend(String id) => _friends.containsKey(id);
  bool hasPendingRequest(String id) => _pendingRequests.contains(id);

  // ---- Mutations ----
  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void login({required String nickname, required String phone}) {
    _loggedIn = true;
    if (nickname.trim().isNotEmpty) _nickname = nickname.trim();
    _phone = phone;
    notifyListeners();
  }

  void setFirstTimeInChina(bool value) {
    _firstTimeInChina = value;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    notifyListeners();
  }

  void setIsNewRegistration(bool value) {
    _isNewRegistration = value;
    notifyListeners();
  }

  void setMood(Mood? mood) {
    _mood = mood;
    notifyListeners();
  }

  void setDietaryRestrictions(Set<String> keys) {
    _dietaryRestrictions
      ..clear()
      ..addAll(keys);
    notifyListeners();
  }

  void toggleSavedPlace(String place) {
    if (_savedPlaces.contains(place)) {
      _savedPlaces.remove(place);
    } else {
      _savedPlaces.add(place);
    }
    notifyListeners();
  }

  void updateProfile({
    String? nickname,
    String? nationality,
    String? nationFlag,
    int? daysInChina,
  }) {
    if (nickname != null && nickname.trim().isNotEmpty) _nickname = nickname.trim();
    if (nationality != null) _nationality = nationality;
    if (nationFlag != null) _nationFlag = nationFlag;
    if (daysInChina != null) _daysInChina = daysInChina;
    notifyListeners();
  }

  void setAvatarPath(String? path) {
    _avatarPath = path;
    notifyListeners();
  }

  void setAvatarBase64(String? base64) {
    _avatarBase64 = base64;
    if (base64 != null) _avatarPath = null; // prefer base64
    notifyListeners();
  }

  void setBackgroundPath(String? path) {
    _backgroundPath = path;
    notifyListeners();
  }

  void addProfileTag(String tag) {
    _profileTags.add(tag);
    notifyListeners();
  }

  void removeProfileTag(String tag) {
    _profileTags.remove(tag);
    notifyListeners();
  }

  void setAllowProfileView(bool v) {
    _allowProfileView = v;
    notifyListeners();
  }

  void addFriend(FriendInfo info) {
    _friends[info.id] = info;
    _pendingRequests.remove(info.id);
    notifyListeners();
  }

  void removeFriend(String id) {
    _friends.remove(id);
    notifyListeners();
  }

  void sendFriendRequest(String id) {
    _pendingRequests.add(id);
    notifyListeners();
  }

  /// Simulate receiving an incoming friend request from another user.
  void addIncomingRequest(FriendInfo info) {
    _incomingRequests[info.id] = info;
    notifyListeners();
  }

  void removeIncomingRequest(String id) {
    _incomingRequests.remove(id);
    notifyListeners();
  }

  /// Accept an incoming request: add to friends and remove from pending.
  void acceptFriendRequest(String id) {
    final info = _incomingRequests.remove(id);
    if (info != null) {
      _friends[info.id] = info;
    }
    notifyListeners();
  }

  void addCommunityPost(UserPost post) {
    _communityPosts.insert(0, post);
    notifyListeners();
  }

  void setShowOnRadar(bool v) { _showOnRadar = v; notifyListeners(); }
  void setShowExactLocation(bool v) { _showExactLocation = v; notifyListeners(); }
  void setAllowMessages(bool v) { _allowMessages = v; notifyListeners(); }
  void setHideProfile(bool v) { _hideProfile = v; notifyListeners(); }
  void setNotifications(bool v) { _notificationsEnabled = v; notifyListeners(); }

  void signOut() {
    _loggedIn = false;
    _onboarded = false;
    _mood = null;
    _dietaryRestrictions.clear();
    _savedPlaces.clear();
    _avatarPath = null;
    _avatarBase64 = null;
    _backgroundPath = null;
    _profileTags = [];
    _friends.clear();
    _pendingRequests.clear();
    _incomingRequests.clear();
    _communityPosts.clear();
    _itineraries.clear();
    _itinerariesLoaded = false;
    notifyListeners();
  }
}
