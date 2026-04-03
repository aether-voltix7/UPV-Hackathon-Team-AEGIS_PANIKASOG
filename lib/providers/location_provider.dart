import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Location Provider for managing location state across the app
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  LatLng? _currentLocation;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;
  bool _isLocationEnabled = false;
  LocationPermission? _locationPermission;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocationEnabled => _isLocationEnabled;
  LocationPermission? get locationPermission => _locationPermission;

  /// Initialize location services
  Future<void> initializeLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location service is enabled
      _isLocationEnabled = await _locationService.isLocationServiceEnabled();
      
      if (!_isLocationEnabled) {
        _error = 'Location service is disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check location permission
      _locationPermission = await _locationService.checkLocationPermission();

      if (_locationPermission == LocationPermission.denied) {
        _locationPermission = await _locationService.requestLocationPermission();
      }

      if (_locationPermission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      await updateCurrentLocation();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update current location
  Future<void> updateCurrentLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      final position = await _locationService.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Get address
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _currentAddress = address;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get location stream
  Stream<LatLng> getLocationStream() async* {
    try {
      await for (final position in _locationService.getPositionStream()) {
        final location = LatLng(position.latitude, position.longitude);
        _currentLocation = location;
        notifyListeners();
        yield location;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get address for a specific location
  Future<String?> getAddressForLocation(LatLng location) async {
    try {
      return await _locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  /// Get location for an address
  Future<LatLng?> getLocationForAddress(String address) async {
    try {
      final coordinates = await _locationService.getCoordinatesFromAddress(address);
      if (coordinates != null) {
        return LatLng(coordinates['latitude']!, coordinates['longitude']!);
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two locations
  double calculateDistance(LatLng from, LatLng to) {
    return _locationService.getDistance(
      startLatitude: from.latitude,
      startLongitude: from.longitude,
      endLatitude: to.latitude,
      endLongitude: to.longitude,
    );
  }

  /// Request location permission
  Future<void> requestLocationPermission() async {
    _locationPermission = await _locationService.requestLocationPermission();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
