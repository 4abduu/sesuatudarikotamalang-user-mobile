enum NotificationType {
  order,
  review,
  system,
  creator,
  pengajuanDiterima,
  pengajuanDitolak,
  ulasanBaru,
  pesananUpdate,
  umum,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String date;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    final typeStr = (j['type'] as String? ?? 'umum').toLowerCase();
    NotificationType nType;
    switch (typeStr) {
      case 'pengajuan_diterima':
        nType = NotificationType.pengajuanDiterima;
        break;
      case 'pengajuan_ditolak':
        nType = NotificationType.pengajuanDitolak;
        break;
      case 'ulasan_baru':
      case 'review':
        nType = NotificationType.ulasanBaru;
        break;
      case 'pesanan_update':
      case 'order':
        nType = NotificationType.pesananUpdate;
        break;
      case 'creator':
        nType = NotificationType.creator;
        break;
      default:
        nType = NotificationType.umum;
        break;
    }

    return NotificationModel(
      id: (j['id'] ?? '').toString(),
      type: nType,
      title: j['title'] as String? ?? '',
      body: j['body'] as String? ?? '',
      date: (j['createdAt'] ?? j['date'] ?? '').toString(),
      read: (j['isRead'] as bool?) ?? ((j['read'] as bool?) ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'date': date,
    'read': read,
  };

  NotificationModel copyWith({bool? read}) => NotificationModel(
    id: id,
    type: type,
    title: title,
    body: body,
    date: date,
    read: read ?? this.read,
  );
}
