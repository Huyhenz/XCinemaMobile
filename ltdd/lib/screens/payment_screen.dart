import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/tempbooking.dart';
import '../services/database_services.dart';
import '../services/payment_service.dart';
import '../utils/booking_helper.dart';

class PaymentScreen extends StatefulWidget {
  final String showtimeId;
  final String cinemaId; // ID của rạp chiếu
  final List<String> selectedSeats;
  final double totalPrice;
  final String? voucherId;

  const PaymentScreen({
    super.key,
    required this.showtimeId,
    required this.cinemaId,
    required this.selectedSeats,
    required this.totalPrice,
    this.voucherId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  String? _tempBookingId;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'paypal'; // Default to PayPal
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _createTempBooking();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createTempBooking() async {
    try {
      int now = DateTime.now().millisecondsSinceEpoch;
      TempBookingModel temp = TempBookingModel(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid,
        showtimeId: widget.showtimeId,
        seats: widget.selectedSeats,
        createdAt: now,
        expiryTime: now + 600000, // 10 minutes
      );
      _tempBookingId = await DatabaseService().saveTempBooking(temp);
      setState(() {});
    } catch (e) {
      print('Error creating temp booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi tạo booking tạm thời'),
            backgroundColor: Color(0xFFE50914),
          ),
        );
        Navigator.pop(context);
      }
    }
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
        case 'googlepay':
          paymentMethod = PaymentMethod.googlePay;
          break;
        case 'zalopay':
          paymentMethod = PaymentMethod.zaloPay;
          break;
        default:
          paymentMethod = PaymentMethod.paypal;
      }

      // Process payment using PaymentService
      PaymentResult result = await PaymentService.processPayment(
        method: paymentMethod,
        amount: widget.totalPrice,
        description: 'Đặt vé xem phim - ${widget.selectedSeats.length} ghế',
        currency: 'VND',
        context: context,
      );

      if (result.success && result.transactionId != null) {
        TempBookingModel? temp = await DatabaseService().getTempBooking(_tempBookingId!);
        if (temp != null) {
          String userId = FirebaseAuth.instance.currentUser!.uid;

          // Create booking
          BookingModel booking = BookingModel(
            id: '',
            userId: temp.userId,
            showtimeId: temp.showtimeId,
            cinemaId: widget.cinemaId,
            seats: temp.seats,
            totalPrice: widget.totalPrice,
            finalPrice: widget.totalPrice,
            voucherId: widget.voucherId,
            status: 'confirmed',
          );
          String bookingId = await DatabaseService().saveBooking(booking);

          // Create payment record
          PaymentModel payment = PaymentModel(
            id: '',
            bookingId: bookingId,
            cinemaId: widget.cinemaId,
            amount: widget.totalPrice,
            status: 'success',
            transactionId: result.transactionId,
            paymentMethod: _selectedPaymentMethod,
          );
          await DatabaseService().savePayment(payment);

          // Delete temp booking (không add seats back vì đã confirm)
          await DatabaseService().deleteTempBooking(_tempBookingId!, addBackSeats: false);

          // Tạo notification
          await BookingHelper.createBookingSuccessNotification(
            userId: userId,
            bookingId: bookingId,
            booking: booking,
          );

          // Sync seats để cập nhật trạng thái
          await DatabaseService().syncShowtimeSeats(booking.showtimeId);

          if (mounted) {
            _showSuccessDialog();
          }
        }
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFE50914),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error handling payment: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vé của bạn đã được đặt thành công',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Về Trang Chủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    if (_tempBookingId == null) {
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
              _buildOrderSummary(),
              _buildPaymentMethods(),
              _buildTimer(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildOrderSummary() {
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
            'Chi Tiết Đơn Hàng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Số ghế', '${widget.selectedSeats.length}'),
          _buildSummaryRow('Ghế đã chọn', widget.selectedSeats.join(', ')),
          const Divider(color: Color(0xFF2A2A2A), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'vi_VN').format(widget.totalPrice)}đ',
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
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
            'googlepay',
            'Google Pay',
            'Thanh toán qua Google Pay',
            Icons.payment,
            const Color(0xFF4285F4), // Google blue
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