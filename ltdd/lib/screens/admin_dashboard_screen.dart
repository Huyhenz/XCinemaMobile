import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Thêm dependency: image_picker: ^1.0.0 vào pubspec.yaml
import 'dart:io';

import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/theater.dart';
import '../services/database_services.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc()..add(LoadAdminData()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Create Movie'),
              Tab(text: 'Create Showtime'),
              Tab(text: 'Manage Theaters'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _CreateMovieTab(),
            _CreateShowtimeTab(),
            _CreateTheaterTab(),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Create Movie
class _CreateMovieTab extends StatefulWidget {
  @override
  _CreateMovieTabState createState() => _CreateMovieTabState();
}

class _CreateMovieTabState extends State<_CreateMovieTab> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _genreController = TextEditingController();
  final _durationController = TextEditingController();
  final _ratingController = TextEditingController();
  File? _posterImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _posterImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadPoster(File image) async {
    final storageRef = FirebaseStorage.instance.ref().child('posters/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.error != null) return Center(child: Text('Error: ${state.error}'));

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: _genreController, decoration: const InputDecoration(labelText: 'Genre (e.g., Action, Comedy)')),
              TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
              TextField(controller: _ratingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rating (0-10)')),
              ElevatedButton(onPressed: _pickImage, child: const Text('Pick Poster Image')),
              if (_posterImage != null) Image.file(_posterImage!, height: 100),
              ElevatedButton(
                onPressed: () async {
                  final posterUrl = _posterImage != null ? await _uploadPoster(_posterImage!) : '';
                  if (posterUrl == null) return;
                  final movie = MovieModel(
                    id: '', // Generated in save
                    title: _titleController.text,
                    description: _descController.text,
                    genre: _genreController.text,
                    duration: int.parse(_durationController.text),
                    posterUrl: posterUrl ?? '',
                    rating: double.parse(_ratingController.text),
                    releaseDate: DateTime.now().millisecondsSinceEpoch,
                  );
                  context.read<AdminBloc>().add(CreateMovie(movie));
                },
                child: const Text('Create Movie'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tab 2: Create Showtime
class _CreateShowtimeTab extends StatefulWidget {
  @override
  _CreateShowtimeTabState createState() => _CreateShowtimeTabState();
}

class _CreateShowtimeTabState extends State<_CreateShowtimeTab> {
  String? _selectedMovieId;
  String? _selectedTheaterId;
  final _priceController = TextEditingController();
  DateTime _startTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) return const Center(child: CircularProgressIndicator());

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButton<String>(
                hint: const Text('Select Movie'),
                value: _selectedMovieId,
                items: state.movies.map((movie) => DropdownMenuItem(value: movie.id, child: Text(movie.title))).toList(),
                onChanged: (value) => setState(() => _selectedMovieId = value),
              ),
              DropdownButton<String>(
                hint: const Text('Select Theater'),
                value: _selectedTheaterId,
                items: state.theaters.map((theater) => DropdownMenuItem(value: theater.id, child: Text(theater.name))).toList(),
                onChanged: (value) => setState(() => _selectedTheaterId = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(context: context, initialDate: _startTime, firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (selectedDate != null) setState(() => _startTime = selectedDate);
                },
                child: Text('Start Time: ${_startTime.toString()}'),
              ),
              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (VND)')),
              ElevatedButton(
                onPressed: () async {
                  final theater = await DatabaseService().getTheater(_selectedTheaterId ?? '');
                  if (theater == null || _selectedMovieId == null) return;
                  final showtime = ShowtimeModel(
                    id: '', // Generated
                    movieId: _selectedMovieId!,
                    theaterId: _selectedTheaterId!,
                    startTime: _startTime.millisecondsSinceEpoch,
                    price: double.parse(_priceController.text),
                    availableSeats: theater.seats, // Copy seats từ theater
                  );
                  context.read<AdminBloc>().add(CreateShowtime(showtime));
                },
                child: const Text('Create Showtime'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tab 3: Create Theater
// File: lib/screens/admin_dashboard_screen.dart (updated _CreateTheaterTab only; rest unchanged)
class _CreateTheaterTab extends StatefulWidget {
  @override
  _CreateTheaterTabState createState() => _CreateTheaterTabState();
}

class _CreateTheaterTabState extends State<_CreateTheaterTab> {
  final _nameController = TextEditingController();
  final _rowsController = TextEditingController();  // New: number of rows (e.g., 5 for A-E)
  final _seatsPerRowController = TextEditingController();  // New: seats per row (e.g., 10)

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Theater Name')),
              TextField(
                controller: _rowsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Rows (e.g., 5 for A-E)'),
              ),
              TextField(
                controller: _seatsPerRowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seats Per Row (e.g., 10)'),
              ),
              ElevatedButton(
                onPressed: () {
                  int numRows = int.tryParse(_rowsController.text) ?? 0;
                  int seatsPerRow = int.tryParse(_seatsPerRowController.text) ?? 0;
                  if (numRows <= 0 || seatsPerRow <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid rows or seats per row')));
                    return;
                  }
                  List<String> seats = [];
                  for (int r = 0; r < numRows; r++) {
                    String rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);
                    for (int i = 1; i <= seatsPerRow; i++) {
                      seats.add('$rowLetter$i');
                    }
                  }
                  final theater = TheaterModel(
                    id: '', // Generated
                    name: _nameController.text,
                    capacity: numRows * seatsPerRow,
                    seats: seats,
                  );
                  context.read<AdminBloc>().add(CreateTheater(theater));
                },
                child: const Text('Create Theater'),
              ),
              const Text('Existing Theaters:'),
              ListView.builder(
                shrinkWrap: true,
                itemCount: state.theaters.length,
                itemBuilder: (context, index) {
                  final theater = state.theaters[index];
                  return ListTile(title: Text(theater.name), subtitle: Text('Seats: ${theater.seats.length}'));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}