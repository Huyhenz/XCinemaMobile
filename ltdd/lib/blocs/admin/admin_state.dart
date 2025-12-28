import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';
import '../../models/voucher.dart';
import '../../models/cinema.dart';

class AdminState {
  final List<MovieModel> movies;
  final List<CinemaModel> cinemas;
  final List<TheaterModel> theaters;
  final List<ShowtimeModel> showtimes;
  final List<VoucherModel> vouchers;
  final String? error;
  final bool isLoading;

  AdminState({
    this.movies = const [],
    this.cinemas = const [],
    this.theaters = const [],
    this.showtimes = const [],
    this.vouchers = const [],
    this.error,
    this.isLoading = false,
  });
}