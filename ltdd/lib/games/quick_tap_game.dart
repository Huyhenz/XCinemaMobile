// File: lib/games/quick_tap_game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/minigame_config.dart';

class QuickTapGame extends StatefulWidget {
  final Function(int points) onComplete;
  final MinigameConfig? config;

  const QuickTapGame({super.key, required this.onComplete, this.config});

  @override
  State<QuickTapGame> createState() => _QuickTapGameState();
}

class _QuickTapGameState extends State<QuickTapGame> {
  int _score = 0;
  int _currentIndex = -1;
  List<bool> _tiles = List.generate(25, (index) => false);
  bool _gameStarted = false;
  bool _gameEnded = false;
  final Random _random = Random();

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _score = 0;
      _tiles = List.filled(25, false);
      _currentIndex = -1;
    });
    _nextTile();
  }

  int get _targetScore => widget.config?.targetScore ?? 10;

  void _nextTile() {
    if (_score >= _targetScore) {
      setState(() => _gameEnded = true);
      widget.onComplete(10);
      return;
    }

    setState(() {
      if (_currentIndex >= 0) _tiles[_currentIndex] = false;
      int newIndex;
      do {
        newIndex = _random.nextInt(25);
      } while (newIndex == _currentIndex);
      _currentIndex = newIndex;
      _tiles[_currentIndex] = true;
    });
  }

  void _tapTile(int index) {
    if (!_gameStarted || _gameEnded) return;
    if (index == _currentIndex) {
      setState(() {
        _score++;
        _tiles[index] = false;
        _currentIndex = -1;
      });
      if (_score < _targetScore) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _nextTile();
        });
      } else {
        setState(() => _gameEnded = true);
        widget.onComplete(_score);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      return Center(
        child: ElevatedButton(
          onPressed: _startGame,
          child: const Text('Bắt Đầu'),
        ),
      );
    }

    return Column(
      children: [
        Text('Điểm: $_score/$_targetScore', style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _tapTile(index),
              child: Container(
                color: _tiles[index] ? Colors.blue : Colors.grey[800],
                child: _tiles[index] ? const Icon(Icons.star, color: Colors.white) : null,
              ),
            );
          },
        ),
      ],
    );
  }
}



