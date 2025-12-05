import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get the current location with proper permission handling
  /// Returns LocationResult on success, throws exception on failure
  Future<LocationResult> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    // Get the current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Open Google Maps with the given coordinates
  Future<bool> openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    
    // Fallback to geo: URI scheme
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    if (await canLaunchUrl(geoUrl)) {
      return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }
    
    return false;
  }

  /// Open app settings for the user to manually enable location permission
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Exception thrown when location services are disabled
class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled. Please enable them in your device settings.';
  
  @override
  String toString() => message;
}

/// Exception thrown when location permission is denied
class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission was denied. Please grant permission to share your location.';
  
  @override
  String toString() => message;
}

/// Exception thrown when location permission is permanently denied
class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message = 'Location permission is permanently denied. Please enable it in app settings.';
  
  @override
  String toString() => message;
}

