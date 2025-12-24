// File: lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/theater.dart';
import '../services/database_services.dart';
import 'admin_cleanup_screen.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc()..add(LoadAdminData()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Database Cleanup',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminCleanupScreen(),
                  ),
                );
              },
            ),
          ],
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
          children: const [
            _CreateMovieTab(),
            _CreateShowtimeTab(),
            _CreateTheaterTab(),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Create Movie - IMPROVED
class _CreateMovieTab extends StatefulWidget {
  const _CreateMovieTab();

  @override
  State<_CreateMovieTab> createState() => _CreateMovieTabState();
}

class _CreateMovieTabState extends State<_CreateMovieTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _genreController = TextEditingController();
  final _durationController = TextEditingController();
  final _ratingController = TextEditingController();
  final _posterUrlController = TextEditingController();
  DateTime? _releaseDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _genreController.dispose();
    _durationController.dispose();
    _ratingController.dispose();
    _posterUrlController.dispose();
    super.dispose();
  }

  Future<void> _createMovie() async {
    if (!_formKey.currentState!.validate()) return;
    if (_releaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày phát hành'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final movie = MovieModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        genre: _genreController.text.trim(),
        duration: int.parse(_durationController.text.trim()),
        posterUrl: _posterUrlController.text.trim(),
        rating: double.parse(_ratingController.text.trim()),
        releaseDate: _releaseDate!.millisecondsSinceEpoch,
      );

      context.read<AdminBloc>().add(CreateMovie(movie));

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _releaseDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã tạo phim thành công!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFE50914),
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên Phim *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.movie),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên phim' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô Tả *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
                ),
                const SizedBox(height: 16),

                // Genre
                TextFormField(
                  controller: _genreController,
                  decoration: const InputDecoration(
                    labelText: 'Thể Loại * (vd: Hành Động, Hài)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập thể loại' : null,
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời Lượng (phút) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập thời lượng';
                    if (int.tryParse(value!) == null) return 'Vui lòng nhập số hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rating
                TextFormField(
                  controller: _ratingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Đánh Giá (0-10) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập điểm đánh giá';
                    final rating = double.tryParse(value!);
                    if (rating == null) return 'Vui lòng nhập số hợp lệ';
                    if (rating < 0 || rating > 10) return 'Điểm đánh giá phải từ 0-10';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Release Date
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _releaseDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE50914),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1A1A1A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _releaseDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày Phát Hành *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _releaseDate == null
                          ? 'Chọn ngày phát hành'
                          : DateFormat('dd/MM/yyyy').format(_releaseDate!),
                      style: TextStyle(
                        color: _releaseDate == null ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Poster URL
                TextFormField(
                  controller: _posterUrlController,
                  onChanged: (value) => setState(() {}), // Update preview when URL changes
                  decoration: const InputDecoration(
                    labelText: 'Link Ảnh Poster (URL) *',
                    hintText: 'https://example.com/poster.jpg',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập link ảnh poster';
                    // Basic URL validation
                    final uri = Uri.tryParse(value!.trim());
                    if (uri == null || !uri.hasScheme) {
                      return 'Vui lòng nhập URL hợp lệ (bắt đầu bằng http:// hoặc https://)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Preview poster image
                if (_posterUrlController.text.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _posterUrlController.text.trim(),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFE50914)),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Create Button
                ElevatedButton(
                  onPressed: _isCreating ? null : _createMovie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'TẠO PHIM',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Tab 2: Create Showtime
class _CreateShowtimeTab extends StatefulWidget {
  const _CreateShowtimeTab();

  @override
  State<_CreateShowtimeTab> createState() => _CreateShowtimeTabState();
}

class _CreateShowtimeTabState extends State<_CreateShowtimeTab> {
  String? _selectedMovieId;
  String? _selectedTheaterId;
  final _priceController = TextEditingController();
  DateTime _startTime = DateTime.now();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

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
                    id: '',
                    movieId: _selectedMovieId!,
                    theaterId: _selectedTheaterId!,
                    startTime: _startTime.millisecondsSinceEpoch,
                    price: double.parse(_priceController.text),
                    availableSeats: theater.seats,
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
class _CreateTheaterTab extends StatefulWidget {
  const _CreateTheaterTab();

  @override
  State<_CreateTheaterTab> createState() => _CreateTheaterTabState();
}

class _CreateTheaterTabState extends State<_CreateTheaterTab> {
  final _nameController = TextEditingController();
  final _rowsController = TextEditingController();
  final _seatsPerRowController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _seatsPerRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Theater Name')),
              TextField(controller: _rowsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rows (e.g., 5 for A-E)')),
              TextField(controller: _seatsPerRowController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seats per Row (e.g., 10)')),
              ElevatedButton(
                onPressed: () {
                  final rows = int.tryParse(_rowsController.text) ?? 5;
                  final seatsPerRow = int.tryParse(_seatsPerRowController.text) ?? 10;
                  List<String> seats = [];
                  for (int i = 0; i < rows; i++) {
                    String row = String.fromCharCode(65 + i); // A, B, C, ...
                    for (int j = 1; j <= seatsPerRow; j++) {
                      seats.add('$row$j');
                    }
                  }
                  final capacity = rows * seatsPerRow;
                  final theater = TheaterModel(
                    id: '',
                    name: _nameController.text,
                    capacity: capacity,
                    seats: seats,
                  );
                  context.read<AdminBloc>().add(CreateTheater(theater));
                },
                child: const Text('Create Theater'),
              ),
            ],
          ),
        );
      },
    );
  }
}
