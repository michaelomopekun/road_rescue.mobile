import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:road_rescue/models/place_prediction.dart';
import 'package:road_rescue/models/workshop_location.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  // Attempt to load from dotenv, default to empty string to avoid null error if not set
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _country = 'ng'; // Restrict to Nigeria

  final String _sessionToken = const Uuid().v4();

  /// Fetch autocomplete predictions
  Future<List<PlacePrediction>> getAutocompleteResults(String input) async {
    if (input.isEmpty) return [];

    try {
      // Removing the 'types' parameter to ensure it searches both addresses and places without error
      final requestUri = Uri.parse(
        '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:$_country&sessiontoken=$_sessionToken&language=en',
      );

      print('Google Places Autocomplete URL: $requestUri');

      final response = await http.get(requestUri);

      print(
        'Google Places Autocomplete Response Status: ${response.statusCode}',
      );
      // Only print first 200 chars of body to avoid flooding console on success, but full body on error
      if (response.statusCode != 200 ||
          !response.body.contains('"status" : "OK"')) {
        print('Google Places Autocomplete Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
          print(
            'Google Places API Error Status: ${json['status']}, Error Message: ${json['error_message']}',
          );
          return []; // Return empty so it doesn't crash
        }

        final predictions = (json['predictions'] as List?) ?? [];

        return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
      } else {
        throw Exception(
          'Failed to fetch autocomplete results. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching autocomplete: $e');
      return [];
    }
  }

  /// Fetch detailed place information
  Future<WorkshopLocation?> getPlaceDetails(String placeId) async {
    try {
      final String url =
          '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&fields=geometry,name,formatted_address,address_components&sessiontoken=$_sessionToken';

      print(
        'Google Places Details URL: $_baseUrl/details/json?place_id=$placeId&key=HIDDEN_KEY...',
      );
      final response = await http.get(Uri.parse(url));

      print('Google Places Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] != 'OK') {
          print(
            'Google Places Details API Error Status: ${json['status']}, Error Message: ${json['error_message']}',
          );
          return null;
        }

        final result = json['result'];

        if (result == null) return null;

        final geometry = result['geometry'];
        final location = geometry['location'];
        final addressComponents = result['address_components'] as List;

        // Extract city, state, country from address components
        String city = '';
        String state = '';
        String country = '';

        for (var component in addressComponents) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            city = component['long_name'] ?? '';
          }
          if (types.contains('administrative_area_level_1')) {
            state = component['long_name'] ?? '';
          }
          if (types.contains('country')) {
            country = component['long_name'] ?? '';
          }
        }

        return WorkshopLocation(
          formattedAddress: result['formatted_address'] ?? '',
          placeId: placeId,
          latitude: location['lat'] ?? 0.0,
          longitude: location['lng'] ?? 0.0,
          city: city,
          state: state,
          country: country,
        );
      } else {
        throw Exception('Failed to fetch place details');
      }
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }
}
