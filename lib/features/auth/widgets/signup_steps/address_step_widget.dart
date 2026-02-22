import 'package:flutter/material.dart';
import 'package:road_rescue/models/place_prediction.dart';
import 'package:road_rescue/models/workshop_location.dart';
import 'package:road_rescue/services/google_places_service.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'dart:async';

class AddressStepWidget extends StatefulWidget {
  final Function(WorkshopLocation) onContinue;

  const AddressStepWidget({super.key, required this.onContinue});

  @override
  State<AddressStepWidget> createState() => _AddressStepWidgetState();
}

class _AddressStepWidgetState extends State<AddressStepWidget> {
  final _addressController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();

  List<PlacePrediction> _predictions = [];
  WorkshopLocation? _selectedLocation;
  Timer? _debounceTimer;
  bool _isLoading = false;

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
      if (query.length > 2) {
        _fetchPredictions(query);
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() {
      _isLoading = true;
    });

    final predictions = await _placesService.getAutocompleteResults(query);

    if (mounted) {
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    }
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    setState(() {
      _isLoading = true;
    });

    final location = await _placesService.getPlaceDetails(prediction.placeId);

    if (location != null && mounted) {
      setState(() {
        _selectedLocation = location;
        _addressController.text = location.formattedAddress;
        _predictions = [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch location details')),
        );
      }
    }
  }

  void _onContinue() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address from suggestions'),
        ),
      );
      return;
    }
    widget.onContinue(_selectedLocation!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select workshop address?',
          style: Theme.of(context).textTheme.headlineMedium,
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
            onPressed: _selectedLocation != null ? _onContinue : null,
            text: 'Continue',
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
