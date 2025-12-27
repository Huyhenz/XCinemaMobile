// File: lib/services/ai_agent_service.dart
// AI Agent Service - Intelligent chatbot với khả năng hiểu ngữ cảnh và xử lý câu hỏi phức tạp

import '../models/movie.dart';
import '../models/showtime.dart';
import 'database_services.dart';
import 'package:intl/intl.dart';

/// Context để lưu trữ trạng thái conversation (tương tự như trong chatbot_service)
class ConversationContext {
  final String? waitingFor;
  final String? lastIntent;
  final Map<String, dynamic> data;

  ConversationContext({
    this.waitingFor,
    this.lastIntent,
    this.data = const {},
  });

  bool get isWaitingForInput => waitingFor != null;
}

/// Response từ AI Agent
class ChatBotResponse {
  final String text;
  final ChatBotResponseType type;
  final List<MovieModel>? movies;
  final List<ShowtimeModel>? showtimes;
  final List<String>? suggestions;
  final ConversationContext? context;

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

/// Conversation History - Lưu trữ lịch sử hội thoại
class ConversationHistory {
  final List<Message> messages;
  final Map<String, dynamic> context;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ConversationHistory({
    List<Message>? messages,
    Map<String, dynamic>? context,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : messages = messages ?? [],
        context = context ?? {},
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  ConversationHistory addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages)..add(message);
    return ConversationHistory(
      messages: updatedMessages,
      context: context,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  ConversationHistory updateContext(Map<String, dynamic> newContext) {
    final updatedContext = Map<String, dynamic>.from(context)..addAll(newContext);
    return ConversationHistory(
      messages: messages,
      context: updatedContext,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  ConversationHistory clearContext() {
    return ConversationHistory(
      messages: messages,
      context: {},
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final Map<String, dynamic>? entities;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.entities,
  });
}

/// Intent Recognition - Nhận diện ý định của user
enum Intent {
  greeting,
  searchMovie,
  movieNowShowing,
  movieComingSoon,
  checkShowtimes,
  checkSeats,
  askPrice,
  askBookingProcess,
  askCancelPolicy,
  askPaymentMethods,
  askCinemas,
  askHelp,
  unknown,
}

/// AI Agent Service
class AIAgentService {
  static final DatabaseService _dbService = DatabaseService();
  
  // Conversation history cho mỗi session
  static final Map<String, ConversationHistory> _conversations = {};

  /// Xử lý tin nhắn với AI Agent
  static Future<ChatBotResponse> processMessage(
    String userMessage, {
    String? sessionId,
    ConversationContext? oldContext,
  }) async {
    final session = sessionId ?? 'default';
    final history = _conversations[session] ?? ConversationHistory();
    
    // Thêm message của user vào history
    final userMsg = Message(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    var updatedHistory = history.addMessage(userMsg);

    // Nhận diện intent
    final intent = _recognizeIntent(userMessage, updatedHistory);
    // ignore: avoid_print
    print('🤖 AI Agent - Intent recognized: $intent for message: "$userMessage"');
    
    // Extract entities
    final entities = _extractEntities(userMessage, intent);
    // ignore: avoid_print
    print('🤖 AI Agent - Entities extracted: $entities');
    
    // Cập nhật message với intent và entities
    final userMsgWithIntent = Message(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      intent: intent.toString(),
      entities: entities,
    );
    updatedHistory = updatedHistory.addMessage(userMsgWithIntent);

    // Xử lý theo intent
    ChatBotResponse response;
    ConversationContext? newContext;

    try {
      switch (intent) {
        case Intent.greeting:
          response = await _handleGreeting(updatedHistory);
          break;
        case Intent.searchMovie:
          response = await _handleSearchMovie(userMessage, entities, updatedHistory, oldContext);
          newContext = response.context;
          break;
        case Intent.movieNowShowing:
          response = await _handleMovieNowShowing(updatedHistory);
          break;
        case Intent.movieComingSoon:
          response = await _handleMovieComingSoon(updatedHistory);
          break;
        case Intent.checkShowtimes:
          response = await _handleCheckShowtimes(userMessage, entities, updatedHistory, oldContext);
          newContext = response.context;
          break;
        case Intent.checkSeats:
          response = await _handleCheckSeats(userMessage, entities, updatedHistory, oldContext);
          newContext = response.context;
          break;
        case Intent.askPrice:
          response = await _handleAskPrice(updatedHistory);
          break;
        case Intent.askBookingProcess:
          response = await _handleAskBookingProcess(updatedHistory);
          break;
        case Intent.askCancelPolicy:
          response = await _handleAskCancelPolicy(updatedHistory);
          break;
        case Intent.askPaymentMethods:
          response = await _handleAskPaymentMethods(updatedHistory);
          break;
        case Intent.askCinemas:
          response = await _handleAskCinemas(updatedHistory);
          break;
        case Intent.askHelp:
          response = await _handleAskHelp(updatedHistory);
          break;
        default:
          response = await _handleUnknown(userMessage, updatedHistory);
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ AI Agent error: $e');
      response = ChatBotResponse(
        text: 'Xin lỗi, tôi gặp lỗi khi xử lý câu hỏi của bạn. Vui lòng thử lại sau.',
        type: ChatBotResponseType.text,
        suggestions: ['Phim đang chiếu', 'Có phim gì', 'Giúp'],
      );
    }

    // Thêm response vào history
    final botMsg = Message(
      text: response.text,
      isUser: false,
      timestamp: DateTime.now(),
      intent: intent.toString(),
    );
    updatedHistory = updatedHistory.addMessage(botMsg);

    // Cập nhật context nếu có
    if (newContext != null) {
      updatedHistory = updatedHistory.updateContext({
        'waitingFor': newContext.waitingFor,
        'lastIntent': newContext.lastIntent,
        ...newContext.data,
      });
    } else if (response.context == null) {
      // Clear context nếu response không có context
      updatedHistory = updatedHistory.clearContext();
    }

    // Lưu history
    _conversations[session] = updatedHistory;

    // Cập nhật context trong response
    if (response.context == null && updatedHistory.context.isNotEmpty) {
      response = ChatBotResponse(
        text: response.text,
        type: response.type,
        movies: response.movies,
        showtimes: response.showtimes,
        suggestions: response.suggestions,
        context: ConversationContext(
          waitingFor: updatedHistory.context['waitingFor'],
          lastIntent: updatedHistory.context['lastIntent'],
          data: updatedHistory.context,
        ),
      );
    }

    return response;
  }

  /// Nhận diện intent từ message
  static Intent _recognizeIntent(String message, ConversationHistory history) {
    final msg = message.toLowerCase().trim();

    // Kiểm tra context trước - nếu đang chờ input, không cần recognize intent mới
    if (history.context['waitingFor'] != null) {
      final lastIntent = history.context['lastIntent'];
      if (lastIntent == 'search_movie') {
        return Intent.searchMovie;
      } else if (lastIntent == 'check_seats') {
        return Intent.checkSeats;
      }
      return Intent.searchMovie; // Default cho contextual response
    }

    // Now showing patterns - CHECK FIRST (more specific)
    if (_matchesAny(msg, ['phim đang chiếu', 'đang chiếu', 'phim hôm nay', 'hôm nay có phim gì', 'phim nào đang chiếu'])) {
      return Intent.movieNowShowing;
    }

    // Coming soon patterns
    if (_matchesAny(msg, ['phim sắp chiếu', 'sắp chiếu', 'coming soon', 'phim mới'])) {
      return Intent.movieComingSoon;
    }

    // Search movie patterns - "có phim gì", "phim gì" should match here
    // "Phim gì" = hiển thị tất cả phim
    if (_matchesAny(msg, ['tìm phim', 'tìm', 'search', 'phim nào', 'có phim gì', 'danh sách phim', 'phim gì', 'list phim', 'tất cả phim'])) {
      return Intent.searchMovie;
    }

    // Showtimes patterns
    if (_matchesAny(msg, ['lịch chiếu', 'khi nào', 'suất chiếu', 'showtime', 'chiếu khi nào', 'lịch chiếu tuần này'])) {
      return Intent.checkShowtimes;
    }

    // Seats patterns
    if (_matchesAny(msg, ['ghế', 'chỗ ngồi', 'ghế trống', 'ghế còn trống', 'available seats', 'còn ghế không'])) {
      return Intent.checkSeats;
    }

    // Price patterns
    if (_matchesAny(msg, ['giá', 'giá vé', 'price', 'bao nhiêu tiền', 'cost', 'phí'])) {
      return Intent.askPrice;
    }

    // Booking process patterns
    if (_matchesAny(msg, ['cách đặt', 'làm sao đặt', 'đặt vé như thế nào', 'how to book', 'hướng dẫn đặt vé'])) {
      return Intent.askBookingProcess;
    }

    // Cancel policy patterns
    if (_matchesAny(msg, ['hủy', 'cancel', 'đổi vé', 'refund', 'chính sách hủy'])) {
      return Intent.askCancelPolicy;
    }

    // Payment patterns
    if (_matchesAny(msg, ['thanh toán', 'payment', 'pay', 'trả tiền', 'phương thức thanh toán'])) {
      return Intent.askPaymentMethods;
    }

    // Cinemas patterns
    if (_matchesAny(msg, ['rạp', 'cinema', 'theater', 'rạp nào', 'rạp chiếu'])) {
      return Intent.askCinemas;
    }

    // Help patterns
    if (_matchesAny(msg, ['giúp', 'help', 'hướng dẫn', 'faq', 'câu hỏi thường gặp'])) {
      return Intent.askHelp;
    }

    // Greeting patterns - CHECK LAST (less specific)
    // Chỉ match greeting nếu message ngắn và chỉ chứa greeting words
    final greetingWords = ['xin chào', 'hello', 'hi', 'chào', 'hey', 'chào bạn'];
    if (_matchesAny(msg, greetingWords)) {
      // Chỉ match nếu message chỉ chứa greeting words (không có từ khác)
      final words = msg.split(' ');
      final isOnlyGreeting = words.every((word) => 
        greetingWords.any((gw) => gw.contains(word) || word.contains(gw.split(' ').first))
      );
      if (isOnlyGreeting && words.length <= 3) {
        return Intent.greeting;
      }
    }

    // Coming soon patterns
    if (_matchesAny(msg, ['phim sắp chiếu', 'sắp chiếu', 'coming soon', 'phim mới'])) {
      return Intent.movieComingSoon;
    }

    // Showtimes patterns
    if (_matchesAny(msg, ['lịch chiếu', 'khi nào', 'suất chiếu', 'showtime', 'chiếu khi nào', 'lịch chiếu tuần này'])) {
      return Intent.checkShowtimes;
    }

    // Seats patterns
    if (_matchesAny(msg, ['ghế', 'chỗ ngồi', 'ghế trống', 'ghế còn trống', 'available seats', 'còn ghế không'])) {
      return Intent.checkSeats;
    }

    // Price patterns
    if (_matchesAny(msg, ['giá', 'giá vé', 'price', 'bao nhiêu tiền', 'cost', 'phí'])) {
      return Intent.askPrice;
    }

    // Booking process patterns
    if (_matchesAny(msg, ['cách đặt', 'làm sao đặt', 'đặt vé như thế nào', 'how to book', 'hướng dẫn đặt vé'])) {
      return Intent.askBookingProcess;
    }

    // Cancel policy patterns
    if (_matchesAny(msg, ['hủy', 'cancel', 'đổi vé', 'refund', 'chính sách hủy'])) {
      return Intent.askCancelPolicy;
    }

    // Payment patterns
    if (_matchesAny(msg, ['thanh toán', 'payment', 'pay', 'trả tiền', 'phương thức thanh toán'])) {
      return Intent.askPaymentMethods;
    }

    // Cinemas patterns
    if (_matchesAny(msg, ['rạp', 'cinema', 'theater', 'rạp nào', 'rạp chiếu'])) {
      return Intent.askCinemas;
    }

    // Help patterns
    if (_matchesAny(msg, ['giúp', 'help', 'hướng dẫn', 'faq', 'câu hỏi thường gặp'])) {
      return Intent.askHelp;
    }

    return Intent.unknown;
  }

  /// Extract entities từ message
  static Map<String, dynamic> _extractEntities(String message, Intent intent) {
    final entities = <String, dynamic>{};
    final msg = message.toLowerCase().trim();

    // Extract movie name
    if (intent == Intent.searchMovie || intent == Intent.checkSeats || intent == Intent.checkShowtimes) {
      final movieName = _extractMovieName(message);
      if (movieName != null) {
        entities['movie_name'] = movieName;
      }
    }

    // Extract date/time
    final datePattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-]?(\d{2,4})?');
    if (datePattern.hasMatch(msg)) {
      entities['date'] = datePattern.firstMatch(msg)?.group(0);
    }

    // Extract time
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    if (timePattern.hasMatch(msg)) {
      entities['time'] = timePattern.firstMatch(msg)?.group(0);
    }

    // Extract cinema name
    if (_matchesAny(msg, ['rạp 1', 'rạp 2', 'cinema 1', 'cinema 2'])) {
      entities['cinema'] = msg;
    }

    return entities;
  }

  /// Extract movie name từ message
  static String? _extractMovieName(String message) {
    String cleaned = message
        .replaceAll(RegExp(r'\b(tìm|phim|movie|search|về|cho|tôi|bạn|xem|ghế|trống|đang|chiếu|sắp|lịch|khi nào)\b', caseSensitive: false), '')
        .trim();
    
    if (cleaned.isEmpty || cleaned.length < 2) {
      return null;
    }
    
    return cleaned;
  }

  /// Helper: Check if message matches any pattern
  static bool _matchesAny(String message, List<String> patterns) {
    for (var pattern in patterns) {
      if (message.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  // ========== Intent Handlers ==========

  static Future<ChatBotResponse> _handleGreeting(ConversationHistory history) async {
    final isReturning = history.messages.length > 2;
    
    if (isReturning) {
      return ChatBotResponse(
        text: 'Xin chào lại! Tôi có thể giúp gì cho bạn?\n\n'
            '🎬 Tìm phim\n'
            '📅 Xem lịch chiếu\n'
            '💰 Hỏi về giá vé\n'
            '❓ Trả lời câu hỏi',
        type: ChatBotResponseType.text,
        suggestions: ['Phim đang chiếu', 'Có phim gì', 'Lịch chiếu'],
      );
    }
    
    return ChatBotResponse(
      text: 'Xin chào! Tôi là AI Agent hỗ trợ đặt vé xem phim. Tôi có thể giúp bạn:\n\n'
          '🎬 Tìm phim đang chiếu\n'
          '📅 Xem lịch chiếu\n'
          '💰 Hỏi về giá vé\n'
          '🪑 Kiểm tra ghế trống\n'
          '❓ Trả lời câu hỏi thường gặp\n\n'
          'Bạn cần hỗ trợ gì?',
      type: ChatBotResponseType.text,
      suggestions: ['Phim đang chiếu', 'Phim sắp chiếu', 'Có phim gì', 'Lịch chiếu'],
    );
  }

  static Future<ChatBotResponse> _handleSearchMovie(
    String userMessage,
    Map<String, dynamic> entities,
    ConversationHistory history,
    ConversationContext? oldContext,
  ) async {
    // Nếu đang trong context, xử lý contextual
    if (oldContext?.isWaitingForInput == true && oldContext?.waitingFor == 'movie_name') {
      return _handleContextualSearchMovie(userMessage, oldContext!);
    }

    final msg = userMessage.toLowerCase().trim();
    
    // Nếu user hỏi "có phim gì", "phim gì", "tất cả phim" → hiển thị tất cả phim
    if (_matchesAny(msg, ['có phim gì', 'phim gì', 'tất cả phim', 'danh sách phim', 'list phim'])) {
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

    final movieName = entities['movie_name'] as String?;
    
    if (movieName == null || movieName.isEmpty) {
      // Không có tên phim, hỏi lại
      return ChatBotResponse(
        text: 'Bạn muốn tìm phim nào?\n\n'
            'Vui lòng cho tôi biết:\n'
            '• Tên phim bạn muốn tìm\n'
            '• Hoặc thể loại phim\n\n'
            'Ví dụ: "Tìm phim Avengers" hoặc "Phim hành động"',
        type: ChatBotResponseType.text,
        context: ConversationContext(
          waitingFor: 'movie_name',
          lastIntent: 'search_movie',
        ),
        suggestions: ['Có phim gì', 'Phim đang chiếu'],
      );
    }

    // Tìm phim
    try {
      final allMovies = await _dbService.getAllMovies();
      final movieNameLower = movieName.toLowerCase();
      final matchedMovies = allMovies.where((movie) {
        return movie.title.toLowerCase().contains(movieNameLower) ||
               movie.genre.toLowerCase().contains(movieNameLower);
      }).toList();

      if (matchedMovies.isEmpty) {
        return ChatBotResponse(
          text: 'Không tìm thấy phim nào với từ khóa "$movieName".\n\n'
              'Bạn có thể:\n'
              '• Thử tìm với tên khác\n'
              '• Xem danh sách tất cả phim\n'
              '• Xem phim đang chiếu',
          type: ChatBotResponseType.text,
          suggestions: ['Có phim gì', 'Phim đang chiếu'],
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
  }

  static Future<ChatBotResponse> _handleContextualSearchMovie(
    String userMessage,
    ConversationContext context,
  ) async {
    String? movieName = _extractMovieName(userMessage);
    
    if (movieName == null || movieName.isEmpty) {
      String cleaned = userMessage
          .replaceAll(RegExp(r'\b(tìm|phim|movie|search|về|cho|tôi|bạn|xem|ghế|trống|đang|chiếu|sắp)\b', caseSensitive: false), '')
          .trim();
      
      if (cleaned.isNotEmpty && cleaned.length >= 2) {
        movieName = cleaned;
      }
    }
    
    if (movieName == null || movieName.isEmpty) {
      return ChatBotResponse(
        text: 'Tôi chưa hiểu rõ tên phim bạn muốn tìm.\n\n'
            'Vui lòng cho tôi biết tên phim cụ thể.\n\n'
            'Ví dụ: "Avengers", "Titanic", "Phim hành động"...',
        type: ChatBotResponseType.text,
        context: context,
      );
    }

    try {
      final allMovies = await _dbService.getAllMovies();
      final movieNameLower = movieName.toLowerCase();
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
        context: null,
      );
    }
  }

  static Future<ChatBotResponse> _handleMovieNowShowing(ConversationHistory history) async {
    try {
      final movies = await _dbService.getMoviesShowingToday();
      if (movies.isEmpty) {
        return ChatBotResponse(
          text: 'Hiện tại không có phim nào đang chiếu hôm nay. Bạn có thể xem các phim sắp chiếu nhé!',
          type: ChatBotResponseType.text,
          suggestions: ['Phim sắp chiếu', 'Có phim gì'],
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

  static Future<ChatBotResponse> _handleMovieComingSoon(ConversationHistory history) async {
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

  static Future<ChatBotResponse> _handleCheckShowtimes(
    String userMessage,
    Map<String, dynamic> entities,
    ConversationHistory history,
    ConversationContext? oldContext,
  ) async {
    try {
      final allShowtimes = await _dbService.getAllShowtimes();
      if (allShowtimes.isEmpty) {
        return ChatBotResponse(
          text: 'Hiện tại không có lịch chiếu nào.',
          type: ChatBotResponseType.text,
        );
      }

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
          suggestions: ['Phim sắp chiếu'],
        );
      }

      Set<String> movieIds = weekShowtimes.map((s) => s.movieId).toSet();
      Map<String, MovieModel?> moviesMap = {};
      
      await Future.wait(movieIds.map((movieId) async {
        final movie = await _dbService.getMovie(movieId);
        moviesMap[movieId] = movie;
      }));
      
      Map<String, Map<String, List<ShowtimeModel>>> groupedShowtimes = {};
      for (var showtime in weekShowtimes) {
        final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
        final dateKey = DateFormat('dd/MM/yyyy').format(showtimeDate);
        
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
            response += '    • $timeStr - ${showtime.price.toStringAsFixed(0)}₫\n';
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

  static Future<ChatBotResponse> _handleCheckSeats(
    String userMessage,
    Map<String, dynamic> entities,
    ConversationHistory history,
    ConversationContext? oldContext,
  ) async {
    if (oldContext?.isWaitingForInput == true && oldContext?.waitingFor == 'movie_name') {
      return _handleContextualCheckSeats(userMessage, oldContext!);
    }

    final movieName = entities['movie_name'] as String?;
    
    if (movieName == null || movieName.isEmpty) {
      return ChatBotResponse(
        text: 'Bạn muốn xem ghế trống của phim nào?\n\n'
            'Vui lòng cho tôi biết tên phim bạn muốn kiểm tra ghế ngồi.\n\n'
            'Hoặc bạn có thể xem tất cả suất chiếu còn ghế trống.',
        type: ChatBotResponseType.text,
        context: ConversationContext(
          waitingFor: 'movie_name',
          lastIntent: 'check_seats',
        ),
        suggestions: ['Xem tất cả ghế trống', 'Có phim gì'],
      );
    }

    try {
      final allMovies = await _dbService.getAllMovies();
      final movieNameLower = movieName.toLowerCase();
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
      
      return ChatBotResponse(
        text: response,
        type: ChatBotResponseType.showtimeList,
        showtimes: upcomingShowtimes,
        context: null,
      );
    } catch (e) {
      return ChatBotResponse(
        text: 'Xin lỗi, tôi không thể lấy thông tin ghế ngồi lúc này. Vui lòng thử lại sau.',
        type: ChatBotResponseType.text,
      );
    }
  }

  static Future<ChatBotResponse> _handleContextualCheckSeats(
    String userMessage,
    ConversationContext context,
  ) async {
    String? movieName = _extractMovieName(userMessage);
    
    if (movieName == null || movieName.isEmpty) {
      String cleaned = userMessage
          .replaceAll(RegExp(r'\b(tìm|phim|movie|search|về|cho|tôi|bạn|xem|ghế|trống|đang|chiếu|sắp)\b', caseSensitive: false), '')
          .trim();
      
      if (cleaned.isNotEmpty && cleaned.length >= 2) {
        movieName = cleaned;
      }
    }
    
    if (movieName == null || movieName.isEmpty) {
      return ChatBotResponse(
        text: 'Tôi chưa hiểu rõ tên phim bạn muốn kiểm tra.\n\n'
            'Vui lòng cho tôi biết tên phim cụ thể.',
        type: ChatBotResponseType.text,
        context: context,
      );
    }

    try {
      final allMovies = await _dbService.getAllMovies();
      final movieNameLower = movieName.toLowerCase();
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
          context: null,
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final upcomingShowtimes = showtimes.where((s) => s.startTime >= now && s.availableSeats.isNotEmpty).toList();
      upcomingShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));

      if (upcomingShowtimes.isEmpty) {
        return ChatBotResponse(
          text: 'Phim "${movie.title}" không còn ghế trống cho suất chiếu nào sắp tới.',
          type: ChatBotResponseType.text,
          context: null,
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
        context: null,
      );
    } catch (e) {
      return ChatBotResponse(
        text: 'Xin lỗi, tôi không thể lấy thông tin ghế ngồi lúc này. Vui lòng thử lại sau.',
        type: ChatBotResponseType.text,
        context: null,
      );
    }
  }

  static Future<ChatBotResponse> _handleAskPrice(ConversationHistory history) async {
    return ChatBotResponse(
      text: '💰 Giá vé phụ thuộc vào:\n\n'
          '• Phim bạn chọn\n'
          '• Suất chiếu (2D, 3D, IMAX)\n'
          '• Loại ghế (thường, VIP)\n\n'
          'Giá vé thường từ 50,000₫ - 200,000₫.\n\n'
          'Để biết giá chính xác, bạn hãy chọn phim và suất chiếu cụ thể nhé!',
      type: ChatBotResponseType.text,
      suggestions: ['Phim đang chiếu', 'Lịch chiếu'],
    );
  }

  static Future<ChatBotResponse> _handleAskBookingProcess(ConversationHistory history) async {
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
      suggestions: ['Phim đang chiếu', 'Lịch chiếu'],
    );
  }

  static Future<ChatBotResponse> _handleAskCancelPolicy(ConversationHistory history) async {
    return ChatBotResponse(
      text: '❌ Chính sách hủy/đổi vé:\n\n'
          '• Có thể hủy vé trước 2 giờ so với suất chiếu\n'
          '• Phí hủy: 10% giá vé\n'
          '• Không thể đổi vé, chỉ có thể hủy và đặt lại\n\n'
          'Để hủy vé, bạn vào mục "Hồ Sơ" > "Lịch Sử Đặt Vé" và chọn hủy.',
      type: ChatBotResponseType.text,
    );
  }

  static Future<ChatBotResponse> _handleAskPaymentMethods(ConversationHistory history) async {
    return ChatBotResponse(
      text: '💳 Phương thức thanh toán:\n\n'
          '• PayPal\n'
          '• Google Pay\n'
          '• ZaloPay\n\n'
          'Sau khi thanh toán thành công, bạn sẽ nhận email xác nhận đặt vé.',
      type: ChatBotResponseType.text,
    );
  }

  static Future<ChatBotResponse> _handleAskCinemas(ConversationHistory history) async {
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

  static Future<ChatBotResponse> _handleAskHelp(ConversationHistory history) async {
    return ChatBotResponse(
      text: '❓ Câu hỏi thường gặp:\n\n'
          '• "Phim đang chiếu" - Xem phim hôm nay\n'
          '• "Phim sắp chiếu" - Xem phim sắp ra mắt\n'
          '• "Tìm phim [tên]" - Tìm phim cụ thể\n'
          '• "Lịch chiếu" - Xem lịch chiếu tuần này\n'
          '• "Ghế trống" - Kiểm tra ghế còn trống\n'
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
        'Lịch chiếu',
        'Giá vé',
      ],
    );
  }

  static Future<ChatBotResponse> _handleUnknown(
    String userMessage,
    ConversationHistory history,
  ) async {
    // Thử tìm trong history xem có context không
    if (history.context.isNotEmpty) {
      final waitingFor = history.context['waitingFor'];
      if (waitingFor == 'movie_name') {
        // User đang trả lời câu hỏi về tên phim
        final lastIntent = history.context['lastIntent'];
        if (lastIntent == 'search_movie') {
          return await _handleContextualSearchMovie(userMessage, ConversationContext(
            waitingFor: 'movie_name',
            lastIntent: 'search_movie',
          ));
        } else if (lastIntent == 'check_seats') {
          return await _handleContextualCheckSeats(userMessage, ConversationContext(
            waitingFor: 'movie_name',
            lastIntent: 'check_seats',
          ));
        }
      }
    }

    // Nếu không hiểu, đưa ra gợi ý dựa trên history
    final recentIntents = history.messages
        .where((m) => m.intent != null)
        .map((m) => m.intent!)
        .toList();
    
    String suggestions = '';
    if (recentIntents.contains('search_movie') || recentIntents.contains('movieNowShowing')) {
      suggestions = '\n\nBạn có thể thử:\n• "Phim đang chiếu"\n• "Có phim gì"\n• "Lịch chiếu"';
    } else {
      suggestions = '\n\nBạn có thể:\n• Hỏi về phim đang chiếu\n• Tìm phim theo tên\n• Xem lịch chiếu\n• Hỏi về giá vé';
    }

    return ChatBotResponse(
      text: 'Xin lỗi, tôi chưa hiểu câu hỏi của bạn.$suggestions\n\n'
          'Hoặc gõ "giúp" để xem danh sách câu hỏi thường gặp.',
      type: ChatBotResponseType.text,
      suggestions: ['Phim đang chiếu', 'Có phim gì', 'Giúp'],
    );
  }

  /// Clear conversation history
  static void clearHistory(String? sessionId) {
    final session = sessionId ?? 'default';
    _conversations.remove(session);
  }
}

// Import ChatBotResponse và ConversationContext từ chatbot_service
// (Các class này sẽ được định nghĩa lại hoặc import)

