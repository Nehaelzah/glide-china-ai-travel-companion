import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../providers/chat_provider.dart';
import '../../services/speech_service.dart';
import '../../services/mock_data.dart';
import '../../services/api_client.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/glide_logo.dart';
import '../../widgets/weather_icon.dart';
import 'pocket_tab.dart';
import 'mic_tab.dart';
import 'my_itinerary_screen.dart';
import 'esim_guide_screen.dart';
import 'alipay_guide_screen.dart';
import 'didi_guide_screen.dart';
import 'emergency_guide_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with TickerProviderStateMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _weatherOpen = false;
  int? _playingIndex;
  String _lastCategory = ''; // food/transport/attractions/emergency
  final Set<String> _savedItinerary = {}; // texts saved to itinerary (for filled icon)
  WeatherSnapshot _weather = const WeatherSnapshot(tempC: 28, aqi: 42, uv: 6, condition: 'Partly cloudy');

  // Real device GPS location passed to the AI chat context.
  double? _latitude;
  double? _longitude;
  String? _locationName;

  // Task list (first-time visitor)
  final Set<int> _completedTasks = {};
  bool _tasksCollapsed = false;
  late AnimationController _collapseCtrl;
  late Animation<double> _collapseAnim;

  static const _tasks = [
    ('Get your Chinese SIM / eSIM', 'Recommended providers in Pocket'),
    ('Download & set up Alipay', 'Step-by-step guide'),
    ('Download Didi Chuxing', 'Ride-hailing essential'),
    ('Save emergency phrase cards', 'Help / Police / Allergy'),
  ];

  @override
  void initState() {
    super.initState();
    _collapseCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _collapseAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _collapseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRealLocationAndWeather();
      if (!mounted) return;
      final state = context.read<AppState>();
      context.read<ChatProvider>().seedGreeting(
        username: state.nickname,
        weather: _weather,
        mood: state.mood,
        firstTime: state.firstTimeInChina,
        locationName: _locationName,
      );
    });
  }

  String _todayDate() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _fallbackLocationFromCoordinates(double lat, double lon) {
    // Local fallback labels only. The app first tries backend reverse geocoding.
    bool inBox(double minLat, double maxLat, double minLon, double maxLon) {
      return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
    }

    // DNUI / Dalian software-park campus area used in the demo.
    if (inBox(38.8700, 38.9050, 121.5000, 121.5550)) {
      return 'DNUI Campus, Dalian';
    }

    if (inBox(38.70, 39.20, 121.10, 122.20)) {
      return 'Dalian, Liaoning';
    }

    // Common China demo cities.
    if (inBox(31.00, 31.45, 121.10, 121.80)) return 'Shanghai';
    if (inBox(39.70, 40.15, 116.10, 116.75)) return 'Beijing';
    if (inBox(22.40, 23.05, 113.70, 114.70)) return 'Shenzhen';
    if (inBox(22.85, 23.35, 113.00, 113.75)) return 'Guangzhou';
    if (inBox(30.45, 30.85, 103.70, 104.35)) return 'Chengdu';
    if (inBox(30.15, 30.45, 119.90, 120.45)) return 'Hangzhou';
    if (inBox(34.10, 34.45, 108.70, 109.15)) return "Xi'an";

    // Non-China fallback labels, useful while testing outside China.
    if (inBox(-27.75, -27.20, 152.70, 153.35)) return 'Brisbane';
    if (inBox(1.15, 1.50, 103.55, 104.10)) return 'Singapore';
    if (inBox(9.80, 12.90, 74.80, 77.50)) return 'Kerala';

    return 'your current area';
  }

  Future<String> _reverseLocationName(double lat, double lon) async {
    try {
      final res = await ApiClient.instance
          .get('/api/map/reverse?lat=$lat&lng=$lon')
          .timeout(const Duration(seconds: 8));

      final data = res.data as Map<String, dynamic>;

      final candidates = <String?>[
        data['name']?.toString(),
        data['formatted_address']?.toString(),
        data['address']?.toString(),
        data['district']?.toString(),
        data['city']?.toString(),
      ];

      for (final candidate in candidates) {
        final value = candidate?.trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'your current area') {
          return value;
        }
      }
    } catch (_) {
      // If reverse geocoding fails, use the safe local fallback below.
    }

    return _fallbackLocationFromCoordinates(lat, lon);
  }

  void _sendWithCategory(String prompt, String category) {
    setState(() => _lastCategory = category);
    _send(prompt);
  }

  Future<void> _fetchWeather() async {
    // Safe fallback used only when the real weather endpoint is unavailable.
    final w = await MockData.fetchWeather();
    if (mounted) setState(() => _weather = w);
  }

  Future<void> _loadRealLocationAndWeather() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationName = 'Location unavailable');
        }
        await _fetchWeather();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationName = 'Location permission not granted');
        }
        await _fetchWeather();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      final locationName = await _reverseLocationName(
        pos.latitude,
        pos.longitude,
      );

      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationName = locationName;
      });

      await _fetchWeatherForLocation(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) {
        setState(() => _locationName = 'Location unavailable');
      }
      await _fetchWeather();
    }
  }

  Future<void> _fetchWeatherForLocation(double lat, double lon) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/weather?lat=$lat&lon=$lon',
      );
      final data = res.data as Map<String, dynamic>;

      num? readNum(List<String> keys) {
        for (final key in keys) {
          final value = data[key];
          if (value is num) return value;
          if (value is String) return num.tryParse(value);
        }
        return null;
      }

      final w = WeatherSnapshot(
        tempC: (readNum(['temp_c', 'tempC', 'temperature', 'temperature_c']) ?? 28).round(),
        aqi: (readNum(['aqi', 'air_quality_index']) ?? 42).round(),
        uv: (readNum(['uv', 'uv_index']) ?? 6).round(),
        condition: (data['condition'] ?? data['weather'] ?? data['description'] ?? 'Partly cloudy').toString(),
      );

      if (mounted) setState(() => _weather = w);
    } catch (_) {
      await _fetchWeather();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _collapseCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveToItinerary(String text, {String category = ''}) async {
    // Don't save if this is a question with choices (not an itinerary)
    if (text.contains('?') && RegExp(r'^-\s+').hasMatch(text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('answer_first')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Pick today's date for now
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Parse the AI response into itinerary items
    final lines = text.split('\n');
    final items = <ItineraryItem>[];
    final timeRegex = RegExp(r'(\d{1,2}:\d{2})');
    String currentTime = '';
    String currentTitle = '';
    String currentLoc = '';

    String clean(String s) {
      return s.replaceAll(RegExp(r'^[\s\-–—:*#_>]+'), '')
          .replaceAll(RegExp(r'[\s\-–—:*#_]+$'), '')
          .trim();
    }

    for (final line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      trimmed = trimmed.replaceAll(RegExp(r'\*\*|__|~~|`'), '');

      String? foundTime;
      String rest = trimmed;

      final match = timeRegex.firstMatch(trimmed);
      if (match != null) {
        foundTime = match.group(1)!;
        rest = trimmed.replaceFirst(foundTime, '').trim();
        rest = rest.replaceFirst(RegExp(r'^[\s\-–—:>]+'), '');
      }

      if (foundTime != null) {
        if (currentTitle.isNotEmpty) {
          items.add(ItineraryItem(
            time: currentTime,
            title: clean(currentTitle),
            type: _guessType(currentTitle),
            duration: '1h',
            location: clean(currentLoc),
            category: category,
          ));
        }
        currentTime = foundTime;
        // Extract location if present (after @)
        final atMatch = RegExp(r'[@](.+)$').firstMatch(rest);
        if (atMatch != null) {
          currentTitle = rest.substring(0, atMatch.start).trim();
          currentLoc = atMatch.group(1)!.trim();
        } else {
          currentTitle = rest;
          currentLoc = '';
        }
      } else if (currentTitle.isNotEmpty) {
        // Check if line looks like a location/address
        if (trimmed.contains(RegExp(r'[路街大道巷]|Rd|St|Ave'))) {
          currentLoc = (currentLoc.isNotEmpty ? '$currentLoc ' : '') + trimmed;
        } else {
          currentTitle += ' $trimmed';
        }
      }
    }
    if (currentTitle.isNotEmpty) {
      items.add(ItineraryItem(
        time: currentTime,
        title: clean(currentTitle),
        type: _guessType(currentTitle),
        duration: '1h',
        location: clean(currentLoc),
        category: category,
      ));
    }

    // Fallback: save whole text as one entry
    if (items.isEmpty) {
      String fallbackTitle = text
          .replaceAll(RegExp(r'\n+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (fallbackTitle.length > 80) {
        fallbackTitle = '${fallbackTitle.substring(0, 80)}...';
      }
      items.add(ItineraryItem(
        time: '09:00',
        title: fallbackTitle,
        type: 'attraction',
        duration: '1h',
        category: category,
      ));
    }

    try {
      final res = await ApiClient.instance.post('/api/itineraries/save', data: {
        'date': dateStr,
        'title': 'My Day',
        'items': items.map((i) => i.toJson()).toList(),
      });
      final day = ItineraryDay.fromJson(res.data as Map<String, dynamic>);
      if (mounted) {
        context.read<AppState>().setItinerary(day);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('saved_to_itinerary')),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _lastCategory = '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('save_failed')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _guessType(String title) {
    final t = title.toLowerCase();
    if (t.contains('bus') || t.contains('train') || t.contains('metro') ||
        t.contains('subway') || t.contains('drive') || t.contains('taxi') ||
        t.contains('transport') || t.contains('walk') || t.contains('bike') ||
        t.contains('uber') || t.contains('didi'))
      return 'transport';
    if (t.contains('lunch') || t.contains('dinner') || t.contains('breakfast') ||
        t.contains('restaurant') || t.contains('cafe') || t.contains('eat') ||
        t.contains('food') || t.contains('dining') || t.contains('snack'))
      return 'food';
    if (t.contains('entertainment') || t.contains('bar') || t.contains('club') ||
        t.contains('night') || t.contains('show') || t.contains('music') ||
        t.contains('museum') || t.contains('park') || t.contains('garden'))
      return 'entertainment';
    if (t.contains('rest') || t.contains('hotel') || t.contains('break') ||
        t.contains('nap') || t.contains('check'))
      return 'rest';
    return 'attraction';
  }

  /// Check whether the AI response contains actual itinerary/plan content
  /// so we can show (or hide) the "Save to Calendar" button.
  bool _hasItineraryContent(String text) {
    // AI adds this marker per system prompt when generating plans
    if (text.contains('[📅 Save to My Itinerary]')) return true;
    // Plan A / Plan B structure
    if (RegExp(r'Plan\s+[AB]|方案[一二AB]', caseSensitive: false).hasMatch(text)) return true;
    // At least 2 time-stamped lines (itinerary format like "09:00 Visit...")
    final timeLines =
        text.split('\n').where((l) => RegExp(r'^\s*\d{1,2}:\d{2}').hasMatch(l)).length;
    return timeLines >= 2;
  }

  void _send(String text) {
    final lang = context.read<AppState>().language.name;
    final mood = context.read<AppState>().mood;
    context.read<ChatProvider>().send(
      text,
      language: lang,
      weatherTempC: _weather.tempC,
      weatherCondition: _weather.condition,
      weatherAqi: _weather.aqi,
      weatherUv: _weather.uv,
      mood: mood?.label,
      dietaryRestrictions: context.read<AppState>().dietaryRestrictions,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
    );
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _play(int index, String text) async {
    setState(() => _playingIndex = index);
    final lang = context.read<AppState>().language.name;
    final ok = await SpeechService.instance.speak(text, language: lang);
    if (!ok && mounted) {
      showGlideSnack(context,
          'No $lang voice on this device. Install it in system settings.',
          icon: Icons.record_voice_over_outlined);
    }
    if (mounted) setState(() => _playingIndex = null);
  }

  void _openMoodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodSheet(
        onPick: (mood) {
          context.read<AppState>().setMood(mood);
          // Sync to backend
          ApiClient.instance.put('/api/user/preferences', data: {
            'mood_label': mood?.label,
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _calendarBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyItineraryScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.teal.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, size: 17, color: AppColors.teal),
              const SizedBox(width: 6),
              Text(
                context.t('my_itinerary'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final state = context.watch<AppState>();
    final mood = state.mood;

    final hasMessages = chat.messages.isNotEmpty;
    final needsTaskList = hasMessages && state.isNewRegistration && state.firstTimeInChina && !_tasksCollapsed;
    final extraCount = needsTaskList ? 1 : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _header(mood),
            _calendarBar(),
            if (_weatherOpen) _weatherCard(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: chat.messages.length + (chat.thinking ? 1 : 0) + extraCount,
                itemBuilder: (context, i) {
                  // Position 0 = welcome message
                  if (i == 0 && hasMessages) {
                    return _bubble(chat.messages[0], 0);
                  }
                  // Extra items after welcome
                  int cursor = 1;
                  if (needsTaskList) {
                    if (i == cursor) return _taskList();
                    cursor++;
                  }
                  // Regular messages
                  final msgIdx = i - extraCount;
                  if (msgIdx < chat.messages.length) {
                    return _bubble(chat.messages[msgIdx], msgIdx);
                  }
                  // Thinking indicator
                  if (msgIdx == chat.messages.length && chat.thinking) {
                    return const _TypingBubble();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 10),
            _quickActions(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(Mood? mood) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const GlideLogo(size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('app_name'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(context.t('travel_assistant'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _weatherToggleButton(),
          const SizedBox(width: 8),
          _dietaryButton(),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: _openMoodPicker,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: mood != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/mood/${mood.iconAsset}.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.sentiment_satisfied_alt,
                            color: Colors.white,
                            size: 16),
                      ),
                    )
                        : const Icon(Icons.sentiment_satisfied_alt,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 7),
                  Text(mood?.label ?? context.t('mood'),
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.inkFaint, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dietaryButton() {
    final restrictions = context.read<AppState>().dietaryRestrictions;
    final hasRestrictions = restrictions.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: _openDietaryPicker,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: hasRestrictions ? AppColors.teal : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Icon(
          Icons.restaurant,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }

  void _openDietaryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DietarySheet(),
    );
  }

  Widget _weatherToggleButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: () => setState(() => _weatherOpen = !_weatherOpen),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _weatherOpen ? AppColors.teal : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: WeatherIcon(_weather.condition, size: 22),
      ),
    );
  }

  Widget _weatherCard() {
    final w = _weather;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WeatherIcon(w.condition, size: 24),
            const SizedBox(width: 6),
            Text('${w.tempC}°C',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink)),
            const SizedBox(width: 14),
            Container(width: 1, height: 18, color: AppColors.line),
            const SizedBox(width: 10),
            _miniStat('AQI ${w.aqi}', AppColors.green),
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: AppColors.line),
            const SizedBox(width: 10),
            _miniStat('UV ${w.uv}', AppColors.amber),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: color),
    );
  }

  Widget _bubble(ChatMessage m, int index) {
    final isUser = m.fromUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.userBubble : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: isUser ? null : AppShadows.soft,
                  ),
                  child: _formattedMessageText(m.text, isUser),
                ),
                if (!isUser) _aiActions(m, index),
                // Show selectable choice buttons below AI messages
                if (!isUser && m.choices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: m.choices.map((c) => _choiceChip(c)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formattedMessageText(String text, bool isUser) {
    final baseStyle = TextStyle(
      color: isUser ? Colors.black : AppColors.ink,
      height: 1.4,
      fontSize: 14.5,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _messageSpans(text, baseStyle),
      ),
    );
  }

  List<InlineSpan> _messageSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var index = 0;

    void addPlain(String value) {
      if (value.isEmpty) return;
      // Hide stray Markdown markers instead of showing raw asterisks.
      spans.add(TextSpan(text: value.replaceAll('*', '')));
    }

    while (index < text.length) {
      if (text.startsWith('**', index)) {
        final close = text.indexOf('**', index + 2);
        if (close != -1) {
          final value = text.substring(index + 2, close);
          spans.add(TextSpan(
            text: value,
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ));
          index = close + 2;
          continue;
        }

        addPlain(text.substring(index + 2));
        break;
      }

      if (text[index] == '*' &&
          index + 1 < text.length &&
          text[index + 1].trim().isNotEmpty) {
        final close = text.indexOf('*', index + 1);
        if (close != -1 && text[close - 1].trim().isNotEmpty) {
          final value = text.substring(index + 1, close);
          spans.add(TextSpan(
            text: value,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          index = close + 1;
          continue;
        }

        index++;
        continue;
      }

      final nextBold = text.indexOf('**', index);
      final nextStar = text.indexOf('*', index);
      final nextCandidates = [
        if (nextBold != -1) nextBold,
        if (nextStar != -1) nextStar,
      ];

      final next = nextCandidates.isEmpty
          ? text.length
          : nextCandidates.reduce((a, b) => a < b ? a : b);

      addPlain(text.substring(index, next));
      index = next;
    }

    return spans;
  }

  Widget _choiceChip(ChatChoice c) {
    return InkWell(
      onTap: () => _send(c.value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withOpacity(0.3)),
        ),
        child: Text(
          c.label,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _aiActions(ChatMessage m, int index) {
    final showSave = _hasItineraryContent(m.text);
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => _play(index, m.text),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _playingIndex == index
                        ? Icons.graphic_eq
                        : Icons.volume_up_outlined,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _playingIndex == index ? context.t('playing') : context.t('listen'),
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          if (showSave) ...[
            InkWell(
              onTap: () {
                final isSaved = _savedItinerary.contains(m.text);
                if (isSaved) {
                  setState(() => _savedItinerary.remove(m.text));
                  showGlideSnack(context, context.t('removed_from_itinerary'),
                      icon: Icons.bookmark_remove_outlined);
                } else {
                  _saveToItinerary(m.text, category: _lastCategory);
                  setState(() {
                    _savedItinerary.add(m.text);
                    _lastCategory = '';
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        _savedItinerary.contains(m.text)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 16,
                        color: AppColors.teal),
                    const SizedBox(width: 4),
                    Text(
                      _savedItinerary.contains(m.text)
                          ? context.t('saved_label')
                          : context.t('save_to_itinerary'),
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickActions() {
    // 4 intelligent quick actions: food, transport, attractions, emergency
    final actions = [
      (context.t('nearby_food'), Icons.restaurant, context.t('nearby_food_prompt'), 'food'),
      (context.t('nearby_transport'), Icons.directions_bus, context.t('nearby_transport_prompt'), 'transport'),
      (context.t('nearby_attractions'), Icons.explore, context.t('nearby_attractions_prompt'), 'attractions'),
      (context.t('emergency_help'), Icons.emergency, context.t('emergency_help_prompt'), 'emergency'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Builder(builder: (context) {
                final (label, icon, prompt, category) = actions[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => _sendWithCategory(prompt, category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: AppColors.teal),
                        const SizedBox(width: 5),
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }),
            ],

          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.mic_none, color: AppColors.teal),
                    onPressed: () => showGlideSnack(context,
                        context.t('voice_hint'),
                        icon: Icons.mic),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                      cursorColor: AppColors.teal,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: context.t('chat_hint'),
                        hintStyle: const TextStyle(color: AppColors.inkFaint),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                        const EdgeInsets.fromLTRB(0, 14, 16, 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: () => _send(_input.text),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Task list (first-time China visitors only) ──
  Widget _taskList() {
    return SizeTransition(
      sizeFactor: _collapseAnim,
      axisAlignment: -1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('✅', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              const Text('Get these sorted before landing',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            for (int i = 0; i < _tasks.length; i++) _taskItem(i),
          ],
        ),
      ),
    );
  }

  Widget _taskItem(int index) {
    final (title, desc) = _tasks[index];
    final done = _completedTasks.contains(index);
    return InkWell(
      onTap: done ? null : () => _handleTaskTap(index),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF4CAF50) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? const Color(0xFF4CAF50) : AppColors.inkFaint,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? AppColors.inkFaint : AppColors.ink)),
                  Text(desc,
                      style: const TextStyle(color: AppColors.inkFaint, fontSize: 11)),
                ],
              ),
            ),
            if (!done)
              const Icon(Icons.chevron_right, size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  void _handleTaskTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EsimGuideScreen()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AlipayGuideScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DidiGuideScreen()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EmergencyGuideScreen()));
        break;
    }
    setState(() => _completedTasks.add(index));
    _checkAllTasksDone();
  }

  void _checkAllTasksDone() {
    if (_completedTasks.length >= _tasks.length) {
      _collapseCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _tasksCollapsed = true);
        context.read<ChatProvider>().addAiMessage(
          'All done! You\'re a digital survival pro now 🎉 '
              'Where to next? I\'ll help you plan it!',
        );
      });
    }
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const GlideLogo(size: 18),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.soft,
            ),
            child: Text(context.t('typing'),
                style: const TextStyle(color: AppColors.inkFaint, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _MoodSheet extends StatelessWidget {
  final ValueChanged<Mood> onPick;
  const _MoodSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('mood_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('mood_subtitle'),
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Mood.all.map((m) {
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () => onPick(m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            'assets/images/mood/${m.iconAsset}.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.sentiment_satisfied_alt,
                                size: 18,
                                color: AppColors.teal),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietarySheet extends StatefulWidget {
  const _DietarySheet();

  @override
  State<_DietarySheet> createState() => _DietarySheetState();
}

class _DietarySheetState extends State<_DietarySheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(context.read<AppState>().dietaryRestrictions);
  }

  void _save() {
    context.read<AppState>().setDietaryRestrictions(_selected);
    ApiClient.instance.put('/api/user/preferences', data: {
      'dietary_restrictions': _selected.toList(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 18),
            Text(
              t('dietary'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(t('dietary_prompt'),
                style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: DietaryRestriction.all.map((r) {
                    final checked = _selected.contains(r.key);
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Text(r.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            r.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      value: checked,
                      activeColor: AppColors.teal,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (_) {
                        setState(() {
                          if (checked) {
                            _selected.remove(r.key);
                          } else {
                            _selected.add(r.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t('confirm'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
