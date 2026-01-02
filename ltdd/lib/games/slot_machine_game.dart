// File: lib/games/slot_machine_game.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:async';
import '../models/minigame_config.dart';

class SlotMachineGame extends StatefulWidget {
  final Function(int points) onComplete;
  final MinigameConfig? config;

  const SlotMachineGame({super.key, required this.onComplete, this.config});

  @override
  State<SlotMachineGame> createState() => _SlotMachineGameState();
}

class _SlotMachineGameState extends State<SlotMachineGame> with TickerProviderStateMixin {
  List<String> _reels = ['🍎', '🍋', '🍊', '🍇', '🍒', '⭐', '7️⃣'];
  List<String> _currentReels = ['?', '?', '?'];
  List<AnimationController>? _spinControllers;
  List<Animation<double>>? _spinAnimations;
  int _totalSpins = 0;
  int _score = 0;
  bool _spinning = false;
  bool _isLoading = true;
  final Random _random = Random();
  
  final int _dailySpinLimit = 5;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDailySpins();
  }

  Future<void> _loadDailySpins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final lastSpinDateKey = 'slot_spin_last_date_$userId';
      final spinCountKey = 'slot_spin_count_$userId';
      
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      final lastSpinDate = prefs.getString(lastSpinDateKey);
      
      // Nếu khác ngày thì reset lượt quay
      if (lastSpinDate == null || lastSpinDate != todayString) {
        await prefs.setString(lastSpinDateKey, todayString);
        await prefs.setInt(spinCountKey, 0);
        _totalSpins = 0;
      } else {
        _totalSpins = prefs.getInt(spinCountKey) ?? 0;
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading daily spins: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSpinCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final spinCountKey = 'slot_spin_count_$userId';
      await prefs.setInt(spinCountKey, _totalSpins);
    } catch (e) {
      print('Error saving spin count: $e');
    }
  }

  void _initializeAnimations() {
    _spinControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 30), // Nhanh hơn để quay mượt và thấy nhiều symbols
      );
    });
    
    _spinAnimations = _spinControllers!.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _spinControllers ?? []) {
      controller.dispose();
    }
    super.dispose();
  }

  int _calculateScore(List<String> reels) {
    // Kiểm tra 3 số 7
    if (reels[0] == '7️⃣' && reels[1] == '7️⃣' && reels[2] == '7️⃣') {
      return 10;
    }
    
    // Kiểm tra 3 hình giống nhau
    if (reels[0] == reels[1] && reels[1] == reels[2]) {
      return 5;
    }
    
    // Kiểm tra 2 hình giống nhau
    if (reels[0] == reels[1] || reels[1] == reels[2] || reels[0] == reels[2]) {
      return 2;
    }
    
    // Không có hình giống nhau
    return 0;
  }

  Future<void> _spin() async {
    if (_spinning || _totalSpins >= _dailySpinLimit) return;
    
    setState(() {
      _spinning = true;
    });
    
    // Bắt đầu animation quay cho cả 3 reel
    for (var controller in _spinControllers!) {
      controller.repeat();
    }
    
    // Quay trong 2-3 giây với tốc độ ngẫu nhiên
    final spinDuration = 2000 + _random.nextInt(1000);
    final reelResults = <String>[];
    
    // Mỗi reel dừng ở thời điểm khác nhau để hiệu ứng tự nhiên hơn
    final stopTimes = [
      spinDuration + _random.nextInt(200),
      spinDuration + 200 + _random.nextInt(200),
      spinDuration + 400 + _random.nextInt(200),
    ];
    
    int previousStopTime = 0;
    
    // Dừng từng reel một
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: stopTimes[i] - previousStopTime));
      previousStopTime = stopTimes[i];
      
      final result = _reels[_random.nextInt(_reels.length)];
      reelResults.add(result);
      
      // Dừng animation và set kết quả
      _spinControllers![i].stop();
      
      setState(() {
        _currentReels[i] = result;
      });
      
      // Reset controller để sẵn sàng cho lần quay tiếp theo
      await Future.delayed(const Duration(milliseconds: 100));
      _spinControllers![i].reset();
    }
    
    // Tính điểm
    final roundScore = _calculateScore(reelResults);
    setState(() {
      _score += roundScore;
      _totalSpins++;
      _spinning = false;
    });
    
    // Lưu số lượt quay
    await _saveSpinCount();
    
    // Hiển thị thông báo kết quả
    String message = '';
    if (roundScore == 10) {
      message = '🎰 JACKPOT! 3 số 7️⃣ - +10 điểm!';
    } else if (roundScore == 5) {
      message = '🎉 3 hình giống nhau - +5 điểm!';
    } else if (roundScore == 2) {
      message = '✨ 2 hình giống nhau - +2 điểm!';
    } else {
      message = '😔 Không trúng - 0 điểm';
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: roundScore > 0 ? const Color(0xFF4CAF50) : Colors.grey,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    // Kiểm tra đã hết lượt
    if (_totalSpins >= _dailySpinLimit) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onComplete(_score);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      );
    }

    return Column(
      children: [
        Text(
          'Lượt quay: $_totalSpins/$_dailySpinLimit',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Điểm: $_score',
          style: const TextStyle(
            color: Color(0xFF2196F3),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        
        // Slot machine reels với animation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              width: 90,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                border: Border.all(
                  color: _spinning && index < _currentReels.length && _currentReels[index] == '?'
                      ? Colors.amber
                      : Colors.grey[700]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 100,
                  width: 90,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Hiệu ứng quay hoặc hiển thị kết quả
                      AnimatedBuilder(
                        animation: _spinControllers![index],
                        builder: (context, child) {
                          if (_spinning && _spinControllers![index].isAnimating) {
                            // Tính toán offset để tạo hiệu ứng quay liên tục
                            final controllerValue = _spinControllers![index].value;
                            // Sử dụng tổng số lần lặp để tính offset
                            final totalCycles = controllerValue * 10; // Tăng tốc độ để thấy rõ các symbols
                            final offset = (totalCycles % 1.0) * 100;
                            
                            return Positioned(
                              top: -offset,
                              left: 0,
                              right: 0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Hiển thị nhiều symbols để thấy rõ hiệu ứng quay
                                  // Tạo đủ để quay liên tục (10-12 symbols)
                                  ...List.generate(12, (i) {
                                    // Tính toán index dựa trên vị trí và số chu kỳ đã quay
                                    final cycleOffset = totalCycles.floor();
                                    final symbolIndex = (i + cycleOffset) % _reels.length;
                                    return SizedBox(
                                      height: 100,
                                      width: 90,
                                      child: Center(
                                        child: Text(
                                          _reels[symbolIndex],
                                          style: const TextStyle(fontSize: 48),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          } else {
                            // Hiển thị kết quả khi đã dừng
                            return Positioned.fill(
                              child: Center(
                                child: Text(
                                  _currentReels[index],
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        
        // Hướng dẫn
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            children: [
              const Text(
                'Quy tắc tính điểm:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRuleItem('3 số 7️⃣', '10 điểm'),
              _buildRuleItem('3 hình giống nhau', '5 điểm'),
              _buildRuleItem('2 hình giống nhau', '2 điểm'),
              _buildRuleItem('Không trúng', '0 điểm'),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Nút quay
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _spinning || _totalSpins >= _dailySpinLimit ? null : _spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _totalSpins >= _dailySpinLimit
                  ? Colors.grey[800]
                  : const Color(0xFFE50914),
              disabledBackgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _spinning ? Icons.refresh : Icons.casino,
              color: Colors.white,
            ),
            label: Text(
              _spinning
                  ? 'Đang quay...'
                  : _totalSpins >= _dailySpinLimit
                      ? 'Đã hết lượt hôm nay'
                      : 'Quay',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String label, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          Text(
            points,
            style: const TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}



