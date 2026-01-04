// File: lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../blocs/profile/profile_state.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widgets.dart';
import 'profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      List<dynamic> notifData = await DatabaseService().getNotificationsByUser(userId);

      // Convert to NotificationModel
      _notifications = notifData.map((data) {
        return NotificationModel(
          id: data['id'] as String,
          userId: data['userId'] as String,
          title: data['title'] as String,
          message: data['message'] as String,
          type: data['type'] as String,
          bookingId: data['bookingId'] as String?,
          isRead: data['isRead'] as bool,
          createdAt: data['createdAt'] as int,
        );
      }).toList();

      setState(() {});
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await DatabaseService().markNotificationAsRead(notification.id);
      setState(() {
        int index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await DatabaseService().deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      if (mounted) {
        await DialogHelper.showSuccess(context, 'Đã xóa thông báo');
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Báo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount chưa đọc',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const AppLoadingIndicator(message: 'Đang tải thông báo...')
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFFE50914),
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(_notifications[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Chưa có thông báo',
      subtitle: 'Các thông báo mới sẽ hiển thị ở đây',
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
    final date = DateTime.fromMillisecondsSinceEpoch(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE50914), Color(0xFFB20710)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE50914).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _showNotificationDetail(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: notification.isRead
                ? const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      _getNotificationColor(notification.type).withOpacity(0.15),
                      const Color(0xFF2A2A2A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead
                  ? const Color(0xFF2A2A2A).withOpacity(0.5)
                  : _getNotificationColor(notification.type).withOpacity(0.4),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: notification.isRead
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _getNotificationColor(notification.type).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getNotificationColor(notification.type),
                      _getNotificationColor(notification.type).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _getNotificationColor(notification.type).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_success':
        return Icons.check_circle_outline;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_success':
        return const Color(0xFF4CAF50);
      case 'booking_cancelled':
        return const Color(0xFFE50914);
      default:
        return const Color(0xFF2196F3);
    }
  }

  void _showNotificationDetail(NotificationModel notification) async {
    // Đánh dấu là đã đọc khi mở chi tiết
    await _markAsRead(notification);

    // Hiển thị dialog chi tiết
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => _NotificationDetailDialog(notification: notification),
    );
  }
}

class _NotificationDetailDialog extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationDetailDialog({required this.notification});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
    final date = DateTime.fromMillisecondsSinceEpoch(notification.createdAt);
    
    Color notificationColor;
    IconData notificationIcon;
    
    switch (notification.type) {
      case 'booking_success':
        notificationColor = const Color(0xFF4CAF50);
        notificationIcon = Icons.check_circle;
        break;
      case 'booking_cancelled':
        notificationColor = const Color(0xFFE50914);
        notificationIcon = Icons.cancel;
        break;
      default:
        notificationColor = const Color(0xFF2196F3);
        notificationIcon = Icons.notifications;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF2A2A2A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: notificationColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    notificationColor.withOpacity(0.2),
                    notificationColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notificationColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notificationColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      notificationIcon,
                      color: notificationColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(date),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: notificationColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Loại thông báo',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: notificationColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: notificationColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getTypeLabel(notification.type),
                              style: TextStyle(
                                color: notificationColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nội dung',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (notification.bookingId != null && notification.bookingId!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              notificationColor.withOpacity(0.2),
                              notificationColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: notificationColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: notificationColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mã đặt vé',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.bookingId!,
                                    style: TextStyle(
                                      color: notificationColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  if (notification.bookingId != null && notification.bookingId!.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _showBookingDetail(context, notification.bookingId!);
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Xem chi tiết đặt vé'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: notificationColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (notification.bookingId != null && notification.bookingId!.isNotEmpty)
                    const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'booking_success':
        return 'Đặt vé thành công';
      case 'booking_cancelled':
        return 'Hủy đặt vé';
      case 'email_confirmation':
        return 'Xác nhận email';
      default:
        return 'Thông báo hệ thống';
    }
  }

  Future<void> _showBookingDetail(BuildContext context, String bookingId) async {
    try {
      // Load booking
      final booking = await DatabaseService().getBooking(bookingId);
      if (booking == null) {
        if (context.mounted) {
          await DialogHelper.showError(context, 'Không tìm thấy thông tin đặt vé');
        }
        return;
      }

      // Load showtime
      final showtime = await DatabaseService().getShowtime(booking.showtimeId);
      if (showtime == null) {
        if (context.mounted) {
          await DialogHelper.showError(context, 'Không tìm thấy thông tin suất chiếu');
        }
        return;
      }

      // Load movie
      final movie = await DatabaseService().getMovie(showtime.movieId);
      if (movie == null) {
        if (context.mounted) {
          await DialogHelper.showError(context, 'Không tìm thấy thông tin phim');
        }
        return;
      }

      // Load theater
      final theater = await DatabaseService().getTheater(showtime.theaterId);
      if (theater == null) {
        if (context.mounted) {
          await DialogHelper.showError(context, 'Không tìm thấy thông tin phòng chiếu');
        }
        return;
      }

      // Create BookingDetailModel
      final qrCode = booking.id; // Use booking ID as QR code
      final bookingDetail = BookingDetailModel(
        booking: booking,
        movieTitle: movie.title,
        moviePoster: movie.posterUrl,
        theaterName: theater.name,
        showtime: DateTime.fromMillisecondsSinceEpoch(showtime.startTime),
        qrCode: qrCode,
      );

      // Show booking detail using ProfileScreen's static method
      if (context.mounted) {
        ProfileScreen.showBookingDetailStatic(context, bookingDetail);
      }
    } catch (e) {
      print('Error loading booking detail: $e');
      if (context.mounted) {
        await DialogHelper.showError(context, 'Lỗi khi tải thông tin đặt vé: $e');
      }
    }
  }
}