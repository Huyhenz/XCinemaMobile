import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/showtime.dart';
import '../models/cinema.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';
import '../widgets/auth_guard.dart';
import 'booking_screen.dart';

class ShowtimesScreen extends StatefulWidget {
  final String movieId;
  final String? cinemaId; // ID của rạp (để filter showtimes)
  const ShowtimesScreen({super.key, required this.movieId, this.cinemaId});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  List<ShowtimeModel> _allShowtimes = []; // Tất cả showtimes
  List<ShowtimeModel> _filteredShowtimes = []; // Showtimes đã filter theo ngày
  int _selectedDateIndex = 0;
  List<DateTime> _dates = [];
  CinemaModel? _cinema;
  List<CinemaModel> _allCinemas = [];

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadCinema();
    _loadAllCinemas();
    _loadShowtimes();
  }

  Future<void> _loadCinema() async {
    if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
      try {
        final cinema = await DatabaseService().getCinema(widget.cinemaId!);
        setState(() {
          _cinema = cinema;
        });
      } catch (e) {
        print('❌ Error loading cinema: $e');
      }
    }
  }

  Future<void> _loadAllCinemas() async {
    try {
      final cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _allCinemas = cinemas;
      });
    } catch (e) {
      print('❌ Error loading all cinemas: $e');
    }
  }

  void _generateDates() {
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _dates.add(now.add(Duration(days: i)));
    }
  }

  Future<void> _loadShowtimes() async {
    try {
      // Sử dụng _cinema?.id nếu có, nếu không thì dùng widget.cinemaId
      final cinemaIdToUse = _cinema?.id ?? widget.cinemaId;
      
      if (cinemaIdToUse != null && cinemaIdToUse.isNotEmpty) {
        // Load showtimes by movie and cinema
        _allShowtimes = await DatabaseService().getShowtimesByMovieAndCinema(
          widget.movieId,
          cinemaIdToUse,
        );
      } else {
        // Load all showtimes by movie
        _allShowtimes = await DatabaseService().getShowtimesByMovie(widget.movieId);
      }
      _filterShowtimes();
      setState(() {});
    } catch (e) {
      print('❌ Error loading showtimes: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi tải lịch chiếu: ${e.toString()}');
      }
      setState(() {
        _allShowtimes = [];
        _filteredShowtimes = [];
      });
    }
  }

  void _filterShowtimes() {
    if (_allShowtimes.isEmpty) {
      _filteredShowtimes = [];
      return;
    }

    final selectedDate = _dates[_selectedDateIndex];
    final selectedDateStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final selectedDateEnd = selectedDateStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final selectedDateStartMillis = selectedDateStart.millisecondsSinceEpoch;
    final selectedDateEndMillis = selectedDateEnd.millisecondsSinceEpoch;

    final now = DateTime.now();

    // Filter showtimes theo ngày được chọn (chỉ showtimes của ngày đó, không hết hạn)
    _filteredShowtimes = _allShowtimes.where((showtime) {
      final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
      final showtimeDateStart = DateTime(showtimeDate.year, showtimeDate.month, showtimeDate.day);
      
      // Phải cùng ngày với ngày được chọn (so sánh year, month, day)
      final isOnSelectedDate = showtimeDateStart.year == selectedDate.year &&
                               showtimeDateStart.month == selectedDate.month &&
                               showtimeDateStart.day == selectedDate.day;
      
      // Không hết hạn (chỉ áp dụng cho hôm nay và quá khứ)
      final isNotExpired = showtime.startTime >= now.millisecondsSinceEpoch;
      
      return isOnSelectedDate && isNotExpired;
    }).toList();

    // Sort by time
    _filteredShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn Lịch Chiếu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildTheaterInfo(),
          Expanded(child: _buildShowtimesList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          DateTime date = _dates[index];
          bool isSelected = _selectedDateIndex == index;
          bool isToday = index == 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
                _filterShowtimes(); // Filter lại showtimes theo ngày được chọn
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                )
                    : null,
                color: isSelected ? null : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0xFF2A2A2A),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFFE50914).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'HÔM NAY',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFE50914) : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTheaterInfo() {
    return GestureDetector(
      onTap: _showCinemaSelectionDialog,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFE50914),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _cinema?.name ?? 'Chọn rạp chiếu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.swap_horiz, color: Color(0xFFE50914), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cinema?.address ?? 'Bấm để đổi rạp',
                    style: TextStyle(
                      color: _cinema != null ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCinemaSelectionDialog() async {
    if (_allCinemas.isEmpty) {
      await DialogHelper.showError(context, 'Không có rạp chiếu nào');
      return;
    }

    final selectedCinema = await showModalBottomSheet<CinemaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.theaters, color: Color(0xFFE50914), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chọn Rạp Chiếu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _allCinemas.length,
                itemBuilder: (context, index) {
                  final cinema = _allCinemas[index];
                  final isSelected = _cinema?.id == cinema.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE50914).withOpacity(0.2)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : const Color(0xFF2A2A2A),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE50914),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        cinema.name,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFE50914) : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        cinema.address,
                        style: TextStyle(
                          color: isSelected ? Colors.grey[300] : Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFE50914),
                              size: 24,
                            )
                          : const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                      onTap: () {
                        Navigator.pop(context, cinema);
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );

    if (selectedCinema != null && selectedCinema.id != _cinema?.id) {
      setState(() {
        _cinema = selectedCinema;
      });
      // Reload showtimes với rạp mới
      await _loadShowtimes();
    }
  }


  Widget _buildShowtimesList() {
    if (_filteredShowtimes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có lịch chiếu',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredShowtimes.length,
      itemBuilder: (context, index) {
        ShowtimeModel showtime = _filteredShowtimes[index];
        DateTime time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                // Check authentication before booking, truyền return path
                final isAuthenticated = await AuthGuard.requireAuth(
                  context,
                  returnPath: 'booking:${showtime.id}',
                );
                if (isAuthenticated && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(showtimeId: showtime.id),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(time),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM').format(time),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FutureBuilder(
                        future: DatabaseService().getTheater(showtime.theaterId),
                        builder: (context, snapshot) {
                          final theater = snapshot.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (theater != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.meeting_room, color: Color(0xFFE50914), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      theater.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${showtime.availableSeats.length} ghế trống',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}