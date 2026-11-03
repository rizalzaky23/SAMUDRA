class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'tsunami_alert', 'nearby_earthquake', 'earthquake', 'new_article', 'broadcast', 'info'
  final DateTime sentAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? earthquake;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'info',
    required this.sentAt,
    this.isRead = false,
    this.data,
    this.earthquake,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? sentAt,
    bool? isRead,
    Map<String, dynamic>? data,
    Map<String, dynamic>? earthquake,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      earthquake: earthquake ?? this.earthquake,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['sentAt'] != null) {
      parsedDate = DateTime.tryParse(json['sentAt'].toString())?.toLocal() ?? DateTime.now();
    } else if (json['timestamp'] != null) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] is int ? json['timestamp'] : int.tryParse(json['timestamp'].toString()) ?? DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      parsedDate = DateTime.now();
    }

    // Ekstrak title dan body jika disimpan dalam bentuk message (backward compatibility)
    String rawTitle = json['title'] ?? '';
    String rawBody = json['body'] ?? '';
    if (rawTitle.isEmpty && json['message'] != null) {
      final msg = json['message'].toString();
      if (msg.contains(': ')) {
        final split = msg.split(': ');
        rawTitle = split[0];
        rawBody = split.sublist(1).join(': ');
      } else {
        rawTitle = 'Notifikasi SAMUDRA';
        rawBody = msg;
      }
    }

    return NotificationModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: rawTitle.isNotEmpty ? rawTitle : 'Peringatan SAMUDRA',
      body: rawBody.isNotEmpty ? rawBody : 'Pemberitahuan informasi kebencanaan',
      type: json['type']?.toString() ?? 'info',
      sentAt: parsedDate,
      isRead: json['isRead'] == true,
      data: json['payloadData'] != null && json['payloadData'] is Map<String, dynamic>
          ? json['payloadData']
          : (json['data'] is Map<String, dynamic> ? json['data'] : null),
      earthquake: json['earthquake'] is Map<String, dynamic> ? json['earthquake'] : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
        'earthquake': earthquake,
      };

  bool get isTsunami =>
      type == 'tsunami_alert' ||
      title.toLowerCase().contains('tsunami') ||
      body.toLowerCase().contains('tsunami');

  bool get isEarthquake =>
      type == 'earthquake' ||
      type == 'nearby_earthquake' ||
      title.toLowerCase().contains('gempa') ||
      body.toLowerCase().contains('gempa');

  bool get isArticle =>
      type == 'new_article' ||
      type == 'articles' ||
      title.toLowerCase().contains('artikel');
}

