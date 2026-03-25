import 'dart:async';
import 'package:flutter/material.dart';
import 'package:road_rescue/models/place_prediction.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/google_places_service.dart';

class EditWorkshopBottomSheet extends StatefulWidget {
  final ProviderProfile providerProfile;

  const EditWorkshopBottomSheet({
    super.key,
    required this.providerProfile,
  });

  @override
  State<EditWorkshopBottomSheet> createState() => _EditWorkshopBottomSheetState();
}

class _EditWorkshopBottomSheetState extends State<EditWorkshopBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();

  List<PlacePrediction> _predictions = [];
  Timer? _debounceTimer;
  bool _isLoadingAddress = false;
  final GooglePlacesService _placesService = GooglePlacesService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.providerProfile.businessName);
    _phoneController = TextEditingController(text: widget.providerProfile.businessPhone);
    _addressController = TextEditingController(text: widget.providerProfile.businessAddress);

    _addressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.removeListener(_onSearchChanged);
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final query = _addressController.text.trim();

      // Don't search if the query exactly matches the original text (to avoid searching right after opening)
      if (query == widget.providerProfile.businessAddress) {
        setState(() => _predictions = []);
        return;
      }

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
    setState(() => _isLoadingAddress = true);

    try {
      final predictions = await _placesService.getAutocompleteResults(query);
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  void _onPredictionSelected(PlacePrediction prediction) {
    setState(() {
      // Temporarily remove listener to avoid triggering another search
      _addressController.removeListener(_onSearchChanged);
      _addressController.text = prediction.description;
      _addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: _addressController.text.length),
      );
      _predictions = [];
      
      // Re-add listener
      _addressController.addListener(_onSearchChanged);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Workshop Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2A3B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Business Phone'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Business Address',
                suffixIcon: _isLoadingAddress
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            if (_predictions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      dense: true,
                      title: Text(prediction.mainText, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: prediction.secondaryText != null 
                          ? Text(prediction.secondaryText!, maxLines: 1, overflow: TextOverflow.ellipsis) 
                          : null,
                      onTap: () => _onPredictionSelected(prediction),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'businessName': _nameController.text.trim(),
                      'businessPhone': _phoneController.text.trim(),
                      'businessAddress': _addressController.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Details'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
