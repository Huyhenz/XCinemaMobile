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
    _bookings = await DatabaseService().getBookingsByUser(userId); // Thêm method này: tương tự getShowtimesByMovie, dùng query orderByChild('userId').equalTo(userId)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          Text('Name: ${_user!.name}'),
          Text('Email: ${_user!.email}'),
          ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Logout')),
          const Text('Booking History:'),
          Expanded(
            child: ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                BookingModel booking = _bookings[index];
                return ListTile(
                  title: Text('Showtime: ${booking.showtimeId}'),
                  subtitle: Text('Seats: ${booking.seats.join(', ')} - Status: ${booking.status}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}