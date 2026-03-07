import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String durationText;
  final String distanceText;
  final int durationSeconds;
  final int distanceMeters;

  DirectionsResult({
    required this.polylinePoints,
    required this.durationText,
    required this.distanceText,
    required this.durationSeconds,
    required this.distanceMeters,
  });
}

class DirectionsService {
  // Using the API key from .env
  static const String _apiKey = 'AIzaSyCYo01IGZe8SzUgMO3sswjv9W9lCsEbMQE';

  /// Fetch route directions from origin to destination
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_apiKey',
    );

    try {
      print('[DirectionsService] Fetching: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        print('[DirectionsService] HTTP error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || (data['routes'] as List).isEmpty) {
        print('[DirectionsService] API error: ${data['status']}');
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      // Decode the overview polyline
      final encodedPolyline = route['overview_polyline']['points'] as String;
      final points = _decodePolyline(encodedPolyline);

      return DirectionsResult(
        polylinePoints: points,
        durationText: leg['duration']['text'] as String,
        distanceText: leg['distance']['text'] as String,
        durationSeconds: leg['duration']['value'] as int,
        distanceMeters: leg['distance']['value'] as int,
      );
    } catch (e) {
      print('[DirectionsService] Error fetching directions: $e');
      return null;
    }
  }

  /// Decode Google's encoded polyline string into a list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
