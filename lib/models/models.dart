import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A language the user can pick for the interface, AI, and translation.
class AppLanguage {
  final String code;
  final String name; // English name
  final String nativeName; // e.g. "Español"
  final String flag; // emoji flag

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  ];
}

/// A mood the traveller can set, used to tune AI suggestions.
class Mood {
  final String label;
  final String iconAsset; // filename in assets/images/mood/ (no extension)
  final String prompt; // what gets sent to the AI when picked

  const Mood(this.label, this.iconAsset, this.prompt);

  static const List<Mood> all = [
    Mood('Happy', 'happy', 'I am happy! Suggest something fun to do nearby.'),
    Mood('Hungry', 'hungry', 'I am hungry. Find good food nearby.'),
    Mood('Tired', 'tired', 'I am tired. Suggest somewhere to rest.'),
    Mood('Chill', 'chill', 'I feel chill. Suggest relaxing activities.'),
    Mood('Energetic', 'energetic', 'I am energetic! Any exciting activities nearby?'),
    Mood('Adventurous', 'adventurous', 'I feel adventurous! Any hidden gems nearby?'),
    Mood('Artistic', 'artistic', 'I am feeling artistic. Any creative spots?'),
    Mood('Peaceful', 'peaceful', 'I am peaceful. Find quiet beautiful places.'),
    Mood('Anxious', 'anxious', 'I feel anxious. Suggest calming activities.'),
    Mood('Sad', 'sad', 'I feel sad. Cheer me up with something nice.'),
    Mood('Overwhelmed', 'overwhelmed', 'I feel overwhelmed. Help me relax.'),
    Mood('Lazy', 'lazy', 'I feel lazy. Suggest something easy and close by.'),
    Mood('Unwell', 'unwell', 'I feel unwell. Find medicine or clinics nearby.'),
    Mood('Shopping', 'shopping', 'I want to shop. Best shopping places nearby?'),
    Mood('Night out', 'Nocturnal', 'I want a night out. Bars or nightlife nearby?'),
    Mood('Spacing out', '发呆', 'I am spacing out. What should I do?'),
    Mood('Dead tired', '去世', 'I am dead tired. Help me find food and rest.'),
  ];
}

/// A single setup step with optional screenshot image.
class SetupStep {
  final String instruction;
  final String? imageAsset; // e.g. 'assets/images/guides/alipay_step1.png'

  const SetupStep({required this.instruction, this.imageAsset});
}

/// A Chinese app recommended in onboarding and the Pocket toolkit.
class ChinaApp {
  final String name;
  final String tagline; // short "used for..." explanation
  final IconData icon;
  final Color color;
  final String category;
  final List<SetupStep> setupSteps; // static setup guide content
  final String appStoreUrl; // URL to open in device app store
  final String? imageAssetPath; // e.g. 'assets/images/apps/alipay.png'

  const ChinaApp({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.category,
    required this.setupSteps,
    this.appStoreUrl = '',
    this.imageAssetPath,
  });
}

/// A single message in the AI chat.
class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  /// Optional list of selectable choices shown below the message.
  final List<ChatChoice> choices;

  ChatMessage({required this.text, required this.fromUser, DateTime? time, this.choices = const []})
      : time = time ?? DateTime.now();

  /// Parse choices from the raw text if present.
  /// Supports:
  ///   A. Option / B. Option / C. Option
  ///   A) Option / B) Option
  ///   - Option (legacy)
  /// Choices are only extracted from the last quarter of the text.
  static List<ChatChoice> parseChoices(String text) {
    final result = <ChatChoice>[];
    final lines = text.split('\n');
    bool foundTrigger = false;
    // Only scan the last quarter of the text for choices
    final startIdx = ((lines.length * 3) / 4).floor();
    for (int i = startIdx; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;
      // Look for a question mark or trigger phrase before choices
      if (trimmed.contains('?') ||
          trimmed.contains('preference') ||
          trimmed.contains('sounds better') ||
          trimmed.contains('choose') ||
          trimmed.contains('pick')) {
        foundTrigger = true;
        continue;
      }
      // Match: A. Option  or  A) Option  (letter prefix)
      final letterMatch = RegExp(r'^([A-Da-d])[.)]\s+(.+)$').firstMatch(trimmed);
      if (letterMatch != null) {
        final label = letterMatch.group(2)!.trim();
        if (label.isNotEmpty && label.length <= 80) {
          result.add(ChatChoice(label: label, value: label));
        }
        continue;
      }
      // Match: - Option  (legacy dash format)
      final dashMatch = RegExp(r'^-\s+(.+)$').firstMatch(trimmed);
      if (dashMatch != null) {
        final label = dashMatch.group(1)!.trim();
        if (label.isNotEmpty && label.length <= 80) {
          result.add(ChatChoice(label: label, value: label));
        }
      }
    }
    // Only return choices if we found a trigger before them
    return foundTrigger ? result : [];
  }
}

/// A selectable choice/option in an AI chat message.
class ChatChoice {
  final String label;
  final String value;

  const ChatChoice({required this.label, required this.value});
}

/// A single translated exchange on the Mic page.
class TranslationTurn {
  final String sourceText;
  final String translatedText;
  final String sourceLang; // display name
  final String targetLang;
  final bool fromUserSide; // true = tourist side, false = local side

  TranslationTurn({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.fromUserSide,
  });
}

/// A nearby tourist shown on the Radar page (mock data for MVP).
class NearbyTourist {
  final int? userId; // backend user id (null for mock/default)
  final String nickname;
  final String country;
  final String flag;
  final int distanceMeters;
  final int daysInChina;
  final List<String> languages;
  final List<String> interests;
  final bool online;
  final Color avatarColor;
  final double dx; // relative map position -1..1
  final double dy;

  const NearbyTourist({
    this.userId,
    required this.nickname,
    required this.country,
    required this.flag,
    required this.distanceMeters,
    this.daysInChina = 1,
    required this.languages,
    required this.interests,
    required this.online,
    required this.avatarColor,
    required this.dx,
    required this.dy,
  });
}

/// Details of a friend for display.
class FriendInfo {
  final String id;
  final String nickname;
  final String flag;
  final String country;
  final int daysInChina;
  final Color avatarColor;
  final List<String> tags;
  final String? backgroundPath;

  const FriendInfo({
    required this.id,
    required this.nickname,
    required this.flag,
    required this.country,
    this.daysInChina = 0,
    this.avatarColor = Colors.teal,
    this.tags = const [],
    this.backgroundPath,
  });
}

/// Live weather snapshot for the Chat page toggle.
class WeatherSnapshot {
  final int tempC;
  final int aqi;
  final int uv;
  final String condition;

  const WeatherSnapshot({
    required this.tempC,
    required this.aqi,
    required this.uv,
    required this.condition,
  });
}

/// A single item in a daily itinerary timeline.
class ItineraryItem {
  final String time;
  final String title;
  final String type; // transport/attraction/food/entertainment/rest
  final String duration;
  final String location;
  final String category; // eat/stay/go/explore — which quick-action module

  const ItineraryItem({
    this.time = "",
    this.title = "",
    this.type = "attraction",
    this.duration = "1h",
    this.location = "",
    this.category = "",
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
        time: json['time'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'attraction',
        duration: json['duration'] as String? ?? '1h',
        location: json['location'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'type': type,
        'duration': duration,
        'location': location,
        'category': category,
      };
}

/// A full day itinerary with date and item list.
class ItineraryDay {
  final int? id;
  final String date; // "2026-07-05"
  final String title;
  final List<ItineraryItem> items;
  final int totalHours;

  const ItineraryDay({
    this.id,
    required this.date,
    this.title = "My Day",
    this.items = const [],
    this.totalHours = 0,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        id: json['id'] as int?,
        date: json['date'] as String? ?? '',
        title: json['title'] as String? ?? 'My Day',
        items: (json['items'] as List? ?? [])
            .map((i) => ItineraryItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        totalHours: json['total_hours'] as int? ?? 0,
      );
}

/// A community post shown on the Radar Community tab and in user's post list.
class UserPost {
  final String id;
  final String nickname;
  final String flag;
  String content;
  final String time;
  int likes;
  int comments;
  final Color avatarColor;
  final Uint8List? imageBytes;
  bool liked;
  final List<String> commentList;
  int commentCount;

  UserPost({
    required this.id,
    required this.nickname,
    required this.flag,
    required this.content,
    required this.time,
    this.likes = 0,
    this.comments = 0,
    required this.avatarColor,
    this.imageBytes,
    this.liked = false,
    List<String>? commentList,
    int? commentCount,
  })  : commentList = commentList ?? [],
        commentCount = commentCount ?? comments;
}

/// A dietary restriction the user can set for AI food recommendations.
class DietaryRestriction {
  final String key;
  final String label;
  final String emoji;

  const DietaryRestriction(this.key, this.label, this.emoji);

  static const List<DietaryRestriction> all = [
    DietaryRestriction('no_pork', 'No Pork', '🥩'),
    DietaryRestriction('no_beef', 'No Beef', '🐄'),
    DietaryRestriction('no_seafood', 'No Seafood', '🐟'),
    DietaryRestriction('vegetarian', 'Vegetarian', '🥬'),
    DietaryRestriction('vegan', 'Vegan', '🌱'),
    DietaryRestriction('gluten_free', 'Gluten-Free', '🌾'),
    DietaryRestriction('dairy_free', 'Dairy-Free', '🧀'),
    DietaryRestriction('no_nuts', 'No Nuts', '🥜'),
    DietaryRestriction('no_spicy', 'No Spicy', '🌶️'),
    DietaryRestriction('halal', 'Halal', '☪️'),
    DietaryRestriction('no_allium', 'No Garlic/Onion', '🧅'),
    DietaryRestriction('no_msg', 'No MSG', '🧪'),
    DietaryRestriction('low_salt', 'Low Salt', '🧂'),
  ];

  /// Return the translated label for the given translation function.
  String localized(String Function(String) t) {
    const translations = {
      'no_pork': 'dietary_no_pork',
      'no_beef': 'dietary_no_beef',
      'no_seafood': 'dietary_no_seafood',
      'vegetarian': 'dietary_vegetarian',
      'vegan': 'dietary_vegan',
      'gluten_free': 'dietary_gluten_free',
      'dairy_free': 'dietary_dairy_free',
      'no_nuts': 'dietary_no_nuts',
      'no_spicy': 'dietary_no_spicy',
      'halal': 'dietary_halal',
      'no_allium': 'dietary_no_allium',
      'no_msg': 'dietary_no_msg',
      'low_salt': 'dietary_low_salt',
    };
    return t(translations[key]!);
  }
}
