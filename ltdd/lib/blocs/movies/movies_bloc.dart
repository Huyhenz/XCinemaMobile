import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movie.dart';
import '../../services/database_services.dart';
import 'movies_event.dart';
import 'movies_state.dart';


class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, int> _movieBookingCounts = {}; // Cache booking counts

  MovieBloc() : super(MovieState()) {
    on<LoadMovies>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      List<MovieModel> allMovies;
      if (event.cinemaId != null && event.cinemaId!.isNotEmpty) {
        // Load movies by cinema
        allMovies = await _dbService.getMoviesByCinema(event.cinemaId!);
      } else {
        // Load all movies
        allMovies = await _dbService.getAllMovies();
      }
      // Load booking counts for popular movies
      _movieBookingCounts = await _dbService.getBookingCountsByMovie();
      emit(state.copyWith(
        allMovies: allMovies,
        movies: allMovies,
        isLoading: false,
      ));
    });

    on<SearchMovies>((event, emit) {
      List<MovieModel> filtered = _filterMovies(state.allMovies, event.query, state.category);
      emit(state.copyWith(
        movies: filtered,
        searchQuery: event.query.isEmpty ? null : event.query,
      ));
    });

    on<FilterMoviesByCategory>((event, emit) {
      List<MovieModel> filtered = _filterMovies(state.allMovies, state.searchQuery, event.category);
      emit(state.copyWith(
        movies: filtered,
        category: event.category,
      ));
    });
  }

  List<MovieModel> _filterMovies(List<MovieModel> allMovies, String? query, String? category) {
    List<MovieModel> filtered = List.from(allMovies);

    // Filter by category first
    if (category != null && category.isNotEmpty) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day); // 00:00:00 hôm nay
      final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // 23:59:59 hôm nay
      final todayStartMillis = todayStart.millisecondsSinceEpoch;
      final todayEndMillis = todayEnd.millisecondsSinceEpoch;
      
      filtered = filtered.where((movie) {
        switch (category) {
          case 'nowShowing':
            // Phim chiếu trong ngày hôm nay
            if (movie.releaseDate == null) return false;
            return movie.releaseDate! >= todayStartMillis && movie.releaseDate! <= todayEndMillis;
          case 'comingSoon':
            // Phim chiếu từ ngày mai trở đi
            if (movie.releaseDate == null) return false;
            return movie.releaseDate! > todayEndMillis;
          case 'popular':
            // Phim được đặt >= 5 lần
            final bookingCount = _movieBookingCounts[movie.id] ?? 0;
            return bookingCount >= 5;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query - CHỈ search theo tên phim hoặc thể loại, ẩn phim không match
    if (query != null && query.isNotEmpty && query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase().trim();
      filtered = filtered.where((movie) {
        // Chỉ search theo tên phim hoặc thể loại
        return movie.title.toLowerCase().contains(lowerQuery) ||
               movie.genre.toLowerCase().contains(lowerQuery);
      }).toList();
      // Nếu có search query thì chỉ trả về phim match, không trả về phim không match
    }
    // Nếu query rỗng hoặc null thì hiển thị tất cả phim đã được filter theo category

    return filtered;
  }
}