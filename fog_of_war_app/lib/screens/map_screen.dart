import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/auth_provider.dart';
import '../services/fog_of_war_provider.dart';
import '../services/location_service.dart';
import 'debug_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  bool _isInitialized = false;
  bool _isLoading = true;
  LocationData? _initialPosition;
  List<Polygon> _fogPolygons = [];

  @override
  void initState() {
    super.initState();

    // Initialize map first
    _initializeMap();

    // Then check offline mode after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isOfflineMode) {
        // Set fog of war provider to offline mode
        final fogProvider = Provider.of<FogOfWarProvider>(context, listen: false);
        fogProvider.setOfflineMode(true);
      }
    });
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Initializing map...');
      // Initialize the fog of war provider with the current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final fogProvider = Provider.of<FogOfWarProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        print('Initializing fog provider with user: ${authProvider.currentUser!.username}');
        fogProvider.initialize(authProvider.currentUser!);
      }

      // Get the current position
      print('Getting current position...');
      _initialPosition = await _locationService.getCurrentPosition();

      if (_initialPosition != null) {
        print('Position received: ${_initialPosition!.latitude}, ${_initialPosition!.longitude}');
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      } else {
        print('Position is null, using default position');
        // Use a default position if we couldn't get the current position
        _initialPosition = LocationData.fromMap({
          'latitude': 32.0853, // Default to Tel Aviv
          'longitude': 34.7818,
          'accuracy': 0.0,
          'altitude': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
          'heading': 0.0
        });
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing map: $e');
      // Use a default position on error
      _initialPosition = LocationData.fromMap({
        'latitude': 32.0853, // Default to Tel Aviv
        'longitude': 34.7818,
        'accuracy': 0.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speed_accuracy': 0.0,
        'heading': 0.0
      });

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default location. Error: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _updateFogOfWar() {
    if (!mounted) return;

    final fogProvider = Provider.of<FogOfWarProvider>(context, listen: false);
    if (fogProvider.currentPosition != null) {
      setState(() {
        // Generate fog polygons
        _fogPolygons = _generateFogPolygons(fogProvider);
      });
    }
  }

  List<Polygon> _generateFogPolygons(FogOfWarProvider fogProvider) {
    if (fogProvider.currentPosition == null) {
      return [];
    }

    final LocationData position = fogProvider.currentPosition!;
    final double lat = position.latitude!;
    final double lng = position.longitude!;

    // Create a large black polygon covering the entire visible area
    final List<LatLng> outerPoints = [
      LatLng(lat - 0.1, lng - 0.1),
      LatLng(lat - 0.1, lng + 0.1),
      LatLng(lat + 0.1, lng + 0.1),
      LatLng(lat + 0.1, lng - 0.1),
    ];

    // Create a hole in the polygon for the exposed area
    final List<List<LatLng>> holes = [];
    final List<LatLng> exposedArea = [];

    // Calculate the radius in degrees (approximately 10 meters)
    final double radiusDegrees = 0.0001;

    // Create a circle of points around the current position
    for (int i = 0; i < 30; i++) {
      final double angle = (i / 30) * 2 * math.pi;
      final double holeX = lat + radiusDegrees * 2 * math.cos(angle);
      final double holeY = lng + radiusDegrees * math.sin(angle);
      exposedArea.add(LatLng(holeX, holeY));
    }

    holes.add(exposedArea);

    // Return the polygon
    return [
      Polygon(
        points: outerPoints,
        holePointsList: holes,
        color: Colors.black.withOpacity(0.7),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fog of War Map'),
        actions: [
          // Offline mode indicator
          if (Provider.of<AuthProvider>(context).isOfflineMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: const Text('Offline'),
                backgroundColor: Colors.orange[100],
                labelStyle: const TextStyle(color: Colors.deepOrange),
                avatar: const Icon(Icons.cloud_off, color: Colors.deepOrange, size: 16),
              ),
            ),
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DebugScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isInitialized
              ? Consumer<FogOfWarProvider>(
                  builder: (context, fogProvider, child) {
                    // Update fog of war when position changes
                    if (fogProvider.currentPosition != null) {
                      _updateFogOfWar();
                    }

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _initialPosition!.latitude ?? 0.0,
                          _initialPosition!.longitude ?? 0.0,
                        ),
                        initialZoom: 18,
                        onMapReady: () {
                          _updateFogOfWar();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.fog_of_war_app',
                        ),
                        // Current location marker
                        if (fogProvider.currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  fogProvider.currentPosition!.latitude!,
                                  fogProvider.currentPosition!.longitude!,
                                ),
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        // Fog of war layer
                        PolygonLayer(polygons: _fogPolygons),
                      ],
                    );
                  },
                )
              : const Center(
                  child: Text(
                    'Failed to initialize map. Please restart the app and check your location permissions.',
                    textAlign: TextAlign.center,
                  ),
                ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () async {
                LocationData? position = await _locationService.getCurrentPosition();
                if (position != null) {
                  _mapController.move(
                    LatLng(position.latitude!, position.longitude!),
                    18,
                  );
                  _updateFogOfWar();
                }
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }


}
