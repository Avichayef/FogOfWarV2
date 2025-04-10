import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
// Import math for cos and pi
import 'dart:math';


class FogOfWarProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  bool _offlineMode = false;

  User? _user;
  LocationData? _currentPosition;
  Set<String> _exposedTiles = {};
  bool _isLoading = false;
  StreamSubscription<LocationData>? _positionSubscription;

  // Tile size in meters (1 meter as requested)
  final double tileSize = 1.0;

  // Visibility radius in meters (how far the user can see)
  final double visibilityRadius = 10.0;

  LocationData? get currentPosition => _currentPosition;
  Set<String> get exposedTiles => _exposedTiles;
  bool get isLoading => _isLoading;

  void initialize(User user) {
    _user = user;

    // Only load terrain from server if not in offline mode
    if (!_offlineMode) {
      _loadExposedTerrain();
    }

    _startLocationTracking();
  }

  // Set offline mode
  void setOfflineMode(bool value) {
    _offlineMode = value;

    // If we're switching to offline mode, make sure we have some initial exposed tiles
    // around the current position to avoid a completely black map
    if (value && _currentPosition != null) {
      _exposeTerrainAroundPosition(_currentPosition!);
    }

    notifyListeners();
  }

  Future<void> _loadExposedTerrain() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      var terrainData = await _apiService.getExposedTerrain(_user!.id);

      _exposedTiles = terrainData.map((terrain) {
        return _getTileKey(terrain['latitude'], terrain['longitude']);
      }).toSet();

      notifyListeners();
    } catch (e) {
      print('Error loading exposed terrain: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      await _locationService.startTracking();

      _positionSubscription = _locationService.positionStream.listen((position) {
        _currentPosition = position;
        _exposeTerrainAroundPosition(position);
        notifyListeners();
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  Future<void> _exposeTerrainAroundPosition(LocationData position) async {
    if (_user == null) return;

    // Calculate the tiles that should be exposed based on the visibility radius
    final double latDegreePerMeter = 1 / 111111.0; // Approximate meters per degree of latitude
    final double lonDegreePerMeter = 1 / (111111.0 * cos(position.latitude! * (pi / 180))); // Approximate meters per degree of longitude

    final double latRadius = visibilityRadius * latDegreePerMeter;
    final double lonRadius = visibilityRadius * lonDegreePerMeter;

    // Calculate the grid of tiles to expose
    for (double lat = position.latitude! - latRadius; lat <= position.latitude! + latRadius; lat += tileSize * latDegreePerMeter) {
      for (double lon = position.longitude! - lonRadius; lon <= position.longitude! + lonRadius; lon += tileSize * lonDegreePerMeter) {
        // Calculate distance from current position to this tile
        // Calculate distance using Haversine formula
        double distance = _calculateDistance(
          position.latitude!,
          position.longitude!,
          lat,
          lon
        );

        // Only expose tiles within the visibility radius
        if (distance <= visibilityRadius) {
          String tileKey = _getTileKey(lat, lon);

          if (!_exposedTiles.contains(tileKey)) {
            _exposedTiles.add(tileKey);

            // Save to database if not in offline mode
            if (!_offlineMode) {
              await _apiService.saveExposedTerrain(_user!.id, lat, lon);
            }
          }
        }
      }
    }

    notifyListeners();
  }

  String _getTileKey(double latitude, double longitude) {
    // Round to the nearest tile
    final double latDegreePerMeter = 1 / 111111.0;
    final double lonDegreePerMeter = 1 / (111111.0 * cos(latitude * (pi / 180)));

    final int latTile = (latitude / (tileSize * latDegreePerMeter)).round();
    final int lonTile = (longitude / (tileSize * lonDegreePerMeter)).round();

    return '$latTile:$lonTile';
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  bool isTileExposed(double latitude, double longitude) {
    return _exposedTiles.contains(_getTileKey(latitude, longitude));
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }
}

