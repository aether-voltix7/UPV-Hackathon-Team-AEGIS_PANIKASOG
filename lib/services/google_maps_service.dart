import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class GoogleMapsService {
  late GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  GoogleMapController? get mapController => _mapController;

  // Initialize map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // Get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Move camera to location
  Future<void> moveCameraToLocation(LatLng location) async {
    if (_mapController == null) return;
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  // Get location from address
  Future<LatLng?> getLocationFromAddress(String address) async {
    try {
      final location = await _locationService.getCoordinatesFromAddress(address);
      if (location != null) {
        return LatLng(location['latitude'] ?? 0, location['longitude'] ?? 0);
      }
      return null;
    } catch (e) {
      print('Error getting location from address: $e');
      return null;
    }
  }

  // Get address from location
  Future<String?> getAddressFromLocation(LatLng location) async {
    try {
      final address = await _locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      return address;
    } catch (e) {
      print('Error getting address from location: $e');
      return null;
    }
  }

  // Create marker
  Marker createMarker({
    required String markerId,
    required LatLng position,
    required String title,
    String? infoWindow,
    BitmapDescriptor? icon,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: infoWindow,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
    );
  }

  // Calculate distance between two locations
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  // Dispose map controller
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
  }
}
