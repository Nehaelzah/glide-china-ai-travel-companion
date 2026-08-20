/// Reusable radar map widget using flutter_map + OpenStreetMap tiles.
///
/// Shows the user as a red dot at center and nearby tourists as coloured
/// markers with distance labels.  Supports pinch-to-zoom / pan natively.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.tourists,
    this.helpMarkers = const [],
  });

  final double userLat;
  final double userLng;
  final List<NearbyTourist> tourists;
  final List<LatLng> helpMarkers; // red markers for help requests

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  late final MapController _mapCtrl = MapController();

  @override
  void didUpdateWidget(RadarMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the user's location changes (e.g. real GPS arrives after the map
    // first rendered), move the map to follow it.
    if (oldWidget.userLat != widget.userLat ||
        oldWidget.userLng != widget.userLng) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapCtrl.move(
              LatLng(widget.userLat, widget.userLng), _mapCtrl.camera.zoom);
        } catch (_) {}
      });
    }
  }

  void _zoomIn() =>
      _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
  void _zoomOut() =>
      _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.userLat, widget.userLng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              minZoom: 10,
              maxZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                // 使用高德地图瓦片（国内可访问）
                urlTemplate:
                    'https://webrd01.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
              ),
              MarkerLayer(markers: [
                // Red dot = current user
                Marker(
                  point: center,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: AppShadows.soft,
                    ),
                  ),
                ),
                // Help markers — red with Help label
                for (final pt in widget.helpMarkers)
                  Marker(
                    point: pt,
                    width: 44,
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.soft,
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.danger,
                            child: const Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: AppShadows.soft,
                          ),
                          child: const Text(
                            'Help',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Nearby tourists from API → blue map markers
                for (final t in widget.tourists)
                  Marker(
                    point: _touristLatLng(center, t),
                    width: 44,
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.soft,
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.teal,
                            child: Text(
                              t.nickname.isNotEmpty ? t.nickname[0] : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Text(
                            _distLabel(t.distanceMeters),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
            ],
          ),
          // Zoom controls
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomBtn(Icons.add, _zoomIn),
                const SizedBox(height: 4),
                _zoomBtn(Icons.remove, _zoomOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Convert NearbyTourist (dx/dy) → map LatLng
// ---------------------------------------------------------------------------

LatLng _touristLatLng(LatLng center, NearbyTourist t) {
  const scale = 0.016;
  final cosLat = math.cos(center.latitude * math.pi / 180);
  final lng = center.longitude + t.dx * scale / (cosLat == 0 ? 1 : cosLat);
  final lat = center.latitude + t.dy * scale;
  return LatLng(lat, lng);
}

String _distLabel(int meters) {
  return meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(1)}km';
}
