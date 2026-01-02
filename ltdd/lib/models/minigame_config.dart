// File: lib/models/minigame_config.dart
// Model cho cấu hình minigame

import 'package:firebase_database/firebase_database.dart';

class MinigameConfig {
  final String gameId;
  final int? maxWrongAttempts; // Số lần sai tối đa (cho trò đoán chữ)
  final int? timeLimitSeconds; // Thời gian giới hạn mỗi câu (giây)
  final int? maxLevel; // Level tối đa
  final int? targetScore; // Điểm mục tiêu
  final Map<String, dynamic>? customSettings; // Các cài đặt tùy chỉnh khác

  MinigameConfig({
    required this.gameId,
    this.maxWrongAttempts,
    this.timeLimitSeconds,
    this.maxLevel,
    this.targetScore,
    this.customSettings,
  });

  factory MinigameConfig.fromMap(Map<dynamic, dynamic> data, String gameId) {
    return MinigameConfig(
      gameId: gameId,
      maxWrongAttempts: data['maxWrongAttempts']?.toInt(),
      timeLimitSeconds: data['timeLimitSeconds']?.toInt(),
      maxLevel: data['maxLevel']?.toInt(),
      targetScore: data['targetScore']?.toInt(),
      customSettings: data['customSettings'] != null
          ? Map<String, dynamic>.from(data['customSettings'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxWrongAttempts': maxWrongAttempts,
      'timeLimitSeconds': timeLimitSeconds,
      'maxLevel': maxLevel,
      'targetScore': targetScore,
      'customSettings': customSettings,
    };
  }

  // Default configs cho từng trò chơi
  static MinigameConfig getDefault(String gameId) {
    switch (gameId) {
      case 'word_guess':
        return MinigameConfig(
          gameId: gameId,
          maxWrongAttempts: 5,
          timeLimitSeconds: null,
        );
      case 'math_puzzle':
        return MinigameConfig(
          gameId: gameId,
          timeLimitSeconds: 5,
          maxLevel: 5,
        );
      case 'quick_tap':
        return MinigameConfig(
          gameId: gameId,
          targetScore: 10,
        );
      case 'memory_match':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 6,
        );
      case 'color_sequence':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 5,
        );
      case 'speed_reaction':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 10,
        );
      case 'pattern_match':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 4,
        );
      case 'number_memory':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 4,
        );
      case 'rhythm_tap':
        return MinigameConfig(
          gameId: gameId,
          targetScore: 10,
        );
      case 'slot_machine':
        return MinigameConfig(
          gameId: gameId,
          maxLevel: 5,
        );
      default:
        return MinigameConfig(gameId: gameId);
    }
  }
}

