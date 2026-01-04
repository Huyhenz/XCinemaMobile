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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE50914).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Không tìm thấy thông tin suất chiếu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.2),
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
          'Chọn Ghế',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE50914).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Làm mới',
            ),
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
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE50914).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                ),
              ],
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildLegendItem('Trống', const Color(0xFF2A2A2A), theaterType),
              _buildLegendItem('Đã chọn', const Color(0xFFE50914), theaterType),
              _buildLegendItem('Đã đặt', const Color(0xFF616161), theaterType),
            ],
          ),
          if (theaterType == 'normal') ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF2A2A2A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
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
    final isSelected = color == const Color(0xFFE50914);
    
    // Giảm kích thước icon trong legend để tránh overflow
    final iconWidth = (theaterType == 'vip' || theaterType == 'couple') 
        ? (seatConfig['width'] as double) * 0.7
        : (seatConfig['width'] as double);
    final iconHeight = (theaterType == 'vip' || theaterType == 'couple')
        ? (seatConfig['height'] as double) * 0.7
        : (seatConfig['height'] as double);
    final iconSize = (theaterType == 'vip' || theaterType == 'couple')
        ? (seatConfig['iconSize'] as double) * 0.7
        : (seatConfig['iconSize'] as double);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconWidth,
          height: iconHeight,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : color,
            borderRadius: BorderRadius.circular(seatConfig['borderRadius'] as double),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            seatConfig['icon'] as IconData,
            color: Colors.white70,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
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
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : seatColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isSelected
              ? Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                )
              : isBooked
                  ? Border.all(
                      color: Colors.grey[700]!,
                      width: 1,
                    )
                  : Border.all(
                      color: const Color(0xFF2A2A2A).withOpacity(0.5),
                      width: 1,
                    ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE50914).withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
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
    final isEnabled = _selectedSeats.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE50914).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE50914).withOpacity(0.2),
                            const Color(0xFFB20710).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_seat,
                        color: Color(0xFFE50914),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedSeats.length} ghế đã chọn',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${NumberFormat('#,###', 'vi_VN').format(_totalPrice)}₫',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.2),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                border: isEnabled
                    ? Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? _proceedToPayment : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'TIẾP TỤC THANH TOÁN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}