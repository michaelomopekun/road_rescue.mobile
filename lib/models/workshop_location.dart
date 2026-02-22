class WorkshopLocation {
  final String formattedAddress;
  final String placeId;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  WorkshopLocation({
    required this.formattedAddress,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
  });

  @override
  String toString() =>
      'WorkshopLocation(address: $formattedAddress, lat: $latitude, lng: $longitude)';
}
