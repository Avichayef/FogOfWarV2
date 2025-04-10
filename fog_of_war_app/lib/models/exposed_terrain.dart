class ExposedTerrain {
  final int id;
  final int userId;
  final double latitude;
  final double longitude;

  ExposedTerrain({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  factory ExposedTerrain.fromMap(Map<String, dynamic> map) {
    return ExposedTerrain(
      id: map['id'],
      userId: map['user_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
