import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/theme/app_colors.dart';

class TrackingView extends StatefulWidget {
  final ServiceRequest request;
  final LatLng? mechanicLocation;
  final String statusText;
  final VoidCallback? onCancel;
  final void Function(GoogleMapController) onMapCreated;

  // Payment Phase Properties
  final bool isPaymentPhase;
  final Future<void> Function()? onPay;

  const TrackingView({
    super.key,
    required this.request,
    required this.mechanicLocation,
    required this.statusText,
    this.onCancel,
    required this.onMapCreated,
    this.isPaymentPhase = false,
    this.onPay,
  });

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  QuotationTotalResponse? _quotationTotal;
  bool _isLoadingQuotation = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPaymentPhase) {
      _fetchQuotationTotal();
    }
  }

  Future<void> _fetchQuotationTotal() async {
    final quoteId = widget.request.quotation?.id;
    if (quoteId == null) return;

    setState(() => _isLoadingQuotation = true);

    final response = await DriverService.getQuotationTotal(quoteId);

    if (mounted) {
      setState(() {
        _quotationTotal = response;
        _isLoadingQuotation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverLoc = LatLng(widget.request.latitude, widget.request.longitude);
    final targetLoc =
        widget.mechanicLocation ??
        LatLng(
          widget.request.providerLatitude ?? widget.request.latitude,
          widget.request.providerLongitude ?? widget.request.longitude,
        );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: targetLoc, zoom: 14),
            markers: {
              Marker(
                markerId: const MarkerId('driver'),
                position: driverLoc,
                infoWindow: const InfoWindow(title: 'You'),
              ),
              if (widget.mechanicLocation != null)
                Marker(
                  markerId: const MarkerId('mechanic'),
                  position: widget.mechanicLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: InfoWindow(
                    title: widget.request.providerName ?? 'Unknown Mechanic',
                  ),
                ),
            },
            onMapCreated: widget.onMapCreated,
          ),
          // Top floating App Bar buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/driver'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
                // Cancel Pill Button
                if (widget.onCancel != null)
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.isPaymentPhase
                ? _buildPaymentBottomSheet(context)
                : _buildTrackingBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.statusText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.request.serviceType ?? 'Service Vehicle',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ON-DUTY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 16),
          _buildMechanicInfoRow(),
        ],
      ),
    );
  }

  Widget _buildPaymentBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingQuotation
                          ? '...'
                          : '\$${_quotationTotal?.totalAmount.toStringAsFixed(2) ?? widget.request.quotation?.totalAmount.toStringAsFixed(2) ?? "0.00"}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.request.serviceType ?? 'Service',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Truncated ID pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${widget.request.id.substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.request.location,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 16),
          _buildMechanicInfoRow(isPayment: true),
          const SizedBox(height: 24),
          // Make Payment Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLoadingQuotation || widget.onPay == null)
                  ? null
                  : widget.onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Make Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicInfoRow({bool isPayment = false}) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              child: Text(
                (widget.request.providerName ?? 'M')[0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.request.providerName ?? 'Mechanic',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (widget.request.providerPhone != null)
                Text(
                  widget.request.providerPhone!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        if (!isPayment)
          Column(
            children: [
              InkWell(
                onTap: () {
                  // TODO: implement call
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
