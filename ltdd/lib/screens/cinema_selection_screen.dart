import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cinema.dart';
import '../services/database_services.dart';
import '../blocs/movies/movies_bloc.dart';
import '../blocs/movies/movies_event.dart';
import 'home_screen.dart';

class CinemaSelectionScreen extends StatefulWidget {
  const CinemaSelectionScreen({super.key});

  @override
  State<CinemaSelectionScreen> createState() => _CinemaSelectionScreenState();
}

class _CinemaSelectionScreenState extends State<CinemaSelectionScreen> {
  List<CinemaModel> _cinemas = [];
  bool _isLoading = true;

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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách rạp: ${e.toString()}'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  void _selectCinema(CinemaModel cinema) {
    // Push thay vì pushReplacement để có thể quay lại bằng back button
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MovieBloc()..add(
            FilterMoviesByCategory('nowShowing', cinemaId: cinema.id),
          ),
          child: HomeScreen(selectedCinemaId: cinema.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Chọn Rạp Chiếu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          : _cinemas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.theaters_outlined,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có rạp chiếu',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng liên hệ admin để thêm rạp',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cinemas.length,
                  itemBuilder: (context, index) {
                    CinemaModel cinema = _cinemas[index];
                    return _buildCinemaCard(cinema);
                  },
                ),
    );
  }

  Widget _buildCinemaCard(CinemaModel cinema) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCinema(cinema),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cinema Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: cinema.imageUrl != null && cinema.imageUrl!.isNotEmpty
                      ? Image.network(
                          cinema.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(
                                Icons.theaters,
                                size: 50,
                                color: Color(0xFFE50914),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.theaters,
                            size: 50,
                            color: Color(0xFFE50914),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Cinema Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cinema.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cinema.address,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cinema.phone != null && cinema.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cinema.phone!,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

