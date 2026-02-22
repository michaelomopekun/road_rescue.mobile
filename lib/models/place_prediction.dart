class PlacePrediction {
  final String placeId;
  final String mainText;
  final String? secondaryText;
  final String description;

  PlacePrediction({
    required this.placeId,
    required this.mainText,
    this.secondaryText,
    required this.description,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      mainText: json['main_text'] ?? json['description'] ?? '',
      secondaryText: json['secondary_text'],
      description: json['description'] ?? '',
    );
  }
}
