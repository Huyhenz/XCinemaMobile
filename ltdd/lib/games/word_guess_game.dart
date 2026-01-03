// File: lib/games/word_guess_game.dart
// Trò chơi đoán chữ

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/minigame_config.dart';
import '../utils/dialog_helper.dart';

class WordGuessGame extends StatefulWidget {
  final Function(int points) onComplete;
  final MinigameConfig? config;

  const WordGuessGame({super.key, required this.onComplete, this.config});

  @override
  State<WordGuessGame> createState() => _WordGuessGameState();
}

class _WordGuessGameState extends State<WordGuessGame> {
  final List<WordPuzzle> _puzzles = [
    WordPuzzle(
      hint: 'Bộ phim nổi tiếng về con tàu lớn nhất thế giới bị chìm vào năm 1912. Câu chuyện tình yêu cảm động giữa Jack và Rose trên chuyến tàu định mệnh.',
      answer: 'TITANIC',
      category: 'Phim tình cảm',
      imageEmoji: '🚢',
    ),
    WordPuzzle(
      hint: 'Siêu anh hùng mặc áo choàng đỏ và xanh, có chữ S trên ngực, có thể bay và có sức mạnh siêu nhiên. Đến từ hành tinh Krypton, tên thật là Clark Kent.',
      answer: 'SUPERMAN',
      category: 'Phim hành động',
      imageEmoji: '🦸',
    ),
    WordPuzzle(
      hint: 'Quái vật khổng lồ màu xanh lá, cao như tòa nhà chọc trời, xuất hiện lần đầu ở Nhật Bản năm 1954. Có thể phun ra tia lửa và phá hủy cả thành phố.',
      answer: 'GODZILLA',
      category: 'Phim khoa học viễn tưởng',
      imageEmoji: '🦖',
    ),
    WordPuzzle(
      hint: 'Những robot khổng lồ từ hành tinh Cybertron có thể biến đổi thành xe hơi, máy bay, và nhiều phương tiện khác. Có các nhân vật nổi tiếng như Optimus Prime và Bumblebee.',
      answer: 'TRANSFORMERS',
      category: 'Phim hành động',
      imageEmoji: '🤖',
    ),
    WordPuzzle(
      hint: 'Cậu bé mồ côi có vết sẹo hình tia chớp trên trán, học phép thuật tại trường Hogwarts. Bạn thân là Ron Weasley và Hermione Granger. Tên bắt đầu bằng chữ H.',
      answer: 'HARRY POTTER',
      category: 'Phim phiêu lưu',
      imageEmoji: '⚡',
    ),
    WordPuzzle(
      hint: 'Nhóm siêu anh hùng gồm Iron Man, Captain America, Thor, Hulk, Black Widow và Hawkeye. Tên bắt đầu bằng chữ A và có nghĩa là "Người báo thù".',
      answer: 'AVENGERS',
      category: 'Phim hành động',
      imageEmoji: '🦾',
    ),
    WordPuzzle(
      hint: 'Siêu anh hùng giàu có tên Bruce Wayne, mặc bộ đồ dơi màu đen, sống ở thành phố Gotham. Không có siêu năng lực nhưng có trí tuệ và công nghệ cao.',
      answer: 'BATMAN',
      category: 'Phim hành động',
      imageEmoji: '🦇',
    ),
    WordPuzzle(
      hint: 'Bộ phim về công viên giải trí với những con khủng long được tạo ra từ DNA cổ đại. Có các loài như T-Rex, Velociraptor, và Brachiosaurus.',
      answer: 'JURASSIC PARK',
      category: 'Phim khoa học viễn tưởng',
      imageEmoji: '🦕',
    ),
    WordPuzzle(
      hint: 'Bộ phim khoa học viễn tưởng về chiến tranh giữa các hành tinh, có các chiến binh sử dụng thanh kiếm ánh sáng. Có câu nói nổi tiếng "May the Force be with you".',
      answer: 'STAR WARS',
      category: 'Phim khoa học viễn tưởng',
      imageEmoji: '⭐',
    ),
    WordPuzzle(
      hint: 'Bộ phim kể về 300 chiến binh Sparta dũng cảm chiến đấu chống lại đế quốc Ba Tư. Nhân vật chính là vua Leonidas, được đóng bởi Gerard Butler.',
      answer: '300',
      category: 'Phim hành động',
      imageEmoji: '⚔️',
    ),
  ];

  late WordPuzzle _currentPuzzle;
  String _userGuess = '';
  int _currentPuzzleIndex = 0;
  int _score = 0;
  int _wrongAttempts = 0;
  bool _gameStarted = false;
  bool _gameEnded = false;
  
  int get _maxWrongAttempts => widget.config?.maxWrongAttempts ?? 5;

  @override
  void initState() {
    super.initState();
    _currentPuzzle = _puzzles[0];
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameEnded = false;
      _currentPuzzleIndex = 0;
      _score = 0;
      _wrongAttempts = 0;
      _userGuess = '';
      _currentPuzzle = _puzzles[0];
    });
  }

  Future<void> _checkAnswer() async {
    if (_userGuess.toUpperCase().trim() == _currentPuzzle.answer.toUpperCase()) {
      setState(() {
        _score += 10;
        _wrongAttempts = 0; // Reset wrong attempts khi đúng
        _userGuess = '';
        _currentPuzzleIndex++;
        
        if (_currentPuzzleIndex >= _puzzles.length) {
          _endGame();
        } else {
          _currentPuzzle = _puzzles[_currentPuzzleIndex];
        }
      });
    } else {
      setState(() {
        _wrongAttempts++;
      });
      
      if (_wrongAttempts >= _maxWrongAttempts) {
        // Thua vì sai quá nhiều lần
        await DialogHelper.showError(context, 'Bạn đã sai quá $_maxWrongAttempts lần! Trò chơi kết thúc.');
        _endGame();
      } else {
        await DialogHelper.showWarning(context, 'Sai rồi! Bạn còn ${_maxWrongAttempts - _wrongAttempts} lần thử.');
      }
    }
  }

  void _endGame() {
    setState(() {
      _gameEnded = true;
      _gameStarted = false;
    });
    widget.onComplete(_score);
  }

  String _getMaskedAnswer() {
    return _currentPuzzle.answer.replaceAll(RegExp(r'[A-Z0-9]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted && !_gameEnded) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.quiz, size: 64, color: Color(0xFF2196F3)),
            const SizedBox(height: 16),
            const Text(
              'Đoán Chữ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đọc gợi ý và đoán từ khóa về phim ảnh!',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Bắt Đầu', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );
    }

    if (_gameEnded) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              _score >= 30 ? Icons.celebration : Icons.emoji_events,
              size: 64,
              color: _score >= 30 ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Kết Quả: $_score điểm',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _score >= 30
                  ? 'Xuất sắc! Bạn đã đoán đúng tất cả!'
                  : 'Chúc bạn may mắn lần sau!',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${_currentPuzzleIndex + 1}/${_puzzles.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Điểm: $_score',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Sai: $_wrongAttempts/$_maxWrongAttempts',
                    style: TextStyle(
                      color: _wrongAttempts >= _maxWrongAttempts 
                          ? Colors.red 
                          : Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPuzzleIndex + 1) / _puzzles.length,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 24),
          
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentPuzzle.category,
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Hint with emoji/image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji/Icon hint if available
                if (_currentPuzzle.imageEmoji != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0F0F0F),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _currentPuzzle.imageEmoji!,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Gợi ý:',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currentPuzzle.hint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Answer input
          TextField(
            onChanged: (value) {
              setState(() {
                _userGuess = value;
              });
            },
            onSubmitted: (_) => _checkAnswer(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Nhập câu trả lời...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userGuess.isEmpty ? null : _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[800],
              ),
              child: const Text('Kiểm Tra', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class WordPuzzle {
  final String hint;
  final String answer;
  final String category;
  final String? imageEmoji; // Emoji hoặc icon đại diện cho đề tài

  WordPuzzle({
    required this.hint,
    required this.answer,
    required this.category,
    this.imageEmoji,
  });
}



