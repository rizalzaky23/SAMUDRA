class EarthquakeModel {
  final String id;
  final String bmkgRefId;
  final String magnitude;
  final String depthKm;
  final String latitude;
  final String longitude;
  final String region;
  final bool potentialTsunami;
  final String occurredAt;

  EarthquakeModel({
    required this.id,
    required this.bmkgRefId,
    required this.magnitude,
    required this.depthKm,
    required this.latitude,
    required this.longitude,
    required this.region,
    required this.potentialTsunami,
    required this.occurredAt,
  });

  factory EarthquakeModel.fromJson(Map<String, dynamic> json) {
    return EarthquakeModel(
      id: json['id'],
      bmkgRefId: json['bmkgRefId'],
      magnitude: json['magnitude'],
      depthKm: json['depthKm'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      region: json['region'],
      potentialTsunami: json['potentialTsunami'] ?? false,
      occurredAt: json['occurredAt'],
    );
  }
}
