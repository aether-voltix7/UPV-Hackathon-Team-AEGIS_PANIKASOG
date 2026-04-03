import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationService {

  // Request location permissions
  Future<LocationPermission> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    // Check if location service is enabled
    final isServiceEnabled = await isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Location service is disabled');
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }

  // Get position updates (stream)
  Stream<Position> getPositionStream({
    int distanceFilter = 10, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        distanceFilter: distanceFilter > 0 ? distanceFilter : 0,
      ),
    );
  }

  // Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await geocoding.locationFromAddress(address);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  // Get place info from coordinates
  Future<Map<String, dynamic>?> getPlaceInfoFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      return {
        'street': placemark.street,
        'locality': placemark.locality,
        'administrativeArea': placemark.administrativeArea,
        'postalCode': placemark.postalCode,
        'country': placemark.country,
        'isoCountryCode': placemark.isoCountryCode,
        'name': placemark.name,
      };
    } catch (e) {
      print('Error getting place info: $e');
      return null;
    }
  }

  // Get distance between two coordinates
  double getDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }
}
