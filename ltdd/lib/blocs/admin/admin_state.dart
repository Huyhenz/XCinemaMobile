import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart'; // Nếu thêm

class AdminState {
  final List<MovieModel> movies;
  final List<TheaterModel> theaters;
  final String? error;
  final bool isLoading;

  AdminState({
    this.movies = const [],
    this.theaters = const [],
    this.error,
    this.isLoading = false,
  });
}