import 'package:flutter/material.dart';
import 'package:road_rescue/models/place_prediction.dart';
import 'package:road_rescue/models/workshop_location.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'dart:async';

import 'package:road_rescue/theme/app_theme.dart';

class AddressStepWidget extends StatefulWidget {
  final Function(WorkshopLocation) onContinue;

  const AddressStepWidget({super.key, required this.onContinue});

  @override
  State<AddressStepWidget> createState() => _AddressStepWidgetState();
}

class _AddressStepWidgetState extends State<AddressStepWidget> {
  final _addressController = TextEditingController();

  List<PlacePrediction> _predictions = [];
  WorkshopLocation? _selectedLocation;
  Timer? _debounceTimer;
  bool _isLoading = false;

  // Mock suggestions data
  static const List<Map<String, String>> _mockSuggestions = [
    {
      'placeId': 'mock_1',
      'mainText': 'Bremerton Children\'s Centre',
      'secondaryText': 'Coatbridge House, Camoustie Dr, London, N1 0DX',
      'formattedAddress':
          'Bremerton Children\'s Centre, Coatbridge House, Camoustie Dr, London, N1 0DX',
      'city': 'London',
      'state': 'Greater London',
      'country': 'United Kingdom',
      'latitude': '51.5302',
      'longitude': '-0.1246',
    },
    {
      'placeId': 'mock_2',
      'mainText': 'Jean Stokes Community Centre',
      'secondaryText': 'Coatbridge House, Camoustie Dr, London, N1 0DX',
      'formattedAddress':
          'Jean Stokes Community Centre, Coatbridge House, Camoustie Dr, London, N1 0DX',
      'city': 'London',
      'state': 'Greater London',
      'country': 'United Kingdom',
      'latitude': '51.5305',
      'longitude': '-0.1248',
    },
    {
      'placeId': 'mock_3',
      'mainText': 'Flat 1, Coatbridge House',
      'secondaryText': 'Camoustie Dr, London, N1 0DX',
      'formattedAddress':
          'Flat 1, Coatbridge House, Camoustie Dr, London, N1 0DX',
      'city': 'London',
      'state': 'Greater London',
      'country': 'United Kingdom',
      'latitude': '51.5308',
      'longitude': '-0.1250',
    },
    {
      'placeId': 'mock_4',
      'mainText': 'City Central Garage',
      'secondaryText': 'Market Street, London, N1 9AB',
      'formattedAddress':
          'City Central Garage, 45 Market Street, London, N1 9AB',
      'city': 'London',
      'state': 'Greater London',
      'country': 'United Kingdom',
      'latitude': '51.5315',
      'longitude': '-0.1260',
    },
    {
      'placeId': 'mock_5',
      'mainText': 'North London Auto Services',
      'secondaryText': 'High Road, London, N15 4QT',
      'formattedAddress':
          'North London Auto Services, 123 High Road, London, N15 4QT',
      'city': 'London',
      'state': 'Greater London',
      'country': 'United Kingdom',
      'latitude': '51.6100',
      'longitude': '-0.1050',
    },
  ];

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.removeListener(_onSearchChanged);
    _addressController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    print('🎯 TextField changed: "${_addressController.text}"');

    // Clear selected location if user edits the field
    if (_selectedLocation != null) {
      setState(() {
        _selectedLocation = null;
      });
    }

    // Debounce API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final query = _addressController.text.trim();
      print('⏱️ Debounce fired with query: "$query" (length: ${query.length})');

      if (query.length > 2) {
        _fetchMockPredictions(query);
      } else {
        print('❌ Query too short, clearing predictions');
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  void _fetchMockPredictions(String query) {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 300), () {
      print('🔍 Searching for: $query');
      print('📋 Total mock suggestions: ${_mockSuggestions.length}');

      final filteredSuggestions = _mockSuggestions.where((suggestion) {
        final mainText = suggestion['mainText']!.toLowerCase();
        final secondaryText = suggestion['secondaryText']!.toLowerCase();
        final queryLower = query.toLowerCase();

        final matches =
            mainText.contains(queryLower) || secondaryText.contains(queryLower);

        print('  ✓ ${suggestion['mainText']} - Matches: $matches');
        return matches;
      }).toList();

      print('✅ Filtered results: ${filteredSuggestions.length}');

      if (mounted) {
        setState(() {
          _predictions = filteredSuggestions
              .map(
                (s) => PlacePrediction(
                  placeId: s['placeId']!,
                  mainText: s['mainText']!,
                  secondaryText: s['secondaryText'],
                  description: s['formattedAddress']!,
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    });
  }

  void _onPredictionSelected(PlacePrediction prediction) {
    print('🎯 Prediction selected: "${prediction.mainText}"');

    final mockData = _mockSuggestions.firstWhere(
      (s) => s['placeId'] == prediction.placeId,
      orElse: () => _mockSuggestions.first,
    );

    final location = WorkshopLocation(
      formattedAddress: mockData['formattedAddress']!,
      placeId: mockData['placeId']!,
      latitude: double.parse(mockData['latitude']!),
      longitude: double.parse(mockData['longitude']!),
      city: mockData['city']!,
      state: mockData['state']!,
      country: mockData['country']!,
    );

    print('✅ Location set: ${location.formattedAddress}');

    setState(() {
      _selectedLocation = location;
      _predictions = [];
      // Don't set _addressController.text here - let the green indicator show instead
    });
  }

  void _onContinue() {
    if (_selectedLocation == null) {
      ToastService.showError(
        context,
        'Please select an address from suggestions',
      );
      return;
    }
    print('✅ Address selected, navigating to next step');
    print('📍 Location: ${_selectedLocation!.formattedAddress}');
    widget.onContinue(_selectedLocation!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select workshop address?',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 32),

        // Search TextField
        CustomTextField(
          controller: _addressController,
          hintText: 'enter your address here',
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_on),
        ),
        const SizedBox(height: 16),

        // Predictions List
        if (_predictions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return _PredictionTile(
                  mainText: prediction.mainText,
                  secondaryText: prediction.secondaryText,
                  onTap: () => _onPredictionSelected(prediction),
                );
              },
            ),
          ),

        // Selected Location Indicator
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedLocation!.formattedAddress,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.green[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Continue Button (enabled only when location is selected)
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Continue',
            text: 'Continue',
            onPressed: _selectedLocation != null ? _onContinue : null,
          ),
        ),
      ],
    );
  }
}

class _PredictionTile extends StatelessWidget {
  final String mainText;
  final String? secondaryText;
  final VoidCallback onTap;

  const _PredictionTile({
    required this.mainText,
    this.secondaryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (secondaryText != null) ...[
                const SizedBox(height: 4),
                Text(
                  secondaryText!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:road_rescue/models/place_prediction.dart';
// import 'package:road_rescue/models/workshop_location.dart';
// import 'package:road_rescue/services/google_places_service.dart';
// import 'package:road_rescue/shared/widgets/custom_text_field.dart';
// import 'package:road_rescue/shared/widgets/primary_button.dart';
// import 'dart:async';

// class AddressStepWidget extends StatefulWidget {
//   final Function(WorkshopLocation) onContinue;

//   const AddressStepWidget({super.key, required this.onContinue});

//   @override
//   State<AddressStepWidget> createState() => _AddressStepWidgetState();
// }

// class _AddressStepWidgetState extends State<AddressStepWidget> {
//   final _addressController = TextEditingController();
//   final GooglePlacesService _placesService = GooglePlacesService();

//   List<PlacePrediction> _predictions = [];
//   WorkshopLocation? _selectedLocation;
//   Timer? _debounceTimer;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _addressController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _addressController.removeListener(_onSearchChanged);
//     _addressController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     // Clear selected location if user edits the field
//     if (_selectedLocation != null) {
//       setState(() {
//         _selectedLocation = null;
//       });
//     }

//     // Debounce API calls
//     _debounceTimer?.cancel();
//     _debounceTimer = Timer(const Duration(milliseconds: 400), () {
//       final query = _addressController.text.trim();
//       if (query.length > 2) {
//         _fetchPredictions(query);
//       } else {
//         setState(() {
//           _predictions = [];
//         });
//       }
//     });
//   }

//   Future<void> _fetchPredictions(String query) async {
//     setState(() {
//       _isLoading = true;
//     });

//     final predictions = await _placesService.getAutocompleteResults(query);

//     if (mounted) {
//       setState(() {
//         _predictions = predictions;
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _onPredictionSelected(PlacePrediction prediction) async {
//     setState(() {
//       _isLoading = true;
//     });

//     final location = await _placesService.getPlaceDetails(prediction.placeId);

//     if (location != null && mounted) {
//       setState(() {
//         _selectedLocation = location;
//         _addressController.text = location.formattedAddress;
//         _predictions = [];
//         _isLoading = false;
//       });
//     } else {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to fetch location details')),
//         );
//       }
//     }
//   }

//   void _onContinue() {
//     if (_selectedLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select an address from suggestions'),
//         ),
//       );
//       return;
//     }
//     widget.onContinue(_selectedLocation!);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select workshop address?',
//           style: Theme.of(context).textTheme.headlineMedium,
//         ),
//         const SizedBox(height: 32),

//         // Search TextField
//         CustomTextField(
//           controller: _addressController,
//           hintText: 'enter your address here',
//           suffixIcon: _isLoading
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : const Icon(Icons.location_on),
//         ),
//         const SizedBox(height: 16),

//         // Predictions List
//         if (_predictions.isNotEmpty)
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey[300]!),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             constraints: const BoxConstraints(maxHeight: 300),
//             child: ListView.separated(
//               shrinkWrap: true,
//               itemCount: _predictions.length,
//               separatorBuilder: (_, __) =>
//                   Divider(height: 1, color: Colors.grey[300]),
//               itemBuilder: (context, index) {
//                 final prediction = _predictions[index];
//                 return _PredictionTile(
//                   mainText: prediction.mainText,
//                   secondaryText: prediction.secondaryText,
//                   onTap: () => _onPredictionSelected(prediction),
//                 );
//               },
//             ),
//           ),

//         // Selected Location Indicator
//         if (_selectedLocation != null) ...[
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               border: Border.all(color: Colors.green[200]!),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.green[600], size: 20),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _selectedLocation!.formattedAddress,
//                     style: Theme.of(
//                       context,
//                     ).textTheme.bodySmall?.copyWith(color: Colors.green[700]),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],

//         const SizedBox(height: 32),

//         // Continue Button (enabled only when location is selected)
//         SizedBox(
//           width: double.infinity,
//           child: PrimaryButton(
//             label: 'Continue',
//             onPressed: _selectedLocation != null ? _onContinue : null,
//             text: 'Continue',
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _PredictionTile extends StatelessWidget {
//   final String mainText;
//   final String? secondaryText;
//   final VoidCallback onTap;

//   const _PredictionTile({
//     required this.mainText,
//     this.secondaryText,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 mainText,
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
//               ),
//               if (secondaryText != null) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   secondaryText!,
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
