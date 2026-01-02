// File: lib/games/memory_match_game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/minigame_config.dart';

class MemoryMatchGame extends StatefulWidget {
  final Function(int points) onComplete;
  final MinigameConfig? config;

  const MemoryMatchGame({super.key, required this.onComplete, this.config});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  List<int> _cards = [];
  List<bool> _flipped = [];
  int _firstIndex = -1;
  int _matches = 0;
  bool _canFlip = true;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    List<int> pairs = [1, 2, 3, 4, 5, 6];
    _cards = [...pairs, ...pairs]..shuffle(Random());
    _flipped = List.filled(12, false);
    _matches = 0;
    _firstIndex = -1;
    _canFlip = true;
    _gameEnded = false;
  }

  void _flipCard(int index) {
    if (!_canFlip || _flipped[index]) return;

    setState(() {
      _flipped[index] = true;

      if (_firstIndex == -1) {
        _firstIndex = index;
      } else {
        _canFlip = false;
        if (_cards[_firstIndex] == _cards[index]) {
          _matches++;
          _canFlip = true;
          _firstIndex = -1;
          if (_matches == 6) {
            _gameEnded = true;
            widget.onComplete(12);
          }
        } else {
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              _flipped[_firstIndex] = false;
              _flipped[index] = false;
              _firstIndex = -1;
              _canFlip = true;
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameEnded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Chúc mừng!', style: TextStyle(color: Colors.white, fontSize: 24)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _flipCard(index),
          child: Container(
            decoration: BoxDecoration(
              color: _flipped[index] ? const Color(0xFF2196F3) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _flipped[index]
                  ? Text(
                      '${_cards[index]}',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    )
                  : const Icon(Icons.question_mark, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}



