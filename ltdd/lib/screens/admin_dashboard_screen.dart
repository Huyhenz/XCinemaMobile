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
import '../models/cinema.dart';
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
    _tabController = TabController(length: 7, vsync: this);
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
            isScrollable: true,
            tabs: const [
              Tab(text: 'Create Cinema'),
              Tab(text: 'Create Movie'),
              Tab(text: 'Manage Movies'),
              Tab(text: 'Create Showtime'),
              Tab(text: 'Manage Showtimes'),
              Tab(text: 'Create Theater'),
              Tab(text: 'Manage Theaters'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _CreateCinemaTab(),
            _CreateMovieTab(),
            _ManageMoviesTab(),
            _CreateShowtimeTab(),
            _ManageShowtimesTab(),
            _CreateTheaterTab(),
            _ManageTheatersTab(),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Create Cinema
class _CreateCinemaTab extends StatefulWidget {
  const _CreateCinemaTab();

  @override
  State<_CreateCinemaTab> createState() => _CreateCinemaTabState();
}

class _CreateCinemaTabState extends State<_CreateCinemaTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _createCinema() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      double? latitude;
      double? longitude;
      if (_latitudeController.text.isNotEmpty) {
        latitude = double.tryParse(_latitudeController.text);
      }
      if (_longitudeController.text.isNotEmpty) {
        longitude = double.tryParse(_longitudeController.text);
      }

      final cinema = CinemaModel(
        id: '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        latitude: latitude,
        longitude: longitude,
      );

      await DatabaseService().saveCinema(cinema);

      // Reset form
      _formKey.currentState!.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã tạo rạp chiếu thành công!'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên Rạp Chiếu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.theaters),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên rạp' : null,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Địa Chỉ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số Điện Thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Link Ảnh Rạp (URL)',
                hintText: 'https://example.com/cinema.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),

            // Latitude
            TextFormField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Vĩ Độ (Latitude)',
                hintText: '10.762622',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),

            // Longitude
            TextFormField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kinh Độ (Longitude)',
                hintText: '106.660172',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            ElevatedButton(
              onPressed: _isCreating ? null : _createCinema,
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
                      'TẠO RẠP CHIẾU',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 2: Create Movie - IMPROVED
class _CreateMovieTab extends StatefulWidget {
  const _CreateMovieTab();

  @override
  State<_CreateMovieTab> createState() => _CreateMovieTabState();
}

class _CreateMovieTabState extends State<_CreateMovieTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCinemaId;
  List<CinemaModel> _cinemas = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _genreController = TextEditingController();
  final _durationController = TextEditingController();
  final _ratingController = TextEditingController();
  final _posterUrlController = TextEditingController();
  DateTime? _releaseDate;
  bool _isCreating = false;
  bool _isLoadingCinemas = true;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    try {
      List<CinemaModel> cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _cinemas = cinemas;
        _isLoadingCinemas = false;
      });
    } catch (e) {
      print('Error loading cinemas: $e');
      setState(() => _isLoadingCinemas = false);
    }
  }

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
    if (_selectedCinemaId == null || _selectedCinemaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn rạp chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
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
        cinemaId: _selectedCinemaId!,
        rating: double.parse(_ratingController.text.trim()),
        releaseDate: _releaseDate!.millisecondsSinceEpoch,
      );

      context.read<AdminBloc>().add(CreateMovie(movie));

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedCinemaId = null;
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
                // Cinema Selection
                if (_isLoadingCinemas)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFFE50914)),
                  ))
                else
                  DropdownButtonFormField<String>(
                    value: _selectedCinemaId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn Rạp Chiếu *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.theaters),
                    ),
                    items: _cinemas.map((cinema) {
                      return DropdownMenuItem<String>(
                        value: cinema.id,
                        child: Text(cinema.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCinemaId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
                  ),
                const SizedBox(height: 16),

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

// Tab 3: Create Showtime
class _CreateShowtimeTab extends StatefulWidget {
  const _CreateShowtimeTab();

  @override
  State<_CreateShowtimeTab> createState() => _CreateShowtimeTabState();
}

class _CreateShowtimeTabState extends State<_CreateShowtimeTab> {
  String? _selectedCinemaId;
  String? _selectedMovieId;
  String? _selectedTheaterId;
  List<CinemaModel> _cinemas = [];
  List<MovieModel> _movies = [];
  List<TheaterModel> _theaters = [];
  final _priceController = TextEditingController();
  DateTime _startTime = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isCreating = false;
  bool _isLoadingCinemas = true;
  bool _isLoadingMovies = false;
  bool _isLoadingTheaters = false;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    try {
      List<CinemaModel> cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _cinemas = cinemas;
        _isLoadingCinemas = false;
      });
    } catch (e) {
      print('Error loading cinemas: $e');
      setState(() => _isLoadingCinemas = false);
    }
  }

  Future<void> _loadMoviesByCinema(String cinemaId) async {
    setState(() {
      _isLoadingMovies = true;
      _selectedMovieId = null;
      _movies = [];
    });
    try {
      List<MovieModel> movies = await DatabaseService().getMoviesByCinema(cinemaId);
      setState(() {
        _movies = movies;
        _isLoadingMovies = false;
      });
    } catch (e) {
      print('Error loading movies: $e');
      setState(() => _isLoadingMovies = false);
    }
  }

  Future<void> _loadTheatersByCinema(String cinemaId) async {
    setState(() {
      _isLoadingTheaters = true;
      _selectedTheaterId = null;
      _theaters = [];
    });
    try {
      List<TheaterModel> theaters = await DatabaseService().getTheatersByCinema(cinemaId);
      setState(() {
        _theaters = theaters;
        _isLoadingTheaters = false;
      });
    } catch (e) {
      print('Error loading theaters: $e');
      setState(() => _isLoadingTheaters = false);
    }
  }

  void _onCinemaChanged(String? cinemaId) {
    setState(() {
      _selectedCinemaId = cinemaId;
      _selectedMovieId = null;
      _selectedTheaterId = null;
      _movies = [];
      _theaters = [];
    });
    if (cinemaId != null && cinemaId.isNotEmpty) {
      _loadMoviesByCinema(cinemaId);
      _loadTheatersByCinema(cinemaId);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // Select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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
    if (pickedDate != null) {
      // Select time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
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
      if (pickedTime != null) {
        setState(() {
          _selectedTime = pickedTime;
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createShowtime() async {
    if (_selectedCinemaId == null || _selectedCinemaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn rạp chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
    if (_selectedMovieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phim'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
    if (_selectedTheaterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập giá vé'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giá vé phải là số dương'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final theater = await DatabaseService().getTheater(_selectedTheaterId!);
      if (theater == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy phòng chiếu'),
            backgroundColor: Color(0xFFE50914),
          ),
        );
        return;
      }

      final showtime = ShowtimeModel(
        id: '',
        movieId: _selectedMovieId!,
        theaterId: _selectedTheaterId!,
        startTime: _startTime.millisecondsSinceEpoch,
        price: price,
        availableSeats: theater.seats,
      );
      context.read<AdminBloc>().add(CreateShowtime(showtime));

      // Reset form
      setState(() {
        _selectedCinemaId = null;
        _selectedMovieId = null;
        _selectedTheaterId = null;
        _movies = [];
        _theaters = [];
        _startTime = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });
      _priceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã tạo lịch chiếu thành công!'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cinema Selection
          if (_isLoadingCinemas)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ))
          else
            DropdownButtonFormField<String>(
              value: _selectedCinemaId,
              decoration: const InputDecoration(
                labelText: 'Chọn Rạp Chiếu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.theaters),
              ),
              items: _cinemas.map((cinema) {
                return DropdownMenuItem<String>(
                  value: cinema.id,
                  child: Text(cinema.name),
                );
              }).toList(),
              onChanged: _onCinemaChanged,
              validator: (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
            ),
          const SizedBox(height: 16),

          // Movie Selection (chỉ hiển thị sau khi chọn cinema)
          if (_selectedCinemaId != null && _selectedCinemaId!.isNotEmpty) ...[
            if (_isLoadingMovies)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              ))
            else if (_movies.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rạp này chưa có phim. Vui lòng tạo phim cho rạp này trước.',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedMovieId,
                decoration: const InputDecoration(
                  labelText: 'Chọn Phim *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.movie),
                ),
                items: _movies.map((movie) {
                  return DropdownMenuItem<String>(
                    value: movie.id,
                    child: Text(movie.title),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedMovieId = value);
                },
                validator: (value) => value == null ? 'Vui lòng chọn phim' : null,
              ),
            const SizedBox(height: 16),

            // Theater Selection (chỉ hiển thị sau khi chọn cinema)
            if (_isLoadingTheaters)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              ))
            else if (_theaters.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rạp này chưa có phòng chiếu. Vui lòng tạo phòng chiếu cho rạp này trước.',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedTheaterId,
                decoration: const InputDecoration(
                  labelText: 'Chọn Phòng Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                items: _theaters.map((theater) {
                  return DropdownMenuItem<String>(
                    value: theater.id,
                    child: Text(theater.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedTheaterId = value);
                },
                validator: (value) => value == null ? 'Vui lòng chọn phòng chiếu' : null,
              ),
          ],
          const SizedBox(height: 16),

          // Date & Time Selection
          InkWell(
            onTap: _selectDateTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ngày và Giờ Chiếu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(_startTime)} ${_selectedTime.format(context)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Giá Vé (VND) *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Vui lòng nhập giá vé';
              final price = double.tryParse(value!);
              if (price == null || price <= 0) return 'Giá vé phải là số dương';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Create Button
          ElevatedButton(
            onPressed: _isCreating ? null : _createShowtime,
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
                    'TẠO LỊCH CHIẾU',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

// Tab 5: Manage Showtimes (Edit & Delete)
class _ManageShowtimesTab extends StatelessWidget {
  const _ManageShowtimesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (state.showtimes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có lịch chiếu nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo lịch chiếu mới ở tab "Create Showtime"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.showtimes.length,
          itemBuilder: (context, index) {
            final showtime = state.showtimes[index];
            return FutureBuilder<Map<String, dynamic>>(
              future: _getShowtimeDetails(showtime),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Card(
                    color: Color(0xFF1A1A1A),
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Đang tải...', style: TextStyle(color: Colors.white)),
                    ),
                  );
                }

                final details = snapshot.data!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      details['movieTitle'] ?? 'Phim không xác định',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Phòng: ${details['theaterName'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian: ${details['time']}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          'Giá: ${NumberFormat('#,###', 'vi_VN').format(showtime.price)}₫',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          'Ghế trống: ${showtime.availableSeats.length}/${details['totalSeats'] ?? 0}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          onPressed: () => _showEditShowtimeDialog(context, showtime),
                          tooltip: 'Sửa lịch chiếu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                          onPressed: () => _showDeleteShowtimeConfirmDialog(context, showtime, details),
                          tooltip: 'Xóa lịch chiếu',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getShowtimeDetails(ShowtimeModel showtime) async {
    final dbService = DatabaseService();
    final movie = await dbService.getMovie(showtime.movieId);
    final theater = await dbService.getTheater(showtime.theaterId);
    
    return {
      'movieTitle': movie?.title ?? 'N/A',
      'theaterName': theater?.name ?? 'N/A',
      'totalSeats': theater?.seats.length ?? 0,
      'time': DateFormat('dd/MM/yyyy HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(showtime.startTime),
      ),
    };
  }

  void _showEditShowtimeDialog(BuildContext context, ShowtimeModel showtime) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: adminBloc,
        child: _EditShowtimeDialog(showtime: showtime),
      ),
    );
  }

  void _showDeleteShowtimeConfirmDialog(BuildContext context, ShowtimeModel showtime, Map<String, dynamic> details) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: adminBloc,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Xác nhận xóa',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa lịch chiếu "${details['movieTitle']}"?\n\nThời gian: ${details['time']}\n\nHành động này không thể hoàn tác.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  adminBloc.add(DeleteShowtime(showtime.id));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã xóa lịch chiếu'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Edit Showtime Dialog Widget
class _EditShowtimeDialog extends StatefulWidget {
  final ShowtimeModel showtime;
  const _EditShowtimeDialog({required this.showtime});

  @override
  State<_EditShowtimeDialog> createState() => _EditShowtimeDialogState();
}

class _EditShowtimeDialogState extends State<_EditShowtimeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  DateTime _startTime = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedTheaterId;
  List<TheaterModel> _theaters = [];
  bool _isSaving = false;
  bool _isLoadingTheaters = true;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.fromMillisecondsSinceEpoch(widget.showtime.startTime);
    _selectedTime = TimeOfDay.fromDateTime(_startTime);
    _priceController.text = widget.showtime.price.toString();
    _selectedTheaterId = widget.showtime.theaterId;
    _loadTheaters();
  }

  Future<void> _loadTheaters() async {
    try {
      // Load theater hiện tại để lấy cinemaId
      final currentTheater = await DatabaseService().getTheater(widget.showtime.theaterId);
      if (currentTheater != null) {
        // Load tất cả theaters của cinema này
        final theaters = await DatabaseService().getTheatersByCinema(currentTheater.cinemaId);
        setState(() {
          _theaters = theaters;
          _isLoadingTheaters = false;
        });
      } else {
        // Nếu không tìm thấy theater, load tất cả
        final allTheaters = await DatabaseService().getAllTheaters();
        setState(() {
          _theaters = allTheaters;
          _isLoadingTheaters = false;
        });
      }
    } catch (e) {
      print('Error loading theaters: $e');
      setState(() => _isLoadingTheaters = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Sửa Lịch Chiếu',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingTheaters)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFFE50914)),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedTheaterId,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Chọn Phòng Chiếu *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  items: _theaters.map((theater) {
                    return DropdownMenuItem<String>(
                      value: theater.id,
                      child: Text(theater.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTheaterId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn phòng chiếu' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Giá Vé (VND) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá vé';
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) return 'Giá vé phải là số dương';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ngày chiếu', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_startTime),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: _selectDate,
              ),
              ListTile(
                title: const Text('Giờ chiếu', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: _selectTime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isSaving = true);
              try {
                // Nếu chọn theater mới, cần lấy seats từ theater mới
                List<String> availableSeats = widget.showtime.availableSeats;
                if (_selectedTheaterId != null && _selectedTheaterId != widget.showtime.theaterId) {
                  // Theater đã thay đổi, cần lấy seats mới từ theater
                  final newTheater = await DatabaseService().getTheater(_selectedTheaterId!);
                  if (newTheater != null) {
                    // Giữ lại các ghế đã được đặt (không có trong availableSeats của theater mới)
                    // Nhưng thực tế nên reset về tất cả seats của theater mới
                    availableSeats = List.from(newTheater.seats);
                  }
                }

                final updatedShowtime = ShowtimeModel(
                  id: widget.showtime.id,
                  movieId: widget.showtime.movieId,
                  theaterId: _selectedTheaterId ?? widget.showtime.theaterId,
                  startTime: _startTime.millisecondsSinceEpoch,
                  price: double.parse(_priceController.text),
                  availableSeats: availableSeats,
                );
                context.read<AdminBloc>().add(UpdateShowtime(updatedShowtime));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã cập nhật lịch chiếu'),
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
                setState(() => _isSaving = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

// Tab 6: Manage Theaters (Edit & Delete)
class _ManageTheatersTab extends StatelessWidget {
  const _ManageTheatersTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (state.theaters.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có phòng chiếu nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo phòng chiếu mới ở tab "Manage Theaters"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.theaters.length,
          itemBuilder: (context, index) {
            final theater = state.theaters[index];
            return FutureBuilder<CinemaModel?>(
              future: DatabaseService().getCinema(theater.cinemaId),
              builder: (context, snapshot) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.meeting_room, color: Color(0xFFE50914), size: 40),
                    title: Text(
                      theater.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Rạp: ${snapshot.data?.name ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sức chứa: ${theater.capacity} ghế',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          'Số ghế: ${theater.seats.length}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          onPressed: () => _showEditTheaterDialog(context, theater),
                          tooltip: 'Sửa phòng chiếu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                          onPressed: () => _showDeleteTheaterConfirmDialog(context, theater),
                          tooltip: 'Xóa phòng chiếu',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditTheaterDialog(BuildContext context, TheaterModel theater) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: adminBloc,
        child: _EditTheaterDialog(theater: theater),
      ),
    );
  }

  void _showDeleteTheaterConfirmDialog(BuildContext context, TheaterModel theater) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: adminBloc,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Xác nhận xóa',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa phòng chiếu "${theater.name}"?\n\nHành động này không thể hoàn tác và sẽ xóa tất cả lịch chiếu liên quan.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  adminBloc.add(DeleteTheater(theater.id));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã xóa phòng chiếu "${theater.name}"'),
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Edit Theater Dialog Widget
class _EditTheaterDialog extends StatefulWidget {
  final TheaterModel theater;
  const _EditTheaterDialog({required this.theater});

  @override
  State<_EditTheaterDialog> createState() => _EditTheaterDialogState();
}

class _EditTheaterDialogState extends State<_EditTheaterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rowsController = TextEditingController();
  final _seatsPerRowController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.theater.name;
    // Tính số hàng và số ghế mỗi hàng từ seats hiện tại
    if (widget.theater.seats.isNotEmpty) {
      final rows = widget.theater.seats.map((seat) => seat[0]).toSet().length;
      final seatsPerRow = widget.theater.seats.length ~/ rows;
      _rowsController.text = rows.toString();
      _seatsPerRowController.text = seatsPerRow.toString();
    } else {
      _rowsController.text = '5';
      _seatsPerRowController.text = '10';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _seatsPerRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Sửa Phòng Chiếu',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tên Phòng Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên phòng chiếu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rowsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Số Hàng Ghế * (VD: 5 cho A-E)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grid_view),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số hàng';
                  final rows = int.tryParse(value!);
                  if (rows == null || rows <= 0) return 'Số hàng phải là số dương';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsPerRowController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Số Ghế Mỗi Hàng * (VD: 10)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_seat),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số ghế mỗi hàng';
                  final seatsPerRow = int.tryParse(value!);
                  if (seatsPerRow == null || seatsPerRow <= 0) return 'Số ghế mỗi hàng phải là số dương';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isSaving = true);
              try {
                final rows = int.parse(_rowsController.text);
                final seatsPerRow = int.parse(_seatsPerRowController.text);
                
                if (rows <= 0 || seatsPerRow <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số hàng và số ghế phải lớn hơn 0'),
                      backgroundColor: Color(0xFFE50914),
                    ),
                  );
                  setState(() => _isSaving = false);
                  return;
                }

                // Regenerate seats based on rows and seatsPerRow
                List<String> seats = [];
                for (int i = 0; i < rows; i++) {
                  String row = String.fromCharCode(65 + i); // A, B, C, ...
                  for (int j = 1; j <= seatsPerRow; j++) {
                    seats.add('$row$j');
                  }
                }
                
                final capacity = rows * seatsPerRow;
                final updatedTheater = TheaterModel(
                  id: widget.theater.id,
                  name: _nameController.text.trim(),
                  cinemaId: widget.theater.cinemaId,
                  capacity: capacity,
                  seats: seats,
                );
                context.read<AdminBloc>().add(UpdateTheater(updatedTheater));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã cập nhật phòng chiếu'),
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
                setState(() => _isSaving = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

// Tab 4: Create Theater (keep for creating new theaters)
class _CreateTheaterTab extends StatefulWidget {
  const _CreateTheaterTab();

  @override
  State<_CreateTheaterTab> createState() => _CreateTheaterTabState();
}

class _CreateTheaterTabState extends State<_CreateTheaterTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCinemaId;
  List<CinemaModel> _cinemas = [];
  final _nameController = TextEditingController();
  final _rowsController = TextEditingController();
  final _seatsPerRowController = TextEditingController();
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    try {
      List<CinemaModel> cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _cinemas = cinemas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cinemas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTheater() async {
    setState(() => _isCreating = true);
    try {
      final rows = int.parse(_rowsController.text);
      final seatsPerRow = int.parse(_seatsPerRowController.text);

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
        name: _nameController.text.trim(),
        cinemaId: _selectedCinemaId!,
        capacity: capacity,
        seats: seats,
      );
      context.read<AdminBloc>().add(CreateTheater(theater));

      // Reset form
      _nameController.clear();
      _rowsController.clear();
      _seatsPerRowController.clear();
      setState(() {
        _selectedCinemaId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo phòng chiếu thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _seatsPerRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cinema Selection
              DropdownButtonFormField<String>(
                value: _selectedCinemaId,
                decoration: const InputDecoration(
                  labelText: 'Chọn Rạp Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.theaters),
                ),
                items: _cinemas.map((cinema) {
                  return DropdownMenuItem<String>(
                    value: cinema.id,
                    child: Text(cinema.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCinemaId = value;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
              ),
              const SizedBox(height: 16),

              // Theater Name
                TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Phòng Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                  hintText: 'VD: Phòng 1, Phòng 2',
                ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập tên phòng chiếu' : null,
              ),
              const SizedBox(height: 16),

              // Rows
                TextFormField(
                controller: _rowsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số Hàng Ghế * (VD: 5 cho A-E)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grid_view),
                    hintText: '5',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số hàng ghế';
                    }
                    final rows = int.tryParse(value);
                    if (rows == null || rows <= 0) {
                      return 'Số hàng phải là số nguyên dương';
                    }
                    if (rows > 26) {
                      return 'Số hàng không được vượt quá 26 (A-Z)';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 16),

              // Seats per Row
                TextFormField(
                controller: _seatsPerRowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số Ghế Mỗi Hàng * (VD: 10)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_seat),
                    hintText: '10',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số ghế mỗi hàng';
                    }
                    final seatsPerRow = int.tryParse(value);
                    if (seatsPerRow == null || seatsPerRow <= 0) {
                      return 'Số ghế phải là số nguyên dương';
                    }
                    if (seatsPerRow > 50) {
                      return 'Số ghế mỗi hàng không được vượt quá 50';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: _isCreating ? null : () {
                  if (_formKey.currentState!.validate()) {
                    _createTheater();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
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
                        'TẠO PHÒNG CHIẾU',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ));
      },
    );
  }
}

// Tab 3: Manage Movies (Edit & Delete)
class _ManageMoviesTab extends StatelessWidget {
  const _ManageMoviesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (state.movies.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có phim nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo phim mới ở tab "Create Movie"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.movies.length,
          itemBuilder: (context, index) {
            final movie = state.movies[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    movie.posterUrl,
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      );
                    },
                  ),
                ),
                title: Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      movie.genre,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie.duration} phút | ⭐ ${movie.rating.toStringAsFixed(1)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    if (movie.releaseDate != null)
                      Text(
                        'Ngày phát hành: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(movie.releaseDate!))}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                      onPressed: () => _showEditMovieDialog(context, movie),
                      tooltip: 'Sửa phim',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                      onPressed: () => _showDeleteConfirmDialog(context, movie),
                      tooltip: 'Xóa phim',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditMovieDialog(BuildContext context, MovieModel movie) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: adminBloc,
        child: _EditMovieDialog(movie: movie),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MovieModel movie) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: adminBloc,
          child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa phim "${movie.title}"?\n\nHành động này không thể hoàn tác.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                adminBloc.add(DeleteMovie(movie.id));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã xóa phim "${movie.title}"'),
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
              ),
              child: const Text('Xóa'),
            ),
          ],
          ),
        );
      },
    );
  }
}

// Edit Movie Dialog Widget
class _EditMovieDialog extends StatefulWidget {
  final MovieModel movie;
  const _EditMovieDialog({required this.movie});

  @override
  State<_EditMovieDialog> createState() => _EditMovieDialogState();
}

class _EditMovieDialogState extends State<_EditMovieDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedCinemaId;
  List<CinemaModel> _cinemas = [];
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _genreController;
  late final TextEditingController _durationController;
  late final TextEditingController _ratingController;
  late final TextEditingController _posterUrlController;
  DateTime? _releaseDate;
  bool _isLoadingCinemas = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCinemaId = widget.movie.cinemaId;
    _titleController = TextEditingController(text: widget.movie.title);
    _descController = TextEditingController(text: widget.movie.description);
    _genreController = TextEditingController(text: widget.movie.genre);
    _durationController = TextEditingController(text: widget.movie.duration.toString());
    _ratingController = TextEditingController(text: widget.movie.rating.toString());
    _posterUrlController = TextEditingController(text: widget.movie.posterUrl);
    _releaseDate = widget.movie.releaseDate != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.movie.releaseDate!)
        : null;
    
    // Load cinemas
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    try {
      List<CinemaModel> cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _cinemas = cinemas;
        _isLoadingCinemas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCinemas = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Sửa Phim',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoadingCinemas)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Color(0xFFE50914)),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCinemaId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn Rạp Chiếu *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.theaters),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      items: _cinemas.map((cinema) {
                        return DropdownMenuItem<String>(
                          value: cinema.id,
                          child: Text(cinema.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCinemaId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tên Phim *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.movie),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên phim' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Mô Tả *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _genreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Thể Loại *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập thể loại' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Thời Lượng (phút) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Vui lòng nhập thời lượng';
                      if (int.tryParse(value!) == null) return 'Vui lòng nhập số hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ratingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Đánh Giá (0-10) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                      labelStyle: TextStyle(color: Colors.white),
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
                        labelStyle: TextStyle(color: Colors.white),
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
                  TextFormField(
                    controller: _posterUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Link Ảnh Poster (URL) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Vui lòng nhập link ảnh poster';
                      final uri = Uri.tryParse(value!.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Vui lòng nhập URL hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
      actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                if (_selectedCinemaId == null || _selectedCinemaId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn rạp chiếu'),
                      backgroundColor: Color(0xFFE50914),
                    ),
                  );
                  return;
                }
                if (_releaseDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn ngày phát hành'),
                      backgroundColor: Color(0xFFE50914),
                    ),
                  );
                  return;
                }

                setState(() => _isSaving = true);
                try {
                  final updatedMovie = MovieModel(
                    id: widget.movie.id,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    genre: _genreController.text.trim(),
                    duration: int.parse(_durationController.text.trim()),
                    posterUrl: _posterUrlController.text.trim(),
                    cinemaId: _selectedCinemaId!,
                    rating: double.parse(_ratingController.text.trim()),
                    releaseDate: _releaseDate!.millisecondsSinceEpoch,
                  );

                  context.read<AdminBloc>().add(UpdateMovie(updatedMovie));
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã cập nhật phim thành công!'),
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
                  setState(() => _isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        );
  }
}
