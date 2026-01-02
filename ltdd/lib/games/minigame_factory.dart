// File: lib/games/minigame_factory.dart
// Factory để tạo minigames

import 'package:flutter/material.dart';
import '../models/minigame.dart';
import '../models/minigame_config.dart';
import 'word_guess_game.dart';
import 'memory_match_game.dart';
import 'quick_tap_game.dart';
import 'slot_machine_game.dart';

class MinigameFactory {
  static List<MinigameItem> getAllGames() {
    return [
      MinigameItem(
        id: 'word_guess',
        name: 'Đoán Chữ',
        description: 'Đoán từ khóa dựa trên gợi ý về phim ảnh',
        type: MinigameType.wordGuess,
        rewardPoints: 15,
        icon: Icons.quiz,
      ),
      MinigameItem(
        id: 'memory_match',
        name: 'Trí Nhớ Siêu Đẳng',
        description: 'Nhớ và khớp các cặp hình ảnh',
        type: MinigameType.memoryMatch,
        rewardPoints: 12,
        icon: Icons.memory,
      ),
      MinigameItem(
        id: 'quick_tap',
        name: 'Nhấn Nhanh',
        description: 'Nhấn vào các ô sáng càng nhanh càng tốt',
        type: MinigameType.quickTap,
        rewardPoints: 10,
        icon: Icons.touch_app,
      ),
      MinigameItem(
        id: 'slot_machine',
        name: 'Máy Đánh Bạc',
        description: 'Quay và trúng thưởng',
        type: MinigameType.slotMachine,
        rewardPoints: 8,
        icon: Icons.casino,
      ),
    ];
  }

  static Widget? getGameWidget(
    MinigameType type,
    Function(int points) onComplete, {
    MinigameConfig? config,
  }) {
    switch (type) {
      case MinigameType.wordGuess:
        return WordGuessGame(onComplete: onComplete, config: config);
      case MinigameType.memoryMatch:
        return MemoryMatchGame(onComplete: onComplete, config: config);
      case MinigameType.quickTap:
        return QuickTapGame(onComplete: onComplete, config: config);
      case MinigameType.slotMachine:
        return SlotMachineGame(onComplete: onComplete, config: config);
      default:
        return null;
    }
  }
}



