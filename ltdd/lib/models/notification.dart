// File: lib/models/notification.dart
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'booking_success', 'booking_cancelled', 'system'
  final String? bookingId;
  final bool isRead;
  final int createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.bookingId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? bookingId,
    bool? isRead,
    int? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}