// File: lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/showtime.dart';
import '../models/voucher.dart';
import '../models/theater.dart';
import '../services/database_services.dart';
import '../widgets/auth_guard.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final String showtimeId;
  const BookingScreen({super.key, required this.showtimeId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with TickerProviderStateMixin {
  ShowtimeModel? _showtime;
  TheaterModel? _theater;
  String? _cinemaId; // ID của rạp chiếu
  List<String> _selectedSeats = [];
  String? _voucherCode;
  double _totalPrice = 0.0;
  double _discount = 0.0;
  late AnimationController _animationController;
  bool _isLoading = true;

  // ✅ Stream subscription cho realtime updates
  StreamSubscription? _showtimeSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
    _listenToShowtimeChanges(); // ✅ Bắt đầu listen realtime
  }

  @override
  void dispose() {
    _animationController.dispose();
    _showtimeSubscription?.cancel(); // ✅ Cancel subscription
    super.dispose();
  }

  // ✅ Listen to realtime changes
  void _listenToShowtimeChanges() {
    _showtimeSubscription = DatabaseService()
        .listenToShowtime(widget.showtimeId)
        .listen((updatedShowtime) {
      if (updatedShowtime != null && mounted) {
        setState(() {
          // Lưu lại showtime mới
          final oldAvailableSeats = _showtime?.availableSeats ?? [];
          _showtime = updatedShowtime;

          // Xóa các ghế đã chọn nếu không còn available
          _selectedSeats.removeWhere((seat) => !updatedShowtime.availableSeats.contains(seat));

          // Hiện thông báo nếu có ghế bị mở lại
          final newlyAvailable = updatedShowtime.availableSeats
              .where((seat) => !oldAvailableSeats.contains(seat))
              .toList();

          if (newlyAvailable.isNotEmpty && oldAvailableSeats.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${newlyAvailable.length} ghế vừa được mở lại!'),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          }

          _calculateTotal();
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Đồng bộ ghế trước khi load
      await DatabaseService().syncShowtimeSeats(widget.showtimeId);

      // Load showtime data
      _showtime = await DatabaseService().getShowtime(widget.showtimeId);
      if (_showtime != null) {
        _theater = await DatabaseService().getTheater(_showtime!.theaterId);
        if (_theater != null) {
          _cinemaId = _theater!.cinemaId;
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi tải dữ liệu'),
            backgroundColor: Color(0xFFE50914),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSeat(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else if (_showtime!.availableSeats.contains(seat)) {
        _selectedSeats.add(seat);
        _animationController.forward(from: 0);
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double basePrice = _selectedSeats.length * _showtime!.price;
    _totalPrice = basePrice - _discount;
  }

  Future<void> _applyVoucher() async {
    if (_voucherCode == null || _voucherCode!.isEmpty) return;

    VoucherModel? voucher = await DatabaseService().getVoucher(_voucherCode!);
    if (voucher != null && voucher.isActive) {
      setState(() {
        double basePrice = _selectedSeats.length * _showtime!.price;
        if (voucher.type == 'percent') {
          _discount = basePrice * (voucher.discount / 100);
        } else {
          _discount = voucher.discount;
        }
        _calculateTotal();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Áp dụng voucher thành công!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã voucher không hợp lệ!'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
    }
  }

  void _proceedToPayment() async {
    // Kiểm tra đăng nhập trước khi thanh toán
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Yêu cầu đăng nhập với return path
      final isAuthenticated = await AuthGuard.requireAuth(
        context,
        returnPath: 'booking:${widget.showtimeId}',
      );
      if (!isAuthenticated) {
        return; // Người dùng hủy đăng nhập
      }
    }

    if (_cinemaId == null || _cinemaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin rạp chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          showtimeId: widget.showtimeId,
          cinemaId: _cinemaId!,
          selectedSeats: _selectedSeats,
          totalPrice: _totalPrice,
          voucherId: _voucherCode,
        ),
      ),
    ).then((_) {
      // Reload data when coming back from payment
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    if (_showtime == null || _theater == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy thông tin suất chiếu',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn Ghế',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScreen(),
          _buildSeatLegend(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFE50914),
              child: _buildSeatMap(),
            ),
          ),
          _buildVoucherSection(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE50914),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Trống', const Color(0xFF2A2A2A)),
          _buildLegendItem('Đã chọn', const Color(0xFFE50914)),
          _buildLegendItem('Đã đặt', const Color(0xFF616161)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSeatMap() {
    if (_theater == null) return const SizedBox();

    Map<String, List<String>> rowSeats = {};
    for (String seat in _theater!.seats) {
      String row = seat[0];
      rowSeats.putIfAbsent(row, () => []);
      rowSeats[row]!.add(seat);
    }

    List<String> sortedRows = rowSeats.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: sortedRows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  row,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: rowSeats[row]!.map((seat) => _buildSeat(seat)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeat(String seat) {
    bool isAvailable = _showtime!.availableSeats.contains(seat);
    bool isSelected = _selectedSeats.contains(seat);
    bool isBooked = !isAvailable && !isSelected;

    Color seatColor;
    if (isSelected) {
      seatColor = const Color(0xFFE50914);
    } else if (isAvailable) {
      seatColor = const Color(0xFF2A2A2A);
    } else {
      seatColor = const Color(0xFF616161);
    }

    return GestureDetector(
      onTap: isAvailable ? () => _toggleSeat(seat) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: isBooked
              ? Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                )
              : null,
        ),
        child: Center(
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : isBooked
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 14,
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => _voucherCode = value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập mã voucher',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.local_offer, color: Color(0xFFE50914)),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _applyVoucher,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedSeats.length} ghế đã chọn',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###', 'vi_VN').format(_totalPrice)}₫',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedSeats.isNotEmpty ? _proceedToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedSeats.isNotEmpty
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'TIẾP TỤC THANH TOÁN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}