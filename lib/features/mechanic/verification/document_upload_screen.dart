import 'package:flutter/material.dart';
import 'package:road_rescue/models/workshop_location.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:file_picker/file_picker.dart';

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
  final List<String> _documentTypes = ['RC', 'Certification', 'ID'];
  int _currentDocumentIndex = 0;
  final Map<String, (String fileName, List<int> bytes)?> _uploadedDocuments =
      {};
  bool _isUploading = false;
  String? _serviceProviderId;

  @override
  void initState() {
    super.initState();
    _initializeDocumentTypes();
  }

  void _initializeDocumentTypes() {
    for (var docType in _documentTypes) {
      _uploadedDocuments[docType] = null;
    }
  }

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: File is empty or invalid')),
            );
          }
          return;
        }

        // Validate minimum file size (at least 1KB)
        if (fileSize < 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'File is too small. Please select a valid document.',
                ),
              ),
            );
          }
          return;
        }

        setState(() {
          _uploadedDocuments[_documentTypes[_currentDocumentIndex]] = (
            fileName,
            fileBytes,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File selected: $fileName (${(fileSize / 1024).toStringAsFixed(2)} KB)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _submitVerification() async {
    // Check if all documents are uploaded
    for (var docType in _documentTypes) {
      final doc = _uploadedDocuments[docType];
      if (doc == null || doc.$2.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload $docType document')),
        );
        return;
      }
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

      // Step 2: Upload all documents
      for (var docType in _documentTypes) {
        final uploadedDoc = _uploadedDocuments[docType];
        if (uploadedDoc != null && uploadedDoc.$2.isNotEmpty) {
          final (fileName, fileBytes) = uploadedDoc;

          // Log for debugging
          print('Uploading $docType: $fileName (${fileBytes.length} bytes)');

          await AuthService.uploadVerificationDocument(
            serviceProviderId: _serviceProviderId!,
            documentType: docType,
            documentNumber:
                'DOC_${docType}_${DateTime.now().millisecondsSinceEpoch}',
            fileBytes: fileBytes,
            fileName: fileName,
          );
        }
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation Error: ${e.toString()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _goToNextDocument() {
    if (_currentDocumentIndex < _documentTypes.length - 1) {
      setState(() {
        _currentDocumentIndex++;
      });
    } else {
      // All documents collected, submit
      _submitVerification();
    }
  }

  String get _currentDocumentType => _documentTypes[_currentDocumentIndex];

  bool get _isCurrentDocumentUploaded =>
      _uploadedDocuments[_currentDocumentType] != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey[700]),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _documentTypes.length,
                  (index) => Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentDocumentIndex
                              ? Colors.teal[700]
                              : Colors.grey[300],
                        ),
                      ),
                      if (index < _documentTypes.length - 1)
                        Container(
                          width: 30,
                          height: 2,
                          color: index < _currentDocumentIndex
                              ? Colors.teal[700]
                              : Colors.grey[300],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Document Type Label
            Text(
              _currentDocumentType,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a photo or scan of your ${_currentDocumentType.toLowerCase()}.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Choose Different Document Link
            GestureDetector(
              onTap: _pickFile,
              child: Text(
                'Choose a different document',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Area
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCurrentDocumentUploaded)
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
                            _uploadedDocuments[_currentDocumentType]!.$1,
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
                            'Upload the front side of\nyour document',
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
            const SizedBox(height: 40),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: _currentDocumentIndex == _documentTypes.length - 1
                    ? 'Submit'
                    : 'Continue',
                text: _currentDocumentIndex == _documentTypes.length - 1
                    ? 'Submit'
                    : 'Continue',
                onPressed: _isUploading || !_isCurrentDocumentUploaded
                    ? null
                    : _goToNextDocument,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
