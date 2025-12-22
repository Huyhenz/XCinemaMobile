// File: lib/blocs/profile/profile_state.dart
import '../../models/user.dart';
import '../../models/booking.dart';

class ProfileState {
  final UserModel? user;
  final List<BookingDetailModel> bookings;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.user,
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    List<BookingDetailModel>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Model để lưu thông tin chi tiết booking kèm thông tin phim, rạp, suất chiếu
class BookingDetailModel {
  final BookingModel booking;
  final String movieTitle;
  final String moviePoster;
  final String theaterName;
  final DateTime showtime;
  final String qrCode;

  BookingDetailModel({
    required this.booking,
    required this.movieTitle,
    required this.moviePoster,
    required this.theaterName,
    required this.showtime,
    required this.qrCode,
  });
}