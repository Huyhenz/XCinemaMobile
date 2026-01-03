// File: lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/showtime.dart';
import '../models/theater.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';
import '../widgets/auth_guard.dart';
import 'snack_selection_screen.dart';

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
  double _totalPrice = 0.0;
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

          // Xóa các ghế đã chọn nếu không còn available (đã được xử lý ở trên)
          // Ghế sẽ được mở lại tự động khi thanh toán thất bại hoặc người dùng quay lại
          // Không cần thông báo

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
        await DialogHelper.showError(context, 'Lỗi tải dữ liệu');
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
    if (_theater == null) {
      _totalPrice = 0.0;
      return;
    }
    
    // Tính tổng giá dựa trên loại ghế (đơn/cặp)
    _totalPrice = 0.0;
    for (String seat in _selectedSeats) {
      _totalPrice += _theater!.getSeatPrice(seat);
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
      await DialogHelper.showError(context, 'Lỗi: Không tìm thấy thông tin rạp chiếu');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SnackSelectionScreen(
          showtimeId: widget.showtimeId,
          cinemaId: _cinemaId!,
          selectedSeats: _selectedSeats,
          totalPrice: _totalPrice,
        ),
      ),
    ).then((_) {
      // Reload data when coming back from snack selection
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
    if (_theater == null) return const SizedBox();
    
    // Lấy loại phòng để hiển thị legend phù hợp
    final theaterType = _theater!.theaterType;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Trống', const Color(0xFF2A2A2A), theaterType),
              _buildLegendItem('Đã chọn', const Color(0xFFE50914), theaterType),
              _buildLegendItem('Đã đặt', const Color(0xFF616161), theaterType),
            ],
          ),
          if (theaterType == 'normal') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Ghế đơn', const Color(0xFF2A2A2A), 'normal', seatType: 'single'),
                _buildLegendItem('Ghế đôi', const Color(0xFF2A2A2A), 'normal', seatType: 'couple'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String theaterType, {String? seatType}) {
    final seatConfig = _getSeatConfig(theaterType, seatType ?? 'single');
    return Row(
      children: [
        Container(
          width: seatConfig['width'] as double,
          height: seatConfig['height'] as double,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(seatConfig['borderRadius'] as double),
          ),
          child: Icon(
            seatConfig['icon'] as IconData,
            color: Colors.white70,
            size: seatConfig['iconSize'] as double,
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

  // Lấy cấu hình icon và kích cỡ dựa trên loại phòng và loại ghế
  Map<String, dynamic> _getSeatConfig(String theaterType, String seatType) {
    switch (theaterType) {
      case 'vip':
        // Phòng VIP: giường đôi, kích cỡ bự (hình vuông lớn) - điều chỉnh để vừa 4 ô/hàng
        return {
          'icon': Icons.hotel,
          'width': 65.0,
          'height': 65.0,
          'iconSize': 34.0,
          'borderRadius': 10.0,
          'isWide': false, // Giường đôi là hình vuông lớn
        };
      case 'couple':
        // Phòng couple: ghế đôi dài ra (hình chữ nhật ngang dài)
        return {
          'icon': Icons.airline_seat_flat,
          'width': 70.0,
          'height': 40.0,
          'iconSize': 28.0,
          'borderRadius': 10.0,
          'isWide': true, // Ghế đôi kéo dài ngang
        };
      case 'normal':
      default:
        // Phòng thường: ghế đơn nhỏ, ghế đôi ở hàng cuối dài ra
        if (seatType == 'couple') {
          return {
            'icon': Icons.airline_seat_flat,
            'width': 60.0,
            'height': 38.0,
            'iconSize': 24.0,
            'borderRadius': 8.0,
            'isWide': true,
          };
        } else {
          return {
            'icon': Icons.event_seat,
            'width': 36.0,
            'height': 36.0,
            'iconSize': 18.0,
            'borderRadius': 6.0,
            'isWide': false,
          };
        }
    }
  }

  Widget _buildSeatMap() {
    if (_theater == null) return const SizedBox();

    final theaterType = _theater!.theaterType;
    
    // Phòng VIP và Couple: cần hiển thị lối đi ở giữa
    if (theaterType == 'vip' || theaterType == 'couple') {
      return _buildVipSeatMap();
    }

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
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: rowSeats[row]!.map((seat) => _buildSeat(seat)).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Hiển thị sơ đồ ghế cho phòng VIP và Couple với lối đi ở giữa
  Widget _buildVipSeatMap() {
    Map<String, List<String>> rowSeats = {};
    for (String seat in _theater!.seats) {
      String row = seat[0];
      rowSeats.putIfAbsent(row, () => []);
      rowSeats[row]!.add(seat);
    }

    List<String> sortedRows = rowSeats.keys.toList()..sort();
    final theaterType = _theater!.theaterType;
    
    // Tính số ghế mỗi bên (chia đều)
    int seatsPerRow = rowSeats[sortedRows.first]?.length ?? 4;
    int leftSeatsCount = seatsPerRow ~/ 2;
    int rightSeatsCount = seatsPerRow - leftSeatsCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: sortedRows.map((row) {
        // Tách ghế thành 2 nhóm: bên trái và bên phải
        List<String> leftSeats = rowSeats[row]!.where((seat) {
          final seatNum = int.tryParse(seat.substring(1)) ?? 0;
          return seatNum <= leftSeatsCount;
        }).toList()..sort();
        
        List<String> rightSeats = rowSeats[row]!.where((seat) {
          final seatNum = int.tryParse(seat.substring(1)) ?? 0;
          return seatNum > leftSeatsCount;
        }).toList()..sort();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              SizedBox(
                width: 28,
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
              const SizedBox(width: 6),
              // Bên trái: 2 giường đôi
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (leftSeats.isNotEmpty) _buildSeat(leftSeats[0]),
                    if (leftSeats.length > 1) ...[
                      const SizedBox(width: 4),
                      _buildSeat(leftSeats[1]),
                    ],
                  ],
                ),
              ),
              // Lối đi ở giữa
              Container(
                width: 30,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 2,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'LỐI ĐI',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 2,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              // Bên phải: 2 giường đôi
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (rightSeats.isNotEmpty) _buildSeat(rightSeats[0]),
                    if (rightSeats.length > 1) ...[
                      const SizedBox(width: 4),
                      _buildSeat(rightSeats[1]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeat(String seat) {
    if (_theater == null) return const SizedBox();
    
    bool isAvailable = _showtime!.availableSeats.contains(seat);
    bool isSelected = _selectedSeats.contains(seat);
    bool isBooked = !isAvailable && !isSelected;
    
    // Lấy loại ghế từ theater
    final seatType = _theater!.getSeatType(seat);
    final theaterType = _theater!.theaterType;
    final seatConfig = _getSeatConfig(theaterType, seatType);

    Color seatColor;
    if (isSelected) {
      seatColor = const Color(0xFFE50914);
    } else if (isAvailable) {
      seatColor = const Color(0xFF2A2A2A);
    } else {
      seatColor = const Color(0xFF616161);
    }

    final width = seatConfig['width'] as double;
    final height = seatConfig['height'] as double;
    final borderRadius = seatConfig['borderRadius'] as double;
    final icon = seatConfig['icon'] as IconData;
    final iconSize = seatConfig['iconSize'] as double;

    return GestureDetector(
      onTap: isAvailable ? () => _toggleSeat(seat) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isBooked
              ? Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                )
              : null,
        ),
        child: Center(
          child: isSelected
              ? Icon(Icons.check, color: Colors.white, size: iconSize * 0.9)
              : isBooked
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(borderRadius * 0.7),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: iconSize * 0.6,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white70,
                      size: iconSize,
                    ),
        ),
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