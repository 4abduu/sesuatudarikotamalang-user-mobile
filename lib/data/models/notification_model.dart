enum NotificationType { order, review, system, creator }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String date;
  final bool read;
  const NotificationModel({
    required this.id, required this.type, required this.title,
    required this.body, required this.date, required this.read,
  });
}
