// File: lib/utils/booking_helper.dart
import '../services/database_services.dart';
import '../models/booking.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import 'package:intl/intl.dart';

class BookingHelper {
  static final DatabaseService _dbService = DatabaseService();

  /// Tạo thông báo khi đặt vé thành công
  static Future<void> createBookingSuccessNotification({
    required String userId,
    required String bookingId,
    required BookingModel booking,
  }) async {
    try {
      // Lấy thông tin chi tiết để tạo message
      ShowtimeModel? showtime = await _dbService.getShowtime(booking.showtimeId);
      MovieModel? movie;

      if (showtime != null) {
        movie = await _dbService.getMovie(showtime.movieId);
      }

      final movieTitle = movie?.title ?? 'phim';
      final seats = booking.seats.join(', ');
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
      final showtimeStr = showtime != null
          ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(showtime.startTime))
          : '';

      await _dbService.createNotification(
        userId: userId,
        title: 'Đặt Vé Thành Công! 🎉',
        message: 'Bạn đã đặt vé xem "$movieTitle" thành công. Ghế: $seats. Suất chiếu: $showtimeStr',
        type: 'booking_success',
        bookingId: bookingId,
      );
    } catch (e) {
      print('Error creating booking success notification: $e');
    }
  }

  /// Tạo thông báo khi hủy vé
  static Future<void> createBookingCancelledNotification({
    required String userId,
    required String bookingId,
    required String movieTitle,
  }) async {
    try {
      await _dbService.createNotification(
        userId: userId,
        title: 'Đặt Vé Bị Hủy',
        message: 'Vé xem phim "$movieTitle" của bạn đã bị hủy.',
        type: 'booking_cancelled',
        bookingId: bookingId,
      );
    } catch (e) {
      print('Error creating booking cancelled notification: $e');
    }
  }

  /// Tạo thông báo hệ thống
  static Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _dbService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'system',
      );
    } catch (e) {
      print('Error creating system notification: $e');
    }
  }
}