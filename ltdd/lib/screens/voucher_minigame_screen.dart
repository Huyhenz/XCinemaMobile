// File: lib/screens/voucher_minigame_screen.dart
// Màn hình minigame để nhận điểm hoặc voucher

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../services/database_services.dart';
import '../services/points_service.dart';
import '../models/user.dart';

class VoucherMinigameScreen extends StatefulWidget {
  const VoucherMinigameScreen({super.key});

  @override
  State<VoucherMinigameScreen> createState() => _VoucherMinigameScreenState();
}

class _VoucherMinigameScreenState extends State<VoucherMinigameScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PointsService _pointsService = PointsService();
  
  UserModel? _user;
  bool _isLoading = false;
  int _score = 0;
  final int _target = 10;
  bool _gameStarted = false;
  bool _gameEnded = false;
  List<bool> _tiles = List.generate(25, (index) => false);
  int _currentIndex = -1;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _dbService.getUser(userId);
        setState(() => _user = user);
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameEnded = false;
      _score = 0;
      _tiles = List.generate(25, (index) => false);
      _currentIndex = -1;
    });
    _nextTile();
  }

  void _nextTile() {
    if (_score >= _target) {
      _endGame();
      return;
    }

    setState(() {
      // Reset previous tile
      if (_currentIndex >= 0) {
        _tiles[_currentIndex] = false;
      }
      
      // Choose new random tile
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
      
      if (_score >= _target) {
        _endGame();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _nextTile();
        });
      }
    }
  }

  void _endGame() {
    setState(() {
      _gameEnded = true;
      _gameStarted = false;
      if (_currentIndex >= 0) {
        _tiles[_currentIndex] = false;
      }
      _currentIndex = -1;
    });
  }

  Future<void> _claimReward() async {
    if (_score < _target) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Random reward: 70% chance points, 30% chance voucher
      final rewardType = _random.nextDouble() < 0.7 ? 'points' : 'voucher';
      
      if (rewardType == 'points') {
        // Give 5-10 random points
        final points = 5 + _random.nextInt(6);
        await _pointsService.addPoints(userId, points, 'Minigame');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã nhận $points điểm!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          await _loadUser();
        }
      } else {
        // Give random voucher
        final voucher = await _pointsService.getRandomFreeVoucher();
        if (voucher != null) {
          await _pointsService.addRandomVoucherToUser(userId, voucher.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đã nhận voucher ${voucher.id}!'),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        } else {
          // Fallback to points if no voucher available
          final points = 5 + _random.nextInt(6);
          await _pointsService.addPoints(userId, points, 'Minigame');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đã nhận $points điểm!'),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
            await _loadUser();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Minigame',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points display
            if (_user != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      '${_user!.points} điểm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Game instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Hướng Dẫn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nhấn vào các ô sáng để ghi điểm!\nMục tiêu: $_target điểm\nHoàn thành để nhận điểm hoặc voucher ngẫu nhiên!',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Điểm',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[700],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Mục Tiêu',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_target',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Game grid
            if (_gameStarted || _gameEnded)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: GridView.builder(
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
                        decoration: BoxDecoration(
                          color: _tiles[index]
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tiles[index]
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: _tiles[index]
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2196F3).withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: _tiles[index]
                            ? const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Center(
                  child: Text(
                    'Nhấn "Bắt Đầu" để chơi!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Game end result
            if (_gameEnded)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _score >= _target
                      ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _score >= _target ? Icons.celebration : Icons.sentiment_dissatisfied,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _score >= _target ? 'Chúc Mừng!' : 'Chưa Đạt!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _score >= _target
                          ? 'Bạn đã hoàn thành thử thách!\nNhận phần thưởng ngay!'
                          : 'Bạn cần đạt $_target điểm để nhận thưởng.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            if (!_gameStarted && !_gameEnded)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Bắt Đầu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (_gameEnded)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _startGame,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Chơi Lại',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_score >= _target) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _claimReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Nhận Thưởng',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

