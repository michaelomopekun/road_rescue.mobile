import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });
}

class LocationService {
  static const Duration _locationUpdateInterval = Duration(seconds: 10);

  static StreamSubscription<Position>? _locationSubscription;
  static final _locationStreamController =
      StreamController<LocationData>.broadcast();

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        // Open settings
        await Geolocator.openLocationSettings();
        return false;
      }
      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  /// Get current location once
  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check permissions first
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  static Stream<LocationData> startLocationTracking() {
    _stopLocationTracking(); // Ensure no existing subscription

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Only update if moved 10 meters
            timeLimit: _locationUpdateInterval,
          ),
        ).listen(
          (position) {
            final locationData = LocationData(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                position.timestamp.millisecondsSinceEpoch,
              ),
            );
            _locationStreamController.add(locationData);
          },
          onError: (error) {
            print('Location tracking error: $error');
            _locationStreamController.addError(error);
          },
        );

    return _locationStreamController.stream;
  }

  /// Stop location tracking
  static void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Dispose all resources
  static void dispose() {
    _stopLocationTracking();
    _locationStreamController.close();
  }
}
