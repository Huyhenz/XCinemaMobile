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
      // Nếu query rỗng, clear search
      if (event.query.isEmpty || event.query.trim().isEmpty) {
        emit(state.copyWith(
          searchQuery: null,
          clearSearchQuery: true,
        ));
        return;
      }

      emit(state.copyWith(isLoading: true));

      final cinemaId = state.cinemaId;
      final lowerQuery = event.query.toLowerCase().trim();
      
      // Tìm trong cả phim đang chiếu và sắp chiếu
      List<MovieModel> nowShowingMovies = await _dbService.getMoviesShowingToday(cinemaId: cinemaId);
      List<MovieModel> comingSoonMovies = await _dbService.getMoviesComingSoon(cinemaId: cinemaId);
      
      // Filter theo search query
      final nowShowingFiltered = nowShowingMovies.where((movie) {
        return movie.title.toLowerCase().contains(lowerQuery) ||
               movie.genre.toLowerCase().contains(lowerQuery);
      }).toList();
      
      final comingSoonFiltered = comingSoonMovies.where((movie) {
        return movie.title.toLowerCase().contains(lowerQuery) ||
               movie.genre.toLowerCase().contains(lowerQuery);
      }).toList();
      
      // Xác định category dựa trên kết quả tìm được
      // Ưu tiên: nếu tìm thấy ở cả 2, ưu tiên category hiện tại
      // Nếu chỉ tìm thấy ở 1 category, chuyển sang category đó
      String? newCategory = state.category;
      List<MovieModel> resultMovies = [];
      
      if (nowShowingFiltered.isNotEmpty && comingSoonFiltered.isNotEmpty) {
        // Tìm thấy ở cả 2 category
        // Nếu đang ở "đang chiếu", ưu tiên "đang chiếu"
        // Nếu đang ở "sắp chiếu", ưu tiên "sắp chiếu"
        if (state.category == 'comingSoon') {
          newCategory = 'comingSoon';
          resultMovies = comingSoonFiltered;
        } else {
          // Mặc định ưu tiên "đang chiếu"
          newCategory = 'nowShowing';
          resultMovies = nowShowingFiltered;
        }
      } else if (nowShowingFiltered.isNotEmpty) {
        // Chỉ tìm thấy trong "đang chiếu"
        newCategory = 'nowShowing';
        resultMovies = nowShowingFiltered;
      } else if (comingSoonFiltered.isNotEmpty) {
        // Chỉ tìm thấy trong "sắp chiếu"
        newCategory = 'comingSoon';
        resultMovies = comingSoonFiltered;
      } else {
        // Không tìm thấy, giữ category hiện tại và hiển thị empty
        resultMovies = [];
      }
      
      emit(state.copyWith(
        movies: resultMovies,
        category: newCategory,
        searchQuery: event.query,
        isLoading: false,
      ));
      
      print('🔍 SearchMovies: Query="${event.query}", Found ${nowShowingFiltered.length} in nowShowing, ${comingSoonFiltered.length} in comingSoon, CurrentCategory=${state.category}, NewCategory=$newCategory');
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
        // Note: Expired movies are already filtered in getMoviesByCinema/getAllMovies
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
      
      // Apply search query if exists (chỉ khi searchQuery không rỗng sau khi trim)
      // Lưu searchQuery hiện tại để check
      final currentSearchQuery = state.searchQuery;
      if (currentSearchQuery != null && 
          currentSearchQuery.isNotEmpty && 
          currentSearchQuery.trim().isNotEmpty) {
        final lowerQuery = currentSearchQuery.toLowerCase().trim();
        filteredMovies = filteredMovies.where((movie) {
          return movie.title.toLowerCase().contains(lowerQuery) ||
                 movie.genre.toLowerCase().contains(lowerQuery);
        }).toList();
        print('🎬 FilterMoviesByCategory: Applied search query "$currentSearchQuery", filtered to ${filteredMovies.length} movies');
      } else {
        print('🎬 FilterMoviesByCategory: No search query, showing all ${filteredMovies.length} movies');
      }
      
      // Khi FilterMoviesByCategory được gọi, clear searchQuery để đảm bảo reload đúng
      // (trừ khi đang trong quá trình search)
      emit(state.copyWith(
        movies: filteredMovies,
        category: event.category,
        isLoading: false,
        cinemaId: cinemaId, // Update cinemaId in state if provided in event
        allMovies: filteredMovies, // Also update allMovies for consistency
        clearSearchQuery: true, // Clear searchQuery khi reload phim
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