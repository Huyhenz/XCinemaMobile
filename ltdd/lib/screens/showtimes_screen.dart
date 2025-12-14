// Thêm file mới: lib/screens/showtimes_screen.dart
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
      appBar: AppBar(title: const Text('Showtimes')),
      body: _showtimes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _showtimes.length,
        itemBuilder: (context, index) {
          ShowtimeModel showtime = _showtimes[index];
          return ListTile(
            title: Text('Time: ${DateTime.fromMillisecondsSinceEpoch(showtime.startTime)}'),
            subtitle: Text('Price: ${showtime.price} VND'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookingScreen(showtimeId: showtime.id)),
            ),
          );
        },
      ),
    );
  }
}