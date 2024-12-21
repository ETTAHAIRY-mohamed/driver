class DirectionDetails {
  int? distanceValue;
  int? durationValue;
  String? distanceText;
  String? durationText;
  String? encodedPoints;

  DirectionDetails({
    this.distanceValue,
    this.durationValue,
    this.distanceText,
    this.durationText,
    this.encodedPoints,
  });

  DirectionDetails.fromMap(Map<String, dynamic> map) {
    distanceValue = map['distance_value'];
    durationValue = map['duration_value'];
    distanceText = map['distance_text'];
    durationText = map['duration_text'];
    encodedPoints = map['encoded_points'];
  }
}
