import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/models/quotation.dart';

class ServiceRequest {
  final String id;
  final RequestStatus status;
  final String? serviceType;
  final String description;
  final String location;
  final double latitude;
  final double longitude;

  final String? driverId;
  final String driverName;
  final String? driverPhone;
  final String? providerId;
  final String? providerName;
  final String? providerPhone;

  final double? providerLatitude;
  final double? providerLongitude;
  final double? distanceKm;

  final Quotation? quotation;

  final DateTime? assignedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceRequest({
    required this.id,
    required this.status,
    this.serviceType,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.driverId,
    required this.driverName,
    this.driverPhone,
    this.providerId,
    this.providerName,
    this.providerPhone,
    this.providerLatitude,
    this.providerLongitude,
    this.distanceKm,
    this.quotation,
    this.assignedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      status: RequestStatus.fromString(json['status']?.toString() ?? 'PENDING'),
      serviceType: json['serviceType']?.toString(),
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      driverId: json['driverId']?.toString(),
      driverName: json['driverName']?.toString() ?? 'Unknown Driver',
      driverPhone: json['driverPhone']?.toString(),
      providerId: json['providerId']?.toString(),
      providerName: json['providerName']?.toString(),
      providerPhone: json['providerPhone']?.toString(),
      providerLatitude: _parseDoubleNullable(json['providerLatitude']) ?? _parseDoubleNullable(json['mechanicLatitude']),
      providerLongitude: _parseDoubleNullable(json['providerLongitude']) ?? _parseDoubleNullable(json['mechanicLongitude']),
      distanceKm: _parseDoubleNullable(json['distanceKm']),
      quotation: json['quotation'] != null ? Quotation.fromJson(json['quotation']) : null,
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt'])?.toLocal() : null,
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
    String? serviceType,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? providerId,
    String? providerName,
    String? providerPhone,
    double? providerLatitude,
    double? providerLongitude,
    double? distanceKm,
    Quotation? quotation,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerLatitude: providerLatitude ?? this.providerLatitude,
      providerLongitude: providerLongitude ?? this.providerLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      quotation: quotation ?? this.quotation,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
