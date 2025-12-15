// Updated: lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/user.dart';
import '../services/database_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    _user = await DatabaseService().getUser(userId);
    _bookings = await DatabaseService().getBookingsByUser(userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator(color: Colors.blue));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ'),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Tên: ${_user!.name}',
                    style: TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Email: ${_user!.email}',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
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
                    'Đăng Xuất',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Lịch Sử Đặt Vé:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  BookingModel booking = _bookings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.white,
                    child: ListTile(
                      title: Text('Lịch Chiếu: ${booking.showtimeId}', style: TextStyle(color: Colors.black87)),
                      subtitle: Text('Ghế: ${booking.seats.join(', ')} - Trạng Thái: ${booking.status}', style: TextStyle(color: Colors.black54)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}