// File: lib/blocs/profile/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../../services/database_services.dart';
import '../../models/user.dart';
import '../../models/booking.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DatabaseService _dbService = DatabaseService();

  ProfileBloc() : super(ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<RefreshProfile>(_onRefreshProfile);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      // Lấy thông tin user
      UserModel? user = await _dbService.getUser(event.userId);

      // Lấy danh sách booking
      List<BookingModel> bookings = await _dbService.getBookingsByUser(event.userId);

      // Lấy thông tin chi tiết cho mỗi booking
      List<BookingDetailModel> bookingDetails = [];
      for (var booking in bookings) {
        try {
          ShowtimeModel? showtime = await _dbService.getShowtime(booking.showtimeId);
          if (showtime != null) {
            MovieModel? movie = await _dbService.getMovie(showtime.movieId);
            TheaterModel? theater = await _dbService.getTheater(showtime.theaterId);

            // Xử lý timestamp an toàn
            DateTime showtimeDate;
            try {
              showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
            } catch (e) {
              // Nếu lỗi timestamp, dùng thời gian hiện tại
              showtimeDate = DateTime.now();
              print('Error parsing timestamp: $e');
            }

            bookingDetails.add(BookingDetailModel(
              booking: booking,
              movieTitle: movie?.title ?? 'Unknown Movie',
              moviePoster: movie?.posterUrl ?? '',
              theaterName: theater?.name ?? 'Unknown Theater',
              showtime: showtimeDate,
              qrCode: _generateQRCode(booking.id),
            ));
          }
        } catch (e) {
          print('Error loading booking detail: $e');
          // Tiếp tục với booking tiếp theo thay vì dừng hẳn
          continue;
        }
      }

      // Sắp xếp theo thời gian đặt vé (bookedAt) - mới nhất trước
      bookingDetails.sort((a, b) {
        final bookedAtA = a.booking.bookedAt ?? 0;
        final bookedAtB = b.booking.bookedAt ?? 0;
        // Sắp xếp giảm dần: mới nhất (timestamp lớn hơn) sẽ đứng trước
        return bookedAtB.compareTo(bookedAtA);
      });

      emit(state.copyWith(
        user: user,
        bookings: bookingDetails,
        isLoading: false,
      ));
    } catch (e) {
      print('Error in LoadProfile: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onRefreshProfile(RefreshProfile event, Emitter<ProfileState> emit) async {
    add(LoadProfile(event.userId));
  }

  // Tạo mã QR ngẫu nhiên dựa trên booking ID
  String _generateQRCode(String bookingId) {
    final random = Random(bookingId.hashCode);
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }
}