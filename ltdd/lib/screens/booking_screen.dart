// Chỉnh sửa file: lib/screens/booking_screen.dart (thay đổi _confirmBooking để pass data sang Payment mà không tạo temp)
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
    if (_showtime == null || _theater == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Book Seats')),
      body: Column(
        children: [
          const Text('Select Seats:'),
          GridView.builder(
            shrinkWrap: true,
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
                  color: isSelected ? Colors.green : (isAvailable ? Colors.grey : Colors.red),
                  child: Center(child: Text(seat)),
                ),
              );
            },
          ),
          TextField(
            onChanged: (value) => _voucherCode = value,
            decoration: const InputDecoration(labelText: 'Voucher Code'),
          ),
          ElevatedButton(onPressed: _applyVoucher, child: const Text('Apply Voucher')),
          Text('Total: $_totalPrice VND'),
          ElevatedButton(onPressed: _selectedSeats.isNotEmpty ? _proceedToPayment : null, child: const Text('Proceed to Payment')),
        ],
      ),
    );
  }
}