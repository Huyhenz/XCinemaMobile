import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/tempbooking.dart';
import '../models/showtime.dart';
import '../models/movie.dart';
import '../models/voucher.dart';
import '../models/snack.dart';
import '../services/database_services.dart';
import '../services/payment_service.dart';
import '../services/email_service.dart';
import '../services/points_service.dart';
import '../utils/booking_helper.dart';
import '../utils/dialog_helper.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String showtimeId;
  final String cinemaId; // ID của rạp chiếu
  final List<String> selectedSeats;
  final double totalPrice;
  final String? voucherId;
  final Map<String, int>? selectedSnacks; // snackId -> quantity

  const PaymentScreen({
    super.key,
    required this.showtimeId,
    required this.cinemaId,
    required this.selectedSeats,
    required this.totalPrice,
    this.voucherId,
    this.selectedSnacks,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  String? _tempBookingId;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'paypal'; // Default to PayPal
  late AnimationController _pulseController;
  
  // Thông tin phim và lịch chiếu
  ShowtimeModel? _showtime;
  MovieModel? _movie;
  bool _isLoadingData = true;
  
  // Thông tin ghế từ temp booking
  List<String> _selectedSeats = [];
  
  // Voucher
  String? _voucherCode;
  VoucherModel? _selectedVoucher;
  List<Map<String, dynamic>> _userVouchers = [];
  double _discount = 0.0;
  double _finalPrice = 0.0;
  String? _appliedVoucherName; // Tên voucher đã áp dụng
  String? _discountType; // 'percent' hoặc 'fixed' để hiển thị
  
  // Snacks
  Map<String, SnackModel> _snackMap = {}; // snackId -> SnackModel

  @override
  void initState() {
    super.initState();
    // Khởi tạo với ghế từ widget (fallback)
    _selectedSeats = List.from(widget.selectedSeats);
    _loadData();
    _createTempBooking();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _finalPrice = widget.totalPrice;
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      // Load showtime
      _showtime = await DatabaseService().getShowtime(widget.showtimeId);
      if (_showtime != null) {
        // Load movie
        _movie = await DatabaseService().getMovie(_showtime!.movieId);
      }
      
      // Load ghế từ temp booking nếu có
      if (_tempBookingId != null) {
        await _loadTempBooking();
      } else {
        // Fallback to widget.selectedSeats
        _selectedSeats = widget.selectedSeats;
      }
      
      // Load voucher đã đổi của user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          _userVouchers = await PointsService().getUserRedeemedVouchers(userId);
        } catch (e) {
          print('⚠️ Error loading user vouchers (non-critical): $e');
          _userVouchers = []; // Continue without vouchers
        }
      }
      
      // Load snacks nếu có
      if (widget.selectedSnacks != null && widget.selectedSnacks!.isNotEmpty) {
        try {
          final allSnacks = await DatabaseService().getAllSnacks();
          for (var snack in allSnacks) {
            if (widget.selectedSnacks!.containsKey(snack.id)) {
              _snackMap[snack.id] = snack;
            }
          }
        } catch (e) {
          print('⚠️ Error loading snacks: $e');
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createTempBooking() async {
    try {
      int now = DateTime.now().millisecondsSinceEpoch;
      
      // Sử dụng _selectedSeats (đã được khởi tạo từ widget.selectedSeats)
      // Nếu _selectedSeats rỗng, sử dụng widget.selectedSeats
      final seatsToSave = _selectedSeats.isNotEmpty ? _selectedSeats : widget.selectedSeats;
      
      TempBookingModel temp = TempBookingModel(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid,
        showtimeId: widget.showtimeId,
        seats: seatsToSave,
        createdAt: now,
        expiryTime: now + 600000, // 10 minutes
      );
      _tempBookingId = await DatabaseService().saveTempBooking(temp);
      
      print('🎫 Created temp booking $_tempBookingId with seats: $seatsToSave');
      
      // Load lại temp booking để đảm bảo có dữ liệu mới nhất
      if (_tempBookingId != null) {
        await _loadTempBooking();
      }
      
      setState(() {});
    } catch (e) {
      print('Error creating temp booking: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi tạo booking tạm thời');
        Navigator.pop(context);
      }
    }
  }
  
  Future<void> _loadTempBooking() async {
    if (_tempBookingId == null) return;
    
    try {
      final tempBooking = await DatabaseService().getTempBooking(_tempBookingId!);
      if (tempBooking != null && tempBooking.seats.isNotEmpty) {
        setState(() {
          _selectedSeats = tempBooking.seats;
        });
        print('🎫 Loaded seats from temp booking: $_selectedSeats (${_selectedSeats.length} seats)');
      } else {
        print('⚠️ Temp booking has no seats, using widget.selectedSeats');
        // Fallback to widget.selectedSeats if temp booking has no seats
        if (widget.selectedSeats.isNotEmpty) {
          setState(() {
            _selectedSeats = widget.selectedSeats;
          });
        }
      }
    } catch (e) {
      print('Error loading temp booking: $e');
      // Fallback to widget.selectedSeats if temp booking load fails
      if (widget.selectedSeats.isNotEmpty) {
        setState(() {
          _selectedSeats = widget.selectedSeats;
        });
      }
    }
  }

  Future<void> _applyVoucher() async {
    VoucherModel? voucher;
    VoucherModel? voucherForDropdown; // Voucher từ _userVouchers để dùng cho dropdown

    // Ưu tiên voucher đã chọn từ dropdown
    if (_selectedVoucher != null) {
      voucher = _selectedVoucher;
      voucherForDropdown = _selectedVoucher; // Đã có trong dropdown
    } else if (_voucherCode != null && _voucherCode!.isNotEmpty) {
      // Nếu không có voucher từ dropdown, thử load từ mã
      voucher = await DatabaseService().getVoucher(_voucherCode!);
      // Kiểm tra xem voucher này có trong danh sách user vouchers không
      if (voucher != null) {
        for (var item in _userVouchers) {
          final userVoucher = item['voucher'] as VoucherModel;
          if (userVoucher.id == voucher!.id) {
            // Tìm thấy trong user vouchers, sử dụng instance từ _userVouchers
            voucherForDropdown = userVoucher;
            break;
          }
        }
        // Nếu không tìm thấy trong user vouchers, voucherForDropdown sẽ là null
      }
    }

    if (voucher == null) {
      await DialogHelper.showError(context, 'Vui lòng chọn voucher hoặc nhập mã voucher');
      return;
    }

    // Kiểm tra voucher còn hạn không
    final now = DateTime.now().millisecondsSinceEpoch;
    if (voucher.expiryDate < now) {
      await DialogHelper.showError(context, 'Voucher đã hết hạn!');
      return;
    }

    if (!voucher.isActive) {
      await DialogHelper.showError(context, 'Voucher không còn hoạt động!');
      return;
    }

    setState(() {
      double basePrice = widget.totalPrice;
      if (voucher!.type == 'percent') {
        // Giảm theo phần trăm
        _discount = basePrice * (voucher.discount / 100);
        _discountType = 'percent';
      } else {
        // Giảm theo số tiền cố định
        _discount = voucher.discount;
        _discountType = 'fixed';
      }
      _voucherCode = voucher.id; // Lưu mã voucher
      _appliedVoucherName = voucher.id; // Lưu tên voucher để hiển thị
      // Chỉ set _selectedVoucher nếu voucher này có trong dropdown items (_userVouchers)
      // Sử dụng voucherForDropdown để đảm bảo cùng instance với items trong dropdown
      _selectedVoucher = voucherForDropdown; // null nếu không có trong _userVouchers
      _finalPrice = basePrice - _discount;
      if (_finalPrice < 0) _finalPrice = 0; // Đảm bảo giá không âm
    });

    await DialogHelper.showSuccess(context, 'Áp dụng voucher thành công!');
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Convert selected payment method to PaymentMethod enum
      PaymentMethod paymentMethod;
      switch (_selectedPaymentMethod) {
        case 'paypal':
          paymentMethod = PaymentMethod.paypal;
          break;
        case 'vnpay':
          paymentMethod = PaymentMethod.vnpay;
          break;
        case 'zalopay':
          paymentMethod = PaymentMethod.zaloPay;
          break;
        default:
          paymentMethod = PaymentMethod.paypal;
      }

      // Process payment using PaymentService với giá đã áp dụng voucher
      PaymentResult result = await PaymentService.processPayment(
        method: paymentMethod,
        amount: _finalPrice,
        description: 'Đặt vé xem phim - ${_selectedSeats.length} ghế',
        currency: 'VND',
        context: context,
      );

      if (result.success && result.transactionId != null) {
        TempBookingModel? temp = await DatabaseService().getTempBooking(_tempBookingId!);
        if (temp != null) {
          String userId = FirebaseAuth.instance.currentUser!.uid;

          // Create booking
          // Chỉ set finalPrice khi có voucher và giá cuối cùng khác giá gốc
          final double? bookingFinalPrice = (_voucherCode != null && _finalPrice != widget.totalPrice) 
              ? _finalPrice 
              : null;
          
          // Convert selected payment method string to string for database
          // _selectedPaymentMethod is already a string ('paypal', 'vnpay', 'zalopay')
          String paymentMethodStr = _selectedPaymentMethod;
          
          BookingModel booking = BookingModel(
            id: '',
            userId: temp.userId,
            showtimeId: temp.showtimeId,
            cinemaId: widget.cinemaId,
            seats: _selectedSeats.isNotEmpty ? _selectedSeats : temp.seats,
            totalPrice: widget.totalPrice,
            finalPrice: bookingFinalPrice,
            voucherId: _voucherCode,
            status: 'confirmed',
            paymentMethod: paymentMethodStr,
            bookedAt: DateTime.now().millisecondsSinceEpoch,
            snacks: widget.selectedSnacks,
          );
          String bookingId = await DatabaseService().saveBooking(booking);

          // Create payment record
          PaymentModel payment = PaymentModel(
            id: '',
            bookingId: bookingId,
            cinemaId: widget.cinemaId,
            amount: _finalPrice,
            status: 'success',
            transactionId: result.transactionId,
            paymentMethod: paymentMethodStr,
          );
          await DatabaseService().savePayment(payment);

          // Đánh dấu voucher đã sử dụng nếu có
          if (_voucherCode != null && _voucherCode!.isNotEmpty) {
            try {
              await PointsService().markVoucherAsUsed(userId, _voucherCode!);
            } catch (e) {
              print('⚠️ Error marking voucher as used: $e');
            }
          }

          // Tích điểm khi đặt vé thành công (3-4 điểm ngẫu nhiên)
          try {
            await PointsService().addPointsForBooking(userId);
          } catch (e) {
            print('⚠️ Error adding points for booking: $e');
          }

          // Delete temp booking (không add seats back vì đã confirm)
          await DatabaseService().deleteTempBooking(_tempBookingId!, addBackSeats: false);

          // Gửi email xác nhận và tạo notification
          bool emailSent = false;
          String? userEmail;
          String? emailError;
          
          try {
            // Lấy thông tin user để gửi email
            final user = await DatabaseService().getUser(userId);
            if (user != null && user.email != null && user.email!.isNotEmpty) {
              userEmail = user.email;
              // Gửi email xác nhận
              emailSent = await EmailService.sendBookingConfirmationEmail(
                userEmail: user.email!,
                userName: user.name ?? 'Khách hàng',
                booking: booking,
                bookingId: bookingId,
              );

              if (emailSent) {
                print('✅ Email xác nhận đã được gửi thành công đến ${user.email}');
                // Tạo notification xác nhận email đã được gửi
                await BookingHelper.createBookingSuccessNotification(
                  userId: userId,
                  bookingId: bookingId,
                  booking: booking,
                );
                // Tạo thêm notification về email
                await DatabaseService().createNotification(
                  userId: userId,
                  title: 'Email xác nhận đã được gửi',
                  message: 'Email xác nhận đặt vé đã được gửi đến ${user.email}',
                  type: 'system',
                );
              } else {
                print('⚠️ Không thể gửi email (SMTP chưa được cấu hình hoặc có lỗi)');
                emailError = 'SMTP chưa được cấu hình. Vui lòng kiểm tra file .env';
                // Vẫn tạo notification dù email không gửi được
                await BookingHelper.createBookingSuccessNotification(
                  userId: userId,
                  bookingId: bookingId,
                  booking: booking,
                );
                // Tạo notification cảnh báo về email
                await DatabaseService().createNotification(
                  userId: userId,
                  title: 'Không thể gửi email xác nhận',
                  message: 'Email xác nhận không thể gửi được. Vui lòng kiểm tra cấu hình SMTP.',
                  type: 'warning',
                );
              }
            } else {
              print('⚠️ User không có email, chỉ tạo notification');
              emailError = 'Tài khoản chưa có email';
              // Tạo notification nếu không có email
              await BookingHelper.createBookingSuccessNotification(
                userId: userId,
                bookingId: bookingId,
                booking: booking,
              );
            }
          } catch (e) {
            print('❌ Lỗi khi gửi email hoặc tạo notification: $e');
            emailError = 'Lỗi khi gửi email: ${e.toString()}';
            // Vẫn tạo notification cơ bản nếu có lỗi
            try {
              await BookingHelper.createBookingSuccessNotification(
                userId: userId,
                bookingId: bookingId,
                booking: booking,
              );
            } catch (notifError) {
              print('❌ Lỗi tạo notification: $notifError');
            }
          }

          // Sync seats để cập nhật trạng thái
          await DatabaseService().syncShowtimeSeats(booking.showtimeId);

          // Navigate to success screen after processing booking
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(
                  transactionId: result.transactionId,
                  message: 'Vé của bạn đã được đặt thành công',
                  emailSent: emailSent,
                  userEmail: userEmail,
                  emailError: emailError,
                ),
              ),
            );
          }
        }
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
          // Navigate to failure screen instead of showing SnackBar
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentFailureScreen(
                message: result.message,
                isCancelled: false,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error handling payment: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        // Navigate to failure screen instead of showing SnackBar
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentFailureScreen(
              message: 'Lỗi: $e',
              isCancelled: false,
            ),
          ),
        );
      }
    }
  }

  // Removed _showSuccessDialog - now using PaymentSuccessScreen instead

  Future<void> _handleCancel() async {
    if (_tempBookingId != null) {
      await DatabaseService().deleteTempBooking(_tempBookingId!);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tempBookingId == null || _isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) async {
        if (!didPop && !_isProcessing) {
          await _handleCancel();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isProcessing ? null : _handleCancel,
          ),
          title: const Text(
            'Thanh Toán',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildMovieInfo(),
              _buildOrderSummary(),
              _buildVoucherSection(),
              _buildPaymentMethods(),
              _buildTimer(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildMovieInfo() {
    if (_movie == null || _showtime == null) {
      return const SizedBox.shrink();
    }
    
    final showtimeDate = DateTime.fromMillisecondsSinceEpoch(_showtime!.startTime);
    final formattedDate = DateFormat('dd/MM/yyyy').format(showtimeDate);
    final formattedTime = DateFormat('HH:mm').format(showtimeDate);
    
    // Debug: Kiểm tra selectedSeats
    print('🎫 PaymentScreen - _selectedSeats: $_selectedSeats');
    print('🎫 PaymentScreen - _selectedSeats.length: ${_selectedSeats.length}');
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông Tin Phim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Tên phim', _movie!.title),
          _buildSummaryRow('Lịch chiếu', '$formattedDate - $formattedTime'),
          _buildSummaryRow('Số ghế', _selectedSeats.isEmpty 
            ? 'Chưa chọn ghế' 
            : '${_selectedSeats.length} ghế'),
          if (_selectedSeats.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSummaryRow('Ghế đã chọn', _selectedSeats.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi Tiết Thanh Toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Hiển thị snacks nếu có
          if (widget.selectedSnacks != null && widget.selectedSnacks!.isNotEmpty && _snackMap.isNotEmpty) ...[
            const Text(
              'Bắp Nước',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.selectedSnacks!.entries.map((entry) {
              final snack = _snackMap[entry.key];
              if (snack == null) return const SizedBox.shrink();
              final quantity = entry.value;
              final snackTotal = snack.price * quantity;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${snack.name} x$quantity',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(snackTotal)}đ',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 16),
          ],
          
          _buildSummaryRow('Tổng tiền', '${NumberFormat('#,###', 'vi_VN').format(widget.totalPrice)}đ'),
          if (_discount > 0 && _appliedVoucherName != null) ...[
            // Hiển thị thông tin giảm giá với voucher
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giảm giá (Voucher: $_appliedVoucherName)',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _discountType == 'percent'
                            ? '-${_selectedVoucher?.discount.toStringAsFixed(0) ?? (_discount / widget.totalPrice * 100).toStringAsFixed(0)}%'
                            : '-${NumberFormat('#,###', 'vi_VN').format(_discount)}đ',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiết kiệm: ${NumberFormat('#,###', 'vi_VN').format(_discount)}đ',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(color: Color(0xFF2A2A2A), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'vi_VN').format(_finalPrice)}đ',
                style: const TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Dropdown chọn voucher đã đổi
          if (_userVouchers.isNotEmpty) ...[
            DropdownButtonFormField<VoucherModel>(
              value: _selectedVoucher,
              decoration: const InputDecoration(
                labelText: 'Chọn voucher đã đổi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard, color: Color(0xFFE50914)),
                labelStyle: TextStyle(color: Colors.white),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: _userVouchers.map((item) {
                final voucher = item['voucher'] as VoucherModel;
                return DropdownMenuItem<VoucherModel>(
                  value: voucher,
                  child: Text(
                    '${voucher.id} - ${voucher.type == 'percent' ? 'Giảm ${voucher.discount}%' : 'Giảm ${voucher.discount.toStringAsFixed(0)}đ'}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoucher = value;
                  if (value != null) {
                    _voucherCode = value.id;
                    // Tự động áp dụng voucher khi chọn từ dropdown
                    _applyVoucher();
                  } else {
                    // Reset voucher khi bỏ chọn
                    _discount = 0.0;
                    _finalPrice = widget.totalPrice;
                    _appliedVoucherName = null;
                    _discountType = null;
                    _voucherCode = null;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Hoặc nhập mã voucher',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Text field nhập mã voucher
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _voucherCode = value;
                      _selectedVoucher = null; // Clear selection khi nhập mã
                      // Reset discount khi thay đổi mã
                      if (value.isEmpty) {
                        _discount = 0.0;
                        _finalPrice = widget.totalPrice;
                        _appliedVoucherName = null;
                        _discountType = null;
                      }
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã voucher',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.local_offer, color: Color(0xFFE50914)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          // Hiển thị thông báo voucher đã áp dụng
          if (_discount > 0 && _appliedVoucherName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã áp dụng voucher: $_appliedVoucherName',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _discountType == 'percent'
                              ? 'Giảm ${_selectedVoucher?.discount.toStringAsFixed(0) ?? (_discount / widget.totalPrice * 100).toStringAsFixed(0)}% - Tiết kiệm: ${NumberFormat('#,###', 'vi_VN').format(_discount)}đ'
                              : 'Giảm ${NumberFormat('#,###', 'vi_VN').format(_discount)}đ',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Xóa voucher đã áp dụng
                      setState(() {
                        _discount = 0.0;
                        _finalPrice = widget.totalPrice;
                        _appliedVoucherName = null;
                        _discountType = null;
                        _voucherCode = null;
                        _selectedVoucher = null;
                      });
                      await DialogHelper.showSuccess(context, 'Đã xóa voucher');
                    },
                    child: const Text(
                      'Xóa',
                      style: TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phương Thức Thanh Toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodTile(
            'paypal',
            'PayPal',
            'Thanh toán qua PayPal',
            Icons.account_balance_wallet,
            const Color(0xFF0070BA), // PayPal blue
          ),
          _buildPaymentMethodTile(
            'vnpay',
            'VNPay',
            'Thanh toán qua VNPay',
            Icons.qr_code,
            const Color(0xFFEE2D24), // VNPay red
          ),
          _buildPaymentMethodTile(
            'zalopay',
            'ZaloPay',
            'Thanh toán qua ZaloPay',
            Icons.phone_android,
            const Color(0xFF0068FF), // ZaloPay blue
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color brandColor,
  ) {
    bool isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? brandColor : const Color(0xFF2A2A2A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? brandColor.withOpacity(0.2)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? brandColor : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? brandColor : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: brandColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE50914).withOpacity(0.2),
            const Color(0xFFB20710).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE50914)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFE50914),
                    const Color(0xFFB20710),
                    _pulseController.value,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian giữ ghế',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '09:45',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'XÁC NHẬN THANH TOÁN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isProcessing ? null : _handleCancel,
              child: const Text(
                'Hủy đặt vé',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}