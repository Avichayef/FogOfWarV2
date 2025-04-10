import 'dart:async';
import 'package:location/location.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  final Location _location = Location();
  StreamController<LocationData> _positionStreamController = StreamController<LocationData>.broadcast();
  bool _isTracking = false;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Stream<LocationData> get positionStream => _positionStreamController.stream;
  bool get isTracking => _isTracking;

  Future<bool> requestPermissions() async {
    // Request location permissions
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }

  Future<LocationData?> getCurrentPosition() async {
    bool hasPermission = await requestPermissions();

    if (!hasPermission) {
      print('Location permissions not granted');
      return null;
    }

    try {
      // Add a timeout to prevent hanging
      return await _location.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Location request timed out, using default location');
          // Return a default location (you can adjust these coordinates)
          return LocationData.fromMap({
            'latitude': 32.0853, // Default to Tel Aviv
            'longitude': 34.7818,
            'accuracy': 0.0,
            'altitude': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'heading': 0.0
          });
        },
      );
    } catch (e) {
      print('Error getting current position: $e');
      // Return a default location on error
      return LocationData.fromMap({
        'latitude': 32.0853, // Default to Tel Aviv
        'longitude': 34.7818,
        'accuracy': 0.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0
      });
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    bool hasPermission = await requestPermissions();

    if (!hasPermission) {
      throw Exception('Location permissions not granted or location services disabled');
    }

    // Configure location settings
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // Update every 1 second
      distanceFilter: 1, // Update every 1 meter
    );

    // Start listening to location updates
    _location.onLocationChanged.listen((LocationData locationData) {
      _positionStreamController.add(locationData);
    });

    _isTracking = true;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
  }

  void dispose() {
    stopTracking();
    _positionStreamController.close();
  }
}
