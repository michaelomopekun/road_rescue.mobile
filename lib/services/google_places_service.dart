import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:road_rescue/models/place_prediction.dart';
import 'package:road_rescue/models/workshop_location.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey =
      'AIzaSyAjWGVIGUe2l5IJkeEVQsunsmJjanHUT7o'; // Add your API key here
  static const String _country = 'ng'; // Restrict to Nigeria

  final String _sessionToken = const Uuid().v4();

  /// Fetch autocomplete predictions
  Future<List<PlacePrediction>> getAutocompleteResults(String input) async {
    if (input.isEmpty) return [];

    try {
      final String url =
          '$_baseUrl/autocomplete/json?input=$input&key=$_apiKey&components=country:$_country&types=establishment|address&sessiontoken=$_sessionToken&language=en';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final predictions = json['predictions'] as List;

        return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
      } else {
        throw Exception('Failed to fetch autocomplete results');
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

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
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
