// File: lib/models/minigame.dart
// Models cho minigame

import 'package:flutter/material.dart';

enum MinigameType {
  wordGuess,      // Đoán chữ
  memoryMatch,    // Trí nhớ siêu đẳng
  quickTap,       // Nhấn nhanh
  slotMachine,    // Máy đánh bạc
}

class MinigameItem {
  final String id;
  final String name;
  final String description;
  final MinigameType type;
  final int rewardPoints;
  final IconData icon;

  MinigameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rewardPoints,
    required this.icon,
  });
}

