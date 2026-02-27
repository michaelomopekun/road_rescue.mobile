import 'package:flutter/material.dart';
import 'package:road_rescue/models/workshop_location.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/theme/app_theme.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String businessName;
  final WorkshopLocation workshopLocation;
  final String phoneNumber;

  const DocumentUploadScreen({
    super.key,
    required this.businessName,
    required this.workshopLocation,
    required this.phoneNumber,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<String> _documentTypes = ['RC', 'CERTIFICATION', 'ID'];
  String? _selectedDocumentType;
  (String fileName, List<int> bytes)? _uploadedDocument;
  bool _isUploading = false;
  String? _serviceProviderId;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        final fileName = file.name;
        final fileSize = file.size; // in bytes

        // Validate file is not empty
        if (fileBytes == null || fileBytes.isEmpty) {
          if (mounted) {
            ToastService.showError(context, 'Error: File is empty or invalid');
          }
          return;
        }

        // Validate minimum file size (at least 1KB)
        if (fileSize < 1024) {
          if (mounted) {
            ToastService.showError(
              context,
              'File is too small. Please select a valid document.',
            );
          }
          return;
        }

        setState(() {
          _uploadedDocument = (fileName, fileBytes);
        });

        if (mounted) {
          ToastService.showSuccess(
            context,
            'File selected: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _submitVerification() async {
    // Validate document type selected
    if (_selectedDocumentType == null) {
      if (mounted) {
        ToastService.showWarning(context, 'Please select a document type');
      }
      return;
    }

    // Validate document uploaded
    if (_uploadedDocument == null || _uploadedDocument!.$2.isEmpty) {
      if (mounted) {
        ToastService.showWarning(context, 'Please upload a document');
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = await TokenService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Step 1: Create provider profile
      final profileResponse = await AuthService.createProviderProfile(
        userId: userId,
        businessName: widget.businessName,
        businessPhone: widget.phoneNumber,
        businessAddress: widget.workshopLocation.formattedAddress,
        baseLatitude: widget.workshopLocation.latitude,
        baseLongitude: widget.workshopLocation.longitude,
      );

      _serviceProviderId = profileResponse.id;

      // Step 2: Upload the selected document
      final (fileName, fileBytes) = _uploadedDocument!;

      // Log for debugging
      print(
        'Uploading $_selectedDocumentType: $fileName (${fileBytes.length} bytes)',
      );

      await AuthService.uploadVerificationDocument(
        serviceProviderId: _serviceProviderId!,
        documentType: _selectedDocumentType!,
        documentNumber:
            'DOC_${_selectedDocumentType}_${DateTime.now().millisecondsSinceEpoch}',
        fileBytes: fileBytes,
        fileName: fileName,
      );

      // Step 3: Save provider ID and verification status
      await TokenService.saveProviderId(_serviceProviderId!);
      await TokenService.saveVerificationStatus('PENDING');

      // Step 4: Navigate to pending screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/verification-pending',
          arguments: {'serviceProviderId': _serviceProviderId},
        );
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Validation Error: ${e.toString()}');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),

            // Progress Indicator (Step 3/3)
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Title and Description
            Text(
              'Select a Document Type',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose one of the following documents to verify your account.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Document Type Selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _documentTypes.map((docType) {
                final isSelected = _selectedDocumentType == docType;
                return FilterChip(
                  label: Text(docType),
                  selected: isSelected,
                  onSelected: _uploadedDocument == null
                      ? (selected) {
                          setState(() {
                            _selectedDocumentType = selected ? docType : null;
                          });
                        }
                      : null, // Disable selection after upload
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.teal[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.teal[700] : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Upload Area (shown when document type selected)
            if (_selectedDocumentType != null) ...[
              Text(
                'Upload ${_selectedDocumentType!}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  height: 332,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondaryBorder,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadedDocument != null)
                        Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Document Uploaded',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _uploadedDocument!.$1,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.green[600]),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue[100],
                              ),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 32,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to upload your\n${_selectedDocumentType?.toLowerCase()}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a document type above to start.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Submit',
                text: 'Submit',
                onPressed:
                    _isUploading ||
                        _selectedDocumentType == null ||
                        _uploadedDocument == null
                    ? null
                    : _submitVerification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
