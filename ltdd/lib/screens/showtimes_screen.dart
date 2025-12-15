// Updated: lib/screens/showtimes_screen.dart
import 'package:flutter/material.dart';

import '../models/showtime.dart';
import '../services/database_services.dart';
import 'booking_screen.dart'; // Import screen booking

class ShowtimesScreen extends StatefulWidget {
  final String movieId;
  const ShowtimesScreen({super.key, required this.movieId});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  List<ShowtimeModel> _showtimes = [];

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    _showtimes = await DatabaseService().getShowtimesByMovie(widget.movieId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Chiếu'),
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
        child: _showtimes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : ListView.builder(
          itemCount: _showtimes.length,
          itemBuilder: (context, index) {
            ShowtimeModel showtime = _showtimes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: ListTile(
                title: Text(
                  'Thời Gian: ${DateTime.fromMillisecondsSinceEpoch(showtime.startTime)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                subtitle: Text('Giá: ${showtime.price} VND', style: TextStyle(color: Colors.black54)),
                trailing: Icon(Icons.arrow_forward, color: Colors.blue.shade700),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingScreen(showtimeId: showtime.id)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}