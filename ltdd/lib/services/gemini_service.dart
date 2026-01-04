// File: lib/services/gemini_service.dart
// Google Gemini Service - Tích hợp Google Gemini API vào chatbot (FREE)

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // Get API key from .env
  static String get _apiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (e) {
      print('⚠️ Error accessing GEMINI_API_KEY: $e');
      return '';
    }
  }

  // Base URL for Google Gemini API - Sử dụng v1beta với models endpoint
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Gọi Google Gemini API để tạo response (FREE)
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
      print('⚠️ Gemini API key not found in .env');
      return null;
    }

    try {
      // System prompt mặc định
      final defaultSystemPrompt = systemPrompt ?? 
        'Bạn là một chatbot hỗ trợ của hệ thống đặt vé xem phim Cinema. '
        'Bạn giúp người dùng tìm phim, xem lịch chiếu, và trả lời các câu hỏi về hệ thống. '
        'Hãy trả lời bằng tiếng Việt một cách thân thiện và hữu ích. '
        'Nếu người dùng hỏi về phim, lịch chiếu, hoặc đặt vé, hãy hướng dẫn họ sử dụng các chức năng trong app.';

      // Chuẩn bị contents (messages) cho Gemini
      final contents = <Map<String, dynamic>>[];
      
      // Thêm system instruction (Gemini không có system role riêng, nên thêm vào user message đầu tiên)
      if (context == null || context.isEmpty) {
        // Nếu không có context, thêm system prompt vào user message đầu tiên
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '$defaultSystemPrompt\n\n$userMessage'}
          ]
        });
      } else {
        // Nếu có context, thêm system prompt vào đầu
        contents.add({
          'role': 'user',
          'parts': [
            {'text': defaultSystemPrompt}
          ]
        });
        contents.add({
          'role': 'model',
          'parts': [
            {'text': 'Tôi hiểu rồi. Tôi sẽ giúp bạn với hệ thống đặt vé xem phim Cinema.'}
          ]
        });

        // Thêm context (lịch sử tin nhắn) - chỉ lấy 5 tin nhắn gần nhất
        final recentContext = context.length > 5 
            ? context.sublist(context.length - 5)
            : context;
        
        for (var msg in recentContext) {
          final isUser = msg['isUser'] == true;
          final text = msg['text'] as String? ?? '';
          if (text.isNotEmpty) {
            contents.add({
              'role': isUser ? 'user' : 'model',
              'parts': [
                {'text': text}
              ]
            });
          }
        }

        // Thêm user message hiện tại
        contents.add({
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ]
        });
      }

      // Gọi API - Thử các model mới nhất trước (Gemini 3 và 2.5)
      // Format: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
      // Sử dụng header x-goog-api-key thay vì query parameter (theo chuẩn mới)
      List<String> modelsToTry = [
        'gemini-3-flash-preview',  // Gemini 3 Flash (Preview) - Model mới nhất
        'gemini-2.5-flash',        // Gemini 2.5 Flash
        'gemini-2.5-flash-lite',   // Gemini 2.5 Flash-Lite
        'gemini-1.5-flash-001',    // Model có free tier, nhanh (fallback)
        'gemini-1.5-flash-latest', // Model có free tier, phiên bản mới nhất
        'gemini-1.5-flash',        // Model có free tier, nhanh (fallback)
        'gemini-1.0-pro',          // Model có free tier, mức nhỏ, tùy khu vực
        'gemini-1.5-pro',          // Model có free tier, mạnh hơn
      ];
      
      http.Response? response;
      String? lastError;
      
      for (var model in modelsToTry) {
        try {
          final url = '$_baseUrl/models/$model:generateContent';
          print('🔄 Trying model: $model');
          print('📡 URL: $url');
          
          response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,  // Sử dụng header thay vì query parameter
            },
            body: json.encode({
              'contents': contents,
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 500,
              },
            }),
          ).timeout(const Duration(seconds: 30));
          
          print('📊 Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            print('✅ Success with model: $model');
            break;
          } else if (response.statusCode == 429) {
            // Quota exceeded - thử model tiếp theo
            try {
              final errorData = json.decode(response.body);
              lastError = errorData['error']?['message'] ?? 'Quota exceeded';
              print('⚠️ Quota exceeded for model $model, trying next...');
            } catch (e) {
              lastError = 'Quota exceeded for model $model';
              print('⚠️ Quota exceeded for model $model');
            }
            continue;
          } else if (response.statusCode == 404) {
            // Model không tồn tại - thử model tiếp theo
            try {
              final errorData = json.decode(response.body);
              lastError = errorData['error']?['message'] ?? 'Model not found';
              print('⚠️ Model $model not found, trying next...');
            } catch (e) {
              lastError = 'Model $model not found';
              print('⚠️ Model $model not found');
            }
            continue;
          } else {
            // Lỗi khác - dừng lại
            print('❌ Error ${response.statusCode} with model $model');
            break;
          }
        } catch (e) {
          print('⚠️ Exception with model $model: $e');
          lastError = e.toString();
          continue;
        }
      }
      
      if (response == null || response.statusCode != 200) {
        print('❌ All models failed or quota exceeded');
        print('💡 Last error: $lastError');
        print('💡 Note: gemini-3-pro-preview may not have free tier. Try using gemini-1.5-flash or gemini-1.5-pro');
        return null;
      }

      print('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.isNotEmpty) {
              print('✅ Gemini response generated successfully');
              return text.trim();
            }
          }
        }
      } else {
        print('❌ Gemini API error: ${response.statusCode}');
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
        return null;
      }
    } catch (e) {
      print('❌ Error calling Gemini API: $e');
      if (e.toString().contains('TimeoutException')) {
        print('💡 Request timed out. Check internet connection.');
      } else if (e.toString().contains('SocketException')) {
        print('💡 Network error. Check internet connection.');
      }
    }

    return null;
  }
}
