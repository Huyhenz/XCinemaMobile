// Updated: lib/screens/payment_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/payment.dart';
import '../models/tempbooking.dart';
import '../services/database_services.dart';

class PaymentScreen extends StatefulWidget {
  final String showtimeId;
  final List<String> selectedSeats;
  final double totalPrice;
  final String? voucherId;

  const PaymentScreen({
    super.key,
    required this.showtimeId,
    required this.selectedSeats,
    required this.totalPrice,
    this.voucherId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _tempBookingId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _createTempBooking();
  }

  Future<void> _createTempBooking() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    TempBookingModel temp = TempBookingModel(
      id: '', // Generate in service
      userId: FirebaseAuth.instance.currentUser!.uid,
      showtimeId: widget.showtimeId,
      seats: widget.selectedSeats,
      createdAt: now,
      expiryTime: now + 600000, // 10 phút
    );
    _tempBookingId = await DatabaseService().saveTempBooking(temp);
    setState(() {}); // Optional, if need to update UI
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    // Simulate payment process (integrate real payment gateway here, e.g., VNPay)
    await Future.delayed(const Duration(seconds: 2)); // Fake delay
    bool paymentSuccess = true; // Simulate success; in real, check gateway response

    if (paymentSuccess) {
      // Convert temp to booking
      TempBookingModel? temp = await DatabaseService().getTempBooking(_tempBookingId!);
      if (temp != null) {
        BookingModel booking = BookingModel(
          id: '', // Generate in service
          userId: temp.userId,
          showtimeId: temp.showtimeId,
          seats: temp.seats,
          totalPrice: widget.totalPrice, // Or calculate again
          finalPrice: widget.totalPrice, // Assuming no further discount
          voucherId: widget.voucherId,
          status: 'confirmed',
        );
        String bookingId = await DatabaseService().saveBooking(booking);

        // Create payment
        PaymentModel payment = PaymentModel(
          id: '', // Generate
          bookingId: bookingId,
          amount: widget.totalPrice,
          status: 'success',
          transactionId: 'fake-trans-id', // From gateway
        );
        await DatabaseService().savePayment(payment);

        // Delete temp booking without adding back seats
        await DatabaseService().deleteTempBooking(_tempBookingId!, addBackSeats: false);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
        Navigator.popUntil(context, (route) => route.isFirst); // Back to home or something
      }
    } else {
      // Payment failed, show message, allow retry or cancel
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Failed! Please try again or cancel.')));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCancel() async {
    // Delete temp booking and release seats
    if (_tempBookingId != null) {
      await DatabaseService().deleteTempBooking(_tempBookingId!);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_tempBookingId == null) return const Center(child: CircularProgressIndicator(color: Colors.blue));

    return WillPopScope(
      onWillPop: () async {
        await _handleCancel();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh Toán'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade100,
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tổng Số Tiền: ${widget.totalPrice} VND',
                  style: TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_isProcessing) const CircularProgressIndicator(color: Colors.blue),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    shadowColor: MaterialStateProperty.all(Colors.blue.shade300),
                    elevation: MaterialStateProperty.all(8),
                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.blue.shade900; // In đậm khi hover
                      }
                      return Colors.blue.shade700;
                    }),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade400],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Thanh Toán Ngay',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleCancel,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    shadowColor: MaterialStateProperty.all(Colors.blue.shade300),
                    elevation: MaterialStateProperty.all(8),
                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.blue.shade900; // In đậm khi hover
                      }
                      return Colors.blue.shade700;
                    }),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade400],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Hủy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}