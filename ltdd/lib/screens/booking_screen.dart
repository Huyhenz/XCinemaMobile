// Updated: lib/screens/booking_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/showtime.dart';
import '../models/voucher.dart';
import '../models/theater.dart';
import '../services/database_services.dart';
import 'payment_screen.dart';  // Add this import

class BookingScreen extends StatefulWidget {
  final String showtimeId;
  const BookingScreen({super.key, required this.showtimeId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  ShowtimeModel? _showtime;
  TheaterModel? _theater;
  List<String> _selectedSeats = [];
  String? _voucherCode;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _showtime = await DatabaseService().getShowtime(widget.showtimeId);
    if (_showtime != null) {
      _theater = await DatabaseService().getTheater(_showtime!.theaterId);
    }
    setState(() {});
  }

  void _toggleSeat(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else if (_showtime!.availableSeats.contains(seat)) {
        _selectedSeats.add(seat);
      }
      _totalPrice = _selectedSeats.length * _showtime!.price;
    });
  }

  Future<void> _applyVoucher() async {
    VoucherModel? voucher = await DatabaseService().getVoucher(_voucherCode ?? '');
    if (voucher != null && voucher.isActive) {
      setState(() {
        if (voucher.type == 'percent') {
          _totalPrice *= (1 - voucher.discount / 100);
        } else {
          _totalPrice -= voucher.discount;
        }
      });
    }
  }

  void _proceedToPayment() {
    // Không tạo temp ở đây, pass data sang PaymentScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          showtimeId: widget.showtimeId,
          selectedSeats: _selectedSeats,
          totalPrice: _totalPrice,
          voucherId: _voucherCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showtime == null || _theater == null) return const Center(child: CircularProgressIndicator(color: Colors.blue));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Ghế'),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Chọn Ghế:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,  // Assume 10 seats per row; adjust or calculate based on seats if varies
                ),
                itemCount: _theater!.seats.length,
                itemBuilder: (context, index) {
                  String seat = _theater!.seats[index];
                  bool isAvailable = _showtime!.availableSeats.contains(seat);
                  bool isSelected = _selectedSeats.contains(seat);
                  return GestureDetector(
                    onTap: isAvailable ? () => _toggleSeat(seat) : null,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : (isAvailable ? Colors.grey : Colors.red),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Center(child: Text(seat, style: TextStyle(color: Colors.white))),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) => _voucherCode = value,
                  decoration: InputDecoration(
                    labelText: 'Mã Voucher',
                    labelStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.card_giftcard, color: Colors.blue),
                  ),
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              ElevatedButton(
                onPressed: _applyVoucher,
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
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
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(
                      'Áp Dụng Voucher',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tổng Tiền: $_totalPrice VND',
                  style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedSeats.isNotEmpty ? _proceedToPayment : null,
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
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
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Tiếp Tục Thanh Toán',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}