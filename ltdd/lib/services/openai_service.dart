// File: lib/services/openai_service.dart
// OpenAI Service - Tích hợp OpenAI GPT API vào chatbot

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  // Get API key from .env
  static String get _apiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing OPENAI_API_KEY: $e');
      return '';
    }
  }

  // Base URL for OpenAI API
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Gọi OpenAI API để tạo response
  /// 
  /// [userMessage]: Câu hỏi của người dùng
  /// [context]: Context của cuộc trò chuyện (List<Map<String, dynamic>> với 'text' và 'isUser')
  /// [systemPrompt]: System prompt để hướng dẫn AI
  /// 
  /// Returns: Response text từ AI, hoặc null nếu có lỗi
  static Future<String?> generateResponse({
    required String userMessage,
    List<Map<String, dynamic>>? context,
    String? systemPrompt,
  }) async {
    // Kiểm tra API key
    if (_apiKey.isEmpty) {
      print('⚠️ OpenAI API key not found in .env');
      return null;
    }

    try {
      // System prompt mặc định
      final defaultSystemPrompt = systemPrompt ?? 
        'Bạn là một chatbot hỗ trợ của hệ thống đặt vé xem phim Cinema. '
        'Bạn giúp người dùng tìm phim, xem lịch chiếu, và trả lời các câu hỏi về hệ thống. '
        'Hãy trả lời bằng tiếng Việt một cách thân thiện và hữu ích. '
        'Nếu người dùng hỏi về phim, lịch chiếu, hoặc đặt vé, hãy hướng dẫn họ sử dụng các chức năng trong app.';

      // Chuẩn bị messages
      final messages = <Map<String, String>>[];
      
      // Thêm system message
      messages.add({
        'role': 'system',
        'content': defaultSystemPrompt,
      });

      // Thêm context (lịch sử tin nhắn) nếu có
      if (context != null && context.isNotEmpty) {
        // Chỉ lấy 5 tin nhắn gần nhất để không vượt quá token limit
        final recentContext = context.length > 5 
            ? context.sublist(context.length - 5)
            : context;
        
        for (var msg in recentContext) {
          final isUser = msg['isUser'] == true;
          final text = msg['text'] as String? ?? '';
          if (text.isNotEmpty) {
            messages.add({
              'role': isUser ? 'user' : 'assistant',
              'content': text,
            });
          }
        }
      }

      // Thêm user message hiện tại
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Gọi API
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo', // Hoặc 'gpt-4' nếu có
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null && content.isNotEmpty) {
          print('✅ OpenAI response generated successfully');
          return content.trim();
        }
      } else {
        print('❌ OpenAI API error: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Parse error message
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            print('Error: ${errorData['error']['message']}');
          }
        } catch (e) {
          // Ignore parse error
        }
      }
    } catch (e) {
      print('❌ Error calling OpenAI API: $e');
      if (e.toString().contains('TimeoutException')) {
        print('💡 Request timed out. Check internet connection.');
      } else if (e.toString().contains('SocketException')) {
        print('💡 Network error. Check internet connection.');
      }
    }

    return null;
  }
}
