import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/google_maps_service.dart';
import '../../services/location_service.dart';
import '../../core/constants/colors.dart';

/// Example Google Maps Screen Implementation
/// This demonstrates how to use Google Maps with the GoogleMapsService
class ExampleMapsScreen extends StatefulWidget {
  const ExampleMapsScreen({super.key});

  @override
  State<ExampleMapsScreen> createState() => _ExampleMapsScreenState();
}

class _ExampleMapsScreenState extends State<ExampleMapsScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final LocationService _locationService = LocationService();

  final Set<Marker> _markers = {};
  LatLng _userLocation = const LatLng(14.5995, 120.9842); // Default: Manila
  String _currentAddress = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Request permissions
      await _locationService.requestLocationPermission();

      // Check if location service is enabled
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (!isEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => _locationService.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await _locationService.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      // Get address
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _userLocation = location;
          _currentAddress = address ?? 'Unknown location';
          _isLoading = false;
        });

        // Move camera to user location
        await _mapsService.moveCameraToLocation(location);

        // Add user marker
        _addUserMarker(location);
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _addUserMarker(LatLng location) {
    final marker = _mapsService.createMarker(
      markerId: 'user_location',
      position: location,
      title: 'My Location',
      infoWindow: 'You are here',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() => _markers.add(marker));
  }

  void _addDisasterMarker(LatLng location) async {
    final address = await _locationService.getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );

    final marker = _mapsService.createMarker(
      markerId: 'disaster_${DateTime.now().millisecondsSinceEpoch}',
      position: location,
      title: 'Disaster Location',
      infoWindow: address ?? 'Unknown location',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.add(marker);
      _currentAddress = address ?? 'Unknown location';
    });

    // Calculate distance from user location
    final distance = _mapsService.calculateDistance(_userLocation, location);
    print('Distance from your location: ${distance.toStringAsFixed(2)} meters');
  }

  void _centerOnUserLocation() async {
    final location = await _mapsService.getCurrentLocation();
    if (location != null) {
      await _mapsService.moveCameraToLocation(location);
      setState(() => _userLocation = location);
    }
  }

  void _showAddMarkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Marker'),
        content: const Text('Long press on the map to add a marker at that location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Map'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showAddMarkerDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapsService.setMapController(controller);
                  },
                  markers: _markers,
                  onLongPress: (LatLng location) {
                    _addDisasterMarker(location);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Location info card
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
