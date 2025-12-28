// File: lib/screens/voucher_tasks_screen.dart
// Màn hình thực hiện nhiệm vụ để nhận điểm hoặc voucher

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_services.dart';
import '../models/user.dart';

class VoucherTasksScreen extends StatefulWidget {
  const VoucherTasksScreen({super.key});

  @override
  State<VoucherTasksScreen> createState() => _VoucherTasksScreenState();
}

class _VoucherTasksScreenState extends State<VoucherTasksScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  UserModel? _user;
  bool _isLoading = true;

  // Danh sách nhiệm vụ
  final List<TaskItem> _tasks = [
    TaskItem(
      id: 'task_1',
      title: 'Đặt vé xem phim lần đầu',
      description: 'Hoàn thành đặt vé đầu tiên',
      rewardType: 'points',
      rewardValue: 10,
      icon: Icons.movie,
    ),
    TaskItem(
      id: 'task_2',
      title: 'Đánh giá 3 phim',
      description: 'Đánh giá ít nhất 3 bộ phim',
      rewardType: 'points',
      rewardValue: 15,
      icon: Icons.star,
    ),
    TaskItem(
      id: 'task_3',
      title: 'Xem 5 phim',
      description: 'Xem tổng cộng 5 bộ phim',
      rewardType: 'voucher',
      rewardValue: 1,
      icon: Icons.local_movies,
    ),
    TaskItem(
      id: 'task_4',
      title: 'Giới thiệu bạn bè',
      description: 'Mời 3 người bạn đăng ký',
      rewardType: 'points',
      rewardValue: 20,
      icon: Icons.person_add,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        _user = await _dbService.getUser(userId);
        // TODO: Load task progress from database when implemented
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _claimReward(TaskItem task) async {
  //   // TODO: Implement task tracking in database
  //   // This method will be implemented when task completion tracking is added
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Nhiệm Vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : SingleChildScrollView(
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
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
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
                  const Text(
                    'Nhiệm Vụ Có Sẵn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._tasks.map((task) => _buildTaskCard(task)),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    // For now, tasks are not implemented with database tracking
    // Users can claim rewards directly for testing
    const isCompleted = false;
    const isClaimed = false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(task.icon, color: const Color(0xFF4CAF50), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
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
          // Progress bar (placeholder)
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.0,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reward info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    task.rewardType == 'points' ? Icons.stars : Icons.card_giftcard,
                    color: const Color(0xFFE50914),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.rewardType == 'points'
                        ? '${task.rewardValue} điểm'
                        : '${task.rewardValue} voucher',
                    style: const TextStyle(
                      color: Color(0xFFE50914),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: null, // Disabled until task tracking is implemented
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: const Text('Sắp Ra Mắt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String rewardType; // 'points' or 'voucher'
  final int rewardValue;
  final IconData icon;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardType,
    required this.rewardValue,
    required this.icon,
  });
}

