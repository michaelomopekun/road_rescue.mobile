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
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>?;

    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      mainText: structuredFormatting?['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting?['secondary_text'],
      description: json['description'] ?? '',
    );
  }
}
