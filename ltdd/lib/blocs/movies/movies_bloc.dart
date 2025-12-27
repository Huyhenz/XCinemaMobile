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
        cinemaId: event.cinemaId,
      ));
    });

    on<SearchMovies>((event, emit) async {
      // Search on current filtered movies
      // If there's a category filter active, we need to reload from DB first
      if (state.category != null && state.category!.isNotEmpty) {
        // Reload filtered movies first, then apply search
        List<MovieModel> filteredMovies = [];
        final cinemaId = state.cinemaId;
        
        if (state.category == 'nowShowing') {
          filteredMovies = await _dbService.getMoviesShowingToday(cinemaId: cinemaId);
        } else if (state.category == 'comingSoon') {
          filteredMovies = await _dbService.getMoviesComingSoon(cinemaId: cinemaId);
        } else if (state.category == 'popular') {
          List<MovieModel> allMovies;
          if (cinemaId != null && cinemaId.isNotEmpty) {
            allMovies = await _dbService.getMoviesByCinema(cinemaId);
          } else {
            allMovies = await _dbService.getAllMovies();
          }
          _movieBookingCounts = await _dbService.getBookingCountsByMovie();
          filteredMovies = allMovies.where((movie) {
            final bookingCount = _movieBookingCounts[movie.id] ?? 0;
            return bookingCount >= 5;
          }).toList();
        } else {
          if (cinemaId != null && cinemaId.isNotEmpty) {
            filteredMovies = await _dbService.getMoviesByCinema(cinemaId);
          } else {
            filteredMovies = await _dbService.getAllMovies();
          }
        }
        
        // Apply search query
        if (event.query.isNotEmpty && event.query.trim().isNotEmpty) {
          final lowerQuery = event.query.toLowerCase().trim();
          filteredMovies = filteredMovies.where((movie) {
            return movie.title.toLowerCase().contains(lowerQuery) ||
                   movie.genre.toLowerCase().contains(lowerQuery);
          }).toList();
        }
        
        emit(state.copyWith(
          movies: filteredMovies,
          searchQuery: event.query.isEmpty ? null : event.query,
        ));
      } else {
        // No category filter, search on current movies
        final lowerQuery = event.query.toLowerCase().trim();
        final filtered = state.movies.where((movie) {
          return movie.title.toLowerCase().contains(lowerQuery) ||
                 movie.genre.toLowerCase().contains(lowerQuery);
        }).toList();
        
        emit(state.copyWith(
          movies: filtered,
          searchQuery: event.query.isEmpty ? null : event.query,
        ));
      }
    });

    on<FilterMoviesByCategory>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      
      // Use cinemaId from event if provided, otherwise use from state
      // Priority: event.cinemaId > state.cinemaId
      final cinemaId = event.cinemaId ?? state.cinemaId;
      
      print('🎬 FilterMoviesByCategory: category=${event.category}');
      print('🎬   - event.cinemaId: ${event.cinemaId}');
      print('🎬   - state.cinemaId: ${state.cinemaId}');
      print('🎬   - Using cinemaId: $cinemaId');
      
      List<MovieModel> filteredMovies = [];
      
      // Reload movies from DB based on category - filter by cinemaId if specified
      if (event.category == 'nowShowing') {
        // Load movies showing today - filter by cinema if selected
        filteredMovies = await _dbService.getMoviesShowingToday(cinemaId: cinemaId);
        print('🎬 FilterMoviesByCategory (nowShowing): Loaded ${filteredMovies.length} movies');
      } else if (event.category == 'comingSoon') {
        // Load movies coming soon (from tomorrow onwards) - filter by cinema if selected
        filteredMovies = await _dbService.getMoviesComingSoon(cinemaId: cinemaId);
      } else if (event.category == 'popular') {
        // Load movies by cinema if specified, then filter by booking count
        List<MovieModel> allMovies;
        if (cinemaId != null && cinemaId.isNotEmpty) {
          allMovies = await _dbService.getMoviesByCinema(cinemaId);
        } else {
          allMovies = await _dbService.getAllMovies();
        }
        // Reload booking counts
        _movieBookingCounts = await _dbService.getBookingCountsByMovie();
        // Filter by booking count >= 5
        filteredMovies = allMovies.where((movie) {
          final bookingCount = _movieBookingCounts[movie.id] ?? 0;
          return bookingCount >= 5;
        }).toList();
      } else {
        // Default: load movies by cinema if specified
        if (cinemaId != null && cinemaId.isNotEmpty) {
          filteredMovies = await _dbService.getMoviesByCinema(cinemaId);
        } else {
          filteredMovies = await _dbService.getAllMovies();
        }
      }
      
      // Apply search query if exists
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        final lowerQuery = state.searchQuery!.toLowerCase().trim();
        filteredMovies = filteredMovies.where((movie) {
          return movie.title.toLowerCase().contains(lowerQuery) ||
                 movie.genre.toLowerCase().contains(lowerQuery);
        }).toList();
      }
      
      emit(state.copyWith(
        movies: filteredMovies,
        category: event.category,
        isLoading: false,
        cinemaId: cinemaId, // Update cinemaId in state if provided in event
        allMovies: filteredMovies, // Also update allMovies for consistency
      ));
      
      print('🎬 FilterMoviesByCategory: Emitted ${filteredMovies.length} movies for cinema $cinemaId');
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