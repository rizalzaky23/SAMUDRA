import 'package:latlong2/latlong.dart';

class SafePointModel {
  final String id;
  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String icon;
  final int? capacity;
  final String? authorId;
  final DateTime? createdAt;

  const SafePointModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.icon = '⛺',
    this.capacity,
    this.authorId,
    this.createdAt,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory SafePointModel.fromJson(Map<String, dynamic> json) {
    return SafePointModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Titik Aman',
      subtitle: json['subtitle']?.toString() ?? 'Zona evakuasi aman',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      icon: json['icon']?.toString() ?? '⛺',
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) : null,
      authorId: json['authorId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'subtitle': subtitle,
        'latitude': latitude,
        'longitude': longitude,
        'icon': icon,
        if (capacity != null) 'capacity': capacity,
      };
}
