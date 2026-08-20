/// Weather icon widget — maps QWeather condition text to asset PNGs.
///
/// Falls back to a sensible Material icon when no PNG is available.
library;

import 'package:flutter/material.dart';

/// Maps a QWeather condition string → asset path & optional MaterialIcon fallback.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon(this.condition, {super.key, this.size = 48});

  final String condition;
  final double size;

  static const _base = 'assets/images/weather';

  /// QWeather condition text → asset file name.
  static String _asset(String cond) {
    // Normalise: lowercase, strip punctuation
    final c = cond.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();

    // Exact / prefix matches
    if (c.startsWith('sunny') || c == 'clear' || c == 'fair') return 'sunny';
    if (c.startsWith('partly cloudy')) return 'partly_cloudy_night';
    if (c.startsWith('cloudy') || c.startsWith('overcast')) return 'cloudy';
    if (c.startsWith('light rain') || c.startsWith('light drizzle')) return 'light_rain';
    if (c.startsWith('moderate rain') || c.startsWith('rain')) return 'moderate_rain';
    if (c.startsWith('heavy rain')) return 'heavy_rain';
    if (c.startsWith('rainstorm') || c.startsWith('downpour')) return 'rainstorm';
    if (c.startsWith('thunderstorm') || c.startsWith('thunder')) return 'thunderstorm';
    if (c.startsWith('sleet') || c.startsWith('ice')) return 'sleet';
    if (c.startsWith('light snow')) return 'light_snow';
    if (c.startsWith('moderate snow') || c.startsWith('snow')) return 'moderate_snow';
    if (c.startsWith('heavy snow')) return 'moderate_snow'; // no heavy_snow icon yet
    if (c.startsWith('fog') || c.startsWith('mist')) return 'fog';
    if (c.startsWith('haze')) return 'moderate_haze';
    if (c.startsWith('dust') || c.startsWith('floating dust')) return 'dust';
    if (c.startsWith('sand') || c.startsWith('blowing sand')) return 'sand';
    if (c.startsWith('wind') || c.startsWith('gale')) return ''; // no wind icon yet
    return '';
  }

  /// IconData fallback when no PNG exists for this condition.
  static IconData _fallbackIcon(String cond) {
    final c = cond.toLowerCase();
    if (c.startsWith('wind') || c.startsWith('gale')) return Icons.air;
    if (c.startsWith('heavy snow')) return Icons.ac_unit;
    if (c.startsWith('partly cloudy')) return Icons.cloud;
    if (c.startsWith('thunder')) return Icons.flash_on;
    if (c.startsWith('rainstorm')) return Icons.water;
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    final name = _asset(condition);
    if (name.isEmpty) {
      return Icon(_fallbackIcon(condition), size: size, color: Colors.grey);
    }
    return Image.asset(
      '$_base/$name.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(_fallbackIcon(condition), size: size, color: Colors.grey),
    );
  }
}
