class FamilyContact {
  final String id;
  final String name;
  final String relationship;
  final String phone;

  const FamilyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'K';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'K';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  FamilyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
  }) {
    return FamilyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
      };

  factory FamilyContact.fromJson(Map<String, dynamic> json) => FamilyContact(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        relationship: json['relationship']?.toString() ?? 'Keluarga',
        phone: json['phone']?.toString() ?? '',
      );
}

