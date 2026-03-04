import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/models/quotation.dart';

class ServiceRequest {
  final String id;
  final RequestStatus status;
  final String description;
  final String location;
  final double latitude;
  final double longitude;

  final String driverName;
  final String? driverPhone;
  final String? providerName;
  final String? providerPhone;

  final double? providerLatitude;
  final double? providerLongitude;
  final double? distanceKm;

  final Quotation? quotation;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceRequest({
    required this.id,
    required this.status,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.driverName,
    this.driverPhone,
    this.providerName,
    this.providerPhone,
    this.providerLatitude,
    this.providerLongitude,
    this.distanceKm,
    this.quotation,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: RequestStatus.fromString(json['status']?.toString() ?? 'PENDING'),
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      driverName: json['driverName']?.toString() ?? 'Unknown Driver',
      driverPhone: json['driverPhone']?.toString(),
      providerName: json['providerName']?.toString(),
      providerPhone: json['providerPhone']?.toString(),
      providerLatitude: _parseDoubleNullable(json['providerLatitude']) ?? _parseDoubleNullable(json['mechanicLatitude']),
      providerLongitude: _parseDoubleNullable(json['providerLongitude']) ?? _parseDoubleNullable(json['mechanicLongitude']),
      distanceKm: _parseDoubleNullable(json['distanceKm']),
      quotation: json['quotation'] != null ? Quotation.fromJson(json['quotation']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'])?.toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'])?.toLocal() : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  ServiceRequest copyWith({
    String? id,
    RequestStatus? status,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? driverName,
    String? driverPhone,
    String? providerName,
    String? providerPhone,
    double? providerLatitude,
    double? providerLongitude,
    double? distanceKm,
    Quotation? quotation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      status: status ?? this.status,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerLatitude: providerLatitude ?? this.providerLatitude,
      providerLongitude: providerLongitude ?? this.providerLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      quotation: quotation ?? this.quotation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
