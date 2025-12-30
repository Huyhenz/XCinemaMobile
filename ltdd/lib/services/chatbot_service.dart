// File: lib/services/chatbot_service.dart
// Chatbot service để hỗ trợ người dùng đặt vé xem phim

import '../models/movie.dart';
import '../models/showtime.dart';
import 'database_services.dart';
import 'package:intl/intl.dart';

/// Context để lưu trữ trạng thái conversation
class ConversationContext {
  final String? waitingFor; // 'movie_name', 'showtime_date', 'cinema_selection', null
  final String? lastIntent; // Intent của câu hỏi trước
  final Map<String, dynamic> data; // Dữ liệu đã thu thập

  ConversationContext({
    this.waitingFor,
    this.lastIntent,
    this.data = const {},
  });

  ConversationContext copyWith({
    String? waitingFor,
    String? lastIntent,
    Map<String, dynamic>? data,
  }) {
    return ConversationContext(
      waitingFor: waitingFor ?? this.waitingFor,
      lastIntent: lastIntent ?? this.lastIntent,
      data: data ?? this.data,
    );
  }

  bool get isWaitingForInput => waitingFor != null;
}

class ChatBotService {
  static final DatabaseService _dbService = DatabaseService();

  /// Xử lý tin nhắn từ user và trả về phản hồi
  static Future<ChatBotResponse> processMessage(
    String userMessage, {
    ConversationContext? context,
  }) async {
    final message = userMessage.toLowerCase().trim();
    ConversationContext? newContext = context;

    // Nếu đang chờ input từ user, xử lý theo context
    if (context?.isWaitingForInput == true) {
      return _handleContextualResponse(message, context!);
    }

    // Chào hỏi
    if (_matchesPattern(message, ['xin chào', 'hello', 'hi', 'chào', 'hey'])) {
      return ChatBotResponse(
        text: 'Xin chào! Tôi là chatbot hỗ trợ đặt vé xem phim. Tôi có thể giúp bạn:\n\n'
            '🎬 Tìm phim đang chiếu\n'
            '📅 Xem lịch chiếu\n'
            '💰 Hỏi về giá vé\n'
            '❓ Trả lời câu hỏi thường gặp\n\n'
            'Bạn cần hỗ trợ gì?',
        type: ChatBotResponseType.text,
      );
    }

    // Hỏi về phim đang chiếu
    if (_matchesPattern(message, ['phim đang chiếu', 'phim nào đang chiếu', 'phim hôm nay', 'đang chiếu'])) {
      try {
        final movies = await _dbService.getMoviesShowingToday();
        if (movies.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại không có phim nào đang chiếu hôm nay. Bạn có thể xem các phim sắp chiếu nhé!',
            type: ChatBotResponseType.text,
          );
        }
        String response = '🎬 Các phim đang chiếu hôm nay:\n\n';
        for (var movie in movies.take(5)) {
          response += '• ${movie.title}\n';
          if (movie.genre.isNotEmpty) {
            response += '  Thể loại: ${movie.genre}\n';
          }
          response += '\n';
        }
        if (movies.length > 5) {
          response += '... và ${movies.length - 5} phim khác.\n\n';
        }
        response += 'Bạn muốn xem chi tiết phim nào?';
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.text,
          movies: movies,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy thông tin phim lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Hỏi về phim sắp chiếu
    if (_matchesPattern(message, ['phim sắp chiếu', 'phim nào sắp chiếu', 'sắp chiếu', 'coming soon'])) {
      try {
        final movies = await _dbService.getMoviesComingSoon();
        if (movies.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại không có phim nào sắp chiếu.',
            type: ChatBotResponseType.text,
          );
        }
        String response = '🎬 Các phim sắp chiếu:\n\n';
        for (var movie in movies.take(5)) {
          response += '• ${movie.title}\n';
          if (movie.genre.isNotEmpty) {
            response += '  Thể loại: ${movie.genre}\n';
          }
          response += '\n';
        }
        if (movies.length > 5) {
          response += '... và ${movies.length - 5} phim khác.\n\n';
        }
        response += 'Bạn muốn xem chi tiết phim nào?';
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.text,
          movies: movies,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy thông tin phim lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Hỏi về tất cả phim (có phim gì)
    if (_matchesPattern(message, ['có phim gì', 'phim gì', 'danh sách phim', 'list phim', 'tất cả phim'])) {
      try {
        final allMovies = await _dbService.getAllMovies();
        if (allMovies.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại không có phim nào trong hệ thống.',
            type: ChatBotResponseType.text,
          );
        }
        String response = '🎬 Danh sách tất cả phim (${allMovies.length} phim):\n\n';
        for (var movie in allMovies.take(10)) {
          response += '• ${movie.title}\n';
          if (movie.genre.isNotEmpty) {
            response += '  Thể loại: ${movie.genre}\n';
          }
          if (movie.duration > 0) {
            response += '  Thời lượng: ${movie.duration} phút\n';
          }
          response += '\n';
        }
        if (allMovies.length > 10) {
          response += '... và ${allMovies.length - 10} phim khác.\n\n';
        }
        response += 'Bạn muốn xem chi tiết phim nào?';
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.text,
          movies: allMovies,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy danh sách phim lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Tìm phim theo tên
    // Chỉ match khi có từ "tìm" hoặc "search", không match chỉ "phim" để tránh conflict
    if (_matchesPattern(message, ['tìm phim', 'tìm', 'search phim', 'search movie'])) {
      // Extract movie name from message
      String? movieName = _extractMovieName(message);
      if (movieName != null && movieName.isNotEmpty) {
        try {
          final allMovies = await _dbService.getAllMovies();
          final matchedMovies = allMovies.where((movie) {
            return movie.title.toLowerCase().contains(movieName.toLowerCase()) ||
                   movie.genre.toLowerCase().contains(movieName.toLowerCase());
          }).toList();

          if (matchedMovies.isEmpty) {
            newContext = ConversationContext(
              waitingFor: 'movie_name',
              lastIntent: 'search_movie',
            );
            return ChatBotResponse(
              text: 'Không tìm thấy phim nào với từ khóa "$movieName".\n\n'
                  'Bạn có thể:\n'
                  '• Thử tìm với tên khác\n'
                  '• Xem danh sách tất cả phim\n'
                  '• Xem phim đang chiếu\n\n'
                  'Bạn muốn làm gì?',
              type: ChatBotResponseType.text,
              context: newContext,
              suggestions: ['Có phim gì', 'Phim đang chiếu', 'Phim sắp chiếu'],
            );
          }

          String response = '🎬 Tìm thấy ${matchedMovies.length} phim:\n\n';
          for (var movie in matchedMovies.take(5)) {
            response += '• ${movie.title}\n';
            if (movie.genre.isNotEmpty) {
              response += '  Thể loại: ${movie.genre}\n';
            }
            response += '\n';
          }
          if (matchedMovies.length > 5) {
            response += '... và ${matchedMovies.length - 5} phim khác.\n\n';
          }
          response += 'Bạn muốn xem chi tiết phim nào?';
          return ChatBotResponse(
            text: response,
            type: ChatBotResponseType.text,
            movies: matchedMovies,
          );
        } catch (e) {
          return ChatBotResponse(
            text: 'Xin lỗi, tôi không thể tìm phim lúc này. Vui lòng thử lại sau.',
            type: ChatBotResponseType.text,
          );
        }
      } else {
        // Không có tên phim, đặt câu hỏi lại
        newContext = ConversationContext(
          waitingFor: 'movie_name',
          lastIntent: 'search_movie',
        );
        return ChatBotResponse(
          text: 'Bạn muốn tìm phim nào?\n\n'
              'Vui lòng cho tôi biết:\n'
              '• Tên phim bạn muốn tìm\n'
              '• Hoặc thể loại phim\n\n'
              'Ví dụ: "Tìm phim hành động" hoặc "Phim kinh dị"',
          type: ChatBotResponseType.text,
          context: newContext,
        );
      }
    }

    // Hỏi về giá vé
    if (_matchesPattern(message, ['giá vé', 'giá', 'price', 'bao nhiêu tiền', 'cost'])) {
      return ChatBotResponse(
        text: '💰 Giá vé phụ thuộc vào:\n\n'
            '• Phim bạn chọn\n'
            '• Suất chiếu (2D, 3D, IMAX)\n'
            '• Loại ghế (thường, VIP)\n\n'
            'Giá vé thường từ 50,000₫ - 200,000₫.\n\n'
            'Để biết giá chính xác, bạn hãy chọn phim và suất chiếu cụ thể nhé!',
        type: ChatBotResponseType.text,
      );
    }

    // Hỏi về cách đặt vé
    if (_matchesPattern(message, ['cách đặt vé', 'làm sao đặt vé', 'đặt vé như thế nào', 'how to book'])) {
      return ChatBotResponse(
        text: '📱 Cách đặt vé:\n\n'
            '1️⃣ Chọn rạp chiếu\n'
            '2️⃣ Chọn phim bạn muốn xem\n'
            '3️⃣ Chọn suất chiếu phù hợp\n'
            '4️⃣ Chọn ghế ngồi\n'
            '5️⃣ Thanh toán\n'
            '6️⃣ Nhận vé qua email\n\n'
            'Rất đơn giản phải không? Bạn muốn bắt đầu đặt vé không?',
        type: ChatBotResponseType.text,
      );
    }

    // Hỏi về hủy vé
    if (_matchesPattern(message, ['hủy vé', 'cancel', 'đổi vé', 'refund'])) {
      return ChatBotResponse(
        text: '❌ Chính sách hủy/đổi vé:\n\n'
            '• Có thể hủy vé trước 2 giờ so với suất chiếu\n'
            '• Phí hủy: 10% giá vé\n'
            '• Không thể đổi vé, chỉ có thể hủy và đặt lại\n\n'
            'Để hủy vé, bạn vào mục "Hồ Sơ" > "Lịch Sử Đặt Vé" và chọn hủy.',
        type: ChatBotResponseType.text,
      );
    }

    // Hỏi về thanh toán
    if (_matchesPattern(message, ['thanh toán', 'payment', 'pay', 'trả tiền'])) {
      return ChatBotResponse(
        text: '💳 Phương thức thanh toán:\n\n'
            '• PayPal\n'
            '• Google Pay\n'
            '• ZaloPay\n\n'
            'Sau khi thanh toán thành công, bạn sẽ nhận email xác nhận đặt vé.',
        type: ChatBotResponseType.text,
      );
    }

    // Hỏi về lịch chiếu (khi nào, tuần này)
    if (_matchesPattern(message, ['lịch chiếu', 'khi nào', 'tuần này', 'showtime', 'suất chiếu', 'lịch chiếu tuần này'])) {
      try {
        final allShowtimes = await _dbService.getAllShowtimes();
        if (allShowtimes.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại không có lịch chiếu nào.',
            type: ChatBotResponseType.text,
          );
        }

        // Lọc showtimes trong tuần này (7 ngày tới)
        final now = DateTime.now();
        final weekEnd = now.add(const Duration(days: 7));
        final weekStartMillis = now.millisecondsSinceEpoch;
        final weekEndMillis = weekEnd.millisecondsSinceEpoch;

        final weekShowtimes = allShowtimes.where((showtime) {
          return showtime.startTime >= weekStartMillis && showtime.startTime <= weekEndMillis;
        }).toList();

        if (weekShowtimes.isEmpty) {
          return ChatBotResponse(
            text: 'Tuần này không có lịch chiếu nào. Bạn có thể xem các phim sắp chiếu nhé!',
            type: ChatBotResponseType.text,
          );
        }

        // Nhóm showtimes theo ngày và phim
        // Tối ưu: Lấy tất cả movieIds trước, sau đó load movies một lần
        Set<String> movieIds = weekShowtimes.map((s) => s.movieId).toSet();
        Map<String, MovieModel?> moviesMap = {};
        
        // Load tất cả movies cần thiết song song
        await Future.wait(movieIds.map((movieId) async {
          final movie = await _dbService.getMovie(movieId);
          moviesMap[movieId] = movie;
        }));
        
        Map<String, Map<String, List<ShowtimeModel>>> groupedShowtimes = {};
        for (var showtime in weekShowtimes) {
          final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
          final dateKey = DateFormat('dd/MM/yyyy').format(showtimeDate);
          
          // Lấy tên phim từ map (đã load trước)
          final movie = moviesMap[showtime.movieId];
          final movieTitle = movie?.title ?? 'Phim không xác định';
          
          if (!groupedShowtimes.containsKey(dateKey)) {
            groupedShowtimes[dateKey] = {};
          }
          if (!groupedShowtimes[dateKey]!.containsKey(movieTitle)) {
            groupedShowtimes[dateKey]![movieTitle] = [];
          }
          groupedShowtimes[dateKey]![movieTitle]!.add(showtime);
        }

        String response = '📅 Lịch chiếu tuần này:\n\n';
        final sortedDates = groupedShowtimes.keys.toList()..sort();
        
        for (var dateKey in sortedDates.take(7)) {
          response += '📆 $dateKey:\n';
          final moviesOnDate = groupedShowtimes[dateKey]!;
          for (var movieTitle in moviesOnDate.keys) {
            response += '  🎬 $movieTitle:\n';
            final showtimes = moviesOnDate[movieTitle]!..sort((a, b) => a.startTime.compareTo(b.startTime));
            for (var showtime in showtimes.take(5)) {
              final time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
              final timeStr = DateFormat('HH:mm').format(time);
              response += '    • $timeStr\n';
            }
            if (showtimes.length > 5) {
              response += '    ... và ${showtimes.length - 5} suất khác\n';
            }
          }
          response += '\n';
        }

        response += 'Bạn muốn xem chi tiết phim nào?';
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.showtimeList,
          showtimes: weekShowtimes,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy lịch chiếu lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Hỏi về ghế ngồi còn trống
    if (_matchesPattern(message, ['ghế ngồi', 'ghế trống', 'ghế còn trống', 'available seats', 'seats', 'chỗ ngồi'])) {
      try {
        // Extract movie name or showtime info from message
        String? movieName = _extractMovieName(message);
        
        if (movieName != null && movieName.isNotEmpty) {
          // Tìm phim
          final allMovies = await _dbService.getAllMovies();
          final matchedMovies = allMovies.where((movie) {
            return movie.title.toLowerCase().contains(movieName.toLowerCase());
          }).toList();

          if (matchedMovies.isEmpty) {
            newContext = ConversationContext(
              waitingFor: 'movie_name',
              lastIntent: 'check_seats',
            );
            return ChatBotResponse(
              text: 'Không tìm thấy phim "$movieName".\n\n'
                  'Bạn có thể:\n'
                  '• Thử tìm với tên khác\n'
                  '• Xem danh sách tất cả phim\n\n'
                  'Bạn muốn tìm phim nào?',
              type: ChatBotResponseType.text,
              context: newContext,
              suggestions: ['Có phim gì'],
            );
          }

          // Lấy showtimes của phim đầu tiên
          final movie = matchedMovies.first;
          final showtimes = await _dbService.getShowtimesByMovie(movie.id);
          
          if (showtimes.isEmpty) {
            return ChatBotResponse(
              text: 'Phim "${movie.title}" hiện chưa có lịch chiếu.',
              type: ChatBotResponseType.text,
            );
          }

          // Lấy showtime sắp tới nhất
          final now = DateTime.now().millisecondsSinceEpoch;
          final upcomingShowtimes = showtimes.where((s) => s.startTime >= now).toList();
          upcomingShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

          if (upcomingShowtimes.isEmpty) {
            return ChatBotResponse(
              text: 'Phim "${movie.title}" không còn suất chiếu nào sắp tới.',
              type: ChatBotResponseType.text,
            );
          }

          String response = '🪑 Ghế ngồi còn trống cho "${movie.title}":\n\n';
          for (var showtime in upcomingShowtimes.take(5)) {
            final time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
            final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(time);
            final availableCount = showtime.availableSeats.length;
            response += '📅 $timeStr:\n';
            response += '  Còn trống: $availableCount ghế\n';
            if (availableCount > 0 && availableCount <= 20) {
              response += '  Ghế: ${showtime.availableSeats.join(", ")}\n';
            } else if (availableCount > 20) {
              response += '  Ghế: ${showtime.availableSeats.take(10).join(", ")} ... và ${availableCount - 10} ghế khác\n';
            }
            response += '\n';
          }
          if (upcomingShowtimes.length > 5) {
            response += '... và ${upcomingShowtimes.length - 5} suất chiếu khác.\n\n';
          }
          response += 'Bạn muốn đặt vé cho suất nào?';
          return ChatBotResponse(
            text: response,
            type: ChatBotResponseType.showtimeList,
            showtimes: upcomingShowtimes,
          );
        } else {
          // Không có tên phim, đặt câu hỏi lại
          newContext = ConversationContext(
            waitingFor: 'movie_name',
            lastIntent: 'check_seats',
          );
          return ChatBotResponse(
            text: 'Bạn muốn xem ghế trống của phim nào?\n\n'
                'Vui lòng cho tôi biết tên phim bạn muốn kiểm tra ghế ngồi.\n\n'
                'Hoặc bạn có thể xem tất cả suất chiếu còn ghế trống.',
            type: ChatBotResponseType.text,
            context: newContext,
            suggestions: ['Xem tất cả ghế trống', 'Có phim gì'],
          );
        }
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy thông tin ghế ngồi lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Xử lý "xem tất cả ghế trống" từ suggestion
    if (_matchesPattern(message, ['xem tất cả ghế trống', 'tất cả ghế trống'])) {
      try {
        // Không có tên phim, hiển thị tất cả ghế trống của các showtime sắp tới
        final allShowtimes = await _dbService.getAllShowtimes();
        final now = DateTime.now().millisecondsSinceEpoch;
        final upcomingShowtimes = allShowtimes.where((s) => s.startTime >= now && s.availableSeats.isNotEmpty).toList();
        upcomingShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcomingShowtimes.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại không còn ghế trống cho suất chiếu nào sắp tới.',
            type: ChatBotResponseType.text,
          );
        }

        // Tối ưu: Load tất cả movies một lần
        Set<String> movieIds = upcomingShowtimes.take(10).map((s) => s.movieId).toSet();
        Map<String, MovieModel?> moviesMap = {};
        
        await Future.wait(movieIds.map((movieId) async {
          final movie = await _dbService.getMovie(movieId);
          moviesMap[movieId] = movie;
        }));
        
        String response = '🪑 Các suất chiếu còn ghế trống:\n\n';
        for (var showtime in upcomingShowtimes.take(10)) {
          final movie = moviesMap[showtime.movieId];
          final movieTitle = movie?.title ?? 'Phim không xác định';
          final time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
          final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(time);
          final availableCount = showtime.availableSeats.length;
          response += '🎬 $movieTitle\n';
          response += '  📅 $timeStr - Còn $availableCount ghế trống\n\n';
        }
        if (upcomingShowtimes.length > 10) {
          response += '... và ${upcomingShowtimes.length - 10} suất chiếu khác.\n\n';
        }
        response += 'Bạn muốn đặt vé cho phim nào?';
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.showtimeList,
          showtimes: upcomingShowtimes,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy thông tin ghế ngồi lúc này. Vui lòng thử lại sau.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Hỏi về rạp chiếu
    if (_matchesPattern(message, ['rạp', 'cinema', 'theater', 'rạp nào'])) {
      try {
        final cinemas = await _dbService.getAllCinemas();
        if (cinemas.isEmpty) {
          return ChatBotResponse(
            text: 'Hiện tại chưa có thông tin về rạp chiếu.',
            type: ChatBotResponseType.text,
          );
        }
        String response = '🎭 Các rạp chiếu:\n\n';
        for (var cinema in cinemas) {
          response += '• ${cinema.name}\n';
          if (cinema.address.isNotEmpty) {
            response += '  Địa chỉ: ${cinema.address}\n';
          }
          response += '\n';
        }
        return ChatBotResponse(
          text: response,
          type: ChatBotResponseType.text,
        );
      } catch (e) {
        return ChatBotResponse(
          text: 'Xin lỗi, tôi không thể lấy thông tin rạp chiếu lúc này.',
          type: ChatBotResponseType.text,
        );
      }
    }

    // Câu hỏi thường gặp
    if (_matchesPattern(message, ['giúp', 'help', 'hướng dẫn', 'faq'])) {
      return ChatBotResponse(
        text: '❓ Câu hỏi thường gặp:\n\n'
            '• "Phim đang chiếu" - Xem phim hôm nay\n'
            '• "Phim sắp chiếu" - Xem phim sắp ra mắt\n'
            '• "Tìm phim [tên]" - Tìm phim cụ thể\n'
            '• "Giá vé" - Thông tin giá vé\n'
            '• "Cách đặt vé" - Hướng dẫn đặt vé\n'
            '• "Hủy vé" - Chính sách hủy vé\n'
            '• "Thanh toán" - Phương thức thanh toán\n'
            '• "Rạp" - Danh sách rạp chiếu\n\n'
            'Bạn muốn hỏi gì?',
        type: ChatBotResponseType.text,
        suggestions: [
          'Phim đang chiếu',
          'Tìm phim',
          'Giá vé',
          'Cách đặt vé',
        ],
      );
    }

    // Mặc định - không hiểu
    return ChatBotResponse(
      text: 'Xin lỗi, tôi chưa hiểu câu hỏi của bạn. Bạn có thể:\n\n'
          '• Hỏi về phim đang chiếu\n'
          '• Tìm phim theo tên\n'
          '• Hỏi về giá vé\n'
          '• Hỏi cách đặt vé\n\n'
          'Hoặc gõ "giúp" để xem danh sách câu hỏi thường gặp.',
      type: ChatBotResponseType.text,
      suggestions: [
        'Phim đang chiếu',
        'Tìm phim',
        'Giá vé',
        'Giúp',
      ],
    );
  }

  /// Kiểm tra xem message có match với các pattern không
  static bool _matchesPattern(String message, List<String> patterns) {
    for (var pattern in patterns) {
      if (message.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Extract tên phim từ message
  static String? _extractMovieName(String message) {
    // Remove common words
    String cleaned = message
        .replaceAll(RegExp(r'\b(tìm|phim|movie|search|về|cho|tôi|bạn|xem|ghế|trống|đang|chiếu|sắp)\b', caseSensitive: false), '')
        .trim();
    
    // Nếu sau khi remove chỉ còn ít hơn 2 ký tự hoặc rỗng, return null
    if (cleaned.isEmpty || cleaned.length < 2) {
      return null;
    }
    
    return cleaned;
  }

  /// Xử lý phản hồi dựa trên context (khi đang chờ input từ user)
  static Future<ChatBotResponse> _handleContextualResponse(
    String userMessage,
    ConversationContext context,
  ) async {
    final message = userMessage.toLowerCase().trim();

    // Cho phép user "thoát" khỏi context bằng cách gửi câu hỏi mới
    // Nếu user gửi câu hỏi mới (không phải trả lời), xử lý như bình thường
    if (_matchesPattern(message, ['phim đang chiếu', 'phim sắp chiếu', 'có phim gì', 'lịch chiếu', 'giá vé', 'giúp', 'help'])) {
      // User muốn hỏi câu mới, clear context và xử lý như bình thường
      return processMessage(userMessage, context: null);
    }

    // Nếu đang chờ tên phim
    if (context.waitingFor == 'movie_name') {
      // Extract movie name - lấy toàn bộ message nếu không extract được
      String? movieName = _extractMovieName(userMessage);
      
      // Nếu không extract được, thử lấy toàn bộ message (trừ các từ thông thường)
      if (movieName == null || movieName.isEmpty) {
        // Thử lấy toàn bộ message làm tên phim
        String cleaned = userMessage
            .replaceAll(RegExp(r'\b(tìm|phim|movie|search|về|cho|tôi|bạn|xem|ghế|trống|đang|chiếu|sắp)\b', caseSensitive: false), '')
            .trim();
        
        if (cleaned.isNotEmpty && cleaned.length >= 2) {
          movieName = cleaned;
        }
      }
      
      // Nếu vẫn không có tên phim, hỏi lại
      if (movieName == null || movieName.isEmpty) {
        return ChatBotResponse(
          text: 'Tôi chưa hiểu rõ tên phim bạn muốn tìm.\n\n'
              'Vui lòng cho tôi biết tên phim cụ thể.\n\n'
              'Ví dụ: "Avengers", "Titanic", "Phim hành động"...\n\n'
              'Hoặc bạn có thể gõ "Hủy" để hủy tìm kiếm.',
          type: ChatBotResponseType.text,
          context: context, // Giữ nguyên context
        );
      }

      // Xử lý theo intent trước đó
      if (context.lastIntent == 'search_movie') {
        // Tìm phim
        try {
          final allMovies = await _dbService.getAllMovies();
          final movieNameLower = movieName!.toLowerCase(); // Đã check null ở trên
          final matchedMovies = allMovies.where((movie) {
            return movie.title.toLowerCase().contains(movieNameLower) ||
                   movie.genre.toLowerCase().contains(movieNameLower);
          }).toList();

          if (matchedMovies.isEmpty) {
            return ChatBotResponse(
              text: 'Không tìm thấy phim nào với từ khóa "$movieName".\n\n'
                  'Bạn có thể thử tìm với tên khác hoặc xem danh sách tất cả phim.',
              type: ChatBotResponseType.text,
              suggestions: ['Có phim gì'],
            );
          }

          String response = '🎬 Tìm thấy ${matchedMovies.length} phim:\n\n';
          for (var movie in matchedMovies.take(5)) {
            response += '• ${movie.title}\n';
            if (movie.genre.isNotEmpty) {
              response += '  Thể loại: ${movie.genre}\n';
            }
            response += '\n';
          }
          if (matchedMovies.length > 5) {
            response += '... và ${matchedMovies.length - 5} phim khác.\n\n';
          }
          response += 'Bạn muốn xem chi tiết phim nào?';
          // Clear context sau khi tìm thấy phim
          return ChatBotResponse(
            text: response,
            type: ChatBotResponseType.text,
            movies: matchedMovies,
            context: null, // Clear context
          );
        } catch (e) {
          return ChatBotResponse(
            text: 'Xin lỗi, tôi không thể tìm phim lúc này. Vui lòng thử lại sau.',
            type: ChatBotResponseType.text,
            context: null, // Clear context khi có lỗi
          );
        }
      } else if (context.lastIntent == 'check_seats') {
        // Kiểm tra ghế trống
        try {
          final allMovies = await _dbService.getAllMovies();
          final movieNameLower = movieName!.toLowerCase(); // Đã check null ở trên
          final matchedMovies = allMovies.where((movie) {
            return movie.title.toLowerCase().contains(movieNameLower);
          }).toList();

          if (matchedMovies.isEmpty) {
            return ChatBotResponse(
              text: 'Không tìm thấy phim "$movieName".\n\n'
                  'Bạn có thể thử tìm với tên khác.',
              type: ChatBotResponseType.text,
              suggestions: ['Có phim gì'],
            );
          }

          final movie = matchedMovies.first;
          final showtimes = await _dbService.getShowtimesByMovie(movie.id);
          
          if (showtimes.isEmpty) {
            return ChatBotResponse(
              text: 'Phim "${movie.title}" hiện chưa có lịch chiếu.',
              type: ChatBotResponseType.text,
            );
          }

          final now = DateTime.now().millisecondsSinceEpoch;
          final upcomingShowtimes = showtimes.where((s) => s.startTime >= now && s.availableSeats.isNotEmpty).toList();
          upcomingShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

          if (upcomingShowtimes.isEmpty) {
            return ChatBotResponse(
              text: 'Phim "${movie.title}" không còn ghế trống cho suất chiếu nào sắp tới.',
              type: ChatBotResponseType.text,
            );
          }

          String response = '🪑 Ghế ngồi còn trống cho "${movie.title}":\n\n';
          for (var showtime in upcomingShowtimes.take(5)) {
            final time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
            final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(time);
            final availableCount = showtime.availableSeats.length;
            response += '📅 $timeStr:\n';
            response += '  Còn trống: $availableCount ghế\n';
            if (availableCount > 0 && availableCount <= 20) {
              response += '  Ghế: ${showtime.availableSeats.join(", ")}\n';
            } else if (availableCount > 20) {
              response += '  Ghế: ${showtime.availableSeats.take(10).join(", ")} ... và ${availableCount - 10} ghế khác\n';
            }
            response += '\n';
          }
          if (upcomingShowtimes.length > 5) {
            response += '... và ${upcomingShowtimes.length - 5} suất chiếu khác.\n\n';
          }
          response += 'Bạn muốn đặt vé cho suất nào?';
          // Clear context sau khi tìm thấy ghế trống
          return ChatBotResponse(
            text: response,
            type: ChatBotResponseType.showtimeList,
            showtimes: upcomingShowtimes,
            context: null, // Clear context
          );
        } catch (e) {
          return ChatBotResponse(
            text: 'Xin lỗi, tôi không thể lấy thông tin ghế ngồi lúc này. Vui lòng thử lại sau.',
            type: ChatBotResponseType.text,
            context: null, // Clear context khi có lỗi
          );
        }
      }
    }

    // Nếu không match với context, xử lý như bình thường
    return ChatBotResponse(
      text: 'Xin lỗi, tôi chưa hiểu. Bạn có thể hỏi lại không?',
      type: ChatBotResponseType.text,
      suggestions: ['Phim đang chiếu', 'Có phim gì', 'Giúp'],
    );
  }
}

/// Response từ chatbot
class ChatBotResponse {
  final String text;
  final ChatBotResponseType type;
  final List<MovieModel>? movies;
  final List<ShowtimeModel>? showtimes; // Showtimes data
  final List<String>? suggestions; // Quick reply suggestions
  final ConversationContext? context; // Context để tiếp tục conversation

  ChatBotResponse({
    required this.text,
    required this.type,
    this.movies,
    this.showtimes,
    this.suggestions,
    this.context,
  });
}

enum ChatBotResponseType {
  text,
  movieList,
  showtimeList,
}

