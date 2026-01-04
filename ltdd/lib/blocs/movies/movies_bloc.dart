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
      
      // Tìm trong TẤT CẢ phim (đang chiếu, sắp chiếu, và phổ biến)
      // Load tất cả phim để tìm kiếm trong toàn bộ danh sách
      List<MovieModel> allMovies = [];
      if (cinemaId != null && cinemaId.isNotEmpty) {
        allMovies = await _dbService.getMoviesByCinema(cinemaId);
      } else {
        // Load tất cả phim từ database
        allMovies = await _dbService.getAllMovies();
        
        // Nếu getAllMovies() filter quá nhiều, load từ cả đang chiếu và sắp chiếu
        if (allMovies.isEmpty) {
          final nowShowingMovies = await _dbService.getMoviesShowingToday(cinemaId: null);
          final comingSoonMovies = await _dbService.getMoviesComingSoon(cinemaId: null);
          
          // Kết hợp và loại bỏ trùng lặp
          final allMovieIds = <String>{};
          allMovies = [];
          
          for (var movie in nowShowingMovies) {
            if (!allMovieIds.contains(movie.id)) {
              allMovies.add(movie);
              allMovieIds.add(movie.id);
            }
          }
          
          for (var movie in comingSoonMovies) {
            if (!allMovieIds.contains(movie.id)) {
              allMovies.add(movie);
              allMovieIds.add(movie.id);
            }
          }
        }
      }
      
      // Filter theo search query - tìm trong tên phim hoặc thể loại
      // Và tính điểm match để sort (match title có điểm cao hơn match genre)
      final resultMoviesWithScore = allMovies.map((movie) {
        final titleLower = movie.title.toLowerCase();
        final genreLower = movie.genre.toLowerCase();
        
        bool titleMatch = titleLower.contains(lowerQuery);
        bool genreMatch = genreLower.contains(lowerQuery);
        
        if (!titleMatch && !genreMatch) {
          return null; // Không match
        }
        
        // Tính điểm: match title = 2 điểm, match genre = 1 điểm
        // Nếu title bắt đầu bằng query = thêm 1 điểm
        int score = 0;
        if (titleMatch) {
          score += 2;
          if (titleLower.startsWith(lowerQuery)) {
            score += 1; // Bonus cho title bắt đầu bằng query
          }
        }
        if (genreMatch) {
          score += 1;
        }
        
        return MapEntry(movie, score);
      }).where((entry) => entry != null).cast<MapEntry<MovieModel, int>>().toList();
      
      // Sort theo điểm (cao nhất lên đầu), sau đó theo tên phim
      resultMoviesWithScore.sort((a, b) {
        if (b.value != a.value) {
          return b.value.compareTo(a.value); // Sort theo điểm giảm dần
        }
        return a.key.title.compareTo(b.key.title); // Nếu điểm bằng nhau, sort theo tên
      });
      
      // Lấy danh sách phim đã sort
      final resultMovies = resultMoviesWithScore.map((entry) => entry.key).toList();
      
      // Xác định category dựa trên phim tìm được
      // Kiểm tra phim tìm được thuộc category nào (đang chiếu hay sắp chiếu)
      String? newCategory = state.category;
      
      if (resultMovies.isNotEmpty) {
        // Lấy danh sách phim đang chiếu và sắp chiếu để so sánh
        final nowShowingMovies = await _dbService.getMoviesShowingToday(cinemaId: cinemaId);
        final comingSoonMovies = await _dbService.getMoviesComingSoon(cinemaId: cinemaId);
        
        final nowShowingIds = nowShowingMovies.map((m) => m.id).toSet();
        final comingSoonIds = comingSoonMovies.map((m) => m.id).toSet();
        
        // Kiểm tra phim đầu tiên (match nhất) thuộc category nào
        // Ưu tiên category của phim đầu tiên trong kết quả
        final firstMovie = resultMovies.first;
        bool firstInComingSoon = comingSoonIds.contains(firstMovie.id);
        bool firstInNowShowing = nowShowingIds.contains(firstMovie.id);
        
        // Đếm số phim tìm được trong mỗi category
        int foundInNowShowing = 0;
        int foundInComingSoon = 0;
        
        for (var movie in resultMovies) {
          if (nowShowingIds.contains(movie.id)) {
            foundInNowShowing++;
          }
          if (comingSoonIds.contains(movie.id)) {
            foundInComingSoon++;
          }
        }
        
        // Nếu phim đầu tiên (match nhất) ở "Sắp Chiếu" → chuyển sang tab "Sắp Chiếu"
        // Nếu phim đầu tiên ở "Đang Chiếu" → chuyển sang tab "Đang Chiếu"
        // Nếu phim đầu tiên không ở cả 2 → ưu tiên category có nhiều phim hơn
        if (firstInComingSoon) {
          newCategory = 'comingSoon';
        } else if (firstInNowShowing) {
          newCategory = 'nowShowing';
        } else {
          // Nếu phim đầu tiên không ở cả 2 category, ưu tiên category có nhiều phim hơn
          if (foundInComingSoon > foundInNowShowing) {
            newCategory = 'comingSoon';
          } else if (foundInNowShowing > 0) {
            newCategory = 'nowShowing';
          }
        }
      }
      
      emit(state.copyWith(
        movies: resultMovies,
        category: newCategory,
        searchQuery: event.query,
        isLoading: false,
      ));
      
      print('🔍 SearchMovies: Query="${event.query}", Found ${resultMovies.length} movies');
      print('🔍   - Category changed to: $newCategory');
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
      
      // Reload movies from DB based on category
      // Note: In home_screen, cinemaId is always null to show all movies
      // Logic: 
      // - Tab "Đang Chiếu": Phim có lịch chiếu hôm nay
      // - Tab "Sắp Chiếu": Phim không có lịch chiếu hôm nay (bao gồm phim không có lịch chiếu + phim có lịch chiếu từ ngày mai)
      // - Tab "Phổ Biến": Phim được đặt >= 5 lần
      if (event.category == 'nowShowing') {
        // Tab "Đang Chiếu": Hiển thị tất cả phim có lịch chiếu hôm nay
        // Use cinemaId from event/state (null in home_screen to show all movies)
        filteredMovies = await _dbService.getMoviesShowingToday(cinemaId: cinemaId);
        print('🎬 FilterMoviesByCategory (nowShowing): Loaded ${filteredMovies.length} movies with showtimes today (cinemaId: $cinemaId)');
      } else if (event.category == 'comingSoon') {
        // Tab "Sắp Chiếu": Hiển thị tất cả phim không có lịch chiếu hôm nay
        // Bao gồm: phim không có lịch chiếu + phim có lịch chiếu từ ngày mai trở đi
        // Use cinemaId from event/state (null in home_screen to show all movies)
        filteredMovies = await _dbService.getMoviesComingSoon(cinemaId: cinemaId);
        print('🎬 FilterMoviesByCategory (comingSoon): Loaded ${filteredMovies.length} movies (no showtimes today or showtimes from tomorrow) (cinemaId: $cinemaId)');
      } else if (event.category == 'popular') {
        // Tab "Phổ Biến": Hiển thị phim được đặt >= 5 lần
        // Load movies by cinema if specified, otherwise load all movies
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
        print('🎬 FilterMoviesByCategory (popular): Loaded ${filteredMovies.length} popular movies (cinemaId: $cinemaId)');
      } else {
        // Default: load movies by cinema if specified, otherwise load all movies
        if (cinemaId != null && cinemaId.isNotEmpty) {
          filteredMovies = await _dbService.getMoviesByCinema(cinemaId);
        } else {
          filteredMovies = await _dbService.getAllMovies();
        }
        print('🎬 FilterMoviesByCategory (default): Loaded ${filteredMovies.length} movies (cinemaId: $cinemaId)');
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