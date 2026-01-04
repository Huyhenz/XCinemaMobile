// File: lib/screens/voucher_tasks_screen.dart
// Màn hình thực hiện nhiệm vụ để nhận điểm hoặc voucher

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_services.dart';
import '../services/points_service.dart';
import '../utils/dialog_helper.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/showtime.dart';
import '../models/movie_rating.dart';
import '../models/voucher.dart';

class VoucherTasksScreen extends StatefulWidget {
  const VoucherTasksScreen({super.key});

  @override
  State<VoucherTasksScreen> createState() => _VoucherTasksScreenState();
}

class _VoucherTasksScreenState extends State<VoucherTasksScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PointsService _pointsService = PointsService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  UserModel? _user;
  bool _isLoading = true;
  bool _isAdmin = false; // Check if user is admin
  List<TaskItem> _tasks = [];
  Set<String> _claimedTaskIds = {}; // Track claimed tasks
  Map<String, TaskProgress> _taskProgress = {}; // Track task progress
  List<VoucherModel> _taskVouchers = []; // Vouchers yêu cầu task
  Map<String, List<VoucherModel>> _taskToVouchers = {}; // Map task ID -> vouchers

  // Pool các nhiệm vụ có sẵn (sẽ được chọn ngẫu nhiên)
  final List<TaskItem> _taskPool = [
    TaskItem(
      id: 'task_1',
      title: 'Đặt vé xem phim lần đầu',
      description: 'Hoàn thành đặt vé đầu tiên',
      rewardType: 'points',
      rewardValue: 15,
      icon: Icons.movie,
      requirementType: 'count_booking',
      requirementValue: 1,
    ),
    TaskItem(
      id: 'task_2',
      title: 'Đánh giá 3 phim',
      description: 'Đánh giá ít nhất 3 bộ phim',
      rewardType: 'points',
      rewardValue: 20,
      icon: Icons.star,
      requirementType: 'count_rating',
      requirementValue: 3,
    ),
    TaskItem(
      id: 'task_3',
      title: 'Xem 5 phim',
      description: 'Xem tổng cộng 5 bộ phim',
      rewardType: 'points',
      rewardValue: 25,
      icon: Icons.local_movies,
      requirementType: 'count_booking',
      requirementValue: 5,
    ),
    TaskItem(
      id: 'task_4',
      title: 'Giới thiệu bạn bè',
      description: 'Mời 3 người bạn đăng ký',
      requirementType: 'manual', // Cần kiểm tra thủ công
      requirementValue: 3,
      rewardType: 'points',
      rewardValue: 30,
      icon: Icons.person_add,
    ),
    TaskItem(
      id: 'task_5',
      title: 'Xem phim cuối tuần',
      description: 'Đặt vé xem phim vào thứ 7 hoặc Chủ nhật',
      rewardType: 'points',
      rewardValue: 12,
      icon: Icons.calendar_today,
      requirementType: 'weekend_booking',
      requirementValue: 1,
    ),
    TaskItem(
      id: 'task_6',
      title: 'Đặt vé phim mới',
      description: 'Xem một bộ phim mới ra mắt trong tuần',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 18,
      icon: Icons.new_releases,
    ),
    TaskItem(
      id: 'task_7',
      title: 'Chia sẻ phim yêu thích',
      description: 'Chia sẻ 1 bộ phim bạn yêu thích với bạn bè',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 10,
      icon: Icons.share,
    ),
    TaskItem(
      id: 'task_8',
      title: 'Đánh giá phim chi tiết',
      description: 'Viết đánh giá chi tiết cho 1 bộ phim (tối thiểu 50 từ)',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 15,
      icon: Icons.rate_review,
    ),
    TaskItem(
      id: 'task_9',
      title: 'Xem phim 3D',
      description: 'Trải nghiệm xem phim định dạng 3D',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 22,
      icon: Icons.video_library,
    ),
    TaskItem(
      id: 'task_10',
      title: 'Đặt combo bắp nước',
      description: 'Đặt vé kèm combo bắp nước',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 14,
      icon: Icons.fastfood,
    ),
    TaskItem(
      id: 'task_11',
      title: 'Xem phim ban đêm',
      description: 'Đặt vé suất chiếu sau 20:00',
      rewardType: 'points',
      rewardValue: 16,
      icon: Icons.nightlight_round,
      requirementType: 'night_booking',
      requirementValue: 1,
    ),
    TaskItem(
      id: 'task_12',
      title: 'Xem phim cùng gia đình',
      description: 'Đặt ít nhất 3 vé trong một lần',
      rewardType: 'points',
      rewardValue: 20,
      icon: Icons.family_restroom,
      requirementType: 'multi_seat_booking',
      requirementValue: 3,
    ),
    TaskItem(
      id: 'task_13',
      title: 'Khám phá thể loại mới',
      description: 'Xem phim thuộc thể loại bạn chưa từng xem',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 15,
      icon: Icons.explore,
    ),
    TaskItem(
      id: 'task_14',
      title: 'Đánh giá 5 sao',
      description: 'Đánh giá một bộ phim với 5 sao',
      rewardType: 'points',
      rewardValue: 12,
      icon: Icons.star_border,
      requirementType: 'five_star_rating',
      requirementValue: 1,
    ),
    TaskItem(
      id: 'task_15',
      title: 'Xem phim hành động',
      description: 'Xem một bộ phim thể loại hành động',
      requirementType: 'manual',
      requirementValue: 1,
      rewardType: 'points',
      rewardValue: 13,
      icon: Icons.movie_filter,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  // Khởi tạo nhiệm vụ - kiểm tra ngày và đổi nếu cần
  Future<void> _initializeTasks() async {
    await _checkAndRefreshTasks();
    _loadData();
  }

  // Kiểm tra ngày và đổi nhiệm vụ nếu qua ngày mới
  Future<void> _checkAndRefreshTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final lastUpdateKey = 'task_last_update_$userId';
      
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      final lastUpdateString = prefs.getString(lastUpdateKey);
      
      // Nếu chưa có ngày lưu hoặc ngày khác thì đổi nhiệm vụ
      if (lastUpdateString == null || lastUpdateString != todayString) {
        _selectRandomTasks();
        await prefs.setString(lastUpdateKey, todayString);
      } else {
        // Load lại nhiệm vụ đã lưu
        await _loadSavedTasks();
      }
    } catch (e) {
      print('Error checking task date: $e');
      // Fallback: chọn nhiệm vụ mới
      _selectRandomTasks();
    }
  }

  // Chọn cố định 5 nhiệm vụ từ pool (mỗi ngày)
  void _selectRandomTasks() {
    final random = Random();
    final taskCount = 5; // Cố định 5 nhiệm vụ mỗi ngày
    final shuffled = List<TaskItem>.from(_taskPool)..shuffle(random);
    _tasks = shuffled.take(taskCount).toList();
    _saveTasks(); // Lưu nhiệm vụ
  }

  // Lưu danh sách nhiệm vụ hiện tại
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final taskIdsKey = 'task_ids_$userId';
      
      final taskIds = _tasks.map((t) => t.id).toList();
      await prefs.setStringList(taskIdsKey, taskIds);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  // Load lại nhiệm vụ đã lưu
  Future<void> _loadSavedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final taskIdsKey = 'task_ids_$userId';
      
      final taskIds = prefs.getStringList(taskIdsKey);
      if (taskIds != null && taskIds.isNotEmpty) {
        _tasks = _taskPool.where((task) => taskIds.contains(task.id)).toList();
        // Đảm bảo có đủ nhiệm vụ
        if (_tasks.isEmpty) {
          _selectRandomTasks();
        }
      } else {
        _selectRandomTasks();
      }
    } catch (e) {
      print('Error loading saved tasks: $e');
      _selectRandomTasks();
    }
  }

  // Reload khi quay lại màn hình
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload progress khi quay lại để đảm bảo dữ liệu mới nhất
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && _tasks.isNotEmpty && !_isLoading) {
      _loadTaskProgress(userId);
    }
  }

  // Dialog xác nhận reset nhiệm vụ (chỉ admin)
  Future<void> _showAdminResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Nhiệm Vụ'),
        content: const Text(
          'Bạn có chắc muốn reset nhiệm vụ hôm nay không? Tất cả tiến độ sẽ bị xóa và chọn lại nhiệm vụ mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetTasks();
    }
  }

  // Reset nhiệm vụ (chỉ admin)
  Future<void> _resetTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final lastUpdateKey = 'task_last_update_$userId';
      
      // Xóa ngày update để force refresh
      await prefs.remove(lastUpdateKey);
      
      // Xóa completed tasks từ database
      if (userId != 'anonymous') {
        await _dbRef.child('users/$userId/completedTasks').remove();
      }
      
      // Chọn nhiệm vụ mới
      _selectRandomTasks();
      
      // Reload progress for tasks
      if (userId != 'anonymous') {
        setState(() {
          _claimedTaskIds.clear();
          _taskProgress.clear();
        });
        await _loadTaskProgress(userId);
        await _loadTaskVouchers(userId);
      }
      
      if (mounted) {
        await DialogHelper.showSuccess(context, '✅ Đã reset nhiệm vụ thành công!');
      }
    } catch (e) {
      print('Error resetting tasks: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi: $e');
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        _user = await _dbService.getUser(userId);
        _isAdmin = _user?.role == 'admin'; // Check admin role
        // Load completed tasks from database
        await _loadCompletedTasks(userId);
        // Load task progress
        await _loadTaskProgress(userId);
        // Load task vouchers
        await _loadTaskVouchers(userId);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load completed tasks from database
  Future<void> _loadCompletedTasks(String userId) async {
    try {
      final snapshot = await _dbRef.child('users/$userId/completedTasks').get();
      if (snapshot.exists && snapshot.value != null) {
        final completedTasks = snapshot.value;
        if (completedTasks is Map) {
          setState(() {
            _claimedTaskIds = Set<String>.from(
              completedTasks.keys.map((key) => key.toString()),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading completed tasks: $e');
    }
  }

  // Save completed task to database
  Future<void> _saveCompletedTask(String userId, String taskId) async {
    try {
      await _dbRef.child('users/$userId/completedTasks/$taskId').set(ServerValue.timestamp);
    } catch (e) {
      print('Error saving completed task: $e');
    }
  }

  // Unlock vouchers khi task hoàn thành
  Future<void> _unlockVouchersForTask(String taskId) async {
    try {
      final vouchersToUnlock = _taskVouchers.where((v) => 
        v.requiredTaskId == taskId && !v.isUnlocked
      ).toList();
      
      for (var voucher in vouchersToUnlock) {
        try {
          // Update voucher in database
          final updatedVoucher = VoucherModel(
            id: voucher.id,
            discount: voucher.discount,
            type: voucher.type,
            expiryDate: voucher.expiryDate,
            isActive: voucher.isActive,
            points: voucher.points,
            voucherType: voucher.voucherType,
            requiredTaskId: voucher.requiredTaskId,
            isUnlocked: true, // Unlock voucher
          );
          await _dbService.updateVoucher(updatedVoucher);
          print('✅ Đã mở khóa voucher ${voucher.id} cho task $taskId');
        } catch (e) {
          print('⚠️ Error unlocking voucher ${voucher.id}: $e');
        }
      }
    } catch (e) {
      print('Error unlocking vouchers for task $taskId: $e');
    }
  }

  // Load vouchers yêu cầu task và map với tasks
  Future<void> _loadTaskVouchers(String userId) async {
    try {
      final allVouchers = await _dbService.getAllVouchers();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Filter task vouchers còn hiệu lực
      _taskVouchers = allVouchers.where((voucher) {
        return voucher.isActive && 
               voucher.expiryDate > now &&
               voucher.voucherType == 'task' &&
               voucher.requiredTaskId != null;
      }).toList();

      // Map task ID với vouchers
      _taskToVouchers.clear();
      for (var voucher in _taskVouchers) {
        final taskId = voucher.requiredTaskId!;
        if (!_taskToVouchers.containsKey(taskId)) {
          _taskToVouchers[taskId] = [];
        }
        _taskToVouchers[taskId]!.add(voucher);
      }

      // Cập nhật isUnlocked cho mỗi voucher dựa trên task completion
      for (var voucher in _taskVouchers) {
        final taskId = voucher.requiredTaskId!;
        final task = _tasks.firstWhere((t) => t.id == taskId, orElse: () => TaskItem(
          id: taskId,
          title: '',
          description: '',
          rewardType: 'points',
          rewardValue: 0,
          icon: Icons.task,
          requirementType: 'manual',
          requirementValue: 0,
        ));
        
        if (task.id != '') {
          final progress = _taskProgress[taskId];
          if (progress != null && progress.isCompleted) {
            // Update voucher unlock status in list
            final index = _taskVouchers.indexWhere((v) => v.id == voucher.id);
            if (index != -1) {
              _taskVouchers[index] = VoucherModel(
                id: voucher.id,
                discount: voucher.discount,
                type: voucher.type,
                expiryDate: voucher.expiryDate,
                isActive: voucher.isActive,
                points: voucher.points,
                voucherType: voucher.voucherType,
                requiredTaskId: voucher.requiredTaskId,
                isUnlocked: true,
              );
              // Update in map too
              final mapIndex = _taskToVouchers[taskId]?.indexWhere((v) => v.id == voucher.id);
              if (mapIndex != null && mapIndex != -1) {
                _taskToVouchers[taskId]![mapIndex] = _taskVouchers[index];
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading task vouchers: $e');
    }
  }

  // Load progress cho tất cả tasks
  Future<void> _loadTaskProgress(String userId) async {
    _taskProgress.clear();
    
    for (var task in _tasks) {
      final progress = await _checkTaskProgress(task, userId);
      _taskProgress[task.id] = progress;
    }
    
    setState(() {});
  }

  // Kiểm tra tiến độ của một task
  Future<TaskProgress> _checkTaskProgress(TaskItem task, String userId) async {
    try {
      switch (task.requirementType) {
        case 'count_booking':
          final bookings = await _dbService.getBookingsByUser(userId);
          final confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();
          final current = confirmedBookings.length;
          final required = task.requirementValue;
          return TaskProgress(current: current, required: required);
          
        case 'count_rating':
          // Lấy tất cả ratings của user
          final allRatings = await _getAllRatingsByUser(userId);
          final uniqueMovieIds = allRatings.map((r) => r.movieId).toSet();
          final current = uniqueMovieIds.length;
          final required = task.requirementValue;
          return TaskProgress(current: current, required: required);
          
        case 'weekend_booking':
          final bookings = await _dbService.getBookingsByUser(userId);
          final confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();
          int weekendCount = 0;
          
          for (var booking in confirmedBookings) {
            try {
              final showtime = await _dbService.getShowtime(booking.showtimeId);
              if (showtime != null) {
                final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
                final weekday = showtimeDate.weekday;
                if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
                  weekendCount++;
                }
              }
            } catch (e) {
              print('Error checking weekend for booking ${booking.id}: $e');
            }
          }
          return TaskProgress(current: weekendCount, required: task.requirementValue);
          
        case 'night_booking':
          final bookings = await _dbService.getBookingsByUser(userId);
          final confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();
          int nightCount = 0;
          
          for (var booking in confirmedBookings) {
            try {
              final showtime = await _dbService.getShowtime(booking.showtimeId);
              if (showtime != null) {
                final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
                final hour = showtimeDate.hour;
                if (hour >= 20) { // Sau 20:00
                  nightCount++;
                }
              }
            } catch (e) {
              print('Error checking night time for booking ${booking.id}: $e');
            }
          }
          return TaskProgress(current: nightCount, required: task.requirementValue);
          
        case 'multi_seat_booking':
          final bookings = await _dbService.getBookingsByUser(userId);
          final confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();
          int multiSeatCount = 0;
          
          for (var booking in confirmedBookings) {
            if (booking.seats.length >= task.requirementValue) {
              multiSeatCount++;
            }
          }
          return TaskProgress(current: multiSeatCount > 0 ? 1 : 0, required: 1);
          
        case 'five_star_rating':
          final allRatings = await _getAllRatingsByUser(userId);
          final fiveStarRatings = allRatings.where((r) => r.rating == 5.0).toList();
          return TaskProgress(current: fiveStarRatings.length > 0 ? 1 : 0, required: 1);
          
        case 'manual':
        default:
          // Manual tasks không thể tự động kiểm tra
          return TaskProgress(current: 0, required: task.requirementValue);
      }
    } catch (e) {
      print('Error checking task progress for ${task.id}: $e');
      return TaskProgress(current: 0, required: task.requirementValue);
    }
  }

  // Helper method để lấy tất cả ratings của user
  Future<List<MovieRating>> _getAllRatingsByUser(String userId) async {
    try {
      // Load tất cả movies và check ratings
      // Cách đơn giản hơn: load tất cả ratings và filter
      final allMovies = await _dbService.getAllMovies();
      List<MovieRating> allUserRatings = [];
      
      for (var movie in allMovies) {
        try {
          final ratings = await _dbService.getRatingsByMovieAndUser(movie.id, userId);
          allUserRatings.addAll(ratings);
        } catch (e) {
          // Skip nếu lỗi
        }
      }
      
      return allUserRatings;
    } catch (e) {
      print('Error getting all ratings by user: $e');
      return [];
    }
  }

  Future<void> _claimReward(TaskItem task) async {
    if (_claimedTaskIds.contains(task.id)) {
      return; // Already claimed
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      await DialogHelper.showError(context, 'Vui lòng đăng nhập để nhận phần thưởng');
      return;
    }

    // Kiểm tra điều kiện nhiệm vụ
    final progress = _taskProgress[task.id];
    if (progress == null) {
      // Reload progress
      await _loadTaskProgress(userId);
      final updatedProgress = _taskProgress[task.id];
      if (updatedProgress == null || !updatedProgress.isCompleted) {
        await DialogHelper.showWarning(
          context,
          task.requirementType == 'manual'
              ? 'Vui lòng hoàn thành nhiệm vụ trước khi nhận thưởng'
              : 'Bạn chưa đáp ứng đủ điều kiện! (${updatedProgress?.current ?? 0}/${updatedProgress?.required ?? task.requirementValue})',
        );
        return;
      }
    } else if (!progress.isCompleted) {
      // Reload progress để đảm bảo có dữ liệu mới nhất
      await _loadTaskProgress(userId);
      final updatedProgress = _taskProgress[task.id];
      if (updatedProgress == null || !updatedProgress.isCompleted) {
        await DialogHelper.showWarning(
          context,
          task.requirementType == 'manual'
              ? 'Vui lòng hoàn thành nhiệm vụ trước khi nhận thưởng'
              : 'Bạn chưa đáp ứng đủ điều kiện! (${updatedProgress?.current ?? 0}/${updatedProgress?.required ?? task.requirementValue})',
        );
        return;
      }
    }

    try {
      setState(() => _isLoading = true);

      if (task.rewardType == 'points') {
        await _pointsService.addPoints(userId, task.rewardValue, 'Hoàn thành nhiệm vụ: ${task.title}');
      }

      // Mark task as claimed
      setState(() {
        _claimedTaskIds.add(task.id);
      });

      // Save completed task to database
      await _saveCompletedTask(userId, task.id);

      // Reload user data to update points
      _user = await _dbService.getUser(userId);
      
      // Unlock vouchers if task is completed
      await _unlockVouchersForTask(task.id);
      
      // Reload task vouchers to update unlock status
      await _loadTaskVouchers(userId);

      if (mounted) {
        await DialogHelper.showSuccess(
          context,
          task.rewardType == 'points'
              ? '🎉 Chúc mừng! Bạn đã nhận ${task.rewardValue} điểm!'
              : '🎉 Chúc mừng! Bạn đã nhận phần thưởng!',
        );
      }
    } catch (e) {
      print('Error claiming reward: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        actions: [
          // Chỉ admin mới có nút reset
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _showAdminResetDialog(),
              tooltip: 'Reset nhiệm vụ (Admin)',
            ),
        ],
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
                  
                  // Thông tin vouchers cần mở khóa
                  if (_taskVouchers.isNotEmpty) ...[
                    _buildVoucherUnlockInfo(),
                    const SizedBox(height: 24),
                  ],
                  
                  const Text(
                    'Nhiệm Vụ Có Sẵn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._tasks.where((task) => !_claimedTaskIds.contains(task.id)).map((task) => _buildTaskCard(task)),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final isClaimed = _claimedTaskIds.contains(task.id);
    final progress = _taskProgress[task.id];
    final isCompleted = progress?.isCompleted ?? false;
    final canClaim = !isClaimed && isCompleted && !_isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed 
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : isCompleted
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : const Color(0xFF2A2A2A),
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
                  color: isClaimed
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : isCompleted
                          ? const Color(0xFF4CAF50).withOpacity(0.3)
                          : const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  task.icon, 
                  color: isClaimed || isCompleted
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4CAF50).withOpacity(0.7), 
                  size: 24
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: isClaimed 
                                  ? Colors.grey[500]
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isClaimed 
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isClaimed)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          )
                        else if (isCompleted)
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        color: isClaimed 
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    // Progress text
                    if (progress != null && task.requirementType != 'manual' && !isClaimed)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tiến độ: ${progress.current}/${progress.required}',
                          style: TextStyle(
                            color: isCompleted 
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Hiển thị voucher sẽ được mở khóa khi hoàn thành task này
          if (_taskToVouchers.containsKey(task.id) && _taskToVouchers[task.id]!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFF2196F3),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mở khóa voucher khi hoàn thành:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._taskToVouchers[task.id]!.map((voucher) {
                          final isUnlocked = voucher.isUnlocked;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isUnlocked ? Icons.check_circle : Icons.lock_outline,
                                  color: isUnlocked ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${voucher.id}: ${voucher.type == 'percent' ? '${voucher.discount.toInt()}% giảm' : '${voucher.discount.toInt()}đ giảm'} ${isUnlocked ? '(Đã mở khóa)' : ''}',
                                    style: TextStyle(
                                      color: isUnlocked ? const Color(0xFF4CAF50) : Colors.white,
                                      fontSize: 12,
                                      fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: isClaimed 
                  ? 1.0 
                  : progress != null 
                      ? (progress.current / progress.required).clamp(0.0, 1.0)
                      : 0.0,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isClaimed
                        ? [Colors.grey[700]!, Colors.grey[800]!]
                        : isCompleted
                            ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
                            : [const Color(0xFFE50914).withOpacity(0.6), const Color(0xFFB20710).withOpacity(0.6)],
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
                onPressed: canClaim
                    ? () => _claimReward(task)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  disabledForegroundColor: Colors.grey[600],
                ),
                child: Text(
                  isClaimed 
                      ? 'Đã Nhận' 
                      : isCompleted 
                          ? 'Nhận Thưởng' 
                          : task.requirementType == 'manual'
                              ? 'Hoàn Thành'
                              : 'Chưa Hoàn Thành',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thông tin voucher sẽ được mở khóa
  Widget _buildVoucherUnlockInfo() {
    final unlockedCount = _taskVouchers.where((v) => v.isUnlocked).length;
    final totalCount = _taskVouchers.length;
    final lockedVouchers = _taskVouchers.where((v) => !v.isUnlocked).toList();
    
    // Đếm số task cần hoàn thành
    final requiredTaskIds = lockedVouchers.map((v) => v.requiredTaskId).whereType<String>().toSet();
    final currentTasksNeeded = requiredTaskIds.intersection(_tasks.map((t) => t.id).toSet());
    final tasksNeededCount = currentTasksNeeded.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.3),
            const Color(0xFF1976D2).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.5),
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
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voucher Chờ Mở Khóa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đã mở khóa: $unlockedCount/$totalCount voucher',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.task_alt,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tasksNeededCount > 0
                        ? 'Cần hoàn thành $tasksNeededCount nhiệm vụ để mở khóa ${lockedVouchers.length} voucher'
                        : 'Không có voucher nào cần mở khóa từ nhiệm vụ hiện tại',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (lockedVouchers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lockedVouchers.map((voucher) {
                final taskId = voucher.requiredTaskId!;
                final task = _tasks.firstWhere(
                  (t) => t.id == taskId,
                  orElse: () => TaskItem(
                    id: taskId,
                    title: 'Nhiệm vụ #$taskId',
                    description: '',
                    rewardType: 'points',
                    rewardValue: 0,
                    icon: Icons.task,
                    requirementType: 'manual',
                    requirementValue: 0,
                  ),
                );
                final progress = _taskProgress[taskId];
                final isCompleted = progress?.isCompleted ?? false;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : const Color(0xFF1A1A1A).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.lock,
                        color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${voucher.type == 'percent' ? '${voucher.discount.toInt()}%' : '${voucher.discount.toInt()}đ'} - ${task.title}',
                          style: TextStyle(
                            color: isCompleted ? Colors.white : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
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
  final String requirementType; // 'count_booking', 'count_rating', 'weekend_booking', 'night_booking', 'multi_seat_booking', 'five_star_rating', 'manual'
  final int requirementValue; // Giá trị yêu cầu (số lần, số lượng, etc.)

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardType,
    required this.rewardValue,
    required this.icon,
    required this.requirementType,
    required this.requirementValue,
  });
}

class TaskProgress {
  final int current;
  final int required;
  
  TaskProgress({
    required this.current,
    required this.required,
  });
  
  bool get isCompleted => current >= required;
  
  double get progress => required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;
}

