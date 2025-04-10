import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../services/fog_of_war_provider.dart';
// Import math for cos and pi
import 'dart:math';


class FogOverlay extends StatefulWidget {
  final MapController mapController;
  final FogOfWarProvider fogProvider;

  const FogOverlay({
    super.key,
    required this.mapController,
    required this.fogProvider,
  });

  @override
  State<FogOverlay> createState() => _FogOverlayState();
}

class _FogOverlayState extends State<FogOverlay> {
  List<GeoPoint> _visibleRegion = [];
  double _currentZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _setupMapListeners();
  }

  void _setupMapListeners() {
    widget.mapController.listenerRegionIsChanging.addListener(() async {
      if (widget.mapController.listenerRegionIsChanging.value != null) {
        _updateVisibleRegion();
      }
    });

    // For older versions of the plugin, we'll use a fixed zoom level
    setState(() {
      _currentZoom = 18.0; // Default zoom level
    });

    // Initial update
    _updateVisibleRegion();
  }

  Future<void> _updateVisibleRegion() async {
    try {
      // For older versions, we'll estimate the visible region based on the current position
      final currentPosition = widget.fogProvider.currentPosition;
      if (currentPosition != null) {
        // Estimate visible region (approximately 500m in each direction at zoom level 18)
        final double lat = currentPosition.latitude;
        final double lon = currentPosition.longitude;
        final double latOffset = 0.005; // Approximately 500m in latitude
        final double lonOffset = 0.005 / cos(lat * pi / 180); // Adjust for longitude

        setState(() {
          _visibleRegion = [
            GeoPoint(latitude: lat + latOffset, longitude: lon - lonOffset),
            GeoPoint(latitude: lat + latOffset, longitude: lon + lonOffset),
            GeoPoint(latitude: lat - latOffset, longitude: lon + lonOffset),
            GeoPoint(latitude: lat - latOffset, longitude: lon - lonOffset),
          ];
        });
      }
    } catch (e) {
      print('Error updating visible region: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleRegion.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: FogPainter(
        visibleRegion: _visibleRegion,
        fogProvider: widget.fogProvider,
        zoom: _currentZoom,
      ),
    );
  }
}

class FogPainter extends CustomPainter {
  final List<GeoPoint> visibleRegion;
  final FogOfWarProvider fogProvider;
  final double zoom;

  FogPainter({
    required this.visibleRegion,
    required this.fogProvider,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibleRegion.isEmpty) return;

    // Calculate the bounds of the visible region
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (var point in visibleRegion) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLon = minLon > point.longitude ? point.longitude : minLon;
      maxLon = maxLon < point.longitude ? point.longitude : maxLon;
    }

    // Calculate the size of a tile in degrees based on zoom level
    // At zoom level 18, 1 meter is approximately visible
    final double latDegreePerMeter = 1 / 111111.0;
    final double lonDegreePerMeter = 1 / (111111.0 * cos(minLat * (pi / 180)));

    final double tileSize = fogProvider.tileSize;
    final double latTileSize = tileSize * latDegreePerMeter;
    final double lonTileSize = tileSize * lonDegreePerMeter;

    // Calculate the number of tiles in the visible region
    final int latTiles = ((maxLat - minLat) / latTileSize).ceil() + 1;
    final int lonTiles = ((maxLon - minLon) / lonTileSize).ceil() + 1;

    // Calculate the size of each tile on the screen
    final double tileWidth = size.width / lonTiles;
    final double tileHeight = size.height / latTiles;

    // Draw the fog (black tiles) for unexplored areas
    final Paint fogPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int latIndex = 0; latIndex < latTiles; latIndex++) {
      for (int lonIndex = 0; lonIndex < lonTiles; lonIndex++) {
        final double tileLat = maxLat - (latIndex * latTileSize);
        final double tileLon = minLon + (lonIndex * lonTileSize);

        // Check if this tile is exposed
        if (!fogProvider.isTileExposed(tileLat, tileLon)) {
          final double left = lonIndex * tileWidth;
          final double top = latIndex * tileHeight;

          canvas.drawRect(
            Rect.fromLTWH(left, top, tileWidth, tileHeight),
            fogPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(FogPainter oldDelegate) {
    return oldDelegate.visibleRegion != visibleRegion ||
        oldDelegate.zoom != zoom ||
        oldDelegate.fogProvider.exposedTiles != fogProvider.exposedTiles;
  }
}

