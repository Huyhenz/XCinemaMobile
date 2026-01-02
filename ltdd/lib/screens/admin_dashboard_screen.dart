// File: lib/screens/admin_dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/admin/admin_bloc.dart';
import '../blocs/admin/admin_event.dart';
import '../blocs/admin/admin_state.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/theater.dart';
import '../models/cinema.dart';
import '../models/voucher.dart';
import '../models/minigame_config.dart';
import '../models/minigame.dart';
import '../models/snack.dart';
import '../games/minigame_factory.dart';
import '../services/database_services.dart';
import 'admin_cleanup_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close drawer
  }

  Widget _getCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const _CreateCinemaTab();
      case 1:
        return const _ManageCinemasTab();
      case 2:
        return const _CreateMovieTab();
      case 3:
        return const _ManageMoviesTab();
      case 4:
        return const _CreateShowtimeTab();
      case 5:
        return const _ManageShowtimesTab();
      case 6:
        return const _CreateTheaterTab();
      case 7:
        return const _ManageTheatersTab();
      case 8:
        return const _CreateVoucherTab();
      case 9:
        return const _ManageVouchersTab();
      case 10:
        return const _ManageMinigameConfigTab();
      case 11:
        return const _CreateSnackTab();
      case 12:
        return const _ManageSnacksTab();
      default:
        return const _CreateCinemaTab();
    }
  }

  String _getCurrentTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tạo Rạp Chiếu';
      case 1:
        return 'Quản Lý Rạp Chiếu';
      case 2:
        return 'Tạo Phim';
      case 3:
        return 'Quản Lý Phim';
      case 4:
        return 'Tạo Lịch Chiếu';
      case 5:
        return 'Quản Lý Lịch Chiếu';
      case 6:
        return 'Tạo Phòng Chiếu';
      case 7:
        return 'Quản Lý Phòng Chiếu';
      case 8:
        return 'Tạo Voucher';
      case 9:
        return 'Quản Lý Voucher';
      case 10:
        return 'Quản Lý Minigame';
      case 11:
        return 'Tạo Bắp Nước';
      case 12:
        return 'Quản Lý Bắp Nước';
      default:
        return 'Admin Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminBloc()..add(LoadAdminData()),
      child: Scaffold(
        drawer: _buildDrawer(),
        appBar: AppBar(
          title: Text(_getCurrentTitle()),
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
        ),
        body: _getCurrentTab(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE50914),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.theaters, 'Tạo Rạp Chiếu', 0),
          _buildDrawerItem(Icons.business, 'Quản Lý Rạp Chiếu', 1),
          const Divider(color: Color(0xFF2A2A2A)),
          _buildDrawerItem(Icons.movie, 'Tạo Phim', 2),
          _buildDrawerItem(Icons.edit, 'Quản Lý Phim', 3),
          _buildDrawerItem(Icons.schedule, 'Tạo Lịch Chiếu', 4),
          _buildDrawerItem(Icons.event_available, 'Quản Lý Lịch Chiếu', 5),
          _buildDrawerItem(Icons.meeting_room, 'Tạo Phòng Chiếu', 6),
          _buildDrawerItem(Icons.room, 'Quản Lý Phòng Chiếu', 7),
          const Divider(color: Color(0xFF2A2A2A)),
          _buildDrawerItem(Icons.local_offer, 'Tạo Voucher', 8),
          _buildDrawerItem(Icons.card_giftcard, 'Quản Lý Voucher', 9),
          const Divider(color: Color(0xFF2A2A2A)),
          _buildDrawerItem(Icons.games, 'Quản Lý Minigame', 10),
          const Divider(color: Color(0xFF2A2A2A)),
          _buildDrawerItem(Icons.fastfood, 'Tạo Bắp Nước', 11),
          _buildDrawerItem(Icons.restaurant_menu, 'Quản Lý Bắp Nước', 12),
          const Divider(color: Color(0xFF2A2A2A)),
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.grey),
            title: const Text(
              'Database Cleanup',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCleanupScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int tabIndex) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () => _navigateToTab(tabIndex),
      selected: _currentIndex == tabIndex,
      selectedTileColor: const Color(0xFF2A2A2A),
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

      context.read<AdminBloc>().add(CreateCinema(cinema));

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

// Tab 2: Manage Cinemas (Edit & Delete)
class _ManageCinemasTab extends StatelessWidget {
  const _ManageCinemasTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (state.cinemas.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.theaters_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có rạp chiếu nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo rạp chiếu mới ở tab "Tạo Rạp Chiếu"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.cinemas.length,
          itemBuilder: (context, index) {
            final cinema = state.cinemas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.theaters, color: Color(0xFFE50914), size: 28),
                ),
                title: Text(
                  cinema.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      cinema.address,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (cinema.phone != null && cinema.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ĐT: ${cinema.phone}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                    if (cinema.latitude != null && cinema.longitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Vị trí: ${cinema.latitude!.toStringAsFixed(6)}, ${cinema.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                      onPressed: () => _showEditCinemaDialog(context, cinema),
                      tooltip: 'Sửa rạp chiếu',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                      onPressed: () => _showDeleteCinemaConfirmDialog(context, cinema),
                      tooltip: 'Xóa rạp chiếu',
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

  void _showEditCinemaDialog(BuildContext context, CinemaModel cinema) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: adminBloc,
        child: _EditCinemaDialog(cinema: cinema),
      ),
    );
  }

  void _showDeleteCinemaConfirmDialog(BuildContext context, CinemaModel cinema) {
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
              'Bạn có chắc chắn muốn xóa rạp chiếu "${cinema.name}"?\n\nHành động này không thể hoàn tác.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  adminBloc.add(DeleteCinema(cinema.id));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã xóa rạp chiếu'),
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

// Edit Cinema Dialog Widget
class _EditCinemaDialog extends StatefulWidget {
  final CinemaModel cinema;
  const _EditCinemaDialog({required this.cinema});

  @override
  State<_EditCinemaDialog> createState() => _EditCinemaDialogState();
}

class _EditCinemaDialogState extends State<_EditCinemaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.cinema.name;
    _addressController.text = widget.cinema.address;
    _phoneController.text = widget.cinema.phone ?? '';
    _imageUrlController.text = widget.cinema.imageUrl ?? '';
    _latitudeController.text = widget.cinema.latitude?.toString() ?? '';
    _longitudeController.text = widget.cinema.longitude?.toString() ?? '';
  }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          const Icon(Icons.theaters, color: Color(0xFFE50914)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sửa Rạp Chiếu: ${widget.cinema.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tên Rạp Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.theaters),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên rạp' : null,
              ),
              const SizedBox(height: 16),
              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Địa Chỉ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Số Điện Thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Image URL
              TextFormField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Link Ảnh Rạp (URL)',
                  hintText: 'https://example.com/cinema.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Latitude
              TextFormField(
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Vĩ Độ (Latitude)',
                  hintText: '10.762622',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Longitude
              TextFormField(
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Kinh Độ (Longitude)',
                  hintText: '106.660172',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                  labelStyle: TextStyle(color: Colors.white),
                ),
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

            setState(() => _isSaving = true);
            try {
              double? latitude;
              double? longitude;
              if (_latitudeController.text.isNotEmpty) {
                latitude = double.tryParse(_latitudeController.text);
              }
              if (_longitudeController.text.isNotEmpty) {
                longitude = double.tryParse(_longitudeController.text);
              }

              final updatedCinema = CinemaModel(
                id: widget.cinema.id,
                name: _nameController.text.trim(),
                address: _addressController.text.trim(),
                phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
                latitude: latitude,
                longitude: longitude,
                createdAt: widget.cinema.createdAt,
              );

              context.read<AdminBloc>().add(UpdateCinema(updatedCinema));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã cập nhật rạp chiếu thành công!'),
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

// Tab 3: Create Movie - IMPROVED
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
  final _trailerUrlController = TextEditingController();
  final _ageRatingController = TextEditingController();
  final _posterUrlController = TextEditingController();
  DateTime? _releaseDate;
  bool _isCreating = false;
  bool _isLoadingCinemas = true;
  bool _createForAllCinemas = false;

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
    _trailerUrlController.dispose();
    _posterUrlController.dispose();
    super.dispose();
  }

  Future<void> _createMovie() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_createForAllCinemas && (_selectedCinemaId == null || _selectedCinemaId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn rạp chiếu hoặc chọn tạo cho tất cả rạp'),
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
      final List<String> cinemaIds = _createForAllCinemas 
          ? _cinemas.map((c) => c.id).toList()
          : [_selectedCinemaId!];

      int successCount = 0;
      int failCount = 0;

      for (final cinemaId in cinemaIds) {
        try {
          final movie = MovieModel(
            id: '',
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            genre: _genreController.text.trim(),
            duration: int.parse(_durationController.text.trim()),
            posterUrl: _posterUrlController.text.trim(),
            cinemaId: cinemaId,
            trailerUrl: _trailerUrlController.text.trim().isEmpty ? null : _trailerUrlController.text.trim(),
            ageRating: _ageRatingController.text.trim().isEmpty ? null : _ageRatingController.text.trim(),
            releaseDate: _releaseDate!.millisecondsSinceEpoch,
          );

          context.read<AdminBloc>().add(CreateMovie(movie));
          successCount++;
        } catch (e) {
          print('Error creating movie for cinema $cinemaId: $e');
          failCount++;
        }
      }

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedCinemaId = null;
        _releaseDate = null;
        _createForAllCinemas = false;
      });

      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo phim thành công cho ${successCount} rạp!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Đã tạo phim cho $successCount rạp, thất bại $failCount rạp'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
                else ...[
                  // Checkbox for "Create for all cinemas"
                  CheckboxListTile(
                    title: const Text(
                      'Tạo cho tất cả rạp',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: const Text(
                      'Tạo phim này cho tất cả rạp cùng lúc',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _createForAllCinemas,
                    onChanged: (value) {
                      setState(() {
                        _createForAllCinemas = value ?? false;
                        if (_createForAllCinemas) {
                          _selectedCinemaId = null;
                        }
                      });
                    },
                    activeColor: const Color(0xFFE50914),
                  ),
                  const SizedBox(height: 8),
                  // Cinema dropdown (disabled when "create for all" is selected)
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
                    onChanged: _createForAllCinemas ? null : (value) {
                      setState(() {
                        _selectedCinemaId = value;
                      });
                    },
                    validator: _createForAllCinemas ? null : (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
                  ),
                ],
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

                // Trailer URL
                TextFormField(
                  controller: _trailerUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Link Trailer (URL)',
                    hintText: 'https://youtube.com/watch?v=... hoặc link video khác',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.play_circle_outline),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final uri = Uri.tryParse(value.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Vui lòng nhập URL hợp lệ (bắt đầu bằng http:// hoặc https://)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age Rating
                TextFormField(
                  controller: _ageRatingController,
                  decoration: const InputDecoration(
                    labelText: 'Độ Tuổi Xem (Tùy chọn)',
                    hintText: 'VD: T13, T16, T18, P (Phổ thông). Để trống = Tất cả độ tuổi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.child_care),
                  ),
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
  DateTime _startTime = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isCreating = false;
  bool _isLoadingCinemas = true;
  bool _isLoadingMovies = false;
  bool _isLoadingTheaters = false;
  bool _createForAllCinemas = false;
  bool _useRandomTime = false;

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
      // Use getMoviesByCinemaForAdmin to show all movies including expired ones in admin dashboard
      List<MovieModel> movies = await DatabaseService().getMoviesByCinemaForAdmin(cinemaId);
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
    if (cinemaId != null && cinemaId.isNotEmpty && !_createForAllCinemas) {
      _loadMoviesByCinema(cinemaId);
      _loadTheatersByCinema(cinemaId);
    }
  }

  // Generate random time between 7 AM and 11 PM
  DateTime _generateRandomTime(DateTime baseDate) {
    final random = Random();
    // Random hour between 7 (7 AM) and 23 (11 PM)
    final hour = 7 + random.nextInt(17); // 7 to 23 inclusive
    // Random minute in 5-minute intervals: 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55
    final minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    final minute = minuteOptions[random.nextInt(minuteOptions.length)];
    
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // Select date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Đảm bảo initialDate không nhỏ hơn firstDate
    // Nếu showtime cũ trong quá khứ, dùng hôm nay làm initialDate
    final initialDate = _startTime.isBefore(today) ? today : _startTime;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
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
    if (!_createForAllCinemas && (_selectedCinemaId == null || _selectedCinemaId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn rạp chiếu hoặc chọn tạo cho tất cả rạp'),
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
    if (!_createForAllCinemas && _selectedTheaterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      int successCount = 0;
      int failCount = 0;

      if (_createForAllCinemas) {
        // Create showtimes for all cinemas
        for (final cinema in _cinemas) {
          try {
            // Get all theaters for this cinema
            final theaters = await DatabaseService().getTheatersByCinema(cinema.id);
            if (theaters.isEmpty) {
              print('No theaters found for cinema ${cinema.id}');
              continue;
            }

            // Get movies for this cinema (to check if the selected movie exists in this cinema)
            final cinemaMovies = await DatabaseService().getMoviesByCinemaForAdmin(cinema.id);
            final movieExists = cinemaMovies.any((m) => m.id == _selectedMovieId);
            
            if (!movieExists) {
              print('Movie ${_selectedMovieId} does not exist in cinema ${cinema.id}');
              continue;
            }

            // Create showtime for each theater in this cinema
            for (final theater in theaters) {
              try {
                // Generate time: use random if enabled, otherwise use selected time
                final showtimeDateTime = _useRandomTime 
                    ? _generateRandomTime(_startTime)
                    : _startTime;

                final showtime = ShowtimeModel(
                  id: '',
                  movieId: _selectedMovieId!,
                  theaterId: theater.id,
                  startTime: showtimeDateTime.millisecondsSinceEpoch,
                  availableSeats: theater.seats,
                );
                context.read<AdminBloc>().add(CreateShowtime(showtime));
                successCount++;
              } catch (e) {
                print('Error creating showtime for theater ${theater.id}: $e');
                failCount++;
              }
            }
          } catch (e) {
            print('Error processing cinema ${cinema.id}: $e');
            failCount++;
          }
        }
      } else {
        // Create showtime for single cinema
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

        // Generate time: use random if enabled, otherwise use selected time
        final showtimeDateTime = _useRandomTime 
            ? _generateRandomTime(_startTime)
            : _startTime;

        final showtime = ShowtimeModel(
          id: '',
          movieId: _selectedMovieId!,
          theaterId: _selectedTheaterId!,
          startTime: showtimeDateTime.millisecondsSinceEpoch,
          availableSeats: theater.seats,
        );
        context.read<AdminBloc>().add(CreateShowtime(showtime));
        successCount++;
      }

      // Reset form
      setState(() {
        _selectedCinemaId = null;
        _selectedMovieId = null;
        _selectedTheaterId = null;
        _movies = [];
        _theaters = [];
        _startTime = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _createForAllCinemas = false;
        _useRandomTime = false;
      });

      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo lịch chiếu thành công! (${successCount} lịch chiếu)'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Đã tạo $successCount lịch chiếu, thất bại $failCount lịch chiếu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
          else ...[
            // Checkbox for "Create for all cinemas"
            CheckboxListTile(
              title: const Text(
                'Tạo cho tất cả rạp',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                'Tạo lịch chiếu cho tất cả rạp cùng lúc',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _createForAllCinemas,
              onChanged: (value) {
                setState(() {
                  _createForAllCinemas = value ?? false;
                  if (_createForAllCinemas) {
                    _selectedCinemaId = null;
                    _selectedMovieId = null;
                    _selectedTheaterId = null;
                    _movies = [];
                    _theaters = [];
                  }
                });
              },
              activeColor: const Color(0xFFE50914),
            ),
            const SizedBox(height: 8),
            // Cinema dropdown (disabled when "create for all" is selected)
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
              onChanged: _createForAllCinemas ? null : _onCinemaChanged,
              validator: _createForAllCinemas ? null : (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
            ),
          ],
          const SizedBox(height: 16),

          // Movie Selection (chỉ hiển thị sau khi chọn cinema hoặc khi tạo cho tất cả rạp)
          if (_createForAllCinemas || (_selectedCinemaId != null && _selectedCinemaId!.isNotEmpty)) ...[
            // When creating for all cinemas, load all movies
            if (_createForAllCinemas) ...[
              FutureBuilder<List<MovieModel>>(
                future: DatabaseService().getAllMoviesForAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Color(0xFFE50914)),
                    ));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
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
                              'Không có phim nào trong hệ thống. Vui lòng tạo phim trước.',
                              style: TextStyle(color: Colors.orange, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final allMovies = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedMovieId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn Phim *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.movie),
                    ),
                    items: allMovies.map((movie) {
                      return DropdownMenuItem<String>(
                        value: movie.id,
                        child: Text(
                          movie.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return allMovies.map((movie) {
                        return Text(
                          movie.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }).toList();
                    },
                    onChanged: (value) {
                      setState(() => _selectedMovieId = value);
                    },
                    validator: (value) => value == null ? 'Vui lòng chọn phim' : null,
                  );
                },
              ),
            ] else
            // When creating for single cinema, use existing logic
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
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Chọn Phim *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.movie),
                ),
                items: _movies.map((movie) {
                  return DropdownMenuItem<String>(
                    value: movie.id,
                    child: Text(
                      movie.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (BuildContext context) {
                  return _movies.map((movie) {
                    return Text(
                      movie.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                onChanged: (value) {
                  setState(() => _selectedMovieId = value);
                },
                validator: (value) => value == null ? 'Vui lòng chọn phim' : null,
              ),
            const SizedBox(height: 16),

            // Theater Selection (chỉ hiển thị khi tạo cho 1 rạp, không hiển thị khi tạo cho tất cả rạp)
            if (_createForAllCinemas)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lịch chiếu sẽ được tạo cho tất cả phòng chiếu của tất cả rạp',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingTheaters)
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

          // Random Time Checkbox
          CheckboxListTile(
            title: const Text(
              'Random thời gian',
              style: TextStyle(fontSize: 16),
            ),
            subtitle: const Text(
              'Tự động tạo thời gian ngẫu nhiên từ 7h sáng đến 11h tối (chỉ áp dụng khi tạo cho tất cả rạp)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _useRandomTime,
            onChanged: (value) {
              setState(() {
                _useRandomTime = value ?? false;
              });
            },
            activeColor: const Color(0xFFE50914),
          ),
          const SizedBox(height: 8),

          // Date & Time Selection
          InkWell(
            onTap: _useRandomTime && _createForAllCinemas ? null : _selectDateTime,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ngày và Giờ Chiếu *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: _useRandomTime && _createForAllCinemas
                    ? const Icon(Icons.shuffle, color: Colors.orange)
                    : null,
              ),
              child: Text(
                _useRandomTime && _createForAllCinemas
                    ? '${DateFormat('dd/MM/yyyy').format(_startTime)} - Thời gian sẽ được random'
                    : '${DateFormat('dd/MM/yyyy').format(_startTime)} ${_selectedTime.format(context)}',
                style: TextStyle(
                  color: _useRandomTime && _createForAllCinemas ? Colors.orange : Colors.white,
                ),
              ),
            ),
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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Đảm bảo initialDate không nhỏ hơn firstDate
    // Nếu showtime cũ trong quá khứ, dùng hôm nay làm initialDate
    final initialDate = _startTime.isBefore(today) ? today : _startTime;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today, // Cho phép chọn từ hôm nay trở đi
      lastDate: today.add(const Duration(days: 365)),
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
  final _singlePriceController = TextEditingController();
  final _couplePriceController = TextEditingController();
  final _vipPriceController = TextEditingController();
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
    // Load giá hiện tại
    _singlePriceController.text = widget.theater.singleSeatPrice.toStringAsFixed(0);
    _couplePriceController.text = widget.theater.coupleSeatPrice.toStringAsFixed(0);
    _vipPriceController.text = widget.theater.vipSeatPrice.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _seatsPerRowController.dispose();
    _singlePriceController.dispose();
    _couplePriceController.dispose();
    _vipPriceController.dispose();
    super.dispose();
  }

  // Tạo danh sách ghế và phân loại ghế dựa trên loại phòng (giống như trong _CreateTheaterTab)
  Map<String, dynamic> _generateSeats(String theaterType, int rows, int seatsPerRow) {
    List<String> seats = [];
    Map<String, String> seatTypes = {};

    switch (theaterType) {
      case 'normal':
        // Phòng thường: hàng cuối là ghế đôi, các hàng khác là ghế đơn
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, ...
          String seatType = (i == rows - 1) ? 'couple' : 'single'; // Hàng cuối là ghế đôi
          for (int j = 1; j <= seatsPerRow; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = seatType;
          }
        }
        break;
      case 'couple':
        // Phòng couple: tất cả là ghế đôi (chia đều 2 bên)
        int leftSeats = seatsPerRow ~/ 2;
        int rightSeats = seatsPerRow - leftSeats;
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, ...
          // Bên trái
          for (int j = 1; j <= leftSeats; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'couple';
          }
          // Bên phải
          for (int j = leftSeats + 1; j <= seatsPerRow; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'couple';
          }
        }
        break;
      case 'vip':
        // Phòng VIP: tất cả là giường đôi (VIP)
        // Nếu seatsPerRow là số chẵn, chia đều 2 bên
        int leftSeats = seatsPerRow ~/ 2;
        int rightSeats = seatsPerRow - leftSeats;
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, ...
          // Bên trái
          for (int j = 1; j <= leftSeats; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'vip';
          }
          // Bên phải
          for (int j = leftSeats + 1; j <= seatsPerRow; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'vip';
          }
        }
        break;
      default:
        // Fallback: tất cả là ghế đơn
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i);
          for (int j = 1; j <= seatsPerRow; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'single';
          }
        }
    }

    return {
      'seats': seats,
      'seatTypes': seatTypes,
      'capacity': seats.length,
    };
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
              // Hiển thị loại phòng (read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Loại phòng: ${widget.theater.theaterType == 'normal' ? 'Thường' : widget.theater.theaterType == 'couple' ? 'Couple' : 'VIP'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
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
              // Chỉ hiển thị số ghế mỗi hàng cho phòng normal
              if (widget.theater.theaterType == 'normal') ...[
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
              ] else ...[
                // Phòng Couple và VIP: tự động tính số ghế mỗi hàng
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Số ghế mỗi hàng: ${widget.theater.seats.isNotEmpty ? (widget.theater.seats.length ~/ widget.theater.seats.map((seat) => seat[0]).toSet().length) : 0} (tự động)',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _singlePriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Giá Ghế Đơn (₫) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá ghế đơn';
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) return 'Giá phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _couplePriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Giá Ghế Đôi (₫) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá ghế đôi';
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) return 'Giá phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vipPriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Giá Giường Đôi VIP (₫) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá giường đôi VIP';
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) return 'Giá phải lớn hơn 0';
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
                int seatsPerRow;
                
                // Phòng Couple và VIP: tự động tính số ghế mỗi hàng từ seats hiện tại
                if (widget.theater.theaterType == 'couple' || widget.theater.theaterType == 'vip') {
                  if (widget.theater.seats.isNotEmpty) {
                    final currentRows = widget.theater.seats.map((seat) => seat[0]).toSet().length;
                    seatsPerRow = widget.theater.seats.length ~/ currentRows;
                  } else {
                    // Nếu không có seats, dùng giá trị mặc định
                    seatsPerRow = widget.theater.theaterType == 'couple' ? 4 : 4;
                  }
                } else {
                  // Phòng normal: lấy từ input
                  seatsPerRow = int.parse(_seatsPerRowController.text);
                }
                
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

                // Regenerate seats based on theaterType, rows and seatsPerRow (giữ nguyên loại ghế)
                final singlePrice = double.parse(_singlePriceController.text);
                final couplePrice = double.parse(_couplePriceController.text);
                final vipPrice = double.parse(_vipPriceController.text);
                
                final config = _generateSeats(widget.theater.theaterType, rows, seatsPerRow);
                
                final updatedTheater = TheaterModel(
                  id: widget.theater.id,
                  name: _nameController.text.trim(),
                  cinemaId: widget.theater.cinemaId,
                  capacity: config['capacity'] as int,
                  seats: config['seats'] as List<String>,
                  seatTypes: config['seatTypes'] as Map<String, String>,
                  theaterType: widget.theater.theaterType, // Giữ nguyên loại phòng
                  singleSeatPrice: singlePrice,
                  coupleSeatPrice: couplePrice,
                  vipSeatPrice: vipPrice,
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
  String? _selectedTheaterType; // 'normal', 'couple', 'vip'
  final _singlePriceController = TextEditingController();
  final _couplePriceController = TextEditingController();
  final _vipPriceController = TextEditingController();
  bool _isLoading = true;
  bool _isCreating = false;
  bool _createForAllCinemas = false;

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

  // Tự động setup số hàng và số ghế dựa trên loại phòng
  void _setupTheaterConfig() {
    if (_selectedTheaterType == null) return;
    
    setState(() {
      // Setup giá mặc định nếu chưa có
      if (_singlePriceController.text.isEmpty) {
        _singlePriceController.text = '50000';
      }
      if (_couplePriceController.text.isEmpty) {
        _couplePriceController.text = '80000';
      }
      if (_vipPriceController.text.isEmpty) {
        _vipPriceController.text = '150000';
      }
    });
  }

  // Tạo danh sách ghế và phân loại ghế dựa trên loại phòng
  Map<String, dynamic> _generateSeats(String theaterType) {
    List<String> seats = [];
    Map<String, String> seatTypes = {};
    int rows, seatsPerRow;

    switch (theaterType) {
      case 'normal':
        // Phòng thường: 8 hàng, 12 ghế/hàng, hàng cuối là ghế đôi
        rows = 8;
        seatsPerRow = 12;
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, ...
          String seatType = (i == rows - 1) ? 'couple' : 'single'; // Hàng cuối là ghế đôi
          for (int j = 1; j <= seatsPerRow; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = seatType;
          }
        }
        break;
      case 'couple':
        // Phòng couple: 6 hàng, 4 ghế đôi/hàng, tất cả là ghế đôi (2 bên, mỗi bên 2 ghế, lối đi giữa)
        rows = 6;
        seatsPerRow = 4; // Tổng 4 ghế đôi mỗi hàng (2 bên x 2 ghế)
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, ...
          // Bên trái: 2 ghế đôi (1, 2)
          for (int j = 1; j <= 2; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'couple';
          }
          // Bên phải: 2 ghế đôi (3, 4)
          for (int j = 3; j <= 4; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'couple';
          }
        }
        break;
      case 'vip':
        // Phòng VIP: 4 hàng, mỗi hàng 4 giường đôi (2 bên, mỗi bên 2 giường, lối đi giữa)
        rows = 4;
        seatsPerRow = 4; // Tổng 4 giường đôi mỗi hàng (2 bên x 2 giường)
        for (int i = 0; i < rows; i++) {
          String row = String.fromCharCode(65 + i); // A, B, C, D
          // Bên trái: 2 giường đôi (1, 2)
          for (int j = 1; j <= 2; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'vip';
          }
          // Bên phải: 2 giường đôi (3, 4)
          for (int j = 3; j <= 4; j++) {
            String seatName = '$row$j';
            seats.add(seatName);
            seatTypes[seatName] = 'vip';
          }
        }
        break;
      default:
        rows = 0;
        seatsPerRow = 0;
    }

    return {
      'seats': seats,
      'seatTypes': seatTypes,
      'rows': rows,
      'seatsPerRow': seatsPerRow,
      'capacity': seats.length,
    };
  }

  Future<void> _createTheater() async {
    if (_selectedTheaterType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại phòng chiếu'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }
    if (!_createForAllCinemas && (_selectedCinemaId == null || _selectedCinemaId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn rạp chiếu hoặc chọn tạo cho tất cả rạp'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final singlePrice = double.tryParse(_singlePriceController.text) ?? 0.0;
      final couplePrice = double.tryParse(_couplePriceController.text) ?? 0.0;
      final vipPrice = double.tryParse(_vipPriceController.text) ?? 0.0;

      if (singlePrice <= 0 || couplePrice <= 0 || vipPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập giá hợp lệ cho tất cả loại ghế'),
            backgroundColor: Color(0xFFE50914),
          ),
        );
        setState(() => _isCreating = false);
        return;
      }

      final config = _generateSeats(_selectedTheaterType!);
      
      int successCount = 0;
      int failCount = 0;

      if (_createForAllCinemas) {
        // Tạo phòng chiếu cho tất cả rạp
        for (final cinema in _cinemas) {
          try {
            final theater = TheaterModel(
              id: '',
              name: _nameController.text.trim(),
              cinemaId: cinema.id,
              capacity: config['capacity'] as int,
              seats: config['seats'] as List<String>,
              seatTypes: config['seatTypes'] as Map<String, String>,
              theaterType: _selectedTheaterType!,
              singleSeatPrice: singlePrice,
              coupleSeatPrice: couplePrice,
              vipSeatPrice: vipPrice,
            );
            context.read<AdminBloc>().add(CreateTheater(theater));
            successCount++;
          } catch (e) {
            print('Error creating theater for cinema ${cinema.id}: $e');
            failCount++;
          }
        }
      } else {
        // Tạo phòng chiếu cho một rạp
        final theater = TheaterModel(
          id: '',
          name: _nameController.text.trim(),
          cinemaId: _selectedCinemaId!,
          capacity: config['capacity'] as int,
          seats: config['seats'] as List<String>,
          seatTypes: config['seatTypes'] as Map<String, String>,
          theaterType: _selectedTheaterType!,
          singleSeatPrice: singlePrice,
          coupleSeatPrice: couplePrice,
          vipSeatPrice: vipPrice,
        );
        context.read<AdminBloc>().add(CreateTheater(theater));
        successCount++;
      }

      // Reset form
      _nameController.clear();
      _singlePriceController.clear();
      _couplePriceController.clear();
      _vipPriceController.clear();
      setState(() {
        _selectedCinemaId = null;
        _selectedTheaterType = null;
        _createForAllCinemas = false;
      });

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã tạo phòng chiếu thành công cho ${successCount} rạp!'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Đã tạo phòng chiếu cho $successCount rạp, thất bại $failCount rạp'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
    _singlePriceController.dispose();
    _couplePriceController.dispose();
    _vipPriceController.dispose();
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
              // Checkbox for "Create for all cinemas"
              CheckboxListTile(
                title: const Text(
                  'Tạo cho tất cả rạp',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Tạo phòng chiếu này cho tất cả rạp cùng lúc',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _createForAllCinemas,
                onChanged: (value) {
                  setState(() {
                    _createForAllCinemas = value ?? false;
                    if (_createForAllCinemas) {
                      _selectedCinemaId = null;
                    }
                  });
                },
                activeColor: const Color(0xFFE50914),
              ),
              const SizedBox(height: 8),
              // Cinema Selection (disabled when "create for all" is selected)
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
                onChanged: _createForAllCinemas ? null : (value) {
                  setState(() {
                    _selectedCinemaId = value;
                  });
                },
                validator: _createForAllCinemas ? null : (value) => value == null ? 'Vui lòng chọn rạp chiếu' : null,
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

              // Theater Type
              DropdownButtonFormField<String>(
                value: _selectedTheaterType,
                decoration: const InputDecoration(
                  labelText: 'Loại Phòng Chiếu *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'normal',
                    child: Text(
                      'Phòng Thường',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'couple',
                    child: Text(
                      'Phòng Couple',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'vip',
                    child: Text(
                      'Phòng VIP',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTheaterType = value;
                    _setupTheaterConfig();
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn loại phòng chiếu' : null,
              ),
              const SizedBox(height: 16),

              // Hiển thị thông tin setup tự động
              if (_selectedTheaterType != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE50914).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cấu hình tự động:',
                        style: TextStyle(
                          color: Color(0xFFE50914),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTheaterType == 'normal'
                            ? '• 8 hàng (A-H), 12 ghế/hàng\n• Hàng A-G: Ghế đơn\n• Hàng H: Ghế đôi'
                            : _selectedTheaterType == 'couple'
                                ? '• 6 hàng (A-F), 4 ghế đôi/hàng\n• Tất cả: Ghế đôi'
                                : '• 4 hàng (A-D), 4 giường đôi/hàng\n• Lối đi giữa, mỗi bên 2 giường đôi',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Giá ghế đơn
              TextFormField(
                controller: _singlePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Giá Ghế Đơn (VND) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '50000',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá ghế đơn';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Giá phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Giá ghế đôi
              TextFormField(
                controller: _couplePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Giá Ghế Đôi (VND) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '80000',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá ghế đôi';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Giá phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Giá ghế VIP
              TextFormField(
                controller: _vipPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Giá Ghế VIP (VND) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '150000',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá ghế VIP';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Giá phải là số dương';
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
                      '${movie.duration} phút',
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
  late final TextEditingController _trailerUrlController;
  late final TextEditingController _ageRatingController;
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
    _trailerUrlController = TextEditingController(text: widget.movie.trailerUrl ?? '');
    _ageRatingController = TextEditingController(text: widget.movie.ageRating ?? '');
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
    _trailerUrlController.dispose();
    _ageRatingController.dispose();
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
                    controller: _trailerUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Link Trailer (URL)',
                      hintText: 'https://youtube.com/watch?v=... hoặc link video khác',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.play_circle_outline),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasScheme) {
                          return 'Vui lòng nhập URL hợp lệ';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageRatingController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Độ Tuổi Xem (Tùy chọn)',
                      hintText: 'VD: T13, T16, T18, P (Phổ thông). Để trống = Tất cả độ tuổi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.child_care),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
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
                    trailerUrl: _trailerUrlController.text.trim().isEmpty ? null : _trailerUrlController.text.trim(),
                    ageRating: _ageRatingController.text.trim().isEmpty ? null : _ageRatingController.text.trim(),
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

// Tab 8: Create Voucher
class _CreateVoucherTab extends StatefulWidget {
  const _CreateVoucherTab();

  @override
  State<_CreateVoucherTab> createState() => _CreateVoucherTabState();
}

class _CreateVoucherTabState extends State<_CreateVoucherTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _pointsController = TextEditingController();
  final _taskIdController = TextEditingController();
  String _selectedType = 'percent';
  String _voucherType = 'free'; // 'free', 'task', 'points'
  DateTime? _expiryDate;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin khi init (free voucher mặc định)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillVoucherInfo();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _pointsController.dispose();
    _taskIdController.dispose();
    super.dispose();
  }

  // Generate voucher code ngẫu nhiên (6 ký tự)
  void _generateVoucherCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    
    // Tạo mã 6 ký tự ngẫu nhiên
    final code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    
    setState(() {
      _codeController.text = code;
    });
  }

  // Tự động điền thông tin mặc định cho voucher
  void _autoFillVoucherInfo() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    
    // Generate mã 6 ký tự
    final code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    _codeController.text = code;
    
    // Set giá trị giảm giá mặc định theo loại voucher
    if (_voucherType == 'free') {
      // Free voucher: giá trị thấp (5-15%)
      _selectedType = 'percent';
      _discountController.text = (5 + random.nextInt(11)).toString(); // 5-15%
      _pointsController.clear();
      _taskIdController.clear();
    } else if (_voucherType == 'task') {
      // Task voucher: giá trị trung bình (10-20%)
      _selectedType = 'percent';
      _discountController.text = (10 + random.nextInt(11)).toString(); // 10-20%
      // Tự động set task ID mẫu
      _taskIdController.text = 'task_${1 + random.nextInt(10)}'; // task_1 đến task_10
      _pointsController.clear();
    } else if (_voucherType == 'points') {
      // Points voucher: giá trị cao hơn (15-25%)
      _selectedType = 'percent';
      _discountController.text = (15 + random.nextInt(11)).toString(); // 15-25%
      // Tự động set điểm (100-500, bước 50)
      final pointsOptions = [100, 150, 200, 250, 300, 350, 400, 450, 500];
      _pointsController.text = pointsOptions[random.nextInt(pointsOptions.length)].toString();
      _taskIdController.clear();
    }
    
    // Set ngày hết hạn mặc định là 30 ngày sau
    if (_expiryDate == null) {
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  Widget _buildVoucherTypeOption(String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _voucherType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _voucherType = value;
          // Tự động điền thông tin khi chọn loại voucher
          _autoFillVoucherInfo();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A2A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
          ],
        ),
      ),
    );
  }

  Future<void> _createVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày hết hạn'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    // Validate based on voucher type
    if (_voucherType == 'points' && (_pointsController.text.trim().isEmpty || int.tryParse(_pointsController.text.trim()) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher điểm cần nhập số điểm hợp lệ'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    if (_voucherType == 'task' && _taskIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher nhiệm vụ cần nhập ID nhiệm vụ'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final voucher = VoucherModel(
        id: _codeController.text.trim().toUpperCase(),
        discount: double.parse(_discountController.text.trim()),
        type: _selectedType,
        expiryDate: _expiryDate!.millisecondsSinceEpoch,
        isActive: true,
        voucherType: _voucherType,
        points: _voucherType == 'points' && _pointsController.text.trim().isNotEmpty
            ? int.tryParse(_pointsController.text.trim())
            : null,
        requiredTaskId: _voucherType == 'task' && _taskIdController.text.trim().isNotEmpty
            ? _taskIdController.text.trim()
            : null,
        isUnlocked: false, // Task voucher sẽ unlock khi task hoàn thành
      );

      context.read<AdminBloc>().add(CreateVoucher(voucher));

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedType = 'percent';
        _voucherType = 'free';
        _expiryDate = null;
        _pointsController.clear();
        _taskIdController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã tạo voucher ${_voucherType == 'free' ? 'miễn phí' : _voucherType == 'task' ? 'nhiệm vụ' : 'điểm'} thành công!'),
          backgroundColor: const Color(0xFF4CAF50),
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
            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn loại voucher và bấm "Tạo" - Hệ thống sẽ tự động điền thông tin',
                      style: TextStyle(color: Colors.blue[200], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Voucher Type Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loại Voucher *',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Free Voucher
                  _buildVoucherTypeOption(
                    'free',
                    'Voucher Miễn Phí',
                    'Giá trị thấp, người dùng có thể nhận ngay',
                    Icons.card_giftcard,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 8),
                  // Task Voucher
                  _buildVoucherTypeOption(
                    'task',
                    'Voucher Nhiệm Vụ',
                    'Phải hoàn thành nhiệm vụ để mở khóa',
                    Icons.task_alt,
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 8),
                  // Points Voucher
                  _buildVoucherTypeOption(
                    'points',
                    'Voucher Đổi Điểm',
                    'Cần đủ điểm để đổi được voucher',
                    Icons.stars,
                    const Color(0xFFE50914),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preview voucher info (hidden fields for form validation)
            // Voucher Code (hidden but required for validation)
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng chọn loại voucher' : null,
            ),
            
            // Discount Type (hidden)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _selectedType),
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
            
            // Discount Amount (hidden)
            TextFormField(
              controller: _discountController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Vui lòng chọn loại voucher';
                final discount = double.tryParse(value!);
                if (discount == null) return 'Lỗi hệ thống';
                if (_selectedType == 'percent' && (discount <= 0 || discount > 100)) {
                  return 'Lỗi giá trị';
                }
                return null;
              },
            ),
            
            // Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _voucherType == 'free'
                            ? Icons.card_giftcard
                            : _voucherType == 'task'
                                ? Icons.task_alt
                                : Icons.stars,
                        color: _voucherType == 'free'
                            ? const Color(0xFF4CAF50)
                            : _voucherType == 'task'
                                ? const Color(0xFF2196F3)
                                : const Color(0xFFE50914),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _codeController.text.isEmpty ? '---' : _codeController.text.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _discountController.text.isEmpty
                                  ? '---'
                                  : 'Giảm ${_discountController.text}%',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_discountController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A2A)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _expiryDate == null
                              ? 'Chưa có ngày hết hạn'
                              : 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(_expiryDate!)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    if (_voucherType == 'points' && _pointsController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.stars, color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Cần ${_pointsController.text} điểm',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (_voucherType == 'task' && _taskIdController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.task_alt, color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Nhiệm vụ: ${_taskIdController.text}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hidden fields for validation
            // Points (hidden)
            TextFormField(
              controller: _pointsController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) {
                if (_voucherType == 'points' && (value?.isEmpty ?? true)) {
                  return 'Lỗi hệ thống';
                }
                return null;
              },
            ),
            
            // Task ID (hidden)
            TextFormField(
              controller: _taskIdController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) {
                if (_voucherType == 'task' && (value?.isEmpty ?? true)) {
                  return 'Lỗi hệ thống';
                }
                return null;
              },
            ),
            
            // Expiry Date (hidden, auto-set to 30 days)
            // Set default expiry date
            Builder(
              builder: (context) {
                if (_expiryDate == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _expiryDate = DateTime.now().add(const Duration(days: 30));
                    });
                  });
                }
                return const SizedBox.shrink();
              },
            ),
            
            const SizedBox(height: 24),

            // Create Button
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createVoucher,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                _isCreating 
                    ? 'Đang tạo...'
                    : 'TẠO VOUCHER ${_voucherType == 'free' ? 'MIỄN PHÍ' : _voucherType == 'task' ? 'NHIỆM VỤ' : 'ĐIỂM'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _voucherType == 'free'
                    ? const Color(0xFF4CAF50)
                    : _voucherType == 'task'
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE50914),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 9: Manage Vouchers
class _ManageVouchersTab extends StatelessWidget {
  const _ManageVouchersTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        if (state.vouchers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có voucher nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo voucher mới ở tab "Create Voucher"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.vouchers.length,
          itemBuilder: (context, index) {
            final voucher = state.vouchers[index];
            final isExpired = DateTime.fromMillisecondsSinceEpoch(voucher.expiryDate).isBefore(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpired || !voucher.isActive
                        ? Colors.grey[800]
                        : const Color(0xFFE50914).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: isExpired || !voucher.isActive ? Colors.grey : const Color(0xFFE50914),
                    size: 28,
                  ),
                ),
                title: Text(
                  voucher.id,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: isExpired ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      voucher.type == 'percent'
                          ? 'Giảm ${voucher.discount.toStringAsFixed(0)}%'
                          : 'Giảm ${NumberFormat('#,###', 'vi_VN').format(voucher.discount.toInt())} VND',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hết hạn: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(voucher.expiryDate))}',
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      voucher.isActive ? 'Đang hoạt động' : 'Đã tắt',
                      style: TextStyle(
                        color: voucher.isActive ? Colors.green : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isExpired)
                      Text(
                        'Đã hết hạn',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                      onPressed: () => _showEditVoucherDialog(context, voucher),
                      tooltip: 'Sửa voucher',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                      onPressed: () => _showDeleteVoucherConfirmDialog(context, voucher),
                      tooltip: 'Xóa voucher',
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

  void _showEditVoucherDialog(BuildContext context, VoucherModel voucher) {
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: adminBloc,
        child: _EditVoucherDialog(voucher: voucher),
      ),
    );
  }

  void _showDeleteVoucherConfirmDialog(BuildContext context, VoucherModel voucher) {
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
              'Bạn có chắc chắn muốn xóa voucher "${voucher.id}"?\n\nHành động này không thể hoàn tác.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  adminBloc.add(DeleteVoucher(voucher.id));
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã xóa voucher'),
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

// Edit Voucher Dialog Widget
class _EditVoucherDialog extends StatefulWidget {
  final VoucherModel voucher;
  const _EditVoucherDialog({required this.voucher});

  @override
  State<_EditVoucherDialog> createState() => _EditVoucherDialogState();
}

class _EditVoucherDialogState extends State<_EditVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  final _pointsController = TextEditingController();
  String _selectedType = 'percent';
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isSaving = false;
  bool _requiresPoints = false;

  @override
  void initState() {
    super.initState();
    _discountController.text = widget.voucher.discount.toString();
    _selectedType = widget.voucher.type;
    _expiryDate = DateTime.fromMillisecondsSinceEpoch(widget.voucher.expiryDate);
    _isActive = widget.voucher.isActive;
    _requiresPoints = widget.voucher.points != null;
    if (_requiresPoints) {
      _pointsController.text = widget.voucher.points.toString();
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          const Icon(Icons.local_offer, color: Color(0xFFE50914)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sửa Voucher: ${widget.voucher.id}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Discount Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Loại Giảm Giá *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                  labelStyle: TextStyle(color: Colors.white),
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                items: const [
                  DropdownMenuItem(value: 'percent', child: Text('Phần trăm (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Giá cố định (VND)')),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              // Discount Amount
              TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: _selectedType == 'percent' ? 'Giảm Giá (%) *' : 'Giảm Giá (VND) *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.discount),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số tiền giảm giá';
                  final discount = double.tryParse(value!);
                  if (discount == null) return 'Vui lòng nhập số hợp lệ';
                  if (_selectedType == 'percent' && (discount <= 0 || discount > 100)) {
                    return 'Phần trăm phải từ 1-100';
                  }
                  if (_selectedType == 'fixed' && discount <= 0) {
                    return 'Giá giảm phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Expiry Date
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
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
                    setState(() => _expiryDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày Hết Hạn *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'Chọn ngày hết hạn'
                        : DateFormat('dd/MM/yyyy').format(_expiryDate!),
                    style: TextStyle(
                      color: _expiryDate == null ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Requires Points Checkbox
              CheckboxListTile(
                title: const Text(
                  'Yêu cầu điểm để đổi voucher',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Nếu bật, user cần đủ điểm mới đổi được voucher này',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                value: _requiresPoints,
                onChanged: (value) {
                  setState(() {
                    _requiresPoints = value ?? false;
                    if (!_requiresPoints) {
                      _pointsController.clear();
                    }
                  });
                },
                activeColor: const Color(0xFFE50914),
              ),
              if (_requiresPoints) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Điểm cần để đổi *',
                    hintText: 'VD: 100, 200, 500',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stars),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  validator: (value) {
                    if (_requiresPoints && (value?.isEmpty ?? true)) {
                      return 'Vui lòng nhập điểm cần để đổi';
                    }
                    if (_requiresPoints && value != null && value.isNotEmpty) {
                      final points = int.tryParse(value);
                      if (points == null || points <= 0) {
                        return 'Điểm phải là số nguyên dương';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              // Active Status
              SwitchListTile(
                title: const Text(
                  'Trạng thái hoạt động',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _isActive ? 'Đang hoạt động' : 'Đã tắt',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                value: _isActive,
                activeColor: const Color(0xFFE50914),
                onChanged: (value) {
                  setState(() => _isActive = value);
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
            if (_expiryDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng chọn ngày hết hạn'),
                  backgroundColor: Color(0xFFE50914),
                ),
              );
              return;
            }

            setState(() => _isSaving = true);
            try {
              final updatedVoucher = VoucherModel(
                id: widget.voucher.id,
                discount: double.parse(_discountController.text.trim()),
                type: _selectedType,
                expiryDate: _expiryDate!.millisecondsSinceEpoch,
                isActive: _isActive,
                points: _requiresPoints && _pointsController.text.trim().isNotEmpty
                    ? int.tryParse(_pointsController.text.trim())
                    : null,
              );

              context.read<AdminBloc>().add(UpdateVoucher(updatedVoucher));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã cập nhật voucher thành công!'),
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

// Tab 11: Manage Minigame Config
class _ManageMinigameConfigTab extends StatefulWidget {
  const _ManageMinigameConfigTab();

  @override
  State<_ManageMinigameConfigTab> createState() => _ManageMinigameConfigTabState();
}

class _ManageMinigameConfigTabState extends State<_ManageMinigameConfigTab> {
  final DatabaseService _dbService = DatabaseService();
  List<MinigameItem> _games = [];
  Map<String, MinigameConfig> _configs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      _games = MinigameFactory.getAllGames();
      
      // Load configs từ database
      final savedConfigs = await _dbService.getAllMinigameConfigs();
      for (var config in savedConfigs) {
        _configs[config.gameId] = config;
      }
      
      // Thêm default configs cho những game chưa có config
      for (var game in _games) {
        if (!_configs.containsKey(game.id)) {
          _configs[game.id] = MinigameConfig.getDefault(game.id);
        }
      }
    } catch (e) {
      print('Error loading configs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig(String gameId, MinigameConfig config) async {
    try {
      await _dbService.saveMinigameConfig(config);
      setState(() {
        _configs[gameId] = config;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu cấu hình thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editConfig(MinigameItem game) {
    final config = _configs[game.id]!;
    
    final maxWrongAttemptsController = TextEditingController(
      text: config.maxWrongAttempts?.toString() ?? '',
    );
    final timeLimitController = TextEditingController(
      text: config.timeLimitSeconds?.toString() ?? '',
    );
    final maxLevelController = TextEditingController(
      text: config.maxLevel?.toString() ?? '',
    );
    final targetScoreController = TextEditingController(
      text: config.targetScore?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Chỉnh Sửa: ${game.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: maxWrongAttemptsController,
                decoration: const InputDecoration(
                  labelText: 'Số lần sai tối đa',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'VD: 5 (cho trò đoán chữ)',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeLimitController,
                decoration: const InputDecoration(
                  labelText: 'Thời gian giới hạn (giây)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'VD: 5 (cho trò toán học)',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxLevelController,
                decoration: const InputDecoration(
                  labelText: 'Level tối đa',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'VD: 5',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetScoreController,
                decoration: const InputDecoration(
                  labelText: 'Điểm mục tiêu',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'VD: 10',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newConfig = MinigameConfig(
                gameId: game.id,
                maxWrongAttempts: maxWrongAttemptsController.text.isNotEmpty
                    ? int.tryParse(maxWrongAttemptsController.text)
                    : null,
                timeLimitSeconds: timeLimitController.text.isNotEmpty
                    ? int.tryParse(timeLimitController.text)
                    : null,
                maxLevel: maxLevelController.text.isNotEmpty
                    ? int.tryParse(maxLevelController.text)
                    : null,
                targetScore: targetScoreController.text.isNotEmpty
                    ? int.tryParse(targetScoreController.text)
                    : null,
              );
              _saveConfig(game.id, newConfig);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Quản Lý Cấu Hình Minigame',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chỉnh sửa số lần, thời gian và các thông số khác cho từng trò chơi',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 24),
        ..._games.map((game) {
          final config = _configs[game.id]!;
          return Card(
            color: const Color(0xFF1A1A1A),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(game.icon, color: const Color(0xFF2196F3)),
              title: Text(
                game.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.description, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (config.maxWrongAttempts != null)
                        Chip(
                          label: Text('Sai tối đa: ${config.maxWrongAttempts}'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      if (config.timeLimitSeconds != null)
                        Chip(
                          label: Text('Thời gian: ${config.timeLimitSeconds}s'),
                          backgroundColor: Colors.red.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      if (config.maxLevel != null)
                        Chip(
                          label: Text('Level max: ${config.maxLevel}'),
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      if (config.targetScore != null)
                        Chip(
                          label: Text('Mục tiêu: ${config.targetScore}'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                onPressed: () => _editConfig(game),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Tab 11: Create Snack
class _CreateSnackTab extends StatefulWidget {
  const _CreateSnackTab();

  @override
  State<_CreateSnackTab> createState() => _CreateSnackTabState();
}

class _CreateSnackTabState extends State<_CreateSnackTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'popcorn';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin khi init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillSnackInfo();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Tự động điền thông tin cho snack
  void _autoFillSnackInfo() {
    final random = Random();
    
    // Danh sách snacks mẫu cho từng category
    final snackTemplates = {
      'popcorn': [
        {'name': 'Bắp Rang Bơ Lớn', 'description': 'Bắp rang bơ thơm ngon, size lớn', 'price': [45000, 50000, 55000]},
        {'name': 'Bắp Rang Bơ Vừa', 'description': 'Bắp rang bơ size vừa, đủ cho 1 người', 'price': [35000, 40000]},
        {'name': 'Bắp Ngọt Caramel', 'description': 'Bắp rang bơ với vị caramel đặc biệt', 'price': [50000, 55000, 60000]},
        {'name': 'Bắp Phô Mai', 'description': 'Bắp rang bơ phủ phô mai thơm ngon', 'price': [50000, 60000]},
        {'name': 'Bắp Mix 2 Vị', 'description': 'Bắp rang bơ mix 2 vị theo yêu cầu', 'price': [55000, 60000]},
      ],
      'drink': [
        {'name': 'Coca Cola', 'description': 'Nước ngọt Coca Cola lạnh', 'price': [25000, 30000]},
        {'name': 'Pepsi', 'description': 'Nước ngọt Pepsi lạnh', 'price': [25000, 30000]},
        {'name': 'Sprite', 'description': 'Nước ngọt Sprite mát lạnh', 'price': [25000, 30000]},
        {'name': 'Nước Suối', 'description': 'Nước suối tinh khiết', 'price': [15000, 20000]},
        {'name': 'Trà Đào', 'description': 'Trà đào thơm mát', 'price': [30000, 35000]},
        {'name': 'Nước Cam', 'description': 'Nước cam ép tươi', 'price': [35000, 40000]},
        {'name': 'Trà Sữa', 'description': 'Trà sữa thơm ngon', 'price': [35000, 40000]},
      ],
      'combo': [
        {'name': 'Combo Đôi', 'description': '2 bắp lớn + 2 nước ngọt lớn', 'price': [120000, 130000, 140000]},
        {'name': 'Combo Gia Đình', 'description': '3 bắp lớn + 4 nước ngọt', 'price': [180000, 200000]},
        {'name': 'Combo VIP', 'description': '2 bắp lớn + 2 nước ngọt + 2 snack', 'price': [150000, 160000]},
        {'name': 'Combo Nhỏ', 'description': '1 bắp vừa + 1 nước ngọt', 'price': [70000, 80000]},
        {'name': 'Combo Tiết Kiệm', 'description': '1 bắp lớn + 1 nước ngọt', 'price': [85000, 90000]},
      ],
      'snack': [
        {'name': 'Khoai Tây Chiên', 'description': 'Khoai tây chiên giòn, nóng hổi', 'price': [40000, 45000]},
        {'name': 'Hot Dog', 'description': 'Xúc xích nóng trong bánh mì', 'price': [50000, 55000]},
        {'name': 'Bánh Mì Kẹp', 'description': 'Bánh mì kẹp thịt thơm ngon', 'price': [45000, 50000]},
        {'name': 'Gà Viên Chiên', 'description': 'Gà viên chiên giòn, thơm lừng', 'price': [55000, 60000]},
        {'name': 'Bánh Ngọt', 'description': 'Bánh ngọt đa dạng hương vị', 'price': [30000, 35000]},
      ],
    };

    // Chọn một snack template ngẫu nhiên từ category
    final templates = snackTemplates[_selectedCategory] ?? snackTemplates['snack']!;
    final template = templates[random.nextInt(templates.length)];
    
    final name = template['name'] as String;
    final description = template['description'] as String;
    final prices = template['price'] as List<int>;
    final price = prices[random.nextInt(prices.length)];

    // Generate image URL từ Unsplash với keyword phù hợp
    final imageKeywords = {
      'popcorn': 'popcorn',
      'drink': 'soft+drink',
      'combo': 'food+combo',
      'snack': 'snack+food',
    };
    final keyword = imageKeywords[_selectedCategory] ?? 'food';
    final imageUrl = 'https://source.unsplash.com/400x400/?$keyword&sig=${random.nextInt(1000)}';

    setState(() {
      _nameController.text = name;
      _descriptionController.text = description;
      _priceController.text = price.toString();
      _imageUrlController.text = imageUrl;
    });
  }

  Future<void> _createSnack() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      final snack = SnackModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: _imageUrlController.text.trim(),
        category: _selectedCategory,
        isActive: true,
      );

      await DatabaseService().saveSnack(snack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã tạo ${_nameController.text} thành công!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      // Tự động generate snack mới
      _autoFillSnackInfo();
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
    final categoryColors = {
      'popcorn': const Color(0xFFFF9800),
      'drink': const Color(0xFF2196F3),
      'combo': const Color(0xFF9C27B0),
      'snack': const Color(0xFF4CAF50),
    };
    final categoryNames = {
      'popcorn': 'Bắp',
      'drink': 'Nước',
      'combo': 'Combo',
      'snack': 'Đồ Ăn',
    };
    final categoryColor = categoryColors[_selectedCategory] ?? Colors.grey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chọn danh mục và bấm "Tạo" - Hệ thống sẽ tự động điền thông tin',
                      style: TextStyle(color: Colors.blue[200], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Category Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh Mục *',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categoryColors.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = entry.key;
                            _autoFillSnackInfo();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? entry.value.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? entry.value : const Color(0xFF2A2A2A),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.key == 'popcorn'
                                    ? Icons.agriculture
                                    : entry.key == 'drink'
                                        ? Icons.local_drink
                                        : entry.key == 'combo'
                                            ? Icons.set_meal
                                            : Icons.fastfood,
                                color: isSelected ? entry.value : Colors.grey[400],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryNames[entry.key] ?? entry.key,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hidden fields for validation
            TextFormField(
              controller: _nameController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng chọn danh mục' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Lỗi hệ thống' : null,
            ),
            TextFormField(
              controller: _priceController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Lỗi hệ thống';
                final price = double.tryParse(value!);
                if (price == null || price <= 0) return 'Lỗi giá trị';
                return null;
              },
            ),
            TextFormField(
              controller: _imageUrlController,
              readOnly: true,
              style: const TextStyle(fontSize: 0, height: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Lỗi hệ thống' : null,
            ),

            // Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF2A2A2A),
                        ),
                        child: _imageUrlController.text.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: _imageUrlController.text,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2196F3),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.fastfood,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              )
                            : const Icon(Icons.fastfood, color: Colors.grey, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryNames[_selectedCategory] ?? _selectedCategory,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _nameController.text.isEmpty ? '---' : _nameController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _priceController.text.isEmpty
                                  ? '---'
                                  : '${NumberFormat('#,###', 'vi_VN').format(int.tryParse(_priceController.text) ?? 0)}đ',
                              style: const TextStyle(
                                color: Color(0xFFE50914),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_descriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A2A)),
                    const SizedBox(height: 12),
                    Text(
                      _descriptionController.text,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createSnack,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                _isCreating
                    ? 'Đang tạo...'
                    : 'TẠO ${categoryNames[_selectedCategory]?.toUpperCase() ?? "BẮP NƯỚC"}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 12: Manage Snacks
class _ManageSnacksTab extends StatelessWidget {
  const _ManageSnacksTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SnackModel>>(
      future: DatabaseService().getAllSnacks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        final snacks = snapshot.data ?? [];

        if (snacks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có bắp nước nào',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy tạo bắp nước mới ở tab "Tạo Bắp Nước"',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snacks.length,
          itemBuilder: (context, index) {
            final snack = snacks[index];
            final categoryColors = {
              'popcorn': const Color(0xFFFF9800),
              'drink': const Color(0xFF2196F3),
              'combo': const Color(0xFF9C27B0),
              'snack': const Color(0xFF4CAF50),
            };
            final categoryNames = {
              'popcorn': 'Bắp',
              'drink': 'Nước',
              'combo': 'Combo',
              'snack': 'Đồ Ăn',
            };
            final categoryColor = categoryColors[snack.category] ?? Colors.grey;

            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: categoryColor.withOpacity(0.2),
                  child: Icon(Icons.fastfood, color: categoryColor),
                ),
                title: Text(
                  snack.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      snack.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryNames[snack.category] ?? snack.category,
                            style: TextStyle(color: categoryColor, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat('#,###', 'vi_VN').format(snack.price.toInt())}đ',
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snack.isActive ? 'Đang hoạt động' : 'Đã tắt',
                      style: TextStyle(
                        color: snack.isActive ? Colors.green : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                      onPressed: () => _showEditSnackDialog(context, snack),
                      tooltip: 'Sửa',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFE50914)),
                      onPressed: () => _showDeleteSnackConfirmDialog(context, snack),
                      tooltip: 'Xóa',
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

  void _showEditSnackDialog(BuildContext context, SnackModel snack) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditSnackDialog(snack: snack),
    );
  }

  void _showDeleteSnackConfirmDialog(BuildContext context, SnackModel snack) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Xác nhận xóa',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa "${snack.name}"?\n\nHành động này không thể hoàn tác.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await DatabaseService().deleteSnack(snack.id);
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã xóa bắp nước'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: const Color(0xFFE50914),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}

// Edit Snack Dialog
class _EditSnackDialog extends StatefulWidget {
  final SnackModel snack;
  const _EditSnackDialog({required this.snack});

  @override
  State<_EditSnackDialog> createState() => _EditSnackDialogState();
}

class _EditSnackDialogState extends State<_EditSnackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'snack';
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.snack.name;
    _descriptionController.text = widget.snack.description;
    _priceController.text = widget.snack.price.toString();
    _imageUrlController.text = widget.snack.imageUrl;
    _selectedCategory = widget.snack.category;
    _isActive = widget.snack.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          const Icon(Icons.fastfood, color: Color(0xFFE50914)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sửa: ${widget.snack.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
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
                  labelText: 'Tên *',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Danh Mục *',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'popcorn', child: Text('Bắp')),
                  DropdownMenuItem(value: 'drink', child: Text('Nước')),
                  DropdownMenuItem(value: 'combo', child: Text('Combo')),
                  DropdownMenuItem(value: 'snack', child: Text('Đồ Ăn')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Giá (VND) *',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) return 'Giá phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'URL Hình Ảnh *',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập URL' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Đang hoạt động', style: TextStyle(color: Colors.white)),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                activeColor: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            
            setState(() => _isSaving = true);
            try {
              final updatedSnack = SnackModel(
                id: widget.snack.id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                price: double.parse(_priceController.text.trim()),
                imageUrl: _imageUrlController.text.trim(),
                category: _selectedCategory,
                isActive: _isActive,
              );
              
              await DatabaseService().updateSnack(updatedSnack);
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã cập nhật bắp nước thành công!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: const Color(0xFFE50914),
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
