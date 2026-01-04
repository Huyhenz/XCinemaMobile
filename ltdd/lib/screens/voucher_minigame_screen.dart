// File: lib/screens/voucher_minigame_screen.dart
// Màn hình minigame để nhận điểm hoặc voucher

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../services/database_services.dart';
import '../services/points_service.dart';
import '../utils/dialog_helper.dart';
import '../models/user.dart';
import '../models/minigame.dart';
import '../models/minigame_config.dart';
import '../games/minigame_factory.dart';

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
  MinigameItem? _currentGame;
  bool _gameCompleted = false;
  int _earnedPoints = 0;
  bool _isAdmin = false;
  Map<String, MinigameConfig> _gameConfigs = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initializeGame();
  }

  Future<void> _loadUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _dbService.getUser(userId);
        setState(() {
          _user = user;
          _isAdmin = user?.role == 'admin';
        });
        // Load configs nếu là admin hoặc để sử dụng trong game
        await _loadGameConfigs();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  // Load cấu hình cho tất cả trò chơi
  Future<void> _loadGameConfigs() async {
    try {
      final allGames = MinigameFactory.getAllGames();
      for (var game in allGames) {
        final config = await _dbService.getMinigameConfig(game.id);
        if (config != null) {
          _gameConfigs[game.id] = config;
        } else {
          // Sử dụng default config nếu chưa có trong database
          _gameConfigs[game.id] = MinigameConfig.getDefault(game.id);
        }
      }
      setState(() {});
    } catch (e) {
      print('Error loading game configs: $e');
    }
  }

  // Lấy config cho trò chơi hiện tại
  MinigameConfig? getCurrentGameConfig() {
    if (_currentGame == null) return null;
    return _gameConfigs[_currentGame!.id] ?? MinigameConfig.getDefault(_currentGame!.id);
  }

  // Khởi tạo trò chơi - kiểm tra ngày và chọn trò chơi
  Future<void> _initializeGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final lastGameDateKey = 'minigame_last_date_$userId';
      final currentGameKey = 'minigame_current_game_$userId';
      final adminOverrideKey = 'minigame_admin_override_$userId';
      
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      final lastGameDate = prefs.getString(lastGameDateKey);
      final isAdminOverride = prefs.getBool(adminOverrideKey) ?? false;
      
      // Nếu là admin override, giữ nguyên trò chơi đã chọn
      if (isAdminOverride && _isAdmin) {
        final savedGameId = prefs.getString(currentGameKey);
        if (savedGameId != null) {
          final allGames = MinigameFactory.getAllGames();
          _currentGame = allGames.firstWhere(
            (game) => game.id == savedGameId,
            orElse: () => allGames.first,
          );
          setState(() {});
          return;
        }
      }
      
      // Nếu chưa có ngày lưu hoặc ngày khác thì chọn trò chơi mới
      if (lastGameDate == null || lastGameDate != todayString) {
        _selectDailyGame();
        await prefs.setString(lastGameDateKey, todayString);
        // Reset admin override khi qua ngày mới
        await prefs.setBool(adminOverrideKey, false);
      } else {
        // Load lại trò chơi đã chọn hôm nay
        final savedGameId = prefs.getString(currentGameKey);
        if (savedGameId != null) {
          final allGames = MinigameFactory.getAllGames();
          _currentGame = allGames.firstWhere(
            (game) => game.id == savedGameId,
            orElse: () => allGames.first,
          );
        } else {
          _selectDailyGame();
        }
      }
      
      setState(() {});
    } catch (e) {
      print('Error initializing game: $e');
      _selectDailyGame();
    }
  }

  // Chọn trò chơi ngẫu nhiên cho ngày hôm nay
  Future<void> _selectDailyGame() async {
    final allGames = MinigameFactory.getAllGames();
    final random = Random();
    final selectedGame = allGames[random.nextInt(allGames.length)];
    
    setState(() {
      _currentGame = selectedGame;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await prefs.setString('minigame_current_game_$userId', selectedGame.id);
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  // Đổi trò chơi (chỉ dành cho admin)
  Future<void> _changeGame() async {
    final allGames = MinigameFactory.getAllGames();
    final currentGameId = _currentGame?.id;

    // Hiển thị dialog để chọn trò chơi
    final selectedGame = await showDialog<MinigameItem>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Chọn Trò Chơi',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allGames.length,
            itemBuilder: (context, index) {
              final game = allGames[index];
              final isCurrentGame = game.id == currentGameId;
              return ListTile(
                leading: Icon(game.icon, color: isCurrentGame ? Colors.blue : Colors.white),
                title: Text(
                  game.name,
                  style: TextStyle(
                    color: isCurrentGame ? Colors.blue : Colors.white,
                    fontWeight: isCurrentGame ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  game.description,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: isCurrentGame
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  Navigator.pop(context, game);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (selectedGame != null) {
      setState(() {
        _currentGame = selectedGame;
        _gameCompleted = false;
        _earnedPoints = 0;
      });
      
      // Lưu trò chơi đã chọn (admin override daily game)
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        await prefs.setString('minigame_current_game_$userId', selectedGame.id);
        await prefs.setBool('minigame_admin_override_$userId', true);
      } catch (e) {
        print('Error saving admin game selection: $e');
      }

      await DialogHelper.showSuccess(context, '✅ Đã đổi sang trò chơi: ${selectedGame.name}');
    }
  }

  // Xử lý khi hoàn thành trò chơi
  Future<void> _onGameComplete(int points) async {
    setState(() {
      _gameCompleted = true;
      _earnedPoints = points;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && points > 0) {
        setState(() => _isLoading = true);
        
        // Thưởng điểm dựa trên điểm số của trò chơi
        final rewardPoints = _currentGame!.rewardPoints;
        await _pointsService.addPoints(
          userId, 
          rewardPoints, 
          'Minigame: ${_currentGame!.name}'
        );
        
        await _loadUser();
        
        if (mounted) {
          await DialogHelper.showSuccess(context, '🎉 Chúc mừng! Bạn đã nhận $rewardPoints điểm!');
        }
      }
    } catch (e) {
      print('Error claiming reward: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGame == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Trò Chơi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Nút đổi trò chơi cho admin
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                tooltip: 'Đổi trò chơi (Admin)',
                onPressed: _changeGame,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points display
            if (_user != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.stars, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_user!.points}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'điểm',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Game info card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentGame!.icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentGame!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentGame!.description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Phần thưởng: ${_currentGame!.rewardPoints} điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Game widget
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MinigameFactory.getGameWidget(
                _currentGame!.type,
                _onGameComplete,
                config: getCurrentGameConfig(),
              ) ?? const SizedBox(),
            ),

            // Game completed message
            if (_gameCompleted)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Hoàn Thành!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn đã hoàn thành trò chơi và nhận ${_currentGame!.rewardPoints} điểm!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
