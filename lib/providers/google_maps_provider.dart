import 'package:flutter/material.dart';
import '../services/google_maps_service.dart';
import '../services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps Provider for managing map state across the app
class GoogleMapsProvider extends ChangeNotifier {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  Set<Marker> get markers => _markers;
  LatLng? get currentLocation => _currentLocation;
  String? get error => _error;
  GoogleMapsService get mapsService => _mapsService;

  /// Initialize map with current location
  Future<void> initializeMap() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = await _mapsService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        _addUserMarker(location);
      }
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Add user marker
  void _addUserMarker(LatLng location) {
    final marker = _mapsService.createMarker(
      markerId: 'user_location',
      position: location,
      title: 'My Location',
      infoWindow: 'You are here',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    _markers.add(marker);
  }

  /// Add marker at location
  Future<void> addMarkerAtLocation({
    required String markerId,
    required LatLng location,
    required String title,
    String? infoWindow,
    BitmapDescriptor? icon,
  }) async {
    try {
      final address = await _locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      final marker = _mapsService.createMarker(
        markerId: markerId,
        position: location,
        title: title,
        infoWindow: infoWindow ?? address ?? '',
        icon: icon ?? BitmapDescriptor.defaultMarker,
      );

      _markers.add(marker);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Remove marker
  void removeMarker(String markerId) {
    _markers.removeWhere((m) => m.markerId.value == markerId);
    notifyListeners();
  }

  /// Clear all markers except user location
  void clearMarkersExceptUser() {
    _markers.removeWhere((m) => m.markerId.value != 'user_location');
    notifyListeners();
  }

  /// Clear all markers
  void clearAllMarkers() {
    _markers.clear();
    notifyListeners();
  }

  /// Calculate distance to a location
  double? getDistanceToLocation(LatLng location) {
    if (_currentLocation == null) return null;
    return _mapsService.calculateDistance(_currentLocation!, location);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }
}
