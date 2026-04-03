
# 🚀 Google APIs Implementation Guide for PANIKASOG

This guide covers the complete setup and integration of Google APIs in your Flutter app.

## ✅ Completed Setup

### 1. **Packages Added**
- ✅ `google_maps_flutter: ^2.12.0` - Google Maps
- ✅ `google_sign_in: ^6.3.0` - Google Sign-In (already had)
- ✅ `geolocator: ^14.0.2` - Location services
- ✅ `geocoding: ^4.0.0` - Address geocoding
- ✅ `permission_handler: ^11.4.4` - Permission handling

### 2. **Services Created**
- ✅ `location_service.dart` - Geolocation and geocoding
- ✅ `google_maps_service.dart` - Google Maps functionality
- ✅ `google_sign_in_service.dart` - Google Sign-In wrapper
- ✅ `google_places_service.dart` - Places query support

### 3. **Android Configuration Updated**
- ✅ Google Maps API Key configured in AndroidManifest.xml
- ✅ Location permissions added
- ✅ Camera permission added
- ✅ Google Play Services queries added

---

## 🔧 Configuration Steps

### Step 1: Add Google Maps API Key
**Already configured in AndroidManifest.xml:**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR-API-KEY-HERE"/>
```

### Step 2: Install Dependencies
Run in terminal:
```bash
flutter pub get
```

### Step 3: iOS Configuration (if needed)
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to provide disaster response services.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location for emergency response coordination.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location for emergency response.</string>
```

### Step 4: Android Permissions (Already configured)
AndroidManifest.xml includes:
- `INTERNET` - For API calls
- `ACCESS_FINE_LOCATION` - Precise location
- `ACCESS_COARSE_LOCATION` - Approximate location
- `CAMERA` - For image capture
- `READ/WRITE_EXTERNAL_STORAGE` - For media

---

## 📱 Usage Examples

### 1. **Using Location Service**

```dart
import 'package:panikasog/services/location_service.dart';

final locationService = LocationService();

// Get current position
final position = await locationService.getCurrentPosition();
print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

// Get address from coordinates
final address = await locationService.getAddressFromCoordinates(
  14.5995, // latitude
  120.9842, // longitude
);
print('Address: $address');

// Listen to position updates
locationService.getPositionStream().listen((position) {
  print('Updated location: ${position.latitude}, ${position.longitude}');
});
```

### 2. **Using Google Maps Service**

```dart
import 'package:panikasog/services/google_maps_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final mapsService = GoogleMapsService();

// In your GoogleMap widget:
GoogleMap(
  initialCameraPosition: const CameraPosition(
    target: LatLng(14.5995, 120.9842), // Manila, PH
    zoom: 15,
  ),
  onMapCreated: (controller) {
    mapsService.setMapController(controller);
  },
)

// Get current location and move camera
final userLocation = await mapsService.getCurrentLocation();
if (userLocation != null) {
  await mapsService.moveCameraToLocation(userLocation);
}

// Create markers
final marker = mapsService.createMarker(
  markerId: 'disaster_1',
  position: const LatLng(14.5995, 120.9842),
  title: 'Disaster Location',
  infoWindow: 'Typhoon affected area',
);

// Calculate distance between locations
final distance = mapsService.calculateDistance(
  const LatLng(14.5995, 120.9842),
  const LatLng(14.6091, 120.9824),
);
print('Distance: ${distance}m');
```

### 3. **Using Google Sign-In Service**

```dart
import 'package:panikasog/services/google_sign_in_service.dart';

final googleSignInService = GoogleSignInService();

// Sign in with Google
final userCredential = await googleSignInService.signIn();
if (userCredential != null) {
  User firebaseUser = userCredential.user!;
  print('Logged in: ${firebaseUser.email}');
}

// Check if already signed in
final isSignedIn = await googleSignInService.isSignedIn();

// Get user profile
final profile = await googleSignInService.getUserProfile();
if (profile != null) {
  print('Name: ${profile['displayName']}');
  print('Email: ${profile['email']}');
}

// Sign out
await googleSignInService.signOut();
```

### 4. **Using Google Places Service**

```dart
import 'package:panikasog/services/google_places_service.dart';

final placesService = GooglePlacesService();

// Get place predictions for autocomplete
final predictions = await placesService.getPlacePredictions('Manila Hospital');
for (var prediction in predictions) {
  print('${prediction.mainText} - ${prediction.secondaryText}');
}

// Search nearby places
final nearbyPlaces = await placesService.searchNearbyPlaces(
  latitude: 14.5995,
  longitude: 120.9842,
  type: 'hospital', // or 'police', 'shelter', etc.
  radiusInMeters: 5000, // 5km radius
);
```

---

## 🔐 Permissions Handling

### Request Permissions at Runtime

```dart
import 'package:permission_handler/permission_handler.dart';

// Request location permission
PermissionStatus status = await Permission.location.request();

if (status.isDenied) {
  print('Location permission denied');
} else if (status.isPermanentlyDenied) {
  openAppSettings(); // Redirect user to app settings
}

// Request camera permission
PermissionStatus cameraStatus = await Permission.camera.request();

// Request storage permission
PermissionStatus storageStatus = await Permission.storage.request();
```

---

## 🗺️ Complete Google Maps Widget Example

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:panikasog/services/google_maps_service.dart';
import 'package:panikasog/services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final LocationService _locationService = LocationService();
  
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  LatLng _userLocation = const LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  void _loadUserLocation() async {
    try {
      final location = await _mapsService.getCurrentLocation();
      if (location != null) {
        setState(() => _userLocation = location);
        _mapsService.moveCameraToLocation(location);
      }
    } catch (e) {
      print('Error loading location: $e');
    }
  }

  void _addMarker(LatLng location) async {
    final address = await _mapsService.getAddressFromLocation(location);
    
    final marker = _mapsService.createMarker(
      markerId: '${DateTime.now().millisecondsSinceEpoch}',
      position: location,
      title: 'Mark Location',
      infoWindow: address ?? 'Unknown location',
    );

    setState(() => _markers.add(marker));
  }

  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _userLocation,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _mapsService.setMapController(controller);
          _controller = controller;
        },
        markers: _markers,
        onLongPress: _addMarker,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
```

---

## 🐛 Troubleshooting

### Issue: "Google Maps API key not working"
- ✅ Verify key is in `AndroidManifest.xml`
- ✅ Check API is enabled in Google Cloud Console
- ✅ Rebuild app: `flutter clean && flutter pub get && flutter run`

### Issue: "Location permission denied"
- ✅ App not requesting permissions at runtime
- ✅ User denied permission - add Settings option
- ✅ Check `android/app/src/main/AndroidManifest.xml` has permissions

### Issue: "com.google.android.gms.maps.NotYetImplementedError"
- ✅ Maps not initialized properly
- ✅ GoogleMapController not set before use
- ✅ Rebuild app in release mode

### Issue: "Geocoding returns empty results"
- ✅ Check internet connection
- ✅ Verify address format is correct
- ✅ Try with different location

---

## 📚 Next Steps

1. **Create Map Screen** - Use GoogleMapsWidget with markers
2. **Add Location Tracking** - Use `LocationService.getPositionStream()`
3. **Integrate with Reports** - Show disaster locations on map
4. **Add Nearby Search** - Find hospitals, shelters, police stations
5. **Enhance Auth** - Implement Google Sign-In button on landing screen

---

## 📞 API Resources

- [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Documentation](https://pub.dev/packages/geolocator)
- [Geocoding Documentation](https://pub.dev/packages/geocoding)
- [Permission Handler Documentation](https://pub.dev/packages/permission_handler)
- [Google Sign-In Documentation](https://pub.dev/packages/google_sign_in)

---

**All APIs are now ready to use! Start implementing features! 🎉**
